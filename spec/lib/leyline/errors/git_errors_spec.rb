# frozen_string_literal: true

require 'spec_helper'
require 'leyline/errors'

RSpec.describe 'Git-specific errors' do
  describe Leyline::GitError do
    it_behaves_like 'a leyline error' do
      let(:described_class) { Leyline::GitError }
    end

    it_behaves_like 'an error with context' do
      let(:described_class) { Leyline::GitError }
    end

    it_behaves_like 'an error with recovery suggestions' do
      let(:described_class) { Leyline::GitError }
    end

    describe 'GitNotAvailableError' do
      # Define the specialized error class
      before do
        stub_const('Leyline::GitNotAvailableError', Class.new(Leyline::GitError) do
          def recovery_suggestions
            [
              'Install git using your system package manager',
              'On macOS: brew install git',
              'On Ubuntu/Debian: sudo apt-get install git',
              'Ensure git is in your PATH'
            ]
          end
        end)
      end

      let(:error) { Leyline::GitNotAvailableError.new('Git binary not found') }

      it 'inherits from GitError' do
        expect(Leyline::GitNotAvailableError).to be < Leyline::GitError
      end

      it 'provides helpful recovery suggestions' do
        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Install git using your system package manager')
        expect(suggestions).to include('Ensure git is in your PATH')
      end

      it 'has git error type' do
        expect(error.error_type).to eq(:git)
      end
    end

    describe 'GitCommandError' do
      before do
        stub_const('Leyline::GitCommandError', Class.new(Leyline::GitError) do
          attr_reader :command, :exit_status

          def initialize(message, command = nil, exit_status = nil)
            super(message, { command: command, exit_status: exit_status }.compact)
            @command = command
            @exit_status = exit_status
          end

          def recovery_suggestions
            suggestions = []

            if exit_status == 128
              suggestions << 'Check if the repository is properly initialized'
              suggestions << 'Run: git init'
            elsif command&.include?('sparse-checkout')
              suggestions << 'Ensure git version supports sparse-checkout (2.25+)'
              suggestions << 'Check git version: git --version'
            end

            suggestions << 'Check git status and working directory'
            suggestions
          end
        end)
      end

      it 'stores command and exit status' do
        error = Leyline::GitCommandError.new('Command failed', 'git status', 128)
        expect(error.command).to eq('git status')
        expect(error.exit_status).to eq(128)
        expect(error.context[:command]).to eq('git status')
        expect(error.context[:exit_status]).to eq(128)
      end

      it 'provides context-aware recovery suggestions' do
        error = Leyline::GitCommandError.new('Not a git repository', 'git status', 128)
        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Check if the repository is properly initialized')
        expect(suggestions).to include('Run: git init')
      end

      it 'handles sparse-checkout errors' do
        error = Leyline::GitCommandError.new('sparse-checkout failed', 'git sparse-checkout init', 1)
        suggestions = error.recovery_suggestions
        expect(suggestions).to include('Ensure git version supports sparse-checkout (2.25+)')
      end
    end
  end
end
