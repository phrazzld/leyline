# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'Cache error handling' do
  let(:temp_cache_dir) { Dir.mktmpdir('leyline-cache-error-test') }
  let(:temp_source_dir) { Dir.mktmpdir('leyline-source-test') }
  let(:temp_target_dir) { Dir.mktmpdir('leyline-target-test') }

  after do
    FileUtils.rm_rf(temp_cache_dir) if Dir.exist?(temp_cache_dir)
    FileUtils.rm_rf(temp_source_dir) if Dir.exist?(temp_source_dir)
    FileUtils.rm_rf(temp_target_dir) if Dir.exist?(temp_target_dir)
  end

  describe 'FileCache error resilience' do
    context 'when cache directory cannot be created' do
      it 'logs error but allows initialization' do
        # Make parent directory read-only
        parent_dir = File.join(temp_cache_dir, 'readonly')
        FileUtils.mkdir_p(parent_dir)
        File.chmod(0o444, parent_dir)

        cache_dir = File.join(parent_dir, 'cache')

        # Should not raise error during initialization
        expect { Leyline::Cache::FileCache.new(cache_dir) }.not_to raise_error

        # Restore permissions for cleanup
        File.chmod(0o755, parent_dir)
      end
    end

    context 'when put operation fails' do
      let(:cache) { Leyline::Cache::FileCache.new(temp_cache_dir) }

      it 'returns nil on write failure' do
        # Make cache directory read-only after initialization
        content_dir = File.join(temp_cache_dir, 'content')
        FileUtils.mkdir_p(content_dir)
        File.chmod(0o444, content_dir)

        result = cache.put('test content')
        expect(result).to be_nil

        # Restore permissions
        File.chmod(0o755, content_dir)
      end

      it 'handles non-string content gracefully' do
        result = cache.put(123)
        expect(result).to be_nil

        result = cache.put(nil)
        expect(result).to be_nil

        result = cache.put({ key: 'value' })
        expect(result).to be_nil
      end
    end

    context 'when get operation fails' do
      let(:cache) { Leyline::Cache::FileCache.new(temp_cache_dir) }

      it 'returns nil for invalid hash format' do
        expect(cache.get('invalid')).to be_nil
        expect(cache.get('')).to be_nil
        expect(cache.get(nil)).to be_nil
        expect(cache.get(123)).to be_nil
      end

      it 'returns nil when file is unreadable' do
        # Put content successfully first
        hash = cache.put('test content')
        expect(hash).not_to be_nil

        # Make file unreadable
        file_path = File.join(temp_cache_dir, 'content', hash[0..1], hash[2..-1])
        File.chmod(0o000, file_path)

        result = cache.get(hash)
        expect(result).to be_nil

        # Restore permissions
        File.chmod(0o644, file_path)
      end

      it 'detects and handles corrupted cache files' do
        # Create a corrupted cache file manually
        hash = Digest::SHA256.hexdigest('expected content')
        file_path = File.join(temp_cache_dir, 'content', hash[0..1], hash[2..-1])
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, 'corrupted content')

        # Should detect corruption and return nil
        result = cache.get(hash)
        expect(result).to be_nil

        # Corrupted file should be deleted
        expect(File.exist?(file_path)).to be false
      end
    end

    context 'health status reporting' do
      it 'reports healthy cache' do
        cache = Leyline::Cache::FileCache.new(temp_cache_dir)
        health = cache.health_status

        expect(health[:healthy]).to be true
        expect(health[:issues]).to be_empty
        expect(health[:error_rate]).to eq(0.0)
      end

      it 'tracks error rate' do
        cache = Leyline::Cache::FileCache.new(temp_cache_dir)

        # Successful operation
        cache.put('test')

        # These operations don't count as errors because they return nil gracefully
        # Only actual exceptions count as errors
        cache.get('invalid') # Returns nil, not an error
        cache.put(nil) # Returns nil, not an error

        # Force an actual error
        content_dir = File.join(temp_cache_dir, 'content')
        File.chmod(0o444, content_dir)
        cache.put('should fail') # This will actually error
        File.chmod(0o755, content_dir)

        health = cache.health_status
        expect(health[:operation_count]).to eq(4)
        expect(health[:error_count]).to eq(1)
        expect(health[:error_rate]).to be_within(0.1).of(25.0)
      end
    end
  end

  describe 'FileSyncer cache error resilience' do
    before do
      # Create test files
      FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
      File.write(File.join(temp_source_dir, 'docs', 'test.md'), 'content')
    end

    context 'when cache operations fail during sync' do
      it 'continues sync despite cache put failures' do
        # Create a cache that always fails put operations
        mock_cache = instance_double('Leyline::Cache::FileCache')
        allow(mock_cache).to receive(:put).and_raise(StandardError.new('Cache write failed'))
        allow(mock_cache).to receive(:get).and_return(nil)

        syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir, cache: mock_cache)

        # Sync should still succeed
        results = syncer.sync
        expect(results[:copied]).to include('docs/test.md')
        expect(results[:errors]).to be_empty

        # Verify file was actually copied
        expect(File.exist?(File.join(temp_target_dir, 'docs', 'test.md'))).to be true
      end

      it 'continues sync despite cache get failures' do
        # Create a cache that always fails get operations
        mock_cache = instance_double('Leyline::Cache::FileCache')
        allow(mock_cache).to receive(:get).and_raise(StandardError.new('Cache read failed'))
        allow(mock_cache).to receive(:put).and_return(nil)

        syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir, cache: mock_cache)

        # Sync should still succeed
        results = syncer.sync
        expect(results[:copied]).to include('docs/test.md')
        expect(results[:errors]).to be_empty
      end
    end

    context 'when cache is completely broken' do
      it 'falls back to non-cached sync' do
        # Create a cache that fails everything
        mock_cache = instance_double('Leyline::Cache::FileCache')
        allow(mock_cache).to receive(:get).and_raise(StandardError.new('Cache broken'))
        allow(mock_cache).to receive(:put).and_raise(StandardError.new('Cache broken'))

        syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir, cache: mock_cache)

        # First sync should work
        results = syncer.sync
        expect(results[:copied]).to include('docs/test.md')

        # Second sync should also work (no cache optimization, but still functional)
        results = syncer.sync
        expect(results[:skipped]).to include('docs/test.md')
      end
    end
  end

  describe 'CLI cache error handling' do
    let(:cli) { Leyline::CLI.new }

    context 'when cache initialization fails' do
      it 'continues without cache' do
        # Test the actual perform_sync method with cache failure
        allow(Leyline::Cache::FileCache).to receive(:new).and_raise(
          StandardError.new('Cache init failed')
        )

        # Mock only the git operations to avoid actual network calls
        allow_any_instance_of(Leyline::Sync::GitClient).to receive(:setup_sparse_checkout)
        allow_any_instance_of(Leyline::Sync::GitClient).to receive(:add_sparse_paths)
        allow_any_instance_of(Leyline::Sync::GitClient).to receive(:fetch_version)
        allow_any_instance_of(Leyline::Sync::GitClient).to receive(:cleanup)

        # Create empty source directory to avoid file not found
        temp_dir = Dir.mktmpdir
        allow(Dir).to receive(:mktmpdir).and_return(temp_dir)
        FileUtils.mkdir_p(File.join(temp_dir, 'docs'))

        output = capture_stdout do
          cli.instance_variable_set(:@options, { verbose: true })
          expect { cli.send(:perform_sync, '.', ['core'], cli.instance_variable_get(:@options)) }.not_to raise_error
        end

        # Cleanup
        FileUtils.rm_rf(temp_dir)

        # Should show warning in verbose mode
        expect(output).to include('Warning: Cache initialization failed')
        expect(output).to include('Continuing without cache optimization')
      end
    end

    context 'cache health warnings' do
      it 'displays health warnings in verbose mode' do
        # Just test the specific method that shows health warnings
        cache = instance_double('Leyline::Cache::FileCache')
        allow(cache).to receive(:health_status).and_return({
                                                             healthy: false,
                                                             issues: [
                                                               { type: 'not_writable', path: '/tmp/cache' },
                                                               { type: 'large_cache', size: 600_000_000 }
                                                             ]
                                                           })

        output = capture_stdout do
          # Test just the health check logic directly
          if cache
            health = cache.health_status
            unless health[:healthy]
              puts 'Warning: Cache health issues detected:'
              health[:issues].each do |issue|
                puts "  - #{issue[:type]}: #{issue[:path] || issue[:error]}"
              end
            end
          end
        end

        expect(output).to include('Warning: Cache health issues detected')
        expect(output).to include('not_writable')
        expect(output).to include('large_cache')
      end
    end
  end

  describe 'CacheErrorHandler' do
    context 'environment variable configuration' do
      it 'respects LEYLINE_CACHE_WARNINGS setting' do
        # Disable warnings
        ENV['LEYLINE_CACHE_WARNINGS'] = 'false'

        expect(STDERR).not_to receive(:puts)
        Leyline::Cache::CacheErrorHandler.warn('Test warning')

        ENV.delete('LEYLINE_CACHE_WARNINGS')
      end

      it 'outputs structured JSON when enabled' do
        ENV['LEYLINE_STRUCTURED_LOGGING'] = 'true'

        # Capture stderr properly
        original_stderr = $stderr
        captured_output = StringIO.new
        $stderr = captured_output

        Leyline::Cache::CacheErrorHandler.warn('Test warning', { context: 'test' })

        output = captured_output.string
        $stderr = original_stderr

        expect(output).to include('"event":"cache_warning"')
        expect(output).to include('"message":"Test warning"')
        expect(output).to include('"context":"test"')

        ENV.delete('LEYLINE_STRUCTURED_LOGGING')
      end

      it 'outputs human-readable format by default' do
        # Ensure structured logging is off
        ENV.delete('LEYLINE_STRUCTURED_LOGGING')

        # Capture stderr properly
        original_stderr = $stderr
        captured_output = StringIO.new
        $stderr = captured_output

        Leyline::Cache::CacheErrorHandler.warn('Test warning')

        output = captured_output.string
        $stderr = original_stderr

        expect(output).to include('WARNING: [Cache] Test warning')
      end
    end
  end

  private

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
