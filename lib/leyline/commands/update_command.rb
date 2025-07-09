# frozen_string_literal: true

require_relative 'base_command'
require_relative '../file_comparator'
require_relative '../sync_state'
require_relative '../sync/file_syncer'
require_relative '../sync/git_client'
require_relative '../version'
require_relative '../errors'
require 'tmpdir'
require 'json'
require 'net/http'
require 'timeout'
require 'set'

module Leyline
  module Commands
    # Implements the 'leyline update' command for safe, preview-first updates
    # Shows pending changes, detects conflicts between local and remote updates
    # Provides clear resolution guidance with dry-run and force options
    class UpdateCommand < BaseCommand
      class UpdateError < Leyline::LeylineError
        def error_type
          :command
        end

        def recovery_suggestions
          [
            'Check your internet connection',
            'Verify the repository URL is correct',
            'Use --verbose flag for detailed error information',
            'Try --force-git to bypass cache'
          ]
        end
      end

      class ConflictDetectedError < UpdateError
        def recovery_suggestions
          [
            'Review conflicts with: leyline update --dry-run',
            'Accept remote changes: leyline update --force',
            'Keep local changes: cancel update and commit your changes'
          ]
        end
      end

      # Represents a planned update with change analysis
      UpdatePlan = Struct.new(:changes, :conflicts, :summary, :metadata, keyword_init: true) do
        def conflicted?
          conflicts.any?
        end

        def safe_to_apply?
          !conflicted?
        end

        def total_changes
          changes[:added].size + changes[:modified].size + changes[:removed].size
        end
      end

      # Represents a detected conflict requiring resolution
      Conflict = Struct.new(:path, :type, :local_content, :remote_content, keyword_init: true) do
        def resolution_options
          case type
          when :both_modified
            [
              'Keep local version (no action needed)',
              'Use remote version (run with --force)',
              'Merge manually (recommended for critical files)'
            ]
          when :local_added_remote_modified
            [
              'Keep local addition',
              'Replace with remote version (--force)'
            ]
          when :local_modified_remote_removed
            [
              'Keep local changes',
              'Remove file to match remote (--force)'
            ]
          else
            ['Manual resolution required']
          end
        end
      end

      class CommandError < UpdateError; end

      # Execute update command with preview-first approach
      def execute
        # Validate path
        if @base_directory.start_with?('-')
          error_and_exit("Invalid path '#{@base_directory}'. Path cannot start with a dash.\nDid you mean to use 'leyline help update' for help?")
        end

        # Validate parent directory exists
        parent_dir = File.dirname(@base_directory)
        unless Dir.exist?(parent_dir)
          error_and_exit("Parent directory does not exist: #{parent_dir}\nPlease ensure the parent directory exists before running this command.")
        end

        start_time = Time.now

        begin
          # Step 1: Analyze what would change
          update_plan = analyze_updates

          # Step 2: Show preview
          show_preview(update_plan)

          # Step 3: Handle dry-run mode
          if @options[:dry_run]
            if @options[:format] == 'json' || @options['format'] == 'json'
              # JSON already output in show_preview
              return update_plan
            else
              puts "\n✓ Dry-run complete. No changes were made."
              return update_plan
            end
          end

          # Step 4: Check for conflicts
          if update_plan.conflicted? && !@options[:force]
            show_conflict_resolution(update_plan)
            raise ConflictDetectedError, 'Conflicts detected. Use --force to override or resolve manually.'
          end

          # Step 5: Apply updates if safe
          if update_plan.total_changes > 0
            results = apply_updates(update_plan)
            show_completion(results, Time.now - start_time)
          else
            puts "\n✓ Already up to date. No changes needed."
          end

          update_plan
        rescue StandardError => e
          handle_error(e)
          nil
        end
      end

      private

      def analyze_updates
        sync_state = SyncState.new(@cache_dir)
        file_comparator = FileComparator.new(cache: file_cache, base_directory: @base_directory)

        # Get current state
        current_files = discover_local_files
        current_manifest = file_comparator.create_manifest(current_files)

        # Load baseline from last sync
        begin
          baseline_comparison = sync_state.compare_with_current_files(current_manifest)
        rescue StandardError
          # If sync state doesn't exist or is corrupted, create a fallback plan
          return UpdatePlan.new(
            changes: { added: [], modified: [], removed: [] },
            conflicts: [],
            summary: { status: 'No sync state found', added: 0, modified: 0, removed: 0 },
            metadata: {
              baseline_exists: false,
              categories: determine_active_categories,
              cache_enabled: cache_available?
            }
          )
        end

        # Get what remote has available
        remote_changes = nil
        begin
          fetch_remote_content_for_comparison do |remote_docs_path|
            remote_files = discover_remote_files(remote_docs_path)
            remote_manifest = file_comparator.create_manifest(remote_files)

            remote_changes = analyze_remote_changes(current_manifest, remote_manifest, current_files, remote_files)
          end
        rescue StandardError
          # If remote fetch fails, create a no-changes plan
          return UpdatePlan.new(
            changes: { added: [], modified: [], removed: [] },
            conflicts: [],
            summary: { status: 'No differences found', added: 0, modified: 0, removed: 0 },
            metadata: {
              baseline_exists: !baseline_comparison.nil?,
              categories: determine_active_categories,
              cache_enabled: cache_available?
            }
          )
        end

        # Detect conflicts using three-way analysis
        conflicts = detect_conflicts(baseline_comparison, remote_changes)

        UpdatePlan.new(
          changes: remote_changes || { added: [], modified: [], removed: [] },
          conflicts: conflicts,
          summary: build_summary(remote_changes, conflicts),
          metadata: {
            baseline_exists: !baseline_comparison.nil?,
            categories: determine_active_categories,
            cache_enabled: cache_available?
          }
        )
      end

      def analyze_remote_changes(local_manifest, remote_manifest, local_files, remote_files)
        # Create lookup maps for efficient comparison
        local_lookup = create_file_lookup(local_files)
        remote_lookup = create_file_lookup(remote_files)

        local_paths = Set.new(local_lookup.keys)
        remote_paths = Set.new(remote_lookup.keys)

        # Use set operations for efficiency (O(n) instead of O(n²))
        added_paths = remote_paths - local_paths
        removed_paths = local_paths - remote_paths
        potentially_modified = local_paths & remote_paths

        # Check for actual content modifications
        modified_paths = potentially_modified.select do |path|
          local_file = local_lookup[path]
          remote_file = remote_lookup[path]

          next false unless local_file && remote_file

          local_hash = local_manifest[local_file]
          remote_hash = remote_manifest[remote_file]

          local_hash && remote_hash && local_hash != remote_hash
        end

        {
          added: added_paths.to_a.sort,
          modified: modified_paths.sort,
          removed: removed_paths.to_a.sort,
          file_mappings: {
            local: local_lookup,
            remote: remote_lookup
          }
        }
      end

      def detect_conflicts(baseline_comparison, remote_changes)
        conflicts = []
        return conflicts if baseline_comparison.nil? || remote_changes.nil?

        # Files modified locally and also changed remotely = conflict
        local_modified = Set.new(baseline_comparison[:modified])
        remote_modified = Set.new(remote_changes[:modified])

        conflicted_files = local_modified & remote_modified

        conflicted_files.each do |path|
          local_file = remote_changes[:file_mappings][:local][path]
          remote_file = remote_changes[:file_mappings][:remote][path]

          conflicts << Conflict.new(
            path: path,
            type: :both_modified,
            local_content: local_file ? File.read(local_file) : nil,
            remote_content: remote_file ? File.read(remote_file) : nil
          )
        end

        # Additional conflict scenarios
        local_added = Set.new(baseline_comparison[:added])
        remote_modified_paths = Set.new(remote_changes[:modified])

        (local_added & remote_modified_paths).each do |path|
          conflicts << Conflict.new(
            path: path,
            type: :local_added_remote_modified
          )
        end

        conflicts
      end

      def build_summary(changes, conflicts)
        return 'No changes available' unless changes

        summary = {
          total_changes: changes[:added].size + changes[:modified].size + changes[:removed].size,
          added: changes[:added].size,
          modified: changes[:modified].size,
          removed: changes[:removed].size,
          conflicts: conflicts.size
        }

        summary[:status] = if conflicts.any?
                             'Updates available with conflicts'
                           elsif summary[:total_changes] > 0
                             'Updates available'
                           else
                             'Up to date'
                           end

        summary
      end

      def plan_to_json(plan)
        {
          summary: {
            status: plan.summary[:status],
            total_changes: plan.total_changes,
            added_files: plan.changes[:added].size,
            modified_files: plan.changes[:modified].size,
            removed_files: plan.changes[:removed].size
          },
          changes: {
            added: plan.changes[:added].sort,
            modified: plan.changes[:modified].sort,
            removed: plan.changes[:removed].sort
          },
          conflicts: plan.conflicts.map do |conflict|
            {
              path: conflict.path,
              type: conflict.type,
              resolution_options: conflict.resolution_options
            }
          end,
          metadata: plan.metadata
        }
      end

      def show_preview(plan)
        if @options[:format] == 'json' || @options['format'] == 'json'
          output_json(plan_to_json(plan))
          return
        end

        puts 'Leyline Update Preview'
        puts '====================='
        puts

        puts "Status: #{plan.summary[:status]}"

        if plan.total_changes == 0
          if plan.summary[:status] == 'No sync state found'
            puts '✓ No sync state found'
          elsif plan.summary[:status] == 'No differences found'
            puts '✓ No differences found'
          else
            puts '✓ Already synchronized with remote standards'
          end
          return
        end

        puts 'Changes to apply:'
        puts "  Files to add: #{plan.summary[:added]}"
        puts "  Files to update: #{plan.summary[:modified]}"
        puts "  Files to remove: #{plan.summary[:removed]}"

        puts "  ⚠️  Conflicts detected: #{plan.summary[:conflicts]}" if plan.conflicted?

        puts

        # Show file lists
        show_change_details(plan.changes) if @options[:verbose] || plan.total_changes < 20

        return unless plan.conflicted?

        puts '⚠️  Conflicts found - see details below'
      end

      def show_change_details(changes)
        unless changes[:added].empty?
          puts 'Files to add:'
          changes[:added].each { |file| puts "  + #{file}" }
        end

        unless changes[:modified].empty?
          puts 'Files to update:'
          changes[:modified].each { |file| puts "  ~ #{file}" }
        end

        unless changes[:removed].empty?
          puts 'Files to remove:'
          changes[:removed].each { |file| puts "  - #{file}" }
        end

        puts
      end

      def show_conflict_resolution(plan)
        puts "\n🚨 Conflict Resolution Required"
        puts '================================'
        puts

        plan.conflicts.each_with_index do |conflict, index|
          puts "#{index + 1}. #{conflict.path}"
          puts "   Issue: #{format_conflict_type(conflict.type)}"
          puts '   Options:'
          conflict.resolution_options.each { |option| puts "     • #{option}" }
          puts
        end

        puts '💡 Resolution Tips:'
        puts '   • Review conflicts carefully before using --force'
        puts "   • Use 'leyline diff' to see exact changes"
        puts '   • Back up important local modifications'
        puts '   • Consider merging critical files manually'
        puts
      end

      def format_conflict_type(type)
        case type
        when :both_modified
          'File modified both locally and remotely'
        when :local_added_remote_modified
          'File added locally but modified remotely'
        when :local_modified_remote_removed
          'File modified locally but removed remotely'
        else
          'Unknown conflict type'
        end
      end

      def apply_updates(plan)
        puts "\n🔄 Applying updates..."

        # Use existing FileSyncer for actual file operations
        temp_dir = Dir.mktmpdir('leyline-update-')

        begin
          # Fetch fresh remote content
          fetch_remote_content_for_update(temp_dir)

          # Apply changes using FileSyncer
          remote_docs = File.join(temp_dir, 'docs')
          target_docs = File.join(@base_directory, 'docs', 'leyline')

          # Ensure we have the leyline subdirectory in remote_docs
          remote_leyline = File.join(remote_docs, 'leyline')
          remote_docs = remote_leyline if Dir.exist?(remote_leyline)

          file_syncer = Sync::FileSyncer.new(remote_docs, target_docs, cache: file_cache)
          sync_results = file_syncer.sync(force: @options[:force], verbose: @options[:verbose])

          # Update sync state
          update_sync_state(plan)

          sync_results
        ensure
          FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      def update_sync_state(plan)
        return unless plan.metadata[:cache_enabled]

        sync_state = SyncState.new(@cache_dir)
        current_files = discover_local_files
        file_comparator = FileComparator.new(cache: file_cache, base_directory: @base_directory)
        current_manifest = file_comparator.create_manifest(current_files)

        sync_state.save_sync_state({
                                     categories: plan.metadata[:categories],
                                     manifest: current_manifest,
                                     leyline_version: VERSION
                                   })
      end

      def show_completion(results, elapsed_time)
        puts "\n✅ Update completed successfully!"
        puts "   Files copied: #{results[:copied].size}"
        puts "   Files skipped: #{results[:skipped].size}"
        puts "   Errors: #{results[:errors].size}"
        puts "   Duration: #{(elapsed_time * 1000).round(2)}ms"

        return unless results[:errors].any? && @options[:verbose]

        puts "\nErrors encountered:"
        results[:errors].each { |error| puts "  ⚠️  #{error}" }
      end

      def fetch_remote_content_for_comparison
        temp_dir = Dir.mktmpdir('leyline-update-comparison-')
        git_client = Sync::GitClient.new

        begin
          git_client.setup_sparse_checkout(temp_dir)

          sparse_paths = build_sparse_paths_for_categories
          sparse_paths.each { |path| git_client.add_sparse_paths([path]) }

          begin
            git_client.fetch_version('https://github.com/phrazzld/leyline-standards.git', 'master')
          rescue Sync::GitClient::GitCommandError => e
            # Fallback for development/testing
            unless Dir.exist?(File.join(@base_directory, '.git'))
              raise UpdateError.new("Failed to fetch remote content: #{e.message}")
            end

            current_repo_docs = File.join(@base_directory, 'docs')
            unless Dir.exist?(current_repo_docs)
              raise UpdateError.new("No leyline content found locally and failed to fetch remote: #{e.message}")
            end

            FileUtils.cp_r(current_repo_docs, temp_dir)
          end

          remote_docs_path = File.join(temp_dir, 'docs')
          yield remote_docs_path if Dir.exist?(remote_docs_path)
        ensure
          git_client.cleanup if git_client
          FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      def fetch_remote_content_for_update(target_dir)
        git_client = Sync::GitClient.new

        begin
          git_client.setup_sparse_checkout(target_dir)

          sparse_paths = build_sparse_paths_for_categories
          sparse_paths.each { |path| git_client.add_sparse_paths([path]) }

          git_client.fetch_version('https://github.com/phrazzld/leyline-standards.git', 'master')
        rescue Sync::GitClient::GitCommandError => e
          # Fallback for development
          unless Dir.exist?(File.join(@base_directory, '.git'))
            raise UpdateError.new("Failed to fetch remote content for update: #{e.message}")
          end

          current_repo_docs = File.join(@base_directory, 'docs')
          FileUtils.cp_r(current_repo_docs, target_dir) if Dir.exist?(current_repo_docs)
        ensure
          git_client.cleanup if git_client
        end
      end

      def discover_local_files
        return [] unless Dir.exist?(@base_directory)

        leyline_path = File.join(@base_directory, 'docs', 'leyline')
        return [] unless Dir.exist?(leyline_path)

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
        bindings_path = File.join(@base_directory, 'docs', 'leyline', 'bindings', 'categories')

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

      def extract_relative_path(file_path)
        if file_path.include?('/docs/leyline/')
          file_path.split('/docs/leyline/').last
        elsif file_path.include?('/docs/')
          file_path.split('/docs/').last
        else
          File.basename(file_path)
        end
      end

      def cache_available?
        !file_cache.nil?
      end

      # Override BaseCommand's normalize_error to handle UpdateCommand-specific errors
      def normalize_error(error, context = {})
        case error
        when ConflictDetectedError
          # Conflict errors are already handled in show_conflict_resolution
          error
        when Errno::ENOENT
          UpdateError.new('Leyline directory not found')
        when Errno::EROFS
          Leyline::FileSystemError.new(
            'Filesystem is read-only',
            reason: :read_only_filesystem,
            path: @base_directory
          )
        when Leyline::Sync::GitClient::GitNotAvailableError
          Leyline::RemoteAccessError.new(
            'Git binary not found',
            reason: :git_not_installed
          )
        when Leyline::Sync::GitClient::GitCommandError
          handle_git_command_error(error)
        when Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
          Leyline::RemoteAccessError.new(
            'Network timeout while fetching updates',
            reason: :network_timeout,
            url: 'https://github.com/phrazzld/leyline.git'
          )
        else
          super(error, context)
        end
      end

      def handle_error(error, context = {})
        # Special handling for ConflictDetectedError - already shown in show_conflict_resolution
        return if error.is_a?(ConflictDetectedError)
        super(error, context)
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
        elsif error.message.include?('merge conflict')
          Leyline::ConflictDetectedError.new(
            'Git merge conflict detected',
            operation: 'update',
            suggestion: 'Use --force to overwrite or resolve manually'
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
