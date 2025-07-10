# frozen_string_literal: true

require 'tmpdir'
require 'digest'
require_relative 'base_command'
require_relative 'helpers/shared_helpers'
require_relative '../sync/git_client'
require_relative '../sync/file_syncer'
require_relative '../sync_state'
require_relative '../cache/file_cache'
require_relative '../cache/cache_stats'
require_relative '../cli/options'
require_relative '../configuration/leyline_file'
require_relative '../version'

module Leyline
  module Commands
    class SyncCommand < BaseCommand
      include Helpers::SharedHelpers

      def initialize(options)
        super
        @path = options[:path] || '.'
        @verbose = options[:verbose] || false
        @dry_run = options[:dry_run] || false
        @no_cache = options[:no_cache] || false
        @force_git = options[:force_git] || false
        @show_stats = options[:stats] || false

        # Load .leyline file configuration
        @leyline_config = Configuration::LeylineFile.load(@path)

        # Categories from command line override .leyline file
        # Thor uses string keys, not symbols
        @categories = if @options['categories'] && !@options['categories'].empty?
                        @options['categories']
                      elsif @leyline_config && @leyline_config.valid?
                        @leyline_config.categories
                      else
                        ['core']
                      end
      end

      def execute
        # Validate path to prevent accidental flag-like directory creation
        if @path.start_with?('-')
          error_and_exit("Invalid path '#{@path}'. Path cannot start with a dash.\nDid you mean to use 'leyline help sync' for help?")
        end

        # Pre-process categories to handle comma-separated values
        # Use @categories which already has the right value from initialize
        processed_categories = preprocess_categories(@categories)

        # Validate options before proceeding
        begin
          CliOptions.validate_sync_options(
            { categories: processed_categories, dry_run: @dry_run },
            @path
          )
        rescue CliOptions::ValidationError => e
          error_and_exit(e.message)
        end

        target_path = File.expand_path(@path)

        # Validate parent directory exists
        parent_dir = File.dirname(target_path)
        unless Dir.exist?(parent_dir)
          error_and_exit("Error: Parent directory does not exist: #{parent_dir}\nPlease ensure the parent directory exists before running this command.")
        end

        puts "Synchronizing leyline standards to: #{File.join(target_path, 'docs', 'leyline')}"

        # Use explicit categories or default to 'core'
        normalized_categories = CliOptions.normalize_categories(processed_categories) || ['core']

        puts "Categories: #{normalized_categories.join(', ')}" unless normalized_categories.empty?

        # Show if categories came from .leyline file
        if @leyline_config && @leyline_config.valid? && (!@options['categories'] || @options['categories'].empty?)
          puts '  (from .leyline file)'
        end

        display_active_options

        # Perform the actual sync
        begin
          perform_sync(target_path, normalized_categories)
        rescue StandardError => e
          error_and_exit("Error during sync: #{e.message}")
        end
      end

      private

      def preprocess_categories(categories)
        # Handle comma-separated values
        if categories.is_a?(Array) && categories.length == 1 && categories.first.include?(',')
          categories.first.split(',').map(&:strip)
        else
          categories
        end
      end

      def display_active_options
        active_options = []
        active_options << 'categories' if @options['categories'] && !@options['categories'].empty?
        active_options << 'dry_run' if @dry_run
        active_options << 'verbose' if @verbose
        active_options << 'no_cache' if @no_cache
        active_options << 'force_git' if @force_git
        active_options << 'stats' if @show_stats

        puts "Options: #{active_options.join(', ')}" unless active_options.empty?
      end

      def perform_sync(target_path, categories)
        # Create cache unless disabled
        cache = create_cache unless @no_cache

        # Create stats tracker
        stats = @show_stats ? Cache::CacheStats.new : nil

        # Target directory for leyline content
        leyline_target = File.join(target_path, 'docs', 'leyline')

        # Always fetch from git to temp directory
        # FileSyncer will handle cache optimization during sync
        temp_dir = Dir.mktmpdir('leyline-sync-')
        git_client = Sync::GitClient.new

        begin
          puts 'Fetching leyline standards...' if @verbose

          # Set up git sparse-checkout
          git_client.setup_sparse_checkout(temp_dir)

          # Determine sparse paths based on categories
          sparse_paths = build_sparse_paths(categories)
          git_client.add_sparse_paths(sparse_paths)

          # Fetch from leyline repository
          remote_url = 'https://github.com/phrazzld/leyline.git'
          git_client.fetch_version(remote_url, 'master')

          # Point to the docs subdirectory in temp_dir to avoid double nesting
          source_docs_dir = File.join(temp_dir, 'docs')
        rescue StandardError => e
          # Clean up and re-raise git errors
          git_client&.cleanup
          raise e
        end

        begin
          puts "Copying files to #{leyline_target}..." if @verbose

          # Sync files to target directory under docs/leyline
          # Always rebuild - sync command always overwrites
          file_syncer = Sync::FileSyncer.new(source_docs_dir, leyline_target, cache: cache, stats: stats)
          results = file_syncer.sync(force: true, force_git: @force_git, verbose: @verbose)

          # Report results
          report_sync_results(results, stats: stats, cache: cache)

          # Save sync state for status/diff/update commands
          save_sync_state(leyline_target, categories, cache) if results[:errors].empty?
        ensure
          # Clean up temp directory
          git_client&.cleanup if temp_dir
        end
      end

      def create_cache
        cache = Cache::FileCache.new

        # Check cache health on verbose mode
        if @verbose && cache
          health = cache.health_status
          unless health[:healthy]
            puts 'Warning: Cache health issues detected:'
            health[:issues].each do |issue|
              puts "  - #{issue[:type]}: #{issue[:path] || issue[:error]}"
            end
          end
        end

        cache
      rescue StandardError => e
        # Log cache initialization failure but continue without cache
        puts "Warning: Cache initialization failed: #{e.message}" if @verbose
        puts 'Continuing without cache optimization...' if @verbose
        nil
      end

      def build_sparse_paths(categories)
        paths = []

        # Always include tenets and core bindings
        paths << 'docs/tenets/'
        paths << 'docs/bindings/core/'

        # Add category-specific bindings
        categories.each do |category|
          unless category == 'core' # Skip core since we always include it above
            paths << "docs/bindings/categories/#{category}/"
          end
        end

        paths
      end

      def report_sync_results(results, stats: nil, cache: nil)
        copied_count = results[:copied].length
        skipped_count = results[:skipped].length
        error_count = results[:errors].length

        puts "Sync completed: #{copied_count} files copied, #{skipped_count} files skipped"

        puts "#{error_count} errors occurred during sync" if error_count > 0

        if @verbose && copied_count > 0
          puts "\nCopied files:"
          results[:copied].each { |file| puts "  + #{file}" }
        end

        if @verbose && skipped_count > 0
          puts "\nSkipped files (use --force to overwrite):"
          results[:skipped].each { |file| puts "  - #{file}" }
        end

        if error_count > 0
          puts "\nErrors:"
          results[:errors].each { |error| puts "  ! #{error[:file]}: #{error[:error]}" }
        end

        # Display cache statistics if requested
        return unless stats

        puts "\n" + '=' * 50
        puts 'CACHE STATISTICS'
        puts '=' * 50

        cache_directory_stats = cache&.directory_stats || {}
        puts stats.format_stats(cache_directory_stats)
      end

      def save_sync_state(leyline_target, categories, _cache)
        # Save sync state for future status/diff/update commands
        cache_dir = ENV['LEYLINE_CACHE_DIR'] || File.expand_path('~/.cache/leyline')
        cache_dir = File.expand_path(cache_dir)
        sync_state = SyncState.new(cache_dir)

        # Build manifest of synced files
        manifest = {}
        Dir.glob(File.join(leyline_target, '**', '*.md')).each do |file|
          relative_path = file.sub("#{leyline_target}/", '')
          content = File.read(file)
          manifest[relative_path] = Digest::SHA256.hexdigest(content)
        end

        # Save state with current timestamp and version
        sync_state.save_sync_state({
                                     categories: categories,
                                     manifest: manifest,
                                     leyline_version: VERSION,
                                     timestamp: Time.now.to_s
                                   })
      end
    end
  end
end
