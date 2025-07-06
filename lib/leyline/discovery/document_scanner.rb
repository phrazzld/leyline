# frozen_string_literal: true

require 'yaml'
require 'digest'
require 'concurrent-ruby'

module Leyline
  module Discovery
    # High-performance document scanner optimized for YAML front-matter extraction
    # Implements streaming algorithms to minimize memory usage and maximize throughput
    class DocumentScanner
      class ScanError < StandardError; end

      # Performance optimization constants
      MAX_FRONT_MATTER_SIZE = 8 * 1024  # 8KB max front-matter size
      CONTENT_PREVIEW_LENGTH = 200      # Characters for search preview
      PARALLEL_THRESHOLD = 10           # Use parallel processing for 10+ files
      MAX_THREADS = 4                   # Limit concurrent threads for I/O

      def initialize
        @scan_stats = Concurrent::Hash.new
        @scan_stats.merge!({
                             files_scanned: 0,
                             yaml_parse_errors: 0,
                             total_bytes_processed: 0,
                             avg_scan_time: 0.0,
                             parallel_batches: 0,
                             sequential_batches: 0
                           })
      end

      # Scan a single document file for metadata
      # Returns document metadata hash or nil if scan fails
      def scan_document(file_path)
        start_time = Time.now

        return nil unless File.exist?(file_path)

        begin
          # Read file content efficiently
          content = File.read(file_path)
          @scan_stats[:total_bytes_processed] += content.bytesize

          # Extract front-matter with performance optimization
          front_matter = extract_front_matter_fast(content)

          return nil unless front_matter

          # Build document metadata
          document = build_document_metadata(file_path, content, front_matter)

          # Update scan statistics
          @scan_stats[:files_scanned] += 1
          scan_time = Time.now - start_time
          update_avg_scan_time(scan_time)

          document
        rescue StandardError => e
          warn "Document scan error for #{file_path}: #{e.message}"
          nil
        end
      end

      # Batch scan multiple documents with optimized I/O
      # Uses parallel processing for large batches (10+ files)
      def scan_documents(file_paths)
        return [] if file_paths.empty?

        # Use parallel processing for larger batches
        if file_paths.length >= PARALLEL_THRESHOLD
          scan_documents_parallel(file_paths)
        else
          scan_documents_sequential(file_paths)
        end
      end

      # Get scanning performance statistics
      def scan_statistics
        @scan_stats.dup
      end

      # Reset statistics (useful for testing)
      def reset_statistics!
        @scan_stats = Concurrent::Hash.new
        @scan_stats.merge!({
                             files_scanned: 0,
                             yaml_parse_errors: 0,
                             total_bytes_processed: 0,
                             avg_scan_time: 0.0,
                             parallel_batches: 0,
                             sequential_batches: 0
                           })
      end

      private

      # Parallel document scanning using ThreadPoolExecutor
      def scan_documents_parallel(file_paths)
        @scan_stats[:parallel_batches] += 1
        start_time = Time.now

        # Thread-safe results collection
        results = Concurrent::Map.new

        # Create thread pool with limited concurrency for I/O operations
        pool = Concurrent::ThreadPoolExecutor.new(
          min_threads: 1,
          max_threads: MAX_THREADS,
          max_queue: file_paths.length
        )

        # Submit all scanning tasks
        futures = file_paths.map.with_index do |path, index|
          Concurrent::Future.execute(executor: pool) do
            document = scan_document(path)
            results[index] = document if document
          end
        end

        # Wait for all tasks to complete
        futures.each(&:value)

        # Shutdown the thread pool
        pool.shutdown
        pool.wait_for_termination(30) # 30 second timeout

        # Extract results in original order
        documents = []
        file_paths.each_with_index do |_path, index|
          documents << results[index] if results.key?(index)
        end

        total_time = Time.now - start_time
        puts "Parallel scan: #{documents.length} documents in #{total_time.round(3)}s" if ENV['LEYLINE_DEBUG']

        documents
      end

      # Sequential document scanning (fallback for small batches)
      def scan_documents_sequential(file_paths)
        @scan_stats[:sequential_batches] += 1
        documents = []

        file_paths.each do |path|
          document = scan_document(path)
          documents << document if document
        end

        documents
      end

      # Optimized front-matter extraction using string operations
      # Avoids regex for better performance on large files
      def extract_front_matter_fast(content)
        # Quick check for front-matter marker
        return nil unless content.start_with?('---')

        # Find the closing marker efficiently
        start_pos = 4 # Skip initial "---\n"
        end_pos = content.index("\n---\n", start_pos)

        return nil unless end_pos

        # Extract YAML content
        yaml_content = content[start_pos...end_pos]

        # Size limit check for security and performance
        if yaml_content.bytesize > MAX_FRONT_MATTER_SIZE
          warn "Front-matter too large (#{yaml_content.bytesize} bytes), skipping"
          return nil
        end

        # Parse YAML with error handling
        begin
          YAML.safe_load(yaml_content)
        rescue StandardError => e
          @scan_stats[:yaml_parse_errors] += 1
          warn "YAML parse error: #{e.message}"
          nil
        end
      end

      def build_document_metadata(file_path, content, front_matter)
        # Calculate content hash for cache invalidation
        content_hash = Digest::SHA256.hexdigest(content)

        # Extract document title efficiently
        title = extract_title_fast(content, file_path)

        # Determine document type and category from path
        doc_type = determine_document_type(file_path)
        category = extract_category_from_path(file_path)

        # Extract content preview for search
        content_preview = extract_content_preview_fast(content)

        # Build metadata structure
        {
          id: front_matter['id'],
          title: title,
          path: file_path,
          category: category,
          type: doc_type,
          metadata: front_matter,
          content_preview: content_preview,
          content_hash: content_hash,
          size: content.bytesize,
          modified_time: File.mtime(file_path),
          scan_time: Time.now
        }
      end

      # Fast title extraction using line-by-line scanning
      def extract_title_fast(content, file_path)
        # Scan for first markdown header after front-matter
        lines = content.lines
        in_front_matter = false
        front_matter_ended = false

        lines.each do |line|
          stripped = line.strip

          # Track front-matter boundaries
          if stripped == '---'
            if in_front_matter
              front_matter_ended = true
              in_front_matter = false
            else
              in_front_matter = true
            end
            next
          end

          next if in_front_matter
          next unless front_matter_ended

          # Look for markdown header
          next unless stripped.start_with?('#')

          # Extract title, removing markdown syntax
          title = stripped.gsub(/^#+\s*/, '').strip
          return title unless title.empty?
        end

        # Fallback: use filename if no title found
        File.basename(file_path, '.md').tr('-', ' ').capitalize
      end

      def extract_category_from_path(file_path)
        # Optimized category extraction using string operations
        path_parts = file_path.split('/')

        # Handle different path structures
        if path_parts.include?('categories')
          category_index = path_parts.index('categories')
          return path_parts[category_index + 1] if category_index && path_parts[category_index + 1]
        end

        # Handle core and tenets
        return 'core' if path_parts.include?('core')
        return 'tenets' if path_parts.include?('tenets')

        'unknown'
      end

      def determine_document_type(file_path)
        case file_path
        when %r{/tenets/}
          'tenet'
        when %r{/bindings/}
          'binding'
        else
          'unknown'
        end
      end

      # Fast content preview extraction for search results
      def extract_content_preview_fast(content)
        lines = content.lines
        in_front_matter = false
        front_matter_ended = false
        preview_text = ''

        lines.each do |line|
          stripped = line.strip

          # Skip front-matter
          if stripped == '---'
            if in_front_matter
              front_matter_ended = true
              in_front_matter = false
            else
              in_front_matter = true
            end
            next
          end

          next if in_front_matter
          next unless front_matter_ended

          # Skip headers and empty lines
          next if stripped.empty? || stripped.start_with?('#')

          # Collect content for preview
          preview_text += stripped + ' '

          # Stop when we have enough content
          break if preview_text.length >= CONTENT_PREVIEW_LENGTH
        end

        # Trim to word boundary
        if preview_text.length > CONTENT_PREVIEW_LENGTH
          preview_text = preview_text[0...CONTENT_PREVIEW_LENGTH]
          last_space = preview_text.rindex(' ')
          preview_text = preview_text[0...last_space] if last_space
          preview_text += '...'
        end

        preview_text.strip
      end

      def update_avg_scan_time(scan_time)
        # Calculate rolling average scan time
        files_scanned = @scan_stats[:files_scanned]
        if files_scanned == 1
          @scan_stats[:avg_scan_time] = scan_time
        else
          current_avg = @scan_stats[:avg_scan_time]
          @scan_stats[:avg_scan_time] = ((current_avg * (files_scanned - 1)) + scan_time) / files_scanned
        end
      end
    end
  end
end
