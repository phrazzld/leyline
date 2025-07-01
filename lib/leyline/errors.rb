# frozen_string_literal: true

require 'uri'

module Leyline
  # Base error for all Leyline operations
  # Provides consistent error handling patterns with actionable recovery guidance
  class LeylineError < StandardError
    attr_reader :operation, :context, :category

    def initialize(message, operation: nil, context: {}, category: :general)
      @operation = operation
      @context = context || {}
      @category = category
      super(build_error_message(message))
    end

    # Subclasses should override to provide specific recovery suggestions
    def recovery_suggestions
      [
        "Run the command with --verbose for more detailed error information",
        "Check the Leyline documentation for troubleshooting guidance"
      ]
    end

    # Platform-aware recovery suggestions
    def platform_specific_suggestions
      suggestions = []
      case platform
      when :windows
        suggestions << "Ensure Windows Defender is not blocking file operations"
        suggestions << "Try running as Administrator if permission errors occur"
      when :macos
        suggestions << "Check System Preferences > Security & Privacy for file access permissions"
        suggestions << "Use 'sudo' if administrative access is required"
      when :linux
        suggestions << "Check file permissions with 'ls -la'"
        suggestions << "Use 'sudo' if administrative access is required"
      end
      suggestions
    end

    # Convert error to structured data for logging
    def to_h
      {
        error_class: self.class.name,
        message: message,
        operation: @operation,
        context: @context,
        category: @category,
        timestamp: Time.now.iso8601,
        platform: platform
      }
    end

    private

    def build_error_message(message)
      parts = [message]
      parts << "Operation: #{@operation}" if @operation

      if @context.any?
        context_info = @context.map { |k, v| "#{k}: #{v}" }.join(", ")
        parts << "Context: #{context_info}"
      end

      parts.join("\n")
    end

    def platform
      @platform ||= case RUBY_PLATFORM
                   when /win32|win64|\.NET|windows|cygwin|mingw32/i
                     :windows
                   when /darwin|mac os/i
                     :macos
                   when /linux/i
                     :linux
                   else
                     :unknown
                   end
    end
  end

  # Raised when conflicts are detected during update operations
  class ConflictDetectedError < LeylineError
    attr_reader :conflicts

    def initialize(conflicts, **options)
      @conflicts = Array(conflicts)

      message = build_conflict_message
      super(message, category: :conflict, **options)
    end

    def recovery_suggestions
      base_suggestions = [
        "Review conflicts carefully before proceeding",
        "Use 'leyline diff' to see exact differences",
        "Create backups of important local modifications"
      ]

      resolution_suggestions = [
        "Use --force to override local changes with remote versions",
        "Manually merge conflicts in affected files",
        "Use --dry-run to preview changes without applying them"
      ]

      base_suggestions + resolution_suggestions
    end

    def conflicted_paths
      @conflicts.map { |c| c.respond_to?(:path) ? c.path : c.to_s }
    end

    def conflict_count
      @conflicts.size
    end

    private

    def build_conflict_message
      count = @conflicts.size
      paths = conflicted_paths.first(3).join(", ")

      message = "#{count} conflict#{'s' if count > 1} detected"
      message += " in: #{paths}"
      message += " and #{count - 3} more" if count > 3
      message
    end
  end

  # Raised when sync state is invalid or corrupted
  class InvalidSyncStateError < LeylineError
    attr_reader :state_file, :validation_errors

    def initialize(message = "Sync state is invalid or corrupted", state_file: nil, validation_errors: [], **options)
      @state_file = state_file
      @validation_errors = validation_errors
      super(message, category: :sync_state, context: { state_file: state_file }, **options)
    end

    def recovery_suggestions
      suggestions = [
        "Run 'leyline sync --force' to rebuild sync state from scratch",
        "Verify cache directory permissions are correct"
      ]

      if @state_file
        suggestions << "Delete corrupted state file: rm '#{@state_file}'"
        suggestions << "Check disk space in cache directory"
      end

      if @validation_errors.any?
        suggestions << "Validation errors found: #{@validation_errors.join(', ')}"
      end

      suggestions + [
        "Clear entire cache if problems persist: rm -rf ~/.cache/leyline",
        "Check for concurrent leyline processes that might be corrupting state"
      ]
    end
  end

  # Raised when file comparison operations fail
  class ComparisonFailedError < LeylineError
    attr_reader :file_a, :file_b, :reason

    def initialize(file_a, file_b, reason: nil, **options)
      @file_a = file_a
      @file_b = file_b
      @reason = reason

      message = "Failed to compare files: #{file_a} and #{file_b}"
      message += " (#{reason})" if reason

      super(message, category: :comparison, context: { file_a: file_a, file_b: file_b, reason: reason }, **options)
    end

    def recovery_suggestions
      suggestions = ["Verify both files exist and are readable"]

      if @reason
        reason_lower = @reason.downcase
        if reason_lower.include?('permission')
          suggestions += [
            "Check file permissions: ls -la '#{@file_a}' '#{@file_b}'",
            "Ensure you have read access to both files"
          ]
        elsif reason_lower.include?('encoding')
          suggestions += [
            "Files may have encoding issues - ensure they are UTF-8",
            "Use 'file' command to check file types: file '#{@file_a}'"
          ]
        elsif reason_lower.include?('size') || reason_lower.include?('too large')
          suggestions += [
            "One of the files may be too large for comparison",
            "Check available memory and disk space"
          ]
        elsif reason_lower.include?('lock')
          suggestions += [
            "Files may be locked by another process",
            "Wait for other processes to complete and retry"
          ]
        end
      end

      suggestions += platform_specific_suggestions
      suggestions
    end
  end

  # Raised when remote access operations fail
  class RemoteAccessError < LeylineError
    attr_reader :url, :operation_type, :http_status

    def initialize(message, url: nil, operation_type: nil, http_status: nil, **options)
      @url = url
      @operation_type = operation_type
      @http_status = http_status

      super(message, category: :remote_access, context: { url: url, operation_type: operation_type, http_status: http_status }, **options)
    end

    def recovery_suggestions
      suggestions = []

      case @http_status
      when 401, 403
        suggestions += [
          "Check authentication credentials",
          "Verify you have access to the repository",
          "Update git credentials if using HTTPS"
        ]
      when 404
        suggestions += [
          "Verify the repository URL is correct",
          "Check if the repository exists and is accessible"
        ]
      when 408, 502, 503, 504
        suggestions += [
          "Network or server issue - retry in a few minutes",
          "Check your internet connection"
        ]
      when 429
        suggestions += [
          "Rate limited - wait before retrying",
          "Check if you're making too many requests"
        ]
      end

      suggestions += [
        "Check firewall and proxy settings",
        "Try using a different network connection"
      ]

      if @url
        suggestions << "Verify DNS resolution: nslookup #{extract_domain(@url)}"
      end

      suggestions.compact
    end

    private

    def extract_domain(url)
      return nil unless url
      URI.parse(url).host
    rescue URI::InvalidURIError
      nil
    end
  end

  # Base class for cache-related errors
  class CacheError < LeylineError
    def initialize(message, **options)
      super(message, category: :cache, **options)
    end

    def recovery_suggestions
      [
        "Clear the cache directory: rm -rf ~/.cache/leyline",
        "Run sync with --no-cache flag to bypass cache",
        "Check cache directory permissions and available disk space"
      ]
    end
  end

  # Raised when cache operations fail
  class CacheOperationError < CacheError
    attr_reader :cache_path, :operation_type, :disk_space_available

    def initialize(message, cache_path: nil, operation_type: nil, **options)
      @cache_path = cache_path
      @operation_type = operation_type
      @disk_space_available = check_disk_space(cache_path) if cache_path

      super(message, context: { cache_path: cache_path, operation_type: operation_type }, **options)
    end

    def recovery_suggestions
      suggestions = []

      case @operation_type
      when :write, :put
        suggestions += [
          "Check available disk space: #{@disk_space_available || 'unknown'}",
          "Clean up old cache files: leyline cache clean"
        ]

        if @cache_path
          suggestions << "Verify cache directory permissions: ls -la '#{File.dirname(@cache_path)}'"
        end
      when :read, :get
        suggestions += [
          "Cache may be corrupted - try clearing it: rm -rf ~/.cache/leyline",
          "Check file permissions on cache directory"
        ]
      when :delete
        suggestions += [
          "Check if files are locked by another process",
          "Verify you have write permissions to cache directory"
        ]
      end

      suggestions += [
        "Try running with a different cache directory: LEYLINE_CACHE_DIR=/tmp/leyline-cache",
        "Check for concurrent leyline processes using the same cache"
      ]

      suggestions + platform_specific_suggestions
    end

    private

    def check_disk_space(path)
      return nil unless path && File.exist?(File.dirname(path))

      # Simple disk space check - could be enhanced per platform
      stat = File.statvfs(File.dirname(path))
      available_mb = (stat.bavail * stat.frsize) / (1024 * 1024)
      "#{available_mb}MB available"
    rescue StandardError
      nil
    end
  end

  # Raised when filesystem operations fail
  class FileSystemError < LeylineError
    attr_reader :path, :reason

    def initialize(message, path: nil, reason: nil, **options)
      @path = path
      @reason = reason
      super(message, category: :filesystem, context: { path: path, reason: reason }, **options)
    end

    def recovery_suggestions
      suggestions = []

      case @reason
      when :permission_denied
        suggestions += [
          "Ensure you have appropriate access rights",
          "Try running with elevated privileges if necessary"
        ]
        suggestions << "Check file permissions: ls -la '#{@path}'" if @path
      when :read_only_filesystem
        suggestions += [
          "Filesystem is mounted read-only",
          "Remount filesystem with write permissions if possible"
        ]
        suggestions << "Check mount options: mount | grep '#{@path}'" if @path
      when :disk_full
        suggestions += [
          "Free up disk space",
          "Remove unnecessary files or move to another location"
        ]
        suggestions << "Check disk usage: df -h '#{@path}'" if @path
      end

      suggestions += platform_specific_suggestions
      suggestions.compact
    end
  end

  # Raised when git operations fail
  class GitError < LeylineError
    attr_reader :command, :exit_status, :stderr_output

    def initialize(message, command: nil, exit_status: nil, stderr_output: nil, **options)
      @command = command
      @exit_status = exit_status
      @stderr_output = stderr_output
      super(message, category: :git, context: { command: command, exit_status: exit_status }, **options)
    end

    def recovery_suggestions
      suggestions = []

      if @stderr_output
        case @stderr_output.downcase
        when /permission denied|access denied/
          suggestions += [
            "Check git repository permissions",
            "Verify SSH key or authentication credentials",
            "Ensure git user has appropriate access rights"
          ]
        when /not found|does not exist/
          suggestions += [
            "Verify the repository URL is correct",
            "Check if the repository exists and is accessible",
            "Ensure the branch or tag exists"
          ]
        when /network|connection/
          suggestions += [
            "Check internet connection",
            "Verify DNS resolution for git host",
            "Check firewall and proxy settings"
          ]
        end
      end

      suggestions += [
        "Verify git is installed and in PATH",
        "Check git configuration: git config --list",
        "Try running the git command manually for more details"
      ]

      suggestions
    end
  end

  # Raised when platform-specific operations fail
  class PlatformError < LeylineError
    attr_reader :platform_operation, :platform_type

    def initialize(message, platform_operation: nil, **options)
      @platform_operation = platform_operation
      @platform_type = platform

      super(message, category: :platform, context: { platform_operation: platform_operation, platform_type: @platform_type }, **options)
    end

    def recovery_suggestions
      suggestions = []

      case @platform_operation
      when :file_locking
        case platform
        when :windows
          suggestions += [
            "Close any programs that might be using the files",
            "Check Windows Resource Monitor for file handles",
            "Try restarting if files remain locked"
          ]
        when :macos, :linux
          suggestions += [
            "Check for processes using the files: lsof '#{@context[:file_path]}'",
            "Wait for other processes to complete",
            "Use 'fuser' to identify blocking processes"
          ]
        end
      when :permissions
        case platform
        when :windows
          suggestions += [
            "Run Command Prompt as Administrator",
            "Check file properties > Security tab for permissions",
            "Use 'icacls' command to modify permissions"
          ]
        when :macos
          suggestions += [
            "Use 'chmod' to fix permissions: chmod 644 filename",
            "Check System Preferences > Security & Privacy",
            "Use 'sudo' for administrative operations"
          ]
        when :linux
          suggestions += [
            "Check permissions: ls -la filename",
            "Use 'chmod' to fix permissions: chmod 644 filename",
            "Use 'sudo' for administrative operations"
          ]
        end
      end

      suggestions
    end
  end

  # Module for consistent error formatting across commands
  module ErrorHandler
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def handle_transparency_errors(&block)
        block.call
      rescue ConflictDetectedError => e
        display_conflict_error(e)
        exit 1
      rescue InvalidSyncStateError => e
        display_sync_state_error(e)
        exit 1
      rescue ComparisonFailedError => e
        display_comparison_error(e)
        exit 1
      rescue RemoteAccessError => e
        display_remote_access_error(e)
        exit 1
      rescue CacheOperationError => e
        display_cache_error(e)
        exit 1
      rescue PlatformError => e
        display_platform_error(e)
        exit 1
      rescue LeylineError => e
        display_generic_error(e)
        exit 1
      end

      private

      def display_conflict_error(error)
        warn "⚠️  Conflicts detected:"
        warn error.message
        warn "\n🔧 Resolution steps:"
        error.recovery_suggestions.each_with_index do |suggestion, i|
          warn "  #{i + 1}. #{suggestion}"
        end
      end

      def display_sync_state_error(error)
        warn "❌ Sync state error:"
        warn error.message
        warn "\n🔧 Recovery steps:"
        error.recovery_suggestions.each_with_index do |suggestion, i|
          warn "  #{i + 1}. #{suggestion}"
        end
      end

      def display_comparison_error(error)
        warn "❌ File comparison failed:"
        warn error.message
        warn "\n🔧 Possible solutions:"
        error.recovery_suggestions.each { |s| warn "  • #{s}" }
      end

      def display_remote_access_error(error)
        warn "🌐 Remote access failed:"
        warn error.message
        warn "\n🔧 Network troubleshooting:"
        error.recovery_suggestions.each { |s| warn "  • #{s}" }
      end

      def display_cache_error(error)
        warn "💾 Cache operation failed:"
        warn error.message
        warn "\n🔧 Cache recovery:"
        error.recovery_suggestions.each { |s| warn "  • #{s}" }
      end

      def display_platform_error(error)
        warn "🖥️  Platform-specific error:"
        warn error.message
        warn "\n🔧 Platform solutions:"
        error.recovery_suggestions.each { |s| warn "  • #{s}" }
      end

      def display_generic_error(error)
        warn "❌ Operation failed:"
        warn error.message
        if error.respond_to?(:recovery_suggestions) && error.recovery_suggestions.any?
          warn "\n🔧 Suggestions:"
          error.recovery_suggestions.each { |s| warn "  • #{s}" }
        end
      end
    end
  end

  # Configuration-related errors
  class ConfigurationError < LeylineError
    def initialize(message, **options)
      super(message, **options)
    end

    def recovery_suggestions
      [
        'Check configuration file syntax and permissions',
        'Verify environment variables are set correctly',
        'Use default configuration if custom config is problematic'
      ]
    end
  end
end
