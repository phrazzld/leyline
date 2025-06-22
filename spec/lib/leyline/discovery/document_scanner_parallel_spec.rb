# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../../../../lib/leyline/discovery/document_scanner'

RSpec.describe Leyline::Discovery::DocumentScanner do
  subject(:scanner) { described_class.new }

  describe 'parallel document processing' do
    let(:temp_dir) { Dir.mktmpdir('document_scanner_test') }
    let(:test_files) { [] }

    before do
      # Create test markdown files with YAML front-matter
      15.times do |i|
        file_path = File.join(temp_dir, "test_#{i}.md")
        content = <<~MARKDOWN
          ---
          id: test-document-#{i}
          title: Test Document #{i}
          category: test
          ---

          # Test Document #{i}

          This is the content for test document #{i}.
          It contains some sample text for testing parallel processing.
        MARKDOWN

        File.write(file_path, content)
        test_files << file_path
      end
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context 'when processing many files (>= parallel threshold)' do
      it 'processes documents correctly using parallel execution' do
        results = scanner.scan_documents(test_files)

        expect(results).to have_attributes(length: 15)
        expect(results).to all(be_a(Hash))
        expect(results).to all(include(:id, :title, :path, :category, :type))

        # Verify all expected documents are present
        result_ids = results.map { |doc| doc[:id] }.sort
        expected_ids = 15.times.map { |i| "test-document-#{i}" }.sort
        expect(result_ids).to eq(expected_ids)
      end

      it 'records parallel batch statistics' do
        scanner.scan_documents(test_files)
        stats = scanner.scan_statistics

        expect(stats[:parallel_batches]).to eq(1)
        expect(stats[:sequential_batches]).to eq(0)
        expect(stats[:files_scanned]).to eq(15)
      end
    end

    context 'when processing few files (< parallel threshold)' do
      let(:small_batch) { test_files.first(5) }

      it 'uses sequential processing for small batches' do
        results = scanner.scan_documents(small_batch)

        expect(results).to have_attributes(length: 5)

        stats = scanner.scan_statistics
        expect(stats[:sequential_batches]).to eq(1)
        expect(stats[:parallel_batches]).to eq(0)
        expect(stats[:files_scanned]).to eq(5)
      end
    end

    context 'error handling' do
      let(:mixed_files) do
        valid_files = test_files.first(3)
        invalid_files = [
          File.join(temp_dir, 'nonexistent.md')
        ]

        valid_files + invalid_files
      end

      it 'handles missing files gracefully' do
        results = scanner.scan_documents(mixed_files)

        # Should only get results for valid files
        expect(results.length).to eq(3)
        expect(results).to all(include(:id, :title))
      end
    end

    context 'resource management' do
      it 'limits concurrent threads to reasonable number' do
        expect(described_class::MAX_THREADS).to be_between(1, 8)
        expect(described_class::PARALLEL_THRESHOLD).to be_between(5, 20)
      end
    end
  end

  describe 'integration with existing functionality' do
    let(:temp_dir) { Dir.mktmpdir('integration_test') }
    let(:test_file) { File.join(temp_dir, 'test.md') }

    before do
      content = <<~MARKDOWN
        ---
        id: integration-test
        title: Integration Test Document
        ---

        # Integration Test

        This document tests integration with existing scanner functionality.
      MARKDOWN

      File.write(test_file, content)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'maintains compatibility with single document scanning' do
      result = scanner.scan_document(test_file)

      expect(result).to include(
        id: 'integration-test',
        title: 'Integration Test', # DocumentScanner extracts from markdown header, not YAML
        path: test_file
      )
    end

    it 'maintains statistics tracking across different scan methods' do
      # Scan single document
      scanner.scan_document(test_file)

      # Scan batch
      scanner.scan_documents([test_file])

      stats = scanner.scan_statistics
      expect(stats[:files_scanned]).to eq(2)
    end
  end
end
