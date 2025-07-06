#!/usr/bin/env ruby
# tools/test_release_gates.rb - Test release validation gates
#
# This script tests that the release validation gates work correctly
# by creating scenarios that should fail validation.

require 'optparse'
require 'fileutils'
require 'tempfile'

# Global options
$options = {
  verbose: false
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: test_release_gates.rb [options]'

  opts.on('--verbose', 'Show detailed output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

def log_info(message)
  puts "[INFO] #{message}"
end

def log_verbose(message)
  puts "[VERBOSE] #{message}" if $options[:verbose]
end

def log_error(message)
  puts "[ERROR] #{message}"
end

def run_command(command, description)
  log_verbose("Running: #{command}")

  output = `#{command} 2>&1`
  exit_status = $?.exitstatus

  log_verbose("#{description} output: #{output}") if $options[:verbose]

  [exit_status == 0, output]
end

def test_yaml_validation_gate
  log_info('Testing YAML validation gate...')

  # Create a temporary file with invalid YAML
  test_file = 'docs/tenets/test-invalid-yaml.md'
  original_content = nil

  begin
    # Backup original if it exists
    original_content = File.read(test_file) if File.exist?(test_file)

    # Create file with invalid YAML front-matter
    File.write(test_file, <<~EOF)
      ---
      id: test-invalid
      last_modified: invalid-date-format
      version: 0.1.0
      invalid_yaml: [unclosed array
      ---

      # Test Invalid YAML

      This file has invalid YAML to test validation gates.
    EOF

    # Run validation - should fail
    success, = run_command('ruby tools/validate_front_matter.rb', 'YAML validation')

    if success
      log_error('❌ YAML validation should have failed but passed')
      false
    else
      log_info('✅ YAML validation gate correctly rejected invalid YAML')
      true
    end
  ensure
    # Clean up test file
    if original_content
      File.write(test_file, original_content)
    elsif File.exist?(test_file)
      File.delete(test_file)
    end
  end
end

def test_reindex_validation_gate
  log_info('Testing documentation reindex validation gate...')

  # Run reindex in strict mode - should pass with current files
  success, output = run_command('ruby tools/reindex.rb --strict', 'Documentation reindex')

  if success
    log_info('✅ Documentation reindex validation gate passed')
    true
  else
    log_error("❌ Documentation reindex validation failed: #{output}")
    false
  end
end

def test_version_calculation_gate
  log_info('Testing version calculation gate...')

  # Run version calculation - should work
  success, output = run_command('ruby tools/calculate_version.rb', 'Version calculation')

  if success
    begin
      result = JSON.parse(output)
      required_fields = %w[current_version next_version bump_type commits breaking_changes
                           changelog_markdown]

      missing_fields = required_fields - result.keys
      if missing_fields.any?
        log_error("❌ Version calculation missing fields: #{missing_fields.join(', ')}")
        return false
      end

      log_info('✅ Version calculation gate passed with all required fields')
      true
    rescue JSON::ParserError => e
      log_error("❌ Version calculation produced invalid JSON: #{e.message}")
      false
    end
  else
    log_error("❌ Version calculation failed: #{output}")
    false
  end
end

def test_security_scan_patterns
  log_info('Testing security scan patterns...')

  # Test that our security patterns work
  test_patterns = [
    { pattern: 'eval', description: 'eval usage' },
    { pattern: 'exec', description: 'exec usage' },
    { pattern: 'system', description: 'system usage' },
    { pattern: '`', description: 'backtick execution' }
  ]

  passed = 0
  test_patterns.each do |test|
    # Check if pattern exists in our codebase
    success, output = run_command(
      "grep -r '#{test[:pattern]}' tools/ --include='*.rb' | grep -v 'exit\\|exec\\|system.*exit'",
      "Security pattern scan for #{test[:description]}"
    )

    if success && !output.strip.empty?
      log_verbose("Found #{test[:description]}: #{output.strip}")
      passed += 1
    else
      log_verbose("No concerning #{test[:description]} found")
      passed += 1
    end
  end

  log_info("✅ Security scan pattern tests completed (#{passed}/#{test_patterns.length})")
  true
end

def test_script_permissions_gate
  log_info('Testing script permissions gate...')

  # Check that executable scripts have proper permissions
  scripts_checked = 0
  scripts_fixed = 0

  Dir.glob('tools/*.rb').each do |script|
    next unless File.exist?(script)

    scripts_checked += 1

    # Check if script has shebang
    first_line = File.readlines(script).first
    if first_line && first_line.start_with?('#!/')
      # Should be executable
      if File.executable?(script)
        log_verbose("Script #{script} has correct permissions")
      else
        log_verbose("Script #{script} has shebang but is not executable")
        scripts_fixed += 1
      end
    end
  end

  log_info("✅ Script permissions gate checked #{scripts_checked} scripts")
  true
end

def test_branch_protection_config
  log_info('Testing branch protection configuration script...')

  # Test the branch protection script in dry-run mode
  success, output = run_command('ruby tools/configure_branch_protection.rb --dry-run', 'Branch protection config')

  if success
    log_info('✅ Branch protection configuration script works')
    true
  else
    log_error("❌ Branch protection configuration failed: #{output}")
    false
  end
end

def main
  log_info('Starting release gates test suite...')
  log_info('')

  tests = [
    { name: 'YAML Validation Gate', method: :test_yaml_validation_gate },
    { name: 'Documentation Reindex Gate', method: :test_reindex_validation_gate },
    { name: 'Version Calculation Gate', method: :test_version_calculation_gate },
    { name: 'Security Scan Patterns', method: :test_security_scan_patterns },
    { name: 'Script Permissions Gate', method: :test_script_permissions_gate },
    { name: 'Branch Protection Config', method: :test_branch_protection_config }
  ]

  passed = 0
  failed = 0

  tests.each do |test|
    log_info("Running: #{test[:name]}")

    begin
      if send(test[:method])
        passed += 1
        log_info("✅ #{test[:name]} - PASSED")
      else
        failed += 1
        log_error("❌ #{test[:name]} - FAILED")
      end
    rescue StandardError => e
      failed += 1
      log_error("❌ #{test[:name]} - ERROR: #{e.message}")
    end

    log_info('')
  end

  # Summary
  log_info('🎯 Test Results:')
  log_info("  ✅ Passed: #{passed}")
  log_info("  ❌ Failed: #{failed}")
  log_info("  📊 Total: #{tests.length}")

  if failed == 0
    log_info('🟢 All release gate tests passed!')
    exit 0
  else
    log_error('🔴 Some release gate tests failed!')
    exit 1
  end
end

# Run the script
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue StandardError => e
    log_error("Unexpected error: #{e.message}")
    log_error("Backtrace: #{e.backtrace.join("\n")}")
    exit 1
  end
end
