# frozen_string_literal: true

require 'digest'
require_relative 'base_command'
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
    class StatusCommand < BaseCommand
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

      class CommandError < StatusError; end

      # Execute status command and return results
      # Returns hash with status information or nil on error
      def execute
        # Validate path
        if @base_directory.start_with?('-')
          error_and_exit("Invalid path '#{@base_directory}'. Path cannot start with a dash.\nDid you mean to use 'leyline help status' for help?")
        end

        # Validate parent directory exists
        parent_dir = File.dirname(@base_directory)
        unless Dir.exist?(parent_dir)
          error_and_exit("Parent directory does not exist: #{parent_dir}\nPlease ensure the parent directory exists before running this command.")
        end

        begin
          status_data, execution_time_ms = measure_time { gather_status_information }

          status_data[:performance] = {
            execution_time_ms: execution_time_ms,
            cache_enabled: cache_available?
          }

          output_result(status_data)
          status_data
        rescue StandardError => e
          handle_error(e)
          nil
        end
      end

      protected

      # Override BaseCommand's output_human_readable for status-specific formatting
      def output_human_readable(status_data)
        puts 'Leyline Status Report'
        puts '===================='
        puts

        output_version_info(status_data)
        puts

        output_sync_state_info(status_data[:sync_state])
        puts

        output_local_changes_info(status_data[:local_changes])
        puts

        output_file_summary_info(status_data[:file_summary])

        return unless verbose?

        puts
        output_performance_info(status_data[:performance])
      end

      private

      def gather_status_information
        sync_state = SyncState.new(@cache_dir)
        FileComparator.new(cache: file_cache, base_directory: @base_directory)

        # Get current file state
        current_files = discover_current_files

        # Create manifest with relative paths for comparison
        current_manifest = {}
        current_files.each do |relative_path|
          full_path = File.join(leyline_path, relative_path)
          next unless File.exist?(full_path)

          begin
            content = File.read(full_path)
            current_manifest[relative_path] = Digest::SHA256.hexdigest(content)
          rescue Errno::EACCES => e
            # Skip files we can't read but note in verbose mode
            warn "Warning: Cannot read #{relative_path}: #{e.message}" if verbose?
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
            # Handle encoding errors gracefully
            raise Leyline::ComparisonFailedError.new(
              relative_path, nil,
              reason: :encoding_error
            )
          end
        end

        # Compare with saved sync state
        begin
          state_comparison = sync_state.compare_with_current_files(current_manifest)
        rescue StandardError => e
          # If sync state comparison fails, continue with limited information
          warn "Warning: Sync state comparison failed: #{e.message}" if verbose?
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
        return [] unless leyline_exists?

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
          categories << entry if Dir.exist?(category_path)
        end

        categories.sort
      end


      def cache_available?
        !file_cache.nil?
      end

      def output_version_info(status_data)
        puts "Current Leyline Version: #{status_data[:leyline_version]}"
        puts "Base Directory: #{status_data[:base_directory]}"
        puts "Active Categories: #{status_data[:categories].join(', ')}"
      end

      def output_sync_state_info(sync_state)
        puts 'Sync State:'

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
        puts 'Local Changes:'

        if changes[:total_changes] == 0
          puts '  ✓ No local changes detected'
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
        puts 'File Summary:'
        puts "  Total files: #{summary[:total_files]}"

        unless summary[:by_category].empty?
          puts '  By category:'
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
        puts 'Performance:'
        puts "  Execution time: #{performance[:execution_time_ms]}ms"
        puts "  Cache enabled: #{performance[:cache_enabled] ? 'Yes' : 'No'}"
      end

      def format_age(seconds)
        return 'unknown' if seconds.nil?

        if seconds < 60
          "#{seconds.round}s"
        elsif seconds < 3600
          "#{(seconds / 60).round}m"
        elsif seconds < 86_400
          "#{(seconds / 3600).round}h"
        else
          "#{(seconds / 86_400).round}d"
        end
      end
    end
  end
end
