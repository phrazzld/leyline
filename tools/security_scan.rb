#!/usr/bin/env ruby
# tools/security_scan.rb - Security vulnerability scanner for Leyline tools
#
# This script performs comprehensive security scanning of Ruby scripts to detect:
# - Hardcoded secrets and credentials
# - Shell injection vulnerabilities
# - File path traversal attempts
# - Unsafe YAML loading
# - Insecure system calls
# - Input validation gaps
#
# Usage:
#   ruby tools/security_scan.rb
#   ruby tools/security_scan.rb --format json
#   ruby tools/security_scan.rb --strict

require 'optparse'
require 'json'
require 'digest'
require_relative 'security_utils'

# Configuration
$options = {
  format: 'text',
  strict: false,
  verbose: false,
  output_file: nil
}

$scan_results = {
  summary: {
    files_scanned: 0,
    total_issues: 0,
    critical_issues: 0,
    high_issues: 0,
    medium_issues: 0,
    low_issues: 0,
    scan_time: nil
  },
  issues: []
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: security_scan.rb [options]"

  opts.on("-f", "--format FORMAT", "Output format (text, json)") do |format|
    $options[:format] = format
  end

  opts.on("--strict", "Fail on any security issues found") do
    $options[:strict] = true
  end

  opts.on("-v", "--verbose", "Show detailed scanning information") do
    $options[:verbose] = true
  end

  opts.on("-o", "--output FILE", "Write results to file") do |file|
    $options[:output_file] = file
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end.parse!

# Security issue structure
class SecurityIssue
  attr_reader :severity, :type, :message, :file, :line, :code, :recommendation

  def initialize(severity:, type:, message:, file:, line: nil, code: nil, recommendation: nil)
    @severity = severity
    @type = type
    @message = message
    @file = file
    @line = line
    @code = code
    @recommendation = recommendation
  end

  def to_hash
    {
      severity: @severity,
      type: @type,
      message: @message,
      file: @file,
      line: @line,
      code: @code&.strip,
      recommendation: @recommendation
    }.compact
  end
end

# Security patterns to detect
SECURITY_PATTERNS = {
  # Hardcoded secrets
  secrets: {
    severity: 'critical',
    patterns: [
      {
        regex: /(?:password|passwd|pwd)\s*[:=]\s*['"][^'"\s]+['"]/i,
        message: 'Hardcoded password detected',
        recommendation: 'Use environment variables or secure credential storage'
      },
      {
        regex: /(?:api[_-]?key|apikey|access[_-]?key)\s*[:=]\s*['"][^'"\s]+['"]/i,
        message: 'Hardcoded API key detected',
        recommendation: 'Use environment variables or secure credential storage'
      },
      {
        regex: /(?:secret|token)\s*[:=]\s*['"][^'"\s]{20,}['"]/i,
        message: 'Hardcoded secret/token detected',
        recommendation: 'Use environment variables or secure credential storage'
      },
      {
        regex: /gh[ps]_[a-zA-Z0-9]{36}/,
        message: 'GitHub token detected in code',
        recommendation: 'Use GITHUB_TOKEN environment variable'
      }
    ]
  },

  # Shell injection vulnerabilities
  shell_injection: {
    severity: 'high',
    patterns: [
      {
        regex: /system\s*\(\s*['"][^'"]*#\{[^}]*\}[^'"]*['"]\s*\)/,
        message: 'Shell injection vulnerability in system() call with interpolation',
        recommendation: 'Use SecurityUtils.safe_system() with parameter arrays'
      },
      {
        regex: /`[^`]*#\{[^}]*\}[^`]*`/,
        message: 'Shell injection vulnerability in backtick execution with interpolation',
        recommendation: 'Use SecurityUtils.safe_capture() with parameter arrays'
      },
      {
        regex: /exec\s*\(\s*['"][^'"]*#\{[^}]*\}[^'"]*['"]\s*\)/,
        message: 'Shell injection vulnerability in exec() call with interpolation',
        recommendation: 'Use SecurityUtils.safe_system() with parameter arrays'
      },
      {
        regex: /Open3\.(capture2|capture3|popen3)\s*\(\s*['"][^'"]*#\{[^}]*\}[^'"]*['"]/,
        message: 'Shell injection vulnerability in Open3 call with interpolation',
        recommendation: 'Use SecurityUtils.safe_git_command() for git operations'
      }
    ]
  },

  # File path traversal
  path_traversal: {
    severity: 'high',
    patterns: [
      {
        regex: /File\.(read|write|open|delete)\s*\(\s*['"][^'"]*#\{[^}]*\}[^'"]*['"]/,
        message: 'Potential path traversal in file operation with interpolation',
        recommendation: 'Validate file paths with SecurityUtils.validate_file_path()'
      },
      {
        regex: /['"][^'"]*\.\.\/[^'"]*['"]/,
        message: 'Directory traversal pattern detected',
        recommendation: 'Use absolute paths or validate with SecurityUtils.validate_file_path()'
      }
    ]
  },

  # Unsafe YAML loading
  unsafe_yaml: {
    severity: 'high',
    patterns: [
      {
        regex: /YAML\.load(?!_file\s*\(|.*safe_load)/,
        message: 'Unsafe YAML.load() can execute arbitrary code',
        recommendation: 'Use YAML.safe_load() with restricted classes'
      },
      {
        regex: /YAML\.load_file\s*\([^)]*\)\s*(?!.*safe_load)/,
        message: 'YAML.load_file() can execute arbitrary code',
        recommendation: 'Use YAML.safe_load() with file content'
      }
    ]
  },

  # Insecure randomness
  weak_random: {
    severity: 'medium',
    patterns: [
      {
        regex: /rand\s*\(/,
        message: 'Weak random number generation',
        recommendation: 'Use SecureRandom for cryptographic purposes'
      },
      {
        regex: /srand\s*\(/,
        message: 'Predictable random seed',
        recommendation: 'Use SecureRandom for cryptographic purposes'
      }
    ]
  },

  # Information disclosure
  info_disclosure: {
    severity: 'medium',
    patterns: [
      {
        regex: /puts\s+[^'"]*\.backtrace/,
        message: 'Stack trace printed to output',
        recommendation: 'Log detailed errors securely, show generic messages to users'
      },
      {
        regex: /raise\s+.*#\{.*password.*\}/i,
        message: 'Sensitive information in exception message',
        recommendation: 'Avoid including sensitive data in error messages'
      }
    ]
  },

  # Unsafe network operations
  unsafe_network: {
    severity: 'medium',
    patterns: [
      {
        regex: /Net::HTTP\.get\s*\(\s*['"][^'"]*#\{[^}]*\}[^'"]*['"]/,
        message: 'HTTP request with interpolated URL',
        recommendation: 'Validate URLs and use allowlists for external requests'
      },
      {
        regex: /open\s*\(\s*['"]https?:\/\/[^'"]*#\{[^}]*\}[^'"]*['"]/,
        message: 'URL opening with interpolated content',
        recommendation: 'Validate URLs and use allowlists for external requests'
      }
    ]
  }
}.freeze

# Scan a single file for security issues
def scan_file(file_path)
  puts "Scanning: #{file_path}" if $options[:verbose]

  begin
    content = File.read(file_path)
    lines = content.lines
    issues = []

    # Scan each pattern category
    SECURITY_PATTERNS.each do |category, config|
      config[:patterns].each do |pattern|
        lines.each_with_index do |line, index|
          if line.match?(pattern[:regex])
            issue = SecurityIssue.new(
              severity: config[:severity],
              type: category.to_s,
              message: pattern[:message],
              file: file_path,
              line: index + 1,
              code: line.chomp,
              recommendation: pattern[:recommendation]
            )
            issues << issue

            SecurityUtils.log_security_event('security_issue_detected', {
              file: file_path,
              line: index + 1,
              type: category,
              severity: config[:severity]
            })
          end
        end
      end
    end

    issues
  rescue => e
    puts "Warning: Could not scan #{file_path}: #{e.message}" if $options[:verbose]
    []
  end
end

# Discover Ruby files to scan
def discover_ruby_files
  patterns = ['tools/*.rb', 'lib/**/*.rb', 'scripts/*.rb']
  files = []

  patterns.each do |pattern|
    files.concat(Dir.glob(pattern))
  end

  # Filter out test files and this scanner itself
  files.reject! do |file|
    File.basename(file).start_with?('test_') ||
    File.basename(file) == 'security_scan.rb'
  end

  files.sort
end

# Add issue to results
def add_issue(issue)
  $scan_results[:issues] << issue.to_hash
  $scan_results[:summary][:total_issues] += 1

  case issue.severity
  when 'critical'
    $scan_results[:summary][:critical_issues] += 1
  when 'high'
    $scan_results[:summary][:high_issues] += 1
  when 'medium'
    $scan_results[:summary][:medium_issues] += 1
  when 'low'
    $scan_results[:summary][:low_issues] += 1
  end
end

# Format text output
def format_text_output
  output = []

  output << "# Security Scan Report"
  output << ""
  output << "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  output << ""

  summary = $scan_results[:summary]

  output << "## Summary"
  output << ""
  output << "**Files Scanned:** #{summary[:files_scanned]}"
  output << "**Total Issues:** #{summary[:total_issues]}"
  output << "**Scan Time:** #{summary[:scan_time]&.round(2)}s"
  output << ""

  if summary[:total_issues] == 0
    output << "✅ **No security issues detected!**"
    output << ""
    output << "All scanned files passed security validation."
  else
    output << "### Issue Breakdown"
    output << ""
    output << "- **Critical:** #{summary[:critical_issues]} 🔴"
    output << "- **High:** #{summary[:high_issues]} 🟠"
    output << "- **Medium:** #{summary[:medium_issues]} 🟡"
    output << "- **Low:** #{summary[:low_issues]} 🔵"
    output << ""

    # Group issues by severity
    %w[critical high medium low].each do |severity|
      severity_issues = $scan_results[:issues].select { |i| i[:severity] == severity }
      next if severity_issues.empty?

      output << "## #{severity.capitalize} Issues"
      output << ""

      severity_issues.each do |issue|
        output << "### #{issue[:message]}"
        output << ""
        output << "**File:** #{issue[:file]}"
        output << "**Line:** #{issue[:line]}" if issue[:line]
        output << "**Type:** #{issue[:type]}"
        output << ""

        if issue[:code]
          output << "**Code:**"
          output << "```ruby"
          output << issue[:code]
          output << "```"
          output << ""
        end

        if issue[:recommendation]
          output << "**Recommendation:**"
          output << issue[:recommendation]
          output << ""
        end

        output << "---"
        output << ""
      end
    end
  end

  output.join("\n")
end

# Format JSON output
def format_json_output
  JSON.pretty_generate($scan_results)
end

# Write output to file or stdout
def write_output(content)
  if $options[:output_file]
    File.write($options[:output_file], content)
    puts "Security scan report written to #{$options[:output_file]}"
  else
    puts content
  end
end

# Main scanning function
def run_security_scan
  start_time = Time.now

  # Discover files to scan
  files = discover_ruby_files

  if files.empty?
    puts "No Ruby files found to scan"
    exit 0
  end

  puts "🔍 Security scanning #{files.length} Ruby files..." unless $options[:format] == 'json'

  # Scan each file
  files.each do |file|
    $scan_results[:summary][:files_scanned] += 1
    issues = scan_file(file)
    issues.each { |issue| add_issue(issue) }
  end

  $scan_results[:summary][:scan_time] = Time.now - start_time

  # Format output
  content = case $options[:format]
  when 'json'
    format_json_output
  else
    format_text_output
  end

  # Write results
  write_output(content)

  # Exit with appropriate code
  if $options[:strict] && $scan_results[:summary][:total_issues] > 0
    puts "\n❌ Security scan failed in strict mode (#{$scan_results[:summary][:total_issues]} issues found)" unless $options[:format] == 'json'
    exit 1
  elsif $scan_results[:summary][:critical_issues] > 0 || $scan_results[:summary][:high_issues] > 0
    puts "\n⚠️  Critical or high severity security issues found" unless $options[:format] == 'json'
    exit 1
  else
    puts "\n✅ Security scan completed successfully" unless $options[:format] == 'json'
    exit 0
  end
end

# Main execution
if __FILE__ == $0
  begin
    run_security_scan
  rescue Interrupt
    puts "\n\n⚠️  Security scan interrupted by user"
    exit 1
  rescue => e
    puts "\n❌ Security scan error: #{e.message}"
    puts e.backtrace.join("\n") if $options[:verbose]
    exit 1
  end
end
