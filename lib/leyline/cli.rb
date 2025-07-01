# frozen_string_literal: true

require 'thor'
require 'tmpdir'
require_relative 'version'
require_relative 'cli/options'
require_relative 'sync/git_client'
require_relative 'sync/file_syncer'
require_relative 'sync_state'
require_relative 'cache/file_cache'
require_relative 'cache/cache_stats'
require_relative 'discovery/metadata_cache'
require_relative 'discovery/document_scanner'

module Leyline
  class CLI < Thor
    package_name 'leyline'

    desc 'version', 'Show version information'
    long_desc <<-LONGDESC
      Display leyline CLI version and system information.

      EXAMPLES:
        leyline version                   # Show version number
        leyline version -v               # Verbose with system details

      VERSION INFORMATION:
        - leyline CLI version
        - Ruby version compatibility
        - System platform detection
        - Cache directory location
    LONGDESC
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed system information',
                  aliases: '-v'
    def version
      puts VERSION

      if options[:verbose]
        puts "\nSystem Information:"
        puts "  Ruby version: #{RUBY_VERSION}"
        puts "  Platform: #{RUBY_PLATFORM}"
        puts "  Cache directory: #{ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')}"
        puts "  Git available: #{system('which git > /dev/null 2>&1') ? 'Yes' : 'No'}"
      end
    end

    desc 'categories', 'List all available categories for synchronization'
    long_desc <<-LONGDESC
      Lists all available categories that can be synchronized using the `sync` command.

      This command provides a simple list of category names that you can use with
      the `leyline sync -c <category>` command to add specific standards to your project.

      EXAMPLE:
        leyline categories
    LONGDESC
    def categories
      require_relative 'cli/options'

      puts "Available categories for sync:"
      puts
      Leyline::CliOptions::VALID_CATEGORIES.each do |category|
        puts "  - #{category}"
      end
      puts
      puts "You can sync them using: leyline sync -c <category1>,<category2>"
    end

    desc 'show CATEGORY', 'Show documents in a specific category'
    long_desc <<-LONGDESC
      Display all documents (tenets and bindings) within a specific category.
      Useful for exploring standards relevant to your technology stack.

      EXAMPLES:
        leyline show typescript           # Show TypeScript-specific documents
        leyline show core                # Show universal core principles
        leyline show frontend -v         # Verbose with content previews
        leyline show backend --stats     # Include performance metrics

      DOCUMENT TYPES:
        - Tenets: Fundamental principles and philosophies
        - Bindings: Specific, actionable rules and guidelines

      OUTPUT INFORMATION:
        - Document title and unique identifier
        - Document type (tenet or binding)
        - Content preview (in verbose mode)
        - File path (in verbose mode)

      PERFORMANCE:
        - Category filtering optimizes load time
        - Cache-aware: subsequent runs are faster
        - Use --stats to monitor cache efficiency
    LONGDESC
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
    long_desc <<-LONGDESC
      Full-text search across all leyline documents with relevance scoring.
      Searches titles, content, and metadata with intelligent ranking.

      EXAMPLES:
        leyline search "error handling"   # Search for error handling practices
        leyline search testing -v         # Verbose results with previews
        leyline search api --limit 5      # Limit to top 5 results
        leyline search "type safety" --stats  # Include performance stats

      SEARCH FEATURES:
        - Full-text search across all document content
        - Relevance scoring with visual indicators (★★★★★)
        - Content preview with smart truncation
        - "Did you mean?" suggestions for typos

      SEARCH TIPS:
        - Use quotes for exact phrases: "error handling"
        - Single words find broader matches: testing
        - Results ranked by relevance score
        - Use --limit to control number of results

      PERFORMANCE:
        - Search index cached for speed
        - First search may be slower (index building)
        - Subsequent searches: <200ms typical response
        - Use --stats to monitor search performance
    LONGDESC
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

    desc 'status [PATH]', 'Show sync status and local modifications'
    long_desc <<-LONGDESC
      Display the current sync status for leyline standards in the specified directory.
      Shows locally modified files, available updates, and summary statistics.

      EXAMPLES:
        leyline status                    # Check status in current directory
        leyline status /path/to/project   # Check status in specific directory
        leyline status -c typescript     # Check only TypeScript category
        leyline status --json            # Output as JSON for automation
        leyline status -v --stats        # Verbose output with performance stats

      PERFORMANCE TIPS:
        - Use category filtering (-c) for faster checks on large projects
        - Cache hit ratio >80% indicates optimal performance
        - Run with --stats to monitor cache efficiency
        - First run may be slower (cache warming)

      TROUBLESHOOTING:
        - If no leyline directory found, run 'leyline sync' first
        - Permission errors: check file access in docs/leyline
        - Slow performance: ensure cache directory is writable
    LONGDESC
    method_option :categories,
                  type: :array,
                  desc: 'Filter status by specific categories',
                  aliases: '-c'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed status information',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :json,
                  type: :boolean,
                  desc: 'Output status in JSON format',
                  aliases: '--json'
    def status(path = '.')
      perform_transparency_command(:status, options.merge(path: path))
    end

    desc 'diff [PATH]', 'Show differences between local and remote leyline standards'
    long_desc <<-LONGDESC
      Display unified diff showing changes between your local leyline standards
      and the latest remote version, without making any modifications.

      EXAMPLES:
        leyline diff                      # Show all differences
        leyline diff /path/to/project     # Check specific directory
        leyline diff -c typescript,go    # Show only TypeScript and Go changes
        leyline diff --format json       # Output as JSON for scripts
        leyline diff -v                  # Verbose with file-by-file details

      OUTPUT FORMATS:
        text (default): Human-readable unified diff format
        json:          Structured data for automation and scripts

      PERFORMANCE OPTIMIZATION:
        - Category filtering reduces comparison scope
        - Cache optimization speeds up repeated diff operations
        - Use --stats to monitor performance metrics
        - Target: <1.5s for 100 files, <2s for 1000+ files

      COMMON WORKFLOWS:
        1. leyline diff                   # See what would change
        2. leyline update --dry-run       # Preview update without applying
        3. leyline update                 # Apply changes after review
    LONGDESC
    method_option :categories,
                  type: :array,
                  desc: 'Filter diff by specific categories',
                  aliases: '-c'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed diff output',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :format,
                  type: :string,
                  desc: 'Output format (text, json)',
                  default: 'text',
                  enum: ['text', 'json']
    def diff(path = '.')
      perform_transparency_command(:diff, options.merge(path: path))
    end

    desc 'update [PATH]', 'Preview and apply leyline updates with conflict detection'
    long_desc <<-LONGDESC
      Safely update leyline standards with preview-first approach and intelligent
      conflict detection. Always shows what will change before applying updates.

      EXAMPLES:
        leyline update                    # Interactive update with preview
        leyline update --dry-run          # Show changes without applying
        leyline update -c core           # Update only core standards
        leyline update --force           # Override conflicts (use carefully)
        leyline update -v --stats        # Verbose with performance monitoring

      SAFETY FEATURES:
        - Three-way conflict detection (base, local, remote)
        - Preview-first: see changes before applying
        - Backup recommendations for important modifications
        - Rollback guidance if issues occur

      CONFLICT RESOLUTION:
        1. Review conflicts shown in preview
        2. Manually resolve conflicts in your editor
        3. Re-run update to apply remaining changes
        4. Use --force only when conflicts are intentional

      PERFORMANCE TARGETS:
        - Conflict detection: <2 seconds
        - Cache hit ratio: >80% for optimal speed
        - Memory usage: <50MB regardless of project size

      TROUBLESHOOTING:
        - Conflicts detected: Review and resolve manually before --force
        - Permission denied: Check write access to docs/leyline
        - Network errors: Ensure internet connectivity for remote fetch
    LONGDESC
    method_option :categories,
                  type: :array,
                  desc: 'Update specific categories only',
                  aliases: '-c'
    method_option :force,
                  type: :boolean,
                  desc: 'Force updates even with conflicts',
                  aliases: '-f'
    method_option :dry_run,
                  type: :boolean,
                  desc: 'Show what would be updated without making changes',
                  aliases: '-n'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed update information',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    def update(path = '.')
      perform_transparency_command(:update, options.merge(path: path))
    end

    desc 'sync [PATH]', 'Synchronize leyline standards to target directory'
    long_desc <<-LONGDESC
      Download and synchronize leyline standards to your project's docs/leyline directory.
      Creates the foundation for transparency commands (status, diff, update).

      EXAMPLES:
        leyline sync                      # Sync core standards to current directory
        leyline sync /path/to/project     # Sync to specific project
        leyline sync -c typescript,go    # Sync TypeScript and Go categories
        leyline sync --dry-run           # Preview without making changes
        leyline sync --force             # Overwrite local modifications
        leyline sync --no-cache         # Force fresh download
        leyline sync --stats            # Show detailed performance metrics

      CATEGORIES:
        core:       Universal development principles (always included)
        typescript: TypeScript-specific standards
        go:         Go-specific standards
        rust:       Rust-specific standards
        frontend:   Frontend development standards
        backend:    Backend development standards

      CACHE OPTIMIZATION:
        - First sync: Downloads and caches content (~2-5 seconds)
        - Subsequent syncs: <1 second with >80% cache hit ratio
        - Use --force-git to bypass cache when needed
        - Cache directory: ~/.cache/leyline

      PERFORMANCE MONITORING:
        - Use --stats for detailed cache and timing metrics
        - Target: <2s response times for all operations
        - Cache hit ratio >80% indicates optimal performance
        - Memory usage bounded to <50MB regardless of project size

      TROUBLESHOOTING:
        - Network errors: Check internet connectivity
        - Permission denied: Ensure write access to target directory
        - Cache issues: Clear ~/.cache/leyline and retry
        - Git not found: Install git and ensure it's in PATH
    LONGDESC
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

    desc 'help [COMMAND]', 'Show comprehensive help information'
    long_desc <<-LONGDESC
      Display detailed help information for leyline commands.
      Provides usage examples, performance tips, and troubleshooting guidance.

      EXAMPLES:
        leyline help                      # Show overview of all commands
        leyline help sync                # Detailed help for sync command
        leyline help status              # Detailed help for status command
        leyline                          # Show basic command list (Thor default)

      GETTING STARTED:
        1. leyline sync                  # Download standards to current project
        2. leyline status               # Check sync status and modifications
        3. leyline diff                 # See what has changed
        4. leyline update               # Apply updates safely

      COMMON WORKFLOWS:
        Discovery:    categories → show → search
        Sync:         sync → status → diff → update
        Monitoring:   Use --stats flag for performance insights
    LONGDESC
    def help(command = nil)
      if command.nil?
        display_comprehensive_help
      else
        super(command)
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

        # Start background cache warming to eliminate cold-start penalty
        begin
          warming_started = metadata_cache.warm_cache_in_background
          puts "🔄 Starting cache warm-up in background..." if verbose && warming_started
        rescue => e
          # Warming failures should not break the command
          puts "Warning: Cache warming failed: #{e.message}" if verbose
        end

        # Execute the specific discovery command
        case command
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

        if verbose && doc[:content_preview] && !doc[:content_preview].empty?
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

        # Provide "Did you mean?" suggestions
        suggestions = metadata_cache.suggest_corrections(query)
        if suggestions.any?
          puts
          puts "Did you mean:"
          suggestions.each { |suggestion| puts "  #{suggestion}" }
        end

        return
      end

      # Store full results count before limiting
      total_results = results.length
      results = results.first(limit)

      # Enhanced search result header with progressive disclosure
      puts format_search_header(query, results.length, total_results, limit)
      puts

      # Display results with enhanced formatting
      results.each_with_index do |result, index|
        display_search_result(result, index, verbose)
      end

      # Show truncation notice if applicable
      if total_results > limit
        puts "Showing #{limit} of #{total_results} results. Use --limit to see more."
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

    def format_search_header(query, shown_count, total_count, limit)
      header = "Search Results for '#{query}'"

      if total_count <= limit
        "#{header} (#{total_count} results):"
      else
        "#{header} (showing #{shown_count} of #{total_count}):"
      end
    end

    def display_search_result(result, index, verbose)
      doc = result[:document]
      score = result[:score]
      category = result[:category]

      # Progressive disclosure: Basic info always shown
      puts "#{format_result_number(index + 1)} #{doc[:title]}"
      puts "   #{format_result_metadata(category, doc[:type], doc[:id], score, verbose)}"

      # Progressive disclosure: Content preview with smart truncation
      if doc[:content_preview] && !doc[:content_preview].empty?
        preview = format_content_preview(doc[:content_preview], verbose)
        puts "   #{preview}" if preview
      end

      # Verbose mode: Additional context
      if verbose
        display_verbose_search_details(doc, result, score)
      end

      puts
    end

    def format_result_number(number)
      # Add visual hierarchy with consistent numbering
      sprintf("%2d.", number)
    end

    def format_result_metadata(category, type, id, score, verbose)
      base_info = "Category: #{category} | Type: #{type} | ID: #{id}"

      if verbose
        relevance_indicator = format_relevance_score(score)
        "#{base_info} | #{relevance_indicator}"
      else
        base_info
      end
    end

    def format_relevance_score(score)
      # Convert numeric score to visual relevance indicator
      case score
      when 100..Float::INFINITY
        "Relevance: ★★★★★ (#{score})"
      when 75..99
        "Relevance: ★★★★☆ (#{score})"
      when 50..74
        "Relevance: ★★★☆☆ (#{score})"
      when 25..49
        "Relevance: ★★☆☆☆ (#{score})"
      when 10..24
        "Relevance: ★☆☆☆☆ (#{score})"
      else
        "Relevance: ☆☆☆☆☆ (#{score})"
      end
    end

    def format_content_preview(content, verbose)
      return nil if content.nil? || content.empty?

      # Smart truncation based on mode
      max_length = verbose ? 200 : 100

      if content.length <= max_length
        content
      else
        # Try to break at word boundary
        truncated = content[0, max_length]
        last_space = truncated.rindex(' ')

        if last_space && last_space > max_length * 0.7
          "#{content[0, last_space]}..."
        else
          "#{truncated}..."
        end
      end
    end

    def display_verbose_search_details(doc, result, score)
      # Additional context in verbose mode
      puts "   Path: #{doc[:path]}" if doc[:path]

      # Show match details if available
      if doc[:metadata] && doc[:metadata].any?
        metadata_preview = doc[:metadata].select { |k, v| k.to_s != 'content' }
                                         .first(3)
                                         .map { |k, v| "#{k}: #{v}" }
                                         .join(', ')
        puts "   Metadata: #{metadata_preview}" unless metadata_preview.empty?
      end

      # Show timing if document has scan time
      if doc[:scan_time]
        puts "   Last updated: #{doc[:scan_time].strftime('%Y-%m-%d %H:%M')}"
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

        # Save sync state for status/diff/update commands
        if results[:errors].empty?
          save_sync_state(leyline_target, categories, cache)
        end

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

    def save_sync_state(leyline_target, categories, cache)
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

    def perform_transparency_command(command, options)
      start_time = Time.now

      # Pre-process categories (consistent with sync command)
      processed_options = preprocess_transparency_options(options)

      # Validate options
      begin
        validate_transparency_options(command, processed_options)
      rescue CliOptions::ValidationError => e
        puts "Error: #{e.message}"
        exit 1
      end

      # Expand and validate path
      target_path = File.expand_path(processed_options[:path] || '.')

      begin
        # Initialize shared infrastructure
        file_cache = create_file_cache_if_needed(processed_options[:verbose])

        # Execute specific transparency command
        case command
        when :status
          execute_status_command(target_path, processed_options, file_cache)
        when :diff
          execute_diff_command(target_path, processed_options, file_cache)
        when :update
          execute_update_command(target_path, processed_options, file_cache)
        else
          puts "Unknown transparency command: #{command}"
          exit 1
        end

        # Show performance statistics if requested
        if processed_options[:stats]
          display_transparency_stats(file_cache, start_time)
        end

      rescue => e
        puts "Error during #{command}: #{e.message}"
        puts e.backtrace if processed_options[:verbose]
        exit 1
      end
    end

    def preprocess_transparency_options(options)
      processed = options.dup

      # Handle comma-separated categories (consistent with sync)
      if processed[:categories].is_a?(Array) &&
         processed[:categories].length == 1 &&
         processed[:categories].first.include?(',')
        processed[:categories] = processed[:categories].first.split(',').map(&:strip)
      end

      processed
    end

    def validate_transparency_options(command, options)
      # Common validations using existing patterns
      if options[:categories]
        CliOptions.normalize_categories(options[:categories])
      end

      # Command-specific validations
      case command
      when :diff
        validate_format_option(options[:format])
      end
    end

    def validate_format_option(format)
      return true if format.nil?

      valid_formats = ['text', 'json']
      unless valid_formats.include?(format)
        raise CliOptions::ValidationError, "Invalid format '#{format}'. Valid formats: #{valid_formats.join(', ')}"
      end

      true
    end

    def execute_status_command(target_path, options, cache)
      require_relative 'commands/status_command'

      command_options = options.merge(
        directory: target_path,
        cache_dir: ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
      )

      status_command = Commands::StatusCommand.new(command_options)
      status_command.execute
    end

    def execute_diff_command(target_path, options, cache)
      require_relative 'commands/diff_command'

      command_options = options.merge(
        directory: target_path,
        cache_dir: ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
      )

      diff_command = Commands::DiffCommand.new(command_options)
      diff_command.execute
    end

    def execute_update_command(target_path, options, cache)
      require_relative 'commands/update_command'

      command_options = options.merge(
        directory: target_path,
        cache_dir: ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
      )

      update_command = Commands::UpdateCommand.new(command_options)
      update_command.execute
    end

    def display_transparency_stats(cache, start_time)
      total_time = Time.now - start_time

      puts "\n" + "="*50
      puts "TRANSPARENCY COMMAND PERFORMANCE"
      puts "="*50

      puts "Execution Time: #{total_time.round(3)}s"
      puts "Target Met: #{total_time < 2.0 ? '✅' : '❌'} (<2s)"

      if cache&.respond_to?(:directory_stats)
        stats = cache.directory_stats
        puts "\nCache Performance:"
        puts "  Directory: #{stats[:path]}"
        puts "  Files: #{stats[:file_count]}"
        puts "  Size: #{format_bytes(stats[:size])}"
        puts "  Utilization: #{stats[:utilization_percent]}%"
      end
    end

    def display_comprehensive_help
      puts "LEYLINE CLI - Development Standards Synchronization"
      puts "="*60
      puts
      puts "Leyline helps you synchronize and manage development standards across"
      puts "your projects, providing transparency into changes and updates."
      puts
      puts "COMMAND CATEGORIES:"
      puts
      puts "  📋 DISCOVERY COMMANDS"
      puts "    categories          List available leyline categories"
      puts "    show CATEGORY       Show documents in a specific category"
      puts "    search QUERY        Search leyline documents by content"
      puts
      puts "  🔄 SYNC COMMANDS"
      puts "    sync [PATH]         Download leyline standards to project"
      puts "    status [PATH]       Show sync status and local modifications"
      puts "    diff [PATH]         Show differences without applying changes"
      puts "    update [PATH]       Preview and apply updates with conflict detection"
      puts
      puts "  ℹ️  UTILITY COMMANDS"
      puts "    version             Show version and system information"
      puts "    help [COMMAND]      Show detailed help for specific commands"
      puts
      puts "QUICK START:"
      puts "  1. leyline sync               # Download standards to current project"
      puts "  2. leyline status            # Check what's synchronized"
      puts "  3. leyline categories        # Explore available categories"
      puts "  4. leyline show typescript   # View TypeScript-specific standards"
      puts
      puts "PERFORMANCE OPTIMIZATION:"
      puts "  • Cache automatically optimizes subsequent operations"
      puts "  • Use category filtering (-c) for faster operations"
      puts "  • Add --stats to any command for performance insights"
      puts "  • Target response times: <2s for all operations"
      puts
      puts "TROUBLESHOOTING:"
      puts "  • Run with -v (verbose) flag for detailed output"
      puts "  • Use --stats to monitor cache and performance"
      puts "  • Check ~/.cache/leyline for cache issues"
      puts "  • Ensure git is installed and internet connectivity"
      puts
      puts "For detailed help on any command: leyline help COMMAND"
      puts "Documentation: https://github.com/phrazzld/leyline"
    end
  end
end
