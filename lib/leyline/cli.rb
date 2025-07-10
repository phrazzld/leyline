# frozen_string_literal: true

require 'thor'
require_relative 'version'
require_relative 'cli/options'
require_relative 'commands/discovery'

module Leyline
  class CLI < Thor
    package_name 'leyline'

    # Define exit behavior for Thor compatibility
    def self.exit_on_failure?
      true
    end

    # Register discovery subcommand
    desc 'discovery SUBCOMMAND', 'Discover and explore leyline documents'
    subcommand 'discovery', Commands::DiscoveryCommand

    desc 'version', 'Show version information'
    long_desc 'Display leyline CLI version and system information. Use -v for verbose details or --json for automation.'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed system information',
                  aliases: '-v'
    method_option :json,
                  type: :boolean,
                  desc: 'Output version information as JSON',
                  aliases: '--json'
    def version
      require_relative 'commands/version_command'
      command = Commands::VersionCommand.new(options.to_h)
      command.execute
    end

    desc 'status [PATH]', 'Show sync status and local modifications'
    long_desc 'Display sync status for leyline standards. Shows locally modified files, available updates, and summary statistics. Use -c for category filtering, --json for automation.'
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
      require_relative 'commands/status_command'
      command = Commands::StatusCommand.new(options.to_h.merge(directory: path))
      command.execute
    end

    desc 'diff [PATH]', 'Show differences between local and remote leyline standards'
    long_desc 'Display unified diff showing changes between local and remote leyline standards. Use -c for category filtering, --format json for automation.'
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
                  enum: %w[text json]
    def diff(path = '.')
      require_relative 'commands/diff_command'
      command = Commands::DiffCommand.new(options.to_h.merge(directory: path))
      command.execute
    end

    desc 'update [PATH]', 'Preview and apply leyline updates with conflict detection'
    long_desc 'Safely update leyline standards with preview-first approach and intelligent conflict detection. Use --dry-run to preview changes, --force to override conflicts.'
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
      require_relative 'commands/update_command'
      command = Commands::UpdateCommand.new(options.to_h.merge(directory: path))
      command.execute
    end

    desc 'sync [PATH]', 'Synchronize leyline standards to target directory'
    long_desc 'Download and synchronize leyline standards to your project docs/leyline directory. Use -c for specific categories, --dry-run to preview, --stats for performance metrics.'
    method_option :categories,
                  type: :array,
                  desc: 'Specific categories to sync (e.g., typescript, go, core)',
                  aliases: '-c'
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
      # Handle help flag specially to maintain backward compatibility
      if path == '--help'
        help('sync')
        return
      end

      require_relative 'commands/sync_command'
      command = Commands::SyncCommand.new(options.to_h.merge(path: path))
      command.execute
    end

    desc 'help [COMMAND]', 'Show comprehensive help information'
    long_desc 'Display detailed help information for leyline commands. Use without arguments for command overview or specify a command for detailed help.'
    def help(command = nil)
      if command.nil?
        require_relative 'commands/help_command'
        help_command = Commands::HelpCommand.new
        help_command.execute
      else
        super(command)
      end
    end

    # Legacy commands for backward compatibility
    desc 'categories', 'List available leyline categories (legacy - use discovery categories)'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed category information',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :json,
                  type: :boolean,
                  desc: 'Output categories as JSON',
                  aliases: '--json'
    def categories
      require_relative 'commands/discovery/categories_command'
      command = Commands::Discovery::CategoriesCommand.new(options.to_h)
      command.execute
    end

    desc 'show CATEGORY', 'Show documents in a specific category (legacy - use discovery show)'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show additional document details',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :json,
                  type: :boolean,
                  desc: 'Output documents as JSON',
                  aliases: '--json'
    def show(category)
      require_relative 'commands/discovery/show_command'
      command = Commands::Discovery::ShowCommand.new(options.to_h.merge(category: category))
      command.execute
    end

    desc 'search QUERY', 'Search leyline documents by content (legacy - use discovery search)'
    method_option :limit,
                  type: :numeric,
                  desc: 'Maximum number of results to show',
                  default: 10,
                  aliases: '-l'
    method_option :verbose,
                  type: :boolean,
                  desc: 'Show detailed search results',
                  aliases: '-v'
    method_option :stats,
                  type: :boolean,
                  desc: 'Show cache performance statistics',
                  aliases: '--stats'
    method_option :json,
                  type: :boolean,
                  desc: 'Output search results as JSON',
                  aliases: '--json'
    def search(query)
      require_relative 'commands/discovery/search_command'
      command = Commands::Discovery::SearchCommand.new(options.to_h.merge(query: query))
      command.execute
    end

    default_task :sync
  end
end
