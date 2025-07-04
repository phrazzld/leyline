#!/usr/bin/env ruby
# lib/yaml_line_tracker.rb - YAML parsing with line number tracking
# Provides enhanced YAML parsing that tracks the line number of each key
# for improved error reporting in validation tools.

require 'psych'
require 'date'
require 'time'

class YAMLLineTracker
  # Parse YAML front-matter with line tracking
  #
  # @param front_matter_text [String] Raw YAML content to parse
  # @return [Hash] Hash containing :data, :line_map, and :errors
  #   - :data - Parsed YAML data (Hash or nil if parse failed)
  #   - :line_map - Hash mapping top-level keys to their line numbers
  #   - :errors - Array of error hashes with context
  def self.parse(front_matter_text)
    result = {
      data: nil,
      line_map: {},
      errors: []
    }

    return result if front_matter_text.nil? || front_matter_text.empty?

    # Attempt to parse YAML using Psych
    begin
      result[:data] = Psych.safe_load(front_matter_text, permitted_classes: [Date, Time])

      # Build line mapping for successful parse
      result[:line_map] = build_line_map(front_matter_text, result[:data]) if result[:data].is_a?(Hash)
    rescue Psych::SyntaxError => e
      # Capture syntax error with line/column information
      result[:errors] << {
        type: 'yaml_syntax',
        line: e.line,
        column: e.column,
        message: "YAML syntax error: #{e.message}",
        suggestion: "Check YAML syntax around line #{e.line}. Common issues: unquoted colons, incorrect indentation, missing quotes around strings with special characters."
      }
    rescue StandardError => e
      # Catch any other parsing errors
      result[:errors] << {
        type: 'yaml_parse',
        line: nil,
        column: nil,
        message: "YAML parsing failed: #{e.message}",
        suggestion: 'Ensure the content is valid YAML format between --- delimiters.'
      }
    end

    result
  end

  # Build a mapping of top-level YAML keys to their line numbers
  #
  # @param yaml_text [String] Raw YAML content
  # @param parsed_data [Hash] Successfully parsed YAML data
  # @return [Hash] Mapping of key names to line numbers
  def self.build_line_map(yaml_text, parsed_data)
    line_map = {}
    return line_map unless parsed_data.is_a?(Hash)

    lines = yaml_text.split("\n")

    # Scan each line to find top-level keys
    lines.each_with_index do |line, index|
      line_number = index + 1 # Line numbers are 1-based

      # Look for top-level key patterns (key: value or key:)
      # Must be at start of line (no indentation for top-level keys)
      next unless line =~ /^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:/

      key_name = ::Regexp.last_match(1)

      # Only map keys that exist in the parsed data
      line_map[key_name] = line_number if parsed_data.key?(key_name)
    end

    line_map
  end
end
