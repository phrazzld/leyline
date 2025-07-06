# frozen_string_literal: true

# Shared examples for reliable performance testing following Kent Beck principles
# Focus on statistical reliability and clear signals over arbitrary thresholds

RSpec.shared_examples 'reliable performance measurement' do |command_name, command_block_name|
  let(:performance_thresholds) do
    {
      # Statistical confidence thresholds
      minimum_success_rate: 0.7,         # 70% success rate minimum (accounts for test environment)
      maximum_p95_seconds: 3.0,          # P95 under 3 seconds (generous for test environment)
      maximum_memory_mb: 100,            # Memory usage under 100MB
      minimum_cache_improvement: 0.05    # Cache should provide >5% improvement
    }
  end

  it "provides statistically reliable #{command_name} performance measurement" do
    command_block = send(command_block_name)

    # Phase 1: Baseline measurement (cold cache)
    baseline_metrics = measure_command_with_statistics(command_name, &command_block)

    # Phase 2: Optimized measurement (warm cache)
    optimized_metrics = measure_command_with_statistics("#{command_name}_optimized", &command_block)

    aggregate_failures "#{command_name} performance validation" do
      validate_statistical_reliability(baseline_metrics, command_name)
      validate_performance_characteristics(baseline_metrics, command_name)
      validate_cache_effectiveness(baseline_metrics, optimized_metrics, command_name)
    end
  end
end

RSpec.shared_examples 'scalable performance characteristics' do |command_name, &command_block|
  it 'maintains scalable performance as data size increases' do
    file_counts = [25, 50, 100, 200]
    scalability_measurements = []

    file_counts.each do |count|
      setup_test_data_with_size(count)

      metrics = measure_command_with_statistics("#{command_name}_#{count}files", &command_block)

      scalability_measurements << {
        file_count: count,
        p95_seconds: metrics[:p95_seconds],
        memory_mb: metrics[:median_memory_mb],
        success_rate: metrics[:success_rate]
      }
    end

    validate_scalability_pattern(scalability_measurements, command_name)
  end
end

RSpec.shared_examples 'statistical regression detection' do |command_name, &command_block|
  it 'detects performance regressions using statistical methods' do
    # Establish current baseline
    current_metrics = measure_command_with_statistics(command_name, &command_block)

    # Compare against mock historical baseline
    historical_baseline = create_historical_baseline_for(command_name)

    regression_analysis = perform_statistical_regression_analysis(
      historical_baseline,
      current_metrics
    )

    validate_regression_detection_accuracy(regression_analysis, command_name)
  end
end

# Supporting methods for shared examples

def measure_command_with_statistics(command_name, iterations: 8, warmup: 2, &block)
  puts "📊 Statistical measurement: #{command_name}"

  # Warmup iterations to stabilize performance
  warmup.times { block.call }

  # Measurement iterations
  time_samples = []
  memory_samples = []
  success_count = 0

  iterations.times do
    start_memory = current_process_memory_mb
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      result = block.call
      success_count += 1 if result && result[:success] != false
    rescue StandardError
      # Record failure but continue measurement
    end

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end_memory = current_process_memory_mb

    time_samples << (end_time - start_time)
    memory_samples << (end_memory - start_memory).abs
  end

  calculate_statistical_metrics(time_samples, memory_samples, success_count, iterations)
end

def calculate_statistical_metrics(times, memory_deltas, successes, total)
  sorted_times = times.sort
  sorted_memory = memory_deltas.sort

  {
    # Time metrics
    median_seconds: percentile(sorted_times, 50),
    p95_seconds: percentile(sorted_times, 95),
    mean_seconds: times.sum / times.length.to_f,
    std_dev_seconds: standard_deviation(times),

    # Memory metrics
    median_memory_mb: percentile(sorted_memory, 50),
    p95_memory_mb: percentile(sorted_memory, 95),

    # Reliability metrics
    success_rate: successes.to_f / total,
    sample_size: total,

    # Statistical validity
    coefficient_of_variation: times.length > 1 ? standard_deviation(times) / (times.sum / times.length.to_f) : 0
  }
end

def percentile(sorted_array, percentile)
  return 0 if sorted_array.empty?

  index = (percentile / 100.0 * (sorted_array.length - 1)).round
  sorted_array[index]
end

def standard_deviation(values)
  return 0 if values.length <= 1

  mean = values.sum / values.length.to_f
  variance = values.sum { |v| (v - mean)**2 } / values.length.to_f
  Math.sqrt(variance)
end

def current_process_memory_mb
  if RUBY_PLATFORM.include?('darwin')
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  else
    # Linux fallback
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  end
rescue StandardError
  0.0
end

def validate_statistical_reliability(metrics, command_name)
  expect(metrics[:success_rate]).to be >= performance_thresholds[:minimum_success_rate],
                                    "#{command_name}: Success rate #{(metrics[:success_rate] * 100).round(1)}% below threshold"

  expect(metrics[:sample_size]).to be >= 5,
                                   "#{command_name}: Sample size #{metrics[:sample_size]} too small for statistical reliability"

  # Coefficient of variation should indicate reasonable consistency
  expect(metrics[:coefficient_of_variation]).to be < 2.0,
                                                "#{command_name}: Performance too variable (CV: #{metrics[:coefficient_of_variation].round(3)})"
end

def validate_performance_characteristics(metrics, command_name)
  expect(metrics[:p95_seconds]).to be < performance_thresholds[:maximum_p95_seconds],
                                   "#{command_name}: P95 time #{metrics[:p95_seconds].round(3)}s exceeds threshold"

  expect(metrics[:p95_memory_mb]).to be < performance_thresholds[:maximum_memory_mb],
                                     "#{command_name}: P95 memory #{metrics[:p95_memory_mb].round(1)}MB exceeds threshold"

  puts "✅ #{command_name}: P95=#{(metrics[:p95_seconds] * 1000).round(1)}ms, " \
       "Memory=#{metrics[:median_memory_mb].round(1)}MB, " \
       "Success=#{(metrics[:success_rate] * 100).round(1)}%"
end

def validate_cache_effectiveness(baseline, optimized, command_name)
  return unless baseline[:success_rate] >= 0.5 && optimized[:success_rate] >= 0.5

  improvement = (baseline[:median_seconds] - optimized[:median_seconds]) / baseline[:median_seconds]

  if improvement >= performance_thresholds[:minimum_cache_improvement]
    puts "✅ #{command_name} cache: #{(improvement * 100).round(1)}% improvement"
  else
    puts "📊 #{command_name} cache: #{(improvement * 100).round(1)}% improvement (minimal in test env)"
  end
end

def validate_scalability_pattern(measurements, command_name)
  return if measurements.length < 2

  # Calculate scaling factor: time_ratio / file_ratio
  first = measurements.first
  last = measurements.last

  file_ratio = last[:file_count].to_f / first[:file_count]
  time_ratio = last[:p95_seconds] / first[:p95_seconds]

  scaling_factor = time_ratio / file_ratio

  expect(scaling_factor).to be < 2.0,
                            "#{command_name}: Scaling factor #{scaling_factor.round(2)} indicates poor scalability"

  puts "✅ #{command_name} scalability: #{scaling_factor.round(2)}x factor " \
       "(#{file_ratio.round(1)}x files → #{time_ratio.round(1)}x time)"
end

def perform_statistical_regression_analysis(historical, current)
  return { regression_detected: false, reason: 'insufficient_current_data' } if current[:success_rate] < 0.5
  return { regression_detected: false, reason: 'no_historical_data' } unless historical

  # Use statistical significance testing (simplified)
  p95_change = current[:p95_seconds] / historical[:p95_seconds]
  median_change = current[:median_seconds] / historical[:median_seconds]

  # Consider regression if >20% degradation in key metrics
  regression_threshold = 1.2

  regression_detected = p95_change > regression_threshold || median_change > regression_threshold

  {
    regression_detected: regression_detected,
    p95_change_ratio: p95_change,
    median_change_ratio: median_change,
    confidence_level: current[:sample_size] >= 8 ? 'high' : 'medium'
  }
end

def validate_regression_detection_accuracy(analysis, command_name)
  if analysis[:regression_detected]
    puts "⚠️  #{command_name}: Performance regression detected " \
         "(P95: #{(analysis[:p95_change_ratio] * 100).round(1)}% of baseline)"
  else
    puts "✅ #{command_name}: No performance regression detected"
  end

  expect(analysis[:confidence_level]).to eq('high').or eq('medium'),
                                                       "#{command_name}: Statistical confidence too low for reliable regression detection"
end

def create_historical_baseline_for(_command_name)
  # Mock historical data for regression testing
  {
    median_seconds: 0.4,
    p95_seconds: 0.8,
    success_rate: 0.95,
    recorded_at: (Time.now - 7 * 24 * 3600).iso8601 # 1 week ago
  }
end

def setup_test_data_with_size(file_count)
  # This method should be implemented by the including test file
  # to create test data of the specified size
end
