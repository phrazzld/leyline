# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/discovery/show_command'

RSpec.describe Leyline::Commands::Discovery::ShowCommand do
  let(:category) { 'typescript' }
  let(:options) { { category: category } }
  let(:command) { described_class.new(options) }

  describe '#initialize' do
    it 'inherits from Discovery::Base' do
      expect(command).to be_a(Leyline::Commands::Discovery::Base)
    end

    it 'inherits from BaseCommand' do
      expect(command).to be_a(Leyline::Commands::BaseCommand)
    end

    it 'stores the category parameter' do
      expect(command.instance_variable_get(:@category)).to eq(category)
    end

    context 'with string key category' do
      let(:options) { { 'category' => 'go' } }

      it 'handles string key category parameter' do
        expect(command.instance_variable_get(:@category)).to eq('go')
      end
    end

    context 'without category parameter' do
      let(:options) { {} }

      it 'raises DiscoveryError' do
        expect { command }.to raise_error(Leyline::Commands::Discovery::Base::DiscoveryError, 'Category parameter is required')
      end
    end
  end

  describe '#execute' do
    let(:mock_metadata_cache) { instance_double(Leyline::Discovery::MetadataCache) }
    let(:mock_documents) do
      [
        {
          title: 'TypeScript Best Practices',
          id: 'typescript-best-practices',
          type: 'binding',
          path: 'docs/bindings/categories/typescript/best-practices.md',
          description: 'Guidelines for writing clean TypeScript code'
        },
        {
          title: 'Testing Patterns',
          id: 'typescript-testing-patterns',
          type: 'binding',
          path: 'docs/bindings/categories/typescript/testing-patterns.md',
          description: 'Patterns for effective TypeScript testing'
        }
      ]
    end

    before do
      allow(command).to receive(:initialize_metadata_cache).and_return(mock_metadata_cache)
      allow(mock_metadata_cache).to receive(:documents_for_category).with(category).and_return(mock_documents)
      allow(mock_metadata_cache).to receive(:categories).and_return(['typescript', 'go', 'rust'])
      allow(command).to receive(:display_stats)
    end

    context 'with default options' do
      it 'returns category documents information' do
        result = command.execute

        expect(result).to be_a(Hash)
        expect(result[:category]).to eq('typescript')
        expect(result[:document_count]).to eq(2)
        expect(result[:documents].size).to eq(2)
        expect(result[:available_categories]).to eq(['typescript', 'go', 'rust'])
      end

      it 'displays human-readable output' do
        output = capture_stdout { command.execute }

        expect(output).to include("Documents in 'typescript' (2):")
        expect(output).to include('TypeScript Best Practices')
        expect(output).to include('ID: typescript-best-practices')
        expect(output).to include('Type: binding')
        expect(output).to include('Testing Patterns')
        expect(output).to include('ID: typescript-testing-patterns')
      end

      it 'calls display_stats' do
        command.execute
        expect(command).to have_received(:display_stats)
      end
    end

    context 'with verbose option' do
      let(:options) { { category: category, verbose: true } }

      it 'displays additional information' do
        output = capture_stdout { command.execute }

        expect(output).to include('Path: docs/bindings/categories/typescript/best-practices.md')
        expect(output).to include('Description: Guidelines for writing clean TypeScript code')
        expect(output).to include('Path: docs/bindings/categories/typescript/testing-patterns.md')
        expect(output).to include('Description: Patterns for effective TypeScript testing')
      end
    end

    context 'with JSON output' do
      let(:options) { { category: category, json: true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }

        expect(output).to include('"category"')
        expect(output).to include('"document_count"')
        expect(output).to include('"documents"')
        expect(output).to include('"available_categories"')
        expect(output).to include('"typescript"')
      end

      it 'does not output human-readable format' do
        output = capture_stdout { command.execute }

        expect(output).not_to include("Documents in 'typescript' (2):")
        expect(output).not_to include('ID: typescript-best-practices')
        expect(output).not_to include('Type: binding')
      end
    end

    context 'with string key json option' do
      let(:options) { { category: category, 'json' => true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }

        expect(output).to include('"category"')
        expect(output).to include('"document_count"')
        expect(output).to include('"documents"')
      end
    end

    context 'with empty documents' do
      let(:mock_documents) { [] }

      it 'displays appropriate message for empty category' do
        output = capture_stdout { command.execute }

        expect(output).to include("No documents found in category 'typescript'")
        expect(output).to include('Available categories: typescript, go, rust')
      end

      it 'returns correct structure for empty category' do
        result = command.execute

        expect(result[:category]).to eq('typescript')
        expect(result[:document_count]).to eq(0)
        expect(result[:documents]).to be_empty
        expect(result[:available_categories]).to eq(['typescript', 'go', 'rust'])
      end
    end

    context 'with single document' do
      let(:mock_documents) do
        [
          {
            title: 'Single Document',
            id: 'single-doc',
            type: 'tenet',
            path: 'docs/tenets/single.md',
            description: 'A single document'
          }
        ]
      end

      it 'displays single document correctly' do
        output = capture_stdout { command.execute }

        expect(output).to include("Documents in 'typescript' (1):")
        expect(output).to include('Single Document')
        expect(output).to include('ID: single-doc')
        expect(output).to include('Type: tenet')
      end
    end

    context 'with document without description' do
      let(:mock_documents) do
        [
          {
            title: 'No Description Doc',
            id: 'no-desc',
            type: 'binding',
            path: 'docs/bindings/no-desc.md',
            description: nil
          }
        ]
      end

      it 'handles missing description gracefully' do
        output = capture_stdout { command.execute }

        expect(output).to include('No Description Doc')
        expect(output).to include('ID: no-desc')
        expect(output).to include('Type: binding')
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
        allow(mock_metadata_cache).to receive(:documents_for_category).and_raise(StandardError.new('Cache error'))
        allow(command).to receive(:handle_error)
      end

      it 'handles metadata cache errors' do
        result = command.execute

        expect(result).to be_nil
        expect(command).to have_received(:handle_error).with(instance_of(StandardError))
      end
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
