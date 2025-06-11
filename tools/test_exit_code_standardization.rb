#!/usr/bin/env ruby
# Test for CRITICAL-003 - Exit code standardization

require 'tempfile'
require 'fileutils'
require 'open3'

def test_exit_code_consistency
  puts "🔧 Testing exit code standardization..."

  # Test 1: Valid file should return exit code 0
  puts "\n1. Testing valid file exit code..."
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f spec/fixtures/tenets/valid-tenet.md")
  exit_code = status.exitstatus

  if exit_code == 0
    puts "✅ PASS: Valid file returns exit code 0"
  else
    puts "❌ FAIL: Valid file returned exit code #{exit_code}, expected 0"
    return false
  end

  # Test 2: YAML syntax error should return exit code 1
  puts "\n2. Testing YAML syntax error exit code..."
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/yaml-syntax-error.md")
  exit_code = status.exitstatus

  if exit_code == 1
    puts "✅ PASS: YAML syntax error returns exit code 1"
  else
    puts "❌ FAIL: YAML syntax error returned exit code #{exit_code}, expected 1"
    return false
  end

  # Test 3: Field validation error should return exit code 1
  puts "\n3. Testing field validation error exit code..."
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/invalid-field-formats.md")
  exit_code = status.exitstatus

  if exit_code == 1
    puts "✅ PASS: Field validation error returns exit code 1"
  else
    puts "❌ FAIL: Field validation error returned exit code #{exit_code}, expected 1"
    return false
  end

  # Test 4: Missing fields should return exit code 1
  puts "\n4. Testing missing fields error exit code..."
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/missing-required-fields.md")
  exit_code = status.exitstatus

  if exit_code == 1
    puts "✅ PASS: Missing fields error returns exit code 1"
  else
    puts "❌ FAIL: Missing fields error returned exit code #{exit_code}, expected 1"
    return false
  end

  # Test 5: Invalid path should return exit code 1
  puts "\n5. Testing invalid path error exit code..."
  temp_file = Tempfile.new(['invalid_path', '.md'])
  begin
    temp_file.write("---\nid: test\n---\n# Test")
    temp_file.flush

    stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f #{temp_file.path}")
    exit_code = status.exitstatus

    if exit_code == 1
      puts "✅ PASS: Invalid path error returns exit code 1"
    else
      puts "❌ FAIL: Invalid path error returned exit code #{exit_code}, expected 1"
      return false
    end
  ensure
    temp_file.close
    temp_file.unlink
  end

  puts "\n🎉 All exit code standardization tests passed!"
  return true
end

def test_no_granular_exit_codes
  puts "\n🔍 Testing granular exit codes are removed..."

  # Test that -g flag is no longer accepted
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -g 2>&1")
  exit_code = status.exitstatus

  # Should fail because -g is not a valid option anymore
  if stderr.include?("invalid option") || stderr.include?("unrecognized option") || exit_code != 0
    puts "✅ PASS: Granular exit codes option (-g) has been removed"
  else
    puts "❌ FAIL: Granular exit codes option (-g) is still available"
    return false
  end

  # Test help output doesn't mention granular codes
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -h")
  help_output = stdout + stderr

  if !help_output.include?("granular") && !help_output.include?("exit code 2") && !help_output.include?("exit code 3")
    puts "✅ PASS: Help output no longer mentions granular exit codes"
  else
    puts "❌ FAIL: Help output still mentions granular exit codes"
    puts "Help output: #{help_output}"
    return false
  end

  puts "🎉 Granular exit codes successfully removed!"
  return true
end

def test_ci_compatibility
  puts "\n🌐 Testing CI compatibility..."

  # Test that piped output has consistent exit codes
  cmd = "ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/yaml-syntax-error.md 2>&1 | cat"
  piped_output = `#{cmd}`
  piped_exit = $?.exitstatus

  # Note: In a pipe, we get the exit code of the last command (cat), but the output should still be correct
  if piped_output.include?("Validation failed")
    puts "✅ PASS: Piped output contains expected error content"
  else
    puts "❌ FAIL: Piped output missing expected error content"
    return false
  end

  # Test direct execution for exit code
  stdout, stderr, status = Open3.capture3("ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/yaml-syntax-error.md")
  if status.exitstatus == 1
    puts "✅ PASS: Direct execution returns consistent exit code 1"
  else
    puts "❌ FAIL: Direct execution returned exit code #{status.exitstatus}, expected 1"
    return false
  end

  puts "🎉 CI compatibility verified!"
  return true
end

# Run all tests
puts "Testing CRITICAL-003: Exit code standardization\n"

if test_exit_code_consistency && test_no_granular_exit_codes && test_ci_compatibility
  puts "\n✅ ALL TESTS PASSED - Exit code standardization complete!"
  puts "\nExit Code Strategy:"
  puts "  0 = All files validated successfully"
  puts "  1 = Any validation errors found"
  puts "\nGranular exit codes (2, 3) have been removed for CI/CD compatibility."
  exit 0
else
  puts "\n❌ TESTS FAILED - Exit code standardization issues detected"
  exit 1
end
