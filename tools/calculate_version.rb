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
require 'open3'

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
  rules_file = File.join(File.dirname(__FILE__), 'breaking_change_rules.yml')
  unless File.exist?(rules_file)
    report_error("Breaking change rules file not found: #{rules_file}")
    return {}
  end

  begin
    YAML.load_file(rules_file)
  rescue => e
    report_error("Failed to load breaking change rules: #{e.message}")
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
      version = File.read(version_file).strip
      puts "Found current version from VERSION file: #{version}" if $options[:verbose]
      version
    else
      puts "No version found, defaulting to 0.1.0" if $options[:verbose]
      "0.1.0"
    end
  end
end

# Get commits since last tag
def get_commits_since_last_tag(current_version)
  # Find the tag corresponding to current version
  tag_name = "v#{current_version}"

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
      {
        hash: hash,
        message: message || '',
        type: extract_commit_type(message || ''),
        breaking: commit_has_breaking_change?(message || '')
      }
    end.compact

    puts "Found #{commits.length} commits since #{tag_name}" if $options[:verbose]
    commits
  else
    puts "Failed to get git commits: #{output}" if $options[:verbose]
    []
  end
end

# Extract conventional commit type from message
def extract_commit_type(message)
  if message =~ /^(\w+)(\(.+?\))?(!)?:/
    type = $1.downcase
    breaking_marker = $3
    return 'breaking' if breaking_marker == '!'
    type
  else
    'other'
  end
end

# Check if commit message indicates breaking change
def commit_has_breaking_change?(message)
  message.include?('BREAKING CHANGE:') || !!(message =~ /^(\w+)(\(.+?\))?!:/)
end

# Detect breaking changes from file changes (future enhancement)
def detect_file_based_breaking_changes(commits)
  # For now, return empty array
  # This would analyze git diff for file deletions/moves based on breaking_change_rules.yml
  []
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

# Run git command safely
def run_git_command(command)
  full_command = "git #{command}"
  puts "Running: #{full_command}" if $options[:verbose]

  output, status = Open3.capture2(full_command)
  [output, status]
rescue => e
  report_error("Git command failed: #{e.message}")
  ["", nil]
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

# Main calculation function
def calculate_version
  rules = load_breaking_change_rules
  current_version = get_current_version
  commits = get_commits_since_last_tag(current_version)
  breaking_changes = detect_file_based_breaking_changes(commits)
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
