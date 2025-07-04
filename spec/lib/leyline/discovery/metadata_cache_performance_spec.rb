# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Leyline::Discovery::MetadataCache, '#performance_telemetry' do
  let(:temp_dir) { Dir.mktmpdir('metadata-cache-perf-test') }
  let(:cache) { described_class.new }

  before do
    # Create test document structure
    setup_test_documents
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe 'microsecond precision timing' do
    it 'tracks operation timing with microsecond precision' do
      # Force cache to scan our test documents
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      # Execute operations to generate timing data
      cache.categories
      cache.documents_for_category('typescript')
      cache.search('test')

      # Get performance stats
      stats = cache.performance_stats

      # Verify operation metrics exist
      expect(stats[:operation_metrics]).to be_a(Hash)
      expect(stats[:operation_metrics]).to have_key(:list_categories)
      expect(stats[:operation_metrics]).to have_key(:show_category)
      expect(stats[:operation_metrics]).to have_key(:search_content)

      # Verify timing precision and data structure
      list_stats = stats[:operation_metrics][:list_categories]
      expect(list_stats[:count]).to eq(1)
      expect(list_stats[:avg_time_us]).to be > 0
      expect(list_stats[:avg_time_us]).to be_a(Float)
      expect(list_stats[:min_time_us]).to be > 0
      expect(list_stats[:max_time_us]).to be > 0
      expect(list_stats[:recent_timings]).to be_an(Array)
      expect(list_stats[:recent_timings].size).to eq(1)

      # Verify performance summary
      expect(stats[:performance_summary]).to be_a(Hash)
      expect(stats[:performance_summary][:total_discovery_operations]).to eq(3)
      expect(stats[:performance_summary][:performance_target_met]).to be true
    end

    it 'maintains performance target of <1 second per operation' do
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      # Execute operations multiple times
      5.times do
        cache.categories
        cache.documents_for_category('typescript')
        cache.search('test')
      end

      stats = cache.performance_stats

      # Verify all operations meet performance target
      stats[:operation_metrics].each do |operation, metrics|
        avg_time_ms = metrics[:avg_time_ms]
        expect(avg_time_ms).to be < 1000,
                               "Operation #{operation} took #{avg_time_ms}ms, target: <1000ms"
      end

      expect(stats[:performance_summary][:performance_target_met]).to be true
    end

    it 'tracks multiple operations with separate timing' do
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      # Execute different numbers of each operation
      3.times { cache.categories }
      2.times { cache.documents_for_category('typescript') }
      1.times { cache.search('test') }

      stats = cache.performance_stats

      # Verify operation counts
      expect(stats[:operation_metrics][:list_categories][:count]).to eq(3)
      expect(stats[:operation_metrics][:show_category][:count]).to eq(2)
      expect(stats[:operation_metrics][:search_content][:count]).to eq(1)

      # Verify total operations
      expect(stats[:performance_summary][:total_discovery_operations]).to eq(6)
    end

    it 'maintains memory efficiency with bounded timing history' do
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      # Execute many operations (more than the 100-item limit)
      150.times { cache.categories }

      stats = cache.performance_stats
      list_stats = stats[:operation_metrics][:list_categories]

      # Verify timing history is bounded
      expect(list_stats[:recent_timings].size).to be <= 100
      expect(list_stats[:count]).to eq(150) # But count should be accurate

      # Verify recent timings contains timing data (some may be 0 for very fast operations)
      expect(list_stats[:recent_timings]).to all(be >= 0)
      expect(list_stats[:recent_timings].sum).to be > 0 # At least some operations should take time
    end
  end

  describe 'integration with existing performance stats' do
    it 'preserves existing cache statistics' do
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      cache.categories
      stats = cache.performance_stats

      # Verify existing stats are still present
      expect(stats).to have_key(:hit_ratio)
      expect(stats).to have_key(:memory_usage)
      expect(stats).to have_key(:document_count)
      expect(stats).to have_key(:category_count)
      expect(stats).to have_key(:scan_count)
      expect(stats).to have_key(:last_scan)

      # Verify new telemetry is added
      expect(stats).to have_key(:operation_metrics)
      expect(stats).to have_key(:performance_summary)
    end

    it 'integrates with cache hit/miss tracking' do
      allow(cache).to receive(:discover_document_paths).and_return(test_document_paths)

      # Call categories twice - the first will trigger a scan, second won't
      cache.categories
      cache.categories

      stats = cache.performance_stats

      # Verify timing statistics work alongside existing cache infrastructure
      expect(stats[:operation_metrics][:list_categories][:count]).to eq(2)
      expect(stats[:scan_count]).to eq(1) # Only one scan should have occurred
      expect(stats[:document_count]).to be > 0 # Documents should be cached
    end
  end

  private

  def setup_test_documents
    # Create test directory structure
    FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'tenets'))
    FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'bindings', 'core'))
    FileUtils.mkdir_p(File.join(temp_dir, 'docs', 'bindings', 'categories', 'typescript'))

    # Create test documents
    create_test_document(
      File.join(temp_dir, 'docs', 'tenets', 'simplicity.md'),
      'simplicity',
      'Simplicity Above All',
      'Prefer the simplest design that solves the problem completely.'
    )

    create_test_document(
      File.join(temp_dir, 'docs', 'bindings', 'categories', 'typescript', 'no-any.md'),
      'no-any',
      'Avoid the Any Type',
      'Never use the any type in TypeScript code.'
    )
  end

  def create_test_document(path, id, title, content)
    File.write(path, <<~MARKDOWN)
      ---
      id: #{id}
      last_modified: '2025-01-01'
      version: '0.1.0'
      ---

      # #{title}

      #{content}

      Additional content for testing search functionality.
    MARKDOWN
  end

  def test_document_paths
    [
      File.join(temp_dir, 'docs', 'tenets', 'simplicity.md'),
      File.join(temp_dir, 'docs', 'bindings', 'categories', 'typescript', 'no-any.md')
    ]
  end
end
