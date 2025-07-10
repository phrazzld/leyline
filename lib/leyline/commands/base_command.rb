# frozen_string_literal: true

require_relative '../version'
require_relative '../errors'

module Leyline
  module Commands
    # Base class for all Leyline commands providing shared functionality
    # Handles common concerns like error handling, option parsing, and output formatting
    class BaseCommand
      def initialize(options = {})
        @options = options
        @base_directory = @options[:directory] || Dir.pwd
        @cache_dir = @options[:cache_dir] || ENV.fetch('LEYLINE_CACHE_DIR', '~/.cache/leyline')
        @cache_dir = File.expand_path(@cache_dir)
      end

      # Execute command - must be implemented by subclasses
      # Returns command result or nil on error
      def execute
        raise NotImplementedError, 'Subclasses must implement execute method'
      end

      protected

      # Common error handling with recovery suggestions
      def handle_error(error, context = {})
        leyline_error = normalize_error(error, context)
        output_error_with_recovery(leyline_error)
      end

      # Print error message and exit with code 1
      def error_and_exit(message)
        puts "Error: #{message}"
        exit 1
      end

      # Output data in requested format (JSON or human-readable)
      def output_result(data)
        if @options[:json] || @options['json']
          output_json(data)
        else
          output_human_readable(data)
        end
      end

      # Check if verbose mode is enabled
      def verbose?
        @options['verbose'] || @options[:verbose]
      end

      # Get leyline docs path
      def leyline_path
        File.join(@base_directory, 'docs', 'leyline')
      end

      # Check if leyline directory exists
      def leyline_exists?
        Dir.exist?(leyline_path)
      end

      # Get categories from options or default
      def categories
        @options[:categories] || []
      end

      private

      # Convert various errors to Leyline errors with recovery guidance
      def normalize_error(error, context = {})
        case error
        when Leyline::LeylineError
          error
        when Errno::EACCES, Errno::EPERM
          path = extract_path_from_error(error)
          Leyline::FileSystemError.new(
            'Permission denied accessing files',
            reason: :permission_denied,
            path: path
          )
        when Errno::ENOENT
          Leyline::FileSystemError.new(
            'File or directory not found',
            reason: :not_found,
            path: context[:path]
          )
        when Errno::ENOSPC
          Leyline::CacheOperationError.new(
            'No space left on device',
            operation_type: :disk_full,
            cache_path: @cache_dir
          )
        when JSON::ParserError
          Leyline::InvalidSyncStateError.new(
            'Data file is corrupted',
            state_file: context[:file]
          )
        else
          # Create generic command error
          command_error_class = self.class.const_get(:CommandError) rescue Leyline::LeylineError
          command_error_class.new(error.message)
        end
      end

      def extract_path_from_error(error)
        return nil unless error.message
        error.message.match(/- (.+)$/)[1]
      rescue StandardError
        nil
      end

      def output_error_with_recovery(error)
        warn "Error: #{error.message}"

        suggestions = error.recovery_suggestions
        if suggestions.any?
          warn "\nTo resolve this issue, try:"
          suggestions.each_with_index do |suggestion, i|
            warn "  #{i + 1}. #{suggestion}"
          end
        end

        if verbose?
          warn "\nDebug information:"
          warn "  Error category: #{error.category}" if error.respond_to?(:category)
          warn "  Context: #{error.context.inspect}" if error.respond_to?(:context) && error.context.any?
          if error.respond_to?(:cause) && error.cause
            warn "  Original error: #{error.cause.class} - #{error.cause.message}"
            warn '  Backtrace:'
            error.cause.backtrace.first(5).each { |line| warn "    #{line}" }
          end
        else
          warn "\nRun with --verbose for more details"
        end
      end

      def output_json(data)
        require 'json'
        puts JSON.pretty_generate(data)
      end

      # Default human-readable output - subclasses should override
      def output_human_readable(data)
        puts data.inspect
      end

      def detect_platform
        require_relative '../platform_helper'
        if Leyline::PlatformHelper.windows?
          'windows'
        elsif Leyline::PlatformHelper.macos?
          'macos'
        elsif Leyline::PlatformHelper.linux?
          'linux'
        else
          'unknown'
        end
      end

      # Measure execution time of a block
      def measure_time(&block)
        start_time = Time.now
        result = yield
        execution_time_ms = ((Time.now - start_time) * 1000).round(2)
        [result, execution_time_ms]
      end

      # Load and cache metadata cache instance
      def metadata_cache
        @metadata_cache ||= begin
          require_relative '../discovery/metadata_cache'
          Discovery::MetadataCache.new(@cache_dir)
        end
      end

      # Load and cache file cache instance
      def file_cache
        @file_cache ||= begin
          require_relative '../cache/file_cache'
          Cache::FileCache.new(@cache_dir)
        rescue StandardError => e
          warn "Warning: Cache initialization failed: #{e.message}" if verbose?
          nil
        end
      end
    end
  end
end
