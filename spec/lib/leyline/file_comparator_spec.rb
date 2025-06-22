# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'leyline/file_comparator'

RSpec.describe Leyline::FileComparator do
  let(:cache) { nil }  # Start without cache for basic tests
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
        File.chmod(0000, unreadable_file)
      end

      after do
        File.chmod(0644, unreadable_file) if File.exist?(unreadable_file)
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

        expect {
          comparator.generate_diff_data('/nonexistent/file.txt', existing_file)
        }.to raise_error(Leyline::FileComparator::ComparisonError, /File A does not exist/)
      end

      it 'raises error for missing second file' do
        existing_file = File.join(temp_dir, 'exists.txt')
        File.write(existing_file, 'content')

        expect {
          comparator.generate_diff_data(existing_file, '/nonexistent/file.txt')
        }.to raise_error(Leyline::FileComparator::ComparisonError, /File B does not exist/)
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

        # Note: Since discover_remote_files returns empty hash for now,
        # all local files will appear as "removed"
        expect(result[:removed]).not_to be_empty
      end
    end

    context 'with invalid inputs' do
      it 'raises error for non-existent local path' do
        expect {
          comparator.compare_with_remote('/nonexistent/path', 'core')
        }.to raise_error(Leyline::FileComparator::ComparisonError, /Local path does not exist/)
      end

      it 'raises error for nil category' do
        expect {
          comparator.compare_with_remote(temp_dir, nil)
        }.to raise_error(Leyline::FileComparator::ComparisonError, /Category cannot be nil or empty/)
      end

      it 'raises error for empty category' do
        expect {
          comparator.compare_with_remote(temp_dir, '  ')
        }.to raise_error(Leyline::FileComparator::ComparisonError, /Category cannot be nil or empty/)
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

        expect(duration).to be < 0.5  # 500ms
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

        expect(duration).to be < 0.5  # 500ms
        expect(modifications.size).to eq(10)
      end
    end
  end
end
