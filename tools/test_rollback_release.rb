#!/usr/bin/env ruby
# test_rollback_release.rb - Test the rollback_release.rb functionality
#
# This script tests the rollback functionality in a safe environment
# without actually affecting releases.

require 'fileutils'
require 'tmpdir'
require 'yaml'

$test_results = []
$test_dir = nil

def log_test(test_name, status, details = nil)
  result = {
    test: test_name,
    status: status,
    details: details
  }

  $test_results << result

  icon = case status
         when 'pass' then '✅'
         when 'fail' then '❌'
         when 'skip' then '⏭️'
         end

  message = "#{icon} #{test_name}"
  message += " - #{details}" if details

  puts message
end

def setup_test_environment
  $test_dir = Dir.mktmpdir('rollback_test_')
  Dir.chdir($test_dir)

  # Initialize git repo
  system('git init -q')
  system('git config user.email "test@example.com"')
  system('git config user.name "Test User"')

  # Create initial files
  File.write('VERSION', '0.1.0')
  File.write('CHANGELOG.md', <<~CHANGELOG)
    # Changelog

    ## [0.1.0] - 2024-01-01
    - Initial release
  CHANGELOG

  # Initial commit
  system('git add .')
  system('git commit -m "Initial commit" -q')
  system('git tag v0.1.0')

  # Simulate a release
  File.write('VERSION', '0.2.0')
  File.write('CHANGELOG.md', <<~CHANGELOG)
    # Changelog

    ## [0.2.0] - 2024-01-02
    - Added new feature
    - Fixed bug

    ## [0.1.0] - 2024-01-01
    - Initial release
  CHANGELOG

  system('git add .')
  system('git commit -m "chore: release 0.2.0" -q')
  system('git tag v0.2.0')

  log_test('Test environment setup', 'pass', $test_dir)
end

def test_dry_run
  puts "\n📋 Testing dry run mode..."

  original_version = File.read('VERSION').strip
  original_changelog = File.read('CHANGELOG.md')

  # Run rollback in dry run mode
  cmd = "ruby #{File.join(File.dirname(__dir__), 'tools',
                          'rollback_release.rb')} --version v0.2.0 --dry-run --repo test/repo"
  output = `#{cmd} 2>&1`
  $?.success?

  if output.include?('DRY RUN SUMMARY - No changes were made')
    log_test('Dry run execution', 'pass')
  else
    log_test('Dry run execution', 'fail', 'Command failed or no summary')
  end

  # Verify no changes were made
  if File.read('VERSION').strip == original_version
    log_test('Dry run - VERSION unchanged', 'pass')
  else
    log_test('Dry run - VERSION unchanged', 'fail', 'VERSION was modified')
  end

  if File.read('CHANGELOG.md') == original_changelog
    log_test('Dry run - CHANGELOG unchanged', 'pass')
  else
    log_test('Dry run - CHANGELOG unchanged', 'fail', 'CHANGELOG was modified')
  end

  # Check tag still exists
  if system('git rev-parse v0.2.0 >/dev/null 2>&1')
    log_test('Dry run - Tag preserved', 'pass')
  else
    log_test('Dry run - Tag preserved', 'fail', 'Tag was deleted')
  end
end

def test_version_revert
  puts "\n📋 Testing VERSION file revert..."

  # Run rollback
  cmd = "ruby #{File.join(File.dirname(__dir__), 'tools',
                          'rollback_release.rb')} --version v0.2.0 --no-issue --repo test/repo"
  output = `#{cmd} 2>&1`
  success = $?.success?

  if success
    log_test('Rollback execution', 'pass')
  else
    log_test('Rollback execution', 'fail', 'Command failed')
    puts output
    return
  end

  # Check VERSION was reverted
  current_version = File.read('VERSION').strip
  if current_version == '0.1.0'
    log_test('VERSION revert', 'pass', 'Reverted to 0.1.0')
  else
    log_test('VERSION revert', 'fail', "VERSION is #{current_version}, expected 0.1.0")
  end
end

def test_changelog_revert
  puts "\n📋 Testing CHANGELOG revert..."

  changelog_content = File.read('CHANGELOG.md')

  # Check that v0.2.0 section was removed
  if !changelog_content.include?('## [0.2.0]')
    log_test('CHANGELOG revert', 'pass', 'v0.2.0 section removed')
  else
    log_test('CHANGELOG revert', 'fail', 'v0.2.0 section still present')
  end

  # Check that v0.1.0 section is still there
  if changelog_content.include?('## [0.1.0]')
    log_test('CHANGELOG preservation', 'pass', 'v0.1.0 section preserved')
  else
    log_test('CHANGELOG preservation', 'fail', 'v0.1.0 section missing')
  end
end

def test_tag_deletion
  puts "\n📋 Testing tag deletion..."

  # Check that v0.2.0 tag was deleted
  if !system('git rev-parse v0.2.0 >/dev/null 2>&1')
    log_test('Tag deletion', 'pass', 'v0.2.0 tag deleted')
  else
    log_test('Tag deletion', 'fail', 'v0.2.0 tag still exists')
  end

  # Check that v0.1.0 tag still exists
  if system('git rev-parse v0.1.0 >/dev/null 2>&1')
    log_test('Tag preservation', 'pass', 'v0.1.0 tag preserved')
  else
    log_test('Tag preservation', 'fail', 'v0.1.0 tag missing')
  end
end

def test_invalid_version
  puts "\n📋 Testing invalid version handling..."

  # Test with invalid version format
  cmd = "ruby #{File.join(File.dirname(__dir__), 'tools',
                          'rollback_release.rb')} --version invalid-version --repo test/repo"
  output = `#{cmd} 2>&1`
  success = $?.success?

  if !success && output.include?('Invalid version format')
    log_test('Invalid version rejection', 'pass')
  else
    log_test('Invalid version rejection', 'fail', 'Should reject invalid version')
  end

  # Test with non-existent version
  cmd = "ruby #{File.join(File.dirname(__dir__), 'tools', 'rollback_release.rb')} --version v9.9.9 --repo test/repo"
  output = `#{cmd} 2>&1`

  if output.include?('Could not determine previous version')
    log_test('Non-existent version handling', 'pass')
  else
    log_test('Non-existent version handling', 'fail', 'Should warn about missing version')
  end
end

def cleanup_test_environment
  Dir.chdir(File.expand_path('../..', __dir__))
  FileUtils.rm_rf($test_dir) if $test_dir && Dir.exist?($test_dir)
end

def generate_report
  puts "\n" + '=' * 60
  puts '# Rollback Release Test Report'

  total = $test_results.size
  passed = $test_results.count { |r| r[:status] == 'pass' }
  failed = $test_results.count { |r| r[:status] == 'fail' }
  skipped = $test_results.count { |r| r[:status] == 'skip' }

  puts "\nTotal: #{total} | Passed: #{passed} | Failed: #{failed} | Skipped: #{skipped}"

  if failed > 0
    puts "\nFailed tests:"
    $test_results.select { |r| r[:status] == 'fail' }.each do |result|
      puts "  - #{result[:test]}: #{result[:details]}"
    end
  end

  success_rate = (passed.to_f / total * 100).round(1)
  puts "\nSuccess rate: #{success_rate}%"

  if failed == 0
    puts "\n✅ All tests passed!"
    exit 0
  else
    puts "\n❌ #{failed} test(s) failed"
    exit 1
  end
end

# Main test execution
begin
  puts "🧪 Testing rollback_release.rb functionality\n"

  setup_test_environment
  test_dry_run
  test_version_revert
  test_changelog_revert
  test_tag_deletion
  test_invalid_version

  generate_report
rescue StandardError => e
  puts "\n❌ Test error: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
ensure
  cleanup_test_environment
end
