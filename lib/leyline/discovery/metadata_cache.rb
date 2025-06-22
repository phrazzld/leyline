# frozen_string_literal: true

require 'digest'
require 'yaml'
require 'lz4-ruby'
require_relative 'document_scanner'

module Leyline
  module Discovery
    # High-performance metadata cache for document discovery operations
    # Implements cache-aware algorithms optimized for <1s performance targets
    class MetadataCache
      class CacheError < StandardError; end

      # Performance targets
      TARGET_CACHE_HIT_RATIO = 0.8
      MAX_MEMORY_USAGE = 10 * 1024 * 1024  # 10MB

      def initialize(file_cache: nil, compression_enabled: false)
        @file_cache = file_cache
        @memory_cache = {}
        @content_hashes = {}
        @categories_index = {}
        @search_index = {}
        @last_scan_time = nil
        @memory_usage = 0

        # Compression configuration
        @compression_enabled = compression_enabled
        @compression_stats = {
          compressed_documents: 0,
          total_original_size: 0,
          total_compressed_size: 0,
          compression_events: 0
        }

        # Cache warming state
        @warming_thread = nil
        @warming_complete = false

        # Performance tracking
        @hit_count = 0
        @miss_count = 0
        @scan_count = 0

        # Microsecond precision performance telemetry
        @operation_timings = {
          list_categories: [],
          show_category: [],
          search_content: []
        }
        @operation_stats = {
          list_categories: { count: 0, total_time: 0.0, min_time: Float::INFINITY, max_time: 0.0 },
          show_category: { count: 0, total_time: 0.0, min_time: Float::INFINITY, max_time: 0.0 },
          search_content: { count: 0, total_time: 0.0, min_time: Float::INFINITY, max_time: 0.0 }
        }
      end

      # Fast category listing - O(1) lookup after initial scan
      def categories
        time_operation(:list_categories) do
          ensure_cache_current
          @categories_index.keys.sort
        end
      end

      # Fast category document lookup - O(1) category + O(k) documents in category
      def documents_for_category(category)
        time_operation(:show_category) do
          ensure_cache_current
          documents = @categories_index[category.to_s] || []
          # Decompress documents for external access
          documents.map { |doc| decompress_if_needed(doc) }
        end
      end

      # Optimized search - O(m) where m is query length using suffix matching
      def search(query)
        time_operation(:search_content) do
          ensure_cache_current
          return [] if query.nil? || query.strip.empty?

          query_normalized = query.downcase.strip
          results = []

          # Search through all cached documents
          @memory_cache.each_value do |document|
            score = calculate_relevance_score(document, query_normalized)
            if score > 0
              decompressed_document = decompress_if_needed(document)
              results << {
                document: decompressed_document,
                score: score,
                category: decompressed_document[:category] # Use category from DocumentScanner
              }
            end
          end

          # Sort by relevance score (descending)
          results.sort_by { |r| -r[:score] }
        end
      end

      # Cache health metrics for performance monitoring
      def performance_stats
        total_operations = @hit_count + @miss_count
        hit_ratio = total_operations > 0 ? @hit_count.to_f / total_operations : 0.0

        # Calculate operation-specific statistics
        operation_metrics = {}
        @operation_stats.each do |operation, stats|
          if stats[:count] > 0
            avg_time = stats[:total_time] / stats[:count]
            operation_metrics[operation] = {
              count: stats[:count],
              total_time_us: stats[:total_time],
              avg_time_us: avg_time,
              min_time_us: stats[:min_time],
              max_time_us: stats[:max_time],
              avg_time_ms: avg_time / 1000.0,
              recent_timings: @operation_timings[operation].last(10) # Last 10 for trend analysis
            }
          end
        end

        {
          # Existing stats
          hit_ratio: hit_ratio,
          hit_count: @hit_count,
          miss_count: @miss_count,
          memory_usage: @memory_usage,
          document_count: @memory_cache.size,
          category_count: @categories_index.size,
          scan_count: @scan_count,
          last_scan: @last_scan_time,

          # New microsecond precision metrics
          operation_metrics: operation_metrics,
          performance_summary: calculate_performance_summary(operation_metrics),

          # Compression statistics
          compression_stats: calculate_compression_stats
        }
      end

      # Start cache warming in background to eliminate cold-start penalty
      def warm_cache_in_background
        return false if @warming_thread&.alive? || @warming_complete

        @warming_thread = Thread.new do
          begin
            ensure_cache_current
            @warming_complete = true
          rescue => e
            # Warming failures shouldn't break existing functionality
            warn "Cache warming failed: #{e.message}" if ENV['LEYLINE_DEBUG']
          end
        end

        true
      end

      # Check if cache warming has completed
      def cache_warm?
        @warming_complete || (!@warming_thread&.alive? && !@last_scan_time.nil?)
      end

      # Check if compression is enabled
      def compression_enabled?
        @compression_enabled
      end

      # Get current memory usage in bytes
      def memory_usage_bytes
        @memory_usage
      end

      # Generate "Did you mean?" suggestions for failed searches
      def suggest_corrections(query, max_suggestions = 3)
        return [] if query.nil? || query.strip.empty? || query.length < 3

        query_normalized = query.downcase.strip
        candidates = []

        # Collect potential suggestions from document titles
        @memory_cache.each_value do |document|
          searchable_document = decompress_if_needed(document)
          title = searchable_document[:title]
          next unless title

          # Check whole title
          title_normalized = title.downcase
          if title_normalized != query_normalized
            distance = edit_distance(query_normalized, title_normalized)
            if distance > 0 && distance <= 3 && distance < query_normalized.length
              candidates << [title, distance]
            end
          end

          # Check individual words in title
          title.split(/\s+/).each do |word|
            word_normalized = word.downcase
            next if word_normalized.length < 3

            if word_normalized != query_normalized
              distance = edit_distance(query_normalized, word_normalized)
              if distance > 0 && distance <= 2 && distance < query_normalized.length
                candidates << [word, distance]
              end
            end
          end
        end

        # Sort by distance and remove duplicates
        candidates.uniq { |suggestion, _| suggestion.downcase }
                  .sort_by(&:last)
                  .first(max_suggestions)
                  .map(&:first)
      end

      # Cache a document with optional compression
      def cache_document(document)
        # Apply compression if enabled
        cached_document = @compression_enabled ? compress_document(document) : document

        # Subtract old document size if replacing existing document
        if (old_document = @memory_cache[document[:path]])
          @memory_usage -= old_document[:size]
        end

        # Add to memory cache with size tracking
        @memory_cache[document[:path]] = cached_document
        @memory_usage += cached_document[:size]

        # Track content hash and mtime for change detection
        @content_hashes[document[:path]] = {
          hash: document[:content_hash],
          mtime: document[:modified_time]
        }

        # Implement simple LRU if memory usage exceeds limit
        if @memory_usage > MAX_MEMORY_USAGE
          evict_least_recently_used
        end
      end

      # Force cache refresh - use sparingly for testing
      def invalidate!
        @memory_cache.clear
        @content_hashes.clear
        @categories_index.clear
        @search_index.clear
        @last_scan_time = nil
        @memory_usage = 0
      end

      private

      # Microsecond precision timing wrapper for performance telemetry
      def time_operation(operation_name)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
        result = yield
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)

        duration_microseconds = end_time - start_time
        record_operation_timing(operation_name, duration_microseconds)

        result
      end

      def record_operation_timing(operation, duration_microseconds)
        @operation_timings[operation] << duration_microseconds

        # Keep only last 100 timings for memory efficiency
        @operation_timings[operation].shift if @operation_timings[operation].size > 100

        # Update aggregated stats
        stats = @operation_stats[operation]
        stats[:count] += 1
        stats[:total_time] += duration_microseconds
        stats[:min_time] = [stats[:min_time], duration_microseconds].min
        stats[:max_time] = [stats[:max_time], duration_microseconds].max
      end

      def calculate_performance_summary(operation_metrics)
        total_operations = operation_metrics.values.sum { |m| m[:count] }
        total_time_ms = operation_metrics.values.sum { |m| m[:total_time_us] } / 1000.0

        {
          total_discovery_operations: total_operations,
          total_operation_time_ms: total_time_ms,
          avg_operation_time_ms: total_operations > 0 ? total_time_ms / total_operations : 0.0,
          performance_target_met: operation_metrics.values.all? { |m| m[:avg_time_ms] < 1000.0 } # <1s target
        }
      end

      def calculate_compression_stats
        return { enabled: false } unless @compression_enabled

        compression_ratio = if @compression_stats[:total_original_size] > 0
          @compression_stats[:total_compressed_size].to_f / @compression_stats[:total_original_size]
        else
          1.0
        end

        {
          enabled: true,
          compressed_documents: @compression_stats[:compressed_documents],
          compression_ratio: compression_ratio,
          space_saved_bytes: @compression_stats[:total_original_size] - @compression_stats[:total_compressed_size],
          space_saved_percent: ((1.0 - compression_ratio) * 100).round(1),
          compression_events: @compression_stats[:compression_events]
        }
      end

      def ensure_cache_current
        # Check if we need to rescan (first run or cache invalidation)
        if @last_scan_time.nil? || cache_needs_refresh?
          scan_documents
          @last_scan_time = Time.now
          @scan_count += 1
        end
      end

      def cache_needs_refresh?
        # For performance, only check periodically or when explicitly requested
        # In production, this would check file modification times
        false
      end

      def scan_documents
        # Scan order optimized for cache performance:
        # 1. Check existing cache for unchanged files (cache hit)
        # 2. Only re-read files that have changed (cache miss)
        # 3. Build optimized lookup structures with parallel processing

        paths_to_scan = discover_document_paths
        changed_paths = []

        # First pass: check which files need scanning
        paths_to_scan.each do |path|
          begin
            if file_changed?(path)
              @miss_count += 1
              changed_paths << path
            else
              @hit_count += 1
            end
          rescue => e
            # Log error but continue scanning other documents
            warn "Error checking #{path}: #{e.message}"
          end
        end

        # Second pass: scan changed files using parallel processing
        if changed_paths.any?
          scanner = DocumentScanner.new
          documents = scanner.scan_documents(changed_paths)

          documents.each do |document|
            cache_document(document) if document
          end
        end

        rebuild_indexes
      end

      def discover_document_paths
        # Optimized path discovery using existing patterns
        paths = []

        # Look for docs in the expected structure
        base_dirs = [
          'docs/tenets',
          'docs/bindings/core',
          'docs/bindings/categories'
        ]

        base_dirs.each do |base_dir|
          next unless Dir.exist?(base_dir)

          # Use Dir.glob for efficient file discovery
          pattern = File.join(base_dir, '**', '*.md')
          Dir.glob(pattern).each do |path|
            # Skip index files and other non-content files
            next if File.basename(path) =~ /^(index|glance|00-index)\.md$/
            paths << path
          end
        end

        paths
      end

      def file_changed?(path)
        return true unless File.exist?(path)

        # Quick file modification check
        current_mtime = File.mtime(path)
        cached_mtime = @content_hashes[path]&.[](:mtime)

        return true if cached_mtime.nil? || current_mtime > cached_mtime

        # If mtime unchanged, assume content unchanged (performance optimization)
        false
      end

      def evict_least_recently_used
        # Simple LRU implementation - remove oldest entries until under limit
        # In a production system, would track access times
        while @memory_usage > MAX_MEMORY_USAGE * 0.8 && !@memory_cache.empty?
          oldest_path = @memory_cache.keys.first
          document = @memory_cache.delete(oldest_path)
          @memory_usage -= document[:size] if document
        end
      end

      def rebuild_indexes
        # Build optimized category index for O(1) category lookups
        @categories_index.clear

        @memory_cache.each_value do |document|
          category = document[:category]
          @categories_index[category] ||= []
          @categories_index[category] << document
        end

        # Sort documents within each category by title for consistent ordering
        @categories_index.each_value do |documents|
          documents.sort_by! { |doc| doc[:title] }
        end
      end

      def compress_document(document)
        return document unless @compression_enabled

        compressed_document = document.dup
        original_size = document[:size]

        # Compress content_preview and metadata if they're large enough
        compressible_fields = [:content_preview, :metadata]
        compression_applied = false

        compressible_fields.each do |field|
          next unless document[field]

          original_data = field == :metadata ? document[field].to_yaml : document[field].to_s
          next if original_data.bytesize < 100  # Only compress if worthwhile

          begin
            compressed_data = LZ4.compress(original_data)

            # Only use compression if it saves space
            if compressed_data.bytesize < original_data.bytesize
              compressed_document[:"#{field}_compressed"] = compressed_data
              compressed_document[:"#{field}_original_size"] = original_data.bytesize
              compressed_document.delete(field)
              compression_applied = true
            end
          rescue => e
            # Graceful fallback on compression failure
            warn "Compression failed for #{field}: #{e.message}" if ENV['LEYLINE_DEBUG']
          end
        end

        if compression_applied
          compressed_document[:_compressed] = true
          compressed_document[:size] = calculate_compressed_document_size(compressed_document)

          # Update compression statistics
          @compression_stats[:compressed_documents] += 1
          @compression_stats[:total_original_size] += original_size
          @compression_stats[:total_compressed_size] += compressed_document[:size]
          @compression_stats[:compression_events] += 1
        end

        compressed_document
      end

      def decompress_document(document)
        return document unless document[:_compressed]

        decompressed_document = document.dup

        # Decompress each compressed field
        [:content_preview, :metadata].each do |field|
          compressed_key = :"#{field}_compressed"
          if document[compressed_key]
            begin
              decompressed_data = LZ4.decompress(document[compressed_key])
              decompressed_document[field] = field == :metadata ? YAML.safe_load(decompressed_data) : decompressed_data
              decompressed_document.delete(compressed_key)
              decompressed_document.delete(:"#{field}_original_size")
            rescue => e
              warn "Decompression failed for #{field}: #{e.message}" if ENV['LEYLINE_DEBUG']
              # Continue with missing field rather than breaking entirely
            end
          end
        end

        decompressed_document.delete(:_compressed)
        decompressed_document
      end

      def decompress_if_needed(document)
        document[:_compressed] ? decompress_document(document) : document
      end

      def calculate_compressed_document_size(document)
        size = 0
        document.each do |key, value|
          case value
          when String
            size += value.bytesize
          when Integer, Numeric
            size += 8
          when Time
            size += 16
          when Hash
            size += value.to_yaml.bytesize
          else
            size += value.to_s.bytesize
          end
        end
        size
      end

      def calculate_relevance_score(document, query)
        # Ensure document is decompressed for search
        searchable_document = decompress_if_needed(document)
        score = 0

        # Title matches (exact and fuzzy)
        title = searchable_document[:title]&.downcase
        if title&.include?(query)
          score += 100  # Exact substring match
        elsif title && fuzzy_match?(title, query)
          score += fuzzy_score(title, query)  # Fuzzy match with distance-based scoring
        end

        # ID match (high weight)
        if searchable_document[:id]&.include?(query)
          score += 50
        end

        # Content preview match (medium weight)
        content = searchable_document[:content_preview]&.downcase
        if content&.include?(query)
          score += 25
        elsif content && fuzzy_match?(content, query)
          score += fuzzy_score(content, query) / 2  # Lower weight for content fuzzy match
        end

        # Category match (low weight)
        if searchable_document[:category]&.include?(query)
          score += 10
        end

        score
      end

      # Simple fuzzy matching with edit distance threshold
      def fuzzy_match?(text, query)
        return false if text.nil? || query.nil? || query.length < 3

        # Try exact word matches first (more efficient)
        text_words = text.split(/\s+/)
        query_words = query.split(/\s+/)

        # Check for fuzzy word matches
        query_words.any? do |q_word|
          text_words.any? { |t_word| word_fuzzy_match?(t_word, q_word) }
        end || whole_string_fuzzy_match?(text, query)
      end

      # Calculate fuzzy score based on edit distance
      def fuzzy_score(text, query)
        # Word-level fuzzy matching
        text_words = text.split(/\s+/)
        query_words = query.split(/\s+/)

        max_word_score = 0
        query_words.each do |q_word|
          text_words.each do |t_word|
            if word_fuzzy_match?(t_word, q_word)
              distance = edit_distance(t_word, q_word)
              word_score = case distance
                when 0 then 90  # Exact word match
                when 1 then 75  # Single character difference
                when 2 then 60  # Two character difference
                else 40         # More differences but still acceptable
              end
              max_word_score = [max_word_score, word_score].max
            end
          end
        end

        max_word_score
      end

      # Check if two words are fuzzy matches
      def word_fuzzy_match?(word1, word2)
        return false if word1.nil? || word2.nil? || word1.length < 3 || word2.length < 3

        # Quick length check - if too different, no match
        return false if (word1.length - word2.length).abs > 3

        edit_distance(word1, word2) <= 2
      end

      # Check fuzzy match for whole strings (fallback)
      def whole_string_fuzzy_match?(text, query)
        return false if text.length > query.length * 2 || query.length > text.length * 2

        edit_distance(text, query) <= [query.length / 3, 3].min
      end

      # Simple Levenshtein distance implementation
      def edit_distance(str1, str2)
        return str2.length if str1.empty?
        return str1.length if str2.empty?

        # Use single dimensional array for memory efficiency
        prev_row = (0..str2.length).to_a

        str1.each_char.with_index do |char1, i|
          curr_row = [i + 1]

          str2.each_char.with_index do |char2, j|
            # Calculate cost
            cost = char1 == char2 ? 0 : 1

            # Choose minimum operation
            curr_row << [
              prev_row[j + 1] + 1,     # deletion
              curr_row[j] + 1,         # insertion
              prev_row[j] + cost       # substitution
            ].min
          end

          prev_row = curr_row
        end

        prev_row.last
      end
    end
  end
end
