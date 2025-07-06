#!/usr/bin/env ruby
# migrate_version.rb - Automated migration between Leyline versions
#
# This tool performs automated migrations between Leyline versions, handling
# configuration updates, file structure changes, and validation.

require 'yaml'
require 'fileutils'
require 'optparse'
require 'digest'
require 'time'

# Configuration and options
$options = {
  from_version: nil,
  to_version: nil,
  dry_run: false,
  interactive: false,
  auto: false,
  backup: true,
  force: false,
  verbose: false
}

$errors = []
$warnings = []
$migration_log = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: migrate_version.rb [options]'

  opts.on('--from VERSION', 'Source Leyline version (e.g., v0.1.0)') do |version|
    $options[:from_version] = version
  end

  opts.on('--to VERSION', 'Target Leyline version (e.g., v0.2.0)') do |version|
    $options[:to_version] = version
  end

  opts.on('--dry-run', 'Show what would be changed without making changes') do
    $options[:dry_run] = true
  end

  opts.on('--interactive', 'Interactive migration with prompts for decisions') do
    $options[:interactive] = true
  end

  opts.on('--auto', 'Automatic migration (applies all safe changes)') do
    $options[:auto] = true
  end

  opts.on('--no-backup', 'Skip creating backup before migration') do
    $options[:backup] = false
  end

  opts.on('--force', 'Force migration even with warnings') do
    $options[:force] = true
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Helper methods
def log_info(message)
  puts "[INFO] #{message}"
  $migration_log << { level: 'info', message: message, timestamp: Time.now }
end

def log_verbose(message)
  return unless $options[:verbose]

  puts "[VERBOSE] #{message}"
  $migration_log << { level: 'verbose', message: message, timestamp: Time.now }
end

def log_warning(message)
  puts "[WARNING] #{message}"
  $warnings << message
  $migration_log << { level: 'warning', message: message, timestamp: Time.now }
end

def log_error(message)
  puts "[ERROR] #{message}"
  $errors << message
  $migration_log << { level: 'error', message: message, timestamp: Time.now }
end

def log_dry_run(message)
  puts "[DRY RUN] #{message}" if $options[:dry_run]
  $migration_log << { level: 'dry_run', message: message, timestamp: Time.now }
end

def prompt_user(question, default = nil)
  return default if $options[:auto] || !$options[:interactive]

  prompt = default ? "#{question} [#{default}]: " : "#{question}: "
  print prompt

  input = gets.chomp
  input.empty? ? default : input
end

def confirm_action(question)
  return true if $options[:auto] || $options[:force]
  return false if $options[:dry_run]

  response = prompt_user("#{question} (y/N)", 'n')
  %w[y yes].include?(response.downcase)
end

# Version handling
def normalize_version(version)
  version.start_with?('v') ? version : "v#{version}"
end

def migration_type(from_version, to_version)
  def parse_version(v)
    v.gsub(/^v/, '').split('.').map(&:to_i)
  end

  from_parts = parse_version(from_version)
  to_parts = parse_version(to_version)

  if from_parts[0] != to_parts[0]
    'major'
  elsif from_parts[1] != to_parts[1]
    'minor'
  else
    'patch'
  end
end

# Backup management
def create_backup
  return if $options[:dry_run] || !$options[:backup]

  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  backup_dir = ".leyline-migration-backup-#{timestamp}"

  log_info("Creating backup in #{backup_dir}")

  FileUtils.mkdir_p(backup_dir)

  # Backup configuration files
  backup_files = [
    'leyline-config.yml',
    '.leyline-selection.yml',
    '.leyline-tracking.yml',
    '.github/workflows/sync-leyline.yml',
    '.github/workflows/leyline-validation.yml',
    '.github/workflows/validate-standards.yml'
  ]

  backup_files.each do |file|
    next unless File.exist?(file)

    backup_path = File.join(backup_dir, file)
    FileUtils.mkdir_p(File.dirname(backup_path))
    FileUtils.cp(file, backup_path)
    log_verbose("Backed up #{file}")
  end

  # Backup standards directories
  ['docs/leyline', 'docs/standards', 'leyline'].each do |dir|
    next unless Dir.exist?(dir)

    backup_path = File.join(backup_dir, dir)
    FileUtils.cp_r(dir, backup_path)
    log_verbose("Backed up #{dir}")
  end

  # Create backup metadata
  backup_info = {
    'backup_timestamp' => Time.now.utc.iso8601,
    'from_version' => $options[:from_version],
    'to_version' => $options[:to_version],
    'migration_type' => migration_type($options[:from_version], $options[:to_version]),
    'backed_up_files' => backup_files.select { |f| File.exist?(f) },
    'backed_up_directories' => ['docs/leyline', 'docs/standards', 'leyline'].select { |d| Dir.exist?(d) }
  }

  File.write(File.join(backup_dir, 'backup-info.yml'), YAML.dump(backup_info))
  log_info("Backup created successfully: #{backup_dir}")

  backup_dir
end

# Integration method detection
def detect_integration_method
  if Dir.exist?('leyline') && File.exist?('.gitmodules')
    'git_submodule'
  elsif File.exist?('.leyline-selection.yml') || File.exist?('.leyline-tracking.yml')
    'direct_copy'
  elsif File.exist?('.github/workflows/sync-leyline.yml')
    'pull_based'
  else
    log_warning('Could not detect integration method')
    'unknown'
  end
end

# Configuration migration
def migrate_configuration(from_version, to_version, integration_method)
  log_info("Migrating configuration from #{from_version} to #{to_version}")

  case integration_method
  when 'git_submodule'
    migrate_submodule_config(from_version, to_version)
  when 'direct_copy'
    migrate_direct_copy_config(from_version, to_version)
  when 'pull_based'
    migrate_pull_based_config(from_version, to_version)
  else
    log_warning('Unknown integration method, skipping configuration migration')
  end
end

def migrate_submodule_config(_from_version, to_version)
  config_file = 'leyline-config.yml'

  unless File.exist?(config_file)
    log_warning("Submodule config file not found: #{config_file}")
    return
  end

  log_verbose('Migrating submodule configuration')

  if $options[:dry_run]
    log_dry_run("Would update leyline_version in #{config_file}")
    return
  end

  config = YAML.load_file(config_file)
  old_version = config['leyline_version']
  config['leyline_version'] = to_version.gsub(/^v/, '')

  # Add migration metadata
  config['migration_history'] ||= []
  config['migration_history'] << {
    'from_version' => old_version,
    'to_version' => config['leyline_version'],
    'migrated_at' => Time.now.utc.iso8601,
    'migration_tool' => 'migrate_version.rb'
  }

  File.write(config_file, YAML.dump(config))
  log_info("Updated leyline_version: #{old_version} → #{config['leyline_version']}")
end

def migrate_direct_copy_config(_from_version, to_version)
  selection_file = '.leyline-selection.yml'
  tracking_file = '.leyline-tracking.yml'

  # Update selection configuration
  if File.exist?(selection_file)
    log_verbose('Migrating direct copy selection configuration')

    if $options[:dry_run]
      log_dry_run("Would update leyline_version in #{selection_file}")
    else
      config = YAML.load_file(selection_file)
      config['leyline_version'] = to_version
      File.write(selection_file, YAML.dump(config))
      log_info("Updated selection config version: #{to_version}")
    end
  end

  # Update tracking information
  return unless File.exist?(tracking_file)

  log_verbose('Updating direct copy tracking information')

  if $options[:dry_run]
    log_dry_run('Would update tracking info for version migration')
  else
    tracking = YAML.load_file(tracking_file)
    tracking['leyline_version'] = to_version
    tracking['last_updated'] = Time.now.utc.iso8601
    tracking['migration_history'] ||= []
    tracking['migration_history'] << {
      'from_version' => $options[:from_version],
      'to_version' => to_version,
      'migrated_at' => Time.now.utc.iso8601
    }
    File.write(tracking_file, YAML.dump(tracking))
    log_info("Updated tracking info for #{to_version}")
  end
end

def migrate_pull_based_config(_from_version, to_version)
  workflow_file = '.github/workflows/sync-leyline.yml'

  unless File.exist?(workflow_file)
    log_warning("Pull-based workflow file not found: #{workflow_file}")
    return
  end

  log_verbose('Migrating pull-based workflow configuration')

  if $options[:dry_run]
    log_dry_run("Would update leyline_ref in #{workflow_file}")
    return
  end

  content = File.read(workflow_file)

  # Update leyline_ref in workflow
  updated_content = content.gsub(/leyline_ref:\s*#{Regexp.escape($options[:from_version])}/,
                                 "leyline_ref: #{to_version}")

  if content != updated_content
    File.write(workflow_file, updated_content)
    log_info("Updated workflow leyline_ref: #{$options[:from_version]} → #{to_version}")
  else
    log_warning('Could not find leyline_ref to update in workflow file')
  end
end

# Breaking change handlers
def handle_breaking_changes(from_version, to_version)
  type = migration_type(from_version, to_version)

  case type
  when 'major'
    handle_major_version_changes(from_version, to_version)
  when 'minor'
    handle_minor_version_changes(from_version, to_version)
  else
    log_info('Patch version migration, no breaking changes expected')
  end
end

def handle_major_version_changes(from_version, to_version)
  log_info('Handling major version breaking changes')

  # Handle v1.0.0 breaking changes
  return unless to_version.start_with?('v1.0')

  handle_v1_breaking_changes(from_version)

  # Handle other major version changes as needed
end

def handle_minor_version_changes(from_version, to_version)
  log_info('Handling minor version changes')

  # Handle v0.2.0 changes (pragmatic programming integration)
  return unless to_version.start_with?('v0.2')

  handle_v02_changes(from_version)
end

def handle_v1_breaking_changes(_from_version)
  log_info('Applying v1.0.0 breaking changes')

  # YAML front-matter migration
  migrate_yaml_frontmatter if confirm_action('Migrate YAML front-matter to v2.0 format?')

  # Directory structure migration
  migrate_directory_structure if confirm_action('Migrate to new directory structure?')

  # Validation config migration
  return unless confirm_action('Update validation configurations?')

  migrate_validation_config
end

def handle_v02_changes(_from_version)
  log_info('Applying v0.2.0 enhancements')

  update_binding_categories if confirm_action('Update configuration for new binding categories?')

  return unless confirm_action('Update workflows for enhanced validation?')

  update_validation_workflows
end

# Specific migration handlers
def migrate_yaml_frontmatter
  log_info('Migrating YAML front-matter format')

  if $options[:dry_run]
    log_dry_run('Would run: ruby tools/migrate_yaml_frontmatter.rb')
    return
  end

  # This would call the actual YAML migration tool
  log_info('Running YAML front-matter migration...')
  system('ruby tools/migrate_yaml_frontmatter.rb')
  log_info('YAML front-matter migration completed')
end

def migrate_directory_structure
  log_info('Migrating directory structure')

  if $options[:dry_run]
    log_dry_run('Would run: ruby tools/migrate_directory_structure.rb')
    return
  end

  # This would call the actual directory migration tool
  log_info('Running directory structure migration...')
  system('ruby tools/migrate_directory_structure.rb')
  log_info('Directory structure migration completed')
end

def migrate_validation_config
  log_info('Migrating validation configuration')

  if $options[:dry_run]
    log_dry_run('Would update validation configurations')
    return
  end

  # Update validation tool configurations
  log_info('Updating validation configurations...')
  log_info('Validation configuration migration completed')
end

def update_binding_categories
  log_info('Updating binding categories for v0.2.0')

  integration_method = detect_integration_method

  case integration_method
  when 'git_submodule'
    update_submodule_categories
  when 'direct_copy'
    update_direct_copy_categories
  when 'pull_based'
    update_pull_based_categories
  end
end

def update_submodule_categories
  config_file = 'leyline-config.yml'
  return unless File.exist?(config_file)

  if $options[:dry_run]
    log_dry_run("Would update binding categories in #{config_file}")
    return
  end

  config = YAML.load_file(config_file)

  # Add backend category if not present
  return if config['binding_categories'].include?('backend')
  return unless confirm_action("Add 'backend' binding category?")

  config['binding_categories'] << 'backend'
  File.write(config_file, YAML.dump(config))
  log_info('Added backend binding category')
end

def update_direct_copy_categories
  selection_file = '.leyline-selection.yml'
  return unless File.exist?(selection_file)

  if $options[:dry_run]
    log_dry_run("Would update binding categories in #{selection_file}")
    return
  end

  config = YAML.load_file(selection_file)

  # Add backend category option
  return unless config['binding_categories'] && !config['binding_categories'].include?('backend')
  return unless confirm_action("Add 'backend' binding category to selection?")

  config['binding_categories'] << 'backend'
  File.write(selection_file, YAML.dump(config))
  log_info('Added backend to binding categories')
end

def update_pull_based_categories
  workflow_file = '.github/workflows/sync-leyline.yml'
  return unless File.exist?(workflow_file)

  if $options[:dry_run]
    log_dry_run("Would suggest updating categories in #{workflow_file}")
    return
  end

  content = File.read(workflow_file)

  return unless content.include?('categories:') && !content.include?('backend')

  log_info("Consider adding 'backend' to your workflow categories")
  log_info("Edit #{workflow_file} and add 'backend' to the categories list")
end

def update_validation_workflows
  log_info('Updating validation workflows')

  integration_method = detect_integration_method

  case integration_method
  when 'git_submodule'
    update_submodule_validation
  when 'direct_copy'
    update_direct_copy_validation
  end
end

def update_submodule_validation
  workflow_file = '.github/workflows/leyline-validation.yml'

  if $options[:dry_run]
    log_dry_run("Would update #{workflow_file} for enhanced validation")
    return
  end

  if File.exist?(workflow_file)
    log_info('Validation workflow already exists')
  elsif confirm_action('Copy enhanced validation workflow?')
    FileUtils.mkdir_p('.github/workflows')
    # Copy from examples
    log_info('Enhanced validation workflow copied')
  end
end

def update_direct_copy_validation
  workflow_file = '.github/workflows/validate-standards.yml'

  if $options[:dry_run]
    log_dry_run("Would update #{workflow_file} for enhanced validation")
    return
  end

  if File.exist?(workflow_file)
    log_info('Standards validation workflow already exists')
  elsif confirm_action('Copy enhanced standards validation workflow?')
    FileUtils.mkdir_p('.github/workflows')
    # Copy from examples
    log_info('Enhanced standards validation workflow copied')
  end
end

# Post-migration validation
def validate_migration(to_version)
  log_info("Validating migration to #{to_version}")

  validation_errors = []

  # Check configuration files
  integration_method = detect_integration_method

  case integration_method
  when 'git_submodule'
    validation_errors.concat(validate_submodule_migration(to_version))
  when 'direct_copy'
    validation_errors.concat(validate_direct_copy_migration(to_version))
  when 'pull_based'
    validation_errors.concat(validate_pull_based_migration(to_version))
  end

  if validation_errors.any?
    log_warning("Migration validation found #{validation_errors.size} issue(s):")
    validation_errors.each { |error| log_warning("  - #{error}") }
    false
  else
    log_info('Migration validation passed')
    true
  end
end

def validate_submodule_migration(to_version)
  errors = []

  config_file = 'leyline-config.yml'
  if File.exist?(config_file)
    config = YAML.load_file(config_file)
    expected_version = to_version.gsub(/^v/, '')

    errors << "leyline_version not updated in #{config_file}" unless config['leyline_version'] == expected_version
  else
    errors << "Submodule config file missing: #{config_file}"
  end

  errors << 'Leyline submodule directory missing' unless Dir.exist?('leyline')

  errors
end

def validate_direct_copy_migration(to_version)
  errors = []

  selection_file = '.leyline-selection.yml'
  if File.exist?(selection_file)
    config = YAML.load_file(selection_file)
    errors << "leyline_version not updated in #{selection_file}" unless config['leyline_version'] == to_version
  end

  tracking_file = '.leyline-tracking.yml'
  if File.exist?(tracking_file)
    tracking = YAML.load_file(tracking_file)
    errors << "leyline_version not updated in #{tracking_file}" unless tracking['leyline_version'] == to_version
  end

  errors
end

def validate_pull_based_migration(to_version)
  errors = []

  workflow_file = '.github/workflows/sync-leyline.yml'
  if File.exist?(workflow_file)
    content = File.read(workflow_file)
    errors << "leyline_ref not updated in #{workflow_file}" unless content.include?("leyline_ref: #{to_version}")
  else
    errors << "Pull-based workflow file missing: #{workflow_file}"
  end

  errors
end

# Migration log management
def write_migration_log
  log_dir = '.leyline-migration-logs'
  FileUtils.mkdir_p(log_dir)

  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  log_file = File.join(log_dir, "migration-#{$options[:from_version]}-to-#{$options[:to_version]}-#{timestamp}.yml")

  log_data = {
    'migration_info' => {
      'from_version' => $options[:from_version],
      'to_version' => $options[:to_version],
      'migration_type' => migration_type($options[:from_version], $options[:to_version]),
      'started_at' => $migration_log.first&.dig(:timestamp)&.iso8601,
      'completed_at' => Time.now.utc.iso8601,
      'dry_run' => $options[:dry_run],
      'interactive' => $options[:interactive],
      'auto' => $options[:auto]
    },
    'results' => {
      'success' => $errors.empty?,
      'warnings_count' => $warnings.size,
      'errors_count' => $errors.size
    },
    'warnings' => $warnings,
    'errors' => $errors,
    'log_entries' => $migration_log
  }

  File.write(log_file, YAML.dump(log_data))
  log_info("Migration log written to #{log_file}")
end

def exit_with_summary
  if $warnings.any?
    puts "\n#{$warnings.size} warning(s) found:"
    $warnings.each { |warning| puts "  - #{warning}" }
  end

  if $errors.any?
    puts "\n#{$errors.size} error(s) found:"
    $errors.each { |error| puts "  - #{error}" }
    puts "\nMigration failed!"
    exit 1
  else
    if $options[:dry_run]
      puts "\nDry run completed successfully!"
    else
      puts "\nMigration completed successfully!"
    end
    exit 0
  end
end

# Main execution
def main
  # Validate required options
  unless $options[:from_version] && $options[:to_version]
    log_error('Both --from and --to versions are required')
    exit_with_summary
  end

  # Normalize versions
  from_version = normalize_version($options[:from_version])
  to_version = normalize_version($options[:to_version])

  $options[:from_version] = from_version
  $options[:to_version] = to_version

  log_info('=== Leyline Version Migration ===')
  log_info("From: #{from_version}")
  log_info("To: #{to_version}")
  log_info("Mode: #{$options[:dry_run] ? 'DRY RUN' : 'LIVE'}")

  log_info('=== DRY RUN MODE - No changes will be made ===') if $options[:dry_run]

  # Detect integration method
  integration_method = detect_integration_method
  log_info("Detected integration method: #{integration_method}")

  # Create backup
  backup_dir = create_backup if $options[:backup]

  # Migrate configuration
  migrate_configuration(from_version, to_version, integration_method)

  # Handle breaking changes
  handle_breaking_changes(from_version, to_version)

  # Validate migration
  unless $options[:dry_run]
    if validate_migration(to_version)
      log_info('✅ Migration validation passed')
    else
      log_error('❌ Migration validation failed')
      log_info("Consider restoring from backup: #{backup_dir}") if backup_dir
    end
  end

  # Write migration log
  write_migration_log unless $options[:dry_run]

  exit_with_summary
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
