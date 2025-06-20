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
        cli.options = { categories: ['typescript', 'go'] }
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
        cli.options = { categories: ['typescript', 'go', 'python'] }
        expect { capture_stdout { cli.sync } }.not_to raise_error
      end

      it 'accepts comma-separated categories in a single string' do
        cli.options = { categories: ['typescript,go,python'] }
        output = capture_stdout { cli.sync }
        expect(output).to include('Categories: go, python, typescript')
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

    it 'has proper command descriptions' do
      version_command = described_class.commands['version']
      expect(version_command.description).to eq('Show version information')

      sync_command = described_class.commands['sync']
      expect(sync_command.description).to eq('Synchronize leyline standards to target directory')
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
