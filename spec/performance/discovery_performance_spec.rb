# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'benchmark'

RSpec.describe 'Discovery command performance regression tests', :performance do
  let(:temp_test_dir) { Dir.mktmpdir('leyline-discovery-perf') }
  let(:file_cache) { Leyline::Cache::FileCache.new(File.join(temp_test_dir, 'cache')) }
  let(:metadata_cache) { Leyline::Discovery::MetadataCache.new(file_cache: file_cache) }

  # Performance thresholds based on <1s target
  let(:performance_targets) do
    {
      categories_command: 1.0,      # <1s for categories listing
      show_command: 1.0,            # <1s for category document listing
      search_command: 1.0,          # <1s for search operations
      fuzzy_search: 1.0,            # <1s for fuzzy search with typos
      cache_warm_up: 2.0,           # <2s for initial cache population
      suggestion_generation: 0.5    # <0.5s for "Did you mean?" suggestions
    }
  end

  before do
    # Create comprehensive test dataset
    setup_discovery_test_dataset
  end

  after do
    FileUtils.rm_rf(temp_test_dir) if Dir.exist?(temp_test_dir)
  end

  describe 'Categories command performance' do
    it 'meets <1s performance target for categories listing' do
      # Warm up cache first
      metadata_cache.categories

      # Benchmark categories command performance
      elapsed_time = Benchmark.realtime do
        10.times { metadata_cache.categories }
      end

      avg_time = elapsed_time / 10.0
      expect(avg_time).to be < performance_targets[:categories_command],
                        "Categories command took #{avg_time}s, target: <#{performance_targets[:categories_command]}s"

      puts "Categories performance: #{(avg_time * 1000).round(1)}ms per operation"
    end

    it 'scales linearly with document count' do
      document_counts = [50, 100, 200, 500]
      results = []

      document_counts.each do |count|
        cleanup_and_setup_dataset(document_count: count)

        elapsed_time = Benchmark.realtime do
          metadata_cache.categories
        end

        results << { documents: count, time: elapsed_time }
      end

      # Log scalability results
      puts "\nCategories Scalability:"
      results.each do |result|
        puts "  #{result[:documents]} documents: #{(result[:time] * 1000).round(1)}ms"
      end

      # Ensure largest dataset still meets performance target
      largest_test = results.last
      expect(largest_test[:time]).to be < performance_targets[:categories_command],
                                     "Categories with #{largest_test[:documents]} documents took #{largest_test[:time]}s"
    end
  end

  describe 'Show command performance' do
    it 'meets <1s performance target for category document listing' do
      # Warm up cache and get a test category
      categories = metadata_cache.categories
      test_category = categories.first

      elapsed_time = Benchmark.realtime do
        10.times { metadata_cache.documents_for_category(test_category) }
      end

      avg_time = elapsed_time / 10.0
      expect(avg_time).to be < performance_targets[:show_command],
                        "Show command took #{avg_time}s, target: <#{performance_targets[:show_command]}s"

      puts "Show performance: #{(avg_time * 1000).round(1)}ms per operation"
    end

    it 'handles categories with varying document counts efficiently' do
      # Test performance across different category sizes
      category_sizes = [10, 25, 50, 100]

      category_sizes.each do |size|
        category_name = "perf_test_#{size}"

        # Create category with specific document count
        size.times do |i|
          doc = create_test_document(
            id: "#{category_name}-#{i}",
            title: "Document #{i} in #{category_name}",
            category: category_name
          )
          metadata_cache.cache_document(doc)
        end

        elapsed_time = Benchmark.realtime do
          metadata_cache.documents_for_category(category_name)
        end

        expect(elapsed_time).to be < performance_targets[:show_command],
                               "Show command for #{size} documents took #{elapsed_time}s"

        puts "Show #{size} documents: #{(elapsed_time * 1000).round(1)}ms"
      end
    end
  end

  describe 'Search command performance' do
    it 'meets <1s performance target for exact search operations' do
      search_queries = ['testing', 'performance', 'binding', 'cache', 'configuration']

      search_queries.each do |query|
        elapsed_time = Benchmark.realtime do
          5.times { metadata_cache.search(query) }
        end

        avg_time = elapsed_time / 5.0
        expect(avg_time).to be < performance_targets[:search_command],
                          "Search '#{query}' took #{avg_time}s, target: <#{performance_targets[:search_command]}s"
      end

      puts "Exact search performance: meets <1s target for all queries"
    end

    it 'meets <1s performance target for fuzzy search with typos' do
      fuzzy_queries = ['tesitng', 'perfromance', 'bindng', 'cachng', 'configuraton']

      fuzzy_queries.each do |query|
        elapsed_time = Benchmark.realtime do
          3.times { metadata_cache.search(query) }
        end

        avg_time = elapsed_time / 3.0
        expect(avg_time).to be < performance_targets[:fuzzy_search],
                          "Fuzzy search '#{query}' took #{avg_time}s, target: <#{performance_targets[:fuzzy_search]}s"
      end

      puts "Fuzzy search performance: meets <1s target for typo-tolerant queries"
    end

    it 'maintains performance with large result sets' do
      # Create many documents that will match a broad query
      100.times do |i|
        doc = create_test_document(
          id: "broad-match-#{i}",
          title: "Test Document #{i} about testing methodologies",
          category: 'testing'
        )
        metadata_cache.cache_document(doc)
      end

      elapsed_time = Benchmark.realtime do
        results = metadata_cache.search('test')
        expect(results.length).to be > 50  # Should match many documents
      end

      expect(elapsed_time).to be < performance_targets[:search_command],
                             "Search with large result set took #{elapsed_time}s"

      puts "Large result set search: #{(elapsed_time * 1000).round(1)}ms"
    end
  end

  describe 'Suggestion generation performance' do
    it 'meets <0.5s performance target for \"Did you mean?\" suggestions' do
      failed_queries = ['tesng', 'perfrmance', 'cachng', 'bindng']

      failed_queries.each do |query|
        elapsed_time = Benchmark.realtime do
          suggestions = metadata_cache.suggest_corrections(query)
          expect(suggestions).to be_an(Array)  # Should return suggestions
        end

        expect(elapsed_time).to be < performance_targets[:suggestion_generation],
                               "Suggestion generation for '#{query}' took #{elapsed_time}s"
      end

      puts "Suggestion generation: meets <0.5s target for all failed queries"
    end

    it 'scales reasonably with vocabulary size' do
      # Add more documents to increase suggestion vocabulary
      vocab_sizes = [100, 250, 500]

      vocab_sizes.each do |size|
        # Clear cache and add specific number of documents
        metadata_cache.invalidate!

        size.times do |i|
          doc = create_test_document(
            id: "vocab-#{i}",
            title: "#{generate_random_title(i)} Document #{i}",
            category: 'vocabulary_test'
          )
          metadata_cache.cache_document(doc)
        end

        elapsed_time = Benchmark.realtime do
          metadata_cache.suggest_corrections('tesng')
        end

        expect(elapsed_time).to be < performance_targets[:suggestion_generation],
                               "Suggestions with #{size} documents took #{elapsed_time}s"

        puts "Suggestions (#{size} docs): #{(elapsed_time * 1000).round(1)}ms"
      end
    end
  end

  describe 'Cache warm-up performance' do
    it 'meets <2s performance target for cache population' do
      # Start with empty cache
      metadata_cache.invalidate!

      elapsed_time = Benchmark.realtime do
        # Force cache population by accessing data
        metadata_cache.categories
        metadata_cache.search('test')
      end

      expect(elapsed_time).to be < performance_targets[:cache_warm_up],
                             "Cache warm-up took #{elapsed_time}s, target: <#{performance_targets[:cache_warm_up]}s"

      puts "Cache warm-up: #{(elapsed_time * 1000).round(1)}ms"
    end

    it 'demonstrates significant performance improvement after warm-up' do
      # Cold cache timing
      metadata_cache.invalidate!
      cold_time = Benchmark.realtime do
        metadata_cache.categories
        metadata_cache.search('performance')
      end

      # Warm cache timing (same operations)
      warm_time = Benchmark.realtime do
        metadata_cache.categories
        metadata_cache.search('performance')
      end

      improvement_ratio = (cold_time - warm_time) / cold_time
      puts "Cache performance improvement: #{(improvement_ratio * 100).round(1)}%"

      # Warm cache should be faster and meet performance targets
      expect(warm_time).to be < cold_time  # Some improvement expected
      expect(warm_time).to be < performance_targets[:search_command]

      # Performance improvement should be meaningful (at least 10% or meets target)
      expect(improvement_ratio > 0.1 || warm_time < 0.5).to be(true)
    end
  end

  describe 'Discovery operation microsecond telemetry' do
    it 'provides detailed timing metrics for all operations' do
      # Execute various operations to populate timing data
      metadata_cache.categories
      metadata_cache.documents_for_category('testing')
      metadata_cache.search('test')
      metadata_cache.search('fuzzy')

      stats = metadata_cache.performance_stats

      # Verify microsecond precision metrics are available
      expect(stats[:operation_metrics]).to be_a(Hash)
      expect(stats[:operation_metrics]).to have_key(:list_categories)
      expect(stats[:operation_metrics]).to have_key(:show_category)
      expect(stats[:operation_metrics]).to have_key(:search_content)

      # Verify all operations meet performance targets
      stats[:operation_metrics].each do |operation, metrics|
        avg_time_ms = metrics[:avg_time_ms]
        expect(avg_time_ms).to be < 1000.0, "#{operation} averaged #{avg_time_ms}ms, target: <1000ms"
      end

      # Verify performance summary indicates targets are met
      expect(stats[:performance_summary][:performance_target_met]).to be(true)

      puts "Microsecond telemetry: All operations meet <1s performance targets"
    end
  end

  describe 'Regression protection' do
    it 'prevents performance degradation in key operations' do
      # This test serves as a regression guard by setting strict performance expectations
      operations = {
        categories: -> { metadata_cache.categories },
        show: -> { metadata_cache.documents_for_category('testing') },
        exact_search: -> { metadata_cache.search('test') },
        fuzzy_search: -> { metadata_cache.search('tesitng') },
        suggestions: -> { metadata_cache.suggest_corrections('tesng') }
      }

      regression_thresholds = {
        categories: 0.1,      # 100ms for categories
        show: 0.1,           # 100ms for show
        exact_search: 0.2,   # 200ms for exact search
        fuzzy_search: 0.5,   # 500ms for fuzzy search
        suggestions: 0.3     # 300ms for suggestions
      }

      operations.each do |operation_name, operation|
        elapsed_time = Benchmark.realtime { operation.call }
        threshold = regression_thresholds[operation_name]

        expect(elapsed_time).to be < threshold,
                               "REGRESSION: #{operation_name} took #{elapsed_time}s, threshold: #{threshold}s"
      end

      puts "Regression protection: All operations within strict performance bounds"
    end
  end

  private

  def setup_discovery_test_dataset(document_count: 100)
    categories = ['testing', 'performance', 'caching', 'binding', 'configuration']

    document_count.times do |i|
      category = categories[i % categories.length]
      doc = create_test_document(
        id: "test-doc-#{i}",
        title: "#{category.capitalize} Document #{i}",
        category: category
      )
      metadata_cache.cache_document(doc)
    end
  end

  def cleanup_and_setup_dataset(document_count:)
    metadata_cache.invalidate!
    setup_discovery_test_dataset(document_count: document_count)
  end

  def create_test_document(id:, title:, category:)
    {
      id: id,
      title: title,
      path: "/test/#{id}.md",
      category: category,
      type: 'binding',
      metadata: { 'category' => category },
      content_preview: "Comprehensive content for #{title} covering best practices and implementation details.",
      content_hash: "hash-#{id}",
      size: title.length * 20,
      modified_time: Time.now,
      scan_time: Time.now
    }
  end

  def generate_random_title(seed)
    words = ['Advanced', 'Modern', 'Comprehensive', 'Effective', 'Efficient', 'Optimal']
    topics = ['Testing', 'Performance', 'Architecture', 'Design', 'Implementation', 'Strategy']

    Random.srand(seed)
    "#{words.sample} #{topics.sample}"
  end
end
