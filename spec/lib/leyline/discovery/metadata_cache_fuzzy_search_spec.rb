# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe Leyline::Discovery::MetadataCache do
  describe '#search with fuzzy matching' do
    let(:cache) { described_class.new }
    let(:test_documents) do
      [
        create_document(id: 'test-001', title: 'Testing Best Practices'),
        create_document(id: 'perf-001', title: 'Performance Optimization'),
        create_document(id: 'cache-001', title: 'Caching Strategies'),
        create_document(id: 'bind-001', title: 'Binding Guidelines'),
        create_document(id: 'type-001', title: 'TypeScript Configuration')
      ]
    end

    before do
      # Mock to only use our test documents, not real repository files
      allow(cache).to receive(:discover_document_paths).and_return([])
      test_documents.each { |doc| cache.cache_document(doc) }
    end

    context 'exact matches (backward compatibility)' do
      it 'continues to work as before for exact substring matches' do
        results = cache.search('Testing')
        expect(results.first[:document][:title]).to eq('Testing Best Practices')
        expect(results.first[:score]).to be >= 100  # May have additional matches
      end

      it 'finds case-insensitive matches' do
        results = cache.search('PERFORMANCE')
        expect(results.first[:document][:title]).to eq('Performance Optimization')
      end

      it 'handles partial word matches' do
        results = cache.search('Cache')
        expect(results.first[:document][:title]).to eq('Caching Strategies')
      end
    end

    context 'fuzzy matches for typos' do
      it 'finds documents with single character transpositions' do
        results = cache.search('Tesitng')  # transposed 't' and 'i'
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('Testing Best Practices')
        expect(results.first[:score]).to be < 100  # Lower than exact match
      end

      it 'finds documents with missing characters' do
        results = cache.search('Performnce')  # missing 'a'
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('Performance Optimization')
      end

      it 'finds documents with extra characters' do
        results = cache.search('Testting')  # extra 't'
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('Testing Best Practices')
      end

      it 'finds documents with character substitutions' do
        results = cache.search('Cacheng')  # 'i' -> 'e'
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('Caching Strategies')
      end
    end

    context 'fuzzy match relevance scoring' do
      it 'ranks exact matches higher than fuzzy matches' do
        # Add a document with the fuzzy match as exact
        cache.cache_document(create_document(id: 'exact-match', title: 'Tesitng Document'))

        results = cache.search('Testing')

        # Exact match should be first
        expect(results[0][:document][:title]).to eq('Testing Best Practices')
        expect(results[0][:score]).to be > results[1][:score]
      end

      it 'ranks closer fuzzy matches higher' do
        results = cache.search('Testng')  # Missing one character from 'Testing'
        expect(results).not_to be_empty
        close_match_score = results.first[:score]

        results = cache.search('Tesng')  # Missing two characters from 'Testing'
        expect(results).not_to be_empty
        distant_match_score = results.first[:score]

        expect(close_match_score).to be > distant_match_score
      end

      it 'does not match when too many differences exist' do
        results = cache.search('xyz')  # Completely different
        expect(results).to be_empty
      end
    end

    context 'word-level fuzzy matching' do
      it 'matches individual words in multi-word titles' do
        results = cache.search('Guidlines')  # 'Guidelines' with typo
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('Binding Guidelines')
      end

      it 'finds partial word matches' do
        results = cache.search('Type')  # Partial match for 'TypeScript'
        expect(results).not_to be_empty
        expect(results.first[:document][:title]).to eq('TypeScript Configuration')
      end
    end

    context 'performance with fuzzy search' do
      it 'maintains sub-second performance with fuzzy matching enabled' do
        # Create larger dataset for realistic testing
        50.times do |i|
          cache.cache_document(create_document(
            id: "doc-#{i}",
            title: "Document about #{['testing', 'performance', 'caching', 'binding'].sample} #{i}"
          ))
        end

        queries_with_typos = ['tesitng', 'perfromance', 'cachign', 'bindng']

        queries_with_typos.each do |query|
          elapsed = Benchmark.realtime { cache.search(query) }
          expect(elapsed).to be < 1.0
        end
      end

      it 'does not significantly degrade performance vs exact search' do
        exact_time = Benchmark.realtime { cache.search('Testing') }
        fuzzy_time = Benchmark.realtime { cache.search('Tesitng') }

        # Fuzzy search should not be more than 5x slower
        expect(fuzzy_time).to be < exact_time * 5
      end
    end

    context 'configuration and edge cases' do
      it 'handles empty and nil queries gracefully' do
        expect(cache.search('')).to be_empty
        expect(cache.search(nil)).to be_empty
      end

      it 'handles very short queries' do
        results = cache.search('T')
        expect(results).to be_an(Array)  # Should not crash
      end

      it 'preserves existing search behavior for long exact matches' do
        cache.cache_document(create_document(
          id: 'long-001',
          title: 'A Very Long Document Title With Many Words'
        ))

        results = cache.search('Very Long Document')
        expect(results.first[:document][:title]).to eq('A Very Long Document Title With Many Words')
      end
    end

    context '"Did you mean?" suggestions' do
      it 'provides suggestions for queries with no results' do
        suggestions = cache.suggest_corrections('Testng')  # Close to 'Testing'
        expect(suggestions).to include('Testing')
      end

      it 'provides multiple relevant suggestions' do
        suggestions = cache.suggest_corrections('Performnce')  # Close to 'Performance'
        expect(suggestions).to include('Performance')
      end

      it 'returns empty array for very different queries' do
        suggestions = cache.suggest_corrections('xyz')
        expect(suggestions).to be_empty
      end

      it 'returns empty array for very short queries' do
        suggestions = cache.suggest_corrections('ab')
        expect(suggestions).to be_empty
      end

      it 'limits number of suggestions' do
        suggestions = cache.suggest_corrections('Te', 2)  # May match multiple words
        expect(suggestions.length).to be <= 2
      end

      it 'suggests words from document titles' do
        suggestions = cache.suggest_corrections('Cachng')  # Close to 'Caching'
        expect(suggestions).to include('Caching')
      end
    end
  end

  private

  def create_document(id:, title:)
    {
      id: id,
      title: title,
      path: "/test/#{id}.md",
      category: 'test',
      type: 'binding',
      metadata: { 'test' => true },
      content_preview: "Content for #{title}",
      content_hash: "hash-#{id}",
      size: title.length * 10,
      modified_time: Time.now,
      scan_time: Time.now
    }
  end
end
