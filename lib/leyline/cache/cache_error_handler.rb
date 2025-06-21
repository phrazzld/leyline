# frozen_string_literal: true

require 'json'
require 'time'

module Leyline
  module Cache
    # Provides comprehensive error handling for cache operations
    # Ensures cache errors never break sync functionality
    module CacheErrorHandler
      class << self
        # Log a cache warning without interrupting flow
        def warn(message, context = {})
          return unless warnings_enabled?

          log_entry = build_log_entry('cache_warning', message, context)
          output_log(log_entry, :warn)
        rescue StandardError => e
          # Even error logging shouldn't break the application
          warn "Failed to log warning: #{e.message}" if debug_mode?
        end

        # Log a cache error and return safe default
        def handle_error(error, operation, context = {})
          return unless warnings_enabled?

          log_entry = build_log_entry('cache_error', error.message, {
                                        operation: operation,
                                        error_class: error.class.name,
                                        backtrace: error.backtrace&.first(3),
                                        **context
                                      })

          output_log(log_entry, :error)
        rescue StandardError => e
          # Even error logging shouldn't break the application
          warn "Failed to log error: #{e.message}" if debug_mode?
        end

        # Check if cache directory is healthy
        def check_cache_health(cache_dir)
          issues = []

          # Check directory existence
          issues << { type: 'missing_directory', path: cache_dir } unless Dir.exist?(cache_dir)

          # Check permissions
          if Dir.exist?(cache_dir)
            issues << { type: 'not_readable', path: cache_dir } unless File.readable?(cache_dir)

            issues << { type: 'not_writable', path: cache_dir } unless File.writable?(cache_dir)
          end

          # Check disk space (basic check)
          begin
            stat = File.stat(cache_dir)
            # This is a simplified check - in production you'd check actual free space
            if stat.size > 500 * 1024 * 1024 # 500MB warning threshold
              issues << { type: 'large_cache', size: stat.size }
            end
          rescue StandardError => e
            issues << { type: 'stat_failed', error: e.message }
          end

          issues
        end

        # Attempt to recover from cache corruption
        def attempt_recovery(cache_dir, error)
          return false unless recovery_enabled?

          warn('Attempting cache recovery', {
                 cache_dir: cache_dir,
                 error: error.message
               })

          # For now, just return false. In a full implementation,
          # this could attempt to clear corrupted files, recreate
          # directory structure, etc.
          false
        end

        private

        def warnings_enabled?
          ENV['LEYLINE_CACHE_WARNINGS'] != 'false'
        end

        def debug_mode?
          ENV['LEYLINE_DEBUG'] == 'true'
        end

        def structured_logging?
          ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
        end

        def recovery_enabled?
          ENV['LEYLINE_CACHE_AUTO_RECOVERY'] == 'true'
        end

        def build_log_entry(event_type, message, context)
          entry = {
            timestamp: Time.now.iso8601,
            event: event_type,
            message: message,
            **context
          }

          # Add correlation ID if available
          entry[:correlation_id] = Thread.current[:leyline_correlation_id] if Thread.current[:leyline_correlation_id]

          entry
        end

        def output_log(log_entry, level)
          if structured_logging?
            warn JSON.generate(log_entry)
          else
            # Human-readable format
            prefix = level == :error ? 'ERROR' : 'WARNING'
            message = "#{prefix}: [Cache] #{log_entry[:message]}"

            message += " (operation: #{log_entry[:operation]})" if debug_mode? && log_entry[:operation]

            warn message
          end
        end
      end
    end
  end
end
