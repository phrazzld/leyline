# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'digest'
require 'leyline/sync_state'

RSpec.describe Leyline::SyncState do
  let(:temp_cache_dir) { Dir.mktmpdir('leyline-sync-state-test') }
  let(:sync_state) { described_class.new(temp_cache_dir) }
  let(:valid_metadata) do
    {
      categories: %w[core typescript],
      manifest: {
        'tenets/clarity.md' => 'a' * 64,
        'bindings/core/naming.md' => 'b' * 64
      },
      leyline_version: '2.1.0',
      cache_hit_ratio: 0.85,
      sync_duration_ms: 1200
    }
  end

  after do
    FileUtils.rm_rf(temp_cache_dir) if Dir.exist?(temp_cache_dir)
  end

  describe '#initialize' do
    it 'uses provided cache directory' do
      custom_dir = '/tmp/custom-cache'
      state = described_class.new(custom_dir)
      expect(state.cache_directory).to eq(custom_dir)
    end

    it 'uses environment variable when no cache_dir provided' do
      ENV['LEYLINE_CACHE_DIR'] = '/tmp/env-cache'
      state = described_class.new
      expect(state.cache_directory).to eq('/tmp/env-cache')
      ENV.delete('LEYLINE_CACHE_DIR')
    end

    it 'uses default cache directory when no override' do
      ENV.delete('LEYLINE_CACHE_DIR')
      state = described_class.new
      expect(state.cache_directory).to eq(File.expand_path('~/.cache/leyline'))
    end

    it 'expands tilde in cache directory path' do
      state = described_class.new('~/test-cache')
      expect(state.cache_directory).to eq(File.expand_path('~/test-cache'))
    end
  end

  describe '#save_sync_state' do
    it 'saves valid metadata to YAML file' do
      result = sync_state.save_sync_state(valid_metadata)
      expect(result).to be true
      expect(sync_state.state_exists?).to be true
    end

    it 'creates cache directory if it does not exist' do
      new_cache_dir = File.join(temp_cache_dir, 'nested', 'cache')
      state = described_class.new(new_cache_dir)

      result = state.save_sync_state(valid_metadata)
      expect(result).to be true
      expect(Dir.exist?(new_cache_dir)).to be true
    end

    it 'includes all required metadata fields' do
      sync_state.save_sync_state(valid_metadata)
      state_data = YAML.safe_load(File.read(sync_state.state_file_path), permitted_classes: [Time])

      expect(state_data['version']).to eq(1)
      expect(state_data['timestamp']).to be_a(String)
      expect(state_data['leyline_version']).to eq('2.1.0')
      expect(state_data['categories']).to eq(%w[core typescript])
      expect(state_data['manifest']).to eq(valid_metadata[:manifest])
    end

    it 'includes optional performance metadata' do
      sync_state.save_sync_state(valid_metadata)
      state_data = YAML.safe_load(File.read(sync_state.state_file_path), permitted_classes: [Time])

      expect(state_data['metadata']['total_files']).to eq(2)
      expect(state_data['metadata']['cache_hit_ratio']).to eq(0.85)
      expect(state_data['metadata']['sync_duration_ms']).to eq(1200)
    end

    it 'uses atomic write operations' do
      # Verify temp file is used and cleaned up
      temp_file_path = "#{sync_state.state_file_path}.tmp"

      sync_state.save_sync_state(valid_metadata)

      expect(File.exist?(temp_file_path)).to be false
      expect(File.exist?(sync_state.state_file_path)).to be true
    end

    context 'validation errors' do
      it 'rejects nil metadata' do
        expect do
          sync_state.save_sync_state(nil)
        end.to raise_error(Leyline::SyncState::SyncStateError, 'Metadata cannot be nil')
      end

      it 'rejects invalid categories' do
        invalid_metadata = valid_metadata.merge(categories: 'not_array')
        expect do
          sync_state.save_sync_state(invalid_metadata)
        end.to raise_error(Leyline::SyncState::SyncStateError, 'Categories must be an array')
      end

      it 'rejects invalid manifest' do
        invalid_metadata = valid_metadata.merge(manifest: 'not_hash')
        expect do
          sync_state.save_sync_state(invalid_metadata)
        end.to raise_error(Leyline::SyncState::SyncStateError, 'Manifest must be a hash')
      end

      it 'rejects invalid SHA256 hashes' do
        invalid_metadata = valid_metadata.merge(
          manifest: { 'file.md' => 'invalid_hash' }
        )
        expect do
          sync_state.save_sync_state(invalid_metadata)
        end.to raise_error(Leyline::SyncState::SyncStateError, /Invalid hash for file/)
      end
    end

    context 'file system errors' do
      it 'handles write permission errors gracefully' do
        # Make directory read-only after creation
        FileUtils.mkdir_p(temp_cache_dir)
        File.chmod(0o444, temp_cache_dir)

        result = sync_state.save_sync_state(valid_metadata)
        expect(result).to be false

        # Restore permissions for cleanup
        File.chmod(0o755, temp_cache_dir)
      end

      it 'cleans up temp file on write failure' do
        # Simulate write failure by making directory read-only
        FileUtils.mkdir_p(temp_cache_dir)
        File.chmod(0o444, temp_cache_dir)

        sync_state.save_sync_state(valid_metadata)
        temp_file = "#{sync_state.state_file_path}.tmp"
        expect(File.exist?(temp_file)).to be false

        File.chmod(0o755, temp_cache_dir)
      end
    end
  end

  describe '#load_sync_state' do
    it 'loads valid state data' do
      sync_state.save_sync_state(valid_metadata)
      loaded_state = sync_state.load_sync_state

      expect(loaded_state).to be_a(Hash)
      expect(loaded_state['categories']).to eq(%w[core typescript])
      expect(loaded_state['manifest']).to eq(valid_metadata[:manifest])
    end

    it 'returns nil when state file does not exist' do
      expect(sync_state.load_sync_state).to be_nil
    end

    it 'validates loaded state structure' do
      # Create invalid state file
      File.write(sync_state.state_file_path, { invalid: 'structure' }.to_yaml)

      expect(sync_state.load_sync_state).to be_nil
    end

    it 'handles YAML parsing errors' do
      # Create malformed YAML file
      FileUtils.mkdir_p(temp_cache_dir)
      File.write(sync_state.state_file_path, 'invalid: yaml: content: [')

      expect(sync_state.load_sync_state).to be_nil
    end

    it 'validates schema version compatibility' do
      # Create state with incompatible version
      incompatible_state = {
        'version' => 999,
        'timestamp' => Time.now.iso8601,
        'categories' => ['core'],
        'manifest' => {}
      }
      File.write(sync_state.state_file_path, incompatible_state.to_yaml)

      expect(sync_state.load_sync_state).to be_nil
    end

    it 'handles file read permission errors' do
      sync_state.save_sync_state(valid_metadata)

      # Make file unreadable
      File.chmod(0o000, sync_state.state_file_path)

      expect(sync_state.load_sync_state).to be_nil

      # Restore permissions
      File.chmod(0o644, sync_state.state_file_path)
    end
  end

  describe '#state_exists?' do
    it 'returns true when state file exists' do
      sync_state.save_sync_state(valid_metadata)
      expect(sync_state.state_exists?).to be true
    end

    it 'returns false when state file does not exist' do
      expect(sync_state.state_exists?).to be false
    end
  end

  describe '#clear_sync_state' do
    it 'removes existing state file' do
      sync_state.save_sync_state(valid_metadata)
      expect(sync_state.state_exists?).to be true

      result = sync_state.clear_sync_state
      expect(result).to be true
      expect(sync_state.state_exists?).to be false
    end

    it 'returns true when no state file exists' do
      expect(sync_state.state_exists?).to be false
      result = sync_state.clear_sync_state
      expect(result).to be true
    end

    it 'handles file deletion errors gracefully' do
      sync_state.save_sync_state(valid_metadata)

      # Mock File.delete to simulate permission error
      allow(File).to receive(:delete).with(sync_state.state_file_path).and_raise(Errno::EACCES.new('Permission denied'))

      result = sync_state.clear_sync_state
      expect(result).to be false
    end
  end

  describe '#state_age_seconds' do
    it 'returns age in seconds for existing state' do
      sync_state.save_sync_state(valid_metadata)

      # Small delay to ensure measurable age
      sleep 0.1

      age = sync_state.state_age_seconds
      expect(age).to be_a(Numeric)
      expect(age).to be > 0
      expect(age).to be < 10 # Should be very recent
    end

    it 'returns nil when state does not exist' do
      expect(sync_state.state_age_seconds).to be_nil
    end

    it 'handles file stat errors gracefully' do
      sync_state.save_sync_state(valid_metadata)

      # Remove file after creation to simulate stat error
      File.delete(sync_state.state_file_path)

      expect(sync_state.state_age_seconds).to be_nil
    end
  end

  describe '#state_file_path' do
    it 'returns correct state file path' do
      expected_path = File.join(temp_cache_dir, 'sync_state.yaml')
      expect(sync_state.state_file_path).to eq(expected_path)
    end
  end

  describe '#compare_with_current_files' do
    let(:base_manifest) do
      {
        'tenets/clarity.md' => 'a' * 64,
        'bindings/core/naming.md' => 'b' * 64,
        'bindings/typescript/types.md' => 'c' * 64
      }
    end

    let(:current_manifest) do
      {
        'tenets/clarity.md' => 'a' * 64,        # unchanged
        'bindings/core/naming.md' => 'd' * 64,  # modified
        'bindings/go/errors.md' => 'e' * 64     # added
        # bindings/typescript/types.md removed
      }
    end

    before do
      metadata = valid_metadata.merge(manifest: base_manifest)
      sync_state.save_sync_state(metadata)
    end

    it 'detects added files' do
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison[:added]).to contain_exactly('bindings/go/errors.md')
    end

    it 'detects removed files' do
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison[:removed]).to contain_exactly('bindings/typescript/types.md')
    end

    it 'detects modified files' do
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison[:modified]).to contain_exactly('bindings/core/naming.md')
    end

    it 'detects unchanged files' do
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison[:unchanged]).to contain_exactly('tenets/clarity.md')
    end

    it 'includes base metadata' do
      comparison = sync_state.compare_with_current_files(current_manifest)

      expect(comparison[:base_timestamp]).to be_a(String)
      expect(comparison[:base_version]).to eq('2.1.0')
      expect(comparison[:base_categories]).to eq(%w[core typescript])
    end

    it 'returns nil when no valid state exists' do
      sync_state.clear_sync_state
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison).to be_nil
    end

    it 'returns nil when state has no manifest' do
      # Create state without manifest
      invalid_state = {
        'version' => 1,
        'timestamp' => Time.now.iso8601,
        'categories' => ['core'],
        'leyline_version' => '2.1.0'
      }
      File.write(sync_state.state_file_path, invalid_state.to_yaml)

      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison).to be_nil
    end
  end

  describe 'error handling integration' do
    it 'uses CacheErrorHandler for all errors' do
      expect(Leyline::Cache::CacheErrorHandler).to receive(:handle_error).at_least(:once)

      # Force an error by using a read-only parent directory
      readonly_parent = File.join(temp_cache_dir, 'readonly')
      FileUtils.mkdir_p(readonly_parent)
      File.chmod(0o444, readonly_parent)

      invalid_dir = File.join(readonly_parent, 'cache')
      state = described_class.new(invalid_dir)

      # Should call CacheErrorHandler.handle_error and then raise SyncStateError
      expect do
        state.save_sync_state(valid_metadata)
      end.to raise_error(Leyline::SyncState::SyncStateError, /Failed to create cache directory/)

      # Restore permissions for cleanup
      File.chmod(0o755, readonly_parent)
    end
  end

  describe 'performance characteristics' do
    it 'saves and loads state quickly for typical manifests' do
      large_manifest = {}
      100.times do |i|
        large_manifest["file_#{i}.md"] = Digest::SHA256.hexdigest("content_#{i}")
      end

      large_metadata = valid_metadata.merge(manifest: large_manifest)

      # Measure save performance
      save_start = Time.now
      sync_state.save_sync_state(large_metadata)
      save_time = Time.now - save_start

      # Measure load performance
      load_start = Time.now
      loaded_state = sync_state.load_sync_state
      load_time = Time.now - load_start

      expect(save_time).to be < 0.1 # 100ms
      expect(load_time).to be < 0.1 # 100ms
      expect(loaded_state['manifest'].size).to eq(100)
    end

    it 'handles comparison of large manifests efficiently' do
      large_base = {}
      large_current = {}

      500.times do |i|
        hash = Digest::SHA256.hexdigest("content_#{i}")
        large_base["file_#{i}.md"] = hash

        # Create current manifest with some changes
        if i < 400
          large_current["file_#{i}.md"] = hash # unchanged
        elsif i < 450
          large_current["file_#{i}.md"] = Digest::SHA256.hexdigest("modified_#{i}") # modified
        end
        # files 450-499 are removed
      end

      # Add some new files
      10.times do |i|
        large_current["new_file_#{i}.md"] = Digest::SHA256.hexdigest("new_content_#{i}")
      end

      metadata = valid_metadata.merge(manifest: large_base)
      sync_state.save_sync_state(metadata)

      start_time = Time.now
      comparison = sync_state.compare_with_current_files(large_current)
      comparison_time = Time.now - start_time

      expect(comparison_time).to be < 0.2 # 200ms for 500+ files
      expect(comparison[:unchanged].size).to eq(400)
      expect(comparison[:modified].size).to eq(50)
      expect(comparison[:removed].size).to eq(50)
      expect(comparison[:added].size).to eq(10)
    end
  end
end
