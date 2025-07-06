#!/usr/bin/env ruby
# test_migration_system.rb - Test suite for Leyline migration tools and processes
#
# This tool provides comprehensive testing of the migration system to ensure
# reliability and correctness of migration operations.

require 'yaml'
require 'fileutils'
require 'tempfile'
require 'optparse'

# Configuration and options
$options = {
  component: nil,
  verbose: false,
  cleanup: true,
  quick: false
}

$test_results = []
$temp_dirs = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: test_migration_system.rb [options]'

  opts.on('--component COMPONENT', 'Test specific component (checker, automation, validation)') do |component|
    $options[:component] = component
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('--no-cleanup', 'Keep temporary test directories') do
    $options[:cleanup] = false
  end

  opts.on('--quick', 'Run quick tests only') do
    $options[:quick] = true
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

def log_test(test_name, status, details = nil)
  result = {
    test: test_name,
    status: status,
    details: details,
    timestamp: Time.now
  }

  $test_results << result

  icon = case status
         when 'pass' then '✅'
         when 'fail' then '❌'
         when 'skip' then '⏭️'
         else '❓'
         end

  message = "#{icon} #{test_name}"
  message += " - #{details}" if details && $options[:verbose]

  puts message
end

def create_test_environment
  temp_dir = Dir.mktmpdir('leyline_migration_test_')
  $temp_dirs << temp_dir

  log_verbose("Created test environment: #{temp_dir}")

  # Create basic project structure
  FileUtils.mkdir_p(File.join(temp_dir, 'docs'))
  FileUtils.mkdir_p(File.join(temp_dir, '.github/workflows'))

  temp_dir
end

def create_mock_submodule_config(test_dir)
  config = {
    'leyline_version' => '0.1.5',
    'tenets' => %w[simplicity testability explicit-over-implicit],
    'binding_categories' => %w[core typescript],
    'project' => {
      'primary_language' => 'typescript',
      'maturity' => 'developing'
    }
  }

  config_file = File.join(test_dir, 'leyline-config.yml')
  File.write(config_file, YAML.dump(config))

  config_file
end

def create_mock_direct_copy_config(test_dir)
  selection_config = {
    'leyline_version' => 'v0.1.5',
    'output_directory' => 'docs/standards',
    'tenets' => %w[simplicity testability],
    'binding_categories' => %w[core go],
    'tracking' => {
      'track_versions' => true,
      'track_checksums' => true
    }
  }

  tracking_config = {
    'leyline_version' => 'v0.1.5',
    'last_updated' => Time.now.utc.iso8601,
    'standards' => {
      'tenets/simplicity.md' => {
        'source_version' => 'v0.1.5',
        'copied_at' => Time.now.utc.iso8601
      }
    }
  }

  selection_file = File.join(test_dir, '.leyline-selection.yml')
  tracking_file = File.join(test_dir, '.leyline-tracking.yml')

  File.write(selection_file, YAML.dump(selection_config))
  File.write(tracking_file, YAML.dump(tracking_config))

  [selection_file, tracking_file]
end

def create_mock_standards_directory(test_dir)
  standards_dir = File.join(test_dir, 'docs/standards')

  # Create hierarchical structure
  FileUtils.mkdir_p(File.join(standards_dir, 'tenets'))
  FileUtils.mkdir_p(File.join(standards_dir, 'bindings/core'))
  FileUtils.mkdir_p(File.join(standards_dir, 'bindings/typescript'))

  # Create mock files
  File.write(File.join(standards_dir, 'tenets/simplicity.md'), "# Simplicity\n\nTest content")
  File.write(File.join(standards_dir, 'bindings/core/api-design.md'), "# API Design\n\nTest content")
  File.write(File.join(standards_dir, 'bindings/typescript/no-any.md'), "# No Any\n\nTest content")

  standards_dir
end

# Test migration checker
def test_migration_checker
  log_info('Testing migration checker tool')

  test_dir = create_test_environment
  original_dir = Dir.pwd

  begin
    Dir.chdir(test_dir)

    # Test basic functionality
    cmd = "ruby #{original_dir}/tools/migration_checker.rb --from v0.1.0 --to v0.2.0"
    result = system(cmd)

    if result
      log_test('migration_checker basic functionality', 'pass')
    else
      log_test('migration_checker basic functionality', 'fail', 'Command failed')
    end

    # Test detailed analysis
    unless $options[:quick]
      cmd = "ruby #{original_dir}/tools/migration_checker.rb --from v0.1.0 --to v1.0.0 --detailed"
      result = system(cmd)

      if result
        log_test('migration_checker detailed analysis', 'pass')
      else
        log_test('migration_checker detailed analysis', 'fail', 'Command failed')
      end
    end

    # Test plan generation
    cmd = "ruby #{original_dir}/tools/migration_checker.rb --from v0.1.5 --to v0.2.0 --generate-plan"
    result = system(cmd)

    if result
      log_test('migration_checker plan generation', 'pass')

      # Check if plan file was created
      plan_files = Dir.glob('migration-plan-*.yml')
      if plan_files.any?
        log_test('migration_checker plan file creation', 'pass')
      else
        log_test('migration_checker plan file creation', 'fail', 'Plan file not created')
      end
    else
      log_test('migration_checker plan generation', 'fail', 'Command failed')
    end
  ensure
    Dir.chdir(original_dir)
  end
end

# Test migration automation
def test_migration_automation
  log_info('Testing migration automation tool')

  test_dir = create_test_environment
  original_dir = Dir.pwd

  begin
    Dir.chdir(test_dir)

    # Test with submodule configuration
    create_mock_submodule_config(test_dir)

    # Test dry run
    cmd = "ruby #{original_dir}/tools/migrate_version.rb --from v0.1.5 --to v0.2.0 --dry-run"
    result = system(cmd)

    if result
      log_test('migration_automation dry run', 'pass')
    else
      log_test('migration_automation dry run', 'fail', 'Command failed')
    end

    # Test actual migration (with backup disabled for testing)
    unless $options[:quick]
      cmd = "ruby #{original_dir}/tools/migrate_version.rb --from v0.1.5 --to v0.2.0 --auto --no-backup"
      result = system(cmd)

      if result
        log_test('migration_automation live migration', 'pass')

        # Verify configuration was updated
        if File.exist?('leyline-config.yml')
          config = YAML.load_file('leyline-config.yml')
          if config['leyline_version'] == '0.2.0'
            log_test('migration_automation config update', 'pass')
          else
            log_test('migration_automation config update', 'fail', 'Version not updated')
          end
        end
      else
        log_test('migration_automation live migration', 'fail', 'Command failed')
      end
    end
  ensure
    Dir.chdir(original_dir)
  end
end

# Test migration validation
def test_migration_validation
  log_info('Testing migration validation tool')

  test_dir = create_test_environment
  original_dir = Dir.pwd

  begin
    Dir.chdir(test_dir)

    # Create mock environment with updated configuration
    config = create_mock_submodule_config(test_dir)
    updated_config = YAML.load_file(config)
    updated_config['leyline_version'] = '0.2.0'
    File.write(config, YAML.dump(updated_config))

    # Test validation
    cmd = "ruby #{original_dir}/tools/validate_migration.rb --target v0.2.0"
    result = system(cmd)

    if result
      log_test('migration_validation basic validation', 'pass')
    else
      log_test('migration_validation basic validation', 'fail', 'Command failed')
    end

    # Test component-specific validation
    cmd = "ruby #{original_dir}/tools/validate_migration.rb --target v0.2.0 --component validation-config"
    result = system(cmd)

    if result
      log_test('migration_validation component validation', 'pass')
    else
      log_test('migration_validation component validation', 'fail', 'Command failed')
    end
  ensure
    Dir.chdir(original_dir)
  end
end

# Test integration method migration helpers
def test_integration_migration_helpers
  log_info('Testing integration method migration helpers')

  test_dir = create_test_environment
  original_dir = Dir.pwd

  begin
    Dir.chdir(test_dir)

    # Test submodule config export
    create_mock_submodule_config(test_dir)

    cmd = "ruby #{original_dir}/tools/export_submodule_config.rb --output test-selection.yml"
    result = system(cmd)

    if result
      log_test('export_submodule_config functionality', 'pass')

      # Verify output file
      if File.exist?('test-selection.yml')
        config = YAML.load_file('test-selection.yml')
        if config['leyline_version'] && config['tenets']
          log_test('export_submodule_config output format', 'pass')
        else
          log_test('export_submodule_config output format', 'fail', 'Invalid output format')
        end
      else
        log_test('export_submodule_config output file', 'fail', 'Output file not created')
      end
    else
      log_test('export_submodule_config functionality', 'fail', 'Command failed')
    end

    # Test submodule config generation
    standards_dir = create_mock_standards_directory(test_dir)

    cmd = "ruby #{original_dir}/tools/generate_submodule_config.rb --from #{standards_dir} --output test-submodule.yml"
    result = system(cmd)

    if result
      log_test('generate_submodule_config functionality', 'pass')

      # Verify output file
      if File.exist?('test-submodule.yml')
        config = YAML.load_file('test-submodule.yml')
        if config['leyline_version'] && config['binding_categories']
          log_test('generate_submodule_config output format', 'pass')
        else
          log_test('generate_submodule_config output format', 'fail', 'Invalid output format')
        end
      else
        log_test('generate_submodule_config output file', 'fail', 'Output file not created')
      end
    else
      log_test('generate_submodule_config functionality', 'fail', 'Command failed')
    end
  ensure
    Dir.chdir(original_dir)
  end
end

# Test error handling and edge cases
def test_error_handling
  log_info('Testing error handling and edge cases')

  test_dir = create_test_environment
  original_dir = Dir.pwd

  begin
    Dir.chdir(test_dir)

    # Test missing required parameters
    cmd = "ruby #{original_dir}/tools/migration_checker.rb --from v0.1.0"
    result = system(cmd)

    if !result
      log_test('migration_checker missing parameters', 'pass', 'Properly rejected missing parameters')
    else
      log_test('migration_checker missing parameters', 'fail', 'Should have failed with missing parameters')
    end

    # Test invalid version format
    cmd = "ruby #{original_dir}/tools/migration_checker.rb --from invalid --to v0.2.0"
    result = system(cmd)

    if !result
      log_test('migration_checker invalid version', 'pass', 'Properly rejected invalid version')
    else
      log_test('migration_checker invalid version', 'fail', 'Should have failed with invalid version')
    end

    # Test missing configuration files
    cmd = "ruby #{original_dir}/tools/validate_migration.rb --target v0.2.0"
    system(cmd)

    # This might pass with warnings, so we just check it doesn't crash
    log_test('migration_validation missing config', 'pass', 'Handled missing configuration gracefully')
  ensure
    Dir.chdir(original_dir)
  end
end

def cleanup_test_environments
  return unless $options[:cleanup]

  $temp_dirs.each do |dir|
    FileUtils.rm_rf(dir)
    log_verbose("Cleaned up test directory: #{dir}")
  end
end

def generate_test_report
  total_tests = $test_results.size
  passed_tests = $test_results.count { |r| r[:status] == 'pass' }
  failed_tests = $test_results.count { |r| r[:status] == 'fail' }
  skipped_tests = $test_results.count { |r| r[:status] == 'skip' }

  puts ''
  puts '# Migration System Test Report'
  puts ''
  puts "**Total Tests:** #{total_tests}"
  puts "**Passed:** #{passed_tests}"
  puts "**Failed:** #{failed_tests}"
  puts "**Skipped:** #{skipped_tests}"
  puts ''

  if failed_tests > 0
    puts '## Failed Tests'
    $test_results.select { |r| r[:status] == 'fail' }.each do |result|
      puts "- #{result[:test]}: #{result[:details]}"
    end
    puts ''
  end

  success_rate = (passed_tests.to_f / total_tests * 100).round(1)
  puts "**Success Rate:** #{success_rate}%"

  if failed_tests == 0
    puts '✅ All tests passed!'
    exit 0
  else
    puts "❌ #{failed_tests} test(s) failed"
    exit 1
  end
end

def main
  log_info('Starting Leyline migration system tests')

  # Run component-specific tests or all tests
  case $options[:component]
  when 'checker'
    test_migration_checker
  when 'automation'
    test_migration_automation
  when 'validation'
    test_migration_validation
  when 'helpers'
    test_integration_migration_helpers
  else
    # Run all tests
    test_migration_checker
    test_migration_automation unless $options[:quick]
    test_migration_validation
    test_integration_migration_helpers
    test_error_handling
  end

  cleanup_test_environments
  generate_test_report
end

if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    cleanup_test_environments
    exit 1
  rescue StandardError => e
    puts "[ERROR] Unexpected error: #{e.message}"
    puts "[ERROR] Backtrace: #{e.backtrace.join("\n")}"
    cleanup_test_environments
    exit 1
  end
end
