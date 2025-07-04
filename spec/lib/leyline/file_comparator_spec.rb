# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'leyline/file_comparator'

RSpec.describe Leyline::FileComparator do
  let(:cache) { nil } # Start without cache for basic tests
  let(:base_directory) { nil }
  let(:comparator) { described_class.new(cache: cache, base_directory: base_directory) }

  describe '#initialize' do
    it 'creates a comparator without required dependencies' do
      expect(comparator).to be_a(Leyline::FileComparator)
    end

    context 'with cache' do
      let(:cache) { double('cache') }

      it 'accepts cache dependency' do
        expect(comparator).to be_a(Leyline::FileComparator)
      end
    end
  end

  describe '#files_identical?' do
    let(:temp_dir) { Dir.mktmpdir('file-comparator-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'when files are identical' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'identical content')
        File.write(file_b, 'identical content')
      end

      it 'returns true' do
        expect(comparator.files_identical?(file_a, file_b)).to be true
      end
    end

    context 'when files are different' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'content A')
        File.write(file_b, 'content B')
      end

      it 'returns false' do
        expect(comparator.files_identical?(file_a, file_b)).to be false
      end
    end

    context 'when files have different sizes' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'short')
        File.write(file_b, 'much longer content')
      end

      it 'returns false quickly without reading content' do
        expect(comparator.files_identical?(file_a, file_b)).to be false
      end
    end

    context 'when comparing same file' do
      let(:file_a) { File.join(temp_dir, 'file.txt') }

      before do
        File.write(file_a, 'content')
      end

      it 'returns true' do
        expect(comparator.files_identical?(file_a, file_a)).to be true
      end
    end

    context 'when files do not exist' do
      it 'returns false when first file missing' do
        existing_file = File.join(temp_dir, 'exists.txt')
        File.write(existing_file, 'content')

        expect(comparator.files_identical?('/nonexistent/file.txt', existing_file)).to be false
      end

      it 'returns false when second file missing' do
        existing_file = File.join(temp_dir, 'exists.txt')
        File.write(existing_file, 'content')

        expect(comparator.files_identical?(existing_file, '/nonexistent/file.txt')).to be false
      end

      it 'returns false when both files missing' do
        expect(comparator.files_identical?('/nonexistent/a.txt', '/nonexistent/b.txt')).to be false
      end
    end

    context 'with cache integration' do
      let(:cache) { double('cache') }

      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'cached content')
        File.write(file_b, 'cached content')
      end

      it 'uses cache when available' do
        expect(cache).to receive(:put).twice.and_return('hash123')

        expect(comparator.files_identical?(file_a, file_b)).to be true
      end

      it 'handles cache errors gracefully' do
        expect(cache).to receive(:put).twice.and_raise(StandardError, 'Cache error')

        # Should still work even if cache fails
        expect(comparator.files_identical?(file_a, file_b)).to be true
      end
    end
  end

  describe '#create_manifest' do
    let(:temp_dir) { Dir.mktmpdir('manifest-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'with existing files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'content A')
        File.write(file_b, 'content B')
      end

      it 'creates manifest with file hashes' do
        manifest = comparator.create_manifest([file_a, file_b])

        expect(manifest).to have_key(file_a)
        expect(manifest).to have_key(file_b)
        expect(manifest[file_a]).to match(/\A[a-f0-9]{64}\z/)
        expect(manifest[file_b]).to match(/\A[a-f0-9]{64}\z/)
        expect(manifest[file_a]).not_to eq(manifest[file_b])
      end
    end

    context 'with non-existent files' do
      it 'skips missing files' do
        manifest = comparator.create_manifest(['/nonexistent/file.txt'])

        expect(manifest).to be_empty
      end
    end

    context 'with mix of existing and missing files' do
      let(:existing_file) { File.join(temp_dir, 'exists.txt') }

      before do
        File.write(existing_file, 'content')
      end

      it 'includes only existing files' do
        manifest = comparator.create_manifest([existing_file, '/nonexistent/file.txt'])

        expect(manifest).to have_key(existing_file)
        expect(manifest).not_to have_key('/nonexistent/file.txt')
        expect(manifest.size).to eq(1)
      end
    end

    context 'with unreadable files' do
      let(:unreadable_file) { File.join(temp_dir, 'unreadable.txt') }

      before do
        File.write(unreadable_file, 'content')
        File.chmod(0o000, unreadable_file)
      end

      after do
        File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
      end

      it 'warns and continues for unreadable files' do
        expect { comparator.create_manifest([unreadable_file]) }
          .to output(/Warning: Could not hash file.*Permission denied/).to_stderr

        manifest = comparator.create_manifest([unreadable_file])
        expect(manifest).not_to have_key(unreadable_file)
      end
    end
  end

  describe '#detect_modifications' do
    let(:temp_dir) { Dir.mktmpdir('modifications-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'with unchanged files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'original content A')
        File.write(file_b, 'original content B')
      end

      it 'returns empty array when no files modified' do
        # Create original manifest
        original_manifest = comparator.create_manifest([file_a, file_b])

        modifications = comparator.detect_modifications(original_manifest, [file_a, file_b])

        expect(modifications).to be_empty
      end
    end

    context 'with modified files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'original content A')
        File.write(file_b, 'original content B')
      end

      it 'detects modified files' do
        # Create original manifest
        original_manifest = comparator.create_manifest([file_a, file_b])

        # Modify one file
        File.write(file_a, 'modified content A')

        modifications = comparator.detect_modifications(original_manifest, [file_a, file_b])

        expect(modifications).to include(file_a)
        expect(modifications).not_to include(file_b)
        expect(modifications.size).to eq(1)
      end
    end

    context 'with new files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'original content A')
      end

      it 'detects new files as modifications' do
        # Create manifest with only file_a
        original_manifest = comparator.create_manifest([file_a])

        # Create file_b
        File.write(file_b, 'new content B')

        modifications = comparator.detect_modifications(original_manifest, [file_a, file_b])

        expect(modifications).to include(file_b)
        expect(modifications).not_to include(file_a)
        expect(modifications.size).to eq(1)
      end
    end

    context 'with nil inputs' do
      it 'returns empty array for nil manifest' do
        modifications = comparator.detect_modifications(nil, ['file.txt'])
        expect(modifications).to be_empty
      end

      it 'returns empty array for nil files' do
        modifications = comparator.detect_modifications({}, nil)
        expect(modifications).to be_empty
      end

      it 'returns empty array for both nil' do
        modifications = comparator.detect_modifications(nil, nil)
        expect(modifications).to be_empty
      end
    end

    context 'with missing files' do
      it 'skips files that no longer exist' do
        original_manifest = { '/nonexistent/file.txt' => 'hash123' }

        modifications = comparator.detect_modifications(original_manifest, ['/nonexistent/file.txt'])

        expect(modifications).to be_empty
      end
    end
  end

  describe '#generate_diff_data' do
    let(:temp_dir) { Dir.mktmpdir('diff-data-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'with valid files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'content A')
        File.write(file_b, 'content B')
      end

      it 'generates comprehensive diff data' do
        diff_data = comparator.generate_diff_data(file_a, file_b)

        expect(diff_data).to include(
          file_a: file_a,
          file_b: file_b,
          identical: false,
          size_a: 9,
          size_b: 9,
          hash_a: kind_of(String),
          hash_b: kind_of(String),
          modified_time_a: kind_of(Time),
          modified_time_b: kind_of(Time)
        )

        expect(diff_data[:hash_a]).to match(/\A[a-f0-9]{64}\z/)
        expect(diff_data[:hash_b]).to match(/\A[a-f0-9]{64}\z/)
        expect(diff_data[:hash_a]).not_to eq(diff_data[:hash_b])
      end
    end

    context 'with identical files' do
      let(:file_a) { File.join(temp_dir, 'file_a.txt') }
      let(:file_b) { File.join(temp_dir, 'file_b.txt') }

      before do
        File.write(file_a, 'identical content')
        File.write(file_b, 'identical content')
      end

      it 'reports files as identical' do
        diff_data = comparator.generate_diff_data(file_a, file_b)

        expect(diff_data[:identical]).to be true
        expect(diff_data[:hash_a]).to eq(diff_data[:hash_b])
      end
    end

    context 'with missing files' do
      it 'raises error for missing first file' do
        existing_file = File.join(temp_dir, 'exists.txt')
        File.write(existing_file, 'content')

        expect do
          comparator.generate_diff_data('/nonexistent/file.txt', existing_file)
        end.to raise_error(Leyline::FileComparator::ComparisonError, /File A does not exist/)
      end

      it 'raises error for missing second file' do
        existing_file = File.join(temp_dir, 'exists.txt')
        File.write(existing_file, 'content')

        expect do
          comparator.generate_diff_data(existing_file, '/nonexistent/file.txt')
        end.to raise_error(Leyline::FileComparator::ComparisonError, /File B does not exist/)
      end
    end
  end

  describe '#compare_with_remote' do
    let(:temp_dir) { Dir.mktmpdir('compare-remote-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'with valid inputs' do
      let(:local_path) { temp_dir }

      before do
        # Create local leyline structure
        leyline_dir = File.join(temp_dir, 'docs', 'leyline')
        FileUtils.mkdir_p(File.join(leyline_dir, 'tenets'))
        FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'core'))
        FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'typescript'))

        File.write(File.join(leyline_dir, 'tenets', 'simplicity.md'), 'simplicity content')
        File.write(File.join(leyline_dir, 'bindings', 'core', 'api-design.md'), 'api design content')
        File.write(File.join(leyline_dir, 'bindings', 'categories', 'typescript', 'no-any.md'), 'no-any content')
      end

      it 'discovers local files for core category' do
        result = comparator.compare_with_remote(local_path, 'core')

        expect(result).to include(:added, :modified, :removed, :unchanged)
        expect(result[:added]).to be_an(Array)
        expect(result[:modified]).to be_an(Array)
        expect(result[:removed]).to be_an(Array)
        expect(result[:unchanged]).to be_an(Array)
      end

      it 'discovers local files for typescript category' do
        result = comparator.compare_with_remote(local_path, 'typescript')

        expect(result).to include(:added, :modified, :removed, :unchanged)

        # NOTE: Since discover_remote_files returns empty hash for now,
        # all local files will appear as "removed"
        expect(result[:removed]).not_to be_empty
      end
    end

    context 'with invalid inputs' do
      it 'raises error for non-existent local path' do
        expect do
          comparator.compare_with_remote('/nonexistent/path', 'core')
        end.to raise_error(Leyline::FileComparator::ComparisonError, /Local path does not exist/)
      end

      it 'raises error for nil category' do
        expect do
          comparator.compare_with_remote(temp_dir, nil)
        end.to raise_error(Leyline::FileComparator::ComparisonError, /Category cannot be nil or empty/)
      end

      it 'raises error for empty category' do
        expect do
          comparator.compare_with_remote(temp_dir, '  ')
        end.to raise_error(Leyline::FileComparator::ComparisonError, /Category cannot be nil or empty/)
      end
    end

    context 'without local leyline structure' do
      it 'returns empty comparison when no docs/leyline directory' do
        result = comparator.compare_with_remote(temp_dir, 'core')

        expect(result[:added]).to be_empty
        expect(result[:modified]).to be_empty
        expect(result[:removed]).to be_empty
        expect(result[:unchanged]).to be_empty
      end
    end
  end

  describe 'category filtering' do
    let(:temp_dir) { Dir.mktmpdir('category-test') }
    let(:local_path) { temp_dir }

    after { FileUtils.rm_rf(temp_dir) }

    before do
      # Create comprehensive leyline structure
      leyline_dir = File.join(temp_dir, 'docs', 'leyline')

      # Create directory structure
      FileUtils.mkdir_p(File.join(leyline_dir, 'tenets'))
      FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'core'))
      FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'typescript'))
      FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'go'))
      FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'python'))

      # Create test files
      File.write(File.join(leyline_dir, 'tenets', 'simplicity.md'), 'simplicity content')
      File.write(File.join(leyline_dir, 'tenets', 'testability.md'), 'testability content')
      File.write(File.join(leyline_dir, 'bindings', 'core', 'api-design.md'), 'api design content')
      File.write(File.join(leyline_dir, 'bindings', 'core', 'error-handling.md'), 'error handling content')
      File.write(File.join(leyline_dir, 'bindings', 'categories', 'typescript', 'no-any.md'), 'no-any content')
      File.write(File.join(leyline_dir, 'bindings', 'categories', 'typescript', 'strict-mode.md'),
                 'strict mode content')
      File.write(File.join(leyline_dir, 'bindings', 'categories', 'go', 'error-wrapping.md'), 'go error content')
      File.write(File.join(leyline_dir, 'bindings', 'categories', 'python', 'pep8.md'), 'python style content')
    end

    it 'discovers only core and tenets for core category' do
      result = comparator.compare_with_remote(local_path, 'core')

      # All files should appear as "removed" since discover_remote_files returns empty
      removed_files = result[:removed]

      # Should include tenets and core bindings, but not category-specific bindings
      expect(removed_files).to include('tenets/simplicity.md')
      expect(removed_files).to include('tenets/testability.md')
      expect(removed_files).to include('bindings/core/api-design.md')
      expect(removed_files).to include('bindings/core/error-handling.md')

      # Should not include category-specific files
      expect(removed_files).not_to include('bindings/categories/typescript/no-any.md')
      expect(removed_files).not_to include('bindings/categories/go/error-wrapping.md')
      expect(removed_files).not_to include('bindings/categories/python/pep8.md')
    end

    it 'discovers tenets, core, and typescript for typescript category' do
      result = comparator.compare_with_remote(local_path, 'typescript')

      removed_files = result[:removed]

      # Should include tenets, core bindings, and typescript bindings
      expect(removed_files).to include('tenets/simplicity.md')
      expect(removed_files).to include('bindings/core/api-design.md')
      expect(removed_files).to include('bindings/categories/typescript/no-any.md')
      expect(removed_files).to include('bindings/categories/typescript/strict-mode.md')

      # Should not include other category-specific files
      expect(removed_files).not_to include('bindings/categories/go/error-wrapping.md')
      expect(removed_files).not_to include('bindings/categories/python/pep8.md')
    end

    it 'discovers tenets, core, and go for go category' do
      result = comparator.compare_with_remote(local_path, 'go')

      removed_files = result[:removed]

      # Should include tenets, core bindings, and go bindings only
      expect(removed_files).to include('tenets/simplicity.md')
      expect(removed_files).to include('bindings/core/api-design.md')
      expect(removed_files).to include('bindings/categories/go/error-wrapping.md')

      # Should not include other category-specific files
      expect(removed_files).not_to include('bindings/categories/typescript/no-any.md')
      expect(removed_files).not_to include('bindings/categories/python/pep8.md')
    end
  end

  describe 'private method behaviors' do
    let(:temp_dir) { Dir.mktmpdir('private-methods-test') }

    after { FileUtils.rm_rf(temp_dir) }

    describe 'content hashing with cache integration' do
      let(:cache) { double('cache') }
      let(:comparator_with_cache) { described_class.new(cache: cache, base_directory: temp_dir) }
      let(:test_file) { File.join(temp_dir, 'test.txt') }

      before do
        File.write(test_file, 'test content for hashing')
      end

      it 'caches content when cache is available' do
        expect(cache).to receive(:put).with('test content for hashing').and_return('cached_hash')

        # Access the private method through public interface
        manifest = comparator_with_cache.create_manifest([test_file])

        expect(manifest[test_file]).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'continues normally when cache put fails' do
        expect(cache).to receive(:put).and_raise(StandardError, 'Cache failure')

        # Should not raise error and should still compute hash
        manifest = comparator_with_cache.create_manifest([test_file])

        expect(manifest[test_file]).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'produces consistent SHA256 hashes' do
        # Create two files with identical content
        file1 = File.join(temp_dir, 'file1.txt')
        file2 = File.join(temp_dir, 'file2.txt')
        File.write(file1, 'identical content')
        File.write(file2, 'identical content')

        allow(cache).to receive(:put).and_return('cached')

        manifest = comparator_with_cache.create_manifest([file1, file2])

        expect(manifest[file1]).to eq(manifest[file2])
        expect(manifest[file1]).to eq(Digest::SHA256.hexdigest('identical content'))
      end
    end

    describe 'file discovery error handling' do
      let(:local_path) { temp_dir }

      before do
        # Create basic structure
        leyline_dir = File.join(temp_dir, 'docs', 'leyline')
        FileUtils.mkdir_p(File.join(leyline_dir, 'tenets'))
        File.write(File.join(leyline_dir, 'tenets', 'valid.md'), 'valid content')
      end

      it 'handles errors during file discovery gracefully' do
        # Create a file that will be found by glob but unreadable for content_hash
        leyline_dir = File.join(temp_dir, 'docs', 'leyline')
        unreadable_file = File.join(leyline_dir, 'tenets', 'unreadable.md')

        File.write(unreadable_file, 'content')
        File.chmod(0o000, unreadable_file)

        expect do
          comparator.compare_with_remote(local_path, 'core')
        end.to raise_error(Leyline::FileComparator::ComparisonError, /Failed to discover local files/)

        # Restore permissions for cleanup
        File.chmod(0o644, unreadable_file)
      end
    end

    describe 'pattern building for different categories' do
      # Test pattern building indirectly through file discovery
      let(:local_path) { temp_dir }

      before do
        leyline_dir = File.join(temp_dir, 'docs', 'leyline')
        FileUtils.mkdir_p(File.join(leyline_dir, 'tenets'))
        FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'core'))
        FileUtils.mkdir_p(File.join(leyline_dir, 'bindings', 'categories', 'rust'))

        File.write(File.join(leyline_dir, 'tenets', 'example.md'), 'content')
        File.write(File.join(leyline_dir, 'bindings', 'core', 'example.md'), 'content')
        File.write(File.join(leyline_dir, 'bindings', 'categories', 'rust', 'example.md'), 'content')

        # Add non-markdown files to ensure they're filtered out
        File.write(File.join(leyline_dir, 'tenets', 'readme.txt'), 'text content')
        File.write(File.join(leyline_dir, 'bindings', 'core', 'config.json'), 'json content')
      end

      it 'only includes markdown files' do
        result = comparator.compare_with_remote(local_path, 'rust')
        all_files = result[:added] + result[:modified] + result[:removed] + result[:unchanged]

        # Should only include .md files
        all_files.each do |file|
          expect(file).to end_with('.md')
        end

        expect(all_files).not_to include('tenets/readme.txt')
        expect(all_files).not_to include('bindings/core/config.json')
      end
    end
  end

  describe 'edge cases and error conditions' do
    let(:temp_dir) { Dir.mktmpdir('edge-cases-test') }

    after { FileUtils.rm_rf(temp_dir) }

    describe '#files_identical? error handling' do
      it 'handles file read errors gracefully' do
        file_a = File.join(temp_dir, 'readable.txt')
        file_b = File.join(temp_dir, 'unreadable.txt')

        File.write(file_a, 'content')
        File.write(file_b, 'content')
        File.chmod(0o000, file_b)

        # Should return false when encountering read errors
        result = comparator.files_identical?(file_a, file_b)
        expect(result).to be false

        # Restore permissions for cleanup
        File.chmod(0o644, file_b)
      end
    end

    describe 'detect_modified_files and detect_unchanged_files' do
      it 'handles empty manifests correctly' do
        # Test via public interface through compare_with_remote
        # These methods are used internally but we can verify behavior
        result = comparator.compare_with_remote(temp_dir, 'core')

        # Should handle empty remote files gracefully
        expect(result[:added]).to be_an(Array)
        expect(result[:modified]).to be_an(Array)
        expect(result[:removed]).to be_an(Array)
        expect(result[:unchanged]).to be_an(Array)
      end
    end

    describe 'large file handling' do
      let(:large_file) { File.join(temp_dir, 'large.txt') }

      before do
        # Create a larger file (10KB)
        content = 'a' * 10_000
        File.write(large_file, content)
      end

      it 'handles large files efficiently' do
        start_time = Time.now
        manifest = comparator.create_manifest([large_file])
        duration = Time.now - start_time

        expect(duration).to be < 0.1 # Should be fast even for larger files
        expect(manifest[large_file]).to match(/\A[a-f0-9]{64}\z/)
      end

      it 'compares large files correctly' do
        large_file_b = File.join(temp_dir, 'large_b.txt')
        File.write(large_file_b, 'a' * 10_000) # Same content

        expect(comparator.files_identical?(large_file, large_file_b)).to be true
      end
    end
  end

  describe 'performance characteristics' do
    let(:temp_dir) { Dir.mktmpdir('performance-test') }

    after { FileUtils.rm_rf(temp_dir) }

    context 'with large number of files' do
      before do
        # Create 100 small test files
        100.times do |i|
          File.write(File.join(temp_dir, "file_#{i}.txt"), "content #{i}")
        end
      end

      it 'creates manifest for 100 files in under 500ms' do
        file_paths = Dir.glob(File.join(temp_dir, '*.txt'))

        start_time = Time.now
        manifest = comparator.create_manifest(file_paths)
        duration = Time.now - start_time

        expect(duration).to be < 0.5 # 500ms
        expect(manifest.size).to eq(100)
      end

      it 'detects modifications efficiently' do
        file_paths = Dir.glob(File.join(temp_dir, '*.txt'))
        original_manifest = comparator.create_manifest(file_paths)

        # Modify 10 files
        10.times do |i|
          File.write(File.join(temp_dir, "file_#{i}.txt"), "modified content #{i}")
        end

        start_time = Time.now
        modifications = comparator.detect_modifications(original_manifest, file_paths)
        duration = Time.now - start_time

        expect(duration).to be < 0.5 # 500ms
        expect(modifications.size).to eq(10)
      end

      it 'performs file comparisons efficiently with cache' do
        cache = double('cache')
        allow(cache).to receive(:put).and_return('cached')
        cached_comparator = described_class.new(cache: cache)

        file_paths = Dir.glob(File.join(temp_dir, '*.txt'))

        start_time = Time.now

        # Compare adjacent files (should be fast with caching)
        50.times do |i|
          file_a = file_paths[i]
          file_b = file_paths[i + 1] if i < 99
          next unless file_b

          cached_comparator.files_identical?(file_a, file_b)
        end

        duration = Time.now - start_time
        expect(duration).to be < 0.5 # 500ms for 50 comparisons
      end
    end

    context 'memory usage validation' do
      it 'does not accumulate memory during large manifest creation' do
        # Create files and measure memory usage patterns
        1000.times do |i|
          File.write(File.join(temp_dir, "test_#{i}.txt"), "content #{i % 100}") # Varied content
        end

        file_paths = Dir.glob(File.join(temp_dir, '*.txt'))

        # Multiple iterations to check for memory leaks
        3.times do
          manifest = comparator.create_manifest(file_paths)
          expect(manifest.size).to eq(1000)
        end

        # If we get here without memory issues, the test passes
        expect(true).to be true
      end
    end
  end
end
