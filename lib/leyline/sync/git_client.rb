# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require_relative '../errors'

module Leyline
  module Sync
    class GitClient
      class GitNotAvailableError < GitError
        def recovery_suggestions
          [
            'Install git using your system package manager',
            'On macOS: brew install git',
            'On Ubuntu/Debian: sudo apt-get install git',
            'Ensure git is in your PATH'
          ]
        end
      end

      class GitCommandError < GitError
        attr_reader :command, :exit_status

        def initialize(message, command = nil, exit_status = nil)
          super(message, command: command, exit_status: exit_status)
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

      def add_sparse_paths(paths)
        raise GitCommandError, 'No working directory set. Call setup_sparse_checkout first.' if @working_directory.nil?

        # Handle nil/empty arrays
        paths = Array(paths)
        return if paths.empty?

        # Validate paths
        paths.each do |path|
          validate_sparse_path(path)
        end

        # Ensure .git/info directory exists
        git_info_dir = File.join(@working_directory, '.git', 'info')
        FileUtils.mkdir_p(git_info_dir) unless Dir.exist?(git_info_dir)

        # Write paths to sparse-checkout file
        sparse_checkout_file = File.join(git_info_dir, 'sparse-checkout')

        File.open(sparse_checkout_file, 'a') do |file|
          paths.each do |path|
            file.puts(path)
          end
        end
      end

      def fetch_version(remote_url, version_ref)
        raise GitCommandError, 'No working directory set. Call setup_sparse_checkout first.' if @working_directory.nil?

        # Validate inputs
        validate_remote_url(remote_url)
        validate_version_reference(version_ref) unless version_ref.nil?

        # Default to HEAD if no version specified
        version_ref ||= 'HEAD'

        # Add remote (handle existing remote)
        add_remote_origin(remote_url)

        # Fetch the specified version
        run_git_command("fetch origin #{version_ref}")

        # Checkout the fetched version
        run_git_command('checkout FETCH_HEAD')
      end

      def cleanup
        return if @working_directory.nil?

        FileUtils.rm_rf(@working_directory) if Dir.exist?(@working_directory)

        @working_directory = nil
      end

      private

      def validate_sparse_path(path)
        # Check for invalid characters/patterns
        if path.include?(' ')
          raise GitCommandError, "Invalid sparse-checkout path '#{path}': paths cannot contain spaces"
        end

        if path.start_with?('/')
          raise GitCommandError, "Invalid sparse-checkout path '#{path}': absolute paths not allowed"
        end

        return unless path.include?('../')

        raise GitCommandError, "Invalid sparse-checkout path '#{path}': parent directory traversal not allowed"
      end

      def validate_remote_url(url)
        # Basic URL format validation - support https, http, git@, and file:// URLs
        valid_patterns = [
          %r{\A(https?://|git@)[\w\-.]+[\w-]+(/[\w\-.]+)*\.git\z}, # Remote URLs
          %r{\Afile://.*\z} # Local file URLs
        ]

        return if valid_patterns.any? { |pattern| url.match?(pattern) }

        raise GitCommandError, "Invalid remote URL format: #{url}"
      end

      def validate_version_reference(ref)
        # Check for path traversal and other invalid patterns
        raise GitCommandError, "Invalid version reference: #{ref}" if ref.include?('../') || ref.include?('..\\')

        # Check for other potentially dangerous patterns
        return unless ref.include?(' ') || ref.start_with?('-')

        raise GitCommandError, "Invalid version reference: #{ref}"
      end

      def add_remote_origin(remote_url)
        run_git_command("remote add origin #{remote_url}")
      rescue GitCommandError => e
        # If remote already exists, remove it and try again
        raise e unless e.message.include?('already exists') || e.message.include?('remote origin')

        run_git_command('remote remove origin')
        run_git_command("remote add origin #{remote_url}")
      end

      def run_git_command(command, chdir: nil)
        work_dir = chdir || @working_directory
        git_command = "git #{command}"

        # Capture stderr for better error messages
        stderr_file = Tempfile.new('git-stderr')

        begin
          success = system(
            git_command,
            chdir: work_dir,
            out: '/dev/null',
            err: stderr_file.path
          )

          unless success
            exit_status = $? ? $?.exitstatus : 'unknown'
            stderr_content = begin
              File.read(stderr_file.path)
            rescue StandardError
              ''
            end

            # Enhance error message based on stderr content
            error_message = build_git_error_message(git_command, exit_status, stderr_content)

            raise GitCommandError.new(
              error_message,
              git_command,
              exit_status
            )
          end
        ensure
          stderr_file.close
          stderr_file.unlink
        end
      end

      def build_git_error_message(command, exit_status, stderr_content)
        base_msg = "Git command failed: #{command} (exit status: #{exit_status})"

        # Add context based on common git errors
        if stderr_content.include?('Permission denied')
          "#{base_msg} - Permission denied. Check file permissions and SSH keys."
        elsif stderr_content.include?('Could not resolve host')
          "#{base_msg} - Network error. Check internet connection."
        elsif stderr_content.include?('Authentication failed')
          "#{base_msg} - Authentication failed. Check credentials."
        elsif stderr_content.include?('index.lock')
          "#{base_msg} - Repository locked. Another git process may be running."
        elsif stderr_content.include?('disk quota exceeded')
          "#{base_msg} - Disk quota exceeded. Free up disk space."
        elsif stderr_content.include?('No space left on device')
          "#{base_msg} - No disk space available."
        elsif stderr_content.empty?
          base_msg
        else
          # Include first line of stderr if not recognized
          first_line = stderr_content.lines.first&.strip || ''
          "#{base_msg} - #{first_line}"
        end
      end
    end
  end
end
