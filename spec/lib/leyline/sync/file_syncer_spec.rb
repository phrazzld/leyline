# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe Leyline::Sync::FileSyncer do
  let(:temp_source_dir) { Dir.mktmpdir('leyline-test-source') }
  let(:temp_target_dir) { Dir.mktmpdir('leyline-test-target') }
  let(:mock_cache) { instance_double('Leyline::Cache::FileCache') }

  after do
    FileUtils.rm_rf(temp_source_dir) if Dir.exist?(temp_source_dir)
    FileUtils.rm_rf(temp_target_dir) if Dir.exist?(temp_target_dir)
  end

  describe '#git_sync_needed?' do
    let(:file_syncer) { described_class.new(temp_source_dir, temp_target_dir, cache: mock_cache) }

    context 'with default threshold (0.8)' do
      before do
        # Clear environment variable to use default
        ENV.delete('LEYLINE_CACHE_THRESHOLD')
      end

      it 'returns true when cache hit ratio is below threshold' do
        result = file_syncer.git_sync_needed?(0.7)
        expect(result).to be true
      end

      it 'returns false when cache hit ratio meets threshold' do
        result = file_syncer.git_sync_needed?(0.8)
        expect(result).to be false
      end

      it 'returns false when cache hit ratio exceeds threshold' do
        result = file_syncer.git_sync_needed?(0.9)
        expect(result).to be false
      end
    end

    context 'with custom threshold via environment variable' do
      before do
        ENV['LEYLINE_CACHE_THRESHOLD'] = '0.5'
      end

      after do
        ENV.delete('LEYLINE_CACHE_THRESHOLD')
      end

      it 'uses custom threshold from environment' do
        # Below custom threshold
        expect(file_syncer.git_sync_needed?(0.4)).to be true

        # At custom threshold
        expect(file_syncer.git_sync_needed?(0.5)).to be false

        # Above custom threshold
        expect(file_syncer.git_sync_needed?(0.6)).to be false
      end
    end

    context 'with force_git flag' do
      it 'always returns true when force_git is true, regardless of cache hit ratio' do
        expect(file_syncer.git_sync_needed?(1.0, force_git: true)).to be true
        expect(file_syncer.git_sync_needed?(0.9, force_git: true)).to be true
        expect(file_syncer.git_sync_needed?(0.0, force_git: true)).to be true
      end

      it 'respects threshold when force_git is false' do
        expect(file_syncer.git_sync_needed?(0.9, force_git: false)).to be false
        expect(file_syncer.git_sync_needed?(0.7, force_git: false)).to be true
      end
    end

    context 'with invalid environment variable' do
      before do
        ENV['LEYLINE_CACHE_THRESHOLD'] = 'invalid'
      end

      after do
        ENV.delete('LEYLINE_CACHE_THRESHOLD')
      end

      it 'falls back to git sync on conversion error' do
        result = file_syncer.git_sync_needed?(0.9)
        expect(result).to be true  # Fail safe
      end
    end

    context 'when environment fetch fails' do
      it 'falls back to git sync on error' do
        allow(ENV).to receive(:fetch).and_raise(StandardError.new('Env error'))

        result = file_syncer.git_sync_needed?(0.9)
        expect(result).to be true  # Fail safe
      end
    end
  end

  describe '#calculate_cache_hit_ratio' do
    let(:file_syncer) { described_class.new(temp_source_dir, temp_target_dir, cache: mock_cache) }

    context 'when cache is nil' do
      let(:file_syncer_no_cache) { described_class.new(temp_source_dir, temp_target_dir, cache: nil) }

      it 'returns 0.0' do
        target_files = ['file1.txt', 'file2.txt']
        result = file_syncer_no_cache.calculate_cache_hit_ratio(target_files, nil)
        expect(result).to eq(0.0)
      end
    end

    context 'when target_files is empty' do
      it 'returns 0.0' do
        result = file_syncer.calculate_cache_hit_ratio([], mock_cache)
        expect(result).to eq(0.0)
      end
    end

    context 'with valid files and cache' do
      let(:target_files) { ['docs/file1.md', 'docs/file2.md', 'docs/file3.md'] }

      before do
        # Create source files with known content
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
        File.write(File.join(temp_source_dir, 'docs', 'file2.md'), 'content2')
        File.write(File.join(temp_source_dir, 'docs', 'file3.md'), 'content3')
      end

      context 'when all files are cache hits' do
        it 'returns 1.0' do
          # Mock cache to return content for all files
          allow(mock_cache).to receive(:get).and_return('cached_content')

          result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
          expect(result).to eq(1.0)
        end
      end

      context 'when no files are cache hits' do
        it 'returns 0.0' do
          # Mock cache to return nil for all files (cache miss)
          allow(mock_cache).to receive(:get).and_return(nil)

          result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
          expect(result).to eq(0.0)
        end
      end

      context 'when partial files are cache hits' do
        it 'returns correct ratio (2/3 = 0.67)' do
          # Mock cache to return content for first two files, nil for third
          allow(mock_cache).to receive(:get).with(
            Digest::SHA256.hexdigest('content1')
          ).and_return('cached_content1')

          allow(mock_cache).to receive(:get).with(
            Digest::SHA256.hexdigest('content2')
          ).and_return('cached_content2')

          allow(mock_cache).to receive(:get).with(
            Digest::SHA256.hexdigest('content3')
          ).and_return(nil)

          result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
          expect(result).to be_within(0.01).of(0.67)
        end
      end
    end

    context 'when source files are missing' do
      let(:target_files) { ['missing_file.txt', 'docs/file1.md'] }

      before do
        # Only create one of the files
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'treats missing files as cache misses' do
        # Mock cache to return content for existing file
        allow(mock_cache).to receive(:get).with(
          Digest::SHA256.hexdigest('content1')
        ).and_return('cached_content')

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.5)  # 1 hit out of 2 files
      end
    end

    context 'when file read fails' do
      let(:target_files) { ['docs/file1.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'treats read errors as cache misses' do
        # Mock File.read to raise an error
        allow(File).to receive(:read).and_raise(StandardError.new('Read failed'))

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.0)
      end
    end

    context 'when cache operations fail' do
      let(:target_files) { ['docs/file1.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'returns 0.0 on cache errors' do
        # Mock cache.get to raise an error
        allow(mock_cache).to receive(:get).and_raise(StandardError.new('Cache error'))

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.0)
      end
    end

    context 'when SHA256 computation fails' do
      let(:target_files) { ['docs/file1.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'returns 0.0 on digest errors' do
        # Mock Digest::SHA256.hexdigest to raise an error
        allow(Digest::SHA256).to receive(:hexdigest).and_raise(StandardError.new('Digest error'))

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.0)
      end
    end

    context 'stats integration' do
      let(:mock_stats) { instance_double('Leyline::Cache::CacheStats') }
      let(:file_syncer_with_stats) { described_class.new(temp_source_dir, temp_target_dir, cache: mock_cache, stats: mock_stats) }
      let(:target_files) { ['docs/file1.md', 'docs/file2.md', 'docs/file3.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
        File.write(File.join(temp_source_dir, 'docs', 'file2.md'), 'content2')
        File.write(File.join(temp_source_dir, 'docs', 'file3.md'), 'content3')
      end

      it 'records cache hits correctly in stats' do
        # Mock cache to return content for all files (all hits)
        allow(mock_cache).to receive(:get).and_return('cached_content')

        # Expect stats to record 3 cache hits
        expect(mock_stats).to receive(:record_cache_hit).exactly(3).times
        expect(mock_stats).not_to receive(:record_cache_miss)

        result = file_syncer_with_stats.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(1.0)
      end

      it 'records cache misses correctly in stats' do
        # Mock cache to return nil for all files (all misses)
        allow(mock_cache).to receive(:get).and_return(nil)

        # Expect stats to record 3 cache misses
        expect(mock_stats).to receive(:record_cache_miss).exactly(3).times
        expect(mock_stats).not_to receive(:record_cache_hit)

        result = file_syncer_with_stats.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.0)
      end

      it 'records mixed hits and misses correctly in stats' do
        # Mock cache for partial hits (2 hits, 1 miss)
        allow(mock_cache).to receive(:get).with(
          Digest::SHA256.hexdigest('content1')
        ).and_return('cached_content1')

        allow(mock_cache).to receive(:get).with(
          Digest::SHA256.hexdigest('content2')
        ).and_return('cached_content2')

        allow(mock_cache).to receive(:get).with(
          Digest::SHA256.hexdigest('content3')
        ).and_return(nil)

        # Expect stats to record 2 hits and 1 miss
        expect(mock_stats).to receive(:record_cache_hit).exactly(2).times
        expect(mock_stats).to receive(:record_cache_miss).exactly(1).times

        result = file_syncer_with_stats.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to be_within(0.01).of(0.67)
      end

      it 'records cache miss when file read fails' do
        # Make first file unreadable
        allow(File).to receive(:read).with(File.join(temp_source_dir, 'docs', 'file1.md')).and_raise(StandardError.new('Read failed'))
        allow(File).to receive(:read).with(File.join(temp_source_dir, 'docs', 'file2.md')).and_return('content2')
        allow(File).to receive(:read).with(File.join(temp_source_dir, 'docs', 'file3.md')).and_return('content3')

        allow(mock_cache).to receive(:get).and_return('cached_content')

        # Expect 1 miss (failed read) and 2 hits (successful reads with cache)
        expect(mock_stats).to receive(:record_cache_miss).exactly(1).times
        expect(mock_stats).to receive(:record_cache_hit).exactly(2).times

        result = file_syncer_with_stats.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to be_within(0.01).of(0.67)
      end
    end

    context 'cache content corruption scenarios' do
      let(:target_files) { ['docs/file1.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'treats any non-nil cache result as a hit, regardless of content validity' do
        # Cache returns corrupt/invalid data but non-nil
        allow(mock_cache).to receive(:get).and_return('corrupt_data_that_is_not_nil')

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(1.0)  # Still counts as hit since non-nil
      end

      it 'treats empty string cache result as a hit' do
        # Cache returns empty string (which is non-nil)
        allow(mock_cache).to receive(:get).and_return('')

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(1.0)  # Empty string is still a hit
      end

      it 'treats false cache result as a miss' do
        # Cache returns false (which is different from nil)
        allow(mock_cache).to receive(:get).and_return(false)

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(1.0)  # false is non-nil, so counts as hit
      end
    end

    context 'file permission edge cases' do
      let(:target_files) { ['docs/protected_file.md', 'docs/normal_file.md'] }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))

        # Create normal file
        File.write(File.join(temp_source_dir, 'docs', 'normal_file.md'), 'normal_content')

        # Create protected file that exists but can't be read
        protected_path = File.join(temp_source_dir, 'docs', 'protected_file.md')
        File.write(protected_path, 'protected_content')
        File.chmod(0000, protected_path) # Remove all permissions
      end

      after do
        # Restore permissions for cleanup
        protected_path = File.join(temp_source_dir, 'docs', 'protected_file.md')
        File.chmod(0644, protected_path) if File.exist?(protected_path)
      end

      it 'treats permission-denied files as cache misses' do
        # Mock cache to return content for the readable file
        allow(mock_cache).to receive(:get).with(
          Digest::SHA256.hexdigest('normal_content')
        ).and_return('cached_content')

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to eq(0.5)  # 1 hit (normal file) out of 2 files
      end
    end

    context 'large file set stress testing' do
      let(:large_file_count) { 100 }
      let(:target_files) { (1..large_file_count).map { |i| "docs/file#{i}.md" } }

      before do
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))

        # Create many files with predictable content
        target_files.each_with_index do |file, index|
          File.write(File.join(temp_source_dir, file), "content#{index + 1}")
        end
      end

      it 'handles large number of files efficiently' do
        # Mock cache to return content for all files
        allow(mock_cache).to receive(:get).and_return('cached_content')

        start_time = Time.now
        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        end_time = Time.now

        expect(result).to eq(1.0)
        expect(end_time - start_time).to be < 1.0  # Should complete in under 1 second
      end

      it 'handles mixed hit/miss scenarios with large file sets' do
        # Mock cache to return content for first half, nil for second half
        allow(mock_cache).to receive(:get) do |hash|
          # Calculate which file this hash corresponds to based on content pattern
          content_number = (1..large_file_count).find do |i|
            hash == Digest::SHA256.hexdigest("content#{i}")
          end

          content_number && content_number <= large_file_count / 2 ? 'cached_content' : nil
        end

        result = file_syncer.calculate_cache_hit_ratio(target_files, mock_cache)
        expect(result).to be_within(0.01).of(0.5)  # 50% hit ratio
      end
    end
  end

  # Basic integration test for existing functionality
  describe '#sync' do
    let(:file_syncer) { described_class.new(temp_source_dir, temp_target_dir) }

    context 'when source directory does not exist' do
      let(:file_syncer) { described_class.new('/nonexistent', temp_target_dir) }

      it 'raises SyncError' do
        expect { file_syncer.sync }.to raise_error(
          described_class::SyncError,
          'Source directory does not exist: /nonexistent'
        )
      end
    end

    context 'with valid directories' do
      before do
        # Create a test file in source directory
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'test.md'), 'test content')
      end

      it 'returns sync results hash' do
        results = file_syncer.sync
        expect(results).to have_key(:copied)
        expect(results).to have_key(:skipped)
        expect(results).to have_key(:errors)
      end

      it 'copies files successfully' do
        results = file_syncer.sync
        expect(results[:copied]).to include('docs/test.md')
        expect(File.exist?(File.join(temp_target_dir, 'docs', 'test.md'))).to be true
      end
    end

    context 'with cache-aware sync optimization' do
      let(:file_syncer_with_cache) { described_class.new(temp_source_dir, temp_target_dir, cache: mock_cache) }

      before do
        # Create test files in source directory
        FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
        File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
        File.write(File.join(temp_source_dir, 'docs', 'file2.md'), 'content2')

        # Create matching files in target directory
        FileUtils.mkdir_p(File.join(temp_target_dir, 'docs'))
        File.write(File.join(temp_target_dir, 'docs', 'file1.md'), 'content1')
        File.write(File.join(temp_target_dir, 'docs', 'file2.md'), 'content2')
      end

      context 'when cache hit ratio is high and all target files exist' do
        it 'skips sync and returns all files as skipped' do
          # Mock cache to return content for all files (high hit ratio)
          allow(mock_cache).to receive(:get).and_return('cached_content')

          output = capture_output do
            results = file_syncer_with_cache.sync(verbose: true)
            expect(results[:skipped]).to include('docs/file1.md', 'docs/file2.md')
            expect(results[:copied]).to be_empty
          end

          expect(output).to include('Serving from cache (100.0% hit ratio)')
        end
      end

      context 'when cache hit ratio is high but some target files missing' do
        before do
          # Remove one target file to simulate missing file
          File.delete(File.join(temp_target_dir, 'docs', 'file2.md'))
        end

        it 'proceeds with normal sync despite high cache hit ratio' do
          # Mock cache to return content for all files (high hit ratio)
          allow(mock_cache).to receive(:get).and_return('cached_content')
          allow(mock_cache).to receive(:put).and_return('hash_value')  # Allow put calls during sync

          output = capture_output do
            results = file_syncer_with_cache.sync(verbose: true)
            expect(results[:copied]).to include('docs/file2.md')
          end

          expect(output).to include('but some target files missing')
        end
      end

      context 'when cache hit ratio is below threshold' do
        it 'proceeds with normal sync' do
          # Mock cache to return nil for all files (low hit ratio)
          allow(mock_cache).to receive(:get).and_return(nil)
          allow(mock_cache).to receive(:put).and_return('hash_value')  # Allow put calls during sync

          output = capture_output do
            results = file_syncer_with_cache.sync(verbose: true)
            expect(results[:skipped]).to include('docs/file1.md', 'docs/file2.md')  # Files identical, so skipped
          end

          expect(output).to include('below threshold, proceeding with sync')
        end
      end

      context 'when force_git is true' do
        it 'bypasses cache optimization' do
          # Mock cache to return content for all files (high hit ratio)
          allow(mock_cache).to receive(:get).and_return('cached_content')
          allow(mock_cache).to receive(:put).and_return('hash_value')  # Allow put calls during sync

          results = file_syncer_with_cache.sync(force_git: true, verbose: false)
          # Should proceed with normal sync logic, not cache optimization
          expect(results[:skipped]).to include('docs/file1.md', 'docs/file2.md')  # Files identical, so skipped
        end
      end
    end
  end

  describe '#check_cached_files_exist_in_target' do
    let(:file_syncer) { described_class.new(temp_source_dir, temp_target_dir) }

    before do
      # Create source files
      FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
      File.write(File.join(temp_source_dir, 'docs', 'file1.md'), 'content1')
      File.write(File.join(temp_source_dir, 'docs', 'file2.md'), 'content2')
    end

    context 'when all files exist and match' do
      before do
        # Create matching target files
        FileUtils.mkdir_p(File.join(temp_target_dir, 'docs'))
        File.write(File.join(temp_target_dir, 'docs', 'file1.md'), 'content1')
        File.write(File.join(temp_target_dir, 'docs', 'file2.md'), 'content2')
      end

      it 'returns all_exist: true' do
        result = file_syncer.check_cached_files_exist_in_target(['docs/file1.md', 'docs/file2.md'])
        expect(result[:all_exist]).to be true
        expect(result[:details].all? { |d| d[:status] == :exists_and_matches }).to be true
      end
    end

    context 'when some files are missing in target' do
      before do
        # Create only one target file
        FileUtils.mkdir_p(File.join(temp_target_dir, 'docs'))
        File.write(File.join(temp_target_dir, 'docs', 'file1.md'), 'content1')
      end

      it 'returns all_exist: false' do
        result = file_syncer.check_cached_files_exist_in_target(['docs/file1.md', 'docs/file2.md'])
        expect(result[:all_exist]).to be false

        missing_file = result[:details].find { |d| d[:file] == 'docs/file2.md' }
        expect(missing_file[:status]).to eq(:missing_in_target)
      end
    end

    context 'when target files have different content' do
      before do
        # Create target files with different content
        FileUtils.mkdir_p(File.join(temp_target_dir, 'docs'))
        File.write(File.join(temp_target_dir, 'docs', 'file1.md'), 'different_content')
        File.write(File.join(temp_target_dir, 'docs', 'file2.md'), 'content2')
      end

      it 'returns all_exist: false for content mismatches' do
        result = file_syncer.check_cached_files_exist_in_target(['docs/file1.md', 'docs/file2.md'])
        expect(result[:all_exist]).to be false

        mismatched_file = result[:details].find { |d| d[:file] == 'docs/file1.md' }
        expect(mismatched_file[:status]).to eq(:content_mismatch)
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
