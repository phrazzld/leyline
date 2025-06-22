# frozen_string_literal: true

require_relative '../../../lib/leyline/cli'

RSpec.describe Leyline::CLI do
  subject(:cli) { described_class.new }

  describe 'discovery commands with cache warm-up integration' do
    let(:metadata_cache) { instance_double(Leyline::Discovery::MetadataCache) }
    let(:file_cache) { instance_double(Leyline::Cache::FileCache) }

    before do
      # Mock cache creation
      allow(cli).to receive(:create_file_cache_if_needed).and_return(file_cache)
      allow(Leyline::Discovery::MetadataCache).to receive(:new).and_return(metadata_cache)

      # Mock discovery operations
      allow(metadata_cache).to receive(:categories).and_return(['test'])
      allow(metadata_cache).to receive(:documents_for_category).and_return([])
      allow(metadata_cache).to receive(:search).and_return([])
      allow(metadata_cache).to receive(:performance_stats).and_return({
        hit_ratio: 0.8,
        memory_usage: 1024,
        document_count: 10,
        category_count: 2,
        scan_count: 1,
        last_scan: Time.now
      })
    end

    describe 'cache warm-up integration' do
      it 'triggers cache warming on categories command' do
        expect(metadata_cache).to receive(:warm_cache_in_background).and_return(true)

        capture_output { cli.categories }
      end

      it 'triggers cache warming on show command' do
        expect(metadata_cache).to receive(:warm_cache_in_background).and_return(true)

        capture_output { cli.show('test') }
      end

      it 'triggers cache warming on search command' do
        expect(metadata_cache).to receive(:warm_cache_in_background).and_return(true)

        capture_output { cli.search('test') }
      end

      it 'shows warming message in verbose mode when warming starts' do
        allow(metadata_cache).to receive(:warm_cache_in_background).and_return(true)

        output = capture_output { cli.invoke(:categories, [], verbose: true) }

        expect(output).to include('Starting cache warm-up in background')
      end

      it 'does not show warming message when warming already active' do
        allow(metadata_cache).to receive(:warm_cache_in_background).and_return(false)

        output = capture_output { cli.invoke(:categories, [], verbose: true) }

        expect(output).not_to include('Starting cache warm-up')
      end

      it 'does not show warming message in non-verbose mode' do
        allow(metadata_cache).to receive(:warm_cache_in_background).and_return(true)

        output = capture_output { cli.categories }

        expect(output).not_to include('Starting cache warm-up')
      end
    end

    describe 'error handling' do
      it 'continues normally if cache warming fails to start' do
        allow(metadata_cache).to receive(:warm_cache_in_background).and_raise(StandardError, 'Warming failed')

        expect { capture_output { cli.categories } }.not_to raise_error
      end
    end
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
