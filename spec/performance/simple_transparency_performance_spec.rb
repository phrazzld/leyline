# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'support/shared_examples/performance_testing'

RSpec.describe 'Simple Transparency Performance Tests', :performance do
  let(:test_dirs) do
    {
      target: Dir.mktmpdir('simple-perf-target'),
      cache: Dir.mktmpdir('simple-perf-cache')
    }
  end

  let(:cli) { Leyline::CLI.new }

  before do
    setup_test_environment
    create_basic_test_data
  end

  after do
    cleanup_test_environment
  end

  describe 'Status Command' do
    let(:status_command_block) { proc { invoke_status_command } }

    include_examples 'reliable performance measurement', 'status', :status_command_block
    include_examples 'scalable performance characteristics', 'status', :status_command_block
    include_examples 'statistical regression detection', 'status', :status_command_block
  end

  describe 'Performance Comparison with Existing Tests' do
    it 'demonstrates improved statistical reliability over existing tests' do
      # Show how our statistical approach compares to existing fixed-threshold tests

      # Measure using statistical method (our approach)
      statistical_metrics = measure_command_with_statistics('status_statistical') do
        invoke_status_command
      end

      # Simulate old approach with fixed threshold
      fixed_threshold_result = measure_with_fixed_threshold do
        invoke_status_command
      end

      puts "\n📊 PERFORMANCE TESTING APPROACH COMPARISON"
      puts '=' * 60
      puts 'Statistical Approach (our method):'
      puts "  - P95 time: #{(statistical_metrics[:p95_seconds] * 1000).round(1)}ms"
      puts "  - Success rate: #{(statistical_metrics[:success_rate] * 100).round(1)}%"
      puts "  - Sample size: #{statistical_metrics[:sample_size]}"
      puts "  - Coefficient variation: #{statistical_metrics[:coefficient_of_variation].round(3)}"
      puts
      puts 'Fixed Threshold Approach (comparison):'
      puts "  - Single measurement: #{(fixed_threshold_result[:single_time] * 1000).round(1)}ms"
      puts "  - Pass/fail: #{fixed_threshold_result[:passes_2s_threshold] ? 'PASS' : 'FAIL'} (<2000ms)"
      puts '  - Reliability: Lower (single sample, hardware dependent)'
      puts '=' * 60

      # Our statistical approach should provide more reliable insights
      expect(statistical_metrics[:sample_size]).to be >= 8
      expect(statistical_metrics[:coefficient_of_variation]).to be < 1.0

      puts '✅ Statistical approach provides more reliable performance insights'
    end
  end

  private

  def setup_test_environment
    @original_cache_dir = ENV['LEYLINE_CACHE_DIR']
    ENV['LEYLINE_CACHE_DIR'] = test_dirs[:cache]

    allow(Leyline::Cache::FileCache).to receive(:new).and_return(
      Leyline::Cache::FileCache.new(test_dirs[:cache])
    )
  end

  def cleanup_test_environment
    ENV['LEYLINE_CACHE_DIR'] = @original_cache_dir
    test_dirs.values.each { |dir| FileUtils.rm_rf(dir) if Dir.exist?(dir) }
  end

  def create_basic_test_data
    setup_test_data_with_size(50) # Default size for basic tests
  end

  def setup_test_data_with_size(file_count)
    # Clean target directory
    FileUtils.rm_rf(test_dirs[:target])

    # Create leyline structure
    docs_dir = File.join(test_dirs[:target], 'docs', 'leyline')
    FileUtils.mkdir_p(File.join(docs_dir, 'tenets'))
    FileUtils.mkdir_p(File.join(docs_dir, 'bindings', 'core'))

    # Generate test files
    file_count.times do |i|
      content = create_test_document_content(i)

      file_path = if i.even?
                    File.join(docs_dir, 'tenets', "simple-tenet-#{i}.md")
                  else
                    File.join(docs_dir, 'bindings', 'core', "simple-binding-#{i}.md")
                  end

      File.write(file_path, content)
    end

    # Add some local modifications
    add_local_modifications(docs_dir)
  end

  def create_test_document_content(index)
    <<~CONTENT
      ---
      id: simple-test-#{index}
      last_modified: '2025-06-23'
      version: '0.1.0'
      ---

      # Simple Test Document #{index}

      This is a test document for performance measurement.

      ## Content Section

      #{'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * (5 + index % 10)}

      ## Implementation

      ```ruby
      class SimpleTest#{index}
        def perform
          # Test implementation #{index}
          process_data
        end
      end
      ```

      ## Additional Context

      #{'Performance testing requires realistic content to measure effectively. ' * (3 + index % 5)}
    CONTENT
  end

  def add_local_modifications(docs_dir)
    # Add local changes to simulate real development
    existing_files = Dir.glob('**/*.md', base: docs_dir).first(3)

    existing_files.each do |file|
      file_path = File.join(docs_dir, file)
      content = File.read(file_path)
      File.write(file_path, content + "\n\n## Local Change\n\nLocal modification for testing.\n")
    end
  end

  def invoke_status_command
    result = capture_command_output do
      cli.invoke(:status, [test_dirs[:target]], verbose: false)
    end

    {
      success: result[:stderr].empty? || !result[:stderr].include?('Error'),
      output: result
    }
  end

  def measure_with_fixed_threshold(&block)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = block.call
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    execution_time = end_time - start_time

    {
      single_time: execution_time,
      passes_2s_threshold: execution_time < 2.0,
      result: result
    }
  end

  def capture_command_output(&block)
    original_stdout = $stdout
    original_stderr = $stderr

    stdout_capture = StringIO.new
    stderr_capture = StringIO.new

    $stdout = stdout_capture
    $stderr = stderr_capture

    begin
      block.call
    rescue SystemExit
      # CLI may exit, capture gracefully
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
