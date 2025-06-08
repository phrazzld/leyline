#!/usr/bin/env ruby
# tools/calculate_version.rb - Calculate semantic version based on git history
#
# This script analyzes git commit history and applies semantic versioning rules
# to determine the next version. It supports both pre-1.0 and post-1.0 strategies.
#
# Pre-1.0 Strategy (current):
#   - Breaking changes increment minor version (0.1.0 → 0.2.0)
#   - Features increment minor version (0.1.0 → 0.2.0)
#   - Fixes increment patch version (0.1.0 → 0.1.1)
#
# Post-1.0 Strategy:
#   - Breaking changes increment major version (1.0.0 → 2.0.0)
#   - Features increment minor version (1.0.0 → 1.1.0)
#   - Fixes increment patch version (1.0.0 → 1.0.1)
#
# Usage:
#   ruby tools/calculate_version.rb
#   ruby tools/calculate_version.rb --pretty
#   ruby tools/calculate_version.rb --help

require 'json'
require 'yaml'
require 'optparse'
require 'ostruct'
require_relative 'security_utils'

# Global configuration
$options = {
  pretty: false,
  verbose: false
}

$errors = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: calculate_version.rb [options]"

  opts.on("--pretty", "Pretty print JSON output") do
    $options[:pretty] = true
  end

  opts.on("--verbose", "Show detailed processing information") do
    $options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end.parse!

# Load breaking change rules from YAML configuration
def load_breaking_change_rules
  rules_file = 'breaking_change_rules.yml'  # Simplified path for security
  rules_full_path = File.join(File.dirname(__FILE__), rules_file)

  unless File.exist?(rules_full_path)
    report_error("Breaking change rules file not found: #{rules_full_path}")
    return {}
  end

  begin
    # Read file directly since it's in the same directory and safe
    yaml_content = File.read(rules_full_path)

    # Use safe YAML loading to prevent arbitrary object deserialization
    rules = YAML.safe_load(yaml_content, permitted_classes: [], permitted_symbols: [], aliases: false)

    # Validate the structure contains expected keys
    unless rules.is_a?(Hash)
      report_error("Invalid breaking change rules format: must be a hash")
      SecurityUtils.log_security_event('invalid_rules_format', { type: rules.class })
      return {}
    end

    rules
  rescue SecurityUtils::SecurityError => e
    report_error("Security error loading breaking change rules: #{e.message}")
    SecurityUtils.log_security_event('rules_file_security_error', { error: e.message })
    {}
  rescue => e
    report_error("Failed to load breaking change rules: #{e.message}")
    SecurityUtils.log_security_event('rules_file_load_error', { error: e.message })
    {}
  end
end

# Get current version from git tags
def get_current_version
  # Get the latest tag that looks like a version
  output, status = run_git_command("describe --tags --abbrev=0 --match='v*'")

  if status.success? && !output.empty?
    version = output.strip.sub(/^v/, '') # Remove 'v' prefix if present
    puts "Found current version from git tag: #{version}" if $options[:verbose]
    version
  else
    # No tags found, start with 0.1.0 as per VERSION file
    version_file = 'VERSION'
    if File.exist?(version_file)
      begin
        version = SecurityUtils.safe_file_read(version_file, max_size: 100).strip
        unless SecurityUtils.validate_version(version)
          report_error("Invalid version format in VERSION file: #{version}")
          SecurityUtils.log_security_event('invalid_version_file', { version: version })
          return "0.1.0"
        end
        puts "Found current version from VERSION file: #{version}" if $options[:verbose]
        version
      rescue SecurityUtils::SecurityError => e
        report_error("Failed to read VERSION file: #{e.message}")
        SecurityUtils.log_security_event('version_file_read_error', { error: e.message })
        "0.1.0"
      end
    else
      puts "No version found, defaulting to 0.1.0" if $options[:verbose]
      "0.1.0"
    end
  end
end

# Get commits since last tag
def get_commits_since_last_tag(current_version)
  # Validate current version format
  unless SecurityUtils.validate_version(current_version)
    report_error("Invalid current version format: #{current_version}")
    SecurityUtils.log_security_event('invalid_current_version', { version: current_version })
    return []
  end

  # Find the tag corresponding to current version
  tag_name = "v#{current_version}"

  # Validate tag name format
  unless SecurityUtils.validate_git_ref(tag_name)
    report_error("Invalid tag name format: #{tag_name}")
    SecurityUtils.log_security_event('invalid_tag_name', { tag: tag_name })
    return []
  end

  # Check if tag exists
  _, status = run_git_command("rev-parse --verify #{tag_name}")

  if status.success?
    # Get commits since the tag
    output, status = run_git_command("log #{tag_name}..HEAD --oneline --format='%H|%s'")
  else
    # No tag exists, get all commits
    output, status = run_git_command("log --oneline --format='%H|%s'")
  end

  if status.success?
    commits = output.strip.split("\n").map do |line|
      next if line.empty?
      hash, message = line.split('|', 2)

      # Validate commit hash format (40 character hex string)
      unless hash && hash.match?(/^[a-f0-9]{40}$/)
        SecurityUtils.log_security_event('invalid_commit_hash', { hash: hash })
        next
      end

      # Validate commit message
      unless SecurityUtils.validate_commit_message(message || '')
        SecurityUtils.log_security_event('invalid_commit_message', { hash: hash, message: message })
        next
      end

      # Get full commit message to check for breaking changes in body
      full_message, full_status = run_git_command("log -1 --format=%B #{hash}")
      full_text = full_status.success? ? full_message : (message || '')

      # Validate full commit message too
      unless SecurityUtils.validate_commit_message(full_text)
        SecurityUtils.log_security_event('invalid_full_commit_message', { hash: hash })
        full_text = message || ''  # Fallback to short message
      end

      parsed = parse_conventional_commit(message || '')
      {
        hash: hash,
        message: SecurityUtils.sanitize_output(message || ''),
        full_message: SecurityUtils.sanitize_output(full_text),
        type: parsed[:type],
        scope: parsed[:scope],
        subject: parsed[:subject],
        breaking: commit_has_breaking_change?(full_text)
      }
    end.compact

    puts "Found #{commits.length} commits since #{tag_name}" if $options[:verbose]
    commits
  else
    puts "Failed to get git commits: #{output}" if $options[:verbose]
    []
  end
end

# Parse conventional commit format
def parse_conventional_commit(message)
  if message =~ /^(\w+)(\(([^)]+)\))?(!)?:\s*(.+)/
    {
      type: $1.downcase,
      scope: $3,
      subject: $5,
      breaking: $4 == '!'
    }
  else
    {
      type: 'other',
      scope: nil,
      subject: message,
      breaking: false
    }
  end
end

# Extract conventional commit type from message (legacy method)
def extract_commit_type(message)
  parsed = parse_conventional_commit(message)
  parsed[:breaking] ? 'breaking' : parsed[:type]
end

# Check if commit message indicates breaking change
def commit_has_breaking_change?(message)
  # Check the commit message itself first
  return true if message.include?('BREAKING CHANGE:') || !!(message =~ /^(\w+)(\(.+?\))?!:/)

  # For single-line messages that might be truncated, this is sufficient
  # The full message check happens in extract_breaking_change_details
  false
end

# Detect breaking changes from file changes
def detect_file_based_breaking_changes(commits, rules)
  return [] if commits.empty? || !rules['breaking_patterns']

  breaking_changes = []

  # Get all changed files for these commits
  commits.each do |commit|
    output, status = run_git_command("show --name-only --format= #{commit[:hash]}")
    if status.success?
      files = output.strip.split("\n").reject(&:empty?)

      files.each do |file|
        rules['breaking_patterns'].each do |pattern|
          if file.match?(Regexp.new(pattern))
            breaking_changes << "Breaking change detected in file: #{file}"
          end
        end
      end
    end
  end

  breaking_changes.uniq
end

# Determine version bump type based on commits
def determine_bump_type(commits, current_version, breaking_changes)
  return 'none' if commits.empty?

  has_breaking = commits.any? { |c| c[:breaking] } || !breaking_changes.empty?
  has_features = commits.any? { |c| c[:type] == 'feat' }
  has_fixes = commits.any? { |c| c[:type] == 'fix' }

  is_pre_1_0 = current_version.start_with?('0.')

  if is_pre_1_0
    # Pre-1.0 strategy: breaking changes and features both bump minor
    if has_breaking || has_features
      'minor'
    elsif has_fixes
      'patch'
    else
      'patch' # Other changes default to patch
    end
  else
    # Post-1.0 strategy: standard semver
    if has_breaking
      'major'
    elsif has_features
      'minor'
    elsif has_fixes
      'patch'
    else
      'patch'
    end
  end
end

# Calculate next version based on bump type
def calculate_next_version(current_version, bump_type)
  return current_version if bump_type == 'none'

  parts = current_version.split('.').map(&:to_i)
  major, minor, patch = parts[0] || 0, parts[1] || 0, parts[2] || 0

  case bump_type
  when 'major'
    "#{major + 1}.0.0"
  when 'minor'
    "#{major}.#{minor + 1}.0"
  when 'patch'
    "#{major}.#{minor}.#{patch + 1}"
  else
    current_version
  end
end

# Run git command safely with security validation
def run_git_command(command)
  puts "Running: git #{command}" if $options[:verbose]

  begin
    # Use secure git command execution
    result = SecurityUtils.safe_git_command(command)
    # Create a mock status object that responds to success?
    mock_status = OpenStruct.new(success?: result[:success], exitstatus: result[:exit_code])
    [result[:stdout], mock_status]
  rescue SecurityUtils::SecurityError => e
    report_error("Git command security error: #{e.message}")
    SecurityUtils.log_security_event('git_command_blocked', { command: command, error: e.message })
    mock_status = OpenStruct.new(success?: false, exitstatus: 1)
    ["", mock_status]
  rescue => e
    report_error("Git command failed: #{e.message}")
    mock_status = OpenStruct.new(success?: false, exitstatus: 1)
    ["", mock_status]
  end
end

# Error reporting
def report_error(message)
  puts "ERROR: #{message}" unless $options[:pretty]
  $errors << message
end

# Get GitHub repository URL for commit links
def get_github_repo_url
  # Try to get the GitHub URL from git remote
  output, status = run_git_command("config --get remote.origin.url")

  if status.success? && !output.empty?
    url = output.strip

    # Convert various formats to standard GitHub URL
    if url =~ /github\.com[\/:](.+?)\/(.+?)(?:\.git)?$/
      owner, repo = $1, $2
      "https://github.com/#{owner}/#{repo}"
    else
      # Fallback if we can't parse the URL
      puts "Could not parse GitHub URL: #{url}" if $options[:verbose]
      nil
    end
  else
    puts "Could not get remote origin URL" if $options[:verbose]
    nil
  end
end

# Clean commit message for display
def clean_commit_message(message)
  # Remove conventional commit prefix for display
  cleaned = message.gsub(/^(\w+)(\(.+?\))?!?:\s*/, '')

  # Capitalize first letter
  cleaned = cleaned[0].upcase + cleaned[1..-1] if cleaned.length > 0

  cleaned
end

# Generate changelog markdown from commits
def generate_changelog_markdown(commits, next_version)
  return "No changes since last release." if commits.empty?

  repo_url = get_github_repo_url

  # Categorize commits
  breaking_commits = commits.select { |c| c[:breaking] }
  feature_commits = commits.select { |c| c[:type] == 'feat' && !c[:breaking] }
  fix_commits = commits.select { |c| c[:type] == 'fix' && !c[:breaking] }
  other_commits = commits.select { |c| !['feat', 'fix'].include?(c[:type]) && !c[:breaking] }

  markdown = []
  markdown << "# Release #{next_version}"
  markdown << ""

  # Breaking Changes section
  if breaking_commits.any?
    markdown << "## ⚠️ BREAKING CHANGES"
    markdown << ""
    breaking_commits.each do |commit|
      message = clean_commit_message(commit[:message])
      if repo_url
        markdown << "- #{message} ([#{commit[:hash][0..7]}](#{repo_url}/commit/#{commit[:hash]}))"
      else
        markdown << "- #{message} (#{commit[:hash][0..7]})"
      end
    end
    markdown << ""
  end

  # Features section
  if feature_commits.any?
    markdown << "## ✨ Features"
    markdown << ""
    feature_commits.each do |commit|
      message = clean_commit_message(commit[:message])
      if repo_url
        markdown << "- #{message} ([#{commit[:hash][0..7]}](#{repo_url}/commit/#{commit[:hash]}))"
      else
        markdown << "- #{message} (#{commit[:hash][0..7]})"
      end
    end
    markdown << ""
  end

  # Bug Fixes section
  if fix_commits.any?
    markdown << "## 🐛 Bug Fixes"
    markdown << ""
    fix_commits.each do |commit|
      message = clean_commit_message(commit[:message])
      if repo_url
        markdown << "- #{message} ([#{commit[:hash][0..7]}](#{repo_url}/commit/#{commit[:hash]}))"
      else
        markdown << "- #{message} (#{commit[:hash][0..7]})"
      end
    end
    markdown << ""
  end

  # Other changes section (if any)
  if other_commits.any?
    markdown << "## 🔧 Other Changes"
    markdown << ""
    other_commits.each do |commit|
      message = clean_commit_message(commit[:message])
      if repo_url
        markdown << "- #{message} ([#{commit[:hash][0..7]}](#{repo_url}/commit/#{commit[:hash]}))"
      else
        markdown << "- #{message} (#{commit[:hash][0..7]})"
      end
    end
    markdown << ""
  end

  markdown.join("\n").strip
end

# Extract breaking change details from commits
def extract_breaking_change_details(commits)
  breaking_details = []

  commits.each do |commit|
    # Use the already-fetched full message
    message_to_check = commit[:full_message] || commit[:message]

    # Check for BREAKING CHANGE: in the full message
    if message_to_check.include?('BREAKING CHANGE:')
      # Extract the breaking change description
      breaking_text = message_to_check.split('BREAKING CHANGE:')[1]&.strip
      if breaking_text && !breaking_text.empty?
        # Take the first line or sentence of the breaking change description
        first_line = breaking_text.split("\n").first&.strip
        breaking_details << first_line if first_line && !first_line.empty?
      end
    elsif commit[:message] =~ /^(\w+)(\(.+?\))?!:/
      # For ! syntax, use the commit subject as breaking change
      parsed = parse_conventional_commit(commit[:message])
      breaking_details << parsed[:subject] if parsed[:subject]
    end
  end

  breaking_details
end

# Main calculation function
def calculate_version
  rules = load_breaking_change_rules
  current_version = get_current_version
  commits = get_commits_since_last_tag(current_version)
  file_breaking_changes = detect_file_based_breaking_changes(commits, rules)
  commit_breaking_changes = extract_breaking_change_details(commits)
  breaking_changes = file_breaking_changes + commit_breaking_changes
  bump_type = determine_bump_type(commits, current_version, breaking_changes)
  next_version = calculate_next_version(current_version, bump_type)
  changelog_markdown = generate_changelog_markdown(commits, next_version)

  {
    current_version: current_version,
    next_version: next_version,
    bump_type: bump_type,
    commits: commits,
    breaking_changes: breaking_changes,
    changelog_markdown: changelog_markdown
  }
end

# Main execution
if __FILE__ == $0
  begin
    result = calculate_version

    if $errors.any?
      puts "Errors occurred during version calculation:" unless $options[:pretty]
      $errors.each { |error| puts "  #{error}" } unless $options[:pretty]
      exit 1
    end

    if $options[:pretty]
      puts JSON.pretty_generate(result)
    else
      puts JSON.generate(result)
    end

  rescue => e
    puts "FATAL ERROR: #{e.message}" unless $options[:pretty]
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
