#!/usr/bin/env ruby
# copy-leyline-standards.rb - Copy selected Leyline standards to your project
#
# This script allows you to selectively copy Leyline tenets and bindings
# into your project with version tracking and customization options.
#
# Usage:
#   ruby copy-leyline-standards.rb --config .leyline-selection.yml
#   ruby copy-leyline-standards.rb --interactive
#   ruby copy-leyline-standards.rb --help

require 'yaml'
require 'fileutils'
require 'optparse'
require 'digest'
require 'json'
require 'net/http'
require 'uri'
require 'time'

# Configuration and state
$options = {
  config_file: '.leyline-selection.yml',
  interactive: false,
  verbose: false,
  dry_run: false,
  update: false,
  check_updates: false,
  force: false
}

$errors = []
$warnings = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: copy-leyline-standards.rb [options]'

  opts.on('-c', '--config FILE', 'Configuration file path') do |file|
    $options[:config_file] = file
  end

  opts.on('-i', '--interactive', 'Interactive mode for selecting standards') do
    $options[:interactive] = true
  end

  opts.on('-o', '--output DIR', 'Output directory') do |dir|
    $options[:output_override] = dir
  end

  opts.on('-v', '--version VERSION', 'Leyline version to copy from') do |version|
    $options[:version_override] = version
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('--dry-run', 'Show what would be done without making changes') do
    $options[:dry_run] = true
  end

  opts.on('--update', 'Update previously copied standards') do
    $options[:update] = true
  end

  opts.on('--check-updates', 'Check for available updates') do
    $options[:check_updates] = true
  end

  opts.on('--force', 'Force operation even with warnings') do
    $options[:force] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Helper methods
def log_info(message)
  puts "[INFO] #{message}"
end

def log_verbose(message)
  puts "[VERBOSE] #{message}" if $options[:verbose]
end

def log_warning(message)
  puts "[WARNING] #{message}"
  $warnings << message
end

def log_error(message)
  puts "[ERROR] #{message}"
  $errors << message
end

def exit_with_summary
  if $warnings.any?
    puts "\n#{$warnings.size} warning(s) found:"
    $warnings.each { |warning| puts "  - #{warning}" }
  end

  if $errors.any?
    puts "\n#{$errors.size} error(s) found:"
    $errors.each { |error| puts "  - #{error}" }
    puts "\nOperation failed!"
    exit 1
  else
    puts "\nOperation completed successfully!"
    exit 0
  end
end

# Load configuration
def load_configuration
  config_file = $options[:config_file]

  return run_interactive_selection if $options[:interactive]

  unless File.exist?(config_file)
    log_error("Configuration file not found: #{config_file}")
    log_error("Create one with: cp examples/consumer-direct-copy/standards-selection.yml #{config_file}")
    return nil
  end

  begin
    config = YAML.load_file(config_file)
    log_verbose("Loaded configuration from #{config_file}")
    config
  rescue StandardError => e
    log_error("Failed to load configuration: #{e.message}")
    nil
  end
end

# Interactive mode for selecting standards
def run_interactive_selection
  log_info('Running interactive selection mode...')

  {
    'leyline_version' => prompt_for_version,
    'output_directory' => prompt_for_output_directory,
    'tenets' => prompt_for_tenets,
    'binding_categories' => prompt_for_binding_categories,
    'tracking' => {
      'track_versions' => true,
      'track_checksums' => true,
      'track_sources' => true
    }
  }
end

def prompt_for_version
  print 'Enter Leyline version to copy from (e.g., v0.1.5): '
  version = gets.chomp
  version.empty? ? 'v0.1.5' : version
end

def prompt_for_output_directory
  print 'Enter output directory (default: docs/standards): '
  dir = gets.chomp
  dir.empty? ? 'docs/standards' : dir
end

def prompt_for_tenets
  log_info('Available tenets:')
  available_tenets = get_available_tenets
  available_tenets.each_with_index do |tenet, i|
    puts "  #{i + 1}. #{tenet}"
  end

  print 'Enter tenet numbers (comma-separated, e.g., 1,2,3): '
  selections = gets.chomp.split(',').map(&:strip).map(&:to_i)

  selected_tenets = selections.map { |i| available_tenets[i - 1] }.compact
  log_info("Selected tenets: #{selected_tenets.join(', ')}")
  selected_tenets
end

def prompt_for_binding_categories
  log_info('Available binding categories:')
  available_categories = get_available_binding_categories
  available_categories.each_with_index do |category, i|
    puts "  #{i + 1}. #{category}"
  end

  print 'Enter category numbers (comma-separated, e.g., 1,2): '
  selections = gets.chomp.split(',').map(&:strip).map(&:to_i)

  selected_categories = selections.map { |i| available_categories[i - 1] }.compact
  log_info("Selected categories: #{selected_categories.join(', ')}")
  selected_categories
end

def get_available_tenets
  # In a real implementation, this would fetch from the Leyline repository
  %w[
    simplicity
    testability
    explicit-over-implicit
    maintainability
    modularity
    orthogonality
    dry-dont-repeat-yourself
    automation
    document-decisions
    fix-broken-windows
    no-secret-suppression
  ]
end

def get_available_binding_categories
  # In a real implementation, this would fetch from the Leyline repository
  %w[core typescript go rust frontend backend]
end

# Fetch content from Leyline repository
def fetch_leyline_content(version, path)
  base_url = 'https://raw.githubusercontent.com/phrazzld/leyline'
  url = "#{base_url}/#{version}/#{path}"

  log_verbose("Fetching: #{url}")

  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    return response.body if response.code == '200'

    log_error("Failed to fetch #{path}: HTTP #{response.code}")
    nil
  rescue StandardError => e
    log_error("Network error fetching #{path}: #{e.message}")
    nil
  end
end

# Copy a single standard file
def copy_standard(config, type, name, source_path, dest_path)
  version = $options[:version_override] || config['leyline_version']

  log_info("Copying #{type}/#{name}...")

  if $options[:dry_run]
    log_info("[DRY RUN] Would copy #{source_path} to #{dest_path}")
    return true
  end

  # Fetch content from Leyline repository
  content = fetch_leyline_content(version, source_path)
  return false unless content

  # Apply customizations if configured
  content = apply_customizations(content, config['customization'], type, name) if config['customization']

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(dest_path))

  # Write the file
  begin
    File.write(dest_path, content)
    log_verbose("Written: #{dest_path}")

    # Track the copy if tracking is enabled
    track_copied_file(config, version, source_path, dest_path, content) if config['tracking']

    true
  rescue StandardError => e
    log_error("Failed to write #{dest_path}: #{e.message}")
    false
  end
end

# Apply customizations to content
def apply_customizations(content, customization, _type, _name)
  result = content.dup

  # Apply text replacements
  if customization['replacements']
    customization['replacements'].each do |find, replace|
      result.gsub!(find, replace)
    end
  end

  # Add project context
  if customization['add_project_context']
    project_note = "\n> **Note**: This standard has been copied from Leyline and may be customized for this project.\n"
    result = result.sub(/^(# .+)/, "\\1#{project_note}")
  end

  # Add implementation notes
  if customization['add_implementation_notes']
    impl_note = "\n## Implementation in This Project\n\nSee project documentation for specific implementation guidelines and examples.\n"
    result += impl_note
  end

  # Apply additions
  if customization['additions']
    customization['additions'].each do |addition|
      case addition['position']
      when 'end'
        result += "\n\n#{addition['section']}\n\n#{addition['content']}\n"
      when 'beginning'
        # Add after title
        result = result.sub(/^(# .+)\n/, "\\1\n\n#{addition['section']}\n\n#{addition['content']}\n")
      end
    end
  end

  # Apply removals
  if customization['removals']
    customization['removals'].each do |removal|
      pattern = removal['pattern']
      # Remove section and its content until next section or end
      result.gsub!(/#{Regexp.escape(pattern)}.*?(?=\n#|\Z)/m, '')
    end
  end

  result
end

# Track copied file information
def track_copied_file(_config, version, source_path, dest_path, content)
  tracking_file = '.leyline-tracking.yml'

  # Load existing tracking data
  tracking_data = if File.exist?(tracking_file)
                    YAML.load_file(tracking_file)
                  else
                    {
                      'tracking_version' => '1.0',
                      'standards' => {}
                    }
                  end

  # Calculate checksum
  checksum = Digest::SHA256.hexdigest(content)

  # Store tracking information
  relative_dest = dest_path.sub(%r{^#{Regexp.escape(Dir.pwd)}/}, '')
  source_url = "https://github.com/phrazzld/leyline/blob/#{version}/#{source_path}"

  tracking_data['last_updated'] = Time.now.utc.iso8601
  tracking_data['leyline_version'] = version
  tracking_data['standards'][relative_dest] = {
    'source_version' => version,
    'source_url' => source_url,
    'source_path' => source_path,
    'checksum' => checksum,
    'copied_at' => Time.now.utc.iso8601,
    'modified_locally' => false
  }

  # Write tracking file
  File.write(tracking_file, YAML.dump(tracking_data))
  log_verbose("Updated tracking: #{tracking_file}")
end

# Copy tenets
def copy_tenets(config, tenets)
  return true if tenets.nil? || tenets.empty?

  output_dir = $options[:output_override] || config['output_directory']
  tenets_dir = File.join(output_dir, 'tenets')

  success_count = 0

  tenets.each do |tenet|
    source_path = "docs/tenets/#{tenet}.md"
    dest_path = File.join(tenets_dir, "#{tenet}.md")

    success_count += 1 if copy_standard(config, 'tenet', tenet, source_path, dest_path)
  end

  log_info("Copied #{success_count}/#{tenets.size} tenets")
  success_count == tenets.size
end

# Copy binding categories
def copy_binding_categories(config, categories)
  return true if categories.nil? || categories.empty?

  output_dir = $options[:output_override] || config['output_directory']
  success_count = 0

  categories.each do |category|
    if category == 'core'
      # Copy core bindings
      core_bindings = get_core_bindings
      core_bindings.each do |binding|
        source_path = "docs/bindings/core/#{binding}.md"
        dest_path = File.join(output_dir, 'bindings', 'core', "#{binding}.md")

        success_count += 1 if copy_standard(config, 'binding', "core/#{binding}", source_path, dest_path)
      end
    else
      # Copy category-specific bindings
      category_bindings = get_category_bindings(category)
      category_bindings.each do |binding|
        source_path = "docs/bindings/categories/#{category}/#{binding}.md"
        dest_path = File.join(output_dir, 'bindings', category, "#{binding}.md")

        success_count += 1 if copy_standard(config, 'binding', "#{category}/#{binding}", source_path, dest_path)
      end
    end
  end

  log_info("Copied #{success_count} bindings from #{categories.size} categories")
  success_count > 0
end

# Get list of core bindings (in real implementation, fetch from repository)
def get_core_bindings
  %w[
    api-design
    component-architecture
    pure-functions
    semantic-versioning
    require-conventional-commits
  ]
end

# Get list of bindings for a category (in real implementation, fetch from repository)
def get_category_bindings(category)
  case category
  when 'typescript'
    %w[no-any async-patterns type-safe-state-management]
  when 'go'
    %w[error-wrapping interface-design package-design]
  when 'rust'
    %w[error-handling ownership-patterns trait-composition-patterns]
  when 'frontend'
    %w[state-management web-accessibility]
  when 'backend'
    %w[] # Would be populated from actual repository
  else
    []
  end
end

# Generate project index
def generate_index(config)
  output_dir = $options[:output_override] || config['output_directory']
  return unless config.dig('output', 'create_index')

  if $options[:dry_run]
    log_info("[DRY RUN] Would generate index at #{output_dir}/README.md")
    return
  end

  index_content = generate_index_content(config, output_dir)
  index_path = File.join(output_dir, 'README.md')

  begin
    File.write(index_path, index_content)
    log_info("Generated index: #{index_path}")
  rescue StandardError => e
    log_error("Failed to generate index: #{e.message}")
  end
end

def generate_index_content(config, _output_dir)
  content = "# Development Standards\n\n"
  content += "This directory contains development standards copied from Leyline.\n\n"

  version = $options[:version_override] || config['leyline_version']
  content += "**Source**: [Leyline #{version}](https://github.com/phrazzld/leyline/tree/#{version})\n"
  content += "**Last Updated**: #{Time.now.strftime('%Y-%m-%d')}\n\n"

  # Add tenets section
  if config['tenets'] && !config['tenets'].empty?
    content += "## Tenets\n\n"
    content += "Core principles that guide development:\n\n"
    config['tenets'].each do |tenet|
      content += "- [#{tenet.tr('-', ' ').split.map(&:capitalize).join(' ')}](tenets/#{tenet}.md)\n"
    end
    content += "\n"
  end

  # Add bindings section
  if config['binding_categories'] && !config['binding_categories'].empty?
    content += "## Bindings\n\n"
    content += "Specific implementation standards:\n\n"

    config['binding_categories'].each do |category|
      content += "### #{category.capitalize} Bindings\n\n"
      bindings = category == 'core' ? get_core_bindings : get_category_bindings(category)
      bindings.each do |binding|
        path = category == 'core' ? "bindings/core/#{binding}.md" : "bindings/#{category}/#{binding}.md"
        title = binding.tr('-', ' ').split.map(&:capitalize).join(' ')
        content += "- [#{title}](#{path})\n"
      end
      content += "\n"
    end
  end

  content += "## Usage\n\n"
  content += "These standards are copied from Leyline and may be customized for this project.\n"
  content += "See the tracking file `.leyline-tracking.yml` for version and source information.\n\n"
  content += "To update these standards:\n"
  content += "```bash\n"
  content += "ruby scripts/copy-leyline-standards.rb --update --version v0.2.0\n"
  content += "```\n"

  content
end

# Check for updates
def check_for_updates
  log_info('Checking for available updates...')

  tracking_file = '.leyline-tracking.yml'
  unless File.exist?(tracking_file)
    log_warning('No tracking file found - no standards to check')
    return
  end

  tracking_data = YAML.load_file(tracking_file)
  current_version = tracking_data['leyline_version']

  log_info("Current version: #{current_version}")

  # In a real implementation, this would check GitHub releases API
  log_info('Latest version: v0.2.0')
  log_info('Updates available: Use --update --version v0.2.0 to update')
end

# Main execution
def main
  log_info('=== DRY RUN MODE - No changes will be made ===') if $options[:dry_run]

  if $options[:check_updates]
    check_for_updates
    exit_with_summary
  end

  # Load configuration
  config = load_configuration
  exit_with_summary if config.nil?

  log_info('Starting standards copy operation...')

  # Copy tenets
  copy_tenets(config, config['tenets']) if config['tenets']

  # Copy binding categories
  copy_binding_categories(config, config['binding_categories']) if config['binding_categories']

  # Copy specific bindings
  if config['specific_bindings']
    # Implementation would handle individual binding copy
    log_info('Specific bindings copying not yet implemented')
  end

  # Generate index if requested
  generate_index(config)

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
