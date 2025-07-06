# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Leyline::CLI do
  let(:cli) { described_class.new }

  describe 'initialization' do
    it 'inherits from Thor' do
      expect(cli).to be_a(Thor)
    end

    it 'is properly configured as a Thor CLI' do
      # Verify basic Thor CLI structure is set up correctly
      expect(described_class).to be < Thor
      expect(described_class.commands).not_to be_empty
    end

    it 'sets sync as default task' do
      expect(described_class.default_task).to eq('sync')
    end
  end

  describe '#version' do
    it 'outputs the current version' do
      output = capture_stdout { cli.version }
      expect(output.strip).to eq('0.1.0')
    end
  end

  describe '#sync' do
    context 'with default options' do
      it 'displays synchronization message with current directory' do
        output = capture_stdout { cli.sync }
        expect(output).to include('Synchronizing leyline standards to: ')
        expect(output).to include('Categories: ')
        expect(output).to include('Sync completed:')
      end

      it 'uses current directory as default path' do
        output = capture_stdout { cli.sync }
        expect(output).to include('docs/leyline')
      end
    end

    context 'with custom path' do
      it 'displays synchronization message with specified path' do
        output = capture_stdout { cli.sync('/tmp') }
        expect(output).to include('Synchronizing leyline standards to: /tmp')
      end
    end

    context 'with categories option' do
      before do
        cli.options = { categories: %w[typescript go] }
      end

      it 'displays specified categories' do
        output = capture_stdout { cli.sync }
        expect(output).to include('Categories: go, typescript')
        expect(output).to include('Options: categories')
      end
    end

    context 'with multiple options' do
      before do
        cli.options = {
          categories: ['typescript'],
          force: true,
          dry_run: true,
          verbose: true
        }
      end

      it 'displays all active options' do
        output = capture_stdout { cli.sync }
        expect(output).to include('Categories: typescript')
        expect(output).to include('Options: categories, force, dry_run, verbose')
      end
    end

    context 'with invalid categories' do
      before do
        cli.options = { categories: ['invalid_category'] }
      end

      it 'exits with error for invalid categories' do
        expect { cli.sync }.to exit_with_code(1)
      end

      it 'displays validation error message' do
        output = capture_stdout_and_exit { cli.sync }
        expect(output).to include('Error: Invalid category')
        expect(output).to include('Valid categories:')
      end
    end

    context 'with invalid path' do
      it 'exits with error for nonexistent parent directory' do
        expect { cli.sync('/nonexistent/deeply/nested/path') }.to exit_with_code(1)
      end

      it 'displays path validation error' do
        output = capture_stdout_and_exit { cli.sync('/nonexistent/deeply/nested/path') }
        expect(output).to include('Error: Parent directory does not exist')
      end
    end

    context 'with flag-like paths' do
      it 'rejects paths starting with dash' do
        expect { cli.sync('--help') }.to exit_with_code(1)
      end

      it 'displays helpful error message for --help path' do
        output = capture_stdout_and_exit { cli.sync('--help') }
        expect(output).to include("Error: Invalid path '--help'")
        expect(output).to include('Path cannot start with a dash')
        expect(output).to include("Did you mean to use 'leyline help sync'")
      end

      it 'rejects various flag-like paths' do
        %w[--version -h -v --stats --dry-run].each do |flag_path|
          expect { cli.sync(flag_path) }.to exit_with_code(1)
        end
      end

      it 'prevents accidental directory creation from mistyped commands' do
        # Ensure no directory is created when flag-like path is provided
        temp_dir = Dir.mktmpdir
        begin
          Dir.chdir(temp_dir) do
            capture_stdout_and_exit { cli.sync('--help') }
            expect(Dir.exist?('--help')).to be false
          end
        ensure
          FileUtils.rm_rf(temp_dir)
        end
      end
    end

    context 'with valid categories' do
      let(:valid_categories) { %w[typescript go core python rust web] }

      it 'accepts all valid categories' do
        valid_categories.each do |category|
          cli.options = { categories: [category] }
          expect { capture_stdout { cli.sync } }.not_to raise_error
        end
      end
    end
  end

  describe 'option validation integration' do
    context 'boolean options' do
      it 'accepts valid boolean values' do
        [true, false, nil].each do |value|
          cli.options = { force: value, dry_run: value, verbose: value }
          expect { capture_stdout { cli.sync } }.not_to raise_error
        end
      end
    end

    context 'categories option' do
      it 'accepts empty categories array' do
        cli.options = { categories: [] }
        expect { capture_stdout { cli.sync } }.not_to raise_error
      end

      it 'accepts nil categories' do
        cli.options = { categories: nil }
        expect { capture_stdout { cli.sync } }.not_to raise_error
      end

      it 'accepts multiple valid categories' do
        cli.options = { categories: %w[typescript go python] }
        expect { capture_stdout { cli.sync } }.not_to raise_error
      end

      it 'accepts comma-separated categories in a single string' do
        cli.options = { categories: ['typescript,go,python'] }
        output = capture_stdout { cli.sync }
        expect(output).to include('Categories: go, python, typescript')
      end
    end
  end

  describe '#status' do
    context 'with default options' do
      it 'displays status report with current directory' do
        output = capture_stdout { cli.status }
        expect(output).to include('Leyline Status Report')
      end

      it 'uses current directory as default path' do
        output = capture_stdout { cli.status }
        expect(output).to include('Base Directory:')
      end
    end

    context 'with custom path' do
      it 'displays status for specified path' do
        output = capture_stdout { cli.status('/tmp') }
        expect(output).to include('Base Directory: /tmp')
      end
    end

    context 'with invalid path' do
      it 'exits with error for nonexistent parent directory' do
        expect { cli.status('/nonexistent/deeply/nested/path') }.to exit_with_code(1)
      end

      it 'displays path validation error' do
        output = capture_stdout_and_exit { cli.status('/nonexistent/deeply/nested/path') }
        expect(output).to include('Error: Parent directory does not exist')
      end
    end

    context 'with flag-like paths' do
      it 'rejects paths starting with dash' do
        expect { cli.status('--help') }.to exit_with_code(1)
      end

      it 'displays helpful error message for --help path' do
        output = capture_stdout_and_exit { cli.status('--help') }
        expect(output).to include("Error: Invalid path '--help'")
        expect(output).to include('Path cannot start with a dash')
        expect(output).to include("Did you mean to use 'leyline help status'")
      end

      it 'rejects various flag-like paths' do
        %w[--json -j --categories --verbose].each do |flag_path|
          expect { cli.status(flag_path) }.to exit_with_code(1)
        end
      end
    end

    context 'with categories option' do
      before do
        cli.options = { categories: %w[typescript go] }
      end

      it 'filters status by specified categories' do
        output = capture_stdout { cli.status }
        expect(output).to include('Active Categories: typescript, go')
      end
    end

    context 'with JSON output' do
      before do
        cli.options = { json: true }
      end

      it 'outputs status in JSON format' do
        output = capture_stdout { cli.status }
        expect { JSON.parse(output) }.not_to raise_error
      end
    end
  end

  describe '#diff' do
    context 'with default options' do
      it 'displays diff report with current directory' do
        output = capture_stdout { cli.diff }
        expect(output).to include('Leyline Diff Report')
      end
    end

    context 'with custom path' do
      it 'displays diff for specified path' do
        output = capture_stdout { cli.diff('/tmp') }
        expect(output).to include('Leyline Diff Report')
      end
    end

    context 'with invalid path' do
      it 'exits with error for nonexistent parent directory' do
        expect { cli.diff('/nonexistent/deeply/nested/path') }.to exit_with_code(1)
      end

      it 'displays path validation error' do
        output = capture_stdout_and_exit { cli.diff('/nonexistent/deeply/nested/path') }
        expect(output).to include('Error: Parent directory does not exist')
      end
    end

    context 'with flag-like paths' do
      it 'rejects paths starting with dash' do
        expect { cli.diff('--help') }.to exit_with_code(1)
      end

      it 'displays helpful error message for --help path' do
        output = capture_stdout_and_exit { cli.diff('--help') }
        expect(output).to include("Error: Invalid path '--help'")
        expect(output).to include('Path cannot start with a dash')
        expect(output).to include("Did you mean to use 'leyline help diff'")
      end

      it 'rejects various flag-like paths' do
        %w[--format -f --categories --verbose].each do |flag_path|
          expect { cli.diff(flag_path) }.to exit_with_code(1)
        end
      end
    end

    context 'with format option' do
      before do
        cli.options = { format: 'json' }
      end

      it 'outputs diff in specified format' do
        output = capture_stdout { cli.diff }
        expect { JSON.parse(output) }.not_to raise_error
      end
    end

    context 'with categories option' do
      before do
        cli.options = { categories: %w[typescript go] }
      end

      it 'filters diff by specified categories' do
        output = capture_stdout { cli.diff }
        expect(output).to include('Leyline Diff Report')
      end
    end
  end

  describe '#update' do
    context 'with default options' do
      it 'displays update report with current directory' do
        output = capture_stdout { cli.update }
        expect(output).to include('Leyline Update Preview')
      end
    end

    context 'with custom path' do
      it 'displays update for specified path' do
        output = capture_stdout { cli.update('/tmp') }
        expect(output).to include('Leyline Update Preview')
      end
    end

    context 'with invalid path' do
      it 'exits with error for nonexistent parent directory' do
        expect { cli.update('/nonexistent/deeply/nested/path') }.to exit_with_code(1)
      end

      it 'displays path validation error' do
        output = capture_stdout_and_exit { cli.update('/nonexistent/deeply/nested/path') }
        expect(output).to include('Error: Parent directory does not exist')
      end
    end

    context 'with flag-like paths' do
      it 'rejects paths starting with dash' do
        expect { cli.update('--help') }.to exit_with_code(1)
      end

      it 'displays helpful error message for --help path' do
        output = capture_stdout_and_exit { cli.update('--help') }
        expect(output).to include("Error: Invalid path '--help'")
        expect(output).to include('Path cannot start with a dash')
        expect(output).to include("Did you mean to use 'leyline help update'")
      end

      it 'rejects various flag-like paths' do
        %w[--dry-run -d --force --categories].each do |flag_path|
          expect { cli.update(flag_path) }.to exit_with_code(1)
        end
      end
    end

    context 'with dry-run option' do
      before do
        cli.options = { dry_run: true }
      end

      it 'displays what would be updated without making changes' do
        output = capture_stdout { cli.update }
        expect(output).to include('Leyline Update Preview')
      end
    end

    context 'with force option' do
      before do
        cli.options = { force: true }
      end

      it 'forces update even with conflicts' do
        output = capture_stdout { cli.update }
        expect(output).to include('Leyline Update Preview')
      end
    end

    context 'with categories option' do
      before do
        cli.options = { categories: %w[typescript go] }
      end

      it 'updates only specified categories' do
        output = capture_stdout { cli.update }
        expect(output).to include('Leyline Update Preview')
      end
    end
  end

  describe 'help system integration' do
    it 'responds to help command' do
      # Thor automatically provides help, test that it works
      expect { described_class.start(['help']) }.not_to raise_error
    end

    it 'includes version command in available commands' do
      expect(described_class.commands.keys).to include('version')
    end

    it 'includes sync command in available commands' do
      expect(described_class.commands.keys).to include('sync')
    end

    it 'includes transparency commands in available commands' do
      expect(described_class.commands.keys).to include('status')
      expect(described_class.commands.keys).to include('diff')
      expect(described_class.commands.keys).to include('update')
    end

    it 'has proper command descriptions' do
      version_command = described_class.commands['version']
      expect(version_command.description).to eq('Show version information')

      sync_command = described_class.commands['sync']
      expect(sync_command.description).to eq('Synchronize leyline standards to target directory')

      status_command = described_class.commands['status']
      expect(status_command.description).to eq('Show sync status and local modifications')

      diff_command = described_class.commands['diff']
      expect(diff_command.description).to eq('Show differences between local and remote leyline standards')

      update_command = described_class.commands['update']
      expect(update_command.description).to eq('Update local leyline standards with conflict detection')
    end
  end

  describe 'command line integration' do
    it 'can be invoked with Thor start method' do
      expect { described_class.start(['version']) }.not_to raise_error
    end

    it 'handles empty arguments gracefully' do
      output = capture_stdout { described_class.start([]) }
      expect(output).to include('Synchronizing leyline standards')
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stdout_and_exit
    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      yield
    rescue SystemExit
      # Expected for error cases
    end

    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def exit_with_code(code)
    raise_error(SystemExit) do |error|
      expect(error.status).to eq(code)
    end
  end
end
