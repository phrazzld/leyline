# frozen_string_literal: true

module BenchmarkHelpers
  # Performance targets for Leyline CLI operations
  TARGET_PERFORMANCE_MS = 2000  # 2 seconds for transparency commands
  TARGET_CACHE_HIT_RATIO = 0.8  # 80% cache hit ratio
  TARGET_MEMORY_MB = 50         # 50MB memory limit

  # Helper method to measure execution time
  def measure_time(&block)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = block.call
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration_ms = ((end_time - start_time) * 1000).round(3)
    [result, duration_ms]
  end

  # Helper method to create test cache directories
  def create_test_cache_dir
    Dir.mktmpdir('benchmark-cache-')
  end

  # Helper method to create zero-byte cache files
  def create_zero_byte_cache_files(cache_dir)
    FileUtils.mkdir_p(File.join(cache_dir, 'content', 'ab'))
    File.write(File.join(cache_dir, 'content', 'ab', 'cd1234'), '')
    File.write(File.join(cache_dir, 'content', 'ab', 'cd5678'), '')
  end

  # Helper method to validate performance targets
  def expect_performance_target_met(duration_ms, target_ms = TARGET_PERFORMANCE_MS)
    expect(duration_ms).to be < target_ms,
      "Performance target not met: #{duration_ms}ms >= #{target_ms}ms"
  end

  # Helper method to validate cache hit ratio
  def expect_cache_ratio_target_met(hit_ratio, target_ratio = TARGET_CACHE_HIT_RATIO)
    expect(hit_ratio).to be >= target_ratio,
      "Cache hit ratio target not met: #{hit_ratio} < #{target_ratio}"
  end

  # Helper method to validate memory usage
  def expect_memory_target_met(memory_mb, target_mb = TARGET_MEMORY_MB)
    expect(memory_mb).to be < target_mb,
      "Memory usage target not met: #{memory_mb}MB >= #{target_mb}MB"
  end
end
