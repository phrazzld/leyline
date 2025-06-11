#!/usr/bin/env ruby
# lib/error_collector.rb - Structured error aggregation for validation tools
# Provides centralized collection of validation errors with full context
# for enhanced error reporting and debugging.

class ErrorCollector
  def initialize
    @errors = []
  end

  # Add a structured error with full context
  #
  # @param file [String] File path where error occurred
  # @param line [Integer, nil] Line number of error (nil if not applicable)
  # @param field [String, nil] YAML field name causing error (nil if not field-specific)
  # @param type [String] Error type/category for classification
  # @param message [String] Human-readable error description
  # @param suggestion [String, nil] Actionable fix suggestion (nil if no suggestion available)
  def add_error(file:, line: nil, field: nil, type:, message:, suggestion: nil)
    @errors << {
      file: file,
      line: line,
      field: field,
      type: type,
      message: message,
      suggestion: suggestion
    }
  end

  # Get all collected errors
  #
  # @return [Array<Hash>] Array of error hashes with context
  def errors
    @errors.dup
  end

  # Check if any errors have been collected
  #
  # @return [Boolean] True if errors exist, false otherwise
  def any?
    !@errors.empty?
  end

  # Get count of collected errors
  #
  # @return [Integer] Number of errors collected
  def count
    @errors.length
  end

  # Clear all collected errors
  def clear
    @errors.clear
  end
end
