# frozen_string_literal: true

require_relative 'base'

module Leyline
  module Commands
    module Discovery
      # Implements the 'leyline show CATEGORY' command to display documents in a category
      # Shows all tenets and bindings within the specified category
      class ShowCommand < Base
        def initialize(options = {})
          super
          @category = options['category'] || options[:category]

          unless @category
            raise DiscoveryError, 'Category parameter is required'
          end
        end

        def execute
          metadata_cache = initialize_metadata_cache

          result, execution_time = measure_time do
            gather_category_documents(metadata_cache)
          end

          if @options['json'] || @options[:json]
            output_json(result)
          else
            output_human_readable(result)
          end

          display_stats(metadata_cache, Time.now - (execution_time / 1000.0))

          result
        rescue StandardError => e
          handle_error(e)
          nil
        end

        private

        def gather_category_documents(metadata_cache)
          documents = metadata_cache.documents_for_category(@category)

          {
            category: @category,
            document_count: documents.length,
            documents: documents.map do |doc|
              {
                title: doc[:title],
                id: doc[:id],
                type: doc[:type],
                path: doc[:path],
                description: doc[:description]
              }
            end,
            available_categories: metadata_cache.categories
          }
        end

        def output_human_readable(data)
          if data[:document_count] == 0
            puts "No documents found in category '#{data[:category]}'"
            puts
            puts "Available categories: #{data[:available_categories].join(', ')}"
            return
          end

          puts "Documents in '#{data[:category]}' (#{data[:document_count]}):"
          puts

          data[:documents].each do |doc|
            puts "#{doc[:title]}"
            puts "  ID: #{doc[:id]}"
            puts "  Type: #{doc[:type]}"

            if verbose?
              puts "  Path: #{doc[:path]}"
              puts "  Description: #{truncate_content(doc[:description])}" if doc[:description]
            end

            puts
          end
        end
      end
    end
  end
end
