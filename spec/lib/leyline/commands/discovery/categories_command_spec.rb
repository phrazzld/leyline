# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/discovery/categories_command'

RSpec.describe Leyline::Commands::Discovery::CategoriesCommand do
  let(:options) { {} }
  let(:command) { described_class.new(options) }

  describe '#initialize' do
    it 'inherits from Discovery::Base' do
      expect(command).to be_a(Leyline::Commands::Discovery::Base)
    end

    it 'inherits from BaseCommand' do
      expect(command).to be_a(Leyline::Commands::BaseCommand)
    end
  end

  describe '#execute' do
    before do
      # Mock the available_categories method which is defined in the base class
      allow(command).to receive(:available_categories).and_return(['typescript', 'go', 'rust'])
    end

    context 'with default options' do
      it 'returns categories information' do
        result = command.execute

        expect(result).to be_a(Hash)
        expect(result[:categories]).to eq(['typescript', 'go', 'rust'])
        expect(result[:total_count]).to eq(3)
        expect(result[:command_hint]).to eq('leyline sync -c <category1>,<category2>')
      end

      it 'displays human-readable output' do
        output = capture_stdout { command.execute }

        expect(output).to include('Available categories for sync:')
        expect(output).to include('- typescript')
        expect(output).to include('- go')
        expect(output).to include('- rust')
        expect(output).to include('You can sync them using: leyline sync -c <category1>,<category2>')
      end
    end

    context 'with JSON output' do
      let(:options) { { json: true } }

      it 'outputs JSON format' do
        output = capture_stdout { command.execute }

        expect(output).to include('"categories"')
        expect(output).to include('"total_count"')
        expect(output).to include('"command_hint"')
        expect(output).to include('"typescript"')
        expect(output).to include('"go"')
        expect(output).to include('"rust"')
      end

      it 'does not output human-readable format' do
        output = capture_stdout { command.execute }

        expect(output).not_to include('Available categories for sync:')
        expect(output).not_to include('You can sync them using:')
      end
    end

    context 'with stats option' do
      let(:options) { { stats: true } }

      it 'displays statistics' do
        # Mock the display_stats method
        allow(command).to receive(:display_stats)

        command.execute

        expect(command).to have_received(:display_stats)
      end
    end

    context 'with verbose and stats options' do
      let(:options) { { verbose: true, stats: true } }

      it 'displays both verbose output and statistics' do
        allow(command).to receive(:display_stats)

        output = capture_stdout { command.execute }

        expect(output).to include('Available categories for sync:')
        expect(command).to have_received(:display_stats)
      end
    end

    context 'when an error occurs' do
      before do
        allow(command).to receive(:available_categories).and_raise(StandardError.new('Test error'))
        allow(command).to receive(:handle_error)
      end

      it 'handles the error and returns nil' do
        result = command.execute

        expect(result).to be_nil
        expect(command).to have_received(:handle_error).with(instance_of(StandardError))
      end
    end

    context 'with empty categories' do
      before do
        allow(command).to receive(:available_categories).and_return([])
      end

      it 'handles empty categories gracefully' do
        result = command.execute

        expect(result[:categories]).to eq([])
        expect(result[:total_count]).to eq(0)
      end

      it 'displays appropriate message for empty categories' do
        output = capture_stdout { command.execute }

        expect(output).to include('Available categories for sync:')
        expect(output).to include('You can sync them using:')
      end
    end

    context 'with single category' do
      before do
        allow(command).to receive(:available_categories).and_return(['typescript'])
      end

      it 'displays single category correctly' do
        output = capture_stdout { command.execute }

        expect(output).to include('- typescript')
        expect(output).not_to include('- go')
        expect(output).not_to include('- rust')
      end
    end

    context 'with many categories' do
      before do
        categories = %w[typescript go rust python java csharp javascript php ruby swift kotlin]
        allow(command).to receive(:available_categories).and_return(categories)
      end

      it 'displays all categories' do
        output = capture_stdout { command.execute }

        expect(output).to include('- typescript')
        expect(output).to include('- go')
        expect(output).to include('- rust')
        expect(output).to include('- python')
        expect(output).to include('- java')
        expect(output).to include('- csharp')
        expect(output).to include('- javascript')
        expect(output).to include('- php')
        expect(output).to include('- ruby')
        expect(output).to include('- swift')
        expect(output).to include('- kotlin')
      end

      it 'returns correct total count' do
        result = command.execute
        expect(result[:total_count]).to eq(11)
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
