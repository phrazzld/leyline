# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'
require 'fileutils'
require 'tmpdir'
require_relative '../support/benchmark_helpers'

RSpec.describe 'Transparency Commands Degradation Tests', type: :benchmark do
  include BenchmarkHelpers

  # Failure scenarios to test graceful degradation
  DEGRADATION_SCENARIOS = {
    cache_permission_denied: {
      description: 'Cache directory has no read/write permissions',
      setup: ->(cache_dir) { File.chmod(0o000, cache_dir) if Dir.exist?(cache_dir) },
      cleanup: ->(cache_dir) { File.chmod(0o755, cache_dir) if Dir.exist?(cache_dir) },
      expected_behavior: :fallback_to_no_cache,
      max_performance_penalty: 1.5, # 50% slower maximum
      should_succeed: true
    },

    cache_disk_full: {
      description: 'Disk is full, cache writes fail',
      setup: ->(cache_dir) { simulate_disk_full(cache_dir) },
      cleanup: ->(cache_dir) { cleanup_disk_full_simulation(cache_dir) },
      expected_behavior: :continue_readonly,
      max_performance_penalty: 1.2,
      should_succeed: true
    },

    corrupted_cache_files: {
      description: '10% of cache files are corrupted',
      setup: ->(cache_dir) { corrupt_cache_files(cache_dir, 0.1) },
      cleanup: ->(cache_dir) { FileUtils.rm_rf(Dir.glob(File.join(cache_dir, '**', '*.corrupted'))) },
      expected_behavior: :auto_repair,
      max_performance_penalty: 2.0,
      should_succeed: true
    },

    zero_byte_cache_files: {
      description: 'Cache files exist but are zero bytes',
      setup: ->(cache_dir) { create_zero_byte_cache_files(cache_dir) },
      cleanup: ->(cache_dir) {}, # handled by cache
      expected_behavior: :auto_cleanup,
      max_performance_penalty: 1.3,
      should_succeed: true
    },

    cache_directory_missing: {
      description: 'Cache directory is deleted mid-operation',
      setup: ->(cache_dir) { FileUtils.rm_rf(cache_dir) },
      cleanup: ->(cache_dir) { FileUtils.mkdir_p(cache_dir) },
      expected_behavior: :recreate_cache,
      max_performance_penalty: 1.5,
      should_succeed: true
    },

    partial_cache_state: {
      description: 'Cache metadata is incomplete',
      setup: ->(cache_dir) { create_partial_cache_state(cache_dir) },
      cleanup: ->(cache_dir) {}, # handled by cache
      expected_behavior: :rebuild_metadata,
      max_performance_penalty: 1.8,
      should_succeed: true
    },

    concurrent_cache_access: {
      description: 'Multiple processes accessing cache simultaneously',
      setup: ->(cache_dir) { simulate_concurrent_access(cache_dir) },
      cleanup: ->(cache_dir) { cleanup_concurrent_access(cache_dir) },
      expected_behavior: :handle_contention,
      max_performance_penalty: 1.4,
      should_succeed: true
    },

    invalid_cache_content: {
      description: 'Cache contains invalid/malformed data',
      setup: ->(cache_dir) { inject_invalid_cache_content(cache_dir) },
      cleanup: ->(cache_dir) {}, # handled by cache
      expected_behavior: :skip_invalid,
      max_performance_penalty: 1.3,
      should_succeed: true
    }
  }.freeze

  let(:test_dataset) { setup_test_repository(file_count: 1000) }
  let(:baseline_times) { {} }

  before(:all) do
    puts "\n" + '=' * 80
    puts 'DEGRADATION TEST SUITE'
    puts 'Testing graceful handling of failure conditions'
    puts '=' * 80
  end

  describe 'Baseline Performance' do
    it 'establishes baseline performance metrics' do
      DEGRADATION_SCENARIOS.keys.each do |scenario_name|
        result = measure_baseline_performance(scenario_name)
        baseline_times[scenario_name] = result[:average_ms]

        expect(result[:average_ms]).to be < 2000,
                                       "Baseline performance #{result[:average_ms]}ms exceeds reasonable limits"

        puts "\nBaseline for #{scenario_name}: #{result[:average_ms].round(2)}ms"
      end
    end
  end

  describe 'Degradation Scenarios' do
    DEGRADATION_SCENARIOS.each do |scenario_name, config|
      context config[:description] do
        it 'handles degradation gracefully with acceptable performance impact' do
          # Skip if baseline not established
          skip 'Baseline not established' unless baseline_times[scenario_name]

          baseline = baseline_times[scenario_name]

          # Setup failure condition
          setup_result = setup_degradation_environment(scenario_name, config)

          begin
            # Measure degraded performance
            degraded_result = measure_degraded_performance(scenario_name, setup_result)

            # Validate the command still succeeds (if expected)
            if config[:should_succeed]
              expect(degraded_result[:success]).to be(true),
                                                   'Command failed when it should have succeeded gracefully'
            end

            # Validate performance degradation is within acceptable bounds
            if degraded_result[:average_ms] && baseline > 0
              degradation_ratio = degraded_result[:average_ms] / baseline

              expect(degradation_ratio).to be <= config[:max_performance_penalty],
                                           "Performance degraded by #{degradation_ratio.round(2)}x, " \
                                           "expected <= #{config[:max_performance_penalty]}x"

              # Log detailed results
              log_degradation_results(scenario_name, baseline, degraded_result, degradation_ratio)
            end

            # Validate expected behavior
            validate_expected_behavior(config[:expected_behavior], degraded_result, setup_result)
          ensure
            # Always cleanup
            cleanup_degradation_environment(setup_result, config)
          end
        end

        it 'recovers successfully after failure condition is resolved' do
          skip 'Baseline not established' unless baseline_times[scenario_name]

          # Setup and trigger failure
          setup_result = setup_degradation_environment(scenario_name, config)
          measure_degraded_performance(scenario_name, setup_result)

          # Remove failure condition
          cleanup_degradation_environment(setup_result, config)

          # Measure recovery performance
          recovery_result = measure_recovery_performance(scenario_name, setup_result)

          # Performance should return close to baseline
          if recovery_result[:average_ms] && baseline_times[scenario_name] > 0
            recovery_ratio = recovery_result[:average_ms] / baseline_times[scenario_name]

            expect(recovery_ratio).to be < 1.2,
                                      "Recovery performance #{recovery_ratio.round(2)}x baseline, expected near 1.0x"
          end

          # Validate cache metrics show recovery
          expect(recovery_result[:cache_errors]).to eq(0),
                                                    'Cache errors persist after recovery'
        end
      end
    end
  end

  describe 'Compound Failure Scenarios' do
    it 'handles multiple simultaneous failures' do
      compound_scenarios = [
        %i[cache_permission_denied corrupted_cache_files],
        %i[cache_disk_full invalid_cache_content],
        %i[zero_byte_cache_files concurrent_cache_access]
      ]

      compound_scenarios.each do |scenario_names|
        puts "\nTesting compound failure: #{scenario_names.join(' + ')}"

        setup_results = []

        begin
          # Apply all failure conditions
          scenario_names.each do |name|
            config = DEGRADATION_SCENARIOS[name]
            setup_results << setup_degradation_environment(name, config)
          end

          # Measure performance under compound failures
          result = measure_compound_degradation(scenario_names)

          # Should still complete, even if slowly
          expect(result[:completed]).to be(true),
                                        'Command failed to complete under compound failures'

          # Log results
          puts "  Completed: #{result[:completed]}"
          puts "  Time: #{result[:average_ms]&.round(2)}ms"
          puts "  Errors: #{result[:errors].length}"
        ensure
          # Cleanup all
          setup_results.zip(scenario_names).each do |setup_result, name|
            config = DEGRADATION_SCENARIOS[name]
            cleanup_degradation_environment(setup_result, config)
          end
        end
      end
    end
  end

  describe 'Error Message Quality' do
    it 'provides clear, actionable error messages for each failure' do
      error_quality_results = {}

      DEGRADATION_SCENARIOS.each do |scenario_name, config|
        setup_result = setup_degradation_environment(scenario_name, config)

        begin
          # Capture error output
          error_output = capture_error_output do
            run_command_with_failure(setup_result)
          end

          # Validate error message quality
          error_quality = assess_error_message_quality(error_output)
          error_quality_results[scenario_name] = error_quality

          expect(error_quality[:has_clear_problem]).to be(true),
                                                       "Error message doesn't clearly identify the problem"

          expect(error_quality[:has_suggestion]).to be(true),
                                                    "Error message doesn't provide actionable suggestions"

          expect(error_quality[:mentions_cache]).to be(true),
                                                    "Error message doesn't mention cache when cache-related"
        ensure
          cleanup_degradation_environment(setup_result, config)
        end
      end

      # Report error message quality
      puts "\nError Message Quality Report:"
      error_quality_results.each do |scenario, quality|
        puts "  #{scenario}:"
        puts "    Clear problem: #{quality[:has_clear_problem] ? '✓' : '✗'}"
        puts "    Actionable: #{quality[:has_suggestion] ? '✓' : '✗'}"
        puts "    Contextual: #{quality[:mentions_cache] ? '✓' : '✗'}"
      end
    end
  end

  private

  def setup_test_repository(file_count:)
    base_dir = Dir.mktmpdir('degradation-test')

    # Create standard leyline structure
    leyline_dir = File.join(base_dir, 'docs', 'leyline')
    FileUtils.mkdir_p(File.join(leyline_dir, 'tenets'))
    FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'core'))
    FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'typescript'))

    # Generate test files
    files = []

    (file_count * 0.1).to_i.times do |i|
      path = File.join(leyline_dir, 'tenets', "tenet-#{i}.md")
      File.write(path, generate_test_content('tenet', i))
      files << path
    end

    (file_count * 0.3).to_i.times do |i|
      path = File.join(leyline_dir, 'bindings', 'core', "binding-#{i}.md")
      File.write(path, generate_test_content('binding', i))
      files << path
    end

    (file_count * 0.6).to_i.times do |i|
      path = File.join(leyline_dir, 'bindings', 'categories', 'typescript', "ts-#{i}.md")
      File.write(path, generate_test_content('typescript', i))
      files << path
    end

    { base_dir: base_dir, leyline_dir: leyline_dir, files: files }
  end

  def generate_test_content(type, index)
    <<~CONTENT
      ---
      id: #{type}-#{index}
      last_modified: '2025-06-22'
      version: '0.1.0'
      ---

      # #{type.capitalize} #{index}

      Test content for degradation testing.

      #{'x' * rand(1000..5000)}
    CONTENT
  end

  def setup_degradation_environment(scenario_name, config)
    cache_dir = Dir.mktmpdir('degradation-cache')

    # Pre-populate cache for more realistic testing
    prepopulate_cache(cache_dir, test_dataset[:files].sample(100))

    # Apply failure condition
    config[:setup].call(cache_dir)

    {
      scenario: scenario_name,
      cache_dir: cache_dir,
      base_dir: test_dataset[:base_dir],
      start_time: Time.now
    }
  end

  def cleanup_degradation_environment(setup_result, config)
    config[:cleanup].call(setup_result[:cache_dir]) if config[:cleanup]
    FileUtils.rm_rf(setup_result[:cache_dir]) if Dir.exist?(setup_result[:cache_dir])
  end

  def measure_baseline_performance(scenario_name)
    cache_dir = Dir.mktmpdir('baseline-cache')

    options = {
      directory: test_dataset[:base_dir],
      cache_dir: cache_dir,
      json: true
    }

    times = []

    5.times do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      command = Leyline::Commands::StatusCommand.new(options)
      command.execute

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      times << (end_time - start_time)
    end

    FileUtils.rm_rf(cache_dir)

    {
      scenario: scenario_name,
      average_ms: times.sum / times.length,
      min_ms: times.min,
      max_ms: times.max
    }
  end

  def measure_degraded_performance(scenario_name, setup_result)
    options = {
      directory: setup_result[:base_dir],
      cache_dir: setup_result[:cache_dir],
      json: true
    }

    times = []
    successes = []
    errors = []

    3.times do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      begin
        command = Leyline::Commands::StatusCommand.new(options)
        command.execute

        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        times << (end_time - start_time)
        successes << true
      rescue StandardError => e
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        times << (end_time - start_time)
        successes << false
        errors << e
      end
    end

    {
      scenario: scenario_name,
      average_ms: times.empty? ? nil : times.sum / times.length,
      success: successes.any? { |s| s },
      success_rate: successes.count(true) / successes.length.to_f,
      errors: errors,
      cache_errors: count_cache_errors(errors)
    }
  end

  def measure_recovery_performance(scenario_name, setup_result)
    # Give system time to detect recovery
    sleep 0.5

    measure_degraded_performance("#{scenario_name}_recovery", setup_result)
  end

  def measure_compound_degradation(scenario_names)
    options = {
      directory: test_dataset[:base_dir],
      cache_dir: Dir.mktmpdir('compound-cache'),
      json: true
    }

    times = []
    errors = []
    completed = false

    begin
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      command = Leyline::Commands::StatusCommand.new(options)
      command.execute

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      times << (end_time - start_time)
      completed = true
    rescue StandardError => e
      errors << e
    end

    {
      scenarios: scenario_names,
      completed: completed,
      average_ms: times.empty? ? nil : times.sum / times.length,
      errors: errors
    }
  end

  def validate_expected_behavior(expected_behavior, result, setup_result)
    case expected_behavior
    when :fallback_to_no_cache
      # Should complete without using cache
      expect(result[:success]).to be(true)

    when :continue_readonly
      # Should work but not write to cache
      expect(result[:success]).to be(true)

    when :auto_repair
      # Should fix problems and continue
      expect(result[:success]).to be(true)
      expect(result[:success_rate]).to be > 0.5

    when :auto_cleanup
      # Should remove invalid entries
      expect(result[:success]).to be(true)

    when :recreate_cache
      # Should create new cache directory
      expect(result[:success]).to be(true)
      expect(Dir.exist?(setup_result[:cache_dir])).to be(true)

    when :rebuild_metadata
      # Should reconstruct cache state
      expect(result[:success]).to be(true)

    when :handle_contention
      # Should work despite contention
      expect(result[:success]).to be(true)

    when :skip_invalid
      # Should ignore bad data
      expect(result[:success]).to be(true)
      expect(result[:cache_errors]).to be < 5
    end
  end

  def prepopulate_cache(cache_dir, files)
    cache = Leyline::Cache::FileCache.new(cache_dir)

    files.each do |file|
      content = File.read(file) if File.exist?(file)
      cache.put(content) if content
    end
  end

  def self.simulate_disk_full(cache_dir)
    # Create a file that fills most of available space
    # In practice, would use fallocate or similar
    marker_file = File.join(cache_dir, '.disk_full_simulation')
    File.write(marker_file, 'DISK_FULL_MARKER')

    # Make cache files read-only to simulate write failures
    Dir.glob(File.join(cache_dir, '**', '*')).each do |file|
      File.chmod(0o444, file) if File.file?(file)
    end
  end

  def self.cleanup_disk_full_simulation(cache_dir)
    marker_file = File.join(cache_dir, '.disk_full_simulation')
    File.delete(marker_file) if File.exist?(marker_file)

    # Restore write permissions
    Dir.glob(File.join(cache_dir, '**', '*')).each do |file|
      File.chmod(0o644, file) if File.file?(file)
    end
  end

  def self.corrupt_cache_files(cache_dir, percentage)
    cache_files = Dir.glob(File.join(cache_dir, 'content', '**', '*')).select { |f| File.file?(f) }
    corrupt_count = (cache_files.length * percentage).to_i

    cache_files.sample(corrupt_count).each do |file|
      # Corrupt by truncating or adding garbage
      if rand > 0.5
        File.write(file, "CORRUPTED_DATA_#{rand(1000)}")
      else
        File.truncate(file, rand(10))
      end

      # Mark as corrupted for cleanup
      FileUtils.touch("#{file}.corrupted")
    end
  end

  def self.create_zero_byte_cache_files(cache_dir)
    # Create some zero-byte files in cache
    5.times do |i|
      dir = File.join(cache_dir, 'content', format('%02x', i))
      FileUtils.mkdir_p(dir)
      FileUtils.touch(File.join(dir, "zero_byte_#{i}"))
    end
  end

  def self.create_partial_cache_state(cache_dir)
    # Remove some metadata files to simulate incomplete state
    metadata_files = Dir.glob(File.join(cache_dir, 'metadata', '*'))
    metadata_files.sample(metadata_files.length / 2).each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  def self.simulate_concurrent_access(cache_dir)
    # Create lock files to simulate other processes
    3.times do |i|
      lock_file = File.join(cache_dir, ".lock_process_#{i}")
      File.write(lock_file, Process.pid.to_s)
    end
  end

  def self.cleanup_concurrent_access(cache_dir)
    Dir.glob(File.join(cache_dir, '.lock_process_*')).each do |lock_file|
      File.delete(lock_file) if File.exist?(lock_file)
    end
  end

  def self.inject_invalid_cache_content(cache_dir)
    # Add files with invalid content structure
    3.times do |i|
      dir = File.join(cache_dir, 'content', format('%02x', 100 + i))
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "invalid_#{i}"), '{invalid json content[}')
    end
  end

  def capture_error_output
    original_stderr = $stderr
    $stderr = StringIO.new

    begin
      yield
    rescue StandardError => e
      warn e.message
    end

    $stderr.string
  ensure
    $stderr = original_stderr
  end

  def run_command_with_failure(setup_result)
    options = {
      directory: setup_result[:base_dir],
      cache_dir: setup_result[:cache_dir],
      verbose: true
    }

    command = Leyline::Commands::StatusCommand.new(options)
    command.execute
  end

  def assess_error_message_quality(error_output)
    {
      has_clear_problem: error_output =~ /cache|permission|corrupt|invalid|fail/i,
      has_suggestion: error_output =~ /try|check|ensure|fix|repair/i,
      mentions_cache: error_output =~ /cache/i,
      is_user_friendly: error_output.length < 500 && !error_output.include?('backtrace')
    }
  end

  def count_cache_errors(errors)
    errors.count { |e| e.message =~ /cache/i }
  end

  def log_degradation_results(scenario, baseline, result, ratio)
    puts "\n#{scenario}:"
    puts "  Baseline: #{baseline.round(2)}ms"
    puts "  Degraded: #{result[:average_ms]&.round(2)}ms"
    puts "  Impact: #{((ratio - 1) * 100).round(1)}% slower"
    puts "  Success rate: #{(result[:success_rate] * 100).round(1)}%"
    puts "  Errors: #{result[:errors].length}"
  end
end
