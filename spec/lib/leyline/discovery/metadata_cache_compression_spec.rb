# frozen_string_literal: true

require_relative '../../../../lib/leyline/discovery/metadata_cache'

RSpec.describe Leyline::Discovery::MetadataCache do
  describe 'compression functionality' do
    describe 'document storage compression' do
      it 'has compression support available' do
        cache = described_class.new(compression_enabled: true)
        expect(cache).to respond_to(:compression_enabled?)
      end

      it 'compresses document content when storing in memory cache' do
        cache = described_class.new(compression_enabled: true)
        document = create_large_test_document

        cache.cache_document(document)

        expect(cache.memory_usage_bytes).to be < document[:size] * 0.8 # 20%+ compression expected
      end
    end

    describe 'compression effectiveness' do
      it 'achieves target compression ratio with structured content' do
        cache = described_class.new(compression_enabled: true)

        # Use deterministic test data that compresses well
        content = "# Heading\n\n" + 'This is repeated content. ' * 100
        document = create_document_with_content(content)

        cache.cache_document(document)

        stats = cache.performance_stats
        compression_ratio = stats[:compression_stats][:compression_ratio]
        expect(compression_ratio).to be <= 0.5 # 50% or better compression
      end
    end

    describe 'backward compatibility' do
      let(:test_document) do
        {
          id: 'test-doc',
          title: 'Test Document',
          path: '/test/path.md',
          category: 'test',
          type: 'binding',
          metadata: { 'key' => 'value' },
          content_preview: 'This is test content for compression testing',
          content_hash: 'abc123',
          size: 100,
          modified_time: Time.now,
          scan_time: Time.now
        }
      end

      shared_examples 'maintains cache contract' do
        before do
          subject.cache_document(test_document)
        end

        it 'preserves categories interface' do
          categories = subject.categories
          expect(categories).to be_an(Array)
        end

        it 'preserves documents_for_category interface' do
          documents = subject.documents_for_category('test')
          expect(documents).to be_an(Array)
          expect(documents.first).to include(:id, :title, :content_preview)
        end

        it 'preserves search interface' do
          results = subject.search('test')
          expect(results).to be_an(Array)
          expect(results.first).to include(:document, :score) unless results.empty?
        end
      end

      context 'with compression enabled' do
        subject { described_class.new(compression_enabled: true) }
        include_examples 'maintains cache contract'
      end

      context 'with compression disabled' do
        subject { described_class.new(compression_enabled: false) }
        include_examples 'maintains cache contract'
      end
    end
  end

  private

  def create_large_test_document
    large_content = 'This is repeated content that should compress well. ' * 50
    {
      id: 'large-test-doc',
      title: 'Large Test Document',
      path: '/test/large.md',
      category: 'test',
      type: 'binding',
      metadata: { 'description' => 'Test document with large content' },
      content_preview: large_content,
      content_hash: 'large123',
      size: large_content.bytesize,
      modified_time: Time.now,
      scan_time: Time.now
    }
  end

  def create_document_with_content(content)
    {
      id: 'content-test-doc',
      title: 'Content Test Document',
      path: '/test/content.md',
      category: 'test',
      type: 'binding',
      metadata: { 'content' => 'structured' },
      content_preview: content,
      content_hash: 'content123',
      size: content.bytesize,
      modified_time: Time.now,
      scan_time: Time.now
    }
  end
end
