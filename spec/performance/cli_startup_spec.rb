# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'support/shared_examples/performance_testing'

RSpec.describe 'CLI Startup Performance', :performance do
  let(:test_dirs) do
    {
      target: Dir.mktmpdir('startup-perf-target'),
      cache: Dir.mktmpdir('startup-perf-cache')
    }
  end

  let(:ruby_exe) { RbConfig.ruby }
  let(:leyline_executable) { File.expand_path('../../bin/leyline', __dir__) }

  before do
    setup_test_environment
    create_basic_test_data
  end

  after do
    cleanup_test_environment
  end

  describe 'CLI Startup Time' do
    let(:startup_command_block) { proc { measure_cli_startup_time('version') } }

    include_examples 'reliable performance measurement', 'startup', :startup_command_block

    it 'meets startup time requirement of under 1 second' do
      # Measure startup time across different command scenarios
      commands = ['version', 'help', 'discovery categories']
      startup_times = []

      commands.each do |cmd|
        metrics = measure_command_with_statistics("startup_#{cmd.gsub(' ', '_')}") do
          measure_cli_startup_time(cmd)
        end
        startup_times << {
          command: cmd,
          p95_seconds: metrics[:p95_seconds],
          median_seconds: metrics[:median_seconds],
          success_rate: metrics[:success_rate]
        }
      end

      # Validate that all command scenarios meet the 1-second requirement
      aggregate_failures 'startup time requirements' do
        startup_times.each do |result|
          expect(result[:p95_seconds]).to be < 1.0,
                                           "#{result[:command]}: P95 startup time #{result[:p95_seconds].round(3)}s exceeds 1-second requirement"
          expect(result[:success_rate]).to be >= 0.9,
                                           "#{result[:command]}: Success rate #{(result[:success_rate] * 100).round(1)}% too low"
        end
      end

      # Display results
      puts "\n⚡ CLI STARTUP PERFORMANCE RESULTS"
      puts '=' * 60
      startup_times.each do |result|
        puts "#{result[:command].ljust(20)}: P95=#{(result[:p95_seconds] * 1000).round(1)}ms, " \
             "Median=#{(result[:median_seconds] * 1000).round(1)}ms, " \
             "Success=#{(result[:success_rate] * 100).round(1)}%"
      end
      puts '=' * 60
      puts "✅ All commands meet <1000ms startup requirement"
    end
  end

  describe 'Cold vs Warm Startup' do
    it 'measures performance difference between cold and warm starts' do
      # Cold start (clear all caches)
      clear_all_caches
      cold_metrics = measure_command_with_statistics('cold_startup') do
        measure_cli_startup_time('version')
      end

      # Warm start (with caches populated)
      warm_up_caches
      warm_metrics = measure_command_with_statistics('warm_startup') do
        measure_cli_startup_time('version')
      end

      # Analyze the difference
      cold_p95 = cold_metrics[:p95_seconds]
      warm_p95 = warm_metrics[:p95_seconds]
      improvement = (cold_p95 - warm_p95) / cold_p95

      puts "\n🔥 COLD VS WARM STARTUP COMPARISON"
      puts '=' * 50
      puts "Cold start P95: #{(cold_p95 * 1000).round(1)}ms"
      puts "Warm start P95: #{(warm_p95 * 1000).round(1)}ms"
      puts "Improvement: #{(improvement * 100).round(1)}%"
      puts '=' * 50

      # Both should be under 1 second
      expect(cold_p95).to be < 1.0, "Cold startup exceeds 1-second requirement"
      expect(warm_p95).to be < 1.0, "Warm startup exceeds 1-second requirement"
    end
  end

  describe 'Startup Time Regression Detection' do
    it 'detects if startup time has regressed from baseline' do
      # Current startup performance
      current_metrics = measure_command_with_statistics('current_startup') do
        measure_cli_startup_time('version')
      end

      # Historical baseline (mock data based on requirements)
      historical_baseline = {
        median_seconds: 0.3,    # 300ms baseline
        p95_seconds: 0.6,       # 600ms P95 baseline
        success_rate: 0.98,     # 98% success rate
        recorded_at: (Time.now - 7 * 24 * 3600).iso8601
      }

      # Perform regression analysis
      regression_analysis = perform_statistical_regression_analysis(
        historical_baseline,
        current_metrics
      )

      # Validate regression detection
      if regression_analysis[:regression_detected]
        puts "⚠️  Startup performance regression detected!"
        puts "P95 change: #{(regression_analysis[:p95_change_ratio] * 100).round(1)}% of baseline"
        puts "Median change: #{(regression_analysis[:median_change_ratio] * 100).round(1)}% of baseline"
      else
        puts "✅ No startup performance regression detected"
      end

      # Should not have significant regression (>50% degradation)
      expect(regression_analysis[:p95_change_ratio]).to be < 1.5,
                                                         "Significant startup performance regression detected"
    end
  end

  describe 'Memory Usage During Startup' do
    it 'measures memory consumption during CLI startup' do
      # Test memory usage for different commands
      commands = ['version', 'help', 'discovery categories']
      memory_results = []

      commands.each do |cmd|
        metrics = measure_command_with_statistics("memory_#{cmd.gsub(' ', '_')}") do
          measure_cli_startup_time(cmd)
        end
        memory_results << {
          command: cmd,
          p95_memory_mb: metrics[:p95_memory_mb],
          median_memory_mb: metrics[:median_memory_mb]
        }
      end

      # Validate memory usage is reasonable (under 50MB for startup)
      aggregate_failures 'memory usage validation' do
        memory_results.each do |result|
          expect(result[:p95_memory_mb]).to be < 50,
                                            "#{result[:command]}: P95 memory usage #{result[:p95_memory_mb].round(1)}MB too high"
        end
      end

      puts "\n💾 MEMORY USAGE DURING STARTUP"
      puts '=' * 50
      memory_results.each do |result|
        puts "#{result[:command].ljust(20)}: P95=#{result[:p95_memory_mb].round(1)}MB, " \
             "Median=#{result[:median_memory_mb].round(1)}MB"
      end
      puts '=' * 50
    end
  end

  private

  def setup_test_environment
    @original_cache_dir = ENV['LEYLINE_CACHE_DIR']
    ENV['LEYLINE_CACHE_DIR'] = test_dirs[:cache]

    # Ensure leyline executable is available
    unless File.exist?(leyline_executable)
      skip "Leyline executable not found at #{leyline_executable}"
    end
  end

  def cleanup_test_environment
    ENV['LEYLINE_CACHE_DIR'] = @original_cache_dir
    test_dirs.values.each { |dir| FileUtils.rm_rf(dir) if Dir.exist?(dir) }
  end

  def create_basic_test_data
    # Create minimal test data for commands that might need it
    docs_dir = File.join(test_dirs[:target], 'docs', 'leyline')
    FileUtils.mkdir_p(File.join(docs_dir, 'tenets'))
    FileUtils.mkdir_p(File.join(docs_dir, 'bindings', 'core'))

    # Create a simple tenet for discovery commands
    tenet_content = <<~CONTENT
      ---
      id: test-tenet
      last_modified: '2025-07-09'
      version: '0.1.0'
      ---

      # Test Tenet

      Simple test tenet for performance testing.
    CONTENT

    File.write(File.join(docs_dir, 'tenets', 'test-tenet.md'), tenet_content)
  end

  def measure_cli_startup_time(command)
    # Use subprocess to measure true startup time
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Execute CLI command in subprocess
    result = system(ruby_exe, leyline_executable, *command.split, out: File::NULL, err: File::NULL)

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    {
      success: result == true,
      execution_time: end_time - start_time
    }
  end

  def clear_all_caches
    # Clear file system caches
    FileUtils.rm_rf(test_dirs[:cache]) if Dir.exist?(test_dirs[:cache])
    FileUtils.mkdir_p(test_dirs[:cache])

    # Clear Ruby require cache for clean measurement
    # Note: This is tricky in test environment, so we skip it
  end

  def warm_up_caches
    # Pre-populate caches by running a command
    3.times do
      measure_cli_startup_time('version')
    end
  end

  def setup_test_data_with_size(file_count)
    # Implementation for scalability testing if needed
    # For startup tests, data size shouldn't significantly impact startup time
    create_basic_test_data
  end
end
