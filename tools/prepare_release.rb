#!/usr/bin/env ruby
# tools/prepare_release.rb - Orchestrates all release preparation steps
#
# This script automates the complete release preparation process:
# 1. Calculate next version based on git history
# 2. Update VERSION file with calculated version
# 3. Run full validation suite (validate_front_matter.rb, reindex.rb)
# 4. Generate CHANGELOG.md entry from changelog markdown
# 5. Validate all changes are correct
#
# Usage:
#   ruby tools/prepare_release.rb
#   ruby tools/prepare_release.rb --dry-run
#   ruby tools/prepare_release.rb --help

require 'json'
require 'optparse'
require 'fileutils'
require 'date'

# Global configuration and state
$options = {
  dry_run: false,
  verbose: false
}

$errors = []
$warnings = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: prepare_release.rb [options]"

  opts.on("--dry-run", "Show what would be done without making changes") do
    $options[:dry_run] = true
  end

  opts.on("--verbose", "Show detailed output") do
    $options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end.parse!

# Helper methods for output and error tracking
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
    puts "\nRelease preparation failed!"
    exit 1
  else
    puts "\nRelease preparation completed successfully!"
    exit 0
  end
end

# Run shell command and capture output
def run_command(command, description)
  log_verbose("Running: #{command}")

  output = `#{command} 2>&1`
  exit_status = $?.exitstatus

  if exit_status != 0
    log_error("#{description} failed with exit code #{exit_status}")
    log_error("Command output: #{output}")
    return false, output
  else
    log_verbose("#{description} succeeded")
    return true, output
  end
end

# Step 1: Calculate next version
def calculate_next_version
  log_info("Step 1: Calculating next version...")

  success, output = run_command("ruby tools/calculate_version.rb", "Version calculation")
  return nil unless success

  begin
    version_data = JSON.parse(output)
    current_version = version_data['current_version']
    next_version = version_data['next_version']
    bump_type = version_data['bump_type']
    commits = version_data['commits']
    changelog_markdown = version_data['changelog_markdown']

    log_info("Current version: #{current_version}")
    log_info("Next version: #{next_version}")
    log_info("Bump type: #{bump_type}")
    log_info("Commits since last release: #{commits.size}")

    if next_version == current_version
      log_warning("No version bump needed - no relevant changes found")
      return nil
    end

    return {
      current_version: current_version,
      next_version: next_version,
      bump_type: bump_type,
      commits: commits,
      changelog_markdown: changelog_markdown
    }
  rescue JSON::ParserError => e
    log_error("Failed to parse version calculation output: #{e.message}")
    log_error("Raw output: #{output}")
    return nil
  end
end

# Step 2: Update VERSION file
def update_version_file(next_version)
  log_info("Step 2: Updating VERSION file...")

  version_file = 'VERSION'

  if $options[:dry_run]
    log_info("[DRY RUN] Would update #{version_file} to: #{next_version}")
    return true
  end

  begin
    File.write(version_file, "#{next_version}\n")
    log_info("Updated #{version_file} to: #{next_version}")
    return true
  rescue => e
    log_error("Failed to update #{version_file}: #{e.message}")
    return false
  end
end

# Step 3: Run validation suite
def run_validation_suite
  log_info("Step 3: Running validation suite...")

  # Run front-matter validation
  log_info("Running YAML front-matter validation...")
  success, output = run_command("ruby tools/validate_front_matter.rb", "Front-matter validation")
  return false unless success

  # Run reindexing
  log_info("Running documentation reindexing...")
  success, output = run_command("ruby tools/reindex.rb", "Documentation reindexing")
  return false unless success

  log_info("All validation checks passed")
  return true
end

# Step 4: Update CHANGELOG.md
def update_changelog(version_data)
  log_info("Step 4: Updating CHANGELOG.md...")

  changelog_file = 'CHANGELOG.md'
  next_version = version_data[:next_version]
  changelog_markdown = version_data[:changelog_markdown]

  if $options[:dry_run]
    log_info("[DRY RUN] Would add the following entry to #{changelog_file}:")
    puts "=" * 50
    puts changelog_markdown
    puts "=" * 50
    return true
  end

  # Read existing changelog or create new one
  existing_content = ""
  if File.exist?(changelog_file)
    existing_content = File.read(changelog_file)
  else
    log_info("Creating new #{changelog_file}")
    existing_content = "# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n"
  end

  # Add release date to the changelog entry
  dated_changelog = changelog_markdown.gsub(
    "# Release #{next_version}",
    "# Release #{next_version} (#{Date.today.strftime('%Y-%m-%d')})"
  )

  # Insert new entry after the header
  if existing_content.include?("# Changelog")
    # Find the position after the main header and description
    header_end = existing_content.index("\n\n") + 2
    if header_end < existing_content.length && existing_content[header_end..-1].strip != ""
      # There's existing content, add new entry before it
      new_content = existing_content[0..header_end-1] + "#{dated_changelog}\n\n" + existing_content[header_end..-1]
    else
      # No existing releases, just append
      new_content = existing_content.rstrip + "\n\n#{dated_changelog}\n"
    end
  else
    # No proper changelog structure, create it
    new_content = "# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n#{dated_changelog}\n"
  end

  begin
    File.write(changelog_file, new_content)
    log_info("Added #{next_version} entry to #{changelog_file}")
    return true
  rescue => e
    log_error("Failed to update #{changelog_file}: #{e.message}")
    return false
  end
end

# Step 5: Final validation
def final_validation
  log_info("Step 5: Running final validation...")

  # Re-run validation to ensure everything is still correct
  log_info("Re-running validation after all changes...")
  success, output = run_command("ruby tools/validate_front_matter.rb", "Final validation")
  return false unless success

  log_info("Final validation passed")
  return true
end

# Main execution
def main
  if $options[:dry_run]
    log_info("=== DRY RUN MODE - No changes will be made ===")
  end

  log_info("Starting release preparation...")

  # Step 1: Calculate next version
  version_data = calculate_next_version
  exit_with_summary if $errors.any?

  if version_data.nil?
    log_info("No release preparation needed")
    exit_with_summary
  end

  # Step 2: Update VERSION file
  success = update_version_file(version_data[:next_version])
  exit_with_summary unless success

  # Step 3: Run validation suite
  success = run_validation_suite
  exit_with_summary unless success

  # Step 4: Update CHANGELOG.md
  success = update_changelog(version_data)
  exit_with_summary unless success

  # Step 5: Final validation
  success = final_validation
  exit_with_summary unless success

  # Success!
  if $options[:dry_run]
    log_info("=== DRY RUN COMPLETED ===")
    log_info("All steps would execute successfully")
  else
    log_info("Release preparation completed successfully!")
    log_info("Next version: #{version_data[:next_version]}")
    log_info("Updated files: VERSION, CHANGELOG.md")
    log_info("Ready for commit and release")
  end

  exit_with_summary
end

# Run the script
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue => e
    log_error("Unexpected error: #{e.message}")
    log_error("Backtrace: #{e.backtrace.join("\n")}")
    exit 1
  end
end
