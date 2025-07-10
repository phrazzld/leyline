# frozen_string_literal: true

require_relative 'discovery_base'

module Leyline
  module Commands
    # Command to list available leyline categories
    class CategoriesCommand < DiscoveryBase
      def execute
        # Simple list without cache for backwards compatibility
        output_result(build_categories_data)
      rescue StandardError => e
        handle_error(e)
        nil
      end

      private

      def build_categories_data
        {
          categories: categories_list,
          count: categories_list.length
        }
      end

      def categories_list
        require_relative '../cli/options'
        Leyline::CliOptions::VALID_CATEGORIES
      end

      def output_human_readable(data)
        puts 'Available categories for sync:'
        puts
        data[:categories].each do |category|
          puts "  - #{category}"
        end
        puts
        puts 'You can sync them using: leyline sync -c <category1>,<category2>'
      end
    end
  end
end
