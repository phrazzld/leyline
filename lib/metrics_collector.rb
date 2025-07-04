#!/usr/bin/env ruby
# lib/metrics_collector.rb - Comprehensive metrics collection for validation tools
# Provides centralized collection of performance metrics, success rates, and error patterns
# for observability and continuous improvement of validation processes.
#
# Requirements:
# - Ruby 2.1+ (for Time.now.iso8601 and JSON support)
# - Standard library: json, securerandom, time, fileutils

require 'json'
require 'securerandom'
require 'time'
require 'fileutils'

class MetricsCollector
  attr_reader :correlation_id, :start_time

  def initialize(tool_name:, tool_version: '1.0.0')
    @tool_name = tool_name
    @tool_version = tool_version
    @correlation_id = SecureRandom.uuid
    @start_time = Time.now
    @metrics = {}
    @timers = {}
    @counters = {}
    @performance_data = []
    @error_patterns = Hash.new(0)
  end

  # Record a performance timing with context
  def record_timing(operation:, duration_seconds:, success: true, metadata: {})
    timing_record = {
      operation: operation,
      duration_seconds: duration_seconds.round(3),
      success: success,
      timestamp: Time.now.iso8601,
      correlation_id: @correlation_id,
      **metadata
    }

    @performance_data << timing_record
    log_structured_timing(timing_record) if structured_logging_enabled?
  end

  # Start a timer for an operation
  def start_timer(operation:)
    @timers[operation] = Time.now
  end

  # End a timer and record the timing
  def end_timer(operation:, success: true, metadata: {})
    start_time = @timers.delete(operation)
    return unless start_time

    duration = Time.now - start_time
    record_timing(
      operation: operation,
      duration_seconds: duration,
      success: success,
      metadata: metadata
    )
  end

  # Increment a counter
  def increment_counter(metric:, value: 1, labels: {})
    key = "#{metric}_#{labels.hash}"
    @counters[key] ||= {
      metric: metric,
      labels: labels,
      value: 0,
      last_updated: Time.now.iso8601
    }
    @counters[key][:value] += value
    @counters[key][:last_updated] = Time.now.iso8601
  end

  # Record error pattern for analysis
  def record_error_pattern(error_type:, component:, frequency: 1, context: {})
    pattern_key = "#{error_type}:#{component}"
    @error_patterns[pattern_key] += frequency

    return unless structured_logging_enabled?

    log_structured('error_pattern_recorded', {
                     error_type: error_type,
                     component: component,
                     frequency: frequency,
                     total_occurrences: @error_patterns[pattern_key],
                     context: context
                   })
  end

  # Get comprehensive metrics summary
  def get_metrics_summary
    end_time = Time.now
    total_duration = (end_time - @start_time).round(3)

    # Calculate success rates
    total_operations = @performance_data.length
    successful_operations = @performance_data.count { |p| p[:success] }
    success_rate = total_operations > 0 ? (successful_operations.to_f / total_operations * 100).round(2) : 0

    # Calculate performance statistics
    operation_stats = calculate_operation_statistics

    {
      tool_info: {
        name: @tool_name,
        version: @tool_version,
        correlation_id: @correlation_id
      },
      timing: {
        start_time: @start_time.iso8601,
        end_time: end_time.iso8601,
        total_duration_seconds: total_duration
      },
      performance: {
        total_operations: total_operations,
        successful_operations: successful_operations,
        failed_operations: total_operations - successful_operations,
        success_rate_percent: success_rate,
        operation_statistics: operation_stats
      },
      counters: @counters.values,
      error_patterns: @error_patterns,
      raw_performance_data: @performance_data
    }
  end

  # Export metrics as JSON
  def to_json(*_args)
    JSON.pretty_generate(get_metrics_summary)
  end

  # Save metrics to file for aggregation
  def save_metrics(output_dir: 'metrics')
    FileUtils.mkdir_p(output_dir)
    timestamp = @start_time.strftime('%Y%m%d_%H%M%S')
    filename = "#{output_dir}/#{@tool_name}_#{timestamp}_#{@correlation_id[0..7]}.json"

    File.write(filename, to_json)

    if structured_logging_enabled?
      log_structured('metrics_saved', {
                       filename: filename,
                       total_operations: @performance_data.length,
                       success_rate: calculate_success_rate
                     })
    end

    filename
  end

  # Log validation completion summary
  def log_completion_summary
    return unless structured_logging_enabled?

    summary = {
      event: 'validation_completion',
      correlation_id: @correlation_id,
      timestamp: Time.now.iso8601,
      tool: @tool_name,
      duration_seconds: (Time.now - @start_time).round(3),
      success_rate_percent: calculate_success_rate,
      total_operations: @performance_data.length,
      error_patterns_count: @error_patterns.size,
      top_error_patterns: @error_patterns.sort_by { |_, count| -count }.first(5).to_h
    }

    begin
      warn JSON.generate(summary)
    rescue StandardError => e
      warn "Warning: Metrics logging failed: #{e.message}"
    end
  end

  # Get actionable remediation guidance based on error patterns
  def get_remediation_guidance
    guidance = []

    @error_patterns.each do |pattern, count|
      error_type, component = pattern.split(':', 2)

      guidance << case error_type
                  when 'missing_field'
                    {
                      pattern: pattern,
                      occurrences: count,
                      severity: count > 5 ? 'high' : 'medium',
                      recommendation: "Add missing required field '#{component}' to YAML front-matter",
                      action: 'Review field requirements in TENET_FORMATTING.md'
                    }
                  when 'invalid_format'
                    {
                      pattern: pattern,
                      occurrences: count,
                      severity: count > 3 ? 'high' : 'low',
                      recommendation: "Fix format validation for '#{component}'",
                      action: 'Check format requirements and update accordingly'
                    }
                  when 'performance_degradation'
                    {
                      pattern: pattern,
                      occurrences: count,
                      severity: 'medium',
                      recommendation: "Optimize performance for '#{component}' operations",
                      action: 'Consider caching, parallel processing, or algorithm improvements'
                    }
                  else
                    {
                      pattern: pattern,
                      occurrences: count,
                      severity: 'low',
                      recommendation: "Review error pattern '#{error_type}' in '#{component}'",
                      action: 'Investigate root cause and implement targeted fix'
                    }
                  end
    end

    guidance.sort_by do |g|
      [if g[:severity] == 'high'
         0
       else
         g[:severity] == 'medium' ? 1 : 2
       end, -g[:occurrences]]
    end
  end

  private

  def structured_logging_enabled?
    ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
  end

  def log_structured(event, data = {})
    log_entry = {
      event: event,
      correlation_id: @correlation_id,
      timestamp: Time.now.iso8601,
      tool: @tool_name,
      **data
    }

    warn JSON.generate(log_entry)
  rescue StandardError => e
    warn "Warning: Structured logging failed: #{e.message}"
  end

  def log_structured_timing(timing_record)
    log_structured('performance_timing', timing_record)
  end

  def calculate_success_rate
    return 0 if @performance_data.empty?

    successful = @performance_data.count { |p| p[:success] }
    (successful.to_f / @performance_data.length * 100).round(2)
  end

  def calculate_operation_statistics
    return {} if @performance_data.empty?

    stats_by_operation = @performance_data.group_by { |p| p[:operation] }

    stats_by_operation.transform_values do |operations|
      durations = operations.map { |op| op[:duration_seconds] }
      successes = operations.count { |op| op[:success] }

      {
        count: operations.length,
        success_rate_percent: (successes.to_f / operations.length * 100).round(2),
        avg_duration_seconds: (durations.sum / durations.length).round(3),
        min_duration_seconds: durations.min.round(3),
        max_duration_seconds: durations.max.round(3),
        total_duration_seconds: durations.sum.round(3)
      }
    end
  end
end
