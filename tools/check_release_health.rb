#!/usr/bin/env ruby
# check_release_health.rb - Monitor health of recent releases
#
# This tool checks the health and integrity of recent releases,
# helping identify issues that might require rollback.

require 'optparse'
require 'yaml'
require 'time'
require 'json'

$options = {
  version: nil,
  all: false,
  recent: 5,
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: check_release_health.rb [options]"

  opts.on("-v", "--version VERSION", "Check specific version") do |version|
    $options[:version] = version
  end

  opts.on("-a", "--all", "Check all releases") do
    $options[:all] = true
  end

  opts.on("-r", "--recent N", Integer, "Check N most recent releases (default: 5)") do |n|
    $options[:recent] = n
  end

  opts.on("--verbose", "Verbose output") do
    $options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this help message") do
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

def log_check(component, status, details = nil)
  icon = case status
  when 'healthy' then '✅'
  when 'warning' then '⚠️'
  when 'error' then '❌'
  when 'unknown' then '❓'
  end

  message = "#{icon} #{component}"
  message += ": #{details}" if details
  puts message
end

def get_releases
  # Get all tags that look like version numbers
  tags = `git tag -l 'v*' | sort -rV`.strip.split("\n")

  if $options[:version]
    # Check specific version
    version = $options[:version]
    version = "v#{version}" unless version.start_with?('v')
    tags.include?(version) ? [version] : []
  elsif $options[:all]
    tags
  else
    # Get recent releases
    tags.first($options[:recent])
  end
end

def check_version_file(version)
  log_verbose("Checking VERSION file for #{version}")

  # Get VERSION file content at the tagged commit
  version_content = `git show #{version}:VERSION 2>/dev/null`.strip

  if version_content.empty?
    log_check("VERSION file", "error", "Not found in #{version}")
    return false
  end

  expected_version = version.gsub(/^v/, '')

  if version_content == expected_version
    log_check("VERSION file", "healthy", "Matches tag (#{expected_version})")
    true
  else
    log_check("VERSION file", "error", "Mismatch - file: #{version_content}, tag: #{expected_version}")
    false
  end
end

def check_changelog(version)
  log_verbose("Checking CHANGELOG for #{version}")

  # Get CHANGELOG content at the tagged commit
  changelog = `git show #{version}:CHANGELOG.md 2>/dev/null`

  if changelog.empty?
    log_check("CHANGELOG", "warning", "Not found in #{version}")
    return true
  end

  version_string = version.gsub(/^v/, '')

  if changelog.include?("## [#{version_string}]") || changelog.include?("## #{version_string}")
    log_check("CHANGELOG", "healthy", "Contains entry for #{version}")
    true
  else
    log_check("CHANGELOG", "warning", "No entry found for #{version}")
    false
  end
end

def check_commit_message(version)
  log_verbose("Checking commit message for #{version}")

  # Get the commit message for the tag
  commit_msg = `git log -1 --pretty=%B #{version} 2>/dev/null`.strip

  if commit_msg.empty?
    log_check("Commit message", "error", "Could not retrieve")
    return false
  end

  if commit_msg.include?("release") || commit_msg.include?("Release")
    log_check("Commit message", "healthy", "Appears to be a release commit")
    true
  else
    log_check("Commit message", "warning", "May not be a release commit")
    false
  end
end

def check_github_release(version)
  log_verbose("Checking GitHub release for #{version}")

  # Check if gh CLI is available
  unless system("which gh >/dev/null 2>&1")
    log_check("GitHub release", "unknown", "GitHub CLI not available")
    return nil
  end

  # Check if release exists
  if system("gh release view #{version} >/dev/null 2>&1")
    # Get release info
    release_info = `gh release view #{version} --json isDraft,isPrerelease,createdAt 2>/dev/null`

    begin
      data = JSON.parse(release_info)

      if data['isDraft']
        log_check("GitHub release", "warning", "Still in draft state")
        return false
      elsif data['isPrerelease']
        log_check("GitHub release", "warning", "Marked as pre-release")
        return true
      else
        log_check("GitHub release", "healthy", "Published release")
        return true
      end
    rescue
      log_check("GitHub release", "error", "Could not parse release data")
      return false
    end
  else
    log_check("GitHub release", "error", "Not found")
    return false
  end
end

def check_documentation(version)
  log_verbose("Checking documentation for #{version}")

  # Check if index files exist at the tagged commit
  tenet_index = `git show #{version}:docs/tenets/00-index.md 2>/dev/null`
  binding_index = `git show #{version}:docs/bindings/00-index.md 2>/dev/null`

  issues = []

  if tenet_index.empty?
    issues << "Missing tenet index"
  end

  if binding_index.empty?
    issues << "Missing binding index"
  end

  if issues.empty?
    log_check("Documentation", "healthy", "Index files present")
    true
  else
    log_check("Documentation", "warning", issues.join(", "))
    false
  end
end

def check_tag_signature(version)
  log_verbose("Checking tag signature for #{version}")

  # Check if tag is annotated
  tag_type = `git cat-file -t #{version} 2>/dev/null`.strip

  if tag_type == "tag"
    # Get tag message
    tag_msg = `git tag -n99 #{version} | sed 's/^[^ ]* *//'`.strip

    if tag_msg && !tag_msg.empty?
      log_check("Tag signature", "healthy", "Annotated tag with message")
      true
    else
      log_check("Tag signature", "warning", "Annotated tag but no message")
      false
    end
  else
    log_check("Tag signature", "warning", "Lightweight tag (not annotated)")
    false
  end
end

def check_release_timing(version)
  log_verbose("Checking release timing for #{version}")

  # Get commit date
  commit_date = `git log -1 --format=%ai #{version} 2>/dev/null`.strip

  if commit_date.empty?
    log_check("Release timing", "unknown", "Could not determine")
    return nil
  end

  begin
    release_time = Time.parse(commit_date)
    time_ago = Time.now - release_time

    days_ago = (time_ago / 86400).round

    if days_ago == 0
      log_check("Release timing", "healthy", "Released today")
    elsif days_ago == 1
      log_check("Release timing", "healthy", "Released yesterday")
    else
      log_check("Release timing", "healthy", "Released #{days_ago} days ago")
    end

    true
  rescue
    log_check("Release timing", "error", "Could not parse date")
    false
  end
end

def generate_health_summary(results)
  total_checks = results.values.flatten.count { |r| r != nil }
  healthy_checks = results.values.flatten.count { |r| r == true }
  warning_checks = results.values.flatten.count { |r| r == false }

  health_score = (healthy_checks.to_f / total_checks * 100).round

  puts "\n" + "="*60
  puts "Release Health Summary"
  puts "="*60

  results.each do |version, checks|
    puts "\n📦 #{version}"

    total = checks.count { |_, v| v != nil }
    healthy = checks.count { |_, v| v == true }

    score = (healthy.to_f / total * 100).round

    status = if score >= 80
      "✅ Healthy"
    elsif score >= 60
      "⚠️  Warning"
    else
      "❌ Unhealthy"
    end

    puts "   Status: #{status} (#{score}% health score)"

    # List any issues
    issues = checks.select { |_, v| v == false }.keys
    if issues.any?
      puts "   Issues: #{issues.join(', ')}"
    end
  end

  puts "\n" + "="*60
  puts "Overall Health Score: #{health_score}%"

  if health_score < 80
    puts "\n⚠️  Some releases have health issues that may need attention."
    puts "Consider reviewing releases with low health scores."
  else
    puts "\n✅ All releases appear healthy."
  end
end

def check_release_health(version)
  puts "\n🔍 Checking health of #{version}..."

  checks = {
    version_file: check_version_file(version),
    changelog: check_changelog(version),
    commit_message: check_commit_message(version),
    github_release: check_github_release(version),
    documentation: check_documentation(version),
    tag_signature: check_tag_signature(version),
    timing: check_release_timing(version)
  }

  checks
end

# Main execution
releases = get_releases

if releases.empty?
  log_info("No releases found to check")
  exit 0
end

log_info("Checking health of #{releases.size} release(s)")

results = {}

releases.each do |version|
  results[version] = check_release_health(version)
end

generate_health_summary(results)
