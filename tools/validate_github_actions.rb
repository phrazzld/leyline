#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'optparse'

# GitHub Actions Deprecation Validator
# Prevents CI failures by detecting deprecated action versions in workflow files
class GitHubActionsValidator
  WORKFLOW_GLOB = '.github/workflows/*.yml'
  DEPRECATIONS_FILE = 'tools/github-actions-deprecations.yml'

  def initialize(verbose: false)
    @verbose = verbose
    @deprecations = load_deprecations
    @findings = []
  end

  def validate
    workflow_files = Dir.glob(WORKFLOW_GLOB)

    if workflow_files.empty?
      puts "No GitHub workflow files found in #{WORKFLOW_GLOB}" if @verbose
      return true
    end

    workflow_files.each { |file| validate_workflow(file) }

    report_findings
    @findings.empty?
  end

  private

  def load_deprecations
    return {} unless File.exist?(DEPRECATIONS_FILE)

    YAML.safe_load(File.read(DEPRECATIONS_FILE)) || {}
  rescue StandardError => e
    puts "Warning: Could not load deprecations file: #{e.message}" if @verbose
    {}
  end

  def validate_workflow(file_path)
    content = File.read(file_path)
    lines = content.lines

    lines.each_with_index do |line, index|
      next unless line.strip.start_with?('uses:')

      action_match = line.match(/uses:\s*([^@\s]+@[^\s]+)/)
      next unless action_match

      action_ref = action_match[1].strip
      check_action_deprecation(action_ref, file_path, index + 1)
    end
  rescue StandardError => e
    @findings << {
      file: file_path,
      line: 0,
      severity: 'error',
      message: "Failed to parse workflow file: #{e.message}"
    }
  end

  def check_action_deprecation(action_ref, file_path, line_number)
    deprecation = @deprecations[action_ref]
    return unless deprecation

    @findings << {
      file: file_path,
      line: line_number,
      action: action_ref,
      severity: deprecation['severity'] || 'medium',
      reason: deprecation['reason'],
      upgrade_to: deprecation['upgrade_to'],
      deprecated_since: deprecation['deprecated_since']
    }
  end

  def report_findings
    if @findings.empty?
      puts '✅ GitHub Actions deprecation check passed' if @verbose
      return
    end

    puts '❌ GitHub Actions deprecation issues found:'
    puts

    @findings.each do |finding|
      severity_icon = severity_icon(finding[:severity])

      puts "#{severity_icon} #{finding[:file]}:#{finding[:line]}"
      puts "  Action: #{finding[:action]}"
      puts "  Severity: #{finding[:severity].upcase}"
      puts "  Reason: #{finding[:reason]}" if finding[:reason]

      puts "  🔧 Upgrade to: #{finding[:upgrade_to]}" if finding[:upgrade_to]

      puts "  Deprecated since: #{finding[:deprecated_since]}" if finding[:deprecated_since]
      puts
    end

    puts '💡 Update your workflow files to use supported action versions'
  end

  def severity_icon(severity)
    case severity.to_s.downcase
    when 'high', 'error'
      '🚨'
    when 'medium', 'warning'
      '⚠️'
    when 'low', 'info'
      'ℹ️'
    else
      '❌'
    end
  end
end

# CLI interface
if __FILE__ == $PROGRAM_NAME
  options = { verbose: false }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
    opts.on('-v', '--verbose', 'Enable verbose output') { options[:verbose] = true }
    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit
    end
  end.parse!

  validator = GitHubActionsValidator.new(verbose: options[:verbose])
  success = validator.validate

  exit(success ? 0 : 1)
end
