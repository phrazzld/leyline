# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Leyline::Detection::LanguageDetector do
  let(:temp_dir) { Dir.mktmpdir('leyline-detection-test') }
  let(:detector) { described_class.new(temp_dir) }

  # Create a concrete test detector to test the abstract interface
  let(:test_detector_class) do
    Class.new(described_class) do
      def detect
        ['test-language']
      end
    end
  end
  let(:concrete_detector) { test_detector_class.new(temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe 'initialization' do
    it 'creates a detector with valid project path' do
      expect(detector.instance_variable_get(:@project_path)).to eq(File.expand_path(temp_dir))
    end

    it 'expands relative paths' do
      Dir.chdir(temp_dir) do
        relative_detector = described_class.new('.')
        # Use realpath to handle symlinks consistently across platforms
        expected_path = File.realpath(temp_dir)
        actual_path = File.realpath(relative_detector.instance_variable_get(:@project_path))
        expect(actual_path).to eq(expected_path)
      end
    end

    it 'raises DetectionError for nonexistent project path' do
      nonexistent_path = '/tmp/nonexistent-leyline-test-dir'

      expect { described_class.new(nonexistent_path) }.to raise_error(
        described_class::DetectionError,
        "Project path does not exist: #{nonexistent_path}"
      )
    end
  end

  describe '#detect' do
    it 'raises NotImplementedError for abstract base class' do
      expect { detector.detect }.to raise_error(
        NotImplementedError,
        "#{described_class}#detect must be implemented by subclasses"
      )
    end

    it 'can be implemented by subclasses' do
      expect(concrete_detector.detect).to eq(['test-language'])
    end
  end

  describe 'protected helper methods' do
    describe '#project_path' do
      it 'provides access to project path for subclasses' do
        expect(concrete_detector.send(:project_path)).to eq(File.expand_path(temp_dir))
      end
    end

    describe '#file_exists?' do
      before do
        File.write(File.join(temp_dir, 'existing_file.txt'), 'content')
      end

      it 'returns true for existing files' do
        expect(concrete_detector.send(:file_exists?, 'existing_file.txt')).to be true
      end

      it 'returns false for nonexistent files' do
        expect(concrete_detector.send(:file_exists?, 'nonexistent.txt')).to be false
      end

      it 'handles nested paths' do
        nested_dir = File.join(temp_dir, 'nested')
        FileUtils.mkdir_p(nested_dir)
        File.write(File.join(nested_dir, 'nested_file.txt'), 'nested content')

        expect(concrete_detector.send(:file_exists?, 'nested/nested_file.txt')).to be true
      end
    end

    describe '#read_file' do
      let(:file_content) { 'test file content' }

      before do
        File.write(File.join(temp_dir, 'test_file.txt'), file_content)
      end

      it 'reads existing file content' do
        expect(concrete_detector.send(:read_file, 'test_file.txt')).to eq(file_content)
      end

      it 'returns nil for nonexistent files' do
        expect(concrete_detector.send(:read_file, 'nonexistent.txt')).to be_nil
      end

      it 'handles nested file paths' do
        nested_dir = File.join(temp_dir, 'nested')
        FileUtils.mkdir_p(nested_dir)
        nested_content = 'nested file content'
        File.write(File.join(nested_dir, 'nested.txt'), nested_content)

        expect(concrete_detector.send(:read_file, 'nested/nested.txt')).to eq(nested_content)
      end

      it 'raises DetectionError for read failures' do
        # Create a file and then make it unreadable
        restricted_file = File.join(temp_dir, 'restricted.txt')
        File.write(restricted_file, 'content')

        # Simulate read failure by stubbing File.read
        allow(File).to receive(:read).with(restricted_file).and_raise(StandardError.new('Permission denied'))

        expect { concrete_detector.send(:read_file, 'restricted.txt') }.to raise_error(
          described_class::DetectionError,
          /Failed to read file restricted\.txt: Permission denied/
        )
      end
    end
  end

  describe 'error handling' do
    describe 'DetectionError' do
      it 'is a subclass of StandardError' do
        expect(described_class::DetectionError).to be < StandardError
      end

      it 'can be raised with custom messages' do
        expect { raise described_class::DetectionError, 'custom message' }.to raise_error(
          described_class::DetectionError,
          'custom message'
        )
      end
    end
  end

  describe 'interface contract' do
    it 'provides expected public interface' do
      expect(detector).to respond_to(:detect)
    end

    it 'provides expected protected interface for subclasses' do
      expect(concrete_detector.protected_methods).to include(:project_path, :file_exists?, :read_file)
    end

    it 'does not expose internal implementation details' do
      expect(detector.public_methods).not_to include(:validate_project_path)
    end
  end
end
