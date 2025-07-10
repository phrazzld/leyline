# frozen_string_literal: true

require_relative '../base_command'
require_relative '../../discovery/metadata_cache'
require_relative '../../cache/file_cache'

module Leyline
  module Commands
    module Discovery
      # Base class for all discovery-related commands
      # Provides shared functionality for cache initialization, performance tracking,
      # and common display utilities for categories, show, and search commands
      class Base < BaseCommand
        class DiscoveryError < Leyline::LeylineError
          def error_type
            :discovery
          end

          def recovery_suggestions
            [
              'Ensure leyline repository is accessible',
              'Check network connectivity if using remote repository',
              'Try clearing cache with rm -rf ~/.cache/leyline',
              'Run leyline sync to ensure documents are available'
            ]
          end
        end

        protected

        # Initialize metadata cache with background warming
        def initialize_metadata_cache
          file_cache = create_file_cache
          metadata_cache = Leyline::Discovery::MetadataCache.new(file_cache: file_cache)

          # Start background cache warming if possible
          begin
            warming_started = metadata_cache.warm_cache_in_background
            puts '🔄 Starting cache warm-up in background...' if verbose? && warming_started
          rescue StandardError => e
            # Warming failures should not break the command
            warn "Warning: Cache warming failed: #{e.message}" if verbose?
          end

          metadata_cache
        end

        # Create file cache instance if available
        def create_file_cache
          Leyline::Cache::FileCache.new(@cache_dir)
        rescue StandardError => e
          warn "Warning: File cache initialization failed: #{e.message}" if verbose?
          nil
        end

        # Display performance statistics
        def display_stats(metadata_cache, start_time)
          return unless @options['stats'] || @options[:stats]

          total_time = Time.now - start_time
          stats = metadata_cache.performance_stats

          puts
          puts 'Cache Performance:'
          puts "  Documents scanned: #{stats[:document_count]}"
          puts "  Memory usage: #{format_bytes(stats[:memory_usage])}"
          puts "  Hit ratio: #{(stats[:hit_ratio] * 100).round(1)}%"
          puts "  Compression ratio: #{stats[:compression_ratio].round(2)}x" if stats[:compression_ratio] && stats[:compression_ratio] > 1
          if stats[:operation_stats]&.any?
            puts
            puts 'Operation Performance:'
            stats[:operation_stats].each do |op, timing|
              next if timing[:count] == 0
              puts "  #{op}: #{timing[:avg].round(3)}s avg (#{timing[:count]} calls)"
            end
          end
          puts
          puts "Total time: #{(total_time * 1000).round}ms"
        end

        # Format bytes into human-readable string
        def format_bytes(bytes)
          return '0 B' if bytes == 0

          units = %w[B KB MB GB]
          index = [3, (Math.log(bytes) / Math.log(1024)).floor].min
          size = bytes.to_f / (1024**index)

          format('%.2f %s', size, units[index])
        end

        # Format relevance score as stars
        def format_relevance(score)
          return '' unless score

          # Ensure score is between 0 and 1
          score = [[0, score].max, 1].min

          stars = (score * 5).round
          filled = '★' * stars
          empty = '☆' * [0, (5 - stars)].max
          "#{filled}#{empty}"
        end

        # Truncate content for preview
        def truncate_content(content, max_length = 200)
          return '' unless content

          content = content.strip.gsub(/\s+/, ' ')
          return content if content.length <= max_length

          "#{content[0...(max_length - 3)]}..."
        end

        # Load available categories from CLI options
        def available_categories
          require_relative '../../cli/options'
          Leyline::CliOptions::VALID_CATEGORIES
        end
      end
    end
  end
end
