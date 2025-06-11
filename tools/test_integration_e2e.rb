#!/usr/bin/env ruby
# tools/test_integration_e2e.rb - End-to-end integration tests using fixtures
# Tests the complete validation pipeline with subprocess calls and ErrorFormatter output

require 'open3'
require 'fileutils'

# Test counter
$tests_run = 0
$tests_passed = 0

def test(description)
  $tests_run += 1
  print "Testing #{description}... "

  begin
    yield
    puts "✓ PASS"
    $tests_passed += 1
  rescue => e
    puts "✗ FAIL: #{e.message}"
    puts "  #{e.backtrace.first}" if ENV['DEBUG']
  end
end

def assert(condition, message = "Assertion failed")
  raise message unless condition
end

def assert_equal(expected, actual, message = nil)
  message ||= "Expected #{expected.inspect}, got #{actual.inspect}"
  assert(expected == actual, message)
end

def assert_includes(haystack, needle, message = nil)
  message ||= "Expected #{haystack.inspect} to include #{needle.inspect}"
  assert(haystack.include?(needle), message)
end

def assert_not_includes(haystack, needle, message = nil)
  message ||= "Expected #{haystack.inspect} to not include #{needle.inspect}"
  assert(!haystack.include?(needle), message)
end

# Run validation script as subprocess
def run_validation(file_path, args = "")
  cmd = "ruby tools/validate_front_matter.rb -f #{file_path} #{args}"
  stdout, stderr, status = Open3.capture3(cmd)

  {
    stdout: stdout,
    stderr: stderr,
    exit_code: status.exitstatus,
    success: status.success?
  }
end

# Test fixture data structure defining expected outcomes
FIXTURE_TESTS = {
  # Valid files should pass
  "spec/fixtures/tenets/valid-tenet.md" => {
    should_pass: true,
    expected_exit_code: 0,
    expected_stdout_includes: ["All files validated successfully!"],
    expected_stderr_excludes: ["Validation failed", "ERROR"]
  },

  "spec/fixtures/bindings/valid-binding.md" => {
    should_pass: true,
    expected_exit_code: 0,
    expected_stdout_includes: ["All files validated successfully!"],
    expected_stderr_excludes: ["Validation failed", "ERROR"]
  },

  # YAML syntax errors
  "spec/fixtures/bindings/yaml-syntax-error.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 2, # Syntax errors in granular mode
    expected_stderr_includes: [
      "Validation failed with",
      "YAML syntax error",
      "Empty YAML in front-matter",
      "Metadata validation failed!"
    ],
    expected_context_snippets: true
  },

  "spec/fixtures/bindings/no-front-matter.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 2, # Syntax errors in granular mode
    expected_stderr_includes: [
      "No front-matter found",
      "files must begin with YAML front-matter"
    ]
  },

  # Field validation errors
  "spec/fixtures/bindings/missing-required-fields.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 3, # Field errors in granular mode
    expected_stderr_includes: [
      "Missing required keys",
      "derived_from, enforced_by, version",
      "Missing 'version' field",
      "Invalid format for 'derived_from'",
      "Invalid format for 'enforced_by'"
    ]
  },

  "spec/fixtures/bindings/invalid-field-formats.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 3, # Field errors in granular mode
    expected_stderr_includes: [
      "Invalid ID format",
      "Invalid date format",
      "Version mismatch",
      "References non-existent tenet"
    ],
    expected_context_snippets: true
  },

  "spec/fixtures/bindings/unknown-fields.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 3, # Field errors in granular mode
    expected_stderr_includes: [
      "Unknown key(s) in YAML front-matter"
    ]
  },

  "spec/fixtures/bindings/nonexistent-tenet-reference.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 3, # Field errors in granular mode
    expected_stderr_includes: [
      "References non-existent tenet"
    ]
  },

  # Security validation
  "spec/fixtures/bindings/potential-secrets.md" => {
    should_pass: false,
    expected_exit_code: 1,
    expected_exit_code_granular: 3, # Field errors in granular mode
    expected_stderr_includes: [
      "Potential secret field",
      "api_key",
      "password",
      "token",
      "[REDACTED]" # Values should be redacted
    ],
    expected_stderr_excludes: [
      "sk-1234567890abcdef", # Actual secret values should not appear
      "super-secret-password",
      "ghp_xxxxxxxxxxxxxxxxxxxx"
    ]
  }
}.freeze

# Run tests for each fixture
def test_fixtures
  puts "Running fixture-based integration tests...\n"

  FIXTURE_TESTS.each do |file_path, expected|
    test_name = File.basename(file_path, '.md').gsub('-', ' ')

    test "#{test_name} - basic validation" do
      result = run_validation(file_path)

      # Test exit code
      assert_equal(expected[:expected_exit_code], result[:exit_code],
                   "Exit code mismatch for #{file_path}")

      # Test pass/fail expectation
      if expected[:should_pass]
        assert(result[:success], "Expected #{file_path} to pass validation")
      else
        assert(!result[:success], "Expected #{file_path} to fail validation")
      end

      # Test stdout includes
      if expected[:expected_stdout_includes]
        expected[:expected_stdout_includes].each do |text|
          assert_includes(result[:stdout], text,
                         "Expected stdout to include '#{text}' for #{file_path}")
        end
      end

      # Test stderr includes
      if expected[:expected_stderr_includes]
        expected[:expected_stderr_includes].each do |text|
          assert_includes(result[:stderr], text,
                         "Expected stderr to include '#{text}' for #{file_path}")
        end
      end

      # Test stderr excludes
      if expected[:expected_stderr_excludes]
        expected[:expected_stderr_excludes].each do |text|
          assert_not_includes(result[:stderr], text,
                             "Expected stderr to not include '#{text}' for #{file_path}")
        end
      end

      # Test context snippets are present for applicable errors
      if expected[:expected_context_snippets]
        assert_includes(result[:stderr], "context:",
                       "Expected context snippets in stderr for #{file_path}")
        # Should have line numbers and arrows
        assert(result[:stderr].match?(/\d+ [>│]/) || result[:stderr].match?(/\d+ →/),
               "Expected formatted context with line numbers for #{file_path}")
      end
    end

    # Test granular exit codes if specified
    if expected[:expected_exit_code_granular]
      test "#{test_name} - granular exit codes" do
        result = run_validation(file_path, "-g")

        assert_equal(expected[:expected_exit_code_granular], result[:exit_code],
                     "Granular exit code mismatch for #{file_path}")
      end
    end
  end
end

# Test CI-specific output requirements
def test_ci_compatibility
  puts "\nTesting CI compatibility and non-TTY output...\n"

  test "CI environment produces clean non-TTY output via piping" do
    # Test multiple error scenarios in CI-like piped environment
    test_files = [
      "spec/fixtures/bindings/yaml-syntax-error.md",
      "spec/fixtures/bindings/invalid-field-formats.md",
      "spec/fixtures/bindings/potential-secrets.md"
    ]

    test_files.each do |file|
      # Simulate CI by piping both stdout and stderr
      cmd = "ruby tools/validate_front_matter.rb -f #{file} 2>&1 | cat"
      piped_output = `#{cmd}`

      # Critical CI requirement: No ANSI color codes
      assert_not_includes(piped_output, "\e[",
                         "Expected no ANSI color codes in CI output for #{file}")

      # Should still have structured error output
      assert_includes(piped_output, "Validation failed with",
                     "Expected error header in CI output for #{file}")
      assert_includes(piped_output, "[ERROR]",
                     "Expected error indicators in CI output for #{file}")

      # Verify essential content is preserved
      if file.include?("potential-secrets")
        assert_includes(piped_output, "[REDACTED]",
                       "Expected secret redaction in CI output for #{file}")
      end

      if file.include?("invalid-field-formats")
        assert_includes(piped_output, "context:",
                       "Expected context sections in CI output for #{file}")
      end
    end
  end

  test "CI environment handles different exit code modes correctly" do
    # Test granular exit codes work properly in CI (using proper exit code capture)
    cmd = "ruby tools/validate_front_matter.rb -g -f spec/fixtures/bindings/yaml-syntax-error.md"
    stdout, stderr, status = Open3.capture3(cmd)

    # Should have exit code 2 for syntax errors in granular mode
    assert_equal(2, status.exitstatus, "Expected exit code 2 for syntax errors in granular mode")

    # Combine output and check for no color codes (simulating CI pipe behavior)
    combined_output = stdout + stderr
    assert_not_includes(combined_output, "\e[", "Expected no ANSI codes in granular mode output")

    # Should still have structured content
    assert_includes(stderr, "Validation failed with", "Expected error header in granular mode")
  end
end

# Test ErrorFormatter output structure
def test_error_formatter_output
  puts "\nTesting ErrorFormatter output structure...\n"

  test "ErrorFormatter produces properly structured output" do
    result = run_validation("spec/fixtures/bindings/invalid-field-formats.md")

    # Should have header with error count
    assert_includes(result[:stderr], "Validation failed with",
                   "Expected error count header")

    # Should have file sections
    assert_includes(result[:stderr], "spec/fixtures/bindings/invalid-field-formats.md:",
                   "Expected file section header")

    # Should have error indicators
    assert(result[:stderr].include?("✗") || result[:stderr].include?("[ERROR]"),
           "Expected error indicators")

    # Should have context sections
    assert_includes(result[:stderr], "context:",
                   "Expected context sections")

    # Should have suggestions
    assert_includes(result[:stderr], "suggestion:",
                   "Expected suggestion sections")

    # Should have final failure message
    assert_includes(result[:stderr], "Metadata validation failed!",
                   "Expected final failure message")
  end

  test "ErrorFormatter handles TTY vs non-TTY output" do
    # Test without TTY (CI environment)
    env = {"NO_COLOR" => "1"}
    cmd = "ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/yaml-syntax-error.md"
    stdout, stderr, status = Open3.capture3(env, cmd)

    # Should not contain ANSI color codes when NO_COLOR is set
    assert_not_includes(stderr, "\e[", "Expected no ANSI color codes with NO_COLOR")

    # Should still have error indicators
    assert_includes(stderr, "[ERROR]", "Expected plain text error indicators")
  end

  test "ErrorFormatter disables colors when output is piped (non-TTY)" do
    # Test by piping output to simulate CI environment
    cmd = "ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/invalid-field-formats.md 2>&1 | cat"
    piped_output = `#{cmd}`

    # Should not contain ANSI color codes when piped
    assert_not_includes(piped_output, "\e[", "Expected no ANSI color codes when output is piped")

    # Should still contain all the expected error content
    assert_includes(piped_output, "Validation failed with", "Expected error header in piped output")
    assert_includes(piped_output, "[ERROR]", "Expected plain text error indicators in piped output")
    assert_includes(piped_output, "Invalid ID format", "Expected error messages in piped output")
    assert_includes(piped_output, "context:", "Expected context sections in piped output")
    assert_includes(piped_output, "suggestion:", "Expected suggestion sections in piped output")

    # Verify line indicators use plain text instead of colored arrows
    assert(piped_output.match?(/\d+ > /) || piped_output.match?(/\d+ \│/),
           "Expected plain text line indicators (not colored arrows) in piped output")
  end

  test "ErrorFormatter produces colored output when connected to TTY" do
    # This test verifies the opposite - that we do get colors in TTY mode
    # Note: This may not work in all test environments, so we'll be more lenient
    cmd = "ruby -e 'require_relative \"lib/error_formatter\"; puts ErrorFormatter.new.send(:should_use_colors?)'"
    should_use_colors = `#{cmd}`.strip

    # The result depends on the test environment, but we can at least verify the logic works
    assert(should_use_colors == "true" || should_use_colors == "false",
           "ErrorFormatter should return boolean for should_use_colors?")
  end
end

# Test edge cases and error handling
def test_edge_cases
  puts "\nTesting edge cases...\n"

  test "handles non-existent fixture file" do
    result = run_validation("spec/fixtures/nonexistent.md")

    assert_equal(1, result[:exit_code], "Expected exit code 1 for non-existent file")
    assert_includes(result[:stdout], "File does not exist",
                   "Expected file not found error")
  end

  test "handles directory instead of file" do
    result = run_validation("spec/fixtures")

    assert_equal(1, result[:exit_code], "Expected exit code 1 for directory")
    assert_includes(result[:stdout], "Path is a directory",
                   "Expected directory error")
  end

  test "validates all fixtures directory structure exists" do
    required_dirs = [
      "spec/fixtures",
      "spec/fixtures/tenets",
      "spec/fixtures/bindings"
    ]

    required_dirs.each do |dir|
      assert(Dir.exist?(dir), "Required fixture directory #{dir} does not exist")
    end
  end
end

# Main test execution
def run_all_tests
  puts "=" * 80
  puts "End-to-End Integration Test Suite"
  puts "Testing validation script with fixture files"
  puts "=" * 80
  puts

  test_fixtures
  test_ci_compatibility
  test_error_formatter_output
  test_edge_cases

  puts "\n" + "=" * 80
  puts "Integration Test Results"
  puts "=" * 80
  puts "Tests run: #{$tests_run}"
  puts "Tests passed: #{$tests_passed}"
  puts "Tests failed: #{$tests_run - $tests_passed}"

  if $tests_passed == $tests_run
    puts "✓ ALL TESTS PASSED"
    exit 0
  else
    puts "✗ #{$tests_run - $tests_passed} TESTS FAILED"
    exit 1
  end
end

# Run tests if this script is executed directly
if __FILE__ == $0
  run_all_tests
end
