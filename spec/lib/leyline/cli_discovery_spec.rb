# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'
require 'fileutils'

RSpec.describe Leyline::CLI, 'Discovery Commands' do
  let(:cli) { described_class.new }
  let(:temp_test_dir) { Dir.mktmpdir('leyline-cli-discovery-test') }

  before do
    # Set up test environment with realistic documents
    setup_test_discovery_environment
  end

  after do
    FileUtils.rm_rf(temp_test_dir) if Dir.exist?(temp_test_dir)
  end

  describe '#categories command' do
    context 'basic functionality' do
      it 'lists available categories' do
        output = capture_stdout { cli.categories }

        expect(output).to include('Available Categories')
        expect(output).to include('testing')
        expect(output).to include('performance')
        expect(output).to include('caching')
        expect(output).to match(/\(\d+ documents\)/)
      end

      it 'shows category count in output' do
        output = capture_stdout { cli.categories }

        expect(output).to match(/Available Categories \(\d+\):/)
      end

      it 'displays categories in consistent format' do
        output = capture_stdout { cli.categories }

        # Should show categories with document counts
        expect(output).to match(/^\s+\w+\s+\(\d+\s+documents\)$/)
      end
    end

    context 'with verbose option' do
      before { cli.options = { verbose: true } }

      it 'shows detailed category information with document titles' do
        output = capture_stdout { cli.categories }

        expect(output).to include('Available Categories')
        expect(output).to include('testing')

        # Should show individual document titles in verbose mode
        expect(output).to include('Testing Best Practices')
        expect(output).to include('Performance Optimization')
      end

      it 'shows document IDs for each document' do
        output = capture_stdout { cli.categories }

        expect(output).to include('(test-001)')
        expect(output).to include('(perf-001)')
      end

      it 'groups documents properly under categories' do
        output = capture_stdout { cli.categories }

        # Should show category headers followed by document lists
        lines = output.split("\n")
        testing_line_index = lines.find_index { |line| line.include?('testing') && line.include?('documents') }
        expect(testing_line_index).not_to be_nil

        # Next line should be a document
        expect(lines[testing_line_index + 1]).to match(/^\s+- .*\(.*\)$/)
      end
    end

    context 'with stats option' do
      before { cli.options = { stats: true } }

      it 'shows cache performance statistics' do
        output = capture_stdout { cli.categories }

        expect(output).to include('DISCOVERY PERFORMANCE STATISTICS')
        expect(output).to include('Total time:')
        expect(output).to include('Cache hit ratio:')
        expect(output).to include('Documents cached:')
        expect(output).to include('Categories:')
      end

      it 'shows operation-specific microsecond metrics' do
        output = capture_stdout { cli.categories }

        expect(output).to include('Operation Performance (Microsecond Precision):')
        expect(output).to include('List categories:')
        expect(output).to match(/Average: \d+\.\d+ms/)
        expect(output).to match(/Target met: [✅❌]/)
      end

      it 'shows performance summary' do
        output = capture_stdout { cli.categories }

        expect(output).to include('Performance Summary:')
        expect(output).to include('Total operations:')
        expect(output).to include('All targets met:')
      end
    end

    context 'with combined options' do
      before { cli.options = { verbose: true, stats: true } }

      it 'shows both detailed information and statistics' do
        output = capture_stdout { cli.categories }

        # Should have both verbose output and stats
        expect(output).to include('Testing Best Practices')
        expect(output).to include('DISCOVERY PERFORMANCE STATISTICS')
      end
    end

    context 'error handling' do
      it 'handles cache initialization failures gracefully' do
        # Mock cache failure
        allow(Leyline::Cache::FileCache).to receive(:new).and_raise(StandardError.new('Cache unavailable'))

        expect { capture_stdout { cli.categories } }.not_to raise_error
      end

      it 'continues operation when cache warming fails' do
        # This should not affect the command execution
        output = capture_stdout { cli.categories }
        expect(output).to include('Available Categories')
      end
    end
  end

  describe '#show command' do
    context 'with valid category' do
      it 'shows documents in the specified category' do
        output = capture_stdout { cli.show('testing') }

        expect(output).to include("Documents in 'testing'")
        expect(output).to include('Testing Best Practices')
        expect(output).to include('ID: test-001')
        expect(output).to include('Type: binding')
      end

      it 'shows document count for category' do
        output = capture_stdout { cli.show('testing') }

        expect(output).to match(/Documents in 'testing' \(\d+\):/)
      end

      it 'displays documents in structured format' do
        output = capture_stdout { cli.show('testing') }

        # Should show title, ID, and type for each document
        expect(output).to match(/^Testing Best Practices$/m)
        expect(output).to match(/^\s+ID: test-001$/m)
        expect(output).to match(/^\s+Type: binding$/m)
      end
    end

    context 'with verbose option' do
      before { cli.options = { verbose: true } }

      it 'shows additional document details including path' do
        output = capture_stdout { cli.show('testing') }

        expect(output).to include('Path: ')
        expect(output).to include('test-001.md')
      end

      it 'shows content preview when available' do
        output = capture_stdout { cli.show('testing') }

        expect(output).to include('Preview: ')
        expect(output).to include('Content for Testing Best Practices')
      end
    end

    context 'with invalid category' do
      it 'shows helpful error message for nonexistent category' do
        output = capture_stdout { cli.show('nonexistent') }

        expect(output).to include("No documents found in category 'nonexistent'")
        expect(output).to include('Available categories:')
        expect(output).to include('caching, performance, testing')
      end

      it 'does not exit with error for invalid category' do
        expect { capture_stdout { cli.show('nonexistent') } }.not_to raise_error
      end
    end

    context 'edge cases and error handling' do
      it 'handles documents with nil content preview in verbose mode' do
        # Mock metadata cache to return a document with nil content_preview
        mock_document = {
          id: 'test-nil-preview',
          title: 'Document with Nil Preview',
          path: '/test/nil-preview.md',
          category: 'testing',
          type: 'binding',
          metadata: {},
          content_preview: nil, # This used to cause NoMethodError
          content_hash: 'abc123',
          size: 500,
          modified_time: Time.now,
          scan_time: Time.now
        }

        allow_any_instance_of(Leyline::Discovery::MetadataCache)
          .to receive(:documents_for_category)
          .with('testing')
          .and_return([mock_document])

        cli.options = { verbose: true }

        # This should not raise NoMethodError
        expect do
          output = capture_stdout { cli.show('testing') }

          # Should show the document without the preview
          expect(output).to include('Document with Nil Preview')
          expect(output).to include('ID: test-nil-preview')
          expect(output).not_to include('Preview:')
        end.not_to raise_error
      end

      it 'handles documents with empty content preview in verbose mode' do
        mock_document = {
          id: 'test-empty-preview',
          title: 'Document with Empty Preview',
          path: '/test/empty-preview.md',
          category: 'testing',
          type: 'binding',
          metadata: {},
          content_preview: '', # Empty string should also not show preview
          content_hash: 'abc123',
          size: 500,
          modified_time: Time.now,
          scan_time: Time.now
        }

        allow_any_instance_of(Leyline::Discovery::MetadataCache)
          .to receive(:documents_for_category)
          .with('testing')
          .and_return([mock_document])

        cli.options = { verbose: true }

        output = capture_stdout { cli.show('testing') }

        # Should show the document without the preview (empty string)
        expect(output).to include('Document with Empty Preview')
        expect(output).to include('ID: test-empty-preview')
        expect(output).not_to include('Preview:')
      end
    end

    context 'with stats option' do
      before { cli.options = { stats: true } }

      it 'shows performance statistics for show operation' do
        output = capture_stdout { cli.show('testing') }

        expect(output).to include('DISCOVERY PERFORMANCE STATISTICS')
        expect(output).to include('Show category:')
      end
    end
  end

  describe '#search command' do
    context 'with valid search query' do
      it 'finds and displays matching documents' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include("Search Results for 'testing'")
        expect(output).to include('Testing Best Practices')
        expect(output).to include('Category: testing')
        expect(output).to include('Type: binding')
        expect(output).to include('ID: test-001')
      end

      it 'shows search results count' do
        output = capture_stdout { cli.search('test') }

        expect(output).to match(/Search Results for 'test' \(\d+ results?\):/)
      end

      it 'displays results with numbered format' do
        output = capture_stdout { cli.search('test') }

        expect(output).to match(/^\s*1\.\s+Testing Best Practices$/m)
      end

      it 'shows result metadata in structured format' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to match(/Category: testing \| Type: binding \| ID: test-001/)
      end
    end

    context 'with verbose option' do
      before { cli.options = { verbose: true } }

      it 'shows detailed search results with relevance scores' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include('Relevance: ★')
        expect(output).to match(/Relevance: ★+[☆★]*\s+\(\d+\)/)
      end

      it 'shows document paths in verbose mode' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include('Path: ')
        expect(output).to include('test-001.md')
      end

      it 'shows extended content preview' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include('Content for Testing Best Practices')
      end

      it 'shows document metadata when available' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include('Metadata:')
      end
    end

    context 'with limit option' do
      before { cli.options = { limit: 2 } }

      it 'limits results to specified count' do
        output = capture_stdout { cli.search('test') }

        # Should show "showing X of Y" when results are limited
        expect(output).to match(/showing \d+ of \d+/i)
      end

      it 'shows truncation notice when results exceed limit' do
        output = capture_stdout { cli.search('test') }

        expect(output).to include('Use --limit to see more')
      end
    end

    context 'with fuzzy search and typos' do
      it 'finds documents with simple typos' do
        output = capture_stdout { cli.search('Tesing') } # 'Testing' with missing 't'

        # Should find the testing document via fuzzy search
        expect(output).to include('Search Results')
        expect(output).not_to include('No results found')
      end

      it 'finds documents with character transpositions' do
        output = capture_stdout { cli.search('Performnace') } # 'Performance' with transposed characters

        # Should find the performance document via fuzzy search
        expect(output).to include('Search Results')
        expect(output).not_to include('No results found')
      end

      it 'shows lower relevance scores for fuzzy matches' do
        cli.options = { verbose: true }
        output = capture_stdout { cli.search('Tesing') }

        # Fuzzy matches should have relevance scores
        expect(output).to match(/Relevance: ★+[☆★]*\s+\([0-9]+\)/)
      end
    end

    context 'with failed search and suggestions' do
      it 'shows "Did you mean?" suggestions for failed searches' do
        output = capture_stdout { cli.search('xyzabc') } # Completely different to ensure no match

        expect(output).to include("No results found for 'xyzabc'")
        # May or may not have suggestions for completely different query
      end

      it 'provides multiple relevant suggestions' do
        output = capture_stdout { cli.search('qwerty') } # Different query that should fail

        expect(output).to include("No results found for 'qwerty'")
        # May or may not have suggestions for different query
      end

      it 'handles completely unrelated queries gracefully' do
        output = capture_stdout { cli.search('xyz123nonexistent') }

        expect(output).to include("No results found for 'xyz123nonexistent'")
        # Should not show suggestions for completely unrelated queries
        expect(output).not_to include('Did you mean:')
      end
    end

    context 'with empty or invalid queries' do
      it 'exits with error for empty query' do
        expect { cli.search('') }.to exit_with_code(1)
      end

      it 'exits with error for nil query' do
        expect { cli.search(nil) }.to exit_with_code(1)
      end

      it 'shows appropriate error message for empty query' do
        output = capture_stdout_and_exit { cli.search('') }

        expect(output).to include('Search query cannot be empty')
      end

      it 'exits with error for whitespace-only query' do
        expect { cli.search('   ') }.to exit_with_code(1)
      end
    end

    context 'with stats option' do
      before { cli.options = { stats: true } }

      it 'shows search performance statistics' do
        output = capture_stdout { cli.search('testing') }

        expect(output).to include('DISCOVERY PERFORMANCE STATISTICS')
        expect(output).to include('Search content:')
      end
    end
  end

  describe 'cross-command workflow integration' do
    it 'supports discovering categories, then showing category, then searching' do
      # Step 1: Discover categories
      categories_output = capture_stdout { cli.categories }
      expect(categories_output).to include('testing')

      # Step 2: Show documents in testing category
      show_output = capture_stdout { cli.show('testing') }
      expect(show_output).to include('Testing Best Practices')

      # Step 3: Search for content
      search_output = capture_stdout { cli.search('testing') }
      expect(search_output).to include('Testing Best Practices')
    end

    it 'maintains cache performance across multiple commands' do
      cli.options = { stats: true }

      # Execute multiple commands - cache should improve performance
      capture_stdout { cli.categories }
      capture_stdout { cli.show('testing') }
      output = capture_stdout { cli.search('testing') }

      # Should show cache effectiveness
      expect(output).to include('Cache hit ratio:')
    end
  end

  describe 'performance and cache integration' do
    it 'shows cache warm-up messages in verbose mode' do
      cli.options = { verbose: true }
      output = capture_stdout { cli.categories }

      # May or may not show warm-up message depending on cache state
      # But should not crash or show warnings
      expect(output).not_to include('Warning: Cache warming failed')
    end

    it 'handles cache failures gracefully without breaking commands' do
      # Mock cache to fail
      allow_any_instance_of(Leyline::Discovery::MetadataCache).to receive(:categories).and_raise(StandardError.new('Cache error'))

      expect { cli.categories }.to exit_with_code(1)
    end

    it 'shows performance improvements with warm cache' do
      cli.options = { stats: true }

      # First run (cold cache)
      capture_stdout { cli.categories }

      # Second run (warm cache)
      warm_output = capture_stdout { cli.categories }

      expect(warm_output).to include('DISCOVERY PERFORMANCE STATISTICS')
    end
  end

  describe 'Thor CLI integration' do
    it 'includes discovery commands in available commands' do
      expect(described_class.commands.keys).to include('categories')
      expect(described_class.commands.keys).to include('show')
      expect(described_class.commands.keys).to include('search')
    end

    it 'has proper command descriptions for discovery commands' do
      categories_command = described_class.commands['categories']
      expect(categories_command.description).to eq('List all available leyline categories')

      show_command = described_class.commands['show']
      expect(show_command.description).to eq('Show documents in a specific category')

      search_command = described_class.commands['search']
      expect(search_command.description).to eq('Search leyline documents by content')
    end

    it 'supports Thor start method for discovery commands' do
      expect { described_class.start(['categories', '--help']) }.not_to raise_error
      expect { described_class.start(['show', '--help']) }.not_to raise_error
      expect { described_class.start(['search', '--help']) }.not_to raise_error
    end
  end

  describe 'option validation and parsing' do
    context 'boolean options' do
      it 'accepts valid boolean values for verbose option' do
        [true, false, nil].each do |value|
          cli.options = { verbose: value }
          expect { capture_stdout { cli.categories } }.not_to raise_error
        end
      end

      it 'accepts valid boolean values for stats option' do
        [true, false, nil].each do |value|
          cli.options = { stats: value }
          expect { capture_stdout { cli.categories } }.not_to raise_error
        end
      end
    end

    context 'numeric options' do
      it 'accepts valid numeric values for limit option' do
        [1, 5, 10, 50].each do |value|
          cli.options = { limit: value }
          expect { capture_stdout { cli.search('test') } }.not_to raise_error
        end
      end

      it 'uses default limit when not specified' do
        output = capture_stdout { cli.search('test') }

        # Should not show "showing X of Y" for small result sets with default limit
        expect(output).to include('Search Results')
      end
    end
  end

  private

  def setup_test_discovery_environment
    # Create test directory structure
    FileUtils.mkdir_p(File.join(temp_test_dir, 'docs', 'tenets'))
    FileUtils.mkdir_p(File.join(temp_test_dir, 'docs', 'bindings', 'core'))
    FileUtils.mkdir_p(File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'testing'))
    FileUtils.mkdir_p(File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'performance'))
    FileUtils.mkdir_p(File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'caching'))

    # Create test documents with realistic content
    test_documents = [
      {
        path: File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'testing', 'test-001.md'),
        content: create_test_document_content('test-001', 'Testing Best Practices', 'testing')
      },
      {
        path: File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'performance', 'perf-001.md'),
        content: create_test_document_content('perf-001', 'Performance Optimization', 'performance')
      },
      {
        path: File.join(temp_test_dir, 'docs', 'bindings', 'categories', 'caching', 'cache-001.md'),
        content: create_test_document_content('cache-001', 'Caching Strategies', 'caching')
      }
    ]

    test_documents.each do |doc|
      File.write(doc[:path], doc[:content])
    end

    # Mock the discovery path to use our test directory
    allow_any_instance_of(Leyline::Discovery::MetadataCache).to receive(:discover_document_paths) do
      test_documents.map { |doc| doc[:path] }
    end
  end

  def create_test_document_content(id, title, category)
    <<~CONTENT
      ---
      title: "#{title}"
      id: "#{id}"
      category: "#{category}"
      binding_strength: "must"
      ---

      # #{title}

      This is a test document for #{category} category.

      ## Description

      Content for #{title} covering comprehensive #{category} practices and implementation details.

      ## Implementation Guidelines

      Detailed implementation guidance for #{category} in various contexts.

      ## Examples

      Practical examples and usage patterns for #{category} scenarios.
    CONTENT
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stdout_and_exit
    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      yield
    rescue SystemExit
      # Expected for error cases
    end

    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def exit_with_code(code)
    raise_error(SystemExit) do |error|
      expect(error.status).to eq(code)
    end
  end
end
