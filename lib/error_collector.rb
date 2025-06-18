#!/usr/bin/env ruby
# lib/error_collector.rb - Structured error aggregation for validation tools
# Provides centralized collection of validation errors with full context
# for enhanced error reporting and debugging.

require 'json'
require 'securerandom'

class ErrorCollector
  def initialize
    @errors = []
    @correlation_id = SecureRandom.uuid
    @start_time = Time.now
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
    error_record = {
      file: file,
      line: line,
      field: field,
      type: type,
      message: message,
      suggestion: suggestion,
      correlation_id: @correlation_id,
      timestamp: Time.now.iso8601
    }

    @errors << error_record

    # Log structured JSON if enabled
    log_structured_error(error_record) if structured_logging_enabled?
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

  # Get the correlation ID for this validation session
  #
  # @return [String] Unique correlation ID
  def correlation_id
    @correlation_id
  end

  # Export all errors as structured JSON
  #
  # @return [String] JSON representation of all errors with metadata
  def to_json
    {
      correlation_id: @correlation_id,
      start_time: @start_time.iso8601,
      end_time: Time.now.iso8601,
      duration_seconds: (Time.now - @start_time).round(3),
      error_count: @errors.length,
      errors: @errors
    }.to_json
  end

  # Output validation summary as structured JSON
  def log_validation_summary
    return unless structured_logging_enabled?

    summary = {
      event: 'validation_summary',
      correlation_id: @correlation_id,
      timestamp: Time.now.iso8601,
      duration_seconds: (Time.now - @start_time).round(3),
      total_errors: @errors.length,
      error_types: @errors.group_by { |e| e[:type] }.transform_values(&:count),
      files_with_errors: @errors.map { |e| e[:file] }.uniq.count
    }

    STDERR.puts JSON.generate(summary)
  end

  private

  # Check if structured logging is enabled via environment variable
  def structured_logging_enabled?
    ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
  end

  # Log a single error as structured JSON to STDERR
  def log_structured_error(error_record)
    log_entry = {
      event: 'validation_error',
      **error_record
    }

    STDERR.puts JSON.generate(log_entry)
  end
end
