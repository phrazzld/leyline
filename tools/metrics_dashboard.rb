#!/usr/bin/env ruby
# tools/metrics_dashboard.rb - Validation metrics dashboard and reporting
# Aggregates metrics from validation tools to provide insights into system health,
# performance trends, and actionable remediation guidance.
#
# Requirements:
# - Ruby 2.1+ (for Time.now.iso8601 and JSON support)
# - Standard library: json, time, fileutils, optparse

require 'json'
require 'time'
require 'fileutils'
require 'optparse'

class MetricsDashboard
  def initialize(metrics_dir: 'metrics', output_format: 'text', days_back: 7)
    @metrics_dir = metrics_dir
    @output_format = output_format
    @days_back = days_back
    @aggregated_data = {}
  end

  def generate_dashboard
    metrics_files = load_metrics_files

    if metrics_files.empty?
      puts "No metrics files found in #{@metrics_dir}"
      return
    end

    aggregate_metrics(metrics_files)
    generate_report
  end

  private

  def load_metrics_files
    return [] unless Dir.exist?(@metrics_dir)

    cutoff_time = Time.now - (@days_back * 24 * 60 * 60)

    Dir.glob("#{@metrics_dir}/*.json").select do |file|
      File.mtime(file) >= cutoff_time
    end.sort_by { |file| File.mtime(file) }
  end

  def aggregate_metrics(files)
    @aggregated_data = {
      summary: {
        total_validations: 0,
        successful_validations: 0,
        failed_validations: 0,
        total_duration: 0,
        avg_duration: 0,
        success_rate: 0
      },
      by_tool: {},
      error_patterns: Hash.new(0),
      performance_trends: [],
      time_range: {
        start: nil,
        end: nil
      }
    }

    files.each do |file|
      begin
        data = JSON.parse(File.read(file))
        process_metrics_file(data, file)
      rescue => e
        puts "Warning: Failed to parse metrics file #{file}: #{e.message}"
      end
    end

    calculate_aggregated_statistics
  end

  def process_metrics_file(data, filename)
    tool_name = data.dig('tool_info', 'name') || 'unknown'

    # Initialize tool data if not exists
    @aggregated_data[:by_tool][tool_name] ||= {
      total_runs: 0,
      successful_runs: 0,
      failed_runs: 0,
      total_duration: 0,
      avg_duration: 0,
      success_rate: 0,
      operations: Hash.new { |h, k| h[k] = { count: 0, total_duration: 0, successes: 0 } }
    }

    tool_data = @aggregated_data[:by_tool][tool_name]

    # Process run-level metrics
    success = data.dig('performance', 'success_rate_percent') == 100
    duration = data.dig('timing', 'total_duration_seconds') || 0

    @aggregated_data[:summary][:total_validations] += 1
    tool_data[:total_runs] += 1

    if success
      @aggregated_data[:summary][:successful_validations] += 1
      tool_data[:successful_runs] += 1
    else
      @aggregated_data[:summary][:failed_validations] += 1
      tool_data[:failed_runs] += 1
    end

    @aggregated_data[:summary][:total_duration] += duration
    tool_data[:total_duration] += duration

    # Process error patterns
    error_patterns = data['error_patterns'] || {}
    error_patterns.each do |pattern, count|
      @aggregated_data[:error_patterns][pattern] += count
    end

    # Process operation-level performance data
    operation_stats = data.dig('performance', 'operation_statistics') || {}
    operation_stats.each do |operation, stats|
      op_data = tool_data[:operations][operation]
      op_data[:count] += stats['count'] || 0
      op_data[:total_duration] += stats['total_duration_seconds'] || 0
      op_data[:successes] += (stats['count'] || 0) * (stats['success_rate_percent'] || 0) / 100
    end

    # Track performance trends
    start_time = data.dig('timing', 'start_time')
    if start_time
      @aggregated_data[:performance_trends] << {
        timestamp: start_time,
        tool: tool_name,
        duration: duration,
        success: success,
        operations_count: data.dig('performance', 'total_operations') || 0
      }
    end

    # Update time range
    if start_time
      parsed_time = Time.parse(start_time)
      @aggregated_data[:time_range][:start] = parsed_time if @aggregated_data[:time_range][:start].nil? || parsed_time < @aggregated_data[:time_range][:start]
      @aggregated_data[:time_range][:end] = parsed_time if @aggregated_data[:time_range][:end].nil? || parsed_time > @aggregated_data[:time_range][:end]
    end
  end

  def calculate_aggregated_statistics
    # Calculate summary statistics
    total = @aggregated_data[:summary][:total_validations]
    if total > 0
      @aggregated_data[:summary][:success_rate] =
        (@aggregated_data[:summary][:successful_validations].to_f / total * 100).round(2)
      @aggregated_data[:summary][:avg_duration] =
        (@aggregated_data[:summary][:total_duration] / total).round(3)
    end

    # Calculate per-tool statistics
    @aggregated_data[:by_tool].each do |tool, data|
      if data[:total_runs] > 0
        data[:success_rate] = (data[:successful_runs].to_f / data[:total_runs] * 100).round(2)
        data[:avg_duration] = (data[:total_duration] / data[:total_runs]).round(3)
      end

      # Calculate operation statistics
      data[:operations].each do |operation, op_data|
        if op_data[:count] > 0
          op_data[:avg_duration] = (op_data[:total_duration] / op_data[:count]).round(3)
          op_data[:success_rate] = (op_data[:successes].to_f / op_data[:count] * 100).round(2)
        end
      end
    end
  end

  def generate_report
    case @output_format
    when 'json'
      puts JSON.pretty_generate(@aggregated_data)
    when 'text'
      generate_text_report
    else
      puts "Unknown output format: #{@output_format}"
    end
  end

  def generate_text_report
    puts "📊 Leyline Validation Metrics Dashboard"
    puts "=" * 50
    puts

    # Time range
    if @aggregated_data[:time_range][:start]
      puts "📅 Time Range: #{@aggregated_data[:time_range][:start].strftime('%Y-%m-%d %H:%M')} to #{@aggregated_data[:time_range][:end].strftime('%Y-%m-%d %H:%M')}"
      puts
    end

    # Summary statistics
    summary = @aggregated_data[:summary]
    puts "📈 Summary Statistics"
    puts "-" * 25
    puts "Total Validations: #{summary[:total_validations]}"
    puts "Successful: #{summary[:successful_validations]} (#{summary[:success_rate]}%)"
    puts "Failed: #{summary[:failed_validations]}"
    puts "Average Duration: #{summary[:avg_duration]}s"
    puts "Total Duration: #{summary[:total_duration].round(1)}s"
    puts

    # Success rate indicator
    if summary[:success_rate] >= 95
      puts "✅ System Health: Excellent (#{summary[:success_rate]}%)"
    elsif summary[:success_rate] >= 85
      puts "⚠️  System Health: Good (#{summary[:success_rate]}%)"
    elsif summary[:success_rate] >= 70
      puts "🟡 System Health: Needs Attention (#{summary[:success_rate]}%)"
    else
      puts "🔴 System Health: Critical (#{summary[:success_rate]}%)"
    end
    puts

    # Per-tool breakdown
    puts "🔧 Tool Performance"
    puts "-" * 20
    @aggregated_data[:by_tool].each do |tool, data|
      status = data[:success_rate] >= 95 ? "✅" : data[:success_rate] >= 85 ? "⚠️" : "🔴"
      puts "#{status} #{tool}"
      puts "   Runs: #{data[:total_runs]} | Success Rate: #{data[:success_rate]}% | Avg Duration: #{data[:avg_duration]}s"

      # Show slowest operations
      slow_ops = data[:operations].sort_by { |_, op| -op[:avg_duration] }.first(3)
      unless slow_ops.empty?
        puts "   Slowest Operations:"
        slow_ops.each do |op_name, op_data|
          puts "     - #{op_name}: #{op_data[:avg_duration]}s (#{op_data[:count]} runs, #{op_data[:success_rate]}% success)"
        end
      end
      puts
    end

    # Top error patterns
    top_errors = @aggregated_data[:error_patterns].sort_by { |_, count| -count }.first(10)
    unless top_errors.empty?
      puts "🚨 Top Error Patterns"
      puts "-" * 22
      top_errors.each_with_index do |(pattern, count), index|
        puts "#{index + 1}. #{pattern}: #{count} occurrences"
      end
      puts
    end

    # Performance trends
    if @aggregated_data[:performance_trends].length >= 5
      puts "📊 Performance Trends"
      puts "-" * 21

      # Group by day and calculate daily averages
      daily_stats = @aggregated_data[:performance_trends]
        .group_by { |trend| Time.parse(trend[:timestamp]).strftime('%Y-%m-%d') }
        .transform_values do |trends|
          successful = trends.count { |t| t[:success] }
          {
            total: trends.length,
            success_rate: (successful.to_f / trends.length * 100).round(1),
            avg_duration: (trends.sum { |t| t[:duration] } / trends.length).round(2)
          }
        end

      daily_stats.each do |date, stats|
        trend_indicator = if stats[:success_rate] >= 95
          "✅"
        elsif stats[:success_rate] >= 85
          "⚠️"
        else
          "🔴"
        end
        puts "#{trend_indicator} #{date}: #{stats[:total]} runs, #{stats[:success_rate]}% success, #{stats[:avg_duration]}s avg"
      end
      puts
    end

    # Recommendations
    generate_recommendations
  end

  def generate_recommendations
    puts "💡 Recommendations"
    puts "-" * 18

    recommendations = []

    # Success rate recommendations
    if @aggregated_data[:summary][:success_rate] < 95
      recommendations << "🎯 Improve overall success rate (currently #{@aggregated_data[:summary][:success_rate]}%)"
    end

    # Performance recommendations
    slow_tools = @aggregated_data[:by_tool].select { |_, data| data[:avg_duration] > 5 }
    unless slow_tools.empty?
      recommendations << "⚡ Optimize slow tools: #{slow_tools.keys.join(', ')}"
    end

    # Error pattern recommendations
    top_error = @aggregated_data[:error_patterns].max_by { |_, count| count }
    if top_error && top_error[1] > 5
      recommendations << "🔧 Address top error pattern: #{top_error[0]} (#{top_error[1]} occurrences)"
    end

    # Tool-specific recommendations
    failing_tools = @aggregated_data[:by_tool].select { |_, data| data[:success_rate] < 90 }
    unless failing_tools.empty?
      recommendations << "🚨 Fix failing tools: #{failing_tools.keys.join(', ')}"
    end

    if recommendations.empty?
      puts "🎉 System is performing well! No immediate actions required."
    else
      recommendations.each_with_index do |rec, index|
        puts "#{index + 1}. #{rec}"
      end
    end
    puts
  end
end

# Command line interface
def main
  options = {
    metrics_dir: 'metrics',
    output_format: 'text',
    days_back: 7
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: metrics_dashboard.rb [options]"
    opts.separator ""
    opts.separator "Generate validation metrics dashboard and reports"
    opts.separator ""

    opts.on("-d", "--metrics-dir DIR", "Metrics directory (default: metrics)") do |dir|
      options[:metrics_dir] = dir
    end

    opts.on("-f", "--format FORMAT", "Output format: text, json (default: text)") do |format|
      options[:output_format] = format
    end

    opts.on("--days DAYS", Integer, "Number of days to include (default: 7)") do |days|
      options[:days_back] = days
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit 0
    end
  end.parse!

  dashboard = MetricsDashboard.new(
    metrics_dir: options[:metrics_dir],
    output_format: options[:output_format],
    days_back: options[:days_back]
  )

  dashboard.generate_dashboard
end

# Run the script
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end
