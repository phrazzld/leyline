# frozen_string_literal: true

require 'spec_helper'
require 'leyline/commands/help_command'

RSpec.describe Leyline::Commands::HelpCommand do
  let(:options) { {} }
  let(:command) { described_class.new(options) }

  describe '#initialize' do
    it 'inherits from BaseCommand' do
      expect(command).to be_a(Leyline::Commands::BaseCommand)
    end

    it 'sets default values' do
      expect(command.instance_variable_get(:@command)).to be_nil
    end

    context 'with command option' do
      let(:options) { { command: 'sync' } }

      it 'stores the command option' do
        expect(command.instance_variable_get(:@command)).to eq('sync')
      end
    end
  end

  describe '#execute' do
    it 'displays comprehensive help' do
      expect { command.execute }.to output(
        a_string_including('LEYLINE CLI - Development Standards Synchronization')
      ).to_stdout
    end

    it 'includes command categories section' do
      expect { command.execute }.to output(
        a_string_including('COMMAND CATEGORIES:')
      ).to_stdout
    end

    it 'includes discovery commands section' do
      output = capture_stdout { command.execute }

      expect(output).to include('📋 DISCOVERY COMMANDS')
      expect(output).to include('discovery categories')
      expect(output).to include('discovery show CATEGORY')
      expect(output).to include('discovery search QUERY')
    end

    it 'includes sync commands section' do
      output = capture_stdout { command.execute }

      expect(output).to include('🔄 SYNC COMMANDS')
      expect(output).to include('sync [PATH]')
      expect(output).to include('status [PATH]')
      expect(output).to include('diff [PATH]')
      expect(output).to include('update [PATH]')
    end

    it 'includes utility commands section' do
      output = capture_stdout { command.execute }

      expect(output).to include('ℹ️  UTILITY COMMANDS')
      expect(output).to include('version')
      expect(output).to include('help [COMMAND]')
    end

    it 'includes quick start section' do
      output = capture_stdout { command.execute }

      expect(output).to include('QUICK START:')
      expect(output).to include('leyline sync')
      expect(output).to include('leyline status')
      expect(output).to include('leyline discovery categories')
      expect(output).to include('leyline discovery show typescript')
    end

    it 'includes legacy commands section' do
      output = capture_stdout { command.execute }

      expect(output).to include('LEGACY COMMANDS (backward compatibility):')
      expect(output).to include('leyline categories')
      expect(output).to include('leyline show typescript')
      expect(output).to include('leyline search "query"')
    end

    it 'includes performance optimization section' do
      output = capture_stdout { command.execute }

      expect(output).to include('PERFORMANCE OPTIMIZATION:')
      expect(output).to include('Cache automatically optimizes')
      expect(output).to include('Use category filtering (-c)')
      expect(output).to include('Add --stats to any command')
      expect(output).to include('Target response times: <2s')
    end

    it 'includes troubleshooting section' do
      output = capture_stdout { command.execute }

      expect(output).to include('TROUBLESHOOTING:')
      expect(output).to include('Run with -v (verbose) flag')
      expect(output).to include('Use --stats to monitor cache')
      expect(output).to include('Check ~/.cache/leyline')
      expect(output).to include('Ensure git is installed')
    end

    it 'includes documentation link' do
      output = capture_stdout { command.execute }

      expect(output).to include('Documentation: https://github.com/phrazzld/leyline')
    end

    it 'includes suggestion for specific command help' do
      output = capture_stdout { command.execute }

      expect(output).to include('For detailed help on any command: leyline help COMMAND')
    end

    it 'formats output with proper spacing and dividers' do
      output = capture_stdout { command.execute }

      expect(output).to include('=' * 60)
      expect(output).to include("\n\n")  # Contains blank lines for readability
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
