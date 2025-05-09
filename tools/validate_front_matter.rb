#!/usr/bin/env ruby
# tools/validate_front_matter.rb - Validates front-matter in Markdown files
# Enforces YAML front-matter as the standard format for all tenets and bindings
# See TENET_FORMATTING.md for documentation on the standard format

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
    'applies_to' => ->(value) { value.is_a?(Array) && value.all? { |v| v.is_a?(String) } }
  }
}

# Valid values for applies_to field
VALID_CONTEXTS = [
  # Languages
  'typescript', 'javascript', 'go', 'rust', 'python', 'java', 'csharp', 'ruby',
  # Environments
  'frontend', 'backend', 'mobile', 'desktop', 'cli', 'library', 'service',
  # Special values
  'all'
]

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
all_ids = {}
files_with_issues = []
strict_mode = options[:strict]

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

# Process directories
%w[docs/tenets docs/bindings].each do |dir|
  dir_base = dir.split('/').last
  puts "Validating #{dir_base}..."

  # Skip index files
  Dir.glob("#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
    content = File.read(file)
    format = detect_front_matter_format(content)

    # Check for horizontal rule format (now deprecated)
    if format == :horizontal_rule
      message = "  [WARNING] #{file}: Using deprecated horizontal rule format for metadata"

      if strict_mode
        puts message.gsub("[WARNING]", "[ERROR]")
        puts "  YAML front-matter is now required. See TENET_FORMATTING.md for the standard format."
        puts "  Example:\n---\nid: example-id\nlast_modified: '2025-05-09'\n---"
        exit 1
      else
        puts message
        puts "  Please convert to YAML front-matter format as described in TENET_FORMATTING.md."
        files_with_issues << file
        next
      end
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
      if all_ids[id]
        puts "  [ERROR] #{file}: Duplicate ID '#{id}' in YAML front-matter (already used in #{all_ids[id]})"
        puts "  Each document must have a unique ID."
        exit 1
      end
      all_ids[id] = file

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

      # Validate optional keys if present
      if dir_base == 'bindings' && OPTIONAL_KEYS['bindings']
        OPTIONAL_KEYS['bindings'].each do |key, validator|
          if front_matter.key?(key)
            unless validator.call(front_matter[key])
              puts "  [ERROR] #{file}: Invalid format for '#{key}' in YAML front-matter"
              puts "  For 'applies_to', value must be an array of strings."
              puts "  Example: applies_to: ['typescript', 'frontend']"
              exit 1
            end

            # Additional validation for applies_to values
            if key == 'applies_to'
              invalid_contexts = front_matter[key] - VALID_CONTEXTS
              unless invalid_contexts.empty?
                puts "  [WARNING] #{file}: Unknown context(s) in 'applies_to': #{invalid_contexts.join(', ')}"
                puts "  Valid contexts are: #{VALID_CONTEXTS.join(', ')}"
              end

              # Auto-detect language specific bindings without proper applies_to
              if file =~ /\/(ts|js|go|rust|py|java|cs|rb)-/ && !front_matter[key].any? { |v| v =~ /^(typescript|javascript|go|rust|python|java|csharp|ruby)$/ }
                prefix = $1
                language_map = {
                  'ts' => 'typescript', 'js' => 'javascript', 'go' => 'go',
                  'rust' => 'rust', 'py' => 'python', 'java' => 'java',
                  'cs' => 'csharp', 'rb' => 'ruby'
                }
                puts "  [WARNING] #{file}: Has prefix '#{prefix}-' but doesn't include '#{language_map[prefix]}' in applies_to"
              end
            end
          end
        end
      end

      puts "  [OK] #{file}"
    else
      message = "  [ERROR] #{file}: No front-matter found"

      if strict_mode
        puts message
        puts "  All #{dir_base} files must begin with YAML front-matter between triple dashes."
        puts "  See TENET_FORMATTING.md for the standard format."
        puts "  Example:\n  ---\n  id: example-id\n  last_modified: '2025-05-09'\n  ---"
        exit 1
      else
        puts message.gsub("[ERROR]", "[WARNING]")
        puts "  Please add YAML front-matter as described in TENET_FORMATTING.md."
        files_with_issues << file
      end
    end
  end
end

# Summarize results
if files_with_issues.empty?
  puts "All files validated successfully with standard YAML front-matter!"
else
  issues_count = files_with_issues.length

  puts "\n#{issues_count} file(s) need conversion to YAML front-matter format:"
  files_with_issues.each do |file|
    puts "  - #{file}"
  end

  if strict_mode
    puts "\nStandard YAML front-matter validation failed!"
    puts "Run reindex.rb to ensure indexes are still generated correctly."
    exit 1
  else
    puts "\nValidation completed with warnings."
    puts "Files with non-YAML format will need to be converted as part of tasks T078/T079."
    puts "Run this script with --strict option to enforce strict YAML front-matter validation."

    # Ensure reindex.rb can still run to generate indexes correctly
    if File.exist?('tools/reindex.rb')
      puts "\nRunning reindex.rb to ensure indexes are still generated correctly..."
      system('ruby tools/reindex.rb')
    end
  end
end
