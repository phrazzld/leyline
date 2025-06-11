#!/usr/bin/env ruby
# tools/validate_front_matter.rb - Validates metadata in Markdown files
# Enforces YAML front-matter format only
# See TENET_FORMATTING.md for documentation on the required format
#
# This script performs strict validation on the YAML front-matter in tenet and binding
# markdown files. It checks:
#
# 1. All files must have YAML front-matter delimited by triple dashes (---)
# 2. Required fields are present:
#    - Tenets: id, last_modified, version
#    - Bindings: id, last_modified, derived_from, enforced_by, version
# 3. Field formats are valid:
#    - id: lowercase alphanumeric with hyphens
#    - last_modified: ISO date format (YYYY-MM-DD)
#    - derived_from: lowercase alphanumeric with hyphens, must reference existing tenet
#    - enforced_by: non-empty string
#    - version: semantic version matching VERSION file (e.g., "0.1.0")
# 4. IDs are unique across all documents
# 5. All referenced tenets exist
#
# The script will report errors and warnings:
# - Errors will cause validation to fail (exit code 1)
# - Warnings are reported but will not fail validation
#
# Warnings include:
# - (none currently defined)
#
# Usage examples:
# - Validate all files: ruby tools/validate_front_matter.rb
# - Validate a specific file: ruby tools/validate_front_matter.rb -f docs/tenets/example.md

require 'yaml'
require 'date'

# Load enhanced validation components
require_relative '../lib/yaml_line_tracker'
require_relative '../lib/error_collector'

# Configuration
REQUIRED_KEYS = {
  'tenets' => %w[id last_modified version],
  'bindings' => %w[id last_modified derived_from enforced_by version]
}

# Get expected version from VERSION file
def get_expected_version
  version_file = 'VERSION'
  if File.exist?(version_file)
    File.read(version_file).strip
  else
    puts "ERROR: VERSION file not found"
    exit 1
  end
end

# Validation functions for field types
VALIDATORS = {
  'id' => ->(value) { value.is_a?(String) && value =~ /^[a-z0-9-]+$/ },
  'last_modified' => lambda { |value|
    value.is_a?(Date) ||
    (value.is_a?(String) && value =~ /^\d{4}-\d{2}-\d{2}$/ && begin
      Date.parse(value)
      true
    rescue
      false
    end)
  },
  'derived_from' => ->(value) { value.is_a?(String) && value =~ /^[a-z0-9-]+$/ },
  'enforced_by' => ->(value) { value.is_a?(String) && !value.empty? },
  'version' => lambda { |value|
    value.is_a?(String) && value =~ /^\d+\.\d+\.\d+$/ && value == get_expected_version
  }
}

# Optional keys that have validation rules when present
OPTIONAL_KEYS = {
  'bindings' => {
  }
}

# Categories are determined by the directory structure:
# - docs/bindings/core/ for core bindings
# - docs/bindings/categories/<category>/ for category-specific bindings

# Setup command line options
require 'optparse'

options = { file: nil }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: validate_front_matter.rb [options]"
  opts.separator ""
  opts.separator "This script validates the YAML front-matter in tenet and binding markdown files."
  opts.separator "It ensures all required fields are present and correctly formatted."
  opts.separator ""
  opts.separator "Options:"

  opts.on("-f FILE", "--file FILE", "Validate a specific file only") do |file|
    options[:file] = file
  end

  opts.on("-v", "--verbose", "Show additional validation details") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end

  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  ruby tools/validate_front_matter.rb             # Validate all files"
  opts.separator "  ruby tools/validate_front_matter.rb -f path.md  # Validate single file"
end

parser.parse!

# Track validation state
$all_ids = {}            # Track all ids to ensure uniqueness
$files_with_issues = []  # Track files with issues
$warnings_found = []     # Track warnings (non-fatal issues)
$single_file = options[:file]
$verbose = options[:verbose]
$error_collector = ErrorCollector.new  # Enhanced error collection

# Helper to print styled error messages
def print_error(file, message, details = nil, exit_code = 1)
  puts "  [ERROR] #{file}: #{message}"
  puts "  #{details}" if details
  $files_with_issues << file
  exit exit_code unless $single_file.nil?
end

# Helper to print styled warning messages
def print_warning(file, message, details = nil)
  puts "  [WARNING] #{file}: #{message}"
  puts "  #{details}" if details
  $warnings_found << "#{file}: #{message}"
end

# Helper method to detect front matter format
def detect_front_matter_format(content)
  if content =~ /^---\n(.*?)\n---/m
    :yaml
  else
    :unknown
  end
end

# Process directories and files
def process_tenets_files
  dir = 'docs/tenets'
  dir_base = 'tenets'
  puts "Validating #{dir_base}..."

  # Skip index files
  Dir.glob("#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
    process_single_file(file, dir_base)
  end
end

def get_binding_files
  files = []

  # Core bindings
  core_glob = "docs/bindings/core/*.md"
  files.concat(Dir.glob(core_glob).reject { |f| f =~ /00-index\.md$/ })

  # Category bindings
  categories_glob = "docs/bindings/categories/*/*.md"
  files.concat(Dir.glob(categories_glob).reject { |f| f =~ /00-index\.md$/ })

  # Check for misplaced files in the root - these should be warned about
  root_files = Dir.glob("docs/bindings/*.md").reject { |f| f =~ /00-index\.md$/ }
  if root_files.any?
    puts "  [WARNING] Found #{root_files.size} binding file(s) directly in docs/bindings/ directory."
    puts "  These should be moved to either docs/bindings/core/ or docs/bindings/categories/<category>/:"
    root_files.each do |file|
      puts "    - #{file}"
    end
  end

  files
end

def process_bindings_files(files)
  puts "Validating bindings..."
  dir_base = 'bindings'
  files.each do |file|
    process_single_file(file, dir_base)
  end
end

def process_single_file(file, dir_base)
  content = File.read(file)
  format = detect_front_matter_format(content)

  # Extract front-matter - must use YAML format with triple dashes
  if format == :yaml
    yaml_content = content.match(/^---\n(.*?)\n---/m)[1]

    # Use enhanced YAML parsing with line tracking
    parse_result = YAMLLineTracker.parse(yaml_content)
    front_matter = parse_result[:data]
    line_map = parse_result[:line_map]

    # Handle any YAML parsing errors
    parse_result[:errors].each do |error|
      $error_collector.add_error(
        file: file,
        line: error[:line],
        field: nil,
        type: error[:type],
        message: error[:message],
        suggestion: error[:suggestion]
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    if front_matter.nil?
      $error_collector.add_error(
        file: file,
        line: nil,
        field: nil,
        type: 'empty_frontmatter',
        message: "Empty YAML in front-matter",
        suggestion: "Front-matter must include required fields. See TENET_FORMATTING.md for details."
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
      return  # Skip further validation if front_matter is nil
    end

    # Check required keys
    missing_keys = REQUIRED_KEYS[dir_base] - front_matter.keys
    unless missing_keys.empty?
      $error_collector.add_error(
        file: file,
        line: nil,
        field: nil,
        type: 'missing_required_fields',
        message: "Missing required keys in YAML front-matter: #{missing_keys.join(', ')}",
        suggestion: "#{dir_base.capitalize} must include: #{REQUIRED_KEYS[dir_base].join(', ')}. See TENET_FORMATTING.md for the standard format."
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    # Check for unique ID
    id = front_matter['id']
    if $all_ids[id]
      $error_collector.add_error(
        file: file,
        line: line_map['id'],
        field: 'id',
        type: 'duplicate_id',
        message: "Duplicate ID '#{id}' in YAML front-matter (already used in #{$all_ids[id]})",
        suggestion: "Each document must have a unique ID. Choose a different ID value."
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    # Validate ID format
    unless VALIDATORS['id'].call(id)
      $error_collector.add_error(
        file: file,
        line: line_map['id'],
        field: 'id',
        type: 'invalid_id_format',
        message: "Invalid ID format '#{id}' in YAML front-matter",
        suggestion: "ID must contain only lowercase letters, numbers, and hyphens (e.g., 'example-id')."
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end
    $all_ids[id] = file

    # Validate date format and value
    date = front_matter['last_modified']
    unless VALIDATORS['last_modified'].call(date)
      suggestion = if date.is_a?(Date)
        "Date must be quoted. Change to: last_modified: '#{date.strftime('%Y-%m-%d')}'"
      else
        "Date must be in ISO format (YYYY-MM-DD) and enclosed in quotes. Example: last_modified: '2025-05-09'"
      end

      $error_collector.add_error(
        file: file,
        line: line_map['last_modified'],
        field: 'last_modified',
        type: 'invalid_date_format',
        message: "Invalid date format in 'last_modified' field",
        suggestion: suggestion
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    # Validate version field matches VERSION file
    version = front_matter['version']
    expected_version = get_expected_version
    unless VALIDATORS['version'].call(version)
      if version.nil? || version.empty?
        $error_collector.add_error(
          file: file,
          line: line_map['version'],
          field: 'version',
          type: 'missing_version',
          message: "Missing 'version' field in YAML front-matter",
          suggestion: "The 'version' field is required and must match the VERSION file. Expected: version: '#{expected_version}'"
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      elsif version != expected_version
        $error_collector.add_error(
          file: file,
          line: line_map['version'],
          field: 'version',
          type: 'version_mismatch',
          message: "Version mismatch in YAML front-matter",
          suggestion: "Document version '#{version}' does not match VERSION file '#{expected_version}'. Expected: version: '#{expected_version}'"
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      else
        $error_collector.add_error(
          file: file,
          line: line_map['version'],
          field: 'version',
          type: 'invalid_version_format',
          message: "Invalid version format in YAML front-matter",
          suggestion: "Version must be in semantic version format (e.g., '#{expected_version}')."
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end
    end

    # For bindings, validate derived_from and enforced_by fields
    if dir_base == 'bindings'
      # Validate derived_from exists and has correct format
      derived_from = front_matter['derived_from']
      unless VALIDATORS['derived_from'].call(derived_from)
        $error_collector.add_error(
          file: file,
          line: line_map['derived_from'],
          field: 'derived_from',
          type: 'invalid_derived_from_format',
          message: "Invalid format for 'derived_from' in YAML front-matter",
          suggestion: "The 'derived_from' field must be a string containing only lowercase letters, numbers, and hyphens."
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end

      # Check that derived_from references an existing tenet
      tenet_file = Dir.glob("docs/tenets/#{derived_from}.md").first
      unless tenet_file
        $error_collector.add_error(
          file: file,
          line: line_map['derived_from'],
          field: 'derived_from',
          type: 'nonexistent_tenet_reference',
          message: "References non-existent tenet '#{derived_from}'",
          suggestion: "The 'derived_from' field must reference an existing tenet ID. Check docs/tenets/ for available tenets."
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end

      # Validate enforced_by field
      enforced_by = front_matter['enforced_by']
      unless VALIDATORS['enforced_by'].call(enforced_by)
        $error_collector.add_error(
          file: file,
          line: line_map['enforced_by'],
          field: 'enforced_by',
          type: 'invalid_enforced_by_format',
          message: "Invalid format for 'enforced_by' in YAML front-matter",
          suggestion: "The 'enforced_by' field must be a non-empty string."
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end
    end

    # Validate optional keys if present
    if dir_base == 'bindings' && OPTIONAL_KEYS['bindings'] && !OPTIONAL_KEYS['bindings'].empty?
      OPTIONAL_KEYS['bindings'].each do |key, validator|
        if front_matter.key?(key)
          unless validator.call(front_matter[key])
            $error_collector.add_error(
              file: file,
              line: line_map[key],
              field: key,
              type: 'invalid_optional_field_format',
              message: "Invalid format for '#{key}' in YAML front-matter",
              suggestion: "Invalid value format."
            )
            $files_with_issues << file unless $files_with_issues.include?(file)
          end
        end
      end
    end

    # Check for unknown keys not in required or optional lists
    allowed_keys = REQUIRED_KEYS[dir_base].dup
    if OPTIONAL_KEYS[dir_base] && !OPTIONAL_KEYS[dir_base].empty?
      allowed_keys.concat(OPTIONAL_KEYS[dir_base].keys)
    end

    unknown_keys = front_matter.keys - allowed_keys
    unless unknown_keys.empty?
      $error_collector.add_error(
        file: file,
        line: nil,
        field: nil,
        type: 'unknown_fields',
        message: "Unknown key(s) in YAML front-matter: #{unknown_keys.join(', ')}",
        suggestion: "Only these keys are allowed: #{allowed_keys.join(', ')}. Remove unknown keys or check TENET_FORMATTING.md for valid fields."
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    puts "  [OK] #{file}" if $verbose
  else
    $error_collector.add_error(
      file: file,
      line: nil,
      field: nil,
      type: 'no_frontmatter',
      message: "No front-matter found",
      suggestion: "All #{dir_base} files must begin with YAML front-matter between triple dashes. See TENET_FORMATTING.md for the standard format. Example:\n  ---\n  id: example-id\n  last_modified: '2025-05-09'\n  ---"
    )
    $files_with_issues << file unless $files_with_issues.include?(file)
  end
end

# Run the validation process
if $single_file
  # If a specific file is specified, just validate that one
  puts "Validating single file: #{$single_file}"

  # Determine if it's a tenet or binding based on path
  if $single_file.include?('/tenets/')
    dir_base = 'tenets'
  elsif $single_file.include?('/bindings/')
    dir_base = 'bindings'
  else
    $error_collector.add_error(
      file: $single_file,
      line: nil,
      field: nil,
      type: 'invalid_file_path',
      message: "Unable to determine file type from path",
      suggestion: "Path must include /tenets/ or /bindings/ to identify the file type."
    )
    $files_with_issues << $single_file unless $files_with_issues.include?($single_file)
  end

  process_single_file($single_file, dir_base)
else
  # Process all files
  process_tenets_files

  # Get binding files from the new directory structure
  binding_files = get_binding_files

  # Process the binding files
  process_bindings_files(binding_files)

  # Report warnings that were found (but didn't cause failures)
  if $warnings_found.any?
    puts "\n#{$warnings_found.size} warning(s) found:"
    $warnings_found.each do |warning|
      puts "  - #{warning}"
    end
  end
end

# Summarize results
if $error_collector.any?
  # Output collected errors (enhanced format will be added later)
  puts "\nValidation errors found:"
  $error_collector.errors.each do |error|
    puts "  [ERROR] #{error[:file]}: #{error[:message]}"
    if error[:line]
      puts "    Line #{error[:line]}" + (error[:field] ? " (field: #{error[:field]})" : "")
    end
    puts "    Suggestion: #{error[:suggestion]}" if error[:suggestion]
    puts
  end

  puts "Metadata validation failed!"
  exit 1
else
  puts "All files validated successfully!"

  # Display warnings summary if we have warnings but no errors
  if !$single_file && $warnings_found.any?
    puts "\nNote: #{$warnings_found.size} warning(s) were found, but all files passed validation."
    puts "See warnings above for details on recommended changes."
  end
end
