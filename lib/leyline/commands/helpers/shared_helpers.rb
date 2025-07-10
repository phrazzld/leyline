# frozen_string_literal: true

require_relative '../../cache/file_cache'

module Leyline
  module Commands
    module Helpers
      module SharedHelpers
        # Create file cache helper method (shared by transparency commands)
        def create_file_cache_if_needed(verbose)
          cache = Cache::FileCache.new

          if verbose && cache
            health = cache.health_status
            puts 'Warning: Cache health issues detected (continuing anyway)' unless health[:healthy]
          end

          cache
        rescue StandardError => e
          puts "Warning: Cache unavailable (#{e.message}), using slower fallback" if verbose
          nil
        end

        # Format bytes helper (shared by commands that display stats)
        def format_bytes(bytes)
          return '0 B' if bytes == 0

          units = %w[B KB MB GB]
          unit_index = 0
          size = bytes.to_f

          while size >= 1024 && unit_index < units.length - 1
            size /= 1024
            unit_index += 1
          end

          "#{size.round(1)} #{units[unit_index]}"
        end

        # Display transparency command statistics
        def display_transparency_stats(cache, start_time)
          total_time = Time.now - start_time

          puts "\n" + '=' * 50
          puts 'TRANSPARENCY COMMAND PERFORMANCE'
          puts '=' * 50

          puts "Execution Time: #{total_time.round(3)}s"
          puts "Target Met: #{total_time < 2.0 ? '✅' : '❌'} (<2s)"

          return unless cache&.respond_to?(:directory_stats)

          stats = cache.directory_stats
          puts "\nCache Performance:"
          puts "  Directory: #{stats[:path]}"
          puts "  Files: #{stats[:file_count]}"
          puts "  Size: #{format_bytes(stats[:size])}"
          puts "  Utilization: #{stats[:utilization_percent]}%"
        end
      end
    end
  end
end
