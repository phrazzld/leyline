# frozen_string_literal: true

require 'thor'

module Leyline
  module CLI
    # Discovery subcommand for categories, show, and search operations
    class Discovery < Thor
      desc 'categories', 'List all available categories for synchronization'
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def categories
        require_relative '../commands/categories_command'

        command = Commands::CategoriesCommand.new(options.to_h)
        command.execute
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
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def show(category)
        require_relative '../commands/show_command'

        command_options = options.to_h.merge(category: category)
        command = Commands::ShowCommand.new(command_options)
        command.execute
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
      method_option :json,
                    type: :boolean,
                    desc: 'Output as JSON',
                    aliases: '--json'
      def search(query)
        require_relative '../commands/search_command'

        command_options = options.to_h.merge(query: query)
        command = Commands::SearchCommand.new(command_options)
        command.execute
      end
    end
  end
end
