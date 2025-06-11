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
require_relative '../lib/error_formatter'

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

  opts.on("-g", "--granular-exit-codes", "Use granular exit codes (2=syntax, 3=field errors) instead of 1 for all errors") do
    options[:granular_exit_codes] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end

  opts.separator ""
  opts.separator "Exit Codes:"
  opts.separator "  0 - All files validated successfully"
  opts.separator "  1 - Validation errors found (default mode)"
  opts.separator "  2 - YAML syntax errors found (granular mode only)"
  opts.separator "  3 - Field validation errors found (granular mode only)"
  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  ruby tools/validate_front_matter.rb             # Validate all files"
  opts.separator "  ruby tools/validate_front_matter.rb -f path.md  # Validate single file"
  opts.separator "  ruby tools/validate_front_matter.rb -g          # Use granular exit codes"
end

parser.parse!

# Track validation state
$all_ids = {}            # Track all ids to ensure uniqueness
$files_with_issues = []  # Track files with issues
$warnings_found = []     # Track warnings (non-fatal issues)
$single_file = options[:file]
$verbose = options[:verbose]
$granular_exit_codes = options[:granular_exit_codes]
$error_collector = ErrorCollector.new  # Enhanced error collection
$file_contents = {}      # Store file contents for context snippets

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

# Determine exit code based on error types (when granular exit codes are enabled)
def determine_exit_code(errors)
  return 1 unless $granular_exit_codes

  # Categorize error types
  syntax_error_types = %w[yaml_syntax empty_frontmatter no_frontmatter]

  has_syntax_errors = errors.any? { |error| syntax_error_types.include?(error[:type]) }
  has_field_errors = errors.any? { |error| !syntax_error_types.include?(error[:type]) }

  # Priority: syntax errors take precedence over field errors
  if has_syntax_errors
    2  # Syntax errors
  elsif has_field_errors
    3  # Field errors
  else
    1  # Fallback for any other errors
  end
end

# Validate file path for security and existence
def validate_file_path(file_path)
  # Convert to absolute path for consistent checking
  begin
    absolute_path = File.expand_path(file_path)
  rescue ArgumentError => e
    puts "ERROR: Invalid file path '#{file_path}': #{e.message}"
    exit 1
  end

  # Check for directory traversal sequences in the original path
  if file_path.include?('..')
    puts "ERROR: Directory traversal detected in path '#{file_path}'"
    puts "Paths containing '..' are not allowed for security reasons."
    exit 1
  end

  # Check if path exists
  unless File.exist?(absolute_path)
    puts "ERROR: File does not exist: #{file_path}"
    exit 1
  end

  # Check for symlinks first (before File.file? check since it returns true for symlinks to files)
  if File.symlink?(absolute_path)
    puts "ERROR: Symbolic links are not allowed: #{file_path}"
    exit 1
  end

  # Check if it's a regular file (not directory, device, etc.)
  unless File.file?(absolute_path)
    if File.directory?(absolute_path)
      puts "ERROR: Path is a directory, not a file: #{file_path}"
    else
      puts "ERROR: Path is not a regular file: #{file_path}"
    end
    exit 1
  end

  # Check if file is readable
  unless File.readable?(absolute_path)
    puts "ERROR: File is not readable: #{file_path}"
    exit 1
  end

  # Return the validated absolute path
  absolute_path
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
  # Store content for ErrorFormatter context snippets
  $file_contents[file] = content
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
      # Generate specific suggestions for each missing field
      examples = missing_keys.map do |key|
        case key
        when 'id'
          "id: #{File.basename(file, '.md').gsub('_', '-')}"
        when 'last_modified'
          "last_modified: '#{Date.today.strftime('%Y-%m-%d')}'"
        when 'version'
          "version: '#{get_expected_version}'"
        when 'derived_from'
          "derived_from: parent-tenet-id"
        when 'enforced_by'
          "enforced_by: 'Linter, Code Review'"
        else
          "#{key}: [value]"
        end
      end

      suggestion = "Add missing field(s) to your front-matter:\n#{examples.map { |ex| "  #{ex}" }.join("\n")}"

      $error_collector.add_error(
        file: file,
        line: nil,
        field: nil,
        type: 'missing_required_fields',
        message: "Missing required keys in YAML front-matter: #{missing_keys.join(', ')}",
        suggestion: suggestion
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    # Check for unique ID
    id = front_matter['id']
    if $all_ids[id]
      # Generate specific alternative suggestions
      base_filename = File.basename(file, '.md').gsub('_', '-')
      alternatives = [
        "#{base_filename}",
        "#{id}-v2",
        "#{id}-#{dir_base.gsub('s', '')}",
        "#{base_filename}-#{Dir.glob("#{File.dirname(file)}/*.md").length}"
      ].uniq.reject { |alt| alt == id }

      suggestion = "ID '#{id}' is already used in #{$all_ids[id]}. Try one of these alternatives:\n" +
                   alternatives.first(3).map { |alt| "  id: #{alt}" }.join("\n")

      $error_collector.add_error(
        file: file,
        line: line_map['id'],
        field: 'id',
        type: 'duplicate_id',
        message: "Duplicate ID '#{id}' in YAML front-matter (already used in #{$all_ids[id]})",
        suggestion: suggestion
      )
      $files_with_issues << file unless $files_with_issues.include?(file)
    end

    # Validate ID format
    unless VALIDATORS['id'].call(id)
      # Generate specific fix based on the invalid ID
      fixed_id = id.to_s.downcase.gsub(/[^a-z0-9-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
      fixed_id = 'invalid-id' if fixed_id.empty?

      suggestion = if id.to_s.match?(/[A-Z]/)
        "ID contains uppercase letters. Use lowercase: id: #{fixed_id}"
      elsif id.to_s.match?(/[^a-z0-9-]/)
        "ID contains invalid characters. Use only lowercase letters, numbers, and hyphens: id: #{fixed_id}"
      elsif id.to_s.match?(/^-|-$/)
        "ID cannot start or end with hyphens: id: #{fixed_id}"
      else
        "ID must contain only lowercase letters, numbers, and hyphens: id: #{fixed_id}"
      end

      $error_collector.add_error(
        file: file,
        line: line_map['id'],
        field: 'id',
        type: 'invalid_id_format',
        message: "Invalid ID format '#{id}' in YAML front-matter",
        suggestion: suggestion
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
      if version.nil? || (version.is_a?(String) && version.empty?)
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
        # Generate specific fix suggestion based on the type of error
        suggestion = if derived_from.nil?
          "The 'derived_from' field is required for bindings. Example: derived_from: 'simplicity'"
        elsif !derived_from.is_a?(String)
          "The 'derived_from' field must be a string. Change to: derived_from: '#{derived_from}'"
        elsif derived_from.match?(/[A-Z]/)
          fixed_id = derived_from.downcase.gsub(/[^a-z0-9-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
          "The 'derived_from' field contains uppercase letters. Use: derived_from: '#{fixed_id}'"
        elsif derived_from.match?(/[^a-z0-9-]/)
          fixed_id = derived_from.downcase.gsub(/[^a-z0-9-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
          "The 'derived_from' field contains invalid characters. Use: derived_from: '#{fixed_id}'"
        else
          "The 'derived_from' field must contain only lowercase letters, numbers, and hyphens. Example: derived_from: 'simplicity'"
        end

        $error_collector.add_error(
          file: file,
          line: line_map['derived_from'],
          field: 'derived_from',
          type: 'invalid_derived_from_format',
          message: "Invalid format for 'derived_from' in YAML front-matter",
          suggestion: suggestion
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end

      # Check that derived_from references an existing tenet (only if not nil)
      if derived_from && !derived_from.empty?
        tenet_file = Dir.glob("docs/tenets/#{derived_from}.md").first
        unless tenet_file
        # Get available tenets to suggest alternatives
        available_tenets = Dir.glob("docs/tenets/*.md")
          .reject { |f| f =~ /00-index\.md$/ }
          .map { |f| File.basename(f, '.md') }
          .sort

        # Find close matches using simple string similarity
        close_matches = available_tenets.select { |tenet|
          tenet.include?(derived_from) || derived_from.include?(tenet) ||
          (tenet.length > 3 && derived_from.length > 3 &&
           (tenet[0..2] == derived_from[0..2] || tenet[-3..-1] == derived_from[-3..-1]))
        }.first(3)

        suggestion = if close_matches.any?
          "Tenet '#{derived_from}' does not exist. Did you mean one of these?\n" +
          close_matches.map { |t| "  derived_from: '#{t}'" }.join("\n") +
          "\n\nAvailable tenets: #{available_tenets.first(5).join(', ')}" +
          (available_tenets.length > 5 ? ", and #{available_tenets.length - 5} more" : "")
        else
          "Tenet '#{derived_from}' does not exist. Available tenets:\n" +
          available_tenets.first(10).map { |t| "  #{t}" }.join("\n") +
          (available_tenets.length > 10 ? "\n  ... and #{available_tenets.length - 10} more" : "")
        end

          $error_collector.add_error(
            file: file,
            line: line_map['derived_from'],
            field: 'derived_from',
            type: 'nonexistent_tenet_reference',
            message: "References non-existent tenet '#{derived_from}'",
            suggestion: suggestion
          )
          $files_with_issues << file unless $files_with_issues.include?(file)
        end
      end

      # Validate enforced_by field
      enforced_by = front_matter['enforced_by']
      unless VALIDATORS['enforced_by'].call(enforced_by)
        # Generate specific suggestions based on the error type
        suggestion = if enforced_by.nil?
          "The 'enforced_by' field is required for bindings. Examples:\n" +
          "  enforced_by: 'Linter, Code Review'\n" +
          "  enforced_by: 'CI Pipeline, Static Analysis'\n" +
          "  enforced_by: 'Manual Review'"
        elsif !enforced_by.is_a?(String)
          "The 'enforced_by' field must be a string. Change to: enforced_by: '#{enforced_by}'"
        elsif enforced_by.empty?
          "The 'enforced_by' field cannot be empty. Examples:\n" +
          "  enforced_by: 'Linter, Code Review'\n" +
          "  enforced_by: 'CI Pipeline, Static Analysis'\n" +
          "  enforced_by: 'Manual Review'"
        else
          "The 'enforced_by' field must be a non-empty string describing how this binding is enforced."
        end

        $error_collector.add_error(
          file: file,
          line: line_map['enforced_by'],
          field: 'enforced_by',
          type: 'invalid_enforced_by_format',
          message: "Invalid format for 'enforced_by' in YAML front-matter",
          suggestion: suggestion
        )
        $files_with_issues << file unless $files_with_issues.include?(file)
      end
    end

    # Validate optional keys if present
    if dir_base == 'bindings' && OPTIONAL_KEYS['bindings'] && !OPTIONAL_KEYS['bindings'].empty?
      OPTIONAL_KEYS['bindings'].each do |key, validator|
        if front_matter.key?(key)
          unless validator.call(front_matter[key])
            # Generate specific suggestions for optional field validation errors
            suggestion = case key
            when 'category'
              "The 'category' field should be a string. Example: category: 'frontend'"
            when 'priority'
              "The 'priority' field should be a string like 'high', 'medium', or 'low'."
            when 'tags'
              "The 'tags' field should be an array of strings. Example: tags: ['security', 'performance']"
            else
              "The '#{key}' field has an invalid format. Check the documentation for the expected format."
            end

            $error_collector.add_error(
              file: file,
              line: line_map[key],
              field: key,
              type: 'invalid_optional_field_format',
              message: "Invalid format for '#{key}' in YAML front-matter",
              suggestion: suggestion
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
      # Generate specific suggestions for unknown fields
      suggestions_for_keys = unknown_keys.map do |key|
        # Check if it's a common typo or similar to a valid key
        close_match = allowed_keys.find { |valid_key|
          # Check for common typos or similar names
          valid_key.include?(key) || key.include?(valid_key) ||
          (key.length > 2 && valid_key.length > 2 &&
           (key[0..1] == valid_key[0..1] || key[-2..-1] == valid_key[-2..-1]))
        }

        if close_match
          "  '#{key}' -> did you mean '#{close_match}'?"
        else
          "  '#{key}' -> not a valid field, remove it"
        end
      end

      suggestion = "Remove or fix unknown field(s):\n#{suggestions_for_keys.join("\n")}\n\n" +
                   "Valid #{dir_base} fields: #{allowed_keys.join(', ')}"

      $error_collector.add_error(
        file: file,
        line: nil,
        field: nil,
        type: 'unknown_fields',
        message: "Unknown key(s) in YAML front-matter: #{unknown_keys.join(', ')}",
        suggestion: suggestion
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

  # Validate file path for security first
  validated_file = validate_file_path($single_file)

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
  # Use ErrorFormatter for enhanced error output
  formatter = ErrorFormatter.new
  formatted_output = formatter.render($error_collector.errors, $file_contents)

  # Output to STDERR for proper error stream handling
  $stderr.puts formatted_output
  $stderr.puts
  $stderr.puts "Metadata validation failed!"

  # Use granular exit codes if enabled, otherwise default to 1
  exit_code = determine_exit_code($error_collector.errors)
  exit exit_code
else
  puts "All files validated successfully!"

  # Display warnings summary if we have warnings but no errors
  if !$single_file && $warnings_found.any?
    puts "\nNote: #{$warnings_found.size} warning(s) were found, but all files passed validation."
    puts "See warnings above for details on recommended changes."
  end
end
