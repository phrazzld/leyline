# frozen_string_literal: true

require 'thor'
require_relative 'discovery/categories_command'
require_relative 'discovery/show_command'
require_relative 'discovery/search_command'

module Leyline
  module Commands
    # Thor subcommand class for discovery-related commands
    # Provides a grouped interface for categories, show, and search commands
    # Usage: leyline discovery <subcommand>
    class DiscoveryCommand < Thor
      # Set custom banner to show proper subcommand usage
      def self.banner(command, namespace = nil, subcommand = false)
        "#{basename} discovery #{command.usage}"
      end

      desc 'categories', 'List all available categories for synchronization'
      long_desc <<-LONGDESC
        Lists all available categories that can be synchronized using the `sync` command.

        This command provides a simple list of category names that you can use with
        the `leyline sync -c <category>` command to add specific standards to your project.

        EXAMPLE:
          leyline discovery categories
      LONGDESC
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def categories
        command = Discovery::CategoriesCommand.new(options.to_h)
        command.execute
      end

      desc 'show CATEGORY', 'Show documents in a specific category'
      long_desc <<-LONGDESC
        Display all documents (tenets and bindings) within a specific category.
        Useful for exploring standards relevant to your technology stack.

        EXAMPLES:
          leyline discovery show typescript           # Show TypeScript-specific documents
          leyline discovery show core                # Show universal core principles
          leyline discovery show frontend -v         # Verbose with content previews
          leyline discovery show backend --stats     # Include performance metrics

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
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def show(category)
        command = Discovery::ShowCommand.new(options.to_h.merge(category: category))
        command.execute
      end

      desc 'search QUERY', 'Search leyline documents by content'
      long_desc <<-LONGDESC
        Full-text search across all leyline documents with relevance scoring.
        Searches titles, content, and metadata with intelligent ranking.

        EXAMPLES:
          leyline discovery search "error handling"   # Search for error handling practices
          leyline discovery search testing -v         # Verbose results with previews
          leyline discovery search api --limit 5      # Limit to top 5 results
          leyline discovery search "type safety" --stats  # Include performance stats

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
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def search(query)
        command = Discovery::SearchCommand.new(options.to_h.merge(query: query))
        command.execute
      end
    end
  end
end
