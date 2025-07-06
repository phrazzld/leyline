#!/usr/bin/env ruby
# Test for CRITICAL-002 - Invalid path crash fix

require 'tempfile'
require 'fileutils'

def test_invalid_path_exits_cleanly
  puts '🔧 Testing invalid path detection fix...'

  # Create a temporary file outside of tenets/bindings paths
  temp_file = Tempfile.new(['invalid_path_test', '.md'])

  begin
    # Write some content to the file
    temp_file.write(<<~CONTENT)
      ---
      id: test-invalid-path
      last_modified: '2025-06-11'
      ---

      # Test Invalid Path

      This file is in an invalid location.
    CONTENT
    temp_file.flush

    # Run validation script on the file
    output = `ruby tools/validate_front_matter.rb -f #{temp_file.path} 2>&1`
    exit_code = $?.exitstatus

    # Verify the fix works correctly
    if exit_code == 1
      puts '✅ PASS: Script exits with code 1 for invalid path'
    else
      puts "❌ FAIL: Expected exit code 1, got #{exit_code}"
      return false
    end

    if output.include?('Unable to determine file type from path')
      puts '✅ PASS: Proper error message displayed'
    else
      puts '❌ FAIL: Expected error message not found'
      puts "Output: #{output}"
      return false
    end

    if output.include?('Path must include /tenets/ or /bindings/')
      puts '✅ PASS: Helpful suggestion provided'
    else
      puts '❌ FAIL: Expected suggestion not found'
      return false
    end

    # Most importantly: no crash/exception
    if !output.include?('undefined method') && !output.include?('NoMethodError')
      puts '✅ PASS: No crash - nil dir_base issue fixed'
    else
      puts '❌ FAIL: Script still crashes with nil dir_base'
      puts "Output: #{output}"
      return false
    end

    puts '🎉 Invalid path detection fix working correctly!'
    true
  ensure
    temp_file.close
    temp_file.unlink
  end
end

def test_valid_paths_still_work
  puts "\n🔍 Testing valid paths still work after fix..."

  # Test valid tenet file
  `ruby tools/validate_front_matter.rb -f spec/fixtures/tenets/valid-tenet.md 2>&1`
  tenet_exit = $?.exitstatus

  if tenet_exit == 0
    puts '✅ PASS: Valid tenet file still works'
  else
    puts "❌ FAIL: Valid tenet file broken, exit code: #{tenet_exit}"
    return false
  end

  # Test valid binding file
  `ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/valid-binding.md 2>&1`
  binding_exit = $?.exitstatus

  if binding_exit == 0
    puts '✅ PASS: Valid binding file still works'
  else
    puts "❌ FAIL: Valid binding file broken, exit code: #{binding_exit}"
    return false
  end

  puts '🎉 Valid file validation still working correctly!'
  true
end

# Run the tests
puts "Testing CRITICAL-002 fix: Script crash on invalid path detection\n"

if test_invalid_path_exits_cleanly && test_valid_paths_still_work
  puts "\n✅ ALL TESTS PASSED - CRITICAL-002 fix verified!"
  exit 0
else
  puts "\n❌ TESTS FAILED - CRITICAL-002 fix may have issues"
  exit 1
end
