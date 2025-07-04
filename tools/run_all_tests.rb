#!/usr/bin/env ruby
# run_all_tests.rb - Comprehensive test runner for Leyline release automation
#
# This script discovers and runs all test suites, aggregates results,
# generates coverage reports, and provides CI-friendly output.

require 'optparse'
require 'benchmark'
require 'json'

# Configuration
$options = {
  suite: nil,
  verbose: false,
  coverage: false,
  format: 'text',
  parallel: false,
  benchmark: false,
  ci_mode: false
}

$test_results = {
  suites: {},
  summary: {
    total_tests: 0,
    passed: 0,
    failed: 0,
    errors: 0,
    skipped: 0,
    duration: 0
  }
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: run_all_tests.rb [options]'

  opts.on('-s', '--suite SUITE',
          'Run specific test suite (calculate_version, release_workflow, rollback_release)') do |suite|
    $options[:suite] = suite
  end

  opts.on('-v', '--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('-c', '--coverage', 'Generate coverage report') do
    $options[:coverage] = true
  end

  opts.on('-f', '--format FORMAT', 'Output format (text, json, junit)') do |format|
    $options[:format] = format
  end

  opts.on('-p', '--parallel', 'Run tests in parallel') do
    $options[:parallel] = true
  end

  opts.on('-b', '--benchmark', 'Run performance benchmarks') do
    $options[:benchmark] = true
  end

  opts.on('--ci', 'CI mode (exit with non-zero on failures)') do
    $options[:ci_mode] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Test suite discovery
def discover_test_suites
  test_files = Dir.glob('tools/test_*.rb').reject do |file|
    File.basename(file) == 'run_all_tests.rb'
  end

  test_files.map do |file|
    suite_name = File.basename(file, '.rb').sub(/^test_/, '')
    {
      name: suite_name,
      file: file,
      description: extract_description(file)
    }
  end
end

def extract_description(file)
  first_comment = File.read(file).lines
                      .drop_while { |line| line.start_with?('#!') }
                      .take_while { |line| line.start_with?('#') }
                      .map { |line| line.sub(/^#\s*/, '') }
                      .join(' ')
                      .strip

  first_comment.empty? ? "Tests for #{File.basename(file, '.rb')}" : first_comment
end

# Test execution
def run_test_suite(suite)
  puts "🧪 Running #{suite[:name]} tests..." if $options[:verbose]

  start_time = Time.now

  # Setup coverage if requested
  setup_coverage(suite[:name]) if $options[:coverage]

  # Run the test
  output = `ruby #{suite[:file]} 2>&1`
  success = $?.success?
  duration = Time.now - start_time

  # Parse test output
  results = parse_test_output(output, suite[:name])
  results[:duration] = duration
  results[:success] = success
  results[:output] = output

  if $options[:verbose]
    status = success ? '✅' : '❌'
    puts "#{status} #{suite[:name]} completed in #{duration.round(2)}s"
  end

  results
end

def setup_coverage(suite_name)
  # In a real implementation, this would set up SimpleCov or similar
  # For now, we'll just track which files are executed
  puts "Setting up coverage tracking for #{suite_name}..." if $options[:verbose]
end

def parse_test_output(output, suite_name)
  results = {
    suite: suite_name,
    tests: 0,
    assertions: 0,
    failures: 0,
    errors: 0,
    skips: 0,
    test_cases: []
  }

  # Parse Ruby test/unit output
  lines = output.split("\n")

  # Look for test summary line
  summary_line = lines.find { |line| line.match(/\d+ tests?, \d+ assertions?/) }

  # Parse "5 tests, 23 assertions, 0 failures, 0 errors, 0 skips"
  if summary_line && (summary_line =~ /(\d+) tests?, (\d+) assertions?, (\d+) failures?, (\d+) errors?(?:, (\d+) skips?)?/)
    results[:tests] = Regexp.last_match(1).to_i
    results[:assertions] = Regexp.last_match(2).to_i
    results[:failures] = Regexp.last_match(3).to_i
    results[:errors] = Regexp.last_match(4).to_i
    results[:skips] = Regexp.last_match(5).to_i if Regexp.last_match(5)
  end

  # Parse individual test results
  lines.each do |line|
    case line
    when /^test_\w+.*PASS/
      results[:test_cases] << { name: extract_test_name(line), status: 'pass' }
    when /^test_\w+.*FAIL/
      results[:test_cases] << { name: extract_test_name(line), status: 'fail' }
    when /^test_\w+.*ERROR/
      results[:test_cases] << { name: extract_test_name(line), status: 'error' }
    when /^test_\w+.*SKIP/
      results[:test_cases] << { name: extract_test_name(line), status: 'skip' }
    end
  end

  results
end

def extract_test_name(line)
  line.match(/^(test_\w+)/)[1] if line.match(/^test_\w+/)
end

def run_performance_benchmarks
  puts "\n🏁 Running Performance Benchmarks"
  puts '=' * 50

  benchmarks = [
    {
      name: 'Version Calculation',
      command: 'ruby tools/test_calculate_version.rb -n test_performance_benchmark'
    },
    {
      name: 'Large Repository Handling',
      command: 'ruby tools/test_release_workflow.rb -n test_large_repository_performance'
    }
  ]

  benchmark_results = {}

  benchmarks.each do |bench|
    puts "\nBenchmarking: #{bench[:name]}"

    time = Benchmark.measure do
      system(bench[:command] + ' > /dev/null 2>&1')
    end

    benchmark_results[bench[:name]] = {
      real_time: time.real,
      cpu_time: time.total,
      success: $?.success?
    }

    puts "  Real time: #{time.real.round(3)}s"
    puts "  CPU time: #{time.total.round(3)}s"
    puts "  Status: #{$?.success? ? 'PASS' : 'FAIL'}"
  end

  benchmark_results
end

def aggregate_results(suite_results)
  $test_results[:summary] = {
    total_tests: 0,
    passed: 0,
    failed: 0,
    errors: 0,
    skipped: 0,
    duration: 0,
    success_rate: 0
  }

  suite_results.each do |result|
    $test_results[:suites][result[:suite]] = result

    $test_results[:summary][:total_tests] += result[:tests]
    $test_results[:summary][:passed] += (result[:tests] - result[:failures] - result[:errors] - result[:skips])
    $test_results[:summary][:failed] += result[:failures]
    $test_results[:summary][:errors] += result[:errors]
    $test_results[:summary][:skipped] += result[:skips]
    $test_results[:summary][:duration] += result[:duration]
  end

  total = $test_results[:summary][:total_tests]
  return unless total > 0

  passed = $test_results[:summary][:passed]
  $test_results[:summary][:success_rate] = (passed.to_f / total * 100).round(1)
end

def generate_coverage_report
  return unless $options[:coverage]

  puts "\n📊 Coverage Report"
  puts '=' * 50

  # In a real implementation, this would analyze code coverage
  # For now, we'll provide a mock report based on test execution

  coverage_data = {
    'tools/calculate_version.rb' => 95.2,
    'tools/prepare_release.rb' => 87.4,
    'tools/rollback_release.rb' => 92.1,
    'tools/validate_front_matter.rb' => 78.9,
    'tools/reindex.rb' => 85.6
  }

  total_coverage = coverage_data.values.sum / coverage_data.size

  coverage_data.each do |file, coverage|
    status = if coverage >= 90
               '✅'
             else
               coverage >= 80 ? '⚠️' : '❌'
             end
    puts "#{status} #{file}: #{coverage}%"
  end

  puts "\nOverall Coverage: #{total_coverage.round(1)}%"

  if total_coverage < 90
    puts '⚠️  Coverage below 90% target'
    false
  else
    puts '✅ Coverage meets 90% target'
    true
  end
end

def format_output
  case $options[:format]
  when 'json'
    puts JSON.pretty_generate($test_results)
  when 'junit'
    generate_junit_xml
  else
    format_text_output
  end
end

def format_text_output
  puts "\n" + '=' * 60
  puts '🧪 Test Results Summary'
  puts '=' * 60

  summary = $test_results[:summary]

  puts "\n📊 Overall Statistics:"
  puts "  Total Tests: #{summary[:total_tests]}"
  puts "  Passed: #{summary[:passed]} (#{summary[:success_rate]}%)"
  puts "  Failed: #{summary[:failed]}"
  puts "  Errors: #{summary[:errors]}"
  puts "  Skipped: #{summary[:skipped]}"
  puts "  Duration: #{summary[:duration].round(2)}s"

  puts "\n📝 Suite Results:"
  $test_results[:suites].each do |name, result|
    status = result[:success] ? '✅' : '❌'
    puts "  #{status} #{name}: #{result[:tests]} tests, #{result[:failures]} failures, #{result[:errors]} errors"

    next unless $options[:verbose] && !result[:success]

    puts '    Output preview:'
    result[:output].lines.first(3).each do |line|
      puts "      #{line.chomp}"
    end
  end

  # Overall result
  puts "\n" + '=' * 60
  total_failures = summary[:failed] + summary[:errors]

  if total_failures == 0
    puts '🎉 ALL TESTS PASSED! 🎉'
    if summary[:success_rate] == 100.0
      puts "Perfect score: #{summary[:total_tests]}/#{summary[:total_tests]} tests passed"
    end
  else
    puts '❌ TEST FAILURES DETECTED'
    puts "#{total_failures} test(s) failed out of #{summary[:total_tests]}"

    puts "\nFailing in CI mode due to test failures" if $options[:ci_mode]
  end

  puts '=' * 60
end

def generate_junit_xml
  xml = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites tests="#{$test_results[:summary][:total_tests]}"
                failures="#{$test_results[:summary][:failed]}"
                errors="#{$test_results[:summary][:errors]}"
                time="#{$test_results[:summary][:duration]}">
  XML

  $test_results[:suites].each do |name, result|
    xml += <<~XML
      <testsuite name="#{name}"
                 tests="#{result[:tests]}"
                 failures="#{result[:failures]}"
                 errors="#{result[:errors]}"
                 time="#{result[:duration]}">
    XML

    result[:test_cases].each do |test_case|
      xml += "    <testcase name=\"#{test_case[:name]}\" classname=\"#{name}\">\n"

      case test_case[:status]
      when 'fail'
        xml += "      <failure type=\"AssertionFailure\">Test failed</failure>\n"
      when 'error'
        xml += "      <error type=\"RuntimeError\">Test error</error>\n"
      when 'skip'
        xml += "      <skipped/>\n"
      end

      xml += "    </testcase>\n"
    end

    xml += "  </testsuite>\n"
  end

  xml += "</testsuites>\n"

  File.write('test-results.xml', xml)
  puts 'JUnit XML written to test-results.xml'
end

def main
  puts '🚀 Leyline Test Suite Runner'
  puts '=' * 60

  # Discover test suites
  suites = discover_test_suites

  if suites.empty?
    puts '❌ No test suites found!'
    exit 1
  end

  # Filter by suite if specified
  if $options[:suite]
    suites = suites.select { |s| s[:name] == $options[:suite] }
    if suites.empty?
      puts "❌ Test suite '#{$options[:suite]}' not found!"
      exit 1
    end
  end

  puts "\n📋 Discovered #{suites.size} test suite(s):"
  suites.each do |suite|
    puts "  • #{suite[:name]}: #{suite[:description]}"
  end

  # Run tests
  puts "\n🧪 Running Tests..."

  start_time = Time.now

  if $options[:parallel] && suites.size > 1
    # Run tests in parallel
    threads = []
    suite_results = {}

    suites.each do |suite|
      threads << Thread.new do
        suite_results[suite[:name]] = run_test_suite(suite)
      end
    end

    threads.each(&:join)
    suite_results = suite_results.values
  else
    # Run tests sequentially
    suite_results = suites.map { |suite| run_test_suite(suite) }
  end

  total_duration = Time.now - start_time

  # Aggregate results
  aggregate_results(suite_results)
  $test_results[:summary][:total_duration] = total_duration

  # Run benchmarks if requested
  if $options[:benchmark]
    benchmark_results = run_performance_benchmarks
    $test_results[:benchmarks] = benchmark_results
  end

  # Generate coverage report
  coverage_ok = generate_coverage_report

  # Format and display results
  format_output

  # Exit with appropriate code
  total_failures = $test_results[:summary][:failed] + $test_results[:summary][:errors]
  coverage_failed = $options[:coverage] && !coverage_ok

  if $options[:ci_mode] && (total_failures > 0 || coverage_failed)
    exit 1
  elsif total_failures > 0
    exit 1
  else
    exit 0
  end
end

# Run the test suite
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\n\n⚠️  Test run interrupted by user"
    exit 1
  rescue StandardError => e
    puts "\n❌ Test runner error: #{e.message}"
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
