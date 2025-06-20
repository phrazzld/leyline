# frozen_string_literal: true

require 'fileutils'

module Leyline
  module Sync
    class GitClient
      class GitNotAvailableError < StandardError; end

      class GitCommandError < StandardError
        attr_reader :command, :exit_status

        def initialize(message, command = nil, exit_status = nil)
          super(message)
          @command = command
          @exit_status = exit_status
        end
      end

      attr_reader :working_directory

      def initialize
        @working_directory = nil
      end

      def git_available?
        system('which git > /dev/null 2>&1')
      end

      def setup_sparse_checkout(directory)
        unless git_available?
          raise GitNotAvailableError, 'Git binary not found. Please install git and ensure it is in your PATH.'
        end

        # Create directory if it doesn't exist
        FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

        @working_directory = directory

        # Initialize git repository
        run_git_command('init')

        # Enable sparse checkout
        run_git_command('config core.sparseCheckout true')
      end

      def cleanup
        return if @working_directory.nil?

        if Dir.exist?(@working_directory)
          FileUtils.rm_rf(@working_directory)
        end

        @working_directory = nil
      end

      private

      def run_git_command(command, chdir: nil)
        work_dir = chdir || @working_directory
        git_command = "git #{command}"

        success = system(
          git_command,
          chdir: work_dir,
          out: '/dev/null',
          err: '/dev/null'
        )

        unless success
          exit_status = $? ? $?.exitstatus : 'unknown'
          raise GitCommandError.new(
            "Git command failed: #{git_command} (exit status: #{exit_status})",
            git_command,
            exit_status
          )
        end
      end
    end
  end
end
