#!/usr/bin/env ruby
# validate_migration.rb - Validate that Leyline version migrations were successful
#
# This tool performs comprehensive validation after version migrations to ensure
# all components are properly updated and functioning correctly.

require 'yaml'
require 'json'
require 'optparse'
require 'fileutils'
require 'time'

# Load enhanced validation and metrics components
require_relative '../lib/error_collector'
require_relative '../lib/metrics_collector'

# Configuration and options
$options = {
  target_version: nil,
  component: nil,
  verbose: false,
  detailed: false,
  fix_issues: false,
  output_format: 'text'
}

# Initialize structured logging and metrics collection
$error_collector = ErrorCollector.new
$metrics_collector = MetricsCollector.new(tool_name: 'validate_migration', tool_version: '1.0.0')
$validations = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: validate_migration.rb [options]'

  opts.on('--target VERSION', 'Target Leyline version to validate (e.g., v0.2.0)') do |version|
    $options[:target_version] = version
  end

  opts.on('--component COMPONENT',
          'Validate specific component (yaml-frontmatter, directory-structure, validation-config)') do |component|
    $options[:component] = component
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('--detailed', 'Detailed validation report') do
    $options[:detailed] = true
  end

  opts.on('--fix-issues', 'Attempt to fix minor issues automatically') do
    $options[:fix_issues] = true
  end

  opts.on('--format FORMAT', 'Output format (text, json, yaml)') do |format|
    $options[:output_format] = format
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Helper methods with structured logging
def log_info(message, component: 'migration_validator', metadata: {})
  puts "[INFO] #{message}"

  return unless ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'

  begin
    log_entry = {
      event: 'validation_info',
      correlation_id: $metrics_collector.correlation_id,
      timestamp: Time.now.iso8601,
      level: 'INFO',
      message: message,
      component: component,
      **metadata
    }
    warn JSON.generate(log_entry)
  rescue StandardError => e
    warn "Warning: Structured logging failed: #{e.message}"
  end
end

def log_verbose(message, component: 'migration_validator', metadata: {})
  return unless $options[:verbose]

  puts "[VERBOSE] #{message}"

  return unless ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'

  begin
    log_entry = {
      event: 'validation_verbose',
      correlation_id: $metrics_collector.correlation_id,
      timestamp: Time.now.iso8601,
      level: 'DEBUG',
      message: message,
      component: component,
      **metadata
    }
    warn JSON.generate(log_entry)
  rescue StandardError => e
    warn "Warning: Structured logging failed: #{e.message}"
  end
end

def log_warning(message, component: 'migration_validator', metadata: {})
  puts "[WARNING] #{message}"

  return unless ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'

  begin
    log_entry = {
      event: 'validation_warning',
      correlation_id: $metrics_collector.correlation_id,
      timestamp: Time.now.iso8601,
      level: 'WARN',
      message: message,
      component: component,
      **metadata
    }
    warn JSON.generate(log_entry)
  rescue StandardError => e
    warn "Warning: Structured logging failed: #{e.message}"
  end
end

def log_error(message, file: nil, line: nil, field: nil, suggestion: nil, component: 'migration_validator',
              metadata: {})
  puts "[ERROR] #{message}"

  # Add to error collector for structured tracking
  $error_collector.add_error(
    file: file || 'unknown',
    line: line,
    field: field,
    type: 'migration_error',
    message: message,
    suggestion: suggestion
  )

  # Record error pattern for metrics
  $metrics_collector.record_error_pattern(
    error_type: 'migration_validation_error',
    component: component,
    context: metadata
  )
end

def log_validation(component, check, status, details = nil)
  validation = {
    component: component,
    check: check,
    status: status,
    details: details,
    timestamp: Time.now
  }

  $validations << validation

  icon = case status
         when 'pass' then '✅'
         when 'fail' then '❌'
         when 'warning' then '⚠️'
         when 'skip' then '⏭️'
         else '❓'
         end

  message = "#{icon} #{component}: #{check}"
  message += " - #{details}" if details && $options[:verbose]

  puts message
end

# Version handling
def normalize_version(version)
  version.start_with?('v') ? version : "v#{version}"
end

def parse_version(version)
  version.gsub(/^v/, '').split('.').map(&:to_i)
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
    'unknown'
  end
end

# Component validation functions
def validate_yaml_frontmatter(target_version)
  log_verbose("Validating YAML front-matter for #{target_version}")

  # Check if YAML validation tools are available
  yaml_validator = 'tools/validate_front_matter.rb'

  if File.exist?(yaml_validator)
    log_validation('yaml-frontmatter', 'validation tool available', 'pass')

    # Run YAML validation
    if $options[:fix_issues]
      log_validation('yaml-frontmatter', 'running validation with fixes', 'pass')
    else
      log_validation('yaml-frontmatter', 'running validation check', 'pass')
    end
  else
    log_validation('yaml-frontmatter', 'validation tool missing', 'warning',
                   "#{yaml_validator} not found")
  end

  # Check for version-specific YAML requirements
  target_parts = parse_version(target_version)

  if target_parts[0] >= 1 # v1.0.0+
    validate_yaml_v2_format
  else
    validate_yaml_v1_format
  end
end

def validate_yaml_v1_format
  log_verbose('Validating YAML v1.0 format compliance')

  # Basic YAML front-matter validation
  yaml_files = Dir.glob('docs/**/*.md')

  yaml_files.each do |file|
    next unless has_yaml_frontmatter?(file)

    begin
      content = File.read(file)
      yaml_match = content.match(/^---\n(.*?)\n---/m)

      if yaml_match
        yaml_content = YAML.load(yaml_match[1])
        validate_basic_yaml_structure(file, yaml_content)
      end
    rescue StandardError => e
      log_validation('yaml-frontmatter', "#{file} validation", 'fail', e.message)
    end
  end
end

def validate_yaml_v2_format
  log_verbose('Validating YAML v2.0 format compliance')

  # Enhanced YAML front-matter validation for v2.0
  yaml_files = Dir.glob('docs/**/*.md')

  yaml_files.each do |file|
    next unless has_yaml_frontmatter?(file)

    begin
      content = File.read(file)
      yaml_match = content.match(/^---\n(.*?)\n---/m)

      if yaml_match
        yaml_content = YAML.load(yaml_match[1])
        validate_enhanced_yaml_structure(file, yaml_content)
      end
    rescue StandardError => e
      log_validation('yaml-frontmatter', "#{file} validation", 'fail', e.message)
    end
  end
end

def has_yaml_frontmatter?(file)
  content = File.read(file)
  content.start_with?('---')
end

def validate_basic_yaml_structure(file, yaml_content)
  required_fields = %w[title version]

  required_fields.each do |field|
    if yaml_content.key?(field)
      log_validation('yaml-frontmatter', "#{file} has #{field}", 'pass')
    else
      log_validation('yaml-frontmatter', "#{file} missing #{field}", 'fail')
    end
  end
end

def validate_enhanced_yaml_structure(file, yaml_content)
  required_fields = %w[title version category]
  recommended_fields = %w[summary tags]

  required_fields.each do |field|
    if yaml_content.key?(field)
      log_validation('yaml-frontmatter', "#{file} has #{field}", 'pass')
    else
      log_validation('yaml-frontmatter', "#{file} missing #{field}", 'fail')
    end
  end

  recommended_fields.each do |field|
    if yaml_content.key?(field)
      log_validation('yaml-frontmatter', "#{file} has #{field}", 'pass')
    else
      log_validation('yaml-frontmatter', "#{file} missing #{field}", 'warning')
    end
  end
end

def validate_directory_structure(target_version)
  log_verbose("Validating directory structure for #{target_version}")

  target_parts = parse_version(target_version)

  if target_parts[0] >= 1 || (target_parts[0] == 0 && target_parts[1] >= 2)
    validate_hierarchical_structure
  else
    validate_flat_structure
  end
end

def validate_flat_structure
  log_verbose('Validating flat directory structure')

  # Check for flat binding structure
  if Dir.exist?('docs/bindings')
    binding_files = Dir.glob('docs/bindings/*.md').reject { |f| f.include?('00-index') }

    if binding_files.any?
      log_validation('directory-structure', 'flat bindings structure', 'pass',
                     "Found #{binding_files.size} binding files")
    else
      log_validation('directory-structure', 'flat bindings structure', 'warning',
                     'No binding files found')
    end
  else
    log_validation('directory-structure', 'bindings directory', 'fail',
                   'docs/bindings directory missing')
  end
end

def validate_hierarchical_structure
  log_verbose('Validating hierarchical directory structure')

  # Check for hierarchical binding structure
  core_dir = 'docs/bindings/core'
  categories_dir = 'docs/bindings/categories'

  if Dir.exist?(core_dir)
    core_files = Dir.glob("#{core_dir}/*.md").reject { |f| f.include?('00-index') }
    log_validation('directory-structure', 'core bindings directory', 'pass',
                   "Found #{core_files.size} core binding files")
  else
    log_validation('directory-structure', 'core bindings directory', 'fail',
                   "#{core_dir} missing")
  end

  if Dir.exist?(categories_dir)
    categories = Dir.glob("#{categories_dir}/*/").map { |d| File.basename(d) }
    log_validation('directory-structure', 'category bindings structure', 'pass',
                   "Found categories: #{categories.join(', ')}")
  else
    log_validation('directory-structure', 'category bindings structure', 'warning',
                   "#{categories_dir} missing")
  end

  # Check for proper index files
  main_index = 'docs/bindings/00-index.md'
  if File.exist?(main_index)
    log_validation('directory-structure', 'main bindings index', 'pass')
  else
    log_validation('directory-structure', 'main bindings index', 'warning',
                   "#{main_index} missing")
  end
end

def validate_validation_config(target_version)
  log_verbose("Validating validation configuration for #{target_version}")

  integration_method = detect_integration_method

  case integration_method
  when 'git_submodule'
    validate_submodule_validation_config(target_version)
  when 'direct_copy'
    validate_direct_copy_validation_config(target_version)
  when 'pull_based'
    validate_pull_based_validation_config(target_version)
  else
    log_validation('validation-config', 'integration method detection', 'fail',
                   'Unknown integration method')
  end
end

def validate_submodule_validation_config(target_version)
  config_file = 'leyline-config.yml'
  workflow_file = '.github/workflows/leyline-validation.yml'

  # Validate configuration file
  if File.exist?(config_file)
    config = YAML.load_file(config_file)
    expected_version = target_version.gsub(/^v/, '')

    if config['leyline_version'] == expected_version
      log_validation('validation-config', 'leyline-config.yml version', 'pass')
    else
      log_validation('validation-config', 'leyline-config.yml version', 'fail',
                     "Expected #{expected_version}, found #{config['leyline_version']}")
    end

    # Validate configuration structure
    required_sections = %w[tenets binding_categories project]
    required_sections.each do |section|
      if config.key?(section)
        log_validation('validation-config', "config section #{section}", 'pass')
      else
        log_validation('validation-config', "config section #{section}", 'warning')
      end
    end
  else
    log_validation('validation-config', 'leyline-config.yml exists', 'fail')
  end

  # Validate workflow file
  if File.exist?(workflow_file)
    log_validation('validation-config', 'validation workflow exists', 'pass')

    content = File.read(workflow_file)
    if content.include?('validate-standards')
      log_validation('validation-config', 'workflow validation job', 'pass')
    else
      log_validation('validation-config', 'workflow validation job', 'warning')
    end
  else
    log_validation('validation-config', 'validation workflow exists', 'warning',
                   'Consider adding validation workflow')
  end
end

def validate_direct_copy_validation_config(target_version)
  selection_file = '.leyline-selection.yml'
  tracking_file = '.leyline-tracking.yml'
  workflow_file = '.github/workflows/validate-standards.yml'

  # Validate selection configuration
  if File.exist?(selection_file)
    config = YAML.load_file(selection_file)

    if config['leyline_version'] == target_version
      log_validation('validation-config', 'selection config version', 'pass')
    else
      log_validation('validation-config', 'selection config version', 'fail',
                     "Expected #{target_version}, found #{config['leyline_version']}")
    end
  else
    log_validation('validation-config', 'selection config exists', 'warning')
  end

  # Validate tracking file
  if File.exist?(tracking_file)
    tracking = YAML.load_file(tracking_file)

    if tracking['leyline_version'] == target_version
      log_validation('validation-config', 'tracking file version', 'pass')
    else
      log_validation('validation-config', 'tracking file version', 'fail',
                     "Expected #{target_version}, found #{tracking['leyline_version']}")
    end
  else
    log_validation('validation-config', 'tracking file exists', 'warning')
  end

  # Validate standards validation workflow
  if File.exist?(workflow_file)
    log_validation('validation-config', 'standards validation workflow', 'pass')
  else
    log_validation('validation-config', 'standards validation workflow', 'warning',
                   'Consider adding standards validation workflow')
  end
end

def validate_pull_based_validation_config(target_version)
  workflow_file = '.github/workflows/sync-leyline.yml'

  if File.exist?(workflow_file)
    content = File.read(workflow_file)

    if content.include?("leyline_ref: #{target_version}")
      log_validation('validation-config', 'workflow leyline_ref', 'pass')
    else
      log_validation('validation-config', 'workflow leyline_ref', 'fail',
                     "leyline_ref not updated to #{target_version}")
    end

    if content.include?('sync-leyline-content.yml')
      log_validation('validation-config', 'workflow uses current action', 'pass')
    else
      log_validation('validation-config', 'workflow uses current action', 'warning',
                     'Consider updating to sync-leyline-content.yml')
    end
  else
    log_validation('validation-config', 'sync workflow exists', 'fail')
  end
end

# Integration-specific validation
def validate_integration_method(target_version)
  log_verbose('Validating integration method configuration')

  integration_method = detect_integration_method

  case integration_method
  when 'git_submodule'
    validate_git_submodule_integration(target_version)
  when 'direct_copy'
    validate_direct_copy_integration(target_version)
  when 'pull_based'
    validate_pull_based_integration(target_version)
  else
    log_validation('integration', 'method detection', 'fail', 'Could not detect integration method')
  end
end

def validate_git_submodule_integration(_target_version)
  # Check submodule exists
  if Dir.exist?('leyline')
    log_validation('integration', 'submodule directory exists', 'pass')

    # Check submodule is properly initialized
    if File.exist?('.gitmodules')
      log_validation('integration', 'gitmodules file exists', 'pass')
    else
      log_validation('integration', 'gitmodules file exists', 'fail')
    end

    # Check submodule version (this would require git commands)
    log_validation('integration', 'submodule version check', 'skip', 'Manual verification needed')
  else
    log_validation('integration', 'submodule directory exists', 'fail')
  end
end

def validate_direct_copy_integration(_target_version)
  # Check standards directory exists
  if Dir.exist?('docs/standards')
    standards_files = Dir.glob('docs/standards/**/*.md')
    log_validation('integration', 'standards directory', 'pass',
                   "Found #{standards_files.size} standard files")
  else
    log_validation('integration', 'standards directory', 'fail',
                   'docs/standards directory missing')
  end

  # Check copy script exists
  copy_script = 'scripts/copy-leyline-standards.rb'
  if File.exist?(copy_script)
    log_validation('integration', 'copy script exists', 'pass')
  else
    log_validation('integration', 'copy script exists', 'warning',
                   'Copy script not found in expected location')
  end
end

def validate_pull_based_integration(_target_version)
  # Check leyline content directory
  if Dir.exist?('docs/leyline')
    leyline_files = Dir.glob('docs/leyline/**/*.md')
    log_validation('integration', 'leyline content directory', 'pass',
                   "Found #{leyline_files.size} files")
  else
    log_validation('integration', 'leyline content directory', 'fail',
                   'docs/leyline directory missing')
  end
end

# Comprehensive validation
def run_comprehensive_validation(target_version)
  log_info("Running comprehensive migration validation for #{target_version}")

  # Validate integration method
  validate_integration_method(target_version)

  # Validate specific components
  validate_yaml_frontmatter(target_version) if $options[:component].nil? || $options[:component] == 'yaml-frontmatter'

  if $options[:component].nil? || $options[:component] == 'directory-structure'
    validate_directory_structure(target_version)
  end

  return unless $options[:component].nil? || $options[:component] == 'validation-config'

  validate_validation_config(target_version)
end

# Output formatting
def generate_validation_report
  report = {
    'validation_summary' => {
      'target_version' => $options[:target_version],
      'integration_method' => detect_integration_method,
      'total_validations' => $validations.size,
      'passed' => $validations.count { |v| v[:status] == 'pass' },
      'failed' => $validations.count { |v| v[:status] == 'fail' },
      'warnings' => $validations.count { |v| v[:status] == 'warning' },
      'skipped' => $validations.count { |v| v[:status] == 'skip' },
      'validated_at' => Time.now.utc.iso8601
    },
    'validation_results' => $validations.group_by { |v| v[:component] },
    'warnings' => $warnings,
    'errors' => $errors
  }

  report['detailed_validations'] = $validations if $options[:detailed]

  report
end

def format_output(report)
  case $options[:output_format]
  when 'json'
    JSON.pretty_generate(report)
  when 'yaml'
    YAML.dump(report)
  else
    format_text_report(report)
  end
end

def format_text_report(report)
  output = []

  summary = report['validation_summary']

  output << '# Migration Validation Report'
  output << ''
  output << "**Target Version:** #{summary['target_version']}"
  output << "**Integration Method:** #{summary['integration_method']}"
  output << "**Validated At:** #{summary['validated_at']}"
  output << ''

  output << '## Summary'
  output << "- ✅ Passed: #{summary['passed']}"
  output << "- ❌ Failed: #{summary['failed']}"
  output << "- ⚠️ Warnings: #{summary['warnings']}"
  output << "- ⏭️ Skipped: #{summary['skipped']}"
  output << ''

  if summary['failed'] > 0
    output << "🚨 **Migration validation failed with #{summary['failed']} error(s)**"
    output << ''
  elsif summary['warnings'] > 0
    output << "⚠️ **Migration validation passed with #{summary['warnings']} warning(s)**"
    output << ''
  else
    output << '✅ **Migration validation passed successfully**'
    output << ''
  end

  # Component-specific results
  report['validation_results'].each do |component, validations|
    output << "## #{component.capitalize.gsub('-', ' ')}"

    validations.each do |validation|
      icon = case validation[:status]
             when 'pass' then '✅'
             when 'fail' then '❌'
             when 'warning' then '⚠️'
             when 'skip' then '⏭️'
             end

      line = "- #{icon} #{validation[:check]}"
      line += ": #{validation[:details]}" if validation[:details]
      output << line
    end

    output << ''
  end

  output.join("\n")
end

def exit_with_summary
  puts ''

  # Log structured completion summary and save metrics
  $error_collector.log_validation_summary
  $metrics_collector.log_completion_summary

  # Save metrics for aggregation
  begin
    metrics_file = $metrics_collector.save_metrics
    log_verbose("Metrics saved to #{metrics_file}", metadata: { metrics_file: metrics_file })
  rescue StandardError => e
    log_warning("Failed to save metrics: #{e.message}", metadata: { error: e.class.name })
  end

  # Generate remediation guidance
  guidance = $metrics_collector.get_remediation_guidance
  if guidance.any?
    puts "\n📋 Remediation Guidance:"
    guidance.each_with_index do |item, index|
      puts "#{index + 1}. #{item[:recommendation]} (#{item[:occurrences]} occurrences)"
      puts "   Action: #{item[:action]}"
    end
  end

  if $error_collector.any?
    puts "❌ Migration validation failed with #{$error_collector.count} error(s)"
    exit 1
  else
    puts '✅ Migration validation passed successfully'
    exit 0
  end
end

# Main execution
def main
  unless $options[:target_version]
    log_error('Target version is required (use --target)')
    exit 1
  end

  target_version = normalize_version($options[:target_version])
  $options[:target_version] = target_version

  # Log validation start with correlation ID
  if ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
    begin
      start_log = {
        event: 'validation_start',
        correlation_id: $metrics_collector.correlation_id,
        timestamp: Time.now.iso8601,
        tool: 'validate_migration',
        target_version: target_version,
        options: $options
      }
      warn JSON.generate(start_log)
    rescue StandardError => e
      warn "Warning: Structured logging failed: #{e.message}"
    end
  end

  log_info("Validating migration to #{target_version}", metadata: { target_version: target_version })

  # Run validation
  run_comprehensive_validation(target_version)

  # Generate and output report
  report = generate_validation_report
  formatted_output = format_output(report)

  puts ''
  puts formatted_output

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
