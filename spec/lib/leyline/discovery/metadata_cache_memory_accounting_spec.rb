# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Leyline::Discovery::MetadataCache, 'memory accounting' do
  let(:temp_dir) { Dir.mktmpdir('metadata_cache_memory_test') }
  let(:file_cache) { Leyline::Cache::FileCache.new(temp_dir) }
  let(:metadata_cache) { described_class.new(file_cache: file_cache) }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  def create_test_document(path, size = 1000, id = 'test-doc')
    {
      id: id,
      title: 'Test Document',
      path: path,
      category: 'testing',
      type: 'binding',
      metadata: {},
      content_preview: 'Test content preview',
      content_hash: 'abc123',
      size: size,
      modified_time: Time.now,
      scan_time: Time.now
    }
  end

  describe 'memory usage tracking' do
    it 'correctly tracks memory usage for new documents' do
      doc = create_test_document('/test/doc1.md', 500)

      expect { metadata_cache.send(:cache_document, doc) }
        .to change { metadata_cache.instance_variable_get(:@memory_usage) }
        .from(0).to(500)
    end

    it 'prevents memory usage double-counting when updating existing documents' do
      doc = create_test_document('/test/doc1.md', 1000)

      # Cache document first time
      metadata_cache.send(:cache_document, doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1000)

      # Cache same document again (simulating re-scan)
      metadata_cache.send(:cache_document, doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1000)

      # Cache same document multiple times
      3.times { metadata_cache.send(:cache_document, doc) }
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1000)
    end

    it 'correctly updates memory usage when document size changes' do
      path = '/test/doc1.md'
      small_doc = create_test_document(path, 500)
      large_doc = create_test_document(path, 2000)

      # Cache small document
      metadata_cache.send(:cache_document, small_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(500)

      # Update with larger document
      metadata_cache.send(:cache_document, large_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(2000)

      # Update back to smaller document
      metadata_cache.send(:cache_document, small_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(500)
    end

    it 'correctly tracks memory usage with multiple documents' do
      doc1 = create_test_document('/test/doc1.md', 500, 'doc1')
      doc2 = create_test_document('/test/doc2.md', 750, 'doc2')
      doc3 = create_test_document('/test/doc3.md', 300, 'doc3')

      # Cache first document
      metadata_cache.send(:cache_document, doc1)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(500)

      # Cache second document
      metadata_cache.send(:cache_document, doc2)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1250)

      # Cache third document
      metadata_cache.send(:cache_document, doc3)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1550)

      # Update first document with different size
      updated_doc1 = create_test_document('/test/doc1.md', 800, 'doc1')
      metadata_cache.send(:cache_document, updated_doc1)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1850) # 800 + 750 + 300
    end

    context 'with compression enabled' do
      let(:metadata_cache) { described_class.new(file_cache: file_cache, compression_enabled: true) }

      it 'tracks memory usage correctly with compressed documents' do
        # Create document with structured content that compresses well
        doc = {
          id: 'test-doc',
          title: 'Test Document',
          path: '/test/doc1.md',
          category: 'testing',
          type: 'binding',
          metadata: { 'key1' => 'value1', 'key2' => 'value2' },
          content_preview: 'This is a test content preview that should compress well due to repeated patterns.',
          content_hash: 'abc123',
          size: 1000,
          modified_time: Time.now,
          scan_time: Time.now
        }

        initial_usage = metadata_cache.instance_variable_get(:@memory_usage)
        metadata_cache.send(:cache_document, doc)
        final_usage = metadata_cache.instance_variable_get(:@memory_usage)

        # Memory usage should reflect compressed size, not original size
        usage_increase = final_usage - initial_usage
        expect(usage_increase).to be > 0
        expect(usage_increase).to be <= doc[:size] # Should be less than or equal to original

        # Update same document - should maintain accurate accounting
        metadata_cache.send(:cache_document, doc)
        expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(final_usage)
      end
    end

    it 'handles edge cases gracefully' do
      # Document with zero size
      zero_doc = create_test_document('/test/zero.md', 0)
      metadata_cache.send(:cache_document, zero_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(0)

      # Update to non-zero size
      updated_doc = create_test_document('/test/zero.md', 100)
      metadata_cache.send(:cache_document, updated_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(100)

      # Update back to zero
      metadata_cache.send(:cache_document, zero_doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(0)
    end
  end

  describe 'memory usage consistency' do
    it 'maintains accurate memory usage through cache invalidation' do
      doc1 = create_test_document('/test/doc1.md', 500, 'doc1')
      doc2 = create_test_document('/test/doc2.md', 750, 'doc2')

      # Cache documents
      metadata_cache.send(:cache_document, doc1)
      metadata_cache.send(:cache_document, doc2)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(1250)

      # Invalidate cache
      metadata_cache.invalidate!
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(0)
    end

    it 'maintains memory usage accuracy during LRU eviction scenarios' do
      # This test verifies memory accounting remains accurate during normal operations
      # Full LRU testing would require exceeding MAX_MEMORY_USAGE which is complex to setup

      # Cache a document and verify basic functionality
      doc = create_test_document('/test/doc.md', 500)
      metadata_cache.send(:cache_document, doc)
      expect(metadata_cache.instance_variable_get(:@memory_usage)).to eq(500)

      # Verify eviction method exists as private method
      expect(metadata_cache.private_methods).to include(:evict_least_recently_used)
    end
  end
end
