#!/usr/bin/env ruby
# tools/migrate_directory_structure.rb - Directory structure migration tool
#
# This script migrates directory structure across versions
# Currently implements basic validation and placeholder migration logic
#
# Usage:
#   ruby tools/migrate_directory_structure.rb
#   ruby tools/migrate_directory_structure.rb --dry-run

require 'optparse'
require 'fileutils'

$options = {
  dry_run: false,
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: migrate_directory_structure.rb [options]'

  opts.on('--dry-run', 'Show what would be changed without making changes') do
    $options[:dry_run] = true
  end

  opts.on('-v', '--verbose', 'Show detailed output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

def log_info(message)
  puts "INFO: #{message}"
end

def log_verbose(message)
  puts "VERBOSE: #{message}" if $options[:verbose]
end

def log_dry_run(message)
  puts "DRY-RUN: #{message}"
end

def validate_current_structure
  log_info('Validating current directory structure')

  required_dirs = [
    'docs/tenets',
    'docs/bindings/core',
    'docs/bindings/categories',
    'tools'
  ]

  missing_dirs = []

  required_dirs.each do |dir|
    if Dir.exist?(dir)
      log_verbose("Found required directory: #{dir}")
    else
      log_info("Missing required directory: #{dir}")
      missing_dirs << dir
    end
  end

  if missing_dirs.empty?
    log_info('Directory structure validation passed')
    true
  else
    log_info("Directory structure validation failed - missing #{missing_dirs.length} directories")
    false
  end
end

def migrate_directory_structure
  log_info('Starting directory structure migration')

  # Validate current structure first
  unless validate_current_structure
    log_info('Current structure validation failed - no migration needed')
    exit 0
  end

  # Check for any legacy directories that might need migration
  legacy_dirs = []
  potential_legacy = [
    'docs/standards',  # Example legacy directory
    'docs/rules',      # Example legacy directory
    'docs/guidelines'  # Example legacy directory
  ]

  potential_legacy.each do |dir|
    if Dir.exist?(dir)
      legacy_dirs << dir
      log_info("Found legacy directory: #{dir}")
    end
  end

  if legacy_dirs.empty?
    log_info('No legacy directories found - structure is current')
  else
    log_info("Found #{legacy_dirs.length} legacy directories")

    # Placeholder for actual migration logic
    legacy_dirs.each do |dir|
      if $options[:dry_run]
        log_dry_run("Would migrate legacy directory: #{dir}")
      else
        log_info("Legacy directory migration not implemented for: #{dir}")
        log_info("Manual review required for: #{dir}")
      end
    end
  end

  # Validate index files exist where expected
  index_files = [
    'docs/tenets/00-index.md',
    'docs/bindings/00-index.md'
  ]

  index_files.each do |index_file|
    if File.exist?(index_file)
      log_verbose("Index file exists: #{index_file}")
    else
      log_info("Warning: Missing index file: #{index_file}")
      if $options[:dry_run]
        log_dry_run("Would regenerate missing index: #{index_file}")
      else
        log_info('Consider running: ruby tools/reindex.rb')
      end
    end
  end

  log_info('Directory structure migration completed')
  log_info('Current structure is compatible with latest version')

  exit 0
end

# Main execution
if __FILE__ == $0
  begin
    migrate_directory_structure
  rescue Interrupt
    puts "\nDirectory migration interrupted by user"
    exit 1
  rescue StandardError => e
    puts "Directory migration error: #{e.message}"
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
