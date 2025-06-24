# frozen_string_literal: true

module Leyline
  module Cache
    class CacheStats
      attr_reader :cache_hits, :cache_misses, :cache_puts, :git_operations_skipped, :sync_start_time, :sync_end_time,
                  :cache_check_time

      def initialize
        @cache_hits = 0
        @cache_misses = 0
        @cache_puts = 0
        @git_operations_skipped = false
        @sync_start_time = nil
        @sync_end_time = nil
        @cache_check_time = 0.0
      end

      def record_cache_hit
        @cache_hits += 1
      end

      def record_cache_miss
        @cache_misses += 1
      end

      def record_cache_put
        @cache_puts += 1
      end

      def record_git_operations_skipped
        @git_operations_skipped = true
      end

      def start_sync_timing
        @sync_start_time = Time.now
      end

      def end_sync_timing
        @sync_end_time = Time.now
      end

      def add_cache_check_time(duration)
        @cache_check_time += duration
      end

      def total_sync_time
        return 0.0 unless @sync_start_time && @sync_end_time

        @sync_end_time - @sync_start_time
      end

      def cache_hit_ratio
        total_operations = @cache_hits + @cache_misses
        return 0.0 if total_operations == 0

        @cache_hits.to_f / total_operations
      end

      # Aliases for benchmark compatibility
      alias hit_ratio cache_hit_ratio
      alias hits cache_hits
      alias misses cache_misses

      def total_operations
        @cache_hits + @cache_misses
      end

      def time_saved_estimate
        # Estimate: git operations typically take 3-5 seconds
        @git_operations_skipped ? 4.0 : 0.0
      end

      def to_h
        {
          cache_hits: @cache_hits,
          cache_misses: @cache_misses,
          cache_puts: @cache_puts,
          cache_hit_ratio: cache_hit_ratio,
          git_operations_skipped: @git_operations_skipped,
          total_sync_time: total_sync_time,
          cache_check_time: @cache_check_time,
          estimated_time_saved: time_saved_estimate
        }
      end

      def format_stats(cache_directory_stats = {})
        stats = []

        # Cache performance
        stats << 'Cache Performance:'
        stats << "  Cache hits: #{@cache_hits}"
        stats << "  Cache misses: #{@cache_misses}"
        stats << "  Cache puts: #{@cache_puts}"
        stats << "  Hit ratio: #{(cache_hit_ratio * 100).round(1)}%"

        # Timing information
        if total_sync_time > 0
          stats << "\nTiming:"
          stats << "  Total sync time: #{total_sync_time.round(3)}s"
          stats << "  Cache check time: #{@cache_check_time.round(3)}s"
          stats << if @git_operations_skipped
                     "  Git operations: skipped (saved ~#{time_saved_estimate}s)"
                   else
                     '  Git operations: executed'
                   end
        end

        # Cache directory info
        unless cache_directory_stats.empty?
          stats << "\nCache Directory:"
          stats << "  Location: #{cache_directory_stats[:path]}"
          stats << "  Size: #{format_bytes(cache_directory_stats[:size])}"
          stats << "  Files: #{cache_directory_stats[:file_count]}"
          stats << "  Utilization: #{cache_directory_stats[:utilization_percent]}%"
        end

        stats.join("\n")
      end

      private

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
    end
  end
end
