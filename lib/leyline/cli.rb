# frozen_string_literal: true

require 'thor'
require 'tmpdir'
require_relative 'version'
require_relative 'cli/options'
require_relative 'sync/git_client'
require_relative 'sync/file_syncer'

module Leyline
  class CLI < Thor
    package_name 'leyline'

    desc 'version', 'Show version information'
    def version
      puts VERSION
    end

    desc 'sync [PATH]', 'Synchronize leyline standards to target directory'
    method_option :categories,
                  type: :array,
                  desc: 'Specific categories to sync (e.g., typescript, go, core)',
                  aliases: '-c'
    method_option :force,
                  type: :boolean,
                  desc: 'Overwrite local modifications without confirmation',
                  aliases: '-f'
    method_option :dry_run,
                  type: :boolean,
                  desc: 'Show what would be synced without making changes',
                  aliases: '-n'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed output',
                  aliases: '-v'
    def sync(path = '.')
      # Validate options before proceeding
      begin
        CliOptions.validate_sync_options(options, path)
      rescue CliOptions::ValidationError => e
        puts "Error: #{e.message}"
        exit 1
      end

      target_path = File.expand_path(path)
      puts "Synchronizing leyline standards to: #{File.join(target_path, 'docs', 'leyline')}"

      # Use explicit categories or default to 'core'
      categories = options[:categories] || ['core']
      normalized_categories = CliOptions.normalize_categories(categories) || ['core']

      puts "Categories: #{normalized_categories.join(', ')}" unless normalized_categories.empty?
      puts "Options: #{options.select { |k, v| v }.keys.join(', ')}" if options.any? { |_, v| v }

      # Perform the actual sync
      begin
        perform_sync(target_path, normalized_categories, options)
      rescue => e
        puts "Error during sync: #{e.message}"
        exit 1
      end
    end

    default_task :sync

    private

    def perform_sync(target_path, categories, options)
      force = options[:force] || false
      verbose = options[:verbose] || false

      # Create temp directory for git operations
      temp_dir = Dir.mktmpdir('leyline-sync-')
      git_client = Sync::GitClient.new

      begin
        puts "Fetching leyline standards..." if verbose

        # Set up git sparse-checkout
        git_client.setup_sparse_checkout(temp_dir)

        # Determine sparse paths based on categories
        sparse_paths = build_sparse_paths(categories)
        git_client.add_sparse_paths(sparse_paths)

        # Fetch from leyline repository
        remote_url = 'https://github.com/phrazzld/leyline.git'
        git_client.fetch_version(remote_url, 'master')

        puts "Copying files to #{File.join(target_path, 'docs', 'leyline')}..." if verbose

        # Sync files to target directory under docs/leyline
        leyline_target = File.join(target_path, 'docs', 'leyline')
        file_syncer = Sync::FileSyncer.new(temp_dir, leyline_target)
        results = file_syncer.sync(force: force)

        # Report results
        report_sync_results(results, verbose)

      ensure
        # Clean up temp directory
        git_client.cleanup if git_client
      end
    end

    def build_sparse_paths(categories)
      paths = []

      # Always include tenets
      paths << 'docs/tenets/'

      categories.each do |category|
        if category == 'core'
          paths << 'docs/bindings/core/'
        else
          paths << "docs/bindings/categories/#{category}/"
        end
      end

      paths
    end

    def report_sync_results(results, verbose)
      copied_count = results[:copied].length
      skipped_count = results[:skipped].length
      error_count = results[:errors].length

      puts "Sync completed: #{copied_count} files copied, #{skipped_count} files skipped"

      if error_count > 0
        puts "#{error_count} errors occurred during sync"
      end

      if verbose && copied_count > 0
        puts "\nCopied files:"
        results[:copied].each { |file| puts "  + #{file}" }
      end

      if verbose && skipped_count > 0
        puts "\nSkipped files (use --force to overwrite):"
        results[:skipped].each { |file| puts "  - #{file}" }
      end

      if error_count > 0
        puts "\nErrors:"
        results[:errors].each { |error| puts "  ! #{error[:file]}: #{error[:error]}" }
      end
    end
  end
end
