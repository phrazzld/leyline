#!/usr/bin/env ruby
# tools/migrate_yaml_frontmatter.rb - YAML front-matter migration tool
#
# This script migrates YAML front-matter format across versions
# Currently implements basic validation and placeholder migration logic
#
# Usage:
#   ruby tools/migrate_yaml_frontmatter.rb
#   ruby tools/migrate_yaml_frontmatter.rb --dry-run

require 'optparse'
require 'yaml'
require 'fileutils'

$options = {
  dry_run: false,
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: migrate_yaml_frontmatter.rb [options]'

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

def migrate_yaml_frontmatter
  log_info('Starting YAML front-matter migration')

  # Find all markdown files with YAML front-matter
  markdown_files = Dir.glob('docs/**/*.md').reject { |f| f.include?('00-index.md') }

  log_info("Found #{markdown_files.length} markdown files to examine")

  migrated_count = 0

  markdown_files.each do |file|
    log_verbose("Examining: #{file}")

    begin
      content = File.read(file)

      # Check if file has YAML front-matter
      if content.start_with?('---')
        yaml_end = content.index('---', 3)
        next unless yaml_end

        yaml_content = content[4...yaml_end]
        yaml_data = YAML.safe_load(yaml_content)

        # Perform any necessary migrations here
        # For now, just validate that the YAML is parseable
        if yaml_data.is_a?(Hash)
          log_verbose("Valid YAML front-matter in #{file}")

          # Placeholder for actual migration logic
          # In future versions, this would transform old formats to new formats
          if $options[:dry_run]
            log_dry_run("Would migrate YAML in #{file}")
          else
            # No actual migration needed at this time
            log_verbose("No migration needed for #{file}")
          end

          migrated_count += 1
        else
          log_info("Warning: Invalid YAML front-matter in #{file}")
        end
      else
        log_verbose("No YAML front-matter in #{file}")
      end
    rescue StandardError => e
      log_info("Error processing #{file}: #{e.message}")
    end
  end

  log_info('YAML front-matter migration completed')
  log_info("Processed #{migrated_count} files with valid YAML front-matter")

  exit 0
end

# Main execution
if __FILE__ == $0
  begin
    migrate_yaml_frontmatter
  rescue Interrupt
    puts "\nYAML migration interrupted by user"
    exit 1
  rescue StandardError => e
    puts "YAML migration error: #{e.message}"
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
