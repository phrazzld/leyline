#!/usr/bin/env ruby
# tools/security_utils.rb - Security utilities for Leyline tools
#
# This module provides centralized security functions for input validation,
# shell command safety, and output sanitization across all Leyline tools.
#
# Security Principles:
# - Validate all external inputs at entry points
# - Escape all shell commands and parameters
# - Sanitize all output strings
# - Fail secure - deny by default
# - Principle of least privilege

require 'shellwords'
require 'open3'

module SecurityUtils
  # Security error for validation failures
  class SecurityError < StandardError; end

  # Validate version string format (semantic versioning)
  def self.validate_version(version)
    return false if version.nil? || version.empty?

    # Reject control characters including newlines
    return false if version.match?(/[\x00-\x1F\x7F]/)

    # Allow only semantic version format: X.Y.Z with optional pre-release/build
    pattern = /^\d+\.\d+\.\d+(?:-[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*)?(?:\+[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*)?$/
    return false unless version.match?(pattern)

    # Reject consecutive dots in pre-release/build
    return false if version.include?('..')

    # Additional length check to prevent DoS
    return false if version.length > 100

    true
  end

  # Validate git reference (branch, tag, commit hash)
  def self.validate_git_ref(ref)
    return false if ref.nil? || ref.empty?

    # Reject control characters including newlines
    return false if ref.match?(/[\x00-\x1F\x7F]/)

    # Git refs can contain: letters, numbers, /, -, ., _
    # Cannot start with /, -, or contain consecutive dots or end with .lock
    pattern = %r{^[a-zA-Z0-9][a-zA-Z0-9/_\-.]*[a-zA-Z0-9]$}
    return false unless ref.match?(pattern)
    return false if ref.include?('..')
    return false if ref.end_with?('.lock')
    return false if ref.length > 250 # Git ref name limit

    true
  end

  # Validate file path to prevent directory traversal
  def self.validate_file_path(path)
    return false if path.nil? || path.empty?

    # Reject absolute paths starting with /
    return false if path.start_with?('/')

    # Reject paths with directory traversal attempts
    return false if path.include?('../') || path.include?('/..')
    return false if path == '..' || path.start_with?('../')

    # Reject Windows-style directory traversal
    return false if path.include?('..\\') || path.include?('\\..')

    # Reject control characters and dangerous shell metacharacters
    return false if path.match?(/[\x00-\x1F\x7F]/)
    return false if path.match?(/[;&|`$(){}\[\]<>*?~]/)

    # Reject URL encoded traversal attempts
    return false if path.include?('%2e') || path.include?('%2f') || path.include?('%5c')

    # Only allow safe characters: letters, numbers, -, _, ., /
    return false unless path.match?(%r{^[a-zA-Z0-9\-_./]+$})

    # Length check
    return false if path.length > 1000

    true
  end

  # Validate commit message for safe processing
  def self.validate_commit_message(message)
    return false if message.nil? || message.empty?

    # Reject null bytes and control characters except newlines/tabs
    return false if message.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/)

    # Length check to prevent DoS
    return false if message.length > 10_000

    true
  end

  # Sanitize string for safe output (remove/escape dangerous characters)
  def self.sanitize_output(str)
    return '' if str.nil?

    # Remove null bytes and control characters including newlines for safety
    # Convert newlines to spaces for single-line output safety
    str.gsub(/[\x00-\x1F\x7F]/, ' ')
       .gsub(/\s+/, ' ') # Collapse multiple spaces
       .strip
  end

  # Execute shell command safely with proper escaping
  def self.safe_system(*args)
    raise SecurityError, 'No command provided' if args.empty?

    # Use array form to prevent shell injection
    # Do not use string interpolation or shell metacharacters
    begin
      result = system(*args)
      { success: result, exit_code: $?.exitstatus }
    rescue StandardError => e
      raise SecurityError, "Command execution failed: #{e.message}"
    end
  end

  # Execute shell command and capture output safely
  def self.safe_capture(*args)
    raise SecurityError, 'No command provided' if args.empty?

    begin
      stdout, stderr, status = Open3.capture3(*args)
      {
        stdout: sanitize_output(stdout),
        stderr: sanitize_output(stderr),
        success: status.success?,
        exit_code: status.exitstatus
      }
    rescue StandardError => e
      raise SecurityError, "Command capture failed: #{e.message}"
    end
  end

  # Safe git command execution with validation
  def self.safe_git_command(command, *args)
    raise SecurityError, 'Invalid git command' unless command.is_a?(String)
    raise SecurityError, 'Git command too long' if command.length > 100

    # Validate that it's a legitimate git command
    allowed_commands = %w[
      status log show diff tag branch rev-parse describe
      config ls-files ls-tree cat-file rev-list commit-tree
      symbolic-ref name-rev for-each-ref
    ]

    base_command = command.split.first
    raise SecurityError, "Git command '#{base_command}' not allowed" unless allowed_commands.include?(base_command)

    # Validate all arguments
    args.each do |arg|
      next if arg.is_a?(String) && arg.match?(%r{^[a-zA-Z0-9\-_./=:@+\s]*$})

      raise SecurityError, "Invalid git command argument: #{arg}"
    end

    full_command = ['git', command] + args
    safe_capture(*full_command)
  end

  # Validate GitHub token format (basic validation)
  def self.validate_github_token(token)
    return false if token.nil? || token.empty?

    # GitHub tokens follow specific patterns
    # Classic: ghp_, fine-grained: github_pat_
    patterns = [
      /^ghp_[a-zA-Z0-9]{36}$/,           # Classic personal access token
      /^github_pat_[a-zA-Z0-9_]{82}$/,   # Fine-grained personal access token
      /^ghs_[a-zA-Z0-9]{36}$/,           # Server-to-server token
      /^gho_[a-zA-Z0-9]{36}$/,           # OAuth token
      /^ghu_[a-zA-Z0-9]{36}$/ # User-to-server token
    ]

    patterns.any? { |pattern| token.match?(pattern) }
  end

  # Rate limiting for API calls
  def self.rate_limit_check(key, max_calls: 60, window: 3600)
    @rate_limits ||= {}
    current_time = Time.now.to_i

    # Clean up old entries
    @rate_limits.delete_if { |_k, v| current_time - v[:start] > window }

    # Initialize or update counter
    @rate_limits[key] ||= { count: 0, start: current_time }
    @rate_limits[key][:count] += 1

    raise SecurityError, "Rate limit exceeded for #{key}" if @rate_limits[key][:count] > max_calls

    true
  end

  # Secure file operations
  def self.safe_file_read(path, max_size: 10_000_000) # 10MB limit
    raise SecurityError, 'Invalid file path' unless validate_file_path(path)
    raise SecurityError, 'File does not exist' unless File.exist?(path)

    size = File.size(path)
    raise SecurityError, "File too large: #{size} bytes" if size > max_size

    File.read(path)
  rescue Errno::EACCES
    raise SecurityError, "Access denied to file: #{path}"
  rescue StandardError => e
    raise SecurityError, "File read error: #{e.message}"
  end

  # Secure file write with atomic operation
  def self.safe_file_write(path, content, max_size: 10_000_000)
    raise SecurityError, 'Invalid file path' unless validate_file_path(path)
    raise SecurityError, 'Content too large' if content.length > max_size

    # Write to temporary file first, then move (atomic operation)
    temp_path = "#{path}.tmp.#{Process.pid}"

    begin
      File.write(temp_path, content)
      File.rename(temp_path, path)
    rescue StandardError => e
      File.delete(temp_path) if File.exist?(temp_path)
      raise SecurityError, "File write error: #{e.message}"
    end
  end

  # Log security events
  def self.log_security_event(event, details = {})
    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')
    sanitized_details = details.transform_values { |v| sanitize_output(v.to_s) }

    puts "[SECURITY] #{timestamp} - #{event}: #{sanitized_details}" if ENV['SECURITY_LOGGING']
  end
end
