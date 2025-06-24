# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/benchmark_helpers'

RSpec.describe 'Discovery Performance Validation', type: :integration do
  include BenchmarkHelpers
  # This is a simplified performance validation that can be run in CI
  # to ensure the <1s performance target is maintained over time

  describe 'real-world performance validation' do
    let(:cache) { Leyline::Discovery::MetadataCache.new(compression_enabled: true) }

    it 'validates <1s performance target for all discovery commands' do
      # Test with real repository content
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      # Categories command
      categories = cache.categories
      categories_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time

      expect(categories).to be_an(Array)
      expect(categories_time).to be < TARGET_PERFORMANCE_MS,
        "Categories command took #{categories_time}ms, exceeds #{TARGET_PERFORMANCE_MS}ms target"

      # Show command (test first category if available)
      if categories.any?
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        documents = cache.documents_for_category(categories.first)
        show_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time

        expect(documents).to be_an(Array)
        expect(show_time).to be < TARGET_PERFORMANCE_MS,
          "Show command took #{show_time}ms, exceeds #{TARGET_PERFORMANCE_MS}ms target"
      end

      # Search command
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      results = cache.search('test')
      search_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time

      expect(results).to be_an(Array)
      expect(search_time).to be < TARGET_PERFORMANCE_MS,
        "Search command took #{search_time}ms, exceeds #{TARGET_PERFORMANCE_MS}ms target"

      # Log performance for CI monitoring
      puts "\n[PERFORMANCE VALIDATION] All targets met:"
      puts "  Categories: #{categories_time}ms (target: <#{TARGET_PERFORMANCE_MS}ms)"
      puts "  Show: #{show_time}ms (target: <#{TARGET_PERFORMANCE_MS}ms)" if categories.any?
      puts "  Search: #{search_time}ms (target: <#{TARGET_PERFORMANCE_MS}ms)"
    end

    it 'validates cache infrastructure performance' do
      # Ensure cache operations don't degrade performance
      stats = cache.performance_stats

      expect(stats).to include(:hit_ratio, :memory_usage, :document_count)
      expect(stats[:document_count]).to be >= 0
      expect(stats[:memory_usage]).to be >= 0

      # Verify compression stats if enabled
      if cache.compression_enabled?
        compression_stats = stats[:compression_stats]
        expect(compression_stats[:enabled]).to be true
        expect(compression_stats[:compression_ratio]).to be_a(Numeric)
      end
    end
  end
end
