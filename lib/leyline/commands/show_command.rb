# frozen_string_literal: true

require_relative 'discovery_base'

module Leyline
  module Commands
    # Command to show documents in a specific category
    class ShowCommand < DiscoveryBase
      class CommandError < Leyline::LeylineError
        def error_type
          :show_command_error
        end
      end

      def initialize(options = {})
        super
        @category = options[:category]
        validate_category!
      end

      def execute
        documents = metadata_cache.documents_for_category(@category)

        if documents.empty?
          handle_empty_results
          return nil
        end

        output_result(build_show_data(documents))
        show_stats_if_requested
      rescue StandardError => e
        handle_error(e, category: @category)
        nil
      end

      private

      def validate_category!
        raise ArgumentError, 'Category is required' if @category.nil? || @category.strip.empty?
      end

      def handle_empty_results
        puts "No documents found in category '#{@category}'"
        puts
        puts "Available categories: #{metadata_cache.categories.join(', ')}"
      end

      def build_show_data(documents)
        {
          category: @category,
          document_count: documents.length,
          documents: documents.map { |doc| format_document(doc) }
        }
      end

      def format_document(doc)
        {
          title: doc[:title],
          id: doc[:id],
          type: doc[:type],
          path: doc[:path],
          preview: doc[:content_preview]
        }.compact
      end

      def output_human_readable(data)
        puts "Documents in '#{data[:category]}' (#{data[:document_count]}):"
        puts

        data[:documents].each do |doc|
          puts doc[:title]
          puts "  ID: #{doc[:id]}"
          puts "  Type: #{doc[:type]}"

          if verbose?
            puts "  Path: #{doc[:path]}" if doc[:path]
            if doc[:preview] && !doc[:preview].empty?
              puts "  Preview: #{truncate_content(doc[:preview], 200, verbose?)}"
            end
          end

          puts
        end
      end
    end
  end
end
