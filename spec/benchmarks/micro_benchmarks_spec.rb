# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'
require 'json'
require 'securerandom'
require_relative '../support/benchmark_helpers'

RSpec.describe 'Transparency Commands Micro-Benchmarks', type: :benchmark do
  include BenchmarkHelpers

  # Performance targets for individual operations (milliseconds)
  MICRO_TARGETS = {
    file_discovery: {
      glob_pattern_matching: 100,      # ms for 1000 files
      manifest_creation: 300,          # ms for 1000 files (increased for CI stability)
      hash_computation: 300,           # ms for 1000 files
      category_detection: 50           # ms regardless of size
    },
    cache_operations: {
      cache_lookup: 1,                 # ms per lookup
      cache_write: 5,                  # ms per write
      cache_eviction: 10,              # ms per eviction
      hit_ratio_calculation: 10        # ms for full stats
    },
    comparison_operations: {
      manifest_diff: 100,              # ms for 1000 files
      content_diff: 200,               # ms per modified file
      conflict_detection: 150,         # ms for full analysis
      change_summary: 50               # ms for summary generation
    },
    git_operations: {
      sparse_checkout_setup: 500,      # ms for initial setup
      fetch_with_cache: 100,          # ms when cache valid
      fetch_without_cache: 2000       # ms for full fetch
    }
  }.freeze

  let(:test_dataset) { generate_deterministic_dataset(file_count: 1000) }
  let(:temp_dir) { test_dataset[:temp_dir] }
  let(:file_comparator) { Leyline::FileComparator.new(base_directory: temp_dir) }
  let(:cache) { Leyline::Cache::FileCache.new(Dir.mktmpdir('benchmark-cache')) }

  describe 'File Discovery Operations' do
    context 'glob pattern matching' do
      it 'discovers files within performance target' do
        patterns = ['tenets/**/*.md', 'bindings/core/**/*.md', 'bindings/categories/**/*.md']

        result = benchmark_operation('glob_pattern_matching', iterations: 10) do
          files = []
          patterns.each do |pattern|
            search_path = File.join(temp_dir, 'docs', 'leyline', pattern)
            files.concat(Dir.glob(search_path))
          end
          files
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:file_discovery][:glob_pattern_matching]
        expect(result[:p95_ms]).to be < MICRO_TARGETS[:file_discovery][:glob_pattern_matching] * 1.2

        log_benchmark_result('glob_pattern_matching', result)
      end
    end

    context 'manifest creation' do
      it 'creates file manifest within performance target' do
        files = discover_all_files(temp_dir)

        result = benchmark_operation('manifest_creation', iterations: 10) do
          manifest = {}
          files.each do |file|
            content = File.read(file)
            manifest[file] = Digest::SHA256.hexdigest(content)
          end
          manifest
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:file_discovery][:manifest_creation]
        expect(result[:memory_delta_mb]).to be < 20  # Reasonable memory usage

        log_benchmark_result('manifest_creation', result)
      end
    end

    context 'hash computation' do
      it 'computes file hashes efficiently' do
        files = discover_all_files(temp_dir).first(1000)

        result = benchmark_operation('hash_computation', iterations: 10) do
          files.map do |file|
            content = File.read(file)
            Digest::SHA256.hexdigest(content)
          end
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:file_discovery][:hash_computation]

        # Verify hash rate
        hash_rate = (1000.0 / result[:average_ms]) * 1000  # files per second
        expect(hash_rate).to be > 3000  # Should hash >3000 files/second

        log_benchmark_result('hash_computation', result.merge(hash_rate: hash_rate))
      end
    end

    context 'category detection' do
      it 'detects categories quickly regardless of file count' do
        result = benchmark_operation('category_detection', iterations: 20) do
          categories = ['core']
          bindings_path = File.join(temp_dir, 'docs', 'leyline', 'bindings', 'categories')

          if Dir.exist?(bindings_path)
            Dir.entries(bindings_path).each do |entry|
              next if entry.start_with?('.')
              category_path = File.join(bindings_path, entry)
              categories << entry if Dir.exist?(category_path)
            end
          end

          categories.sort
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:file_discovery][:category_detection]
        expect(result[:std_deviation_ms]).to be < 10  # Should be very consistent

        log_benchmark_result('category_detection', result)
      end
    end
  end

  describe 'Cache Operations' do
    let(:test_content) { 'x' * 5000 }  # 5KB test content

    context 'cache lookup' do
      it 'performs lookups within target' do
        # Pre-populate cache
        100.times { |i| cache.put("test-content-#{i}") }

        result = benchmark_operation('cache_lookup', iterations: 1000) do
          hash = Digest::SHA256.hexdigest("test-content-#{rand(100)}")
          cache.get(hash)
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:cache_operations][:cache_lookup]

        lookup_rate = (1000.0 / result[:average_ms]) * 1000  # lookups per second
        expect(lookup_rate).to be > 100_000  # Should handle >100k lookups/second

        log_benchmark_result('cache_lookup', result.merge(lookup_rate: lookup_rate))
      end
    end

    context 'cache write' do
      it 'writes to cache within target' do
        result = benchmark_operation('cache_write', iterations: 100) do
          content = "test-content-#{SecureRandom.hex(16)}"
          cache.put(content)
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:cache_operations][:cache_write]

        write_rate = (100.0 / result[:average_ms]) * 1000  # writes per second
        expect(write_rate).to be > 10_000  # Should handle >10k writes/second

        log_benchmark_result('cache_write', result.merge(write_rate: write_rate))
      end
    end

    context 'hit ratio calculation' do
      it 'calculates statistics quickly' do
        # Simulate cache activity
        stats = Leyline::Cache::CacheStats.new
        1000.times do
          stats.record_cache_hit
          stats.record_cache_miss if rand > 0.8
        end

        result = benchmark_operation('hit_ratio_calculation', iterations: 100) do
          {
            hit_ratio: stats.hit_ratio,
            total_operations: stats.total_operations,
            hits: stats.hits,
            misses: stats.misses
          }
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:cache_operations][:hit_ratio_calculation]

        log_benchmark_result('hit_ratio_calculation', result)
      end
    end
  end

  describe 'Comparison Operations' do
    let(:manifest1) { create_test_manifest(1000) }
    let(:manifest2) { create_modified_manifest(manifest1, modification_rate: 0.1) }

    context 'manifest diff' do
      it 'compares manifests within target' do
        result = benchmark_operation('manifest_diff', iterations: 20) do
          added = []
          removed = []
          modified = []
          unchanged = []

          all_keys = (manifest1.keys + manifest2.keys).uniq

          all_keys.each do |key|
            if !manifest1[key]
              added << key
            elsif !manifest2[key]
              removed << key
            elsif manifest1[key] != manifest2[key]
              modified << key
            else
              unchanged << key
            end
          end

          { added: added, removed: removed, modified: modified, unchanged: unchanged }
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:comparison_operations][:manifest_diff]

        diff_rate = (1000.0 / result[:average_ms]) * 1000  # files compared per second
        expect(diff_rate).to be > 10_000  # Should compare >10k files/second

        log_benchmark_result('manifest_diff', result.merge(diff_rate: diff_rate))
      end
    end

    context 'conflict detection' do
      it 'detects conflicts efficiently' do
        # Create three-way comparison scenario
        base_manifest = manifest1
        local_manifest = create_modified_manifest(base_manifest, modification_rate: 0.1)
        remote_manifest = create_modified_manifest(base_manifest, modification_rate: 0.15)

        result = benchmark_operation('conflict_detection', iterations: 20) do
          conflicts = []

          # Find files modified in both local and remote
          local_changes = local_manifest.select { |k, v| base_manifest[k] && base_manifest[k] != v }
          remote_changes = remote_manifest.select { |k, v| base_manifest[k] && base_manifest[k] != v }

          conflicted_files = local_changes.keys & remote_changes.keys

          conflicted_files.each do |file|
            conflicts << {
              file: file,
              type: :both_modified,
              local_hash: local_manifest[file],
              remote_hash: remote_manifest[file],
              base_hash: base_manifest[file]
            }
          end

          conflicts
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:comparison_operations][:conflict_detection]

        log_benchmark_result('conflict_detection', result)
      end
    end

    context 'change summary generation' do
      it 'generates summaries quickly' do
        changes = {
          added: Array.new(50) { |i| "added-file-#{i}.md" },
          modified: Array.new(100) { |i| "modified-file-#{i}.md" },
          removed: Array.new(30) { |i| "removed-file-#{i}.md" }
        }

        result = benchmark_operation('change_summary', iterations: 100) do
          {
            total_changes: changes[:added].size + changes[:modified].size + changes[:removed].size,
            added_count: changes[:added].size,
            modified_count: changes[:modified].size,
            removed_count: changes[:removed].size,
            categories_affected: extract_categories_from_paths(changes[:modified]),
            largest_change_type: changes.max_by { |_, v| v.size }.first
          }
        end

        expect(result[:average_ms]).to be < MICRO_TARGETS[:comparison_operations][:change_summary]

        log_benchmark_result('change_summary', result)
      end
    end
  end

  describe 'Memory Efficiency' do
    it 'processes large file sets within memory bounds' do
      file_counts = [100, 500, 1000, 2000, 5000]
      memory_results = []

      file_counts.each do |count|
        dataset = generate_deterministic_dataset(file_count: count)
        files = discover_all_files(dataset[:temp_dir])

        GC.start
        before_memory = get_memory_usage_mb

        # Simulate full command operation
        manifest = {}
        files.each do |file|
          content = File.read(file)
          manifest[file] = Digest::SHA256.hexdigest(content)
        end

        after_memory = get_memory_usage_mb
        memory_delta = after_memory - before_memory

        memory_results << {
          file_count: count,
          memory_used_mb: memory_delta,
          mb_per_1k_files: (memory_delta / (count / 1000.0))
        }

        # Cleanup
        FileUtils.rm_rf(dataset[:temp_dir])
      end

      # Verify memory scales linearly and stays within bounds
      memory_results.each do |result|
        expect(result[:mb_per_1k_files]).to be < 10  # <10MB per 1000 files
      end

      # Log results
      puts "\nMemory Scaling Results:"
      memory_results.each do |r|
        puts "  #{r[:file_count]} files: #{r[:memory_used_mb].round(2)}MB (#{r[:mb_per_1k_files].round(2)}MB/1k files)"
      end
    end
  end

  private

  def generate_deterministic_dataset(file_count:, seed: 42)
    random = Random.new(seed)
    temp_dir = Dir.mktmpdir('benchmark-dataset')

    # Create directory structure
    FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'leyline', 'tenets'))
    FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'leyline', 'bindings', 'core'))

    categories = %w[typescript go rust python frontend backend]
    categories.each do |cat|
      FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'leyline', 'bindings', 'categories', cat))
    end

    # Distribute files realistically
    tenet_count = (file_count * 0.1).to_i
    core_binding_count = (file_count * 0.2).to_i
    category_binding_count = file_count - tenet_count - core_binding_count

    # Generate tenets
    tenet_count.times do |i|
      path = File.join(temp_dir, 'docs', 'leyline', 'tenets', "tenet-#{i}.md")
      File.write(path, generate_file_content('tenet', i, random))
    end

    # Generate core bindings
    core_binding_count.times do |i|
      path = File.join(temp_dir, 'docs', 'leyline', 'bindings', 'core', "binding-#{i}.md")
      File.write(path, generate_file_content('core-binding', i, random))
    end

    # Generate category bindings
    category_binding_count.times do |i|
      category = categories[i % categories.length]
      path = File.join(temp_dir, 'docs', 'leyline', 'bindings', 'categories', category, "#{category}-binding-#{i}.md")
      File.write(path, generate_file_content("#{category}-binding", i, random))
    end

    { temp_dir: temp_dir, file_count: file_count }
  end

  def generate_file_content(type, index, random)
    # Generate realistic file sizes (power law distribution)
    size_category = random.rand(100)
    base_size = case size_category
                when 0..60   then random.rand(1000..5000)      # 1-5KB - 60%
                when 61..85  then random.rand(5000..20000)     # 5-20KB - 25%
                when 86..95  then random.rand(20000..100000)   # 20-100KB - 10%
                else              random.rand(100000..500000)   # 100-500KB - 5%
                end

    content = <<~CONTENT
      ---
      id: #{type}-#{index}
      last_modified: '2025-06-22'
      version: '0.1.0'
      ---

      # #{type.capitalize} #{index}

      #{random.bytes(base_size / 2).unpack1('H*')}

      ## Implementation

      #{random.bytes(base_size / 2).unpack1('H*')}
    CONTENT

    content
  end

  def discover_all_files(base_dir)
    Dir.glob(File.join(base_dir, 'docs', 'leyline', '**', '*.md'))
  end

  def benchmark_operation(name, iterations:)
    times = []
    memory_deltas = []

    # Warmup
    2.times { yield }

    iterations.times do
      GC.start
      before_memory = get_memory_usage_mb

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      yield
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      after_memory = get_memory_usage_mb

      times << (end_time - start_time)
      memory_deltas << (after_memory - before_memory)
    end

    {
      operation: name,
      iterations: iterations,
      times_ms: times,
      average_ms: times.sum / times.length,
      min_ms: times.min,
      max_ms: times.max,
      p95_ms: times.sort[(times.length * 0.95).floor],
      std_deviation_ms: calculate_std_deviation(times),
      memory_delta_mb: memory_deltas.sum / memory_deltas.length
    }
  end

  def create_test_manifest(file_count)
    manifest = {}
    file_count.times do |i|
      path = "test/file-#{i}.md"
      manifest[path] = Digest::SHA256.hexdigest("content-#{i}")
    end
    manifest
  end

  def create_modified_manifest(original, modification_rate:)
    modified = original.dup

    modified.each do |path, hash|
      if rand < modification_rate
        modified[path] = Digest::SHA256.hexdigest("#{hash}-modified")
      end
    end

    # Add some new files
    new_file_count = (original.size * modification_rate * 0.5).to_i
    new_file_count.times do |i|
      path = "test/new-file-#{i}.md"
      modified[path] = Digest::SHA256.hexdigest("new-content-#{i}")
    end

    # Remove some files
    remove_count = (original.size * modification_rate * 0.3).to_i
    modified.keys.sample(remove_count).each { |key| modified.delete(key) }

    modified
  end

  def extract_categories_from_paths(paths)
    categories = Set.new

    paths.each do |path|
      if match = path.match(%r{bindings/categories/([^/]+)/})
        categories << match[1]
      elsif path.include?('bindings/core/')
        categories << 'core'
      elsif path.include?('tenets/')
        categories << 'tenets'
      end
    end

    categories.to_a
  end

  def calculate_std_deviation(values)
    mean = values.sum / values.length.to_f
    variance = values.map { |v| (v - mean) ** 2 }.sum / values.length
    Math.sqrt(variance)
  end

  def get_memory_usage_mb
    @memory_strategy ||= detect_memory_strategy
    @memory_strategy.call
  rescue => e
    warn "Memory measurement failed: #{e.message}" if ENV['LEYLINE_DEBUG']
    0.0
  end

  private

  def detect_memory_strategy
    require 'rbconfig'

    case RbConfig::CONFIG['host_os']
    when /mswin|mingw|cygwin/
      method(:windows_memory)
    when /darwin/
      method(:macos_memory)
    when /linux/
      method(:linux_memory)
    else
      method(:unix_memory)
    end
  end

  def windows_memory
    output = `wmic process where processid=#{Process.pid} get WorkingSetSize /format:list 2>nul`
    if match = output.match(/WorkingSetSize=(\d+)/)
      match[1].to_i / (1024.0 * 1024.0)
    else
      0.0
    end
  end

  def macos_memory
    `ps -o rss= -p #{Process.pid} 2>/dev/null`.to_i / 1024.0
  end

  def linux_memory
    status = File.read("/proc/#{Process.pid}/status")
    if match = status.match(/VmRSS:\s*(\d+)\s*kB/)
      match[1].to_f / 1024.0
    else
      unix_memory
    end
  rescue
    unix_memory
  end

  def unix_memory
    `ps -o rss= -p #{Process.pid} 2>/dev/null`.to_i / 1024.0
  end

  def log_benchmark_result(operation, result)
    puts "\n[MICRO-BENCHMARK] #{operation}:"
    puts "  Average: #{result[:average_ms].round(2)}ms"
    puts "  P95: #{result[:p95_ms].round(2)}ms"
    puts "  Std Dev: #{result[:std_deviation_ms].round(2)}ms"
    puts "  Memory: #{result[:memory_delta_mb].round(2)}MB"

    # Log additional metrics if present
    result.each do |key, value|
      next if [:operation, :iterations, :times_ms, :average_ms, :min_ms, :max_ms, :p95_ms, :std_deviation_ms, :memory_delta_mb].include?(key)
      puts "  #{key.to_s.gsub('_', ' ').capitalize}: #{value.is_a?(Float) ? value.round(2) : value}"
    end
  end
end

# Benchmark helpers module
module BenchmarkHelpers
  def self.included(base)
    base.before(:all) do
      # Ensure consistent environment
      ENV['LEYLINE_BENCHMARK_MODE'] = 'true'
      ENV['LEYLINE_CACHE_DIR'] = Dir.mktmpdir('benchmark-cache')
    end

    base.after(:all) do
      # Cleanup
      FileUtils.rm_rf(ENV['LEYLINE_CACHE_DIR']) if ENV['LEYLINE_CACHE_DIR']
    end
  end
end
