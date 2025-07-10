# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/status_command'

RSpec.describe Leyline::Commands::StatusCommand do
  let(:options) { {} }
  let(:command) { described_class.new(options) }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
  end

  describe '#initialize' do
    it 'inherits from BaseCommand' do
      expect(command).to be_a(Leyline::Commands::BaseCommand)
    end

    it 'sets default base directory' do
      expect(command.instance_variable_get(:@base_directory)).to eq(Dir.pwd)
    end

    context 'with custom directory' do
      let(:options) { { directory: temp_dir } }

      it 'uses provided directory' do
        expect(command.instance_variable_get(:@base_directory)).to eq(temp_dir)
      end
    end
  end

  describe '#execute' do
    let(:mock_sync_state) { instance_double(Leyline::SyncState) }
    let(:mock_file_comparator) { instance_double(Leyline::FileComparator) }
    let(:mock_metadata_cache) { instance_double(Leyline::Discovery::MetadataCache) }

    before do
      # Mock the status gathering data
      status_data = {
        version: '1.0.0',
        categories: ['typescript', 'go'],
        sync_state: {
          last_sync_time: '2025-01-01T00:00:00Z',
          synced_categories: ['typescript', 'go'],
          total_files: 25
        },
        local_changes: {
          modified: ['file1.md', 'file2.md'],
          added: ['file3.md'],
          removed: []
        },
        file_summary: {
          total_files: 25,
          modified_files: 2,
          added_files: 1,
          removed_files: 0
        }
      }

      allow(command).to receive(:gather_status_information).and_return(status_data)
      allow(command).to receive(:measure_time).and_yield.and_return([status_data, 500])
      allow(command).to receive(:cache_available?).and_return(true)
      allow(command).to receive(:output_result)
    end

    context 'with default options' do
      it 'returns status information' do
        result = command.execute

        expect(result).to be_a(Hash)
        expect(result[:sync_state]).to include(:last_sync_time, :synced_categories, :total_files)
        expect(result[:local_changes]).to include(:modified, :added, :removed)
        expect(result[:file_summary]).to include(:total_files, :modified_files, :added_files, :removed_files)
        expect(result[:performance]).to include(:execution_time_ms, :cache_enabled)
      end

      it 'outputs human-readable format' do
        expect(command).to receive(:output_result)
        command.execute
      end
    end

    context 'with JSON output' do
      let(:options) { { json: true } }

      it 'outputs JSON format' do
        expect(command).to receive(:output_result)
        command.execute
      end
    end

    context 'with verbose option' do
      let(:options) { { verbose: true } }

      it 'includes verbose information' do
        result = command.execute

        expect(result[:performance]).to include(:execution_time_ms, :cache_enabled)
      end
    end

    context 'with invalid path starting with dash' do
      let(:options) { { directory: '--invalid' } }

      it 'exits with error' do
        allow(command).to receive(:error_and_exit)

        command.execute

        expect(command).to have_received(:error_and_exit)
          .with(match(/Invalid path '--invalid'/))
      end
    end

    context 'with nonexistent parent directory' do
      let(:options) { { directory: '/nonexistent/path' } }

      it 'exits with error' do
        allow(command).to receive(:error_and_exit)

        command.execute

        expect(command).to have_received(:error_and_exit)
          .with(match(/Parent directory does not exist/))
      end
    end

    context 'when an error occurs' do
      before do
        allow(command).to receive(:gather_status_information).and_raise(StandardError.new('Test error'))
        allow(command).to receive(:handle_error)
      end

      it 'handles the error and returns nil' do
        result = command.execute

        expect(result).to be_nil
        expect(command).to have_received(:handle_error).with(instance_of(StandardError))
      end
    end
  end

  describe '#output_human_readable' do
    let(:status_data) do
      {
        version: '1.0.0',
        categories: ['typescript', 'go'],
        sync_state: {
          last_sync_time: '2025-01-01T00:00:00Z',
          synced_categories: ['typescript', 'go'],
          total_files: 25
        },
        local_changes: {
          modified: ['file1.md', 'file2.md'],
          added: ['file3.md'],
          removed: []
        },
        file_summary: {
          total_files: 25,
          modified_files: 2,
          added_files: 1,
          removed_files: 0,
          by_category: {}
        },
        performance: {
          execution_time_ms: 500,
          cache_enabled: true
        }
      }
    end

    before do
      # Mock all the helper methods to avoid deep testing of internals
      allow(command).to receive(:output_version_info)
      allow(command).to receive(:output_sync_state_info)
      allow(command).to receive(:output_local_changes_info)
      allow(command).to receive(:output_file_summary_info)
      allow(command).to receive(:output_performance_info)
    end

    it 'displays status report header' do
      output = capture_stdout { command.send(:output_human_readable, status_data) }

      expect(output).to include('Leyline Status Report')
      expect(output).to include('====================')
    end

    it 'displays version information' do
      command.send(:output_human_readable, status_data)
      expect(command).to have_received(:output_version_info).with(status_data)
    end

    it 'displays sync state information' do
      command.send(:output_human_readable, status_data)
      expect(command).to have_received(:output_sync_state_info).with(status_data[:sync_state])
    end

    it 'displays local changes information' do
      command.send(:output_human_readable, status_data)
      expect(command).to have_received(:output_local_changes_info).with(status_data[:local_changes])
    end

    it 'displays file summary information' do
      command.send(:output_human_readable, status_data)
      expect(command).to have_received(:output_file_summary_info).with(status_data[:file_summary])
    end

    context 'with verbose option' do
      let(:options) { { verbose: true } }

      it 'displays performance information' do
        command.send(:output_human_readable, status_data)
        expect(command).to have_received(:output_performance_info).with(status_data[:performance])
      end
    end

    context 'without verbose option' do
      it 'does not display performance information' do
        command.send(:output_human_readable, status_data)
        expect(command).not_to have_received(:output_performance_info)
      end
    end
  end

  describe 'StatusError' do
    let(:error) { described_class::StatusError.new('Test error') }

    it 'has correct error type' do
      expect(error.error_type).to eq(:command)
    end

    it 'provides helpful recovery suggestions' do
      suggestions = error.recovery_suggestions

      expect(suggestions).to include('Ensure the leyline directory exists: docs/leyline')
      expect(suggestions).to include('Run leyline sync first to initialize')
      expect(suggestions).to include('Check file permissions in the project directory')
    end
  end

  describe 'CommandError' do
    let(:error) { described_class::CommandError.new('Test error') }

    it 'inherits from StatusError' do
      expect(error).to be_a(described_class::StatusError)
    end

    it 'has correct error type' do
      expect(error.error_type).to eq(:command)
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
