#!/usr/bin/env ruby
# tools/benchmark_performance.rb - Performance benchmarking for validation script
# Tests execution time against large datasets and various error scenarios

require 'benchmark'
require 'fileutils'
require 'tmpdir'
require 'json'

class PerformanceBenchmark
  BENCHMARK_DIR = "benchmark_temp"
  RESULTS_FILE = "benchmark_results.json"

  # Test scenarios with different file counts and types
  TEST_SCENARIOS = {
    small: { count: 50, description: "Small dataset (50 files)" },
    medium: { count: 200, description: "Medium dataset (200 files)" },
    large: { count: 500, description: "Large dataset (500 files)" },
    xl: { count: 1000, description: "Extra-large dataset (1000 files)" }
  }.freeze

  # Different file types for testing various performance characteristics
  FILE_TYPES = {
    valid_tenet: {
      template: lambda { |id|
        <<~MARKDOWN
          ---
          id: #{id}
          last_modified: '2025-05-10'
          version: '0.1.0'
          ---

          # Tenet: #{id.capitalize}

          This is a benchmark tenet file for performance testing.
        MARKDOWN
      },
      directory: "tenets"
    },

    valid_binding: {
      template: lambda { |id|
        <<~MARKDOWN
          ---
          id: #{id}
          last_modified: '2025-05-10'
          derived_from: simplicity
          enforced_by: 'linter, manual review'
          version: '0.1.0'
          ---

          # Binding: #{id.capitalize}

          This is a benchmark binding file for performance testing.
        MARKDOWN
      },
      directory: "bindings/core"
    },

    invalid_yaml: {
      template: lambda { |id|
        <<~MARKDOWN
          ---
          id: #{id}
          last_modified: '2025-05-10
          derived_from: simplicity
          enforced_by: 'linter, manual review'
          version: '0.1.0'
          ---

          # Invalid YAML Binding: #{id.capitalize}

          This file has invalid YAML syntax for testing error handling performance.
        MARKDOWN
      },
      directory: "bindings/core"
    },

    missing_fields: {
      template: lambda { |id|
        <<~MARKDOWN
          ---
          id: #{id}
          last_modified: '2025-05-10'
          ---

          # Missing Fields Binding: #{id.capitalize}

          This file is missing required fields for testing validation performance.
        MARKDOWN
      },
      directory: "bindings/core"
    },

    invalid_references: {
      template: lambda { |id|
        <<~MARKDOWN
          ---
          id: #{id}
          last_modified: '2025-05-10'
          derived_from: nonexistent-tenet-#{id}
          enforced_by: 'linter, manual review'
          version: '0.1.0'
          ---

          # Invalid Reference Binding: #{id.capitalize}

          This file references a non-existent tenet for testing reference validation performance.
        MARKDOWN
      },
      directory: "bindings/core"
    }
  }.freeze

  def initialize
    @results = {}
    @temp_dirs = []
  end

  def run_benchmarks
    puts "=" * 80
    puts "Performance Benchmark Suite"
    puts "Testing validation script performance against various datasets"
    puts "=" * 80
    puts

    begin
      # Create baseline measurement
      run_baseline_benchmark

      # Run scenario-based benchmarks
      TEST_SCENARIOS.each do |scenario_name, config|
        puts "\n" + "-" * 60
        puts "Running scenario: #{config[:description]}"
        puts "-" * 60

        run_scenario_benchmark(scenario_name, config)
      end

      # Run file type specific benchmarks
      run_file_type_benchmarks

      # Save and display results
      save_results
      display_summary

    ensure
      cleanup_temp_directories
    end
  end

  private

  def run_baseline_benchmark
    puts "Establishing baseline with existing repository files..."

    # Test with actual repository files
    existing_files = Dir.glob("docs/**/*.md").select { |f| File.file?(f) }
    puts "Found #{existing_files.count} existing files"

    if existing_files.count > 0
      time = measure_validation_time(existing_files.sample(10)) # Sample to avoid long baseline
      @results[:baseline] = {
        description: "Baseline with #{existing_files.count} existing repository files (sampled 10)",
        file_count: 10,
        execution_time: time,
        throughput: 10.0 / time
      }

      puts "✓ Baseline: #{format_time(time)} for 10 files (#{format_throughput(10.0 / time)})"
    else
      puts "⚠ No existing files found for baseline"
    end
  end

  def run_scenario_benchmark(scenario_name, config)
    temp_dir = create_temp_directory(scenario_name.to_s)

    # Generate balanced mix of file types
    files_per_type = config[:count] / FILE_TYPES.count
    remaining_files = config[:count] % FILE_TYPES.count

    generated_files = []

    FILE_TYPES.each_with_index do |(type_name, type_config), index|
      count = files_per_type
      count += 1 if index < remaining_files # Distribute remainder

      files = generate_files(temp_dir, type_name, type_config, count)
      generated_files.concat(files)
    end

    puts "Generated #{generated_files.count} files across #{FILE_TYPES.count} types"

    # Measure validation time
    time = measure_validation_time(generated_files)

    @results[scenario_name] = {
      description: config[:description],
      file_count: generated_files.count,
      execution_time: time,
      throughput: generated_files.count.to_f / time,
      files_per_type: files_per_type
    }

    puts "✓ #{config[:description]}: #{format_time(time)} for #{generated_files.count} files (#{format_throughput(generated_files.count.to_f / time)})"
  end

  def run_file_type_benchmarks
    puts "\n" + "-" * 60
    puts "File Type Specific Performance Analysis"
    puts "-" * 60

    FILE_TYPES.each do |type_name, type_config|
      temp_dir = create_temp_directory("filetype_#{type_name}")

      # Generate 100 files of this specific type
      files = generate_files(temp_dir, type_name, type_config, 100)

      time = measure_validation_time(files)

      @results["filetype_#{type_name}".to_sym] = {
        description: "100 #{type_name.to_s.gsub('_', ' ')} files",
        file_count: 100,
        execution_time: time,
        throughput: 100.0 / time,
        file_type: type_name
      }

      puts "✓ #{type_name.to_s.gsub('_', ' ').capitalize}: #{format_time(time)} for 100 files (#{format_throughput(100.0 / time)})"
    end
  end

  def create_temp_directory(name)
    temp_dir = File.join(BENCHMARK_DIR, name)
    FileUtils.mkdir_p(temp_dir)
    @temp_dirs << temp_dir

    # Create directory structure
    FileUtils.mkdir_p(File.join(temp_dir, "docs/tenets"))
    FileUtils.mkdir_p(File.join(temp_dir, "docs/bindings/core"))
    FileUtils.mkdir_p(File.join(temp_dir, "docs/bindings/categories/typescript"))

    # Copy VERSION file if it exists
    if File.exist?("VERSION")
      FileUtils.cp("VERSION", temp_dir)
    else
      File.write(File.join(temp_dir, "VERSION"), "0.1.0")
    end

    temp_dir
  end

  def generate_files(base_dir, type_name, type_config, count)
    files = []
    dir_path = File.join(base_dir, "docs", type_config[:directory])
    FileUtils.mkdir_p(dir_path)

    count.times do |i|
      id = "benchmark-#{type_name}-#{i.to_s.rjust(4, '0')}"
      filename = "#{id}.md"
      filepath = File.join(dir_path, filename)

      File.write(filepath, type_config[:template].call(id))
      files << filepath
    end

    files
  end

  def measure_validation_time(files)
    # Create a temporary file list for batch processing
    temp_file_list = File.join(Dir.tmpdir, "benchmark_files_#{Process.pid}.txt")
    File.write(temp_file_list, files.join("\n"))

    time = nil

    if files.count == 1
      # Single file measurement
      time = Benchmark.realtime do
        system("ruby tools/validate_front_matter.rb -f '#{files.first}' >/dev/null 2>&1")
      end
    elsif files.count <= 10
      # Individual file measurement for small sets
      time = Benchmark.realtime do
        files.each do |file|
          system("ruby tools/validate_front_matter.rb -f '#{file}' >/dev/null 2>&1")
        end
      end
    else
      # For larger sets, we need to temporarily modify the script or use existing directory structure
      # Let's measure by copying files to a temporary docs structure and running validation
      temp_docs_dir = File.join(Dir.tmpdir, "benchmark_docs_#{Process.pid}")
      FileUtils.mkdir_p("#{temp_docs_dir}/tenets")
      FileUtils.mkdir_p("#{temp_docs_dir}/bindings/core")

      # Copy files to expected structure
      files.each do |file|
        if file.include?("/tenets/")
          FileUtils.cp(file, "#{temp_docs_dir}/tenets/")
        elsif file.include?("/bindings/")
          FileUtils.cp(file, "#{temp_docs_dir}/bindings/core/")
        end
      end

      # Change to temp directory and run validation
      original_dir = Dir.pwd
      time = Benchmark.realtime do
        Dir.chdir(File.dirname(temp_docs_dir))
        system("ruby '#{original_dir}/tools/validate_front_matter.rb' >/dev/null 2>&1")
      end
      Dir.chdir(original_dir)

      # Cleanup
      FileUtils.rm_rf(temp_docs_dir)
    end

    # Cleanup temp file list
    File.delete(temp_file_list) if File.exist?(temp_file_list)

    time
  rescue => e
    puts "Error measuring validation time: #{e.message}"
    0.0
  end

  def save_results
    # Add metadata
    @results[:metadata] = {
      timestamp: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
      ruby_version: RUBY_VERSION,
      platform: RUBY_PLATFORM,
      total_scenarios: @results.count - 1 # Exclude metadata
    }

    File.write(RESULTS_FILE, JSON.pretty_generate(@results))
    puts "\n✓ Results saved to #{RESULTS_FILE}"
  end

  def display_summary
    puts "\n" + "=" * 80
    puts "Performance Benchmark Summary"
    puts "=" * 80

    if @results[:baseline]
      baseline = @results[:baseline]
      puts "\nBaseline Performance:"
      puts "  Files: #{baseline[:file_count]}"
      puts "  Time: #{format_time(baseline[:execution_time])}"
      puts "  Throughput: #{format_throughput(baseline[:throughput])}"
    end

    puts "\nScenario Performance:"
    TEST_SCENARIOS.each do |scenario_name, _|
      next unless @results[scenario_name]

      result = @results[scenario_name]
      puts "  #{result[:description]}:"
      puts "    Time: #{format_time(result[:execution_time])}"
      puts "    Throughput: #{format_throughput(result[:throughput])}"

      if @results[:baseline]
        ratio = result[:throughput] / @results[:baseline][:throughput]
        puts "    vs Baseline: #{(ratio * 100).round(1)}%"
      end
    end

    puts "\nFile Type Performance (100 files each):"
    FILE_TYPES.each do |type_name, _|
      result_key = "filetype_#{type_name}".to_sym
      next unless @results[result_key]

      result = @results[result_key]
      puts "  #{type_name.to_s.gsub('_', ' ').capitalize}:"
      puts "    Time: #{format_time(result[:execution_time])}"
      puts "    Throughput: #{format_throughput(result[:throughput])}"
    end

    # Performance analysis
    puts "\nPerformance Analysis:"
    analyze_performance
  end

  def analyze_performance
    # Find fastest and slowest scenarios
    scenario_results = @results.select { |k, v| TEST_SCENARIOS.key?(k) }

    if scenario_results.any?
      fastest = scenario_results.max_by { |_, v| v[:throughput] }
      slowest = scenario_results.min_by { |_, v| v[:throughput] }

      puts "  Fastest scenario: #{fastest[1][:description]} (#{format_throughput(fastest[1][:throughput])})"
      puts "  Slowest scenario: #{slowest[1][:description]} (#{format_throughput(slowest[1][:throughput])})"

      if fastest[1][:throughput] > 0 && slowest[1][:throughput] > 0
        ratio = fastest[1][:throughput] / slowest[1][:throughput]
        puts "  Performance variation: #{ratio.round(2)}x difference"
      end
    end

    # File type analysis
    file_type_results = @results.select { |k, v| k.to_s.start_with?('filetype_') }

    if file_type_results.any?
      fastest_type = file_type_results.max_by { |_, v| v[:throughput] }
      slowest_type = file_type_results.min_by { |_, v| v[:throughput] }

      puts "  Fastest file type: #{fastest_type[1][:file_type].to_s.gsub('_', ' ')} (#{format_throughput(fastest_type[1][:throughput])})"
      puts "  Slowest file type: #{slowest_type[1][:file_type].to_s.gsub('_', ' ')} (#{format_throughput(slowest_type[1][:throughput])})"
    end

    # Performance recommendations
    puts "\nRecommendations:"
    if @results[:baseline]
      baseline_throughput = @results[:baseline][:throughput]

      # Check if any scenario is significantly slower
      slow_scenarios = scenario_results.select { |_, v| v[:throughput] < baseline_throughput * 0.5 }

      if slow_scenarios.any?
        puts "  ⚠ Some scenarios are significantly slower than baseline"
        slow_scenarios.each do |name, result|
          puts "    - #{result[:description]}: #{format_throughput(result[:throughput])} (#{((result[:throughput] / baseline_throughput) * 100).round(1)}% of baseline)"
        end
      else
        puts "  ✓ Performance is acceptable across all scenarios"
      end
    end

    # Check for very slow absolute performance
    all_throughputs = @results.values.select { |v| v.is_a?(Hash) && v[:throughput] }.map { |v| v[:throughput] }
    if all_throughputs.any? && all_throughputs.min < 1.0
      puts "  ⚠ Some scenarios have very low throughput (< 1 file/second)"
      puts "    Consider optimizing for large file sets"
    end
  end

  def cleanup_temp_directories
    @temp_dirs.each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
    FileUtils.rm_rf(BENCHMARK_DIR) if Dir.exist?(BENCHMARK_DIR)
  end

  def format_time(seconds)
    if seconds < 1.0
      "#{(seconds * 1000).round(1)}ms"
    else
      "#{seconds.round(3)}s"
    end
  end

  def format_throughput(files_per_second)
    "#{files_per_second.round(2)} files/sec"
  end
end

# Run benchmarks if this script is executed directly
if __FILE__ == $0
  benchmark = PerformanceBenchmark.new
  benchmark.run_benchmarks
end
