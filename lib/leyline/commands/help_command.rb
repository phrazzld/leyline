# frozen_string_literal: true

require_relative 'base_command'

module Leyline
  module Commands
    class HelpCommand < BaseCommand
      def initialize(options = {})
        super
        @command = options[:command]
      end

      def execute
        display_comprehensive_help
      end

      private

      def display_comprehensive_help
        puts 'LEYLINE CLI - Development Standards Synchronization'
        puts '=' * 60
        puts
        puts 'Leyline helps you synchronize and manage development standards across'
        puts 'your projects, providing transparency into changes and updates.'
        puts
        puts 'COMMAND CATEGORIES:'
        puts
        puts '  📋 DISCOVERY COMMANDS'
        puts '    discovery categories      List available leyline categories (preferred)'
        puts '    discovery show CATEGORY   Show documents in a specific category (preferred)'
        puts '    discovery search QUERY    Search leyline documents by content (preferred)'
        puts '    categories                List available leyline categories (legacy)'
        puts '    show CATEGORY             Show documents in a specific category (legacy)'
        puts '    search QUERY              Search leyline documents by content (legacy)'
        puts
        puts '  🔄 SYNC COMMANDS'
        puts '    sync [PATH]         Download leyline standards to project'
        puts '    status [PATH]       Show sync status and local modifications'
        puts '    diff [PATH]         Show differences without applying changes'
        puts '    update [PATH]       Preview and apply updates with conflict detection'
        puts
        puts '  ℹ️  UTILITY COMMANDS'
        puts '    version             Show version and system information'
        puts '    help [COMMAND]      Show detailed help for specific commands'
        puts
        puts 'QUICK START:'
        puts '  1. leyline sync                        # Download standards to current project'
        puts "  2. leyline status                     # Check what's synchronized"
        puts '  3. leyline discovery categories       # Explore available categories (preferred)'
        puts '  4. leyline discovery show typescript  # View TypeScript-specific standards (preferred)'
        puts
        puts 'LEGACY COMMANDS (backward compatibility):'
        puts '  leyline categories        # Same as discovery categories'
        puts '  leyline show typescript   # Same as discovery show typescript'
        puts '  leyline search "query"    # Same as discovery search "query"'
        puts
        puts 'PERFORMANCE OPTIMIZATION:'
        puts '  • Cache automatically optimizes subsequent operations'
        puts '  • Use category filtering (-c) for faster operations'
        puts '  • Add --stats to any command for performance insights'
        puts '  • Target response times: <2s for all operations'
        puts
        puts 'TROUBLESHOOTING:'
        puts '  • Run with -v (verbose) flag for detailed output'
        puts '  • Use --stats to monitor cache and performance'
        puts '  • Check ~/.cache/leyline for cache issues'
        puts '  • Ensure git is installed and internet connectivity'
        puts
        puts 'For detailed help on any command: leyline help COMMAND'
        puts 'Documentation: https://github.com/phrazzld/leyline'
      end
    end
  end
end
