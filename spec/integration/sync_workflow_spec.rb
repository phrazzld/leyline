# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'digest'
require 'leyline/sync_state'
require 'leyline/file_comparator'
require 'leyline/sync/file_syncer'

RSpec.describe 'Sync Workflow Integration', type: :integration do
  # Simple, focused test following Kent Beck's approach
  let(:cache_dir) { Dir.mktmpdir('leyline-cache') }
  let(:target_dir) { Dir.mktmpdir('leyline-target') }
  let(:source_dir) { Dir.mktmpdir('leyline-source') }

  # Minimal fixture data that expresses intent
  let(:base_state) do
    {
      'tenets/clarity.md' => "# Clarity\n\nVersion 1",
      'bindings/core/naming.md' => "# Naming\n\nStable content"
    }
  end

  let(:updated_state) do
    {
      'tenets/clarity.md' => "# Clarity\n\nVersion 2 - Updated",
      'bindings/core/naming.md' => "# Naming\n\nStable content",
      'bindings/core/testing.md' => "# Testing\n\nNew content"
    }
  end

  before do
    # Set up initial target state
    setup_directory(target_dir, base_state)

    # Save initial sync state (simulating previous sync)
    sync_state = Leyline::SyncState.new(cache_dir)
    manifest = create_manifest(target_dir, base_state)
    sync_state.save_sync_state({
      categories: ['core'],
      manifest: manifest,
      leyline_version: '2.1.0'
    })
  end

  after do
    [cache_dir, target_dir, source_dir].each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
  end

  describe 'status → diff → update workflow' do
    it 'detects changes through sync state comparison' do
      # STATUS: Compare current files with saved sync state
      sync_state = Leyline::SyncState.new(cache_dir)
      current_manifest = create_manifest(target_dir, base_state)

      # Verify we can load the saved state
      saved_state = sync_state.load_sync_state
      expect(saved_state).not_to be_nil
      expect(saved_state['manifest']).to eq(manifest_from_content(base_state))

      # No changes yet
      comparison = sync_state.compare_with_current_files(current_manifest)
      expect(comparison[:modified]).to be_empty
      expect(comparison[:added]).to be_empty
      expect(comparison[:removed]).to be_empty
    end

    it 'identifies differences when remote has updates' do
      # DIFF: Set up remote with changes
      setup_directory(source_dir, updated_state)

      # Create manifests for comparison
      local_manifest = create_manifest(target_dir, base_state)
      remote_manifest = create_manifest(source_dir, updated_state)

      # Use FileComparator to identify changes
      comparator = Leyline::FileComparator.new(base_directory: target_dir)

      # Simple comparison logic
      changes = {
        modified: [],
        added: [],
        unchanged: []
      }

      all_files = (base_state.keys + updated_state.keys).uniq
      all_files.each do |file|
        if !local_manifest[file] && remote_manifest[file]
          changes[:added] << file
        elsif local_manifest[file] && remote_manifest[file]
          if local_manifest[file] != remote_manifest[file]
            changes[:modified] << file
          else
            changes[:unchanged] << file
          end
        end
      end

      expect(changes[:modified]).to include('tenets/clarity.md')
      expect(changes[:added]).to include('bindings/core/testing.md')
      expect(changes[:unchanged]).to include('bindings/core/naming.md')
    end

    it 'applies updates using FileSyncer' do
      # UPDATE: Apply changes from source to target
      setup_directory(source_dir, updated_state)

      # Use FileSyncer to apply updates
      syncer = Leyline::Sync::FileSyncer.new(source_dir, target_dir)
      results = syncer.sync(force: true)

      # Verify sync results
      expect(results[:copied]).to include('tenets/clarity.md')
      expect(results[:copied]).to include('bindings/core/testing.md')
      expect(results[:errors]).to be_empty

      # Verify files were actually updated
      clarity_content = File.read(File.join(target_dir, 'tenets/clarity.md'))
      expect(clarity_content).to include('Version 2 - Updated')

      testing_path = File.join(target_dir, 'bindings/core/testing.md')
      expect(File.exist?(testing_path)).to be true
      expect(File.read(testing_path)).to include('New content')
    end

    it 'updates sync state after successful sync' do
      # Complete workflow with state update
      setup_directory(source_dir, updated_state)

      # Apply updates
      syncer = Leyline::Sync::FileSyncer.new(source_dir, target_dir)
      results = syncer.sync(force: true)

      # Update sync state
      sync_state = Leyline::SyncState.new(cache_dir)
      new_manifest = create_manifest(target_dir, updated_state)

      sync_state.save_sync_state({
        categories: ['core'],
        manifest: new_manifest,
        leyline_version: '2.2.0'
      })

      # Verify state was updated
      loaded_state = sync_state.load_sync_state
      expect(loaded_state['leyline_version']).to eq('2.2.0')
      expect(loaded_state['manifest']['bindings/core/testing.md']).not_to be_nil
    end

    context 'with conflicts' do
      it 'detects local modifications that conflict with remote' do
        # Modify local file
        clarity_path = File.join(target_dir, 'tenets/clarity.md')
        File.write(clarity_path, "# Clarity\n\nLocal modification")

        # Load baseline state
        sync_state = Leyline::SyncState.new(cache_dir)
        baseline_state = sync_state.load_sync_state

        # Check current vs baseline
        current_manifest = create_manifest(target_dir, {
          'tenets/clarity.md' => File.read(clarity_path),
          'bindings/core/naming.md' => base_state['bindings/core/naming.md']
        })

        comparison = sync_state.compare_with_current_files(current_manifest)
        expect(comparison[:modified]).to include('tenets/clarity.md')

        # Now simulate remote also having changes
        remote_manifest = manifest_from_content(updated_state)

        # Both modified the same file = conflict
        locally_modified = Set.new(comparison[:modified])
        remotely_modified = updated_state.keys.select { |k|
          base_state[k] && updated_state[k] != base_state[k]
        }

        conflicts = locally_modified & remotely_modified
        expect(conflicts).to include('tenets/clarity.md')
      end
    end

    context 'performance characteristics' do
      it 'completes sync workflow in reasonable time for typical repository' do
        # Create a more realistic set of files
        realistic_content = {}
        20.times do |i|
          realistic_content["tenets/tenet_#{i}.md"] = "# Tenet #{i}\n\nContent for tenet #{i}"
          realistic_content["bindings/core/binding_#{i}.md"] = "# Binding #{i}\n\nBinding content #{i}"
        end

        setup_directory(source_dir, realistic_content)

        start_time = Time.now

        # Perform sync
        syncer = Leyline::Sync::FileSyncer.new(source_dir, target_dir)
        results = syncer.sync(force: true)

        # Update sync state
        sync_state = Leyline::SyncState.new(cache_dir)
        manifest = create_manifest(target_dir, realistic_content)
        sync_state.save_sync_state({
          categories: ['core'],
          manifest: manifest,
          leyline_version: '2.1.0'
        })

        duration = Time.now - start_time

        expect(results[:errors]).to be_empty
        expect(results[:copied].size).to eq(40)
        expect(duration).to be < 1.0  # Should complete in under 1 second
      end
    end

    context 'cache-aware optimization' do
      it 'skips sync when cache hit ratio is high' do
        # Set up cache-aware sync
        require 'leyline/cache/file_cache'
        cache = Leyline::Cache::FileCache.new(cache_dir)

        # Clear target directory for this test
        FileUtils.rm_rf(target_dir)
        FileUtils.mkdir_p(target_dir)

        # First sync to populate cache
        setup_directory(source_dir, base_state)
        syncer = Leyline::Sync::FileSyncer.new(source_dir, target_dir, cache: cache)
        first_results = syncer.sync(force: true)

        expect(first_results[:copied]).not_to be_empty
        expect(first_results[:copied].size).to eq(2)

        # Second sync with same content should use cache optimization
        ENV['LEYLINE_CACHE_THRESHOLD'] = '0.8'

        # FileSyncer checks cache before git operations
        # With high cache hit ratio and files already in target, it should skip
        second_syncer = Leyline::Sync::FileSyncer.new(source_dir, target_dir, cache: cache)
        second_results = second_syncer.sync

        # All files should be skipped since they're identical
        expect(second_results[:skipped].size).to eq(2)
        expect(second_results[:copied]).to be_empty

        ENV.delete('LEYLINE_CACHE_THRESHOLD')
      end
    end
  end

  private

  def setup_directory(dir, content_map)
    content_map.each do |path, content|
      full_path = File.join(dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end
  end

  def create_manifest(base_dir, content_map)
    manifest = {}
    content_map.each do |path, _|
      full_path = File.join(base_dir, path)
      if File.exist?(full_path)
        content = File.read(full_path)
        manifest[path] = Digest::SHA256.hexdigest(content)
      end
    end
    manifest
  end

  def manifest_from_content(content_map)
    content_map.transform_values { |content| Digest::SHA256.hexdigest(content) }
  end
end
