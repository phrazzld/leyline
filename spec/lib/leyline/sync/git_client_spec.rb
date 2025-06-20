# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe Leyline::Sync::GitClient do
  let(:temp_dir) { Dir.mktmpdir('leyline-test') }
  let(:git_client) { described_class.new }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe 'initialization' do
    it 'creates a new git client instance' do
      expect(git_client).to be_a(described_class)
    end

    it 'initializes with no working directory' do
      expect(git_client.working_directory).to be_nil
    end
  end

  describe '#git_available?' do
    context 'when git is available' do
      it 'returns true' do
        allow(git_client).to receive(:system).with('which git > /dev/null 2>&1').and_return(true)
        expect(git_client.git_available?).to be true
      end
    end

    context 'when git is not available' do
      it 'returns false' do
        allow(git_client).to receive(:system).with('which git > /dev/null 2>&1').and_return(false)
        expect(git_client.git_available?).to be false
      end
    end
  end

  describe '#setup_sparse_checkout' do
    context 'when git is not available' do
      before do
        allow(git_client).to receive(:git_available?).and_return(false)
      end

      it 'raises GitNotAvailableError' do
        expect { git_client.setup_sparse_checkout(temp_dir) }.to raise_error(
          described_class::GitNotAvailableError,
          'Git binary not found. Please install git and ensure it is in your PATH.'
        )
      end
    end

    context 'when git is available' do
      before do
        allow(git_client).to receive(:git_available?).and_return(true)
        allow(git_client).to receive(:run_git_command)
      end

      it 'sets up sparse checkout in the specified directory' do
        expect(git_client).to receive(:run_git_command).with('init')
        expect(git_client).to receive(:run_git_command).with('config core.sparseCheckout true')

        git_client.setup_sparse_checkout(temp_dir)
        expect(git_client.working_directory).to eq(temp_dir)
      end

      it 'creates the directory if it does not exist' do
        non_existent_dir = File.join(temp_dir, 'new_directory')
        expect(Dir.exist?(non_existent_dir)).to be false

        allow(git_client).to receive(:run_git_command)
        git_client.setup_sparse_checkout(non_existent_dir)

        expect(Dir.exist?(non_existent_dir)).to be true
      end

      it 'handles git command failures' do
        allow(git_client).to receive(:run_git_command).and_raise(described_class::GitCommandError.new('git init failed'))

        expect { git_client.setup_sparse_checkout(temp_dir) }.to raise_error(
          described_class::GitCommandError,
          'git init failed'
        )
      end
    end
  end

  describe '#cleanup' do
    before do
      git_client.instance_variable_set(:@working_directory, temp_dir)
    end

    it 'removes the working directory' do
      expect(Dir.exist?(temp_dir)).to be true
      git_client.cleanup
      expect(Dir.exist?(temp_dir)).to be false
    end

    it 'resets the working directory to nil' do
      git_client.cleanup
      expect(git_client.working_directory).to be_nil
    end

    it 'handles missing directory gracefully' do
      FileUtils.rm_rf(temp_dir)
      expect { git_client.cleanup }.not_to raise_error
    end

    it 'does nothing if no working directory is set' do
      git_client.instance_variable_set(:@working_directory, nil)
      expect { git_client.cleanup }.not_to raise_error
    end
  end

  describe '#add_sparse_paths' do
    let(:test_paths) { ['docs/tenets', 'docs/bindings/core'] }

    context 'when working directory is not set' do
      it 'raises an error' do
        expect { git_client.add_sparse_paths(test_paths) }.to raise_error(
          described_class::GitCommandError,
          'No working directory set. Call setup_sparse_checkout first.'
        )
      end
    end

    context 'when working directory is set' do
      before do
        git_client.instance_variable_set(:@working_directory, temp_dir)
        FileUtils.mkdir_p(File.join(temp_dir, '.git', 'info'))
      end

      it 'writes paths to sparse-checkout file' do
        git_client.add_sparse_paths(test_paths)

        sparse_checkout_file = File.join(temp_dir, '.git', 'info', 'sparse-checkout')
        expect(File.exist?(sparse_checkout_file)).to be true

        content = File.read(sparse_checkout_file)
        expect(content).to include('docs/tenets')
        expect(content).to include('docs/bindings/core')
      end

      it 'creates .git/info directory if it does not exist' do
        FileUtils.rm_rf(File.join(temp_dir, '.git'))

        git_client.add_sparse_paths(test_paths)

        expect(Dir.exist?(File.join(temp_dir, '.git', 'info'))).to be true
      end

      it 'accepts empty array' do
        expect { git_client.add_sparse_paths([]) }.not_to raise_error
      end

      it 'accepts nil and treats as empty array' do
        expect { git_client.add_sparse_paths(nil) }.not_to raise_error
      end

      it 'validates path format' do
        invalid_paths = ['../outside', '/absolute/path', 'path with spaces']

        expect { git_client.add_sparse_paths(invalid_paths) }.to raise_error(
          described_class::GitCommandError,
          /Invalid sparse-checkout path/
        )
      end

      it 'appends to existing sparse-checkout file' do
        sparse_checkout_file = File.join(temp_dir, '.git', 'info', 'sparse-checkout')
        File.write(sparse_checkout_file, "existing/path\n")

        git_client.add_sparse_paths(['new/path'])

        content = File.read(sparse_checkout_file)
        expect(content).to include('existing/path')
        expect(content).to include('new/path')
      end
    end
  end

  describe 'error handling' do
    describe 'GitNotAvailableError' do
      it 'is a subclass of StandardError' do
        expect(described_class::GitNotAvailableError).to be < StandardError
      end
    end

    describe 'GitCommandError' do
      it 'is a subclass of StandardError' do
        expect(described_class::GitCommandError).to be < StandardError
      end

      it 'stores the command and exit status' do
        error = described_class::GitCommandError.new('git init failed', 'git init', 128)
        expect(error.message).to eq('git init failed')
        expect(error.command).to eq('git init')
        expect(error.exit_status).to eq(128)
      end
    end
  end

  describe 'private methods' do
    describe '#run_git_command' do
      it 'executes git commands in the working directory' do
        git_client.instance_variable_set(:@working_directory, temp_dir)

        expect(git_client).to receive(:system).with(
          'git status',
          chdir: temp_dir,
          out: '/dev/null',
          err: '/dev/null'
        ).and_return(true)

        git_client.send(:run_git_command, 'status')
      end

      it 'raises GitCommandError on failure' do
        git_client.instance_variable_set(:@working_directory, temp_dir)

        allow(git_client).to receive(:system).and_return(false)

        expect { git_client.send(:run_git_command, 'invalid-command') }.to raise_error(
          described_class::GitCommandError,
          /Git command failed: git invalid-command/
        )
      end
    end
  end
end
