# frozen_string_literal: true

require 'yaml'
require_relative '../errors'

module Leyline
  module Configuration
    # Parser for .leyline configuration files
    # Handles project-specific category selection and configuration
    class LeylineFile
      class ConfigurationError < Leyline::LeylineError
        def error_type
          :configuration
        end

        def recovery_suggestions
          [
            'Check .leyline file syntax (must be valid YAML)',
            'Ensure categories is an array of strings',
            'Validate version constraint format (e.g., ">=2.0.0")',
            'Run leyline categories to see available categories'
          ]
        end
      end

      DEFAULT_FILENAME = '.leyline'
      ALLOWED_KEYS = %w[categories version docs_path].freeze

      attr_reader :categories, :version, :docs_path

      # Load configuration from a directory
      # Returns nil if no .leyline file exists
      def self.load(directory = Dir.pwd)
        file_path = File.join(directory, DEFAULT_FILENAME)
        return nil unless File.exist?(file_path)

        new(file_path)
      end

      # Initialize from a file path
      def initialize(file_path)
        @file_path = file_path
        @categories = []
        @version = nil
        @docs_path = 'docs/leyline'

        parse_file
        validate_configuration
      end

      # Check if configuration is valid
      def valid?
        @errors.empty?
      end

      # Get validation errors
      def errors
        @errors.dup
      end

      # Convert to hash representation
      def to_h
        {
          categories: @categories,
          version: @version,
          docs_path: @docs_path
        }
      end

      private

      def parse_file
        @errors = []

        begin
          content = File.read(@file_path)
          data = YAML.safe_load(content, permitted_classes: [Symbol])

          # Handle empty file
          return if data.nil?

          unless data.is_a?(Hash)
            @errors << 'Configuration must be a YAML hash'
            return
          end

          # Parse known keys
          @categories = parse_categories(data['categories'])
          @version = parse_version(data['version'])
          @docs_path = parse_docs_path(data['docs_path'])

          # Warn about unknown keys
          unknown_keys = data.keys - ALLOWED_KEYS
          unless unknown_keys.empty?
            @errors << "Unknown configuration keys: #{unknown_keys.join(', ')}"
          end
        rescue Psych::SyntaxError => e
          @errors << "YAML syntax error: #{e.message}"
        rescue StandardError => e
          @errors << "Failed to parse configuration: #{e.message}"
        end
      end

      def parse_categories(value)
        return [] if value.nil?

        unless value.is_a?(Array)
          @errors << 'categories must be an array'
          return []
        end

        invalid_categories = value.reject { |c| c.is_a?(String) && !c.empty? }
        unless invalid_categories.empty?
          @errors << "Invalid categories: #{invalid_categories.inspect}"
        end

        value.select { |c| c.is_a?(String) && !c.empty? }.uniq
      end

      def parse_version(value)
        return nil if value.nil?

        unless value.is_a?(String)
          @errors << 'version must be a string'
          return nil
        end

        # Basic version constraint validation
        unless value.match?(/^[><=~]+\s*\d+\.\d+(\.\d+)?/)
          @errors << "Invalid version constraint: #{value}"
          return nil
        end

        value
      end

      def parse_docs_path(value)
        return 'docs/leyline' if value.nil?

        unless value.is_a?(String)
          @errors << 'docs_path must be a string'
          return 'docs/leyline'
        end

        # Normalize path
        value.strip
      end

      def validate_configuration
        # Additional validation rules

        # Categories should not be empty (warning, not error)
        if @categories.empty? && @errors.empty?
          # This is just informational, not an error
          # The sync command will handle empty categories appropriately
        end

        # Check for common mistakes
        if @categories.include?('all')
          @errors << "Use specific category names instead of 'all'"
        end

        # Ensure core is not explicitly listed (it's always included)
        if @categories.include?('core')
          @categories.delete('core')
          # Not an error, just silently remove it
        end
      end
    end
  end
end
