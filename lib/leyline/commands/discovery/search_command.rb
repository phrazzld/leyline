# frozen_string_literal: true

require_relative 'base'

module Leyline
  module Commands
    module Discovery
      # Implements the 'leyline search QUERY' command for full-text search
      # Searches across all documents with relevance scoring and smart previews
      class SearchCommand < Base
        def initialize(options = {})
          super
          @query = options['query'] || options[:query]
          @limit = (options['limit'] || options[:limit] || 10).to_i

          if @query.nil? || @query.strip.empty?
            raise DiscoveryError, 'Search query cannot be empty'
          end
        end

        def execute
          metadata_cache = initialize_metadata_cache

          result, execution_time = measure_time do
            perform_search(metadata_cache)
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

        def perform_search(metadata_cache)
          results = metadata_cache.search(@query)
          suggestions = []

          if results.empty?
            suggestions = metadata_cache.suggest_corrections(@query)
          end

          # Limit results
          limited_results = results.first(@limit.to_i)

          {
            query: @query,
            total_results: results.size,
            shown_results: limited_results.size,
            limit: @limit,
            results: limited_results.map { |r| format_result(r) },
            suggestions: suggestions
          }
        end

        def format_result(result)
          doc = result[:document] || result
          {
            title: doc[:title],
            path: doc[:path],
            score: normalize_score(result[:score]),
            type: doc[:type],
            category: extract_category(doc[:path]),
            matches: result[:matches],
            preview: doc[:content_preview]
          }
        end

        def normalize_score(score)
          return 0.0 unless score
          # Normalize to 0-1 range, assuming max score around 200
          [score / 200.0, 1.0].min
        end

        def extract_category(path)
          return 'unknown' unless path

          if path.include?('categories/')
            path.split('categories/')[1].split('/').first
          else
            'core'
          end
        end

        def output_human_readable(data)
          if data[:results].empty?
            puts "No results found for '#{data[:query]}'"

            if data[:suggestions].any?
              puts
              puts 'Did you mean:'
              data[:suggestions].each { |suggestion| puts "  #{suggestion}" }
            end

            return
          end

          actual_shown = [data[:shown_results], data[:results].size].min
          puts "Search results for '#{data[:query]}' (showing #{actual_shown} of #{data[:total_results]}):"
          puts

          data[:results].each_with_index do |result, index|
            puts "#{index + 1}. #{result[:title]} #{format_relevance(result[:score])}"
            puts "   Category: #{result[:category]} | Type: #{result[:type]}"

            if verbose? && result[:preview]
              puts "   Preview: #{truncate_content(result[:preview], 150)}"
            end

            if verbose? && result[:matches]&.any?
              puts "   Matches: #{result[:matches].join(', ')}"
            end

            puts
          end

          if data[:total_results] > data[:shown_results]
            puts "Use --limit #{data[:total_results]} to see all results"
          end
        end
      end
    end
  end
end
