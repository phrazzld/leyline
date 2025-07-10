# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/discovery/search_command'

RSpec.describe Leyline::Commands::Discovery::SearchCommand do
  let(:query) { 'typescript' }
  let(:options) { { query: query } }
  let(:command) { described_class.new(options) }

  describe '#initialize' do
    it 'inherits from Discovery::Base' do
      expect(command).to be_a(Leyline::Commands::Discovery::Base)
    end

    it 'inherits from BaseCommand' do
      expect(command).to be_a(Leyline::Commands::BaseCommand)
    end

    it 'stores the query parameter' do
      expect(command.instance_variable_get(:@query)).to eq(query)
    end

    it 'sets default limit to 10' do
      expect(command.instance_variable_get(:@limit)).to eq(10)
    end

    context 'with string key query' do
      let(:options) { { 'query' => 'testing' } }

      it 'handles string key query parameter' do
        expect(command.instance_variable_get(:@query)).to eq('testing')
      end
    end

    context 'with custom limit' do
      let(:options) { { query: query, limit: 20 } }

      it 'stores the custom limit' do
        expect(command.instance_variable_get(:@limit)).to eq(20)
      end
    end

    context 'with string limit' do
      let(:options) { { query: query, limit: '15' } }

      it 'converts string limit to integer' do
        expect(command.instance_variable_get(:@limit)).to eq(15)
      end
    end

    context 'without query parameter' do
      let(:options) { {} }

      it 'raises DiscoveryError' do
        expect { command }.to raise_error(Leyline::Commands::Discovery::Base::DiscoveryError, 'Search query cannot be empty')
      end
    end

    context 'with empty query' do
      let(:options) { { query: '' } }

      it 'raises DiscoveryError' do
        expect { command }.to raise_error(Leyline::Commands::Discovery::Base::DiscoveryError, 'Search query cannot be empty')
      end
    end

    context 'with whitespace-only query' do
      let(:options) { { query: '   ' } }

      it 'raises DiscoveryError' do
        expect { command }.to raise_error(Leyline::Commands::Discovery::Base::DiscoveryError, 'Search query cannot be empty')
      end
    end
  end

  describe '#execute' do
    let(:mock_metadata_cache) { instance_double(Leyline::Discovery::MetadataCache) }
    let(:mock_search_results) do
      [
        {
          document: {
            title: 'TypeScript Best Practices',
            path: 'docs/bindings/categories/typescript/best-practices.md',
            type: 'binding',
            content_preview: 'This document covers TypeScript best practices for modern development'
          },
          score: 150.0,
          matches: ['typescript', 'best practices']
        },
        {
          document: {
            title: 'Testing Patterns',
            path: 'docs/bindings/categories/typescript/testing-patterns.md',
            type: 'binding',
            content_preview: 'Comprehensive testing patterns for TypeScript applications'
          },
          score: 120.0,
          matches: ['typescript', 'testing']
        }
      ]
    end

    before do
      allow(command).to receive(:initialize_metadata_cache).and_return(mock_metadata_cache)
      allow(mock_metadata_cache).to receive(:search).with(query).and_return(mock_search_results)
      allow(mock_metadata_cache).to receive(:suggest_corrections).and_return([])
      allow(command).to receive(:display_stats)
    end

    context 'with default options' do
      it 'returns search results information' do
        result = command.execute

        expect(result).to be_a(Hash)
        expect(result[:query]).to eq('typescript')
        expect(result[:total_results]).to eq(2)
        expect(result[:shown_results]).to eq(2)
        expect(result[:limit]).to eq(10)
        expect(result[:results].size).to eq(2)
        expect(result[:suggestions]).to be_empty
      end

      it 'displays human-readable output' do
        output = capture_stdout { command.execute }

        expect(output).to include("Search results for 'typescript' (showing 2 of 2):")
        expect(output).to include('1. TypeScript Best Practices')
        expect(output).to include('2. Testing Patterns')
        expect(output).to include('Category: typescript | Type: binding')
      end

      it 'calls display_stats' do
        command.execute
        expect(command).to have_received(:display_stats)
      end
    end

    context 'with verbose option' do
      let(:options) { { query: query, verbose: true } }

      it 'displays additional information' do
        output = capture_stdout { command.execute }

        expect(output).to include('Preview: This document covers TypeScript best practices for modern development')
        expect(output).to include('Matches: typescript, best practices')
        expect(output).to include('Preview: Comprehensive testing patterns for TypeScript applications')
        expect(output).to include('Matches: typescript, testing')
      end
    end

    context 'with JSON output' do
      let(:options) { { query: query, json: true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }

        expect(output).to include('"query"')
        expect(output).to include('"total_results"')
        expect(output).to include('"shown_results"')
        expect(output).to include('"results"')
        expect(output).to include('"suggestions"')
        expect(output).to include('"typescript"')
      end

      it 'does not output human-readable format' do
        output = capture_stdout { command.execute }

        expect(output).not_to include("Search results for 'typescript' (showing 2 of 2):")
        expect(output).not_to include('1. TypeScript Best Practices')
        expect(output).not_to include('Category: typescript | Type: binding')
      end
    end

    context 'with string key json option' do
      let(:options) { { query: query, 'json' => true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }

        expect(output).to include('"query"')
        expect(output).to include('"total_results"')
        expect(output).to include('"results"')
      end
    end

    context 'with custom limit' do
      let(:options) { { query: query, limit: 1 } }

      it 'limits results correctly' do
        result = command.execute

        expect(result[:total_results]).to eq(2)
        expect(result[:shown_results]).to eq(1)
        expect(result[:limit]).to eq(1)
        expect(result[:results].size).to eq(1)
      end

      it 'displays limit message' do
        output = capture_stdout { command.execute }

        expect(output).to include("Search results for 'typescript' (showing 1 of 2):")
        expect(output).to include('Use --limit 2 to see all results')
      end
    end

    context 'with no search results' do
      let(:mock_search_results) { [] }
      let(:suggestions) { ['typescript patterns', 'typescript testing'] }

      before do
        allow(mock_metadata_cache).to receive(:search).with(query).and_return([])
        allow(mock_metadata_cache).to receive(:suggest_corrections).with(query).and_return(suggestions)
      end

      it 'displays no results message' do
        output = capture_stdout { command.execute }

        expect(output).to include("No results found for 'typescript'")
      end

      it 'displays suggestions when available' do
        output = capture_stdout { command.execute }

        expect(output).to include('Did you mean:')
        expect(output).to include('typescript patterns')
        expect(output).to include('typescript testing')
      end

      it 'returns correct structure for no results' do
        result = command.execute

        expect(result[:query]).to eq('typescript')
        expect(result[:total_results]).to eq(0)
        expect(result[:shown_results]).to eq(0)
        expect(result[:results]).to be_empty
        expect(result[:suggestions]).to eq(suggestions)
      end
    end

    context 'with no suggestions' do
      let(:mock_search_results) { [] }

      before do
        allow(mock_metadata_cache).to receive(:search).with(query).and_return([])
        allow(mock_metadata_cache).to receive(:suggest_corrections).with(query).and_return([])
      end

      it 'does not display suggestions section' do
        output = capture_stdout { command.execute }

        expect(output).to include("No results found for 'typescript'")
        expect(output).not_to include('Did you mean:')
      end
    end

    context 'with core category documents' do
      let(:mock_search_results) do
        [
          {
            document: {
              title: 'Core Principle',
              path: 'docs/tenets/core-principle.md',
              type: 'tenet',
              content_preview: 'Core development principle'
            },
            score: 100.0,
            matches: ['core']
          }
        ]
      end

      it 'extracts core category correctly' do
        result = command.execute

        expect(result[:results].first[:category]).to eq('core')
      end
    end

    context 'with unknown category documents' do
      let(:mock_search_results) do
        [
          {
            document: {
              title: 'Unknown Document',
              path: 'unknown/path.md',
              type: 'binding',
              content_preview: 'Unknown document'
            },
            score: 50.0,
            matches: ['unknown']
          }
        ]
      end

      it 'extracts unknown category correctly' do
        result = command.execute

        expect(result[:results].first[:category]).to eq('core')
      end
    end

    context 'when an error occurs' do
      before do
        allow(command).to receive(:initialize_metadata_cache).and_raise(StandardError.new('Test error'))
        allow(command).to receive(:handle_error)
      end

      it 'handles the error and returns nil' do
        result = command.execute

        expect(result).to be_nil
        expect(command).to have_received(:handle_error).with(instance_of(StandardError))
      end
    end

    context 'when metadata cache fails' do
      before do
        allow(mock_metadata_cache).to receive(:search).and_raise(StandardError.new('Search error'))
        allow(command).to receive(:handle_error)
      end

      it 'handles search errors' do
        result = command.execute

        expect(result).to be_nil
        expect(command).to have_received(:handle_error).with(instance_of(StandardError))
      end
    end
  end

  describe 'score normalization' do
    it 'normalizes scores to 0-1 range' do
      command = described_class.new({ query: 'test' })

      expect(command.send(:normalize_score, 0)).to eq(0.0)
      expect(command.send(:normalize_score, 100)).to eq(0.5)
      expect(command.send(:normalize_score, 200)).to eq(1.0)
      expect(command.send(:normalize_score, 300)).to eq(1.0)  # Capped at 1.0
      expect(command.send(:normalize_score, nil)).to eq(0.0)
    end
  end

  describe 'category extraction' do
    it 'extracts category from path correctly' do
      command = described_class.new({ query: 'test' })

      expect(command.send(:extract_category, 'docs/bindings/categories/typescript/file.md')).to eq('typescript')
      expect(command.send(:extract_category, 'docs/bindings/categories/go/file.md')).to eq('go')
      expect(command.send(:extract_category, 'docs/tenets/core-principle.md')).to eq('core')
      expect(command.send(:extract_category, 'unknown/path.md')).to eq('core')
      expect(command.send(:extract_category, nil)).to eq('unknown')
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
