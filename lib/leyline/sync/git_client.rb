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

      def add_sparse_paths(paths)
        if @working_directory.nil?
          raise GitCommandError, 'No working directory set. Call setup_sparse_checkout first.'
        end

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
        if @working_directory.nil?
          raise GitCommandError, 'No working directory set. Call setup_sparse_checkout first.'
        end

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
        run_git_command("checkout FETCH_HEAD")
      end

      def cleanup
        return if @working_directory.nil?

        if Dir.exist?(@working_directory)
          FileUtils.rm_rf(@working_directory)
        end

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

        if path.include?('../')
          raise GitCommandError, "Invalid sparse-checkout path '#{path}': parent directory traversal not allowed"
        end
      end

      def validate_remote_url(url)
        # Basic URL format validation - support https, http, git@, and file:// URLs
        valid_patterns = [
          /\A(https?:\/\/|git@)[\w\-\.]+[\w\-]+(\/[\w\-\.]+)*\.git\z/,  # Remote URLs
          /\Afile:\/\/.*\z/  # Local file URLs
        ]

        unless valid_patterns.any? { |pattern| url.match?(pattern) }
          raise GitCommandError, "Invalid remote URL format: #{url}"
        end
      end

      def validate_version_reference(ref)
        # Check for path traversal and other invalid patterns
        if ref.include?('../') || ref.include?('..\\')
          raise GitCommandError, "Invalid version reference: #{ref}"
        end

        # Check for other potentially dangerous patterns
        if ref.include?(' ') || ref.start_with?('-')
          raise GitCommandError, "Invalid version reference: #{ref}"
        end
      end

      def add_remote_origin(remote_url)
        begin
          run_git_command("remote add origin #{remote_url}")
        rescue GitCommandError => e
          # If remote already exists, remove it and try again
          if e.message.include?('already exists') || e.message.include?('remote origin')
            run_git_command("remote remove origin")
            run_git_command("remote add origin #{remote_url}")
          else
            raise e
          end
        end
      end

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
