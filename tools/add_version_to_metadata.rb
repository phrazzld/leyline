#!/usr/bin/env ruby
# add_version_to_metadata.rb - Add version field to YAML front-matter in markdown files
#
# This script adds the 'version' field to YAML front-matter in tenet and binding
# documents if it's missing. It reads the current version from the VERSION file
# and preserves all existing formatting and content.
#
# Usage:
#   ruby tools/add_version_to_metadata.rb [options]
#
# Options:
#   --dry-run              Show what would be changed without making changes
#   -f, --file FILE        Process a single file
#   -p, --path PATH        Process all .md files in a directory (recursive)
#   -v, --verbose          Show detailed processing information
#   -h, --help             Show this help message

require 'yaml'
require 'optparse'
require 'fileutils'

class VersionMigrator
  attr_reader :options, :current_version, :stats

  def initialize(options)
    @options = options
    @stats = {
      files_processed: 0,
      files_updated: 0,
      files_skipped: 0,
      errors: 0
    }
    @current_version = read_version_file
  end

  def run
    if options[:file]
      process_file(options[:file])
    elsif options[:path]
      process_directory(options[:path])
    else
      # Default to processing both tenets and bindings
      process_directory('docs/tenets')
      process_directory('docs/bindings')
    end

    print_summary
    exit(stats[:errors] > 0 ? 1 : 0)
  end

  private

  def read_version_file
    version_path = 'VERSION'
    unless File.exist?(version_path)
      puts "ERROR: VERSION file not found at #{version_path}"
      exit 1
    end

    version = File.read(version_path).strip
    puts "Using version: #{version}" if options[:verbose]
    version
  end

  def process_directory(path)
    unless Dir.exist?(path)
      puts "WARNING: Directory not found: #{path}"
      return
    end

    puts "\nProcessing directory: #{path}" if options[:verbose]

    Dir.glob(File.join(path, '**', '*.md')).sort.each do |file|
      # Skip index files
      next if File.basename(file).start_with?('00-')

      process_file(file)
    end
  end

  def process_file(file_path)
    unless File.exist?(file_path)
      puts "ERROR: File not found: #{file_path}"
      stats[:errors] += 1
      return
    end

    stats[:files_processed] += 1
    puts "\nProcessing: #{file_path}" if options[:verbose]

    begin
      content = File.read(file_path)

      # Check if file has YAML front-matter
      unless content.start_with?("---\n")
        puts '  SKIP: No YAML front-matter found' if options[:verbose]
        stats[:files_skipped] += 1
        return
      end

      # Extract YAML front-matter and rest of content
      parts = content.split(/^---\s*$/m, 3)
      if parts.length < 3
        puts '  ERROR: Invalid YAML front-matter format'
        stats[:errors] += 1
        return
      end

      yaml_content = parts[1]
      rest_content = '---' + parts[2]

      # Parse YAML to check for version field
      begin
        yaml_data = YAML.safe_load(yaml_content)
      rescue StandardError => e
        puts "  ERROR: Failed to parse YAML: #{e.message}"
        stats[:errors] += 1
        return
      end

      # Check if version field already exists
      if yaml_data && yaml_data['version']
        puts "  SKIP: Version field already exists (#{yaml_data['version']})" if options[:verbose]
        stats[:files_skipped] += 1
        return
      end

      # Add version field
      updated_yaml = add_version_to_yaml(yaml_content)

      if options[:dry_run]
        puts "  DRY RUN: Would add version: '#{current_version}'"
        show_diff(yaml_content, updated_yaml) if options[:verbose]
      else
        # Write updated content
        updated_content = "---\n#{updated_yaml}#{rest_content}"
        File.write(file_path, updated_content)
        puts "  UPDATED: Added version: '#{current_version}'"
      end

      stats[:files_updated] += 1
    rescue StandardError => e
      puts "  ERROR: #{e.message}"
      puts e.backtrace.join("\n") if options[:verbose]
      stats[:errors] += 1
    end
  end

  def add_version_to_yaml(yaml_content)
    lines = yaml_content.strip.split("\n")

    # Find the position to insert version field
    # We want to add it after 'last_modified' if it exists
    insert_index = lines.length

    lines.each_with_index do |line, index|
      if line.match(/^last_modified:/)
        insert_index = index + 1
        break
      end
    end

    # Insert the version field
    lines.insert(insert_index, "version: '#{current_version}'")

    lines.join("\n") + "\n"
  end

  def show_diff(original, updated)
    puts "\n  Original YAML:"
    puts '  ' + original.strip.split("\n").join("\n  ")
    puts "\n  Updated YAML:"
    puts '  ' + updated.strip.split("\n").join("\n  ")
  end

  def print_summary
    puts "\n#{'=' * 60}"
    puts "Migration Summary#{options[:dry_run] ? ' (DRY RUN)' : ''}"
    puts "#{'=' * 60}"
    puts "Files processed: #{stats[:files_processed]}"
    puts "Files updated:   #{stats[:files_updated]}"
    puts "Files skipped:   #{stats[:files_skipped]}"
    puts "Errors:          #{stats[:errors]}"
    puts "#{'=' * 60}"

    if stats[:errors] > 0
      puts "\nERROR: Migration completed with errors"
    elsif stats[:files_updated] == 0
      puts "\nNo files needed updating"
    elsif options[:dry_run]
      puts "\nDRY RUN completed. Use without --dry-run to apply changes."
    else
      puts "\nMigration completed successfully!"
    end
  end
end

# Parse command line options
options = {
  dry_run: false,
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: add_version_to_metadata.rb [options]'

  opts.on('--dry-run', 'Show what would be changed without making changes') do
    options[:dry_run] = true
  end

  opts.on('-f', '--file FILE', 'Process a single file') do |file|
    options[:file] = file
  end

  opts.on('-p', '--path PATH', 'Process all .md files in a directory (recursive)') do |path|
    options[:path] = path
  end

  opts.on('-v', '--verbose', 'Show detailed processing information') do
    options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!

# Run the migration
migrator = VersionMigrator.new(options)
migrator.run
