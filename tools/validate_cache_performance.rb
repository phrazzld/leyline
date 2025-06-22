#!/usr/bin/env ruby
# frozen_string_literal: true

# Performance validation script for cache-aware sync functionality
# Validates end-to-end performance characteristics according to TODO.md requirements

require 'fileutils'
require 'tmpdir'
require 'benchmark'
require 'json'

class CachePerformanceValidator
  attr_reader :results, :test_dir

  def initialize
    @results = {}
    @test_dir = Dir.mktmpdir('leyline-perf-validation')
    @target_dir = File.join(@test_dir, 'target')
    @cache_dir = File.join(@test_dir, 'cache')

    puts 'Performance Validation Test'
    puts '=' * 50
    puts "Test directory: #{@test_dir}"
    puts "Target directory: #{@target_dir}"
    puts "Cache directory: #{@cache_dir}"
    puts ''
  end

  def run_validation
    # Create target directory structure
    FileUtils.mkdir_p(@target_dir)

    # Set cache directory via environment variable
    ENV['LEYLINE_CACHE_DIR'] = @cache_dir

    puts 'Running performance validation tests...'
    puts ''

    # Test 1: First sync performance (cold cache)
    validate_cold_cache_performance

    # Test 2: Second sync performance (warm cache)
    validate_warm_cache_performance

    # Test 3: Cache hit ratio validation
    validate_cache_hit_ratio

    # Test 4: Git operations skipping
    validate_git_operations_skipping

    # Test 5: Performance regression check
    validate_no_performance_regression

    # Generate final report
    generate_final_report
  ensure
    cleanup
  end

  private

  def validate_cold_cache_performance
    puts 'Test 1: Cold cache performance (first sync)'
    puts '-' * 40

    # Clear any existing cache
    FileUtils.rm_rf(@cache_dir) if Dir.exist?(@cache_dir)

    # Measure first sync
    cold_benchmark = Benchmark.measure do
      system("#{File.expand_path('../bin/leyline',
                                 __dir__)} sync #{@target_dir} --verbose --stats > /tmp/leyline_cold.log 2>&1")
    end

    cold_time = cold_benchmark.real
    @results[:cold_cache_time] = cold_time

    puts "Cold cache sync time: #{(cold_time * 1000).round(1)}ms"

    # Verify files were copied
    leyline_dir = File.join(@target_dir, 'docs', 'leyline')
    if Dir.exist?(leyline_dir)
      file_count = Dir.glob('**/*', base: leyline_dir).count { |f| File.file?(File.join(leyline_dir, f)) }
      puts "Files synced: #{file_count}"
      @results[:files_synced] = file_count
    else
      puts '❌ ERROR: Leyline directory not created'
      @results[:cold_cache_error] = 'No leyline directory created'
    end

    puts '✅ Cold cache test completed'
    puts ''
  end

  def validate_warm_cache_performance
    puts 'Test 2: Warm cache performance (second sync)'
    puts '-' * 40

    # Measure second sync with warm cache
    warm_benchmark = Benchmark.measure do
      system("#{File.expand_path('../bin/leyline',
                                 __dir__)} sync #{@target_dir} --verbose --stats > /tmp/leyline_warm.log 2>&1")
    end

    warm_time = warm_benchmark.real
    @results[:warm_cache_time] = warm_time

    puts "Warm cache sync time: #{(warm_time * 1000).round(1)}ms"

    # Check if target is met (<1 second)
    if warm_time < 1.0
      puts '✅ Target met: Warm cache sync <1 second'
      @results[:warm_cache_target_met] = true
    else
      puts "❌ Target missed: Warm cache sync >=1 second (#{warm_time}s)"
      @results[:warm_cache_target_met] = false
    end

    # Calculate improvement
    if @results[:cold_cache_time]
      improvement = ((@results[:cold_cache_time] - warm_time) / @results[:cold_cache_time]) * 100
      @results[:performance_improvement] = improvement
      puts "Performance improvement: #{improvement.round(1)}%"
    end

    puts '✅ Warm cache test completed'
    puts ''
  end

  def validate_cache_hit_ratio
    puts 'Test 3: Cache hit ratio validation'
    puts '-' * 40

    # Parse stats from warm cache log
    warm_log = begin
      File.read('/tmp/leyline_warm.log')
    rescue StandardError
      ''
    end

    # Look for cache statistics in the output
    if warm_log.include?('CACHE STATISTICS')
      # Extract hit ratio from log
      hit_ratio_match = warm_log.match(/Hit ratio: ([\d.]+)%/)
      if hit_ratio_match
        hit_ratio = hit_ratio_match[1].to_f
        @results[:cache_hit_ratio] = hit_ratio
        puts "Cache hit ratio: #{hit_ratio}%"

        if hit_ratio >= 80.0
          puts '✅ Target met: Cache hit ratio >=80%'
          @results[:cache_hit_ratio_target_met] = true
        else
          puts "❌ Target missed: Cache hit ratio <80% (#{hit_ratio}%)"
          @results[:cache_hit_ratio_target_met] = false
        end
      else
        puts '⚠️  Could not extract hit ratio from logs'
        @results[:cache_hit_ratio_error] = 'Could not parse hit ratio'
      end
    else
      puts '⚠️  No cache statistics found in output'
      @results[:cache_hit_ratio_error] = 'No cache statistics in output'
    end

    puts '✅ Cache hit ratio test completed'
    puts ''
  end

  def validate_git_operations_skipping
    puts 'Test 4: Git operations skipping validation'
    puts '-' * 40

    # Check logs for evidence of git operations being skipped
    warm_log = begin
      File.read('/tmp/leyline_warm.log')
    rescue StandardError
      ''
    end

    if warm_log.include?('Serving from cache')
      puts '✅ Git operations successfully skipped (serving from cache)'
      @results[:git_operations_skipped] = true
    elsif warm_log.include?('cache hit ratio') && warm_log.include?('below threshold')
      puts 'ℹ️  Git operations proceeded (cache hit ratio below threshold)'
      @results[:git_operations_skipped] = false
      @results[:git_skip_reason] = 'Below threshold'
    else
      puts '⚠️  Could not determine git operations status from logs'
      @results[:git_operations_status] = 'Unknown'
    end

    puts '✅ Git operations test completed'
    puts ''
  end

  def validate_no_performance_regression
    puts 'Test 5: Performance regression check'
    puts '-' * 40

    cold_time = @results[:cold_cache_time]

    if cold_time
      # Check that cold cache performance is reasonable (should be similar to git-only)
      # Baseline expectation: cold cache should complete within 10 seconds for reasonable repo size
      if cold_time < 10.0
        puts "✅ No performance regression: Cold cache sync in #{(cold_time * 1000).round(1)}ms"
        @results[:no_performance_regression] = true
      else
        puts "❌ Potential performance regression: Cold cache sync took #{cold_time}s"
        @results[:no_performance_regression] = false
      end
    else
      puts '⚠️  Could not validate - no cold cache timing available'
      @results[:regression_check_error] = 'No cold cache timing'
    end

    puts '✅ Performance regression test completed'
    puts ''
  end

  def generate_final_report
    puts 'FINAL PERFORMANCE VALIDATION REPORT'
    puts '=' * 50

    # Summary of all validations
    validations = [
      {
        name: 'Warm cache <1 second',
        result: @results[:warm_cache_target_met],
        value: @results[:warm_cache_time] ? "#{(@results[:warm_cache_time] * 1000).round(1)}ms" : nil
      },
      {
        name: 'Cache hit ratio >=80%',
        result: @results[:cache_hit_ratio_target_met],
        value: @results[:cache_hit_ratio] ? "#{@results[:cache_hit_ratio]}%" : nil
      },
      {
        name: 'Git operations optimization',
        result: @results[:git_operations_skipped],
        value: @results[:git_skip_reason] || 'Working'
      },
      {
        name: 'No performance regression',
        result: @results[:no_performance_regression],
        value: @results[:cold_cache_time] ? "#{(@results[:cold_cache_time] * 1000).round(1)}ms" : nil
      }
    ]

    passed_count = validations.count { |v| v[:result] == true }
    total_count = validations.count { |v| !v[:result].nil? }

    validations.each do |validation|
      status = case validation[:result]
               when true then '✅ PASS'
               when false then '❌ FAIL'
               else '⚠️  SKIP'
               end
      puts "#{status} #{validation[:name]}: #{validation[:value]}"
    end

    puts ''
    puts "Overall: #{passed_count}/#{total_count} validations passed"

    if @results[:performance_improvement]
      puts "Performance improvement: #{@results[:performance_improvement].round(1)}%"
    end

    puts "Files synced: #{@results[:files_synced]}" if @results[:files_synced]

    # Write results to JSON for programmatic access
    results_file = File.join(@test_dir, 'validation_results.json')
    File.write(results_file, JSON.pretty_generate(@results))
    puts ''
    puts "Detailed results written to: #{results_file}"

    # Determine overall success
    critical_validations = %i[warm_cache_target_met no_performance_regression]
    critical_passed = critical_validations.all? { |key| @results[key] == true }

    if critical_passed
      puts ''
      puts '🎉 PERFORMANCE VALIDATION PASSED'
      exit 0
    else
      puts ''
      puts '💥 PERFORMANCE VALIDATION FAILED'
      exit 1
    end
  end

  def cleanup
    puts ''
    puts "Cleaning up test directory: #{@test_dir}"
    FileUtils.rm_rf(@test_dir)
    ENV.delete('LEYLINE_CACHE_DIR')
  end
end

# Run validation if this script is executed directly
if __FILE__ == $0
  validator = CachePerformanceValidator.new
  validator.run_validation
end
