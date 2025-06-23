# frozen_string_literal: true

require 'etc'

module Leyline
  # Platform-specific helpers for cross-platform reliability
  # Handles the messy reality of different operating systems
  class PlatformHelper
    class << self
      def windows?
        RUBY_PLATFORM =~ /mswin|mingw|cygwin/
      end

      def macos?
        RUBY_PLATFORM =~ /darwin/
      end

      def linux?
        RUBY_PLATFORM =~ /linux/
      end

      def wsl?
        linux? && File.exist?('/proc/version') &&
          File.read('/proc/version').include?('Microsoft')
      end

      # Maximum path length for current platform
      def max_path_length
        if windows?
          # Traditional Windows limit, though modern Windows can handle more
          260
        elsif macos?
          # macOS practical limit
          1024
        else
          # Linux theoretical limit
          4096
        end
      end

      # Check if filesystem is case-sensitive
      def case_sensitive_filesystem?(path = '.')
        return @case_sensitive if defined?(@case_sensitive)

        Dir.mktmpdir do |tmpdir|
          test_file = File.join(tmpdir, 'CaseSensitiveTest')
          File.write(test_file, 'test')

          # Try to access with different case
          alt_path = File.join(tmpdir, 'casesensitivetest')
          @case_sensitive = !File.exist?(alt_path)
        end
      rescue
        # Assume case-sensitive if we can't determine
        @case_sensitive = true
      end

      # Normalize path for current platform
      def normalize_path(path)
        normalized = path.to_s

        # Handle Windows path separators
        if windows?
          normalized = normalized.tr('/', '\\')
        else
          normalized = normalized.tr('\\', '/')
        end

        # Remove redundant separators
        normalized = normalized.squeeze('/')
        normalized = normalized.squeeze('\\') if windows?

        # Handle Unicode normalization (important for macOS)
        if macos?
          normalized = normalized.unicode_normalize(:nfc)
        end

        normalized
      end

      # Check if filename is valid for platform
      def valid_filename?(filename)
        return false if filename.nil? || filename.empty?

        if windows?
          # Windows reserved names
          reserved = %w[CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7
                       COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9]

          base_name = File.basename(filename, '.*').upcase
          return false if reserved.include?(base_name)

          # Windows forbidden characters
          return false if filename =~ /[<>:"|?*]/

          # Trailing dots and spaces
          return false if filename =~ /[\. ]$/
        end

        # Path traversal
        return false if filename.include?('..')

        # Control characters
        return false if filename =~ /[\x00-\x1f]/

        true
      end

      # Get optimal number of parallel workers for current system
      def optimal_worker_count
        cpu_count = Etc.nprocessors

        if windows?
          # Windows has higher thread overhead
          [cpu_count / 2, 1].max
        elsif macos?
          # macOS handles threads well
          [cpu_count, 4].min
        else
          # Linux can handle more
          [cpu_count, 8].min
        end
      rescue
        # Conservative fallback
        2
      end

      # Platform-specific temporary directory
      def temp_dir
        if windows?
          ENV['TEMP'] || ENV['TMP'] || 'C:/Windows/Temp'
        else
          ENV['TMPDIR'] || '/tmp'
        end
      end

      # Check if running with elevated privileges
      def elevated_privileges?
        if windows?
          # Check if running as Administrator
          system('net session >nul 2>&1')
        else
          # Check if running as root
          Process.uid == 0
        end
      end

      # Get platform-specific config directory
      def config_home
        if windows?
          ENV['APPDATA'] || File.join(ENV['USERPROFILE'] || 'C:', 'leyline')
        elsif macos?
          File.join(ENV['HOME'], 'Library', 'Application Support', 'leyline')
        else
          ENV['XDG_CONFIG_HOME'] || File.join(ENV['HOME'], '.config', 'leyline')
        end
      end

      # Platform-aware file locking
      def with_file_lock(path, &block)
        if windows?
          # Windows file locking is different
          with_windows_file_lock(path, &block)
        else
          # Unix-style file locking
          with_unix_file_lock(path, &block)
        end
      rescue Errno::EACCES => e
        raise Leyline::FileSystemError.new(
          "Cannot acquire lock - permission denied",
          reason: :permission_denied,
          path: path,
          platform: current_platform
        )
      rescue Errno::ENOSPC => e
        raise Leyline::CacheOperationError.new(
          "Cannot create lock file - no space left on device",
          operation: :disk_full,
          path: path
        )
      rescue Errno::EROFS => e
        raise Leyline::FileSystemError.new(
          "Cannot create lock file - filesystem is read-only",
          reason: :read_only_filesystem,
          path: path
        )
      end

      # Get current platform as string
      def current_platform
        if windows?
          'windows'
        elsif macos?
          'macos'
        elsif linux?
          'linux'
        else
          'unknown'
        end
      end

      # Check if running in a container
      def containerized?
        return @containerized if defined?(@containerized)

        @containerized = File.exist?('/.dockerenv') ||
                        File.exist?('/run/.containerenv') ||
                        (File.exist?('/proc/1/cgroup') &&
                         File.read('/proc/1/cgroup').include?('docker'))
      rescue
        @containerized = false
      end

      # Check available disk space
      def check_disk_space(path)
        require 'sys/filesystem'
        stat = Sys::Filesystem.stat(path)
        {
          available: stat.bytes_available,
          total: stat.bytes_total,
          percent_free: (stat.bytes_available.to_f / stat.bytes_total * 100).round(2)
        }
      rescue LoadError
        # sys-filesystem gem not available, use df
        df_output = `df -k "#{path}" 2>/dev/null | tail -1`
        if df_output && !df_output.empty?
          parts = df_output.split
          {
            available: parts[3].to_i * 1024,
            total: parts[1].to_i * 1024,
            percent_free: (100 - parts[4].to_i)
          }
        else
          nil
        end
      rescue
        nil
      end

      private

      def with_windows_file_lock(path, &block)
        # Windows requires special handling for file locks
        lock_file = "#{path}.lock"
        acquired = false

        10.times do
          begin
            File.open(lock_file, File::CREAT | File::EXCL | File::WRONLY) do |f|
              acquired = true
              yield
            end
            break
          rescue Errno::EEXIST
            # Lock exists, wait and retry
            sleep(0.1)
          end
        end

        raise "Could not acquire lock on #{path}" unless acquired
      ensure
        File.delete(lock_file) if acquired && File.exist?(lock_file)
      end

      def with_unix_file_lock(path, &block)
        File.open("#{path}.lock", File::CREAT) do |f|
          f.flock(File::LOCK_EX)
          yield
        end
      end
    end
  end
end
