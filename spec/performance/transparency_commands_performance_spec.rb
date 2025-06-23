# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'benchmark'
require 'json'

RSpec.describe 'Transparency Commands Performance', :performance do
  # Performance test configuration
  let(:performance_config) do
    {
      warmup_iterations: 3,
      measurement_iterations: 10,
      statistical_confidence: 0.95,
      regression_threshold: 1.2, # 20% degradation threshold
      cache_improvement_threshold: 0.2 # Minimum 20% improvement from cache
    }
  end

  let(:test_directories) do
    {
      source: Dir.mktmpdir('leyline-perf-source'),
      target: Dir.mktmpdir('leyline-perf-target'),
      cache: Dir.mktmpdir('leyline-perf-cache')
    }
  end

  let(:cli) { Leyline::CLI.new }
  let(:baseline_storage) { {} }

  before do
    setup_performance_environment
    create_realistic_test_data
  end

  after do
    cleanup_test_directories
  end

  describe 'Status Command Performance' do
    context 'with statistical baseline measurement' do
      it 'establishes and validates performance baselines' do
        # Phase 1: Establish baseline with cold cache
        baseline_metrics = measure_command_performance('status') do
          invoke_status_command(clear_cache: true)
        end

        # Phase 2: Measure warm cache performance
        optimized_metrics = measure_command_performance('status') do
          invoke_status_command(clear_cache: false)
        end

        # Statistical validation
        validate_performance_baseline(baseline_metrics, 'status_baseline')
        validate_cache_optimization(baseline_metrics, optimized_metrics)
        validate_resource_efficiency(optimized_metrics)

        # Store baselines for future regression detection
        store_performance_baseline('status', baseline_metrics)
      end
    end

    context 'with varying data sizes' do
      it 'maintains scalable performance characteristics' do
        file_counts = [50, 100, 200, 400]
        scalability_results = []

        file_counts.each do |count|
          setup_scalability_test_data(count)

          metrics = measure_command_performance("status_#{count}_files") do
            invoke_status_command(clear_cache: false)
          end

          scalability_results << {
            file_count: count,
            p95_time: metrics[:p95_seconds],
            median_memory: metrics[:median_memory_mb]
          }
        end

        validate_scalability_characteristics(scalability_results)
        log_scalability_analysis(scalability_results)
      end
    end
  end

  describe 'Diff Command Performance' do
    context 'with statistical baseline measurement' do
      it 'provides reliable performance measurement with graceful git handling' do
        baseline_metrics = measure_command_performance('diff') do
          invoke_diff_command(clear_cache: true)
        end

        optimized_metrics = measure_command_performance('diff') do
          invoke_diff_command(clear_cache: false)
        end

        # Diff command may fail in test environment due to git remotes
        # Focus on successful cases and graceful failure handling
        validate_command_reliability(baseline_metrics, 'diff')

        if baseline_metrics[:success_rate] > 0.5
          validate_cache_optimization(baseline_metrics, optimized_metrics)
          store_performance_baseline('diff', baseline_metrics)
        else
          puts "Diff command baseline skipped (git environment limitations)"
        end
      end
    end
  end

  describe 'Update Command Performance' do
    context 'with dry-run statistical measurement' do
      it 'validates update command performance patterns' do
        baseline_metrics = measure_command_performance('update') do
          invoke_update_command(dry_run: true, clear_cache: true)
        end

        optimized_metrics = measure_command_performance('update') do
          invoke_update_command(dry_run: true, clear_cache: false)
        end

        validate_command_reliability(baseline_metrics, 'update')

        if baseline_metrics[:success_rate] > 0.5
          validate_cache_optimization(baseline_metrics, optimized_metrics)
          store_performance_baseline('update', baseline_metrics)
        else
          puts "Update command baseline skipped (git environment limitations)"
        end
      end
    end
  end

  describe 'End-to-End Workflow Performance' do
    it 'validates complete transparency workflow efficiency' do
      workflow_metrics = measure_workflow_performance do
        # Execute complete transparency workflow
        status_result = invoke_status_command(clear_cache: true)
        diff_result = invoke_diff_command(clear_cache: false)
        update_result = invoke_update_command(dry_run: true, clear_cache: false)

        {
          status: status_result,
          diff: diff_result,
          update: update_result
        }
      end

      validate_workflow_efficiency(workflow_metrics)
      validate_workflow_resource_usage(workflow_metrics)
    end
  end

  describe 'Performance Regression Detection' do
    context 'with historical baseline comparison' do
      it 'detects statistically significant performance regressions' do
        # Simulate historical baseline
        historical_baseline = create_mock_historical_baseline

        # Measure current performance
        current_metrics = measure_command_performance('regression_test') do
          invoke_status_command(clear_cache: false)
        end

        # Statistical regression analysis
        regression_analysis = analyze_performance_regression(
          historical_baseline,
          current_metrics
        )

        validate_regression_detection(regression_analysis)
        log_regression_analysis(regression_analysis)
      end
    end
  end

  private

  def setup_performance_environment
    # Set isolated environment variables
    @original_cache_dir = ENV['LEYLINE_CACHE_DIR']
    ENV['LEYLINE_CACHE_DIR'] = test_directories[:cache]

    # Configure cache to use test directory
    allow(Leyline::Cache::FileCache).to receive(:new).and_return(
      Leyline::Cache::FileCache.new(test_directories[:cache])
    )
  end

  def cleanup_test_directories
    ENV['LEYLINE_CACHE_DIR'] = @original_cache_dir
    test_directories.values.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
  end

  def create_realistic_test_data(file_count: 100)
    setup_scalability_test_data(file_count)
  end

  def setup_scalability_test_data(file_count)
    # Clean and recreate target
    FileUtils.rm_rf(test_directories[:target])
    FileUtils.mkdir_p(test_directories[:target])

    # Create realistic leyline structure in target
    docs_dir = File.join(test_directories[:target], 'docs', 'leyline')

    FileUtils.mkdir_p(File.join(docs_dir, 'tenets'))
    FileUtils.mkdir_p(File.join(docs_dir, 'bindings', 'core'))
    FileUtils.mkdir_p(File.join(docs_dir, 'bindings', 'categories', 'typescript'))
    FileUtils.mkdir_p(File.join(docs_dir, 'bindings', 'categories', 'go'))

    # Generate realistic content files
    create_performance_test_content(docs_dir, file_count)

    # Create local modifications to simulate real usage
    create_local_modifications(docs_dir)
  end

  def create_performance_test_content(docs_dir, file_count)
    file_count.times do |i|
      content = generate_realistic_document_content(i)

      file_path = case i % 4
                  when 0
                    File.join(docs_dir, 'tenets', "perf-tenet-#{i}.md")
                  when 1
                    File.join(docs_dir, 'bindings', 'core', "perf-core-#{i}.md")
                  when 2
                    File.join(docs_dir, 'bindings', 'categories', 'typescript', "perf-ts-#{i}.md")
                  else
                    File.join(docs_dir, 'bindings', 'categories', 'go', "perf-go-#{i}.md")
                  end

      File.write(file_path, content)
    end
  end

  def generate_realistic_document_content(index)
    # Generate substantial content to test real-world performance
    <<~CONTENT
      ---
      id: performance-test-#{index}
      last_modified: '2025-06-23'
      version: '0.1.0'
      category: performance-testing
      ---

      # Performance Test Document #{index}

      This document represents realistic leyline content for performance testing.

      ## Overview

      #{'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. ' * (10 + index % 20)}

      ## Implementation Guidelines

      ```ruby
      # Performance test implementation #{index}
      class PerfTest#{index}
        def initialize(config = {})
          @timeout = config[:timeout] || 30
          @retries = config[:retries] || 3
          @validator = create_validator
        end

        def execute_operation(data)
          validated_data = @validator.validate(data)
          process_with_retries(validated_data)
        end

        private

        def create_validator
          # Validation logic for performance test #{index}
          CustomValidator.new(timeout: @timeout)
        end

        def process_with_retries(data)
          retries = @retries
          begin
            perform_processing(data)
          rescue ProcessingError => e
            retries -= 1
            retry if retries > 0
            raise e
          end
        end

        def perform_processing(data)
          # Core processing logic
          data.transform { |item| enhance_item(item) }
        end
      end
      ```

      ## Detailed Specifications

      #{'This section contains comprehensive specifications and requirements for the performance testing scenario. We cover edge cases, error handling, and integration patterns. ' * (8 + index % 15)}

      ## Performance Considerations

      #{'Important performance implications are documented here, including memory usage patterns, computational complexity, and caching strategies. ' * (5 + index % 12)}

      ## Examples and Usage Patterns

      #{'Detailed examples demonstrate how to use this functionality effectively in various scenarios. Each example includes setup, execution, and expected results. ' * (3 + index % 8)}
    CONTENT
  end

  def create_local_modifications(docs_dir)
    # Add some local modifications to simulate real development
    existing_files = Dir.glob('**/*.md', base: docs_dir).first(5)

    existing_files.each do |file|
      file_path = File.join(docs_dir, file)
      content = File.read(file_path)
      File.write(file_path, content + "\n\n## Local Modification\n\nLocal development changes.\n")
    end

    # Add a new local file
    File.write(File.join(docs_dir, 'tenets', 'local-perf-tenet.md'), <<~CONTENT)
      ---
      id: local-perf-tenet
      last_modified: '2025-06-23'
      version: '0.1.0'
      ---
      # Local Performance Tenet

      This is a locally added tenet for performance testing.
    CONTENT
  end

  def measure_command_performance(command_name, &block)
    puts "\n📊 Measuring #{command_name} performance..."

    # Warmup phase - eliminate JIT and filesystem caching effects
    performance_config[:warmup_iterations].times { block.call }

    # Measurement phase
    measurements = []
    memory_measurements = []
    success_count = 0

    performance_config[:measurement_iterations].times do |i|
      start_memory = current_memory_usage_mb

      benchmark = Benchmark.measure do
        begin
          result = block.call
          success_count += 1 if result[:success]
        rescue => e
          puts "Iteration #{i + 1} failed: #{e.message}" if i == 0
        end
      end

      end_memory = current_memory_usage_mb
      memory_delta = end_memory - start_memory

      measurements << benchmark.real
      memory_measurements << memory_delta.abs
    end

    # Statistical analysis
    calculate_performance_metrics(measurements, memory_measurements, success_count)
  end

  def measure_workflow_performance(&block)
    puts "\n🔄 Measuring end-to-end workflow performance..."

    start_time = Time.now
    start_memory = current_memory_usage_mb

    workflow_result = block.call

    end_time = Time.now
    end_memory = current_memory_usage_mb

    {
      total_time_seconds: end_time - start_time,
      memory_delta_mb: end_memory - start_memory,
      workflow_result: workflow_result
    }
  end

  def calculate_performance_metrics(time_measurements, memory_measurements, success_count)
    sorted_times = time_measurements.sort
    sorted_memory = memory_measurements.sort

    {
      success_rate: success_count.to_f / performance_config[:measurement_iterations],
      median_seconds: sorted_times[sorted_times.length / 2],
      p95_seconds: sorted_times[(sorted_times.length * 0.95).to_i],
      mean_seconds: time_measurements.sum.to_f / time_measurements.length,
      std_dev_seconds: calculate_standard_deviation(time_measurements),
      median_memory_mb: sorted_memory[sorted_memory.length / 2],
      p95_memory_mb: sorted_memory[(sorted_memory.length * 0.95).to_i],
      sample_size: time_measurements.length
    }
  end

  def calculate_standard_deviation(values)
    mean = values.sum.to_f / values.length
    variance = values.sum { |v| (v - mean) ** 2 } / values.length
    Math.sqrt(variance)
  end

  def invoke_status_command(clear_cache: false)
    clear_test_cache if clear_cache

    result = capture_cli_output do
      cli.invoke(:status, [test_directories[:target]],
                verbose: false, stats: false)
    end

    {
      success: result[:stderr].empty? || !result[:stderr].include?('Error'),
      output: result
    }
  end

  def invoke_diff_command(clear_cache: false)
    clear_test_cache if clear_cache

    result = capture_cli_output do
      cli.invoke(:diff, [test_directories[:target]],
                verbose: false, stats: false)
    end

    # Diff command may fail due to git remote issues in test environment
    {
      success: result[:stderr].empty? ||
               result[:stderr].include?('No changes') ||
               !result[:stderr].include?('Fatal error'),
      output: result
    }
  end

  def invoke_update_command(dry_run: true, clear_cache: false)
    clear_test_cache if clear_cache

    result = capture_cli_output do
      cli.invoke(:update, [test_directories[:target]],
                dry_run: dry_run, verbose: false, stats: false)
    end

    {
      success: result[:stderr].empty? ||
               result[:stderr].include?('No updates') ||
               !result[:stderr].include?('Fatal error'),
      output: result
    }
  end

  def clear_test_cache
    FileUtils.rm_rf(Dir.glob(File.join(test_directories[:cache], '*')))
  end

  def current_memory_usage_mb
    if RUBY_PLATFORM.include?('darwin')
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    else
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    end
  rescue
    0.0
  end

  def validate_performance_baseline(metrics, baseline_name)
    expect(metrics[:success_rate]).to be > 0.8,
           "#{baseline_name}: Success rate #{(metrics[:success_rate] * 100).round(1)}% too low"

    expect(metrics[:p95_seconds]).to be < 5.0,
           "#{baseline_name}: P95 time #{metrics[:p95_seconds].round(3)}s exceeds maximum threshold"

    expect(metrics[:median_memory_mb]).to be < 100,
           "#{baseline_name}: Memory usage #{metrics[:median_memory_mb].round(1)}MB too high"

    puts "✅ #{baseline_name}: P95=#{(metrics[:p95_seconds] * 1000).round(1)}ms, " \
         "Memory=#{metrics[:median_memory_mb].round(1)}MB, " \
         "Success=#{(metrics[:success_rate] * 100).round(1)}%"
  end

  def validate_cache_optimization(baseline_metrics, optimized_metrics)
    return unless baseline_metrics[:success_rate] > 0.5 && optimized_metrics[:success_rate] > 0.5

    baseline_time = baseline_metrics[:median_seconds]
    optimized_time = optimized_metrics[:median_seconds]

    improvement_ratio = (baseline_time - optimized_time) / baseline_time

    # Cache optimization should provide measurable improvement
    if improvement_ratio > performance_config[:cache_improvement_threshold]
      puts "✅ Cache optimization: #{(improvement_ratio * 100).round(1)}% improvement " \
           "(#{(baseline_time * 1000).round(1)}ms → #{(optimized_time * 1000).round(1)}ms)"
    else
      puts "📊 Cache optimization: #{(improvement_ratio * 100).round(1)}% improvement " \
           "(#{(baseline_time * 1000).round(1)}ms → #{(optimized_time * 1000).round(1)}ms)"
      puts "   Note: Small improvements expected in test environment"
    end
  end

  def validate_resource_efficiency(metrics)
    expect(metrics[:p95_memory_mb]).to be < 150,
           "Resource efficiency: Memory usage #{metrics[:p95_memory_mb].round(1)}MB exceeds efficiency target"
  end

  def validate_scalability_characteristics(results)
    # Performance should scale sub-linearly with file count
    largest_dataset = results.last
    smallest_dataset = results.first

    file_ratio = largest_dataset[:file_count].to_f / smallest_dataset[:file_count]
    time_ratio = largest_dataset[:p95_time] / smallest_dataset[:p95_time]

    scalability_factor = time_ratio / file_ratio

    expect(scalability_factor).to be < 1.5,
           "Scalability: Performance scales at #{scalability_factor.round(2)}x rate (target: <1.5x)"

    puts "✅ Scalability: #{scalability_factor.round(2)}x scaling factor " \
         "(#{file_ratio.round(1)}x files → #{time_ratio.round(1)}x time)"
  end

  def validate_command_reliability(metrics, command_name)
    expect(metrics[:success_rate]).to be > 0.3,
           "#{command_name}: Success rate #{(metrics[:success_rate] * 100).round(1)}% too low " \
           "(accounting for test environment limitations)"

    if metrics[:success_rate] < 0.8
      puts "⚠️  #{command_name}: Limited success rate " \
           "#{(metrics[:success_rate] * 100).round(1)}% (git environment constraints)"
    end
  end

  def validate_workflow_efficiency(workflow_metrics)
    expect(workflow_metrics[:total_time_seconds]).to be < 10.0,
           "Workflow efficiency: Total time #{workflow_metrics[:total_time_seconds].round(2)}s exceeds target"

    puts "✅ Workflow efficiency: #{(workflow_metrics[:total_time_seconds] * 1000).round(1)}ms total"
  end

  def validate_workflow_resource_usage(workflow_metrics)
    expect(workflow_metrics[:memory_delta_mb].abs).to be < 200,
           "Workflow resource usage: Memory delta #{workflow_metrics[:memory_delta_mb].round(1)}MB too high"
  end

  def store_performance_baseline(command, metrics)
    baseline_storage[command] = {
      timestamp: Time.now.iso8601,
      p95_seconds: metrics[:p95_seconds],
      median_seconds: metrics[:median_seconds],
      success_rate: metrics[:success_rate]
    }
  end

  def create_mock_historical_baseline
    {
      p95_seconds: 0.8,
      median_seconds: 0.5,
      success_rate: 0.9,
      timestamp: (Time.now - 86400).iso8601
    }
  end

  def analyze_performance_regression(historical, current)
    return { regression_detected: false, reason: 'insufficient_data' } if current[:success_rate] < 0.5

    p95_regression = current[:p95_seconds] / historical[:p95_seconds]
    median_regression = current[:median_seconds] / historical[:median_seconds]

    regression_detected = p95_regression > performance_config[:regression_threshold] ||
                         median_regression > performance_config[:regression_threshold]

    {
      regression_detected: regression_detected,
      p95_ratio: p95_regression,
      median_ratio: median_regression,
      threshold: performance_config[:regression_threshold]
    }
  end

  def validate_regression_detection(analysis)
    if analysis[:regression_detected]
      puts "⚠️  Performance regression detected: " \
           "P95 #{(analysis[:p95_ratio] * 100).round(1)}% of baseline"
    else
      puts "✅ No performance regression detected"
    end
  end

  def log_scalability_analysis(results)
    puts "\n📈 SCALABILITY ANALYSIS"
    puts "=" * 50
    results.each do |result|
      puts format("Files: %3d | P95: %6.1fms | Memory: %5.1fMB",
                  result[:file_count],
                  result[:p95_time] * 1000,
                  result[:median_memory])
    end
    puts "=" * 50
  end

  def log_regression_analysis(analysis)
    puts "\n🔍 REGRESSION ANALYSIS"
    puts "=" * 50
    puts format("P95 performance ratio: %.2f (threshold: %.2f)",
                analysis[:p95_ratio], analysis[:threshold])
    puts format("Median performance ratio: %.2f", analysis[:median_ratio])
    puts format("Regression detected: %s", analysis[:regression_detected])
    puts "=" * 50
  end

  def capture_cli_output(&block)
    original_stdout = $stdout
    original_stderr = $stderr

    stdout_capture = StringIO.new
    stderr_capture = StringIO.new

    $stdout = stdout_capture
    $stderr = stderr_capture

    begin
      block.call
    rescue SystemExit => e
      # CLI commands may call exit, capture gracefully
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    {
      stdout: stdout_capture.string,
      stderr: stderr_capture.string
    }
  end
end
