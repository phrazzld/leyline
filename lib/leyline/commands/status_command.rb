# frozen_string_literal: true

require 'digest'
require_relative '../file_comparator'
require_relative '../sync_state'
require_relative '../discovery/metadata_cache'
require_relative '../version'
require_relative '../errors'

module Leyline
  module Commands
    # Implements the 'leyline status' command to show current sync state
    # Displays locally modified files, available updates, and summary statistics
    # Supports JSON output and category filtering for transparency operations
    class StatusCommand
      class StatusError < Leyline::LeylineError
        def error_type
          :command
        end

        def recovery_suggestions
          [
            'Ensure the leyline directory exists: docs/leyline',
            'Run leyline sync first to initialize',
            'Check file permissions in the project directory'
          ]
        end
      end

      def initialize(options = {})
        @options = options
        @base_directory = @options[:directory] || Dir.pwd
        @cache_dir = @options[:cache_dir] || ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
        @cache_dir = File.expand_path(@cache_dir)
      end

      # Execute status command and return results
      # Returns hash with status information or nil on error
      def execute
        start_time = Time.now

        begin
          status_data = gather_status_information
          execution_time = ((Time.now - start_time) * 1000).round(2)

          status_data[:performance] = {
            execution_time_ms: execution_time,
            cache_enabled: cache_available?
          }

          if @options[:json]
            output_json(status_data)
          else
            output_human_readable(status_data)
          end

          status_data
        rescue StandardError => e
          handle_error(e)
          nil
        end
      end

      private

      def gather_status_information
        sync_state = SyncState.new(@cache_dir)
        file_comparator = FileComparator.new(cache: file_cache, base_directory: @base_directory)

        # Get current file state
        current_files = discover_current_files

        # Create manifest with relative paths for comparison
        leyline_path = File.join(@base_directory, 'docs', 'leyline')
        current_manifest = {}
        current_files.each do |relative_path|
          full_path = File.join(leyline_path, relative_path)
          if File.exist?(full_path)
            begin
              content = File.read(full_path)
              current_manifest[relative_path] = Digest::SHA256.hexdigest(content)
            rescue Errno::EACCES => e
              # Skip files we can't read but note in verbose mode
              warn "Warning: Cannot read #{relative_path}: #{e.message}" if @options[:verbose]
            rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
              # Handle encoding errors gracefully
              raise Leyline::ComparisonFailedError.new(
                relative_path, nil,
                reason: :encoding_error
              )
            end
          end
        end

        # Compare with saved sync state
        begin
          state_comparison = sync_state.compare_with_current_files(current_manifest)
        rescue StandardError => e
          # If sync state comparison fails, continue with limited information
          warn "Warning: Sync state comparison failed: #{e.message}" if @options[:verbose]
          state_comparison = nil
        end

        {
          leyline_version: VERSION,
          base_directory: @base_directory,
          cache_directory: @cache_dir,
          sync_state: build_sync_state_info(sync_state, state_comparison),
          local_changes: build_local_changes_info(state_comparison),
          file_summary: build_file_summary(current_files, state_comparison),
          categories: determine_active_categories
        }
      end

      def build_sync_state_info(sync_state, comparison)
        if comparison.nil?
          {
            exists: false,
            last_sync: nil,
            synced_version: nil,
            synced_categories: [],
            state_age_seconds: nil
          }
        else
          {
            exists: true,
            last_sync: comparison[:base_timestamp],
            synced_version: comparison[:base_version],
            synced_categories: comparison[:base_categories],
            state_age_seconds: sync_state.state_age_seconds
          }
        end
      end

      def build_local_changes_info(comparison)
        if comparison.nil?
          {
            total_changes: 0,
            added: [],
            modified: [],
            removed: [],
            unchanged: []
          }
        else
          {
            total_changes: comparison[:added].size + comparison[:modified].size + comparison[:removed].size,
            added: comparison[:added].sort,
            modified: comparison[:modified].sort,
            removed: comparison[:removed].sort,
            unchanged: comparison[:unchanged].sort
          }
        end
      end

      def build_file_summary(current_files, comparison)
        {
          total_files: current_files.size,
          by_category: count_files_by_category(current_files),
          sync_coverage: calculate_sync_coverage(comparison)
        }
      end

      def count_files_by_category(files)
        categories = {}

        files.each do |file_path|
          if file_path.include?('tenets/')
            categories['tenets'] = (categories['tenets'] || 0) + 1
          elsif file_path.include?('bindings/core/')
            categories['core'] = (categories['core'] || 0) + 1
          elsif match = file_path.match(%r{bindings/categories/([^/]+)/})
            category = match[1]
            categories[category] = (categories[category] || 0) + 1
          end
        end

        categories
      end

      def calculate_sync_coverage(comparison)
        return { percentage: 0, status: 'no_sync_state' } if comparison.nil?

        total_files = comparison[:added].size + comparison[:modified].size +
                     comparison[:removed].size + comparison[:unchanged].size

        return { percentage: 100, status: 'perfect' } if total_files == 0

        unchanged_count = comparison[:unchanged].size
        coverage_percentage = ((unchanged_count.to_f / total_files) * 100).round(2)

        status = if coverage_percentage == 100
                   'perfect'
                 elsif coverage_percentage >= 80
                   'good'
                 elsif coverage_percentage >= 50
                   'fair'
                 else
                   'poor'
                 end

        { percentage: coverage_percentage, status: status }
      end

      def discover_current_files
        return [] unless Dir.exist?(@base_directory)

        leyline_path = File.join(@base_directory, 'docs', 'leyline')
        return [] unless Dir.exist?(leyline_path)

        files = []
        categories = @options[:categories] || determine_active_categories

        patterns = build_search_patterns(categories)
        patterns.each do |pattern|
          search_path = File.join(leyline_path, pattern)
          Dir.glob(search_path).each do |file_path|
            next unless File.file?(file_path)
            # Store relative path from leyline directory
            relative_path = file_path.sub("#{leyline_path}/", '')
            files << relative_path
          end
        end

        files.sort
      end

      def build_search_patterns(categories)
        patterns = ['tenets/**/*.md', 'bindings/core/**/*.md']

        categories.each do |category|
          next if category == 'core'
          patterns << "bindings/categories/#{category}/**/*.md"
        end

        patterns
      end

      def determine_active_categories
        # Extract categories from options or discover from existing files
        if @options[:categories]
          Array(@options[:categories])
        else
          discover_categories_from_files
        end
      end

      def discover_categories_from_files
        categories = ['core']
        bindings_path = File.join(@base_directory, 'docs', 'leyline', 'bindings', 'categories')

        return categories unless Dir.exist?(bindings_path)

        Dir.entries(bindings_path).each do |entry|
          next if entry.start_with?('.')

          category_path = File.join(bindings_path, entry)
          if Dir.exist?(category_path)
            categories << entry
          end
        end

        categories.sort
      end

      def file_cache
        return @file_cache if defined?(@file_cache)

        begin
          require_relative '../cache/file_cache'
          @file_cache = Cache::FileCache.new(@cache_dir)
        rescue StandardError => e
          warn "Warning: Cache initialization failed: #{e.message}" if @options[:verbose]
          @file_cache = nil
        end

        @file_cache
      end

      def cache_available?
        !file_cache.nil?
      end

      def output_json(status_data)
        require 'json'
        puts JSON.pretty_generate(status_data)
      end

      def output_human_readable(status_data)
        puts "Leyline Status Report"
        puts "===================="
        puts

        output_version_info(status_data)
        puts

        output_sync_state_info(status_data[:sync_state])
        puts

        output_local_changes_info(status_data[:local_changes])
        puts

        output_file_summary_info(status_data[:file_summary])

        if @options[:verbose]
          puts
          output_performance_info(status_data[:performance])
        end
      end

      def output_version_info(status_data)
        puts "Current Leyline Version: #{status_data[:leyline_version]}"
        puts "Base Directory: #{status_data[:base_directory]}"
        puts "Active Categories: #{status_data[:categories].join(', ')}"
      end

      def output_sync_state_info(sync_state)
        puts "Sync State:"

        if sync_state[:exists]
          puts "  ✓ State exists (#{format_age(sync_state[:state_age_seconds])} ago)"
          puts "  Last sync: #{sync_state[:last_sync]}"
          puts "  Synced version: #{sync_state[:synced_version]}"
          puts "  Synced categories: #{sync_state[:synced_categories].join(', ')}"
        else
          puts "  ✗ No sync state found - run 'leyline sync' first"
        end
      end

      def output_local_changes_info(changes)
        puts "Local Changes:"

        if changes[:total_changes] == 0
          puts "  ✓ No local changes detected"
        else
          puts "  #{changes[:total_changes]} change(s) detected:"

          unless changes[:added].empty?
            puts "    Added files (#{changes[:added].size}):"
            changes[:added].first(5).each { |file| puts "      + #{file}" }
            puts "      ... and #{changes[:added].size - 5} more" if changes[:added].size > 5
          end

          unless changes[:modified].empty?
            puts "    Modified files (#{changes[:modified].size}):"
            changes[:modified].first(5).each { |file| puts "      ~ #{file}" }
            puts "      ... and #{changes[:modified].size - 5} more" if changes[:modified].size > 5
          end

          unless changes[:removed].empty?
            puts "    Removed files (#{changes[:removed].size}):"
            changes[:removed].first(5).each { |file| puts "      - #{file}" }
            puts "      ... and #{changes[:removed].size - 5} more" if changes[:removed].size > 5
          end
        end
      end

      def output_file_summary_info(summary)
        puts "File Summary:"
        puts "  Total files: #{summary[:total_files]}"

        unless summary[:by_category].empty?
          puts "  By category:"
          summary[:by_category].each do |category, count|
            puts "    #{category}: #{count} files"
          end
        end

        coverage = summary[:sync_coverage]
        status_icon = case coverage[:status]
                      when 'perfect' then '✓'
                      when 'good' then '○'
                      when 'fair' then '△'
                      else '✗'
                      end

        puts "  Sync coverage: #{status_icon} #{coverage[:percentage]}% (#{coverage[:status]})"
      end

      def output_performance_info(performance)
        puts "Performance:"
        puts "  Execution time: #{performance[:execution_time_ms]}ms"
        puts "  Cache enabled: #{performance[:cache_enabled] ? 'Yes' : 'No'}"
      end

      def format_age(seconds)
        return 'unknown' if seconds.nil?

        if seconds < 60
          "#{seconds.round}s"
        elsif seconds < 3600
          "#{(seconds / 60).round}m"
        elsif seconds < 86400
          "#{(seconds / 3600).round}h"
        else
          "#{(seconds / 86400).round}d"
        end
      end

      def handle_error(error)
        # Convert standard errors to Leyline errors with recovery guidance
        leyline_error = case error
        when Leyline::LeylineError
          error
        when Errno::EACCES, Errno::EPERM
          path = nil
          begin
            path = error.message.match(/- (.+)$/)[1] if error.message
          rescue
            # Ignore extraction errors
          end

          Leyline::FileSystemError.new(
            "Permission denied accessing files",
            reason: :permission_denied,
            path: path
          )
        when Errno::ENOENT
          StatusError.new("Leyline directory not found")
        when Errno::ENOSPC
          Leyline::CacheOperationError.new(
            "No space left on device",
            operation: :disk_full,
            cache_dir: @cache_dir
          )
        when JSON::ParserError
          Leyline::InvalidSyncStateError.new(
            "Sync state file is corrupted",
            file: File.join(@cache_dir, 'sync_state.yaml'),
            platform: detect_platform
          )
        else
          StatusError.new(error.message)
        end

        # Output error with recovery suggestions
        output_error_with_recovery(leyline_error)
      end

      def output_error_with_recovery(error)
        warn "Error: #{error.message}"

        suggestions = error.recovery_suggestions
        if suggestions.any?
          warn "\nTo resolve this issue, try:"
          suggestions.each_with_index do |suggestion, i|
            warn "  #{i + 1}. #{suggestion}"
          end
        end

        if @options[:verbose]
          warn "\nDebug information:"
          warn "  Error type: #{error.error_type}"
          warn "  Context: #{error.context.inspect}" if error.context.any?
          if error.respond_to?(:cause) && error.cause
            warn "  Original error: #{error.cause.class} - #{error.cause.message}"
            warn "  Backtrace:"
            error.cause.backtrace.first(5).each { |line| warn "    #{line}" }
          end
        else
          warn "\nRun with --verbose for more details"
        end
      end

      def detect_platform
        require_relative '../platform_helper'
        if Leyline::PlatformHelper.windows?
          'windows'
        elsif Leyline::PlatformHelper.macos?
          'macos'
        elsif Leyline::PlatformHelper.linux?
          'linux'
        else
          'unknown'
        end
      end
    end
  end
end
