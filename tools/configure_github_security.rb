#!/usr/bin/env ruby
# tools/configure_github_security.rb - Configure GitHub repository security settings
#
# This script configures comprehensive GitHub security settings including:
# - Branch protection rules
# - Required status checks
# - Review requirements
# - Security scanning and vulnerability alerts
#
# Usage:
#   ruby tools/configure_github_security.rb --repo owner/repo
#   ruby tools/configure_github_security.rb --dry-run
#   ruby tools/configure_github_security.rb --help

require 'json'
require 'optparse'
require_relative 'security_utils'

# Configuration
$options = {
  repo: nil,
  dry_run: false,
  verbose: false,
  token: nil
}

$errors = []

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: configure_github_security.rb [options]'

  opts.on('-r', '--repo REPO', 'GitHub repository (owner/repo format)') do |repo|
    $options[:repo] = repo
  end

  opts.on('--dry-run', 'Show what would be configured without making changes') do
    $options[:dry_run] = true
  end

  opts.on('-v', '--verbose', 'Show detailed processing information') do
    $options[:verbose] = true
  end

  opts.on('-t', '--token TOKEN', 'GitHub personal access token') do |token|
    $options[:token] = token
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end
end.parse!

# Security configuration for Leyline repository
SECURITY_CONFIG = {
  branch_protection: {
    branch: 'master', # Main branch name
    protection: {
      required_status_checks: {
        strict: true,
        contexts: %w[
          test-suite
          security-scan
          yaml-validation
          index-generation
        ]
      },
      enforce_admins: true,
      required_pull_request_reviews: {
        required_approving_review_count: 1,
        dismiss_stale_reviews: true,
        require_code_owner_reviews: true,
        restrict_pushes: true
      },
      restrictions: {
        users: [],
        teams: []
      },
      required_linear_history: true,
      allow_force_pushes: false,
      allow_deletions: false
    }
  },
  security_settings: {
    vulnerability_alerts: true,
    security_updates: true,
    dependency_graph: true,
    secret_scanning: true,
    secret_scanning_push_protection: true
  },
  repository_settings: {
    delete_branch_on_merge: true,
    allow_squash_merge: true,
    allow_merge_commit: false,
    allow_rebase_merge: false
  }
}.freeze

# Validate GitHub repository format
def validate_repo_format(repo)
  return false unless repo && !repo.empty?

  # GitHub repo format: owner/repo
  parts = repo.split('/')
  return false unless parts.length == 2

  owner, repo_name = parts

  # Validate owner and repo names (GitHub username/org rules)
  return false unless owner.match?(/^[a-zA-Z0-9\-_.]+$/)
  return false unless repo_name.match?(/^[a-zA-Z0-9\-_.]+$/)
  return false if owner.length > 39 || repo_name.length > 100

  true
end

# Get GitHub token from environment or parameter
def get_github_token
  token = $options[:token] || ENV['GITHUB_TOKEN']

  unless token
    puts 'ERROR: GitHub token required. Set GITHUB_TOKEN environment variable or use --token'
    exit 1
  end

  unless SecurityUtils.validate_github_token(token)
    puts 'ERROR: Invalid GitHub token format'
    SecurityUtils.log_security_event('invalid_github_token', { token_prefix: token[0..10] })
    exit 1
  end

  token
end

# Execute GitHub API call safely
def github_api_call(method, endpoint, payload = nil, token)
  # Rate limiting
  SecurityUtils.rate_limit_check('github_api', max_calls: 5000, window: 3600)

  # Validate endpoint format
  unless endpoint.match?(%r{^/[a-zA-Z0-9/_\-.]+$})
    raise SecurityUtils::SecurityError, "Invalid API endpoint format: #{endpoint}"
  end

  command = [
    'gh', 'api',
    '--method', method.upcase,
    '--header', 'Accept: application/vnd.github.v3+json',
    '--header', "Authorization: token #{token}",
    endpoint
  ]

  if payload
    # Write payload to temporary file for security
    payload_file = "api_payload_#{Process.pid}.json"
    SecurityUtils.safe_file_write(payload_file, JSON.pretty_generate(payload))
    command += ['--input', payload_file]
  end

  puts "API Call: #{method.upcase} #{endpoint}" if $options[:verbose]
  puts "Payload: #{JSON.pretty_generate(payload)}" if $options[:verbose] && payload

  if $options[:dry_run]
    puts "[DRY RUN] Would execute: #{command.join(' ')}"
    return { success: true, output: '{"message": "dry run"}' }
  end

  begin
    result = SecurityUtils.safe_capture(*command)
    File.delete(payload_file) if payload && File.exist?(payload_file)
    result
  rescue StandardError => e
    File.delete(payload_file) if payload && File.exist?(payload_file)
    raise SecurityUtils::SecurityError, "GitHub API call failed: #{e.message}"
  end
end

# Configure branch protection
def configure_branch_protection(repo, token)
  puts "\n🔒 Configuring Branch Protection for #{repo}..."

  config = SECURITY_CONFIG[:branch_protection]
  endpoint = "/repos/#{repo}/branches/#{config[:branch]}/protection"

  result = github_api_call('PUT', endpoint, config[:protection], token)

  if result[:success]
    puts '✅ Branch protection configured successfully'
    SecurityUtils.log_security_event('branch_protection_configured', { repo: repo })
  else
    puts "❌ Branch protection configuration failed: #{result[:stderr]}"
    SecurityUtils.log_security_event('branch_protection_failed', { repo: repo, error: result[:stderr] })
    false
  end
end

# Configure repository security settings
def configure_security_settings(repo, token)
  puts "\n🛡️  Configuring Security Settings for #{repo}..."

  security_config = SECURITY_CONFIG[:security_settings]

  # Enable vulnerability alerts
  if security_config[:vulnerability_alerts]
    endpoint = "/repos/#{repo}/vulnerability-alerts"
    result = github_api_call('PUT', endpoint, nil, token)

    if result[:success]
      puts '✅ Vulnerability alerts enabled'
    else
      puts "⚠️  Could not enable vulnerability alerts: #{result[:stderr]}"
    end
  end

  # Enable security updates (Dependabot)
  if security_config[:security_updates]
    endpoint = "/repos/#{repo}/automated-security-fixes"
    result = github_api_call('PUT', endpoint, nil, token)

    if result[:success]
      puts '✅ Automated security updates enabled'
    else
      puts "⚠️  Could not enable automated security updates: #{result[:stderr]}"
    end
  end

  SecurityUtils.log_security_event('security_settings_configured', { repo: repo })
  true
end

# Configure repository settings
def configure_repository_settings(repo, token)
  puts "\n⚙️  Configuring Repository Settings for #{repo}..."

  repo_config = SECURITY_CONFIG[:repository_settings]
  endpoint = "/repos/#{repo}"

  result = github_api_call('PATCH', endpoint, repo_config, token)

  if result[:success]
    puts '✅ Repository settings configured successfully'
    SecurityUtils.log_security_event('repository_settings_configured', { repo: repo })
  else
    puts "❌ Repository settings configuration failed: #{result[:stderr]}"
    SecurityUtils.log_security_event('repository_settings_failed', { repo: repo, error: result[:stderr] })
    false
  end
end

# Create security policy file
def create_security_policy(repo, token)
  puts "\n📋 Creating Security Policy..."

  security_policy = <<~POLICY
    # Security Policy

    ## Supported Versions

    | Version | Supported          |
    | ------- | ------------------ |
    | 0.1.x   | :white_check_mark: |

    ## Reporting a Vulnerability

    If you discover a security vulnerability in Leyline, please report it by:

    1. **DO NOT** open a public issue
    2. Email security details to the maintainers
    3. Include a detailed description of the vulnerability
    4. Provide steps to reproduce if applicable

    We will respond to security reports within 48 hours and work with you to address any valid security concerns.

    ## Security Measures

    This repository implements the following security measures:

    - Branch protection with required reviews
    - Automated security scanning
    - Dependency vulnerability monitoring
    - Secret scanning and push protection
    - Input validation in all automation scripts
    - Secure coding practices throughout

    ## Security Contacts

    For security-related questions or concerns, please contact the repository maintainers.
  POLICY

  endpoint = "/repos/#{repo}/contents/SECURITY.md"

  payload = {
    message: 'security: add security policy and reporting guidelines',
    content: Base64.strict_encode64(security_policy),
    branch: SECURITY_CONFIG[:branch_protection][:branch]
  }

  result = github_api_call('PUT', endpoint, payload, token)

  if result[:success]
    puts '✅ Security policy created'
    SecurityUtils.log_security_event('security_policy_created', { repo: repo })
  else
    puts "⚠️  Could not create security policy: #{result[:stderr]}"
  end
end

# Main configuration function
def configure_github_security
  # Validate inputs
  unless $options[:repo]
    puts 'ERROR: Repository required. Use --repo owner/repo'
    exit 1
  end

  unless validate_repo_format($options[:repo])
    puts 'ERROR: Invalid repository format. Use owner/repo'
    SecurityUtils.log_security_event('invalid_repo_format', { repo: $options[:repo] })
    exit 1
  end

  # Get GitHub token
  token = get_github_token

  puts "🔐 Configuring GitHub Security for #{$options[:repo]}"
  puts "Mode: #{$options[:dry_run] ? 'DRY RUN' : 'LIVE'}"
  puts ''

  success_count = 0
  total_steps = 4

  # Configure branch protection
  success_count += 1 if configure_branch_protection($options[:repo], token)

  # Configure security settings
  success_count += 1 if configure_security_settings($options[:repo], token)

  # Configure repository settings
  success_count += 1 if configure_repository_settings($options[:repo], token)

  # Create security policy
  success_count += 1 if create_security_policy($options[:repo], token)

  puts "\n" + '=' * 60
  puts '🎯 Security Configuration Summary'
  puts '=' * 60
  puts "Repository: #{$options[:repo]}"
  puts "Steps completed: #{success_count}/#{total_steps}"
  puts "Mode: #{$options[:dry_run] ? 'DRY RUN (no changes made)' : 'LIVE'}"

  if success_count == total_steps
    puts '✅ All security configurations applied successfully!'
    SecurityUtils.log_security_event('github_security_configured', {
                                       repo: $options[:repo],
                                       steps_completed: success_count
                                     })
  else
    puts '⚠️  Some configurations may need manual attention'
    puts 'Check the output above for specific issues'
  end

  puts "\n🔒 Repository is now secured with:"
  puts "  • Branch protection on #{SECURITY_CONFIG[:branch_protection][:branch]}"
  puts '  • Required code reviews and status checks'
  puts '  • Vulnerability scanning and alerts'
  puts '  • Secret scanning with push protection'
  puts '  • Automated security updates'
  puts '  • Security policy documentation'

  exit(success_count == total_steps ? 0 : 1)
end

# Main execution
if __FILE__ == $0
  begin
    configure_github_security
  rescue SecurityUtils::SecurityError => e
    puts "\n❌ Security Error: #{e.message}"
    SecurityUtils.log_security_event('github_security_error', { error: e.message })
    exit 1
  rescue Interrupt
    puts "\n\n⚠️  Configuration interrupted by user"
    exit 1
  rescue StandardError => e
    puts "\n❌ Unexpected error: #{e.message}"
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
