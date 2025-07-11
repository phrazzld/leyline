# frozen_string_literal: true

require_relative 'base_command'
require_relative '../file_comparator'
require_relative '../sync/git_client'
require_relative '../version'
require_relative '../errors'
require 'tmpdir'
require 'json'
require 'net/http'
require 'timeout'

module Leyline
  module Commands
    # Implements the 'leyline diff' command to show what would change without syncing
    # Generates unified diff format output with file additions/deletions/modifications
    # Supports category filtering and format options (text, json)
    class DiffCommand < BaseCommand
      class DiffError < Leyline::LeylineError
        def error_type
          :command
        end

        def recovery_suggestions
          [
            'Run leyline sync first to establish baseline',
            'Check if files exist in docs/leyline directory',
            'Use --verbose flag for detailed error information'
          ]
        end
      end

      class CommandError < DiffError; end

      # Execute diff command and return results
      # Returns hash with diff information or nil on error
      def execute
        # Validate path
        if @base_directory.start_with?('-')
          error_and_exit("Invalid path '#{@base_directory}'. Path cannot start with a dash.\nDid you mean to use 'leyline help diff' for help?")
        end

        # Validate parent directory exists
        parent_dir = File.dirname(@base_directory)
        unless Dir.exist?(parent_dir)
          error_and_exit("Parent directory does not exist: #{parent_dir}\nPlease ensure the parent directory exists before running this command.")
        end

        begin
          diff_data, execution_time_ms = measure_time { gather_diff_information }

          diff_data[:performance] = {
            execution_time_ms: execution_time_ms,
            cache_enabled: cache_available?
          }

          if @options[:format] == 'json' || @options['format'] == 'json'
            output_json(diff_data)
          else
            output_unified_diff(diff_data)
          end

          diff_data
        rescue StandardError => e
          # For critical errors that can't be handled gracefully, still use handle_error
          handle_error(e)
          nil
        end
      end

      private

      def gather_diff_information
        file_comparator = FileComparator.new(cache: file_cache, base_directory: @base_directory)

        # Get current local files
        begin
          local_files = discover_local_files
        rescue Errno::ENOENT
          # Handle missing leyline directory gracefully
          raise DiffError.new(
            'No leyline directory found to compare',
            context: {
              path: leyline_path,
              suggestion: 'Run leyline sync first'
            }
          )
        end

        local_manifest = file_comparator.create_manifest(local_files)

        # Get remote content through temporary git checkout
        diff_results = nil
        begin
          fetch_remote_content_for_diff do |remote_docs_path|
            remote_files = discover_remote_files(remote_docs_path)
            remote_manifest = file_comparator.create_manifest(remote_files)

            # Compare local vs remote
            comparison_result = compare_manifests(local_manifest, remote_manifest, local_files, remote_files)

            # Generate unified diffs for modified files
            unified_diffs = generate_unified_diffs(comparison_result[:modified_files], local_files, remote_files)

            diff_results = {
              summary: {
                total_changes: comparison_result[:added].size + comparison_result[:modified].size + comparison_result[:removed].size,
                added_files: comparison_result[:added].size,
                modified_files: comparison_result[:modified].size,
                removed_files: comparison_result[:removed].size
              },
              changes: {
                added: comparison_result[:added].sort,
                modified: comparison_result[:modified].sort,
                removed: comparison_result[:removed].sort
              },
              unified_diffs: unified_diffs,
              categories: determine_active_categories,
              base_directory: @base_directory
            }
          end
        rescue Interrupt
          # Handle user interruption gracefully
          raise Leyline::LeylineError.new(
            'Diff operation cancelled by user',
            signal: 'SIGINT'
          )
        rescue DiffError => e
          # Handle diff errors gracefully by providing a fallback result
          diff_results = {
            summary: {
              total_changes: 0,
              added_files: 0,
              modified_files: 0,
              removed_files: 0
            },
            changes: {
              added: [],
              modified: [],
              removed: []
            },
            unified_diffs: {},
            categories: determine_active_categories,
            base_directory: @base_directory,
            error: e.message
          }
        end

        # If diff_results is still nil, provide a default fallback
        diff_results ||= {
          summary: {
            total_changes: 0,
            added_files: 0,
            modified_files: 0,
            removed_files: 0
          },
          changes: {
            added: [],
            modified: [],
            removed: []
          },
          unified_diffs: {},
          categories: determine_active_categories,
          base_directory: @base_directory,
          error: 'No sync state found'
        }

        diff_results
      end

      def fetch_remote_content_for_diff
        temp_dir = Dir.mktmpdir('leyline-diff-')
        git_client = Sync::GitClient.new

        begin
          # Setup sparse checkout for performance
          git_client.setup_sparse_checkout(temp_dir)

          # Add paths for requested categories
          sparse_paths = build_sparse_paths_for_categories
          sparse_paths.each { |path| git_client.add_sparse_paths([path]) }

          # Fetch content (using existing GitClient patterns)
          # For development/testing, use current repository if standards repo not available
          begin
            git_client.fetch_version('https://github.com/phrazzld/leyline-standards.git', 'master')
          rescue Sync::GitClient::GitCommandError => e
            # Fallback: use current repository's content for testing
            unless Dir.exist?(File.join(@base_directory, '.git'))
              raise DiffError.new("No sync state found")
            end

            current_repo_docs = File.join(@base_directory, 'docs')
            unless Dir.exist?(current_repo_docs)
              raise DiffError.new("No sync state found")
            end

            FileUtils.cp_r(current_repo_docs, temp_dir)
          end

          remote_docs_path = File.join(temp_dir, 'docs')
          yield remote_docs_path if Dir.exist?(remote_docs_path)
        rescue Sync::GitClient::GitNotAvailableError
          raise DiffError.new("Git is required for diff operations. Please install git and ensure it's in your PATH.")
        rescue Sync::GitClient::GitCommandError => e
          raise DiffError.new("Failed to fetch remote content: #{e.message}")
        ensure
          git_client.cleanup if git_client
          FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      def compare_manifests(local_manifest, remote_manifest, local_files, remote_files)
        # Create lookup maps for file path resolution
        local_lookup = create_file_lookup(local_files)
        remote_lookup = create_file_lookup(remote_files)

        # Find differences using relative paths
        local_relative = extract_relative_paths(local_lookup)
        remote_relative = extract_relative_paths(remote_lookup)

        added = remote_relative - local_relative
        removed = local_relative - remote_relative
        potentially_modified = local_relative & remote_relative

        # Check for actual modifications using file content hashes
        modified = []
        potentially_modified.each do |relative_path|
          local_file = local_lookup[relative_path]
          remote_file = remote_lookup[relative_path]

          next unless local_file && remote_file

          local_hash = local_manifest[local_file]
          remote_hash = remote_manifest[remote_file]

          modified << relative_path if local_hash && remote_hash && local_hash != remote_hash
        end

        {
          added: added,
          removed: removed,
          modified: modified,
          modified_files: build_modified_files_map(modified, local_lookup, remote_lookup)
        }
      end

      def generate_unified_diffs(modified_files, _local_files, _remote_files)
        diffs = {}

        modified_files.each do |relative_path, file_pair|
          local_file = file_pair[:local]
          remote_file = file_pair[:remote]

          next unless File.exist?(local_file) && File.exist?(remote_file)

          begin
            unified_diff = create_unified_diff(local_file, remote_file, relative_path)
            diffs[relative_path] = unified_diff if unified_diff
          rescue StandardError => e
            warn "Warning: Could not generate diff for #{relative_path}: #{e.message}" if verbose?
          end
        end

        diffs
      end

      def create_unified_diff(local_file, remote_file, relative_path)
        local_content = File.read(local_file)
        remote_content = File.read(remote_file)

        # Quick check - if content is identical, no diff needed
        return nil if local_content == remote_content

        local_lines = local_content.lines
        remote_lines = remote_content.lines

        # Generate unified diff using simple algorithm
        diff_lines = []
        diff_lines << "--- a/#{relative_path}"
        diff_lines << "+++ b/#{relative_path}"

        # Simple line-by-line diff for MVP
        # In a full implementation, would use proper LCS algorithm
        max_lines = [local_lines.size, remote_lines.size].max
        hunk_start = nil
        hunk_lines = []

        (0...max_lines).each do |i|
          local_line = local_lines[i]
          remote_line = remote_lines[i]

          if local_line != remote_line
            hunk_start ||= i

            hunk_lines << "-#{local_line.chomp}" if local_line
            hunk_lines << "+#{remote_line.chomp}" if remote_line
          elsif hunk_start && hunk_lines.any?
            # End of hunk - add header and lines
            diff_lines << "@@ -#{hunk_start + 1},#{hunk_lines.count do |l|
              l.start_with?('-')
            end} +#{hunk_start + 1},#{hunk_lines.count do |l|
                                      l.start_with?('+')
                                    end} @@"
            diff_lines.concat(hunk_lines)

            hunk_start = nil
            hunk_lines = []
          end
        end

        # Add final hunk if needed
        if hunk_start && hunk_lines.any?
          diff_lines << "@@ -#{hunk_start + 1},#{hunk_lines.count do |l|
            l.start_with?('-')
          end} +#{hunk_start + 1},#{hunk_lines.count do |l|
                                    l.start_with?('+')
                                  end} @@"
          diff_lines.concat(hunk_lines)
        end

        diff_lines.join("\n")
      end

      def discover_local_files
        return [] unless Dir.exist?(@base_directory)
        return [] unless leyline_exists?

        files = []
        categories = determine_active_categories

        patterns = build_search_patterns(categories)
        patterns.each do |pattern|
          search_path = File.join(leyline_path, pattern)
          Dir.glob(search_path).each do |file_path|
            next unless File.file?(file_path)

            files << file_path
          end
        end

        files.sort
      end

      def discover_remote_files(remote_docs_path)
        return [] unless Dir.exist?(remote_docs_path)

        files = []
        categories = determine_active_categories

        patterns = build_search_patterns(categories)
        patterns.each do |pattern|
          search_path = File.join(remote_docs_path, pattern)
          Dir.glob(search_path).each do |file_path|
            next unless File.file?(file_path)

            files << file_path
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

      def build_sparse_paths_for_categories
        categories = determine_active_categories
        paths = ['docs/tenets/', 'docs/bindings/core/']

        categories.each do |category|
          next if category == 'core'

          paths << "docs/bindings/categories/#{category}/"
        end

        paths
      end

      def determine_active_categories
        if @options[:categories]
          Array(@options[:categories])
        else
          discover_categories_from_files
        end
      end

      def discover_categories_from_files
        categories = ['core']
        bindings_path = File.join(leyline_path, 'bindings', 'categories')

        return categories unless Dir.exist?(bindings_path)

        Dir.entries(bindings_path).each do |entry|
          next if entry.start_with?('.')

          category_path = File.join(bindings_path, entry)
          categories << entry if Dir.exist?(category_path)
        end

        categories.sort
      end

      def create_file_lookup(files)
        lookup = {}
        files.each do |file_path|
          relative_path = extract_relative_path(file_path)
          lookup[relative_path] = file_path
        end
        lookup
      end

      def extract_relative_paths(file_lookup)
        file_lookup.keys
      end

      def extract_relative_path(file_path)
        # Extract path relative to docs/leyline or docs
        if file_path.include?('/docs/leyline/')
          file_path.split('/docs/leyline/').last
        elsif file_path.include?('/docs/')
          file_path.split('/docs/').last
        else
          File.basename(file_path)
        end
      end

      def build_modified_files_map(modified_relative_paths, local_lookup, remote_lookup)
        map = {}
        modified_relative_paths.each do |relative_path|
          map[relative_path] = {
            local: local_lookup[relative_path],
            remote: remote_lookup[relative_path]
          }
        end
        map
      end

      def cache_available?
        !file_cache.nil?
      end

      def output_unified_diff(diff_data)
        # Handle error cases
        if diff_data[:error]
          puts diff_data[:error]
          return
        end

        puts 'Leyline Diff Report'
        puts '=================='
        puts

        summary = diff_data[:summary]
        if summary[:total_changes] == 0
          puts 'No differences found'
          return
        end

        output_summary(summary, diff_data[:changes])
        puts

        output_file_changes(diff_data[:changes])

        return unless diff_data[:unified_diffs].any? && verbose?

        puts
        output_detailed_diffs(diff_data[:unified_diffs])
      end

      def output_summary(summary, _changes)
        puts "Summary: #{summary[:total_changes]} change(s) detected"
        puts "  Added files: #{summary[:added_files]}"
        puts "  Modified files: #{summary[:modified_files]}"
        puts "  Removed files: #{summary[:removed_files]}"
      end

      def output_file_changes(changes)
        unless changes[:added].empty?
          puts 'Added files:'
          changes[:added].each { |file| puts "  + #{file}" }
        end

        unless changes[:modified].empty?
          puts 'Modified files:'
          changes[:modified].each { |file| puts "  ~ #{file}" }
        end

        return if changes[:removed].empty?

        puts 'Removed files:'
        changes[:removed].each { |file| puts "  - #{file}" }
      end

      def output_detailed_diffs(unified_diffs)
        puts 'Detailed Diffs:'
        puts '==============='

        unified_diffs.each do |relative_path, diff_content|
          puts
          puts "diff --git a/#{relative_path} b/#{relative_path}"
          puts diff_content
        end
      end

      # Override BaseCommand's normalize_error to handle DiffCommand-specific errors
      def normalize_error(error, context = {})
        case error
        when Leyline::Sync::GitClient::GitNotAvailableError
          Leyline::RemoteAccessError.new(
            'Git binary not found',
            reason: :git_not_installed
          )
        when Leyline::Sync::GitClient::GitCommandError
          handle_git_command_error(error)
        when Net::OpenTimeout, Net::ReadTimeout
          Leyline::RemoteAccessError.new(
            'Network timeout while fetching remote content',
            reason: :network_timeout,
            url: 'https://github.com/phrazzld/leyline.git'
          )
        else
          super(error, context)
        end
      end

      def handle_git_command_error(error)
        if error.message.include?('authentication')
          Leyline::RemoteAccessError.new(
            'Git authentication failed',
            reason: :authentication_failed,
            repository: 'phrazzld/leyline'
          )
        elsif error.message.include?('could not resolve host')
          Leyline::RemoteAccessError.new(
            'Cannot reach GitHub - check network connection',
            reason: :network_timeout
          )
        elsif error.message.include?('repository not found')
          Leyline::RemoteAccessError.new(
            'Leyline repository not accessible',
            reason: :repository_not_found
          )
        else
          Leyline::GitError.new(
            "Git operation failed: #{error.message}",
            command: error.context[:command],
            exit_status: error.context[:exit_status]
          )
        end
      end

    end
  end
end
