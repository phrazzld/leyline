# frozen_string_literal: true

require_relative 'base'

module Leyline
  module Commands
    module Discovery
      # Implements the 'leyline categories' command to list available categories
      # Shows all categories that can be synchronized using the sync command
      class CategoriesCommand < Base
        def execute
          result, execution_time = measure_time do
            gather_categories_information
          end

          if @options[:json]
            output_json(result)
          else
            output_human_readable(result)
          end

          display_stats(nil, Time.now - (execution_time / 1000.0)) if @options[:stats]

          result
        rescue StandardError => e
          handle_error(e)
          nil
        end

        private

        def gather_categories_information
          {
            categories: available_categories,
            total_count: available_categories.size,
            command_hint: 'leyline sync -c <category1>,<category2>'
          }
        end

        def output_human_readable(data)
          puts 'Available categories for sync:'
          puts

          data[:categories].each do |category|
            puts "  - #{category}"
          end

          puts
          puts "You can sync them using: #{data[:command_hint]}"
        end
      end
    end
  end
end
