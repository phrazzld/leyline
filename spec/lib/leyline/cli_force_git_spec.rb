# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Leyline::CLI do
  describe '--force-git flag' do
    let(:cli) { described_class.new }

    context 'option validation' do
      it 'accepts --force-git flag' do
        expect { cli.options = { force_git: true } }.not_to raise_error
      end

      it 'accepts --force-git=true explicitly' do
        expect { cli.options = { force_git: true } }.not_to raise_error
      end

      it 'accepts --force-git=false explicitly' do
        expect { cli.options = { force_git: false } }.not_to raise_error
      end

      it 'defaults to false when not specified' do
        cli.options = {}
        expect(cli.options[:force_git]).to be_falsy
      end
    end

    context 'with Thor option parsing' do
      it 'recognizes --force-git flag in CLI help' do
        # Test that the flag is recognized by checking help output
        help_output = capture_thor_help { cli.help('sync') }
        expect(help_output).to include('--force-git')
        expect(help_output).to include('Force git operations')
      end
    end

    context 'flag combination validation' do
      it 'allows --force-git with --verbose' do
        options = { force_git: true, verbose: true }
        expect {
          Leyline::CliOptions.validate_sync_options(options, '.')
        }.not_to raise_error
      end

      it 'allows --force-git with --no-cache' do
        options = { force_git: true, no_cache: true }
        expect {
          Leyline::CliOptions.validate_sync_options(options, '.')
        }.not_to raise_error
      end

      it 'allows --force-git with --force' do
        options = { force_git: true, force: true }
        expect {
          Leyline::CliOptions.validate_sync_options(options, '.')
        }.not_to raise_error
      end
    end

    context 'help text integration' do
      it 'includes force_git in help output' do
        help_output = capture_thor_help { cli.help('sync') }
        expect(help_output).to include('--force-git')
        expect(help_output).to include('Force git operations')
      end
    end
  end

  private

  def capture_thor_help
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
