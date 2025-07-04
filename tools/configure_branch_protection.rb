#!/usr/bin/env ruby
# tools/configure_branch_protection.rb - Configure GitHub branch protection rules
#
# This script configures branch protection rules for the main branch to ensure
# that releases can only happen after all required checks pass.
#
# Usage:
#   ruby tools/configure_branch_protection.rb
#   ruby tools/configure_branch_protection.rb --dry-run
#   ruby tools/configure_branch_protection.rb --help

require 'json'
require 'optparse'

# Configuration
PROTECTED_BRANCH = 'main'
REQUIRED_STATUS_CHECKS = [
  'pre-release-validation',
  'Validate YAML front-matter in markdown files',
  'Check index consistency with YAML validation'
]

# Global options
$options = {
  dry_run: false,
  verbose: false
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: configure_branch_protection.rb [options]'

  opts.on('--dry-run', 'Show what would be configured without making changes') do
    $options[:dry_run] = true
  end

  opts.on('--verbose', 'Show detailed output') do
    $options[:verbose] = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

def log_info(message)
  puts "[INFO] #{message}"
end

def log_verbose(message)
  puts "[VERBOSE] #{message}" if $options[:verbose]
end

def log_error(message)
  puts "[ERROR] #{message}"
end

def get_repository_info
  # Try to get repository info from git remote
  remote_url = `git config --get remote.origin.url`.strip

  if remote_url =~ %r{github\.com[/:](.+?)/(.+?)(?:\.git)?$}
    owner = Regexp.last_match(1)
    repo = Regexp.last_match(2)
    { owner: owner, repo: repo, full_name: "#{owner}/#{repo}" }
  else
    log_error("Could not determine GitHub repository from remote URL: #{remote_url}")
    nil
  end
end

def check_github_cli
  # Check if GitHub CLI is available
  unless system('which gh > /dev/null 2>&1')
    log_error('GitHub CLI (gh) is not installed or not in PATH')
    log_error('Please install it from: https://cli.github.com/')
    return false
  end

  # Check if authenticated
  unless system('gh auth status > /dev/null 2>&1')
    log_error('GitHub CLI is not authenticated')
    log_error('Please run: gh auth login')
    return false
  end

  true
end

def get_current_protection(repo_info)
  log_verbose("Getting current branch protection for #{PROTECTED_BRANCH}...")

  output = `gh api repos/#{repo_info[:full_name]}/branches/#{PROTECTED_BRANCH}/protection 2>/dev/null`
  exit_status = $?.exitstatus

  if exit_status == 0
    begin
      JSON.parse(output)
    rescue JSON::ParserError
      log_error('Failed to parse current protection settings')
      nil
    end
  elsif exit_status == 1
    # Branch protection not enabled
    {}
  else
    log_error('Failed to get current branch protection settings')
    nil
  end
end

def create_protection_config
  {
    required_status_checks: {
      strict: true,
      contexts: REQUIRED_STATUS_CHECKS
    },
    enforce_admins: false,
    required_pull_request_reviews: {
      required_approving_review_count: 1,
      dismiss_stale_reviews: true,
      require_code_owner_reviews: false,
      restrict_pushes: true
    },
    restrictions: nil, # Allow all users/teams
    allow_force_pushes: false,
    allow_deletions: false
  }
end

def configure_protection(repo_info, config)
  log_info("Configuring branch protection for #{PROTECTED_BRANCH}...")

  if $options[:dry_run]
    log_info('[DRY RUN] Would configure the following protection:')
    puts JSON.pretty_generate(config)
    return true
  end

  # Write config to temporary file
  config_file = '/tmp/branch_protection_config.json'
  File.write(config_file, JSON.pretty_generate(config))

  # Apply the configuration
  command = "gh api repos/#{repo_info[:full_name]}/branches/#{PROTECTED_BRANCH}/protection " \
           "--method PUT --input #{config_file}"

  log_verbose("Running: #{command}")

  success = system(command)

  # Clean up
  File.delete(config_file) if File.exist?(config_file)

  if success
    log_info('✅ Branch protection configured successfully')
    true
  else
    log_error('❌ Failed to configure branch protection')
    false
  end
end

def main
  log_info('Starting branch protection configuration...')

  log_info('=== DRY RUN MODE - No changes will be made ===') if $options[:dry_run]

  # Check prerequisites
  exit 1 unless check_github_cli

  # Get repository information
  repo_info = get_repository_info
  exit 1 unless repo_info

  log_info("Repository: #{repo_info[:full_name]}")
  log_info("Protected branch: #{PROTECTED_BRANCH}")

  # Get current protection settings
  current_protection = get_current_protection(repo_info)
  exit 1 if current_protection.nil?

  if current_protection.any?
    log_info('Current branch protection is enabled')
    log_verbose("Current settings: #{JSON.pretty_generate(current_protection)}")
  else
    log_info('No branch protection currently configured')
  end

  # Create new protection configuration
  config = create_protection_config

  log_info('Required status checks:')
  REQUIRED_STATUS_CHECKS.each do |check|
    log_info("  - #{check}")
  end

  # Apply the configuration
  success = configure_protection(repo_info, config)

  if success
    log_info('🎉 Branch protection configuration completed!')
    log_info('')
    log_info('Summary of protection rules:')
    log_info('  ✅ Required status checks enabled')
    log_info('  ✅ Require branches to be up to date')
    log_info('  ✅ Require pull request reviews (1 reviewer)')
    log_info('  ✅ Dismiss stale reviews when new commits are pushed')
    log_info('  ✅ Force pushes disabled')
    log_info('  ✅ Branch deletion disabled')
    log_info('')
    log_info('All releases now require validation gates to pass!')
  else
    log_error('Branch protection configuration failed!')
    exit 1
  end
end

# Run the script
if __FILE__ == $0
  begin
    main
  rescue Interrupt
    puts "\nInterrupted by user"
    exit 1
  rescue StandardError => e
    log_error("Unexpected error: #{e.message}")
    log_error("Backtrace: #{e.backtrace.join("\n")}")
    exit 1
  end
end
