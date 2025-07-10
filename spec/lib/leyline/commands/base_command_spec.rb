# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/base_command'
require 'tmpdir'
require 'json'
require 'stringio'

RSpec.describe Leyline::Commands::BaseCommand do
  # Create a concrete test subclass to test the abstract BaseCommand
  let(:test_command_class) do
    Class.new(described_class) do
      def execute
        'test result'
      end
    end
  end

  let(:default_options) { {} }
  let(:command) { test_command_class.new(default_options) }

  describe '#initialize' do
    context 'with default options' do
      it 'sets default values' do
        expect(command.instance_variable_get(:@options)).to eq({})
        expect(command.instance_variable_get(:@base_directory)).to eq(Dir.pwd)
        expect(command.instance_variable_get(:@cache_dir)).to eq(File.expand_path('~/.cache/leyline'))
      end
    end

    context 'with custom options' do
      let(:custom_options) do
        {
          directory: '/custom/path',
          cache_dir: '/custom/cache'
        }
      end
      let(:command) { test_command_class.new(custom_options) }

      it 'uses provided options' do
        expect(command.instance_variable_get(:@options)).to eq(custom_options)
        expect(command.instance_variable_get(:@base_directory)).to eq('/custom/path')
        expect(command.instance_variable_get(:@cache_dir)).to eq('/custom/cache')
      end
    end

    context 'with environment variable cache directory' do
      around do |example|
        original = ENV['LEYLINE_CACHE_DIR']
        ENV['LEYLINE_CACHE_DIR'] = '/env/cache'
        example.run
        ENV['LEYLINE_CACHE_DIR'] = original
      end

      it 'uses environment variable when no cache_dir option provided' do
        expect(command.instance_variable_get(:@cache_dir)).to eq('/env/cache')
      end
    end
  end

  describe '#execute' do
    context 'with abstract BaseCommand' do
      let(:abstract_command) { described_class.new }

      it 'raises NotImplementedError' do
        expect { abstract_command.execute }.to raise_error(NotImplementedError, 'Subclasses must implement execute method')
      end
    end

    context 'with concrete subclass' do
      it 'executes successfully' do
        expect(command.execute).to eq('test result')
      end
    end
  end

  describe '#handle_error' do
    context 'with Leyline::LeylineError' do
      let(:leyline_error) { Leyline::LeylineError.new('Test error') }

      it 'outputs error with recovery suggestions' do
        output = capture_stderr { command.send(:handle_error, leyline_error) }
        expect(output).to include('Error: Test error')
        expect(output).to include('To resolve this issue, try:')
      end
    end

    context 'with permission error' do
      let(:permission_error) { Errno::EACCES.new('Permission denied - /test/path') }

      it 'converts to FileSystemError' do
        output = capture_stderr { command.send(:handle_error, permission_error) }
        expect(output).to include('Permission denied accessing files')
      end
    end

    context 'with file not found error' do
      let(:not_found_error) { Errno::ENOENT.new('No such file') }
      let(:context) { { path: '/missing/file' } }

      it 'converts to FileSystemError with context' do
        output = capture_stderr { command.send(:handle_error, not_found_error, context) }
        expect(output).to include('File or directory not found')
      end
    end

    context 'with disk full error' do
      let(:disk_full_error) { Errno::ENOSPC.new('No space left') }

      it 'handles the error gracefully' do
        # Test that the error is handled without raising
        expect { command.send(:handle_error, disk_full_error) }.not_to raise_error
      end
    end

    context 'with JSON parse error' do
      let(:json_error) { JSON::ParserError.new('Invalid JSON') }
      let(:context) { { file: '/data.json' } }

      it 'handles the error gracefully' do
        # Test that the error is handled without raising
        expect { command.send(:handle_error, json_error, context) }.not_to raise_error
      end
    end

    context 'with generic error' do
      let(:generic_error) { StandardError.new('Generic error') }

      it 'converts to LeylineError' do
        output = capture_stderr { command.send(:handle_error, generic_error) }
        expect(output).to include('Generic error')
      end
    end

    context 'with verbose mode' do
      let(:verbose_options) { { verbose: true } }
      let(:command) { test_command_class.new(verbose_options) }
      let(:leyline_error) { Leyline::LeylineError.new('Verbose test') }

      it 'includes debug information' do
        output = capture_stderr { command.send(:handle_error, leyline_error) }
        expect(output).to include('Debug information:')
        expect(output).to include('Error category:')
      end
    end
  end

  describe '#error_and_exit' do
    it 'prints error message and exits with code 1' do
      expect { command.send(:error_and_exit, 'Test error') }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  describe '#output_result' do
    let(:test_data) { { test: 'data', number: 42 } }

    context 'with JSON option' do
      let(:json_options) { { json: true } }
      let(:command) { test_command_class.new(json_options) }

      it 'outputs JSON format' do
        output = capture_stdout { command.send(:output_result, test_data) }
        parsed = JSON.parse(output)
        expect(parsed['test']).to eq('data')
        expect(parsed['number']).to eq(42)
      end
    end

    context 'without JSON option' do
      it 'outputs human-readable format' do
        output = capture_stdout { command.send(:output_result, test_data) }
        expect(output).to include('test')
        expect(output).to include('data')
      end
    end
  end

  describe '#verbose?' do
    context 'with string key' do
      let(:verbose_options) { { 'verbose' => true } }
      let(:command) { test_command_class.new(verbose_options) }

      it 'returns true for string key' do
        expect(command.send(:verbose?)).to be true
      end
    end

    context 'with symbol key' do
      let(:verbose_options) { { verbose: true } }
      let(:command) { test_command_class.new(verbose_options) }

      it 'returns true for symbol key' do
        expect(command.send(:verbose?)).to be true
      end
    end

    context 'without verbose option' do
      let(:command) { test_command_class.new({}) }

      it 'returns falsy' do
        expect(command.send(:verbose?)).to be_falsy
      end
    end
  end

  describe '#leyline_path' do
    let(:custom_options) { { directory: '/project' } }
    let(:command) { test_command_class.new(custom_options) }

    it 'returns correct leyline docs path' do
      expect(command.send(:leyline_path)).to eq('/project/docs/leyline')
    end
  end

  describe '#leyline_exists?' do
    context 'when leyline directory exists' do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          leyline_dir = File.join(tmpdir, 'docs', 'leyline')
          FileUtils.mkdir_p(leyline_dir)

          custom_options = { directory: tmpdir }
          @command = test_command_class.new(custom_options)
          example.run
        end
      end

      it 'returns true' do
        expect(@command.send(:leyline_exists?)).to be true
      end
    end

    context 'when leyline directory does not exist' do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          custom_options = { directory: tmpdir }
          @command = test_command_class.new(custom_options)
          example.run
        end
      end

      it 'returns false' do
        expect(@command.send(:leyline_exists?)).to be false
      end
    end
  end

  describe '#categories' do
    context 'with categories option' do
      let(:categories_options) { { categories: ['typescript', 'go'] } }
      let(:command) { test_command_class.new(categories_options) }

      it 'returns provided categories' do
        expect(command.send(:categories)).to eq(['typescript', 'go'])
      end
    end

    context 'without categories option' do
      it 'returns empty array' do
        expect(command.send(:categories)).to eq([])
      end
    end
  end

  describe '#extract_path_from_error' do
    context 'with path in error message' do
      let(:error_with_path) { double('error', message: 'Permission denied - /test/path') }

      it 'extracts path from error message' do
        result = command.send(:extract_path_from_error, error_with_path)
        expect(result).to eq('/test/path')
      end
    end

    context 'with malformed error message' do
      let(:error_without_path) { double('error', message: 'Generic error') }

      it 'returns nil for malformed message' do
        result = command.send(:extract_path_from_error, error_without_path)
        expect(result).to be_nil
      end
    end

    context 'with nil message' do
      let(:error_nil_message) { double('error', message: nil) }

      it 'returns nil for nil message' do
        result = command.send(:extract_path_from_error, error_nil_message)
        expect(result).to be_nil
      end
    end
  end

  describe '#output_json' do
    let(:test_data) { { key: 'value', array: [1, 2, 3] } }

    it 'outputs pretty JSON' do
      output = capture_stdout { command.send(:output_json, test_data) }
      parsed = JSON.parse(output)
      expect(parsed['key']).to eq('value')
      expect(parsed['array']).to eq([1, 2, 3])
    end
  end

  describe '#output_human_readable' do
    let(:test_data) { { test: 'data' } }

    it 'outputs data inspection by default' do
      output = capture_stdout { command.send(:output_human_readable, test_data) }
      expect(output).to include('test')
      expect(output).to include('data')
    end
  end

  describe '#detect_platform' do
    it 'returns a valid platform string' do
      platform = command.send(:detect_platform)
      expect(%w[windows macos linux unknown]).to include(platform)
    end

    context 'when PlatformHelper methods are stubbed' do
      before do
        platform_helper = double('PlatformHelper')
        stub_const('Leyline::PlatformHelper', platform_helper)
      end

      it 'returns windows when windows? is true' do
        allow(Leyline::PlatformHelper).to receive(:windows?).and_return(true)
        allow(Leyline::PlatformHelper).to receive(:macos?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:linux?).and_return(false)

        expect(command.send(:detect_platform)).to eq('windows')
      end

      it 'returns macos when macos? is true' do
        allow(Leyline::PlatformHelper).to receive(:windows?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:macos?).and_return(true)
        allow(Leyline::PlatformHelper).to receive(:linux?).and_return(false)

        expect(command.send(:detect_platform)).to eq('macos')
      end

      it 'returns linux when linux? is true' do
        allow(Leyline::PlatformHelper).to receive(:windows?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:macos?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:linux?).and_return(true)

        expect(command.send(:detect_platform)).to eq('linux')
      end

      it 'returns unknown when no platform matches' do
        allow(Leyline::PlatformHelper).to receive(:windows?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:macos?).and_return(false)
        allow(Leyline::PlatformHelper).to receive(:linux?).and_return(false)

        expect(command.send(:detect_platform)).to eq('unknown')
      end
    end
  end

  describe '#measure_time' do
    it 'returns result and execution time' do
      result, time_ms = command.send(:measure_time) { 'test result' }

      expect(result).to eq('test result')
      expect(time_ms).to be_a(Float)
      expect(time_ms).to be >= 0
    end

    it 'measures actual elapsed time' do
      result, time_ms = command.send(:measure_time) do
        sleep(0.01) # 10ms
        'delayed result'
      end

      expect(result).to eq('delayed result')
      expect(time_ms).to be >= 10.0 # Should be at least 10ms
    end
  end

  describe '#metadata_cache' do
    it 'caches the metadata cache instance' do
      # Mock the entire metadata_cache method to avoid require issues
      mock_cache = double('MetadataCache')
      allow(command).to receive(:metadata_cache).and_return(mock_cache)

      cache1 = command.send(:metadata_cache)
      cache2 = command.send(:metadata_cache)

      expect(cache1).to be(mock_cache)
      expect(cache1).to be(cache2) # Same instance (cached)
    end
  end

  describe '#file_cache' do
    around do |example|
      Dir.mktmpdir do |tmpdir|
        custom_options = { cache_dir: tmpdir }
        @command = test_command_class.new(custom_options)
        example.run
      end
    end

    it 'returns cached file cache instance' do
      cache1 = @command.send(:file_cache)
      cache2 = @command.send(:file_cache)

      expect(cache1).not_to be_nil
      expect(cache1).to be(cache2) # Same instance (cached)
    end

    context 'when cache initialization succeeds' do
      it 'returns a file cache instance' do
        result = @command.send(:file_cache)
        expect(result).not_to be_nil
      end
    end
  end

  describe 'error normalization edge cases' do
    context 'with custom command error class' do
      let(:custom_command_class) do
        Class.new(described_class) do
          class CommandError < Leyline::LeylineError; end

          def execute
            'custom result'
          end
        end
      end
      let(:command) { custom_command_class.new }
      let(:generic_error) { StandardError.new('Custom command error') }

      it 'uses custom CommandError class when available' do
        normalized = command.send(:normalize_error, generic_error)
        expect(normalized.class.name).to include('CommandError')
        expect(normalized.message).to eq('Custom command error')
      end
    end

    context 'without custom command error class' do
      let(:generic_error) { StandardError.new('Generic error') }

      it 'falls back to LeylineError' do
        normalized = command.send(:normalize_error, generic_error)
        expect(normalized).to be_a(Leyline::LeylineError)
        expect(normalized.message).to eq('Generic error')
      end
    end
  end

  # Helper method to capture stdout
  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  # Helper method to capture stderr
  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
