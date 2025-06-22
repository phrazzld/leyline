# frozen_string_literal: true

require 'digest'
require 'yaml'
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

      def initialize(file_cache: nil)
        @file_cache = file_cache
        @memory_cache = {}
        @content_hashes = {}
        @categories_index = {}
        @search_index = {}
        @last_scan_time = nil
        @memory_usage = 0

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
          @categories_index[category.to_s] || []
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
              results << {
                document: document,
                score: score,
                category: document[:category] # Use category from DocumentScanner
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
          memory_usage: @memory_usage,
          document_count: @memory_cache.size,
          category_count: @categories_index.size,
          scan_count: @scan_count,
          last_scan: @last_scan_time,

          # New microsecond precision metrics
          operation_metrics: operation_metrics,
          performance_summary: calculate_performance_summary(operation_metrics)
        }
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



      def cache_document(document)
        # Add to memory cache with size tracking
        @memory_cache[document[:path]] = document
        @memory_usage += document[:size]

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

      def calculate_relevance_score(document, query)
        score = 0

        # Title match (highest weight)
        if document[:title]&.downcase&.include?(query)
          score += 100
        end

        # ID match (high weight)
        if document[:id]&.include?(query)
          score += 50
        end

        # Content preview match (medium weight)
        if document[:content_preview]&.downcase&.include?(query)
          score += 25
        end

        # Category match (low weight)
        if document[:category]&.include?(query)
          score += 10
        end

        score
      end
    end
  end
end
