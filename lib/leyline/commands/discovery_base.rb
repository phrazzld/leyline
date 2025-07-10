# frozen_string_literal: true

require_relative 'base_command'
require_relative '../discovery/metadata_cache'
require_relative '../discovery/document_scanner'

module Leyline
  module Commands
    # Base class for discovery commands (categories, show, search)
    # Provides shared cache initialization, warming, and stats display
    class DiscoveryBase < BaseCommand
      def initialize(options = {})
        super
        @metadata_cache = nil
        @cache_warmed = false
        @start_time = Time.now
      end

      protected

      # Initialize and return metadata cache with background warming
      def metadata_cache
        @metadata_cache ||= begin
          cache = Discovery::MetadataCache.new(file_cache: file_cache)
          warm_cache_if_needed(cache)
          cache
        end
      end

      # Show discovery statistics if requested
      def show_stats_if_requested
        return unless @options[:stats]

        display_discovery_stats
      end

      # Format bytes for human-readable display
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

      # Format search result number with consistent padding
      def format_result_number(number)
        format('%2d.', number)
      end

      # Format relevance score as visual stars
      def format_relevance_score(score)
        case score
        when 100..Float::INFINITY
          "Relevance: ★★★★★ (#{score})"
        when 75..99
          "Relevance: ★★★★☆ (#{score})"
        when 50..74
          "Relevance: ★★★☆☆ (#{score})"
        when 25..49
          "Relevance: ★★☆☆☆ (#{score})"
        when 10..24
          "Relevance: ★☆☆☆☆ (#{score})"
        else
          "Relevance: ☆☆☆☆☆ (#{score})"
        end
      end

      # Smart content truncation with word boundaries
      def truncate_content(content, max_length, verbose = false)
        return nil if content.nil? || content.empty?

        # Adjust max length based on verbosity
        length = verbose ? max_length * 2 : max_length

        if content.length <= length
          content
        else
          # Try to break at word boundary
          truncated = content[0, length]
          last_space = truncated.rindex(' ')

          if last_space && last_space > length * 0.7
            "#{content[0, last_space]}..."
          else
            "#{truncated}..."
          end
        end
      end

      private

      # Start background cache warming
      def warm_cache_if_needed(cache)
        return if @cache_warmed

        begin
          warming_started = cache.warm_cache_in_background
          puts '🔄 Starting cache warm-up in background...' if verbose? && warming_started
          @cache_warmed = true
        rescue StandardError => e
          # Warming failures should not break the command
          warn "Warning: Cache warming failed: #{e.message}" if verbose?
        end
      end

      # Display performance statistics
      def display_discovery_stats
        total_time = Time.now - @start_time
        cache_stats = metadata_cache.performance_stats

        puts "\n" + '=' * 50
        puts 'DISCOVERY PERFORMANCE STATISTICS'
        puts '=' * 50

        puts 'Command Performance:'
        puts "  Total time: #{total_time.round(3)}s"
        puts "  Cache hit ratio: #{(cache_stats[:hit_ratio] * 100).round(1)}%"
        puts "  Documents cached: #{cache_stats[:document_count]}"
        puts "  Categories: #{cache_stats[:category_count]}"
        puts "  Memory usage: #{format_bytes(cache_stats[:memory_usage])}"

        display_operation_metrics(cache_stats[:operation_metrics]) if cache_stats[:operation_metrics]&.any?
        display_performance_summary(cache_stats[:performance_summary]) if cache_stats[:performance_summary]
        display_cache_operations(cache_stats) if cache_stats[:scan_count] > 0
      end

      def display_operation_metrics(metrics)
        puts "\nOperation Performance (Microsecond Precision):"
        metrics.each do |operation, data|
          avg_ms = (data[:avg_time_us] / 1000.0).round(3)
          min_ms = (data[:min_time_us] / 1000.0).round(3)
          max_ms = (data[:max_time_us] / 1000.0).round(3)

          puts "  #{operation.to_s.tr('_', ' ').capitalize}:"
          puts "    Operations: #{data[:count]}"
          puts "    Average: #{avg_ms}ms (#{data[:avg_time_us].round(0)}μs)"
          puts "    Range: #{min_ms}ms - #{max_ms}ms"
          puts "    Target met: #{avg_ms < 1000 ? '✅' : '❌'} (<1000ms)"
        end
      end

      def display_performance_summary(summary)
        puts "\nPerformance Summary:"
        puts "  Total operations: #{summary[:total_discovery_operations]}"
        puts "  Total operation time: #{summary[:total_operation_time_ms].round(3)}ms"
        puts "  Average per operation: #{summary[:avg_operation_time_ms].round(3)}ms"
        puts "  All targets met: #{summary[:performance_target_met] ? '✅' : '❌'}"
      end

      def display_cache_operations(stats)
        puts "\nCache Operations:"
        puts "  Scan operations: #{stats[:scan_count]}"
        puts "  Last scan: #{stats[:last_scan]&.strftime('%H:%M:%S') || 'never'}"
      end
    end
  end
end
