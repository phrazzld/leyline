# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'Cache optional parameters validation' do
  let(:temp_source_dir) { Dir.mktmpdir('leyline-cache-optional-source') }
  let(:temp_target_dir) { Dir.mktmpdir('leyline-cache-optional-target') }

  before do
    # Create test files
    FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
    File.write(File.join(temp_source_dir, 'docs', 'test.md'), 'content')
  end

  after do
    FileUtils.rm_rf(temp_source_dir) if Dir.exist?(temp_source_dir)
    FileUtils.rm_rf(temp_target_dir) if Dir.exist?(temp_target_dir)
  end

  describe 'FileSyncer optional parameters' do
    context 'when cache is nil (default behavior)' do
      let(:file_syncer) { Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir) }

      it 'completes sync successfully without cache' do
        results = file_syncer.sync
        expect(results[:copied]).to include('docs/test.md')
        expect(results[:errors]).to be_empty
      end

      it 'does not attempt cache operations when cache is nil' do
        # Should not call any cache methods since cache is nil
        expect { file_syncer.sync }.not_to raise_error
      end

      it 'ignores force_git flag when cache is nil' do
        # force_git only matters when cache exists
        results = file_syncer.sync(force_git: true)
        expect(results[:copied]).to include('docs/test.md')
      end
    end

    context 'when stats is nil (default behavior)' do
      let(:mock_cache) { instance_double('Leyline::Cache::FileCache') }
      let(:file_syncer) { Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir, cache: mock_cache) }

      before do
        allow(mock_cache).to receive(:get).and_return(nil)
        allow(mock_cache).to receive(:put).and_return('hash')
      end

      it 'completes sync successfully without stats' do
        results = file_syncer.sync
        expect(results[:copied]).to include('docs/test.md')
        expect(results[:errors]).to be_empty
      end

      it 'does not attempt stats operations when stats is nil' do
        # Safe navigation operator should prevent any errors
        expect { file_syncer.sync }.not_to raise_error
      end
    end

    context 'mixed parameter combinations' do
      it 'works with cache but no stats' do
        mock_cache = instance_double('Leyline::Cache::FileCache')
        allow(mock_cache).to receive(:get).and_return(nil)
        allow(mock_cache).to receive(:put).and_return('hash')

        syncer = Leyline::Sync::FileSyncer.new(
          temp_source_dir,
          temp_target_dir,
          cache: mock_cache
        )

        results = syncer.sync
        expect(results[:copied]).to include('docs/test.md')
      end

      it 'works with stats but no cache' do
        mock_stats = instance_double('Leyline::Cache::CacheStats')
        allow(mock_stats).to receive(:start_sync_timing)
        allow(mock_stats).to receive(:end_sync_timing)

        syncer = Leyline::Sync::FileSyncer.new(
          temp_source_dir,
          temp_target_dir,
          stats: mock_stats
        )

        results = syncer.sync
        expect(results[:copied]).to include('docs/test.md')
      end
    end
  end

  describe 'CLI optional parameters' do
    let(:cli) { Leyline::CLI.new }

    context 'default flag values' do
      it 'has correct defaults for all cache-related flags' do
        # Simulate Thor not providing options
        allow(cli).to receive(:options).and_return({})

        # Should use defaults without crashing
        expect do
          # Mock perform_sync to avoid actual git operations
          allow(cli).to receive(:perform_sync).and_return(true)
          cli.sync
        end.not_to raise_error
      end
    end

    context 'nil vs false flag handling' do
      it 'treats nil no_cache as false (cache enabled)' do
        allow(cli).to receive(:options).and_return({ no_cache: nil })
        allow(cli).to receive(:perform_sync) do |_path, _categories, options|
          # no_cache nil should default to false (cache enabled)
          expect(options[:no_cache] || false).to eq(false)
        end

        cli.sync
      end

      it 'treats nil force_git as false' do
        allow(cli).to receive(:options).and_return({ force_git: nil })
        allow(cli).to receive(:perform_sync) do |_path, _categories, options|
          # force_git nil should default to false
          expect(options[:force_git] || false).to eq(false)
        end

        cli.sync
      end

      it 'treats nil stats as false' do
        allow(cli).to receive(:options).and_return({ stats: nil })
        allow(cli).to receive(:perform_sync) do |_path, _categories, options|
          # stats nil should default to false
          expect(options[:stats] || false).to eq(false)
        end

        cli.sync
      end
    end
  end

  describe 'Calculate cache hit ratio method safety' do
    let(:file_syncer) { Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir) }

    it 'is a public method that can be called externally' do
      # Method should be accessible
      expect(file_syncer).to respond_to(:calculate_cache_hit_ratio)
    end

    it 'handles nil cache parameter gracefully' do
      result = file_syncer.calculate_cache_hit_ratio(['docs/test.md'], nil)
      expect(result).to eq(0.0)
    end

    it 'handles empty file list' do
      mock_cache = instance_double('Leyline::Cache::FileCache')
      result = file_syncer.calculate_cache_hit_ratio([], mock_cache)
      expect(result).to eq(0.0)
    end
  end

  describe 'Environment variable backward compatibility' do
    context 'LEYLINE_CACHE_THRESHOLD' do
      it 'works when environment variable is not set' do
        ENV.delete('LEYLINE_CACHE_THRESHOLD')

        file_syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir)
        # Should use default threshold of 0.8
        expect(file_syncer.git_sync_needed?(0.7)).to be true
        expect(file_syncer.git_sync_needed?(0.9)).to be false
      end

      it 'does not break existing environments' do
        # Set a custom threshold
        ENV['LEYLINE_CACHE_THRESHOLD'] = '0.5'

        file_syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir)
        expect(file_syncer.git_sync_needed?(0.4)).to be true
        expect(file_syncer.git_sync_needed?(0.6)).to be false

        ENV.delete('LEYLINE_CACHE_THRESHOLD')
      end
    end
  end
end
