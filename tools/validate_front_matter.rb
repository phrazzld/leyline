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
    begin
      # Use safe_load with permitted classes for security
      front_matter = YAML.safe_load(yaml_content, permitted_classes: [Date, Time])
    rescue => e
      print_error(file, "Invalid YAML in front-matter: #{e.message}",
        "Front-matter must use valid YAML syntax. See TENET_FORMATTING.md for the standard format.\n  YAML content: #{yaml_content.inspect}")
    end

    if front_matter.nil?
      print_error(file, "Empty YAML in front-matter",
        "Front-matter must include required fields. See TENET_FORMATTING.md for details.")
    end

    # Check required keys
    missing_keys = REQUIRED_KEYS[dir_base] - front_matter.keys
    unless missing_keys.empty?
      print_error(file, "Missing required keys in YAML front-matter: #{missing_keys.join(', ')}",
        "#{dir_base.capitalize} must include: #{REQUIRED_KEYS[dir_base].join(', ')}\n  See TENET_FORMATTING.md for the standard format.")
    end

    # Check for unique ID
    id = front_matter['id']
    if $all_ids[id]
      print_error(file, "Duplicate ID '#{id}' in YAML front-matter (already used in #{$all_ids[id]})",
        "Each document must have a unique ID.")
    end

    # Validate ID format
    unless VALIDATORS['id'].call(id)
      print_error(file, "Invalid ID format '#{id}' in YAML front-matter",
        "ID must contain only lowercase letters, numbers, and hyphens (e.g., 'example-id').")
    end
    $all_ids[id] = file

    # Validate date format and value
    date = front_matter['last_modified']
    unless VALIDATORS['last_modified'].call(date)
      print_error(file, "Invalid date format in 'last_modified' field",
        "Date must be in ISO format (YYYY-MM-DD) and enclosed in quotes.\n  Example: last_modified: '2025-05-09'")
    end

    # Validate version field matches VERSION file
    version = front_matter['version']
    expected_version = get_expected_version
    unless VALIDATORS['version'].call(version)
      if version.nil? || version.empty?
        print_error(file, "Missing 'version' field in YAML front-matter",
          "The 'version' field is required and must match the VERSION file.\n  Expected: version: '#{expected_version}'")
      elsif version != expected_version
        print_error(file, "Version mismatch in YAML front-matter",
          "Document version '#{version}' does not match VERSION file '#{expected_version}'.\n  Expected: version: '#{expected_version}'")
      else
        print_error(file, "Invalid version format in YAML front-matter",
          "Version must be in semantic version format (e.g., '#{expected_version}').")
      end
    end

    # For bindings, validate derived_from and enforced_by fields
    if dir_base == 'bindings'
      # Validate derived_from exists and has correct format
      derived_from = front_matter['derived_from']
      unless VALIDATORS['derived_from'].call(derived_from)
        print_error(file, "Invalid format for 'derived_from' in YAML front-matter",
          "The 'derived_from' field must be a string containing only lowercase letters, numbers, and hyphens.")
      end

      # Check that derived_from references an existing tenet
      tenet_file = Dir.glob("docs/tenets/#{derived_from}.md").first
      unless tenet_file
        print_error(file, "References non-existent tenet '#{derived_from}'",
          "The 'derived_from' field must reference an existing tenet ID.")
      end

      # Validate enforced_by field
      enforced_by = front_matter['enforced_by']
      unless VALIDATORS['enforced_by'].call(enforced_by)
        print_error(file, "Invalid format for 'enforced_by' in YAML front-matter",
          "The 'enforced_by' field must be a non-empty string.")
      end
    end

    # Validate optional keys if present
    if dir_base == 'bindings' && OPTIONAL_KEYS['bindings'] && !OPTIONAL_KEYS['bindings'].empty?
      OPTIONAL_KEYS['bindings'].each do |key, validator|
        if front_matter.key?(key)
          unless validator.call(front_matter[key])
            details = "Invalid value format."
            print_error(file, "Invalid format for '#{key}' in YAML front-matter", details)
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
      print_error(file, "Unknown key(s) in YAML front-matter: #{unknown_keys.join(', ')}",
        "Only these keys are allowed: #{allowed_keys.join(', ')}\n  Remove unknown keys or check TENET_FORMATTING.md for valid fields.")
    end

    puts "  [OK] #{file}"
  else
    print_error(file, "No front-matter found",
      "All #{dir_base} files must begin with YAML front-matter between triple dashes.\n  See TENET_FORMATTING.md for the standard format.\n  Example:\n  ---\n  id: example-id\n  last_modified: '2025-05-09'\n  ---")
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
    print_error($single_file, "Unable to determine file type from path",
      "Path must include /tenets/ or /bindings/ to identify the file type.")
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
if $files_with_issues.empty?
  puts "All files validated successfully!"

  # Display warnings summary if we have warnings but no errors
  if !$single_file && $warnings_found.any?
    puts "\nNote: #{$warnings_found.size} warning(s) were found, but all files passed validation."
    puts "See warnings above for details on recommended changes."
  end
else
  issues_count = $files_with_issues.length

  puts "\n#{issues_count} file(s) have validation issues:"
  $files_with_issues.each do |file|
    puts "  - #{file}"
  end

  puts "\nMetadata validation failed!"
  exit 1
end
