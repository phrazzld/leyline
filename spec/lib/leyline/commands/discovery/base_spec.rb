# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/discovery/base'

RSpec.describe Leyline::Commands::Discovery::Base do
  # Create a test subclass since Base is abstract
  class TestDiscoveryCommand < described_class
    def execute
      metadata_cache = initialize_metadata_cache
      "Executed with cache: #{!metadata_cache.nil?}"
    end
  end

  let(:options) { {} }
  let(:command) { TestDiscoveryCommand.new(options) }

  describe '#initialize_metadata_cache' do
    it 'creates a metadata cache instance' do
      cache = command.send(:initialize_metadata_cache)
      expect(cache).to be_a(Leyline::Discovery::MetadataCache)
    end

    context 'with verbose option' do
      let(:options) { { verbose: true } }

      it 'shows cache warming message when successful' do
        allow_any_instance_of(Leyline::Discovery::MetadataCache)
          .to receive(:warm_cache_in_background).and_return(true)

        expect { command.send(:initialize_metadata_cache) }
          .to output(/Starting cache warm-up in background/).to_stdout
      end

      it 'shows warning when cache warming fails' do
        allow_any_instance_of(Leyline::Discovery::MetadataCache)
          .to receive(:warm_cache_in_background).and_raise('Warming error')

        expect { command.send(:initialize_metadata_cache) }
          .to output(/Warning: Cache warming failed/).to_stderr
      end
    end
  end

  describe '#format_bytes' do
    it 'formats bytes correctly' do
      expect(command.send(:format_bytes, 0)).to eq('0 B')
      expect(command.send(:format_bytes, 1024)).to eq('1.00 KB')
      expect(command.send(:format_bytes, 1048576)).to eq('1.00 MB')
      expect(command.send(:format_bytes, 1073741824)).to eq('1.00 GB')
    end
  end

  describe '#format_relevance' do
    it 'formats relevance scores as stars' do
      expect(command.send(:format_relevance, nil)).to eq('')
      expect(command.send(:format_relevance, 0.0)).to eq('☆☆☆☆☆')
      expect(command.send(:format_relevance, 0.5)).to eq('★★★☆☆')
      expect(command.send(:format_relevance, 1.0)).to eq('★★★★★')
      expect(command.send(:format_relevance, 2.0)).to eq('★★★★★') # Clamped to max
      expect(command.send(:format_relevance, -1.0)).to eq('☆☆☆☆☆') # Clamped to min
    end
  end

  describe '#truncate_content' do
    it 'truncates long content' do
      long_text = 'a' * 300
      result = command.send(:truncate_content, long_text)
      expect(result.length).to eq(200)
      expect(result).to end_with('...')
    end

    it 'preserves short content' do
      short_text = 'Short text'
      result = command.send(:truncate_content, short_text)
      expect(result).to eq(short_text)
    end

    it 'handles nil content' do
      expect(command.send(:truncate_content, nil)).to eq('')
    end

    it 'normalizes whitespace' do
      spaced_text = "Text  with   multiple\n\nspaces"
      result = command.send(:truncate_content, spaced_text)
      expect(result).to eq('Text with multiple spaces')
    end
  end

  describe '#display_stats' do
    let(:options) { { stats: true } }
    let(:mock_cache) do
      double('metadata_cache',
             cache_performance_stats: {
               document_count: 100,
               memory_usage: 1048576,
               hit_ratio: 0.85,
               compression_ratio: 2.5,
               operation_stats: {
                 search: { avg: 0.123, count: 10 },
                 list: { avg: 0.045, count: 5 }
               }
             })
    end

    it 'displays performance statistics' do
      output = capture_stdout do
        command.send(:display_stats, mock_cache, Time.now - 1)
      end

      expect(output).to include('Cache Performance:')
      expect(output).to include('Documents scanned: 100')
      expect(output).to include('Memory usage: 1.00 MB')
      expect(output).to include('Hit ratio: 85.0%')
      expect(output).to include('Compression ratio: 2.5x')
      expect(output).to include('search: 0.123s avg (10 calls)')
    end
  end

  describe '#available_categories' do
    it 'returns valid categories from CLI options' do
      categories = command.send(:available_categories)
      expect(categories).to be_an(Array)
      expect(categories).to include('core', 'typescript', 'ruby')
    end
  end

  describe 'error handling' do
    it 'defines DiscoveryError with proper recovery suggestions' do
      error = Leyline::Commands::Discovery::Base::DiscoveryError.new('Test error')
      expect(error.error_type).to eq(:discovery)
      expect(error.recovery_suggestions).to include('Ensure leyline repository is accessible')
    end
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
