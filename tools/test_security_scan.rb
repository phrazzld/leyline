#!/usr/bin/env ruby
# test_security_scan.rb - Tests for security scanner functionality
#
# This test suite validates that the security scanner correctly detects
# various types of security vulnerabilities in Ruby code.

require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'

class TestSecurityScan < Test::Unit::TestCase
  def setup
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('security_scan_test_')
    Dir.chdir(@test_dir)

    # Copy security scan script to test directory
    script_source = File.join(@original_dir, 'tools', 'security_scan.rb')
    utils_source = File.join(@original_dir, 'tools', 'security_utils.rb')

    FileUtils.mkdir_p('tools')
    FileUtils.cp(script_source, 'tools/security_scan.rb') if File.exist?(script_source)
    FileUtils.cp(utils_source, 'tools/security_utils.rb') if File.exist?(utils_source)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  def create_vulnerable_file(filename, content)
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, content)
  end

  def run_security_scan(options = '')
    `ruby tools/security_scan.rb --format json #{options} 2>/dev/null`
  end

  def test_detects_hardcoded_secrets
    vulnerable_code = <<~RUBY
      #!/usr/bin/env ruby

      # Hardcoded credentials - should be detected
      password = "super_secret_password"
      api_key = "sk-1234567890abcdef"
      github_token = "ghp_1234567890123456789012345678901234abcd"

      puts "Application starting..."
    RUBY

    create_vulnerable_file('tools/vulnerable_app.rb', vulnerable_code)

    result_json = run_security_scan
    result = JSON.parse(result_json)

    assert result['summary']['total_issues'] > 0, 'Should detect hardcoded secrets'

    # Check for specific secret types
    secret_issues = result['issues'].select { |i| i['type'] == 'secrets' }
    assert secret_issues.any? { |i| i['message'].include?('password') }, 'Should detect hardcoded password'
    assert secret_issues.any? { |i| i['message'].include?('API key') }, 'Should detect hardcoded API key'
    assert secret_issues.any? { |i| i['message'].include?('GitHub token') }, 'Should detect GitHub token'
  end

  def test_detects_shell_injection
    vulnerable_code = <<~RUBY
      #!/usr/bin/env ruby

      # Shell injection vulnerabilities
      def dangerous_git_command(branch)
        system("git checkout \#{branch}")
        output = `git log --oneline \#{branch}`
        result = Open3.capture2("git show \#{branch}")
      end

      def file_operation(filename)
        File.read("data/\#{filename}")
      end
    RUBY

    create_vulnerable_file('tools/vulnerable_commands.rb', vulnerable_code)

    result_json = run_security_scan
    result = JSON.parse(result_json)

    assert result['summary']['total_issues'] > 0, 'Should detect shell injection vulnerabilities'

    # Check for shell injection detection
    shell_issues = result['issues'].select { |i| i['type'] == 'shell_injection' }
    assert shell_issues.length >= 3, 'Should detect multiple shell injection vulnerabilities'

    assert shell_issues.any? { |i| i['message'].include?('system()') }, 'Should detect system() vulnerability'
    assert shell_issues.any? { |i| i['message'].include?('backtick') }, 'Should detect backtick vulnerability'
    assert shell_issues.any? { |i| i['message'].include?('Open3') }, 'Should detect Open3 vulnerability'
  end

  def test_detects_unsafe_yaml
    vulnerable_code = <<~RUBY
      #!/usr/bin/env ruby
      require 'yaml'

      # Unsafe YAML loading
      def load_config(file)
        YAML.load(File.read(file))
      end

      def load_settings
        YAML.load_file('settings.yml')
      end
    RUBY

    create_vulnerable_file('tools/vulnerable_yaml.rb', vulnerable_code)

    result_json = run_security_scan
    result = JSON.parse(result_json)

    assert result['summary']['total_issues'] > 0, 'Should detect unsafe YAML loading'

    yaml_issues = result['issues'].select { |i| i['type'] == 'unsafe_yaml' }
    assert yaml_issues.length >= 2, 'Should detect multiple YAML vulnerabilities'

    assert yaml_issues.any? { |i| i['message'].include?('YAML.load()') }, 'Should detect YAML.load vulnerability'
    assert yaml_issues.any? { |i|
      i['message'].include?('YAML.load_file()')
    }, 'Should detect YAML.load_file vulnerability'
  end

  def test_detects_path_traversal
    vulnerable_code = <<~RUBY
      #!/usr/bin/env ruby

      # Path traversal vulnerabilities
      def read_user_file(filename)
        File.read("../../../etc/\#{filename}")
      end

      def backup_file(name)
        File.write("backup/../\#{name}", "data")
      end

      # Directory traversal patterns
      config_path = "../../config/secrets.yml"
    RUBY

    create_vulnerable_file('tools/vulnerable_paths.rb', vulnerable_code)

    result_json = run_security_scan
    result = JSON.parse(result_json)

    assert result['summary']['total_issues'] > 0, 'Should detect path traversal vulnerabilities'

    path_issues = result['issues'].select { |i| i['type'] == 'path_traversal' }
    assert path_issues.length >= 1, 'Should detect path traversal patterns'
  end

  def test_clean_file_passes_scan
    clean_code = <<~RUBY
      #!/usr/bin/env ruby
      require_relative 'security_utils'

      # Secure implementation
      def safe_git_command(command)
        SecurityUtils.safe_git_command(command)
      end

      def safe_file_read(path)
        return nil unless SecurityUtils.validate_file_path(path)
        SecurityUtils.safe_file_read(path)
      end

      # Using environment variables for secrets
      token = ENV['GITHUB_TOKEN']
      api_key = ENV['API_KEY']

      puts "Secure application starting..."
    RUBY

    create_vulnerable_file('tools/secure_app.rb', clean_code)

    result_json = run_security_scan
    result = JSON.parse(result_json)

    # Clean file should have no critical or high issues
    critical_issues = result['issues'].select { |i| i['severity'] == 'critical' }
    result['issues'].select { |i| i['severity'] == 'high' }

    assert_equal 0, critical_issues.length, 'Clean code should have no critical issues'
    # NOTE: might have some medium/low issues due to defensive coding patterns
  end

  def test_json_output_format
    create_vulnerable_file('tools/test_file.rb', 'system("echo #{user_input}")')

    result_json = run_security_scan
    result = JSON.parse(result_json)

    # Validate JSON structure
    assert result.key?('summary'), 'Should have summary section'
    assert result.key?('issues'), 'Should have issues section'

    assert result['summary'].key?('files_scanned'), 'Should track files scanned'
    assert result['summary'].key?('total_issues'), 'Should track total issues'
    assert result['summary'].key?('critical_issues'), 'Should track critical issues'
    assert result['summary'].key?('high_issues'), 'Should track high issues'

    # Validate issue structure
    return unless result['issues'].any?

    issue = result['issues'].first
    assert issue.key?('severity'), 'Issue should have severity'
    assert issue.key?('type'), 'Issue should have type'
    assert issue.key?('message'), 'Issue should have message'
    assert issue.key?('file'), 'Issue should have file'
  end

  def test_severity_classification
    critical_code = 'password = "hardcoded_password"'
    high_code = 'system("git checkout #{branch}")'
    medium_code = 'puts exception.backtrace'

    create_vulnerable_file('tools/severity_test.rb', "#{critical_code}\n#{high_code}\n#{medium_code}")

    result_json = run_security_scan
    result = JSON.parse(result_json)

    # Should classify issues by severity
    severities = result['issues'].map { |i| i['severity'] }.uniq.sort
    assert severities.include?('high'), 'Should detect high severity issues'

    # Verify severity counts match
    summary = result['summary']
    total_counted = summary['critical_issues'] + summary['high_issues'] +
                    summary['medium_issues'] + summary['low_issues']
    assert_equal summary['total_issues'], total_counted, 'Severity counts should sum to total'
  end

  def test_scanner_handles_empty_directory
    # No Ruby files in tools directory
    result_json = run_security_scan

    # Should handle gracefully, not crash
    assert !result_json.empty?, 'Should produce output even with no files'

    result = JSON.parse(result_json)
    assert_equal 0, result['summary']['files_scanned'], 'Should report 0 files scanned'
    assert_equal 0, result['summary']['total_issues'], 'Should report 0 issues'
  end

  def test_scanner_ignores_test_files
    create_vulnerable_file('tools/test_something.rb', 'password = "secret"')
    create_vulnerable_file('tools/regular_file.rb', 'password = "secret"')

    result_json = run_security_scan
    result = JSON.parse(result_json)

    # Should only scan regular_file.rb, not test_something.rb
    scanned_files = result['issues'].map { |i| i['file'] }.uniq
    assert scanned_files.any? { |f| f.include?('regular_file.rb') }, 'Should scan regular files'
    assert scanned_files.none? { |f| f.include?('test_something.rb') }, 'Should ignore test files'
  end
end
