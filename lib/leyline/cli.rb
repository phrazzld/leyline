# frozen_string_literal: true

require 'thor'
require 'tmpdir'
require_relative 'version'
require_relative 'cli/options'
require_relative 'sync/git_client'
require_relative 'sync/file_syncer'
require_relative 'cache/file_cache'
require_relative 'cache/cache_stats'
require_relative 'discovery/metadata_cache'
require_relative 'discovery/document_scanner'

module Leyline
  class CLI < Thor
    package_name 'leyline'

    desc 'version', 'Show version information'
    def version
      puts VERSION
    end

    desc 'categories', 'List all available leyline categories'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed category information',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    def categories
      perform_discovery_command(:categories, options)
    end

    desc 'show CATEGORY', 'Show documents in a specific category'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed document information',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    def show(category)
      perform_discovery_command(:show, options.merge(category: category))
    end

    desc 'search QUERY', 'Search leyline documents by content'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed search results',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :limit,
                  type: :numeric,
                  desc: 'Maximum number of results to show',
                  default: 10,
                  aliases: '-l'
    def search(query)
      perform_discovery_command(:search, options.merge(query: query))
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
    method_option :no_cache,
                  type: :boolean,
                  desc: 'Bypass cache and fetch fresh content',
                  aliases: '--no-cache'
    method_option :force_git,
                  type: :boolean,
                  desc: 'Force git operations even when cache is sufficient',
                  aliases: '--force-git'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show detailed cache and performance statistics',
                  aliases: '--stats'
    def sync(path = '.')
      # Pre-process categories to handle comma-separated values
      processed_options = options.dup
      if processed_options[:categories].is_a?(Array) &&
         processed_options[:categories].length == 1 &&
         processed_options[:categories].first.include?(',')
        processed_options[:categories] = processed_options[:categories].first.split(',').map(&:strip)
      end

      # Validate options before proceeding
      begin
        CliOptions.validate_sync_options(processed_options, path)
      rescue CliOptions::ValidationError => e
        puts "Error: #{e.message}"
        exit 1
      end

      target_path = File.expand_path(path)
      puts "Synchronizing leyline standards to: #{File.join(target_path, 'docs', 'leyline')}"

      # Use explicit categories or default to 'core'
      categories = processed_options[:categories] || ['core']
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

    def perform_discovery_command(command, options)
      start_time = Time.now
      verbose = options[:verbose] || false
      show_stats = options[:stats] || false

      begin
        # Initialize cache infrastructure
        file_cache = create_file_cache_if_needed(verbose)
        metadata_cache = Discovery::MetadataCache.new(file_cache: file_cache)

        # Execute the specific discovery command
        case command
        when :categories
          execute_categories_command(metadata_cache, options)
        when :show
          execute_show_command(metadata_cache, options)
        when :search
          execute_search_command(metadata_cache, options)
        else
          puts "Unknown discovery command: #{command}"
          exit 1
        end

        # Show performance statistics if requested
        if show_stats
          display_discovery_stats(metadata_cache, start_time)
        end

      rescue => e
        puts "Error during #{command}: #{e.message}"
        puts e.backtrace if verbose
        exit 1
      end
    end

    def execute_categories_command(metadata_cache, options)
      verbose = options[:verbose] || false
      categories = metadata_cache.categories

      if categories.empty?
        puts "No categories found."
        return
      end

      puts "Available Categories (#{categories.length}):"
      puts

      categories.each do |category|
        documents = metadata_cache.documents_for_category(category)

        if verbose
          puts "#{category} (#{documents.length} documents)"
          documents.each do |doc|
            puts "  - #{doc[:title]} (#{doc[:id]})"
          end
          puts
        else
          puts "  #{category} (#{documents.length} documents)"
        end
      end
    end

    def execute_show_command(metadata_cache, options)
      category = options[:category]
      verbose = options[:verbose] || false

      documents = metadata_cache.documents_for_category(category)

      if documents.empty?
        puts "No documents found in category '#{category}'"
        puts
        puts "Available categories: #{metadata_cache.categories.join(', ')}"
        return
      end

      puts "Documents in '#{category}' (#{documents.length}):"
      puts

      documents.each do |doc|
        puts "#{doc[:title]}"
        puts "  ID: #{doc[:id]}"
        puts "  Type: #{doc[:type]}"
        puts "  Path: #{doc[:path]}" if verbose

        if verbose && !doc[:content_preview].empty?
          puts "  Preview: #{doc[:content_preview]}"
        end

        puts
      end
    end

    def execute_search_command(metadata_cache, options)
      query = options[:query]
      verbose = options[:verbose] || false
      limit = options[:limit] || 10

      if query.nil? || query.strip.empty?
        puts "Search query cannot be empty"
        exit 1
      end

      results = metadata_cache.search(query)

      if results.empty?
        puts "No results found for '#{query}'"
        return
      end

      # Limit results
      results = results.first(limit)

      puts "Search Results for '#{query}' (#{results.length} of #{metadata_cache.search(query).length}):"
      puts

      results.each_with_index do |result, index|
        doc = result[:document]
        score = result[:score]
        category = result[:category]

        puts "#{index + 1}. #{doc[:title]}"
        puts "   Category: #{category} | Type: #{doc[:type]} | ID: #{doc[:id]}"

        if verbose
          puts "   Score: #{score} | Path: #{doc[:path]}"
        end

        unless doc[:content_preview].empty?
          puts "   #{doc[:content_preview]}"
        end

        puts
      end
    end

    def create_file_cache_if_needed(verbose)
      # Reuse existing cache creation logic but don't fail if cache unavailable
      begin
        cache = Cache::FileCache.new

        if verbose && cache
          health = cache.health_status
          unless health[:healthy]
            puts "Warning: Cache health issues detected (continuing anyway)"
          end
        end

        cache
      rescue => e
        puts "Warning: Cache unavailable (#{e.message}), using slower fallback" if verbose
        nil
      end
    end

    def display_discovery_stats(metadata_cache, start_time)
      total_time = Time.now - start_time
      cache_stats = metadata_cache.performance_stats

      puts "\n" + "="*50
      puts "DISCOVERY PERFORMANCE STATISTICS"
      puts "="*50

      puts "Command Performance:"
      puts "  Total time: #{total_time.round(3)}s"
      puts "  Cache hit ratio: #{(cache_stats[:hit_ratio] * 100).round(1)}%"
      puts "  Documents cached: #{cache_stats[:document_count]}"
      puts "  Categories: #{cache_stats[:category_count]}"
      puts "  Memory usage: #{format_bytes(cache_stats[:memory_usage])}"

      # New: Operation-specific microsecond metrics
      if cache_stats[:operation_metrics]&.any?
        puts "\nOperation Performance (Microsecond Precision):"
        cache_stats[:operation_metrics].each do |operation, metrics|
          avg_ms = (metrics[:avg_time_us] / 1000.0).round(3)
          min_ms = (metrics[:min_time_us] / 1000.0).round(3)
          max_ms = (metrics[:max_time_us] / 1000.0).round(3)

          puts "  #{operation.to_s.tr('_', ' ').capitalize}:"
          puts "    Operations: #{metrics[:count]}"
          puts "    Average: #{avg_ms}ms (#{metrics[:avg_time_us].round(0)}μs)"
          puts "    Range: #{min_ms}ms - #{max_ms}ms"
          puts "    Target met: #{avg_ms < 1000 ? '✅' : '❌'} (<1000ms)"
        end
      end

      # Performance summary
      if summary = cache_stats[:performance_summary]
        puts "\nPerformance Summary:"
        puts "  Total operations: #{summary[:total_discovery_operations]}"
        puts "  Total operation time: #{summary[:total_operation_time_ms].round(3)}ms"
        puts "  Average per operation: #{summary[:avg_operation_time_ms].round(3)}ms"
        puts "  All targets met: #{summary[:performance_target_met] ? '✅' : '❌'}"
      end

      if cache_stats[:scan_count] > 0
        puts "\nCache Operations:"
        puts "  Scan operations: #{cache_stats[:scan_count]}"
        puts "  Last scan: #{cache_stats[:last_scan]&.strftime('%H:%M:%S') || 'never'}"
      end
    end

    def format_bytes(bytes)
      return '0 B' if bytes == 0

      units = %w[B KB MB GB]
      unit_index = 0
      size = bytes.to_f

      while size >= 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end

      "#{size.round(1)} #{units[unit_index]}"
    end

    def perform_sync(target_path, categories, options)
      force = options[:force] || false
      verbose = options[:verbose] || false
      no_cache = options[:no_cache] || false
      force_git = options[:force_git] || false
      show_stats = options[:stats] || false

      # Create cache unless disabled
      cache = nil
      unless no_cache
        begin
          cache = Cache::FileCache.new

          # Check cache health on verbose mode
          if verbose && cache
            health = cache.health_status
            unless health[:healthy]
              puts "Warning: Cache health issues detected:"
              health[:issues].each do |issue|
                puts "  - #{issue[:type]}: #{issue[:path] || issue[:error]}"
              end
            end
          end
        rescue => e
          # Log cache initialization failure but continue without cache
          puts "Warning: Cache initialization failed: #{e.message}" if verbose
          puts "Continuing without cache optimization..." if verbose
          cache = nil
        end
      end

      # Create stats tracker
      stats = show_stats ? Cache::CacheStats.new : nil

      # Target directory for leyline content
      leyline_target = File.join(target_path, 'docs', 'leyline')

      # Always fetch from git to temp directory
      # FileSyncer will handle cache optimization during sync
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

        # Point to the docs subdirectory in temp_dir to avoid double nesting
        source_docs_dir = File.join(temp_dir, 'docs')
      rescue => e
        # Clean up and re-raise git errors
        git_client&.cleanup
        raise e
      end

      begin
        puts "Copying files to #{leyline_target}..." if verbose

        # Sync files to target directory under docs/leyline
        file_syncer = Sync::FileSyncer.new(source_docs_dir, leyline_target, cache: cache, stats: stats)
        results = file_syncer.sync(force: force, force_git: force_git, verbose: verbose)

        # Report results
        report_sync_results(results, verbose, stats: show_stats ? stats : nil, cache: cache)

      ensure
        # Clean up temp directory
        git_client&.cleanup if temp_dir
      end
    end

    def build_sparse_paths(categories)
      paths = []

      # Always include tenets and core bindings
      paths << 'docs/tenets/'
      paths << 'docs/bindings/core/'

      # Add category-specific bindings
      categories.each do |category|
        unless category == 'core'  # Skip core since we always include it above
          paths << "docs/bindings/categories/#{category}/"
        end
      end

      paths
    end

    def report_sync_results(results, verbose, stats: nil, cache: nil)
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

      # Display cache statistics if requested
      if stats
        puts "\n" + "="*50
        puts "CACHE STATISTICS"
        puts "="*50

        cache_directory_stats = cache&.directory_stats || {}
        puts stats.format_stats(cache_directory_stats)
      end
    end
  end
end
