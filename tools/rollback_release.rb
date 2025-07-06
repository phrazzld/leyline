#!/usr/bin/env ruby
# rollback_release.rb - Rollback a failed release by version tag
#
# This tool provides automated rollback functionality for failed releases,
# reverting version changes, deleting tags/releases, and notifying consumers.

require 'optparse'
require 'octokit'
require 'yaml'
require 'fileutils'
require 'time'

# Configuration and options
$options = {
  version: nil,
  dry_run: false,
  force: false,
  create_issue: true,
  verbose: false,
  github_token: ENV['GITHUB_TOKEN'],
  repo: nil
}

$errors = []
$warnings = []
$actions_taken = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: rollback_release.rb [options]'

  opts.on('-v', '--version VERSION', 'Version to rollback (e.g., v0.2.0)') do |version|
    $options[:version] = version
  end

  opts.on('--dry-run', 'Show what would be done without making changes') do
    $options[:dry_run] = true
  end

  opts.on('--force', 'Force rollback even with warnings') do
    $options[:force] = true
  end

  opts.on('--no-issue', 'Skip creating rollback notification issue') do
    $options[:create_issue] = false
  end

  opts.on('--repo REPO', 'GitHub repository (owner/name)') do |repo|
    $options[:repo] = repo
  end

  opts.on('--token TOKEN', 'GitHub token (or set GITHUB_TOKEN env var)') do |token|
    $options[:github_token] = token
  end

  opts.on('--verbose', 'Verbose output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Helper methods
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

def log_action(action)
  if $options[:dry_run]
    puts "[DRY RUN] Would: #{action}"
  else
    puts "[ACTION] #{action}"
  end
  $actions_taken << action
end

# Detect repository information
def detect_repo_info
  return $options[:repo] if $options[:repo]

  # Try to detect from git remote
  if File.exist?('.git')
    remote_url = `git config --get remote.origin.url 2>/dev/null`.strip
    return "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}" if remote_url =~ %r{github\.com[:/]([^/]+)/(.+?)(\.git)?$}
  end

  nil
end

# Validate version format
def validate_version(version)
  unless version =~ /^v?\d+\.\d+\.\d+(-.*)?$/
    log_error("Invalid version format: #{version}. Expected format: v1.0.0")
    return false
  end
  true
end

# Get previous version from git tags
def get_previous_version(current_version)
  # Get all tags sorted by version
  tags = `git tag -l 'v*' | sort -V`.strip.split("\n")

  current_index = tags.index(current_version)
  return tags[current_index - 1] if current_index && current_index > 0

  log_warning('Could not determine previous version')
  nil
end

# Get release commit SHA
def get_release_commit(version)
  sha = `git rev-list -n 1 #{version} 2>/dev/null`.strip
  sha.empty? ? nil : sha
end

# Revert VERSION file
def revert_version_file(previous_version)
  log_action("Revert VERSION file to #{previous_version}")
  return if $options[:dry_run]

  unless File.exist?('VERSION')
    log_error('VERSION file not found')
    return false
  end

  # Remove 'v' prefix if present
  clean_version = previous_version.gsub(/^v/, '')

  File.write('VERSION', clean_version)
  log_info("Reverted VERSION to #{clean_version}")
  true
end

# Revert CHANGELOG.md
def revert_changelog(version, _previous_version)
  log_action("Revert CHANGELOG.md to remove #{version} entry")
  return if $options[:dry_run]

  unless File.exist?('CHANGELOG.md')
    log_warning('CHANGELOG.md not found')
    return true
  end

  content = File.read('CHANGELOG.md')

  # Find and remove the section for this version
  # Assuming changelog format: ## [version] - date
  version_pattern = /^## \[?#{Regexp.escape(version.gsub(/^v/, ''))}\]?.*?\n(.*?)(?=^## |\z)/m

  if content =~ version_pattern
    original_content = content.dup
    content.gsub!(version_pattern, '')

    if content != original_content
      # Create backup
      backup_file = "CHANGELOG.md.rollback-#{Time.now.strftime('%Y%m%d%H%M%S')}"
      File.write(backup_file, original_content)
      log_verbose("Created changelog backup: #{backup_file}")

      File.write('CHANGELOG.md', content)
      log_info("Removed #{version} entry from CHANGELOG.md")
    end
  else
    log_warning("Could not find #{version} entry in CHANGELOG.md")
  end

  true
end

# Delete git tag
def delete_git_tag(version)
  log_action("Delete git tag #{version}")
  return if $options[:dry_run]

  # Delete local tag
  system("git tag -d #{version} 2>/dev/null")

  # Try to delete remote tag if origin exists
  if system('git remote get-url origin >/dev/null 2>&1')
    if system("git push origin :refs/tags/#{version} 2>&1")
      log_info("Deleted git tag #{version} (local and remote)")
    else
      log_warning("Failed to delete remote tag #{version} - deleted local tag only")
    end
  else
    log_info("Deleted local git tag #{version} (no remote found)")
  end

  true
end

# Delete GitHub release
def delete_github_release(client, repo, version)
  log_action("Delete GitHub release #{version}")
  return if $options[:dry_run]

  begin
    # Find release by tag
    releases = client.releases(repo)
    release = releases.find { |r| r.tag_name == version }

    if release
      client.delete_release(release.url)
      log_info("Deleted GitHub release #{version}")
      true
    else
      log_warning("GitHub release #{version} not found")
      true
    end
  rescue StandardError => e
    log_error("Failed to delete GitHub release: #{e.message}")
    false
  end
end

# Create rollback notification issue
def create_rollback_issue(client, repo, version, previous_version, reason = nil)
  log_action('Create rollback notification issue')
  return if $options[:dry_run]

  title = "🔄 Release Rollback: #{version}"

  body = <<~BODY
    ## Release Rollback Notification

    The release **#{version}** has been rolled back.

    ### Details
    - **Rolled back version:** #{version}
    - **Reverted to version:** #{previous_version || 'previous version'}
    - **Rollback timestamp:** #{Time.now.utc.iso8601}
    - **Rollback initiated by:** Automated rollback system

    ### Actions Taken
    #{$actions_taken.map { |action| "- #{action}" }.join("\n")}

    ### Impact
    - Git tag `#{version}` has been deleted
    - GitHub release for `#{version}` has been removed
    - VERSION file has been reverted to #{previous_version || 'previous version'}
    - CHANGELOG.md has been updated to remove #{version} entry

    ### Next Steps
    1. Review the issues that caused this rollback
    2. Fix the identified problems
    3. Prepare a new release when ready

    ### For Consumers
    If you have already updated to #{version}, please revert to #{previous_version || 'the previous version'}.

    #{reason ? "### Rollback Reason\n#{reason}" : ''}

    ---
    *This issue was automatically created by the rollback system.*
  BODY

  begin
    issue = client.create_issue(repo, title, body, labels: %w[rollback release])
    log_info("Created rollback notification issue ##{issue.number}")
    true
  rescue StandardError => e
    log_error("Failed to create rollback issue: #{e.message}")
    false
  end
end

# Verify rollback success
def verify_rollback(version, previous_version)
  log_info('Verifying rollback success')

  errors = []

  # Check VERSION file
  if File.exist?('VERSION')
    current_version = File.read('VERSION').strip
    expected_version = previous_version.gsub(/^v/, '')

    if current_version != expected_version
      errors << "VERSION file shows #{current_version}, expected #{expected_version}"
    end
  else
    errors << 'VERSION file missing'
  end

  # Check git tag doesn't exist
  errors << "Git tag #{version} still exists" if system("git rev-parse #{version} >/dev/null 2>&1")

  # Check CHANGELOG doesn't contain version
  if File.exist?('CHANGELOG.md')
    content = File.read('CHANGELOG.md')
    log_warning("CHANGELOG.md may still contain references to #{version}") if content.include?(version.gsub(/^v/, ''))
  end

  if errors.any?
    errors.each { |error| log_error("Verification failed: #{error}") }
    false
  else
    log_info('Rollback verification passed')
    true
  end
end

# Main rollback process
def perform_rollback
  # Validate inputs
  unless $options[:version]
    log_error('Version to rollback is required (use --version)')
    return false
  end

  return false unless validate_version($options[:version])

  version = $options[:version]
  version = "v#{version}" unless version.start_with?('v')

  log_info("Starting rollback of version #{version}")

  # Detect repository
  repo = detect_repo_info
  unless repo
    log_error('Could not detect GitHub repository. Use --repo option.')
    return false
  end
  log_verbose("Repository: #{repo}")

  # Get previous version
  previous_version = get_previous_version(version)
  if !previous_version && !$options[:force]
    log_error('Could not determine previous version. Use --force to continue anyway.')
    return false
  end
  log_info("Previous version: #{previous_version || 'unknown'}")

  # Initialize GitHub client if needed
  github_client = nil
  if !$options[:dry_run] && $options[:github_token]
    begin
      github_client = Octokit::Client.new(access_token: $options[:github_token])
      github_client.user # Test authentication
      log_verbose('GitHub authentication successful')
    rescue StandardError => e
      log_error("GitHub authentication failed: #{e.message}")
      return false unless $options[:force]
    end
  elsif !$options[:dry_run] && !$options[:github_token]
    log_warning('No GitHub token provided. Skipping GitHub operations.')
  end

  # Perform rollback steps
  success = true

  # 1. Revert VERSION file
  if previous_version
    success &&= revert_version_file(previous_version)
  else
    log_warning('Skipping VERSION file revert (no previous version)')
  end

  # 2. Revert CHANGELOG.md
  success &&= revert_changelog(version, previous_version)

  # 3. Delete git tag
  success &&= delete_git_tag(version)

  # 4. Delete GitHub release
  success &&= delete_github_release(github_client, repo, version) if github_client

  # 5. Create rollback notification issue
  if github_client && $options[:create_issue] && !$options[:dry_run]
    create_rollback_issue(github_client, repo, version, previous_version)
  end

  # 6. Verify rollback
  verify_rollback(version, previous_version) if !$options[:dry_run] && previous_version

  success
end

# Exit with summary
def exit_with_summary(success)
  puts "\n" + '=' * 60

  if $warnings.any?
    puts "\n#{$warnings.size} warning(s):"
    $warnings.each { |warning| puts "  - #{warning}" }
  end

  if $errors.any?
    puts "\n#{$errors.size} error(s):"
    $errors.each { |error| puts "  - #{error}" }
  end

  if $options[:dry_run]
    puts "\nDRY RUN SUMMARY - No changes were made"
    puts 'Actions that would be taken:'
    $actions_taken.each { |action| puts "  - #{action}" }
  elsif success
    puts "\n✅ Rollback completed successfully"
  else
    puts "\n❌ Rollback failed with errors"
  end

  exit(success ? 0 : 1)
end

# Run the script
if __FILE__ == $0
  begin
    success = perform_rollback
    exit_with_summary(success)
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue StandardError => e
    log_error("Unexpected error: #{e.message}")
    log_error("Backtrace: #{e.backtrace.join("\n")}") if $options[:verbose]
    exit 1
  end
end
