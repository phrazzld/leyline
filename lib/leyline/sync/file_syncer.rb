# frozen_string_literal: true

require 'fileutils'
require 'digest'

module Leyline
  module Sync
    class FileSyncer
      class SyncError < StandardError; end

      def initialize(source_directory, target_directory, cache: nil, stats: nil)
        @source_directory = source_directory
        @target_directory = target_directory
        @cache = cache
        @stats = stats
        @sync_results = {
          copied: [],
          skipped: [],
          errors: []
        }
      end

      def sync(force: false, force_git: false, verbose: false)
        @stats&.start_sync_timing

        raise SyncError, "Source directory does not exist: #{@source_directory}" unless Dir.exist?(@source_directory)

        # Validate target directory name
        target_basename = File.basename(@target_directory)
        if target_basename.start_with?('-')
          raise SyncError,
                "Invalid target directory name '#{target_basename}'. Directory names cannot start with a dash."
        end

        # Create target directory if it doesn't exist
        FileUtils.mkdir_p(@target_directory) unless Dir.exist?(@target_directory)

        # Find all files in source directory
        source_files = find_files(@source_directory)

        # Cache-aware sync optimization: check if we can skip sync entirely
        if @cache && !force_git && source_files.any?
          cache_check_start = Time.now
          cache_hit_ratio = calculate_cache_hit_ratio(source_files, @cache)
          @stats&.add_cache_check_time(Time.now - cache_check_start)

          # Check if git sync is needed based on cache hit ratio
          if !git_sync_needed?(cache_hit_ratio, force_git: force_git)
            # All files are sufficiently cached and exist in target
            cached_files = check_cached_files_exist_in_target(source_files)

            if cached_files[:all_exist]
              puts "Serving from cache (#{(cache_hit_ratio * 100).round(1)}% hit ratio)" if verbose
              @stats&.record_git_operations_skipped

              # Mark all files as skipped since they're already up-to-date from cache
              source_files.each do |file|
                @sync_results[:skipped] << file
              end

              @stats&.end_sync_timing
              return @sync_results
            elsif verbose
              puts "Cache hit ratio #{(cache_hit_ratio * 100).round(1)}% sufficient, but some target files missing. Proceeding with sync..."
            end
          elsif verbose
            if verbose
              puts "Cache hit ratio #{(cache_hit_ratio * 100).round(1)}% below threshold, proceeding with sync..."
            end
          end
        end

        # Standard sync flow - process each file individually
        source_files.each do |source_file|
          sync_file(source_file, force: force)
        end

        @stats&.end_sync_timing
        @sync_results
      end

      # Calculate the percentage of target files available in cache
      # Returns float 0.0-1.0 representing cache hit ratio
      def calculate_cache_hit_ratio(target_files, cache)
        return 0.0 unless cache # No cache = 0% hit ratio

        total_files = target_files.size
        return 0.0 if total_files == 0 # No files = 0% hit ratio

        cache_hits = target_files.count do |relative_path|
          source_path = File.join(@source_directory, relative_path)
          next false unless File.exist?(source_path) # Missing source = cache miss

          begin
            source_content = File.read(source_path)
            source_hash = Digest::SHA256.hexdigest(source_content)
            cache_result = cache.get(source_hash)

            if !cache_result.nil?
              @stats&.record_cache_hit
              true
            else
              @stats&.record_cache_miss
              false
            end
          rescue StandardError
            @stats&.record_cache_miss
            false # File read error = cache miss
          end
        end

        cache_hits.to_f / total_files
      rescue StandardError
        # Log error but return 0.0 to fail safely
        0.0
      end

      # Determine if git sync operations are needed based on cache hit ratio
      # Returns true if git operations should proceed, false if cache is sufficient
      def git_sync_needed?(cache_hit_ratio, force_git: false)
        # Always sync if explicitly forced
        return true if force_git

        # Get threshold from environment variable or use default
        threshold_str = ENV.fetch('LEYLINE_CACHE_THRESHOLD', '0.8')
        threshold = Float(threshold_str)

        # Validate threshold is in reasonable range
        if threshold < 0.0 || threshold > 1.0
          threshold = 0.8 # Fall back to default
        end

        # Sync needed if cache hit ratio is below threshold
        cache_hit_ratio < threshold
      rescue ArgumentError, TypeError
        # Invalid threshold format, default to syncing (fail safe)
        true
      rescue StandardError
        # On any other error, default to syncing (fail safe)
        true
      end

      # Check if cached files exist in target directory and match cache content
      # Returns hash with :all_exist boolean and :details array
      def check_cached_files_exist_in_target(source_files)
        all_exist = true
        details = []

        source_files.each do |relative_path|
          target_path = File.join(@target_directory, relative_path)
          source_path = File.join(@source_directory, relative_path)

          if !File.exist?(target_path)
            all_exist = false
            details << { file: relative_path, status: :missing_in_target }
          elsif File.exist?(source_path)
            # Verify target file matches cached content
            begin
              source_content = File.read(source_path)
              target_content = File.read(target_path)

              if source_content != target_content
                all_exist = false
                details << { file: relative_path, status: :content_mismatch }
              else
                details << { file: relative_path, status: :exists_and_matches }
              end
            rescue StandardError => e
              all_exist = false
              details << { file: relative_path, status: :read_error, error: e.message }
            end
          else
            details << { file: relative_path, status: :source_missing }
          end
        end

        { all_exist: all_exist, details: details }
      rescue StandardError => e
        # On any error, assume we need to sync
        { all_exist: false, details: [{ error: e.message }] }
      end

      private

      def find_files(directory)
        files = []
        Dir.glob('**/*', base: directory).each do |relative_path|
          full_path = File.join(directory, relative_path)
          files << relative_path if File.file?(full_path)
        end
        files
      end

      def sync_file(relative_path, force: false)
        source_path = File.join(@source_directory, relative_path)
        target_path = File.join(@target_directory, relative_path)

        # Create target directory if needed
        target_dir = File.dirname(target_path)
        FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

        # Check if target file exists
        target_existed = File.exist?(target_path)
        if target_existed
          if !files_different?(source_path, target_path)
            # Files are identical, skip copying
            @sync_results[:skipped] << relative_path
            return
          elsif !force
            # Files are different and no force flag, skip to avoid overwriting
            @sync_results[:skipped] << relative_path
            return
          end
          # If force is true and files are different, we'll overwrite below
        end

        # Copy the file
        begin
          FileUtils.cp(source_path, target_path)
          @sync_results[:copied] << relative_path

          # Cache the content after successful copy (only if target didn't exist before)
          # If target existed, files_different? already cached the content
          if @cache && !target_existed
            begin
              source_content = File.read(source_path)
              cache_result = @cache.put(source_content)
              @stats&.record_cache_put if cache_result
            rescue StandardError
              # Cache errors should not interrupt file sync
              # Error is already logged by FileCache
            end
          end
        rescue StandardError => e
          @sync_results[:errors] << { file: relative_path, error: e.message }
        end
      end

      def files_different?(source_path, target_path)
        # Read source file and compute hash
        source_content = File.read(source_path)
        source_hash = Digest::SHA256.hexdigest(source_content)

        # Read target file and compute hash
        target_content = File.read(target_path)
        target_hash = Digest::SHA256.hexdigest(target_content)

        # Cache the source content for future use
        if @cache
          begin
            cache_result = @cache.put(source_content)
            @stats&.record_cache_put if cache_result
          rescue StandardError
            # Cache errors should not interrupt file comparison
            # Error is already logged by FileCache
          end
        end

        source_hash != target_hash
      rescue StandardError
        # If we can't read files for comparison, assume they're different
        true
      end
    end
  end
end
