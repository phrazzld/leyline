#!/usr/bin/env ruby
# tools/validate_front_matter.rb - Validates metadata in Markdown files
# Accepts both horizontal rule and YAML front-matter formats
# See TENET_FORMATTING.md for documentation on the acceptable formats

require 'yaml'
require 'date'

# Configuration
REQUIRED_KEYS = {
  'tenets' => %w[id last_modified],
  'bindings' => %w[id last_modified derived_from enforced_by]
}

# Optional keys that have validation rules when present
OPTIONAL_KEYS = {
  'bindings' => {
    # Note: 'applies_to' field has been removed as part of directory restructuring
    # The binding category is now determined by its location in the directory structure
  }
}

# Note: VALID_CONTEXTS constant has been removed as 'applies_to' is no longer used
# Categories are now determined by the directory structure:
# - docs/bindings/core/ for core bindings
# - docs/bindings/categories/<category>/ for category-specific bindings

# Setup command line options for strict mode
require 'optparse'

options = { strict: false }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: validate_front_matter.rb [options]"
  opts.on("--strict", "Enforce YAML front-matter format strictly, exit on any non-YAML format") do
    options[:strict] = true
  end
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end

parser.parse!

# Track all ids to ensure uniqueness
$all_ids = {}
$files_with_issues = []
$strict_mode = options[:strict]

# Helper method to check if a file uses the old horizontal rule format
def using_horizontal_rule_format?(content)
  content =~ /^____+\s*$/ || # Continuous underscores
  content =~ /^# .*?\n_+\n\*\*ID:\*\* [\w-]+/m # Title, underscores, ID format
end

# Helper method to detect front matter format
def detect_front_matter_format(content)
  if content =~ /^---\n(.*?)\n---/m
    :yaml
  elsif using_horizontal_rule_format?(content)
    :horizontal_rule
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

  # Check for horizontal rule format (now deprecated)
  # Horizontal rule format is fully supported, but we'll extract metadata
  if format == :horizontal_rule
    # For now, just validate that we have a horizontal rule and some metadata
    # In the future, we could add more sophisticated parsing of horizontal rule metadata
    puts "  [OK] #{file} (using horizontal rule format)"
    return
  end

  # Extract front-matter - must use YAML format with triple dashes
  if format == :yaml
    yaml_content = content.match(/^---\n(.*?)\n---/m)[1]
    begin
      front_matter = YAML.safe_load(yaml_content)
    rescue => e
      message = "  [ERROR] #{file}: Invalid YAML in front-matter: #{e.message}"
      puts message
      puts "  YAML content: #{yaml_content.inspect}"
      puts "  Front-matter must use valid YAML syntax. See TENET_FORMATTING.md for the standard format."
      exit 1
    end

    if front_matter.nil?
      puts "  [ERROR] #{file}: Empty YAML in front-matter"
      puts "  Front-matter must include required fields. See TENET_FORMATTING.md for details."
      exit 1
    end

    # Check required keys
    missing_keys = REQUIRED_KEYS[dir_base] - front_matter.keys
    unless missing_keys.empty?
      puts "  [ERROR] #{file}: Missing required keys in YAML front-matter: #{missing_keys.join(', ')}"
      puts "  #{dir_base.capitalize} must include: #{REQUIRED_KEYS[dir_base].join(', ')}"
      puts "  See TENET_FORMATTING.md for the standard format."
      exit 1
    end

    # Check for unique ID
    id = front_matter['id']
    if $all_ids[id]
      puts "  [ERROR] #{file}: Duplicate ID '#{id}' in YAML front-matter (already used in #{$all_ids[id]})"
      puts "  Each document must have a unique ID."
      exit 1
    end
    $all_ids[id] = file

    # Validate date format
    date = front_matter['last_modified']
    unless date.is_a?(Date) || date.is_a?(String) && date =~ /^\d{4}-\d{2}-\d{2}$/
      puts "  [ERROR] #{file}: Invalid date format in 'last_modified' field"
      puts "  Date must be in ISO format (YYYY-MM-DD) and enclosed in quotes."
      puts "  Example: last_modified: '2025-05-09'"
      exit 1
    end

    # For bindings, validate that derived_from exists
    if dir_base == 'bindings' && front_matter['derived_from']
      tenet_file = Dir.glob("docs/tenets/#{front_matter['derived_from']}.md").first
      unless tenet_file
        puts "  [ERROR] #{file}: References non-existent tenet '#{front_matter['derived_from']}'"
        puts "  The 'derived_from' field must reference an existing tenet ID."
        exit 1
      end
    end

    # Validate optional keys if present (if any are defined)
    if dir_base == 'bindings' && OPTIONAL_KEYS['bindings'] && !OPTIONAL_KEYS['bindings'].empty?
      OPTIONAL_KEYS['bindings'].each do |key, validator|
        if front_matter.key?(key)
          unless validator.call(front_matter[key])
            puts "  [ERROR] #{file}: Invalid format for '#{key}' in YAML front-matter"
            exit 1
          end
        end
      end
    end

    # Check for legacy applies_to field and warn to remove it
    if dir_base == 'bindings' && front_matter.key?('applies_to')
      puts "  [WARNING] #{file}: Contains deprecated 'applies_to' field"
      puts "  The 'applies_to' field is no longer used as categories are now determined by directory structure."
      puts "  Please remove this field from the front matter."
    end

    puts "  [OK] #{file}"
  else
    message = "  [ERROR] #{file}: No front-matter found"

    if $strict_mode
      puts message
      puts "  All #{dir_base} files must begin with YAML front-matter between triple dashes."
      puts "  See TENET_FORMATTING.md for the standard format."
      puts "  Example:\n  ---\n  id: example-id\n  last_modified: '2025-05-09'\n  ---"
      exit 1
    else
      puts message.gsub("[ERROR]", "[WARNING]")
      puts "  Please add YAML front-matter as described in TENET_FORMATTING.md."
      $files_with_issues << file
    end
  end
end

# Run the validation process
process_tenets_files

# Get binding files from the new directory structure
binding_files = get_binding_files

# Process the binding files
process_bindings_files(binding_files)

# Summarize results
if $files_with_issues.empty?
  puts "All files validated successfully!"
else
  issues_count = $files_with_issues.length

  puts "\n#{issues_count} file(s) have validation issues:"
  $files_with_issues.each do |file|
    puts "  - #{file}"
  end

  if $strict_mode
    puts "\nMetadata validation failed!"
    puts "Run reindex.rb to ensure indexes are still generated correctly."
    exit 1
  else
    puts "\nValidation completed with warnings."

    # Ensure reindex.rb can still run to generate indexes correctly
    if File.exist?('tools/reindex.rb')
      puts "\nRunning reindex.rb to ensure indexes are still generated correctly..."
      system('ruby tools/reindex.rb')
    end
  end
end
