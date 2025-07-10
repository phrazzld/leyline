# frozen_string_literal: true

require_relative 'discovery_base'

module Leyline
  module Commands
    # Command to search leyline documents by content
    class SearchCommand < DiscoveryBase
      class CommandError < Leyline::LeylineError
        def error_type
          :search_command_error
        end
      end

      def initialize(options = {})
        super
        @query = options[:query]
        @limit = options[:limit] || 10
        validate_query!
      end

      def execute
        results = metadata_cache.search(@query)

        if results.empty?
          handle_empty_results
          return nil
        end

        output_result(build_search_data(results))
        show_stats_if_requested
      rescue StandardError => e
        handle_error(e, query: @query)
        nil
      end

      private

      def validate_query!
        if @query.nil? || @query.strip.empty?
          raise ArgumentError, 'Search query cannot be empty'
        end
      end

      def handle_empty_results
        puts "No results found for '#{@query}'"

        # Provide "Did you mean?" suggestions
        suggestions = metadata_cache.suggest_corrections(@query)
        if suggestions.any?
          puts
          puts 'Did you mean:'
          suggestions.each { |suggestion| puts "  #{suggestion}" }
        end
      end

      def build_search_data(results)
        total_results = results.length
        limited_results = results.first(@limit)

        {
          query: @query,
          total_results: total_results,
          shown_results: limited_results.length,
          limit: @limit,
          results: limited_results.map { |result| format_search_result(result) }
        }
      end

      def format_search_result(result)
        doc = result[:document]
        {
          title: doc[:title],
          id: doc[:id],
          type: doc[:type],
          category: result[:category],
          score: result[:score],
          path: doc[:path],
          preview: doc[:content_preview],
          metadata: doc[:metadata]
        }.compact
      end

      def output_human_readable(data)
        puts format_search_header(data)
        puts

        data[:results].each_with_index do |result, index|
          display_search_result(result, index + 1)
        end

        display_truncation_notice(data) if data[:total_results] > data[:limit]
      end

      def format_search_header(data)
        header = "Search Results for '#{data[:query]}'"

        if data[:total_results] <= data[:limit]
          "#{header} (#{data[:total_results]} results):"
        else
          "#{header} (showing #{data[:shown_results]} of #{data[:total_results]}):"
        end
      end

      def display_search_result(result, number)
        # Basic info always shown
        puts "#{format_result_number(number)} #{result[:title]}"
        puts "   #{format_result_metadata(result)}"

        # Content preview with smart truncation
        if result[:preview] && !result[:preview].empty?
          preview = truncate_content(result[:preview], 100, verbose?)
          puts "   #{preview}" if preview
        end

        # Verbose mode: Additional context
        display_verbose_details(result) if verbose?

        puts
      end

      def format_result_metadata(result)
        base_info = "Category: #{result[:category]} | Type: #{result[:type]} | ID: #{result[:id]}"

        if verbose?
          relevance = format_relevance_score(result[:score])
          "#{base_info} | #{relevance}"
        else
          base_info
        end
      end

      def display_verbose_details(result)
        puts "   Path: #{result[:path]}" if result[:path]

        # Show metadata preview if available
        if result[:metadata] && result[:metadata].any?
          metadata_preview = result[:metadata]
            .select { |k, _v| k.to_s != 'content' }
            .first(3)
            .map { |k, v| "#{k}: #{v}" }
            .join(', ')
          puts "   Metadata: #{metadata_preview}" unless metadata_preview.empty?
        end
      end

      def display_truncation_notice(data)
        puts "Showing #{data[:limit]} of #{data[:total_results]} results. Use --limit to see more."
      end
    end
  end
end
