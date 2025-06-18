#!/usr/bin/env ruby
# tools/validate_cross_references.rb - Validate cross-references in documentation files
#
# This script validates that all cross-references in markdown files point to existing files.
# It checks:
# 1. All markdown links point to existing files
# 2. Tenet references are valid (point to existing tenet files)
# 3. Inter-binding links are valid (point to existing binding files)
# 4. No broken relative or absolute paths

require 'fileutils'
require 'json'
require 'pathname'
require 'time'

# Configuration for structured logging
$structured_logging = ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
$correlation_id = "validation-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{rand(1000)}"
$errors = []

def log_structured(event, data = {})
  return unless $structured_logging

  begin
    log_entry = {
      event: event,
      correlation_id: $correlation_id,
      timestamp: Time.now.iso8601,
      **data
    }

    STDERR.puts JSON.generate(log_entry)
  rescue => e
    # Graceful degradation if structured logging fails
    STDERR.puts "Warning: Structured logging failed: #{e.message}"
  end
end

def add_error(file, link, issue, suggestion = nil)
  error = {
    file: file,
    link: link,
    issue: issue,
    suggestion: suggestion
  }

  $errors << error

  log_structured('cross_reference_error', error) if $structured_logging
end

# Find all markdown files to validate
def find_markdown_files
  markdown_files = Dir.glob("**/*.md").reject do |file|
    file.start_with?("venv/") ||
    file.start_with?("node_modules/") ||
    file.start_with?("site/") ||
    file.end_with?("glance.md") ||  # Skip overview files
    file.end_with?("00-index.md")  # Skip index files
  end

  log_structured('validation_scope', {
    total_files: markdown_files.size,
    excluded_patterns: ['venv/', 'node_modules/', 'site/', 'glance.md', '00-index.md']
  })

  markdown_files
end

# Extract all markdown links from file content
def extract_links(content)
  # Match [text](link) patterns
  content.scan(/\[([^\]]*)\]\(([^)]+)\)/).map { |text, link|
    { text: text, link: link }
  }
end

# Check if a file exists relative to a base file
def file_exists?(base_file, link)
  # Remove anchor fragments (#section)
  clean_link = link.split('#').first
  return false if clean_link.nil? || clean_link.empty?

  # Skip external URLs
  return true if clean_link.match?(/^https?:\/\//)

  # Calculate absolute path
  if clean_link.start_with?('/')
    # Absolute path from repo root
    abs_path = clean_link[1..-1]  # Remove leading slash
  else
    # Relative path from current file
    base_dir = File.dirname(base_file)
    abs_path = File.expand_path(clean_link, base_dir)
    # Convert back to relative from current working directory
    abs_path = Pathname.new(abs_path).relative_path_from(Pathname.new(Dir.pwd)).to_s
  end

  # Check if file exists
  File.exist?(abs_path)
end

# Validate all cross-references in a file
def validate_file_references(file)
  content = File.read(file)
  links = extract_links(content)
  file_errors = 0

  links.each do |link_info|
    link = link_info[:link]
    text = link_info[:text]

    # Skip external URLs and mailto links
    next if link.match?(/^(https?:\/\/|mailto:)/)

    unless file_exists?(file, link)
      suggestion = case link
      when /\.md$/
        if link.include?('/tenets/')
          "Check if the tenet file exists in docs/tenets/ directory"
        elsif link.include?('/bindings/')
          "Check if the binding file exists in docs/bindings/core/ or docs/bindings/categories/ directories"
        else
          "Verify the file path and ensure the referenced file exists"
        end
      else
        "Link appears to reference a non-markdown file or directory"
      end

      add_error(file, link, "Broken link - target file does not exist", suggestion)
      file_errors += 1
    end
  end

  log_structured('file_validated', {
    file: file,
    total_links: links.size,
    errors: file_errors,
    external_links: links.count { |l| l[:link].match?(/^https?:\/\//) }
  }) if $structured_logging

  file_errors
end

# Main validation process
def validate_cross_references
  log_structured('validation_start', {
    tool: 'validate_cross_references',
    mode: 'cross_reference_integrity'
  })

  start_time = Time.now
  markdown_files = find_markdown_files
  total_errors = 0

  puts "Validating cross-references in #{markdown_files.size} markdown files..."

  markdown_files.each do |file|
    file_errors = validate_file_references(file)
    total_errors += file_errors

    if file_errors > 0
      puts "  [ERROR] #{file}: #{file_errors} broken link(s)"
    end
  end

  duration = (Time.now - start_time).round(3)

  log_structured('validation_summary', {
    duration_seconds: duration,
    files_validated: markdown_files.size,
    total_errors: total_errors,
    files_with_errors: $errors.map { |e| e[:file] }.uniq.size
  })

  if total_errors == 0
    puts "✅ All cross-references validated successfully!"
    puts "Checked #{markdown_files.size} files in #{duration}s"
  else
    puts "\n❌ Cross-reference validation failed!"
    puts "Found #{total_errors} broken links in #{$errors.map { |e| e[:file] }.uniq.size} files:"

    # Group errors by file for better readability
    errors_by_file = $errors.group_by { |e| e[:file] }
    errors_by_file.each do |file, file_errors|
      puts "\n#{file}:"
      file_errors.each do |error|
        puts "  • #{error[:link]} - #{error[:issue]}"
        puts "    Suggestion: #{error[:suggestion]}" if error[:suggestion]
      end
    end

    exit 1
  end
end

# Command line option parsing
require 'optparse'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: validate_cross_references.rb [options]"
  opts.separator ""
  opts.separator "This script validates that all cross-references in markdown files point to existing files."
  opts.separator ""
  opts.separator "Options:"

  opts.on("-v", "--verbose", "Show detailed validation progress") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end

  opts.separator ""
  opts.separator "Environment Variables:"
  opts.separator "  LEYLINE_STRUCTURED_LOGGING=true  Enable JSON structured logging to STDERR"
  opts.separator ""
  opts.separator "Exit Codes:"
  opts.separator "  0 - All cross-references are valid"
  opts.separator "  1 - Broken cross-references found"
end

parser.parse!

# Run the validation
validate_cross_references
