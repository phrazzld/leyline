# Transparency Command Performance Benchmarking Architecture

*A comprehensive, deterministic performance validation framework for Leyline's transparency commands*

## Executive Summary

Performance benchmarking isn't about getting impressive numbers in artificial tests - it's about ensuring your software performs reliably in the chaotic reality of production environments. This architecture provides a systematic approach to validating Leyline's transparency commands meet their <2 second response time targets with 1000+ files, while maintaining >80% cache hit ratios and staying within 50MB memory bounds.

## Core Architecture Principles

1. **Deterministic Over Stochastic** - Tests must produce consistent results across runs
2. **Real-World Over Synthetic** - Benchmark actual usage patterns, not idealized scenarios
3. **Continuous Over Periodic** - Performance is validated on every commit
4. **Granular Over Aggregate** - Measure individual operations to identify bottlenecks

## Performance Requirements Matrix

| Command | Target Response Time | File Count | Cache Hit Ratio | Memory Bound |
|---------|---------------------|------------|-----------------|--------------|
| status  | <2s                 | 1000+      | >80%           | <50MB        |
| diff    | <2s                 | 1000+      | >80%           | <50MB        |
| update  | <2s (preview)       | 1000+      | >80%           | <50MB        |

## Benchmarking Architecture

### 1. Micro-Benchmarks (Component Level)

These benchmarks validate individual operations perform within acceptable bounds:

```ruby
module Leyline
  module Benchmarks
    class MicroBenchmarks
      # File Discovery Operations
      DISCOVERY_TARGETS = {
        glob_pattern_matching: 100,      # ms for 1000 files
        manifest_creation: 200,          # ms for 1000 files
        hash_computation: 300,           # ms for 1000 files
        category_detection: 50           # ms regardless of size
      }.freeze

      # Cache Operations
      CACHE_TARGETS = {
        cache_lookup: 1,                 # ms per lookup
        cache_write: 5,                  # ms per write
        cache_eviction: 10,              # ms per eviction
        hit_ratio_calculation: 10        # ms for full stats
      }.freeze

      # Comparison Operations
      COMPARISON_TARGETS = {
        manifest_diff: 100,              # ms for 1000 files
        content_diff: 200,               # ms per modified file
        conflict_detection: 150,         # ms for full analysis
        change_summary: 50               # ms for summary generation
      }.freeze
    end
  end
end
```

### 2. Macro-Benchmarks (Command Level)

End-to-end command execution benchmarks:

```ruby
module Leyline
  module Benchmarks
    class MacroBenchmarks
      # Real-world scenarios with deterministic datasets
      SCENARIOS = {
        fresh_install: {
          description: "First run with no cache",
          file_count: 1000,
          cache_state: :empty,
          expected_time: 2000  # ms
        },

        warm_cache_no_changes: {
          description: "Repeated run with no file changes",
          file_count: 1000,
          cache_state: :warm,
          expected_time: 500   # ms
        },

        incremental_changes: {
          description: "10% of files modified",
          file_count: 1000,
          modified_percentage: 0.1,
          cache_state: :warm,
          expected_time: 800   # ms
        },

        large_repository: {
          description: "Performance at scale",
          file_count: 5000,
          cache_state: :warm,
          expected_time: 2000  # ms
        },

        cache_corruption: {
          description: "Recovery from corrupted cache",
          file_count: 1000,
          cache_state: :corrupted,
          expected_time: 2500  # ms (includes recovery)
        }
      }.freeze
    end
  end
end
```

### 3. Deterministic Test Data Generation

```ruby
module Leyline
  module Benchmarks
    class TestDataGenerator
      # Generates consistent, realistic file structures
      def generate_benchmark_repository(file_count:, seed: 42)
        random = Random.new(seed)  # Deterministic randomness

        structure = {
          tenets: generate_tenets(count: file_count * 0.1, random: random),
          core_bindings: generate_bindings(
            category: 'core',
            count: file_count * 0.2,
            random: random
          ),
          category_bindings: generate_category_bindings(
            categories: %w[typescript go rust python],
            count: file_count * 0.7,
            random: random
          )
        }

        # Add realistic file size distribution
        apply_size_distribution(structure, random)

        # Add realistic modification patterns
        apply_modification_patterns(structure, random)

        structure
      end

      private

      def apply_size_distribution(structure, random)
        # Real-world file sizes follow power law distribution
        # Most files are small, few are large
        structure.values.flatten.each do |file|
          size_category = random.rand(100)
          file[:size] = case size_category
                        when 0..60   then random.rand(1..5)    # KB - 60%
                        when 61..85  then random.rand(5..20)   # KB - 25%
                        when 86..95  then random.rand(20..100) # KB - 10%
                        else              random.rand(100..500) # KB - 5%
                        end
        end
      end

      def apply_modification_patterns(structure, random)
        # Realistic change patterns
        all_files = structure.values.flatten

        # Core files change less frequently
        structure[:tenets].each { |f| f[:change_frequency] = 0.05 }
        structure[:core_bindings].each { |f| f[:change_frequency] = 0.1 }

        # Category bindings change more frequently
        structure[:category_bindings].each do |f|
          f[:change_frequency] = 0.2 + random.rand(0.1)
        end
      end
    end
  end
end
```

### 4. Performance Validation Framework

```ruby
module Leyline
  module Benchmarks
    class PerformanceValidator
      def validate_command_performance(command_class, scenario)
        dataset = TestDataGenerator.new.generate_benchmark_repository(
          file_count: scenario[:file_count]
        )

        results = {
          scenario: scenario[:description],
          measurements: [],
          memory_usage: [],
          cache_metrics: {}
        }

        # Run benchmark with proper isolation
        10.times do |iteration|
          GC.start  # Clean slate for memory measurement

          before_memory = measure_memory_usage
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

          # Execute command
          command = command_class.new(test_options_for_scenario(scenario))
          output = command.execute

          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
          after_memory = measure_memory_usage

          results[:measurements] << end_time - start_time
          results[:memory_usage] << (after_memory - before_memory)

          # Collect cache metrics
          if iteration == 9  # Last run
            results[:cache_metrics] = extract_cache_metrics(output)
          end
        end

        # Validate against targets
        validate_results(results, scenario)
      end

      private

      def validate_results(results, scenario)
        validations = []

        # Response time validation
        avg_time = results[:measurements].sum / results[:measurements].size
        p95_time = results[:measurements].sort[(results[:measurements].size * 0.95).floor]

        validations << {
          metric: 'average_response_time',
          value: avg_time,
          target: scenario[:expected_time],
          passed: avg_time <= scenario[:expected_time]
        }

        validations << {
          metric: 'p95_response_time',
          value: p95_time,
          target: scenario[:expected_time] * 1.2,  # 20% variance allowed
          passed: p95_time <= scenario[:expected_time] * 1.2
        }

        # Memory usage validation
        max_memory = results[:memory_usage].max / 1024.0 / 1024.0  # MB
        validations << {
          metric: 'max_memory_usage_mb',
          value: max_memory,
          target: 50,
          passed: max_memory <= 50
        }

        # Cache hit ratio validation (if applicable)
        if results[:cache_metrics][:hit_ratio]
          validations << {
            metric: 'cache_hit_ratio',
            value: results[:cache_metrics][:hit_ratio],
            target: 0.8,
            passed: results[:cache_metrics][:hit_ratio] >= 0.8
          }
        end

        validations
      end
    end
  end
end
```

### 5. Degradation Testing

```ruby
module Leyline
  module Benchmarks
    class DegradationTests
      FAILURE_SCENARIOS = {
        cache_permission_denied: {
          setup: -> { File.chmod(0000, cache_dir) },
          expected_behavior: :graceful_fallback,
          max_time_penalty: 1.5  # 50% slower max
        },

        disk_full: {
          setup: -> { simulate_disk_full },
          expected_behavior: :continue_readonly,
          max_time_penalty: 1.2
        },

        corrupted_cache_files: {
          setup: -> { corrupt_random_cache_files(0.1) },
          expected_behavior: :auto_repair,
          max_time_penalty: 2.0
        },

        network_timeout: {
          setup: -> { simulate_slow_network(delay: 5000) },
          expected_behavior: :fail_fast,
          max_time_penalty: 1.0  # Should timeout quickly
        }
      }.freeze

      def test_graceful_degradation
        FAILURE_SCENARIOS.each do |scenario_name, config|
          # Baseline performance
          baseline_time = measure_baseline_performance

          # Apply failure condition
          config[:setup].call

          # Measure degraded performance
          degraded_time = measure_degraded_performance

          # Validate behavior
          assert_behavior(config[:expected_behavior])

          # Validate performance degradation is acceptable
          degradation_ratio = degraded_time / baseline_time
          assert degradation_ratio <= config[:max_time_penalty],
            "#{scenario_name} degraded performance by #{degradation_ratio}x, " \
            "expected <= #{config[:max_time_penalty]}x"
        end
      end
    end
  end
end
```

### 6. CI/CD Integration

```yaml
# .github/workflows/performance-benchmarks.yml
name: Performance Benchmarks

on:
  pull_request:
    paths:
      - 'lib/leyline/commands/**'
      - 'lib/leyline/cache/**'
      - 'spec/benchmarks/**'

jobs:
  performance-validation:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup benchmark environment
        run: |
          # Create consistent test environment
          export LEYLINE_BENCHMARK_MODE=true
          export LEYLINE_CACHE_DIR=/tmp/leyline-bench-cache

      - name: Run micro-benchmarks
        run: |
          bundle exec rspec spec/benchmarks/micro_benchmarks_spec.rb \
            --format BenchmarkFormatter \
            --out benchmark-results/micro.json

      - name: Run macro-benchmarks
        run: |
          bundle exec rspec spec/benchmarks/macro_benchmarks_spec.rb \
            --format BenchmarkFormatter \
            --out benchmark-results/macro.json

      - name: Run degradation tests
        run: |
          bundle exec rspec spec/benchmarks/degradation_benchmarks_spec.rb \
            --format BenchmarkFormatter \
            --out benchmark-results/degradation.json

      - name: Compare with baseline
        run: |
          ruby tools/compare_benchmarks.rb \
            --baseline .benchmarks/baseline.json \
            --current benchmark-results/ \
            --threshold 0.1  # 10% regression threshold

      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: benchmark-results/

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const results = require('./benchmark-results/summary.json');
            const comment = generateBenchmarkComment(results);
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### 7. Performance Monitoring Dashboard

```ruby
module Leyline
  module Benchmarks
    class PerformanceDashboard
      def generate_report(benchmark_results)
        report = {
          timestamp: Time.now.iso8601,
          summary: calculate_summary(benchmark_results),
          trends: calculate_trends(benchmark_results),
          alerts: identify_performance_issues(benchmark_results)
        }

        # Generate visualizations
        generate_response_time_chart(benchmark_results)
        generate_memory_usage_chart(benchmark_results)
        generate_cache_hit_ratio_chart(benchmark_results)

        # Output formats
        File.write('performance-report.json', JSON.pretty_generate(report))
        File.write('performance-report.html', generate_html_report(report))

        report
      end

      private

      def identify_performance_issues(results)
        alerts = []

        # Check for performance regressions
        results.each do |command, metrics|
          if metrics[:avg_response_time] > metrics[:target_time]
            alerts << {
              severity: :critical,
              command: command,
              message: "Response time #{metrics[:avg_response_time]}ms exceeds target #{metrics[:target_time]}ms"
            }
          end

          if metrics[:memory_usage_mb] > 50
            alerts << {
              severity: :warning,
              command: command,
              message: "Memory usage #{metrics[:memory_usage_mb]}MB exceeds 50MB limit"
            }
          end

          if metrics[:cache_hit_ratio] && metrics[:cache_hit_ratio] < 0.8
            alerts << {
              severity: :warning,
              command: command,
              message: "Cache hit ratio #{(metrics[:cache_hit_ratio] * 100).round(1)}% below 80% target"
            }
          end
        end

        alerts
      end
    end
  end
end
```

## Implementation Priorities

### Phase 1: Foundation (Week 1)
1. Implement deterministic test data generator
2. Create micro-benchmark framework
3. Set up basic CI integration

### Phase 2: Command Benchmarks (Week 2)
1. Implement status command benchmarks
2. Implement diff command benchmarks
3. Implement update command benchmarks
4. Validate against performance targets

### Phase 3: Advanced Testing (Week 3)
1. Add degradation test scenarios
2. Implement cross-platform testing
3. Create performance monitoring dashboard

### Phase 4: Optimization (Week 4)
1. Profile and optimize bottlenecks identified
2. Implement performance regression prevention
3. Document performance best practices

## Success Metrics

1. **All transparency commands meet <2s target** for 1000+ files
2. **Cache hit ratio consistently >80%** in warm cache scenarios
3. **Memory usage stays under 50MB** even with 5000+ files
4. **Graceful degradation** - no crashes, clear errors
5. **Deterministic results** - <5% variance between runs
6. **CI integration** - automated performance validation on every commit

## Key Insights

The most important aspect of performance benchmarking is not achieving impressive numbers in ideal conditions, but ensuring consistent, reliable performance in the messy reality of production. This architecture provides:

1. **Realistic Testing** - Uses file size distributions and modification patterns from actual repositories
2. **Deterministic Results** - Same inputs always produce comparable outputs
3. **Granular Insights** - Identifies specific bottlenecks, not just overall slowness
4. **Continuous Validation** - Performance is verified on every change
5. **Graceful Degradation** - Validates behavior under failure conditions

Remember: Users don't care about your architecture's elegance if the tool is slow when they need it. Make it fast, keep it fast, and know when it's getting slower.

*"Premature optimization is the root of all evil, but mature optimization is the fruit of all good engineering."*
