#!/usr/bin/env ruby
# tools/run_advisory_checks.rb - Optional comprehensive validation for interested authors
#
# This script provides comprehensive validation feedback for authors who want detailed
# analysis of their documentation work. All checks are ADVISORY ONLY - failures provide
# feedback but never block development workflow.
#
# Purpose: Enable authors to get comprehensive feedback when they want it, without
# making such feedback mandatory or blocking.
#
# Philosophy:
# - Available but not required
# - Never blocks development
# - Informational feedback only
# - Completely separate from CI requirements
#
# Advisory checks included:
# 1. Cross-reference link validation
# 2. TypeScript binding compilation validation
# 3. Security scanning (gitleaks)
# 4. Dependency security auditing
# 5. Document length validation
# 6. External link validation
# 7. Python code example validation (if enabled)
#
# Requirements:
# - Ruby 2.1+
# - Optional: gitleaks (for security scanning)
# - Optional: Node.js + markdown-link-check (for external links)
# - Optional: pnpm (for dependency auditing)
#
# Usage:
# - Full advisory validation: ruby tools/run_advisory_checks.rb
# - Verbose output: ruby tools/run_advisory_checks.rb --verbose
# - Skip specific checks: ruby tools/run_advisory_checks.rb --skip-security --skip-links

require 'time'
require 'json'
require 'fileutils'
require 'optparse'

# Configuration
$verbose = false
$skip_security = false
$skip_links = false
$skip_typescript = false
$skip_dependencies = false

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: run_advisory_checks.rb [options]'
  opts.separator ''
  opts.separator 'Advisory validation script for authors who want comprehensive feedback'
  opts.separator ''
  opts.separator '⚠️  IMPORTANT: All checks are ADVISORY ONLY - failures provide feedback but never block development'
  opts.separator ''
  opts.separator 'Options:'

  opts.on('-v', '--verbose', 'Show detailed output from validation tools') do
    $verbose = true
  end

  opts.on('--skip-security', 'Skip security scanning checks') do
    $skip_security = true
  end

  opts.on('--skip-links', 'Skip external link validation') do
    $skip_links = true
  end

  opts.on('--skip-typescript', 'Skip TypeScript binding validation') do
    $skip_typescript = true
  end

  opts.on('--skip-dependencies', 'Skip dependency security auditing') do
    $skip_dependencies = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end

  opts.separator ''
  opts.separator 'Exit Codes:'
  opts.separator '  0 - Script completed (advisory checks may have findings)'
  opts.separator '  1 - Script execution error (not advisory check failure)'
  opts.separator ''
  opts.separator 'Remember: This script provides ADVISORY feedback only.'
  opts.separator 'Findings are informational and never block development workflow.'
end.parse!

def run_advisory_command(command, description)
  puts "🔍 #{description}..."
  start_time = Time.now

  # Run command and capture output
  if $verbose
    puts "   Command: #{command}"
    success = system(command)
  else
    success = system(command, out: '/dev/null', err: '/dev/null')
  end

  duration = (Time.now - start_time).round(3)

  if success
    puts "✅ #{description} - no issues found (#{duration}s)"
    { status: :clean, duration: duration }
  else
    exit_code = $?.exitstatus
    puts "📋 #{description} - findings available (#{duration}s)"
    puts "   💡 Run manually for details: #{command}"
    { status: :findings, duration: duration, exit_code: exit_code }
  end
end

def check_tool_available(tool, install_hint = nil)
  return true if system("command -v #{tool} >/dev/null 2>&1")

  puts "⚠️  #{tool} not available"
  puts "   #{install_hint}" if install_hint
  false
end

def main
  puts '🔍 Advisory Validation for Authors'
  puts '================================='
  puts 'All checks are ADVISORY ONLY - findings provide feedback but never block development'
  puts ''

  start_time = Time.now
  findings_summary = []

  # Advisory Check 1: Cross-reference validation
  puts '📋 Cross-reference link validation (advisory)...'
  result = run_advisory_command(
    "ruby tools/validate_cross_references.rb#{$verbose ? ' -v' : ''}",
    'Cross-reference validation'
  )
  findings_summary << { check: 'Cross-references', **result }

  # Advisory Check 2: Document length validation
  puts ''
  puts '📏 Document length validation (advisory)...'
  result = run_advisory_command(
    "ruby tools/check_document_length.rb#{$verbose ? ' -v' : ''}",
    'Document length validation'
  )
  findings_summary << { check: 'Document length', **result }

  # Advisory Check 3: TypeScript binding validation
  if $skip_typescript
    puts '⏭️  Skipping TypeScript validation (--skip-typescript)'
  else
    puts ''
    if Dir.exist?('docs/bindings/categories/typescript')
      puts '📋 TypeScript binding validation (advisory)...'
      result = run_advisory_command(
        "ruby tools/validate_typescript_bindings.rb#{$verbose ? ' --verbose' : ''}",
        'TypeScript binding compilation'
      )
      findings_summary << { check: 'TypeScript bindings', **result }
    else
      puts '⏭️  No TypeScript bindings found - skipping TypeScript validation'
    end
  end

  # Advisory Check 4: Security scanning
  if $skip_security
    puts '⏭️  Skipping security scanning (--skip-security)'
  else
    puts ''
    puts '🔒 Security scanning (advisory)...'

    if check_tool_available('gitleaks', 'Install from https://github.com/gitleaks/gitleaks')
      result = run_advisory_command(
        'gitleaks detect --source=. --no-git',
        'Security scan (gitleaks)'
      )
      findings_summary << { check: 'Security scan', **result }
    else
      puts '   ⏭️ Skipping security scan (gitleaks not available)'
    end
  end

  # Advisory Check 5: Dependency security auditing
  if $skip_dependencies
    puts '⏭️  Skipping dependency audit (--skip-dependencies)'
  else
    puts ''
    if File.exist?('examples/typescript-full-toolchain/package.json')
      puts '🔐 Dependency security audit (advisory)...'
      Dir.chdir('examples/typescript-full-toolchain') do
        result = run_advisory_command(
          'pnpm audit --audit-level=moderate',
          'Dependency security audit'
        )
        findings_summary << { check: 'Dependency audit', **result }
      end
    else
      puts '⏭️  No TypeScript example project found - skipping dependency audit'
    end
  end

  # Advisory Check 6: External link validation
  if $skip_links
    puts '⏭️  Skipping external link validation (--skip-links)'
  else
    puts ''
    puts '📡 External link validation (advisory)...'

    if check_tool_available('node') && check_tool_available('npm')
      if system('npm list -g markdown-link-check >/dev/null 2>&1')
        result = run_advisory_command(
          "find . -name '*.md' | grep -v 'node_modules\\|venv\\|site' | xargs markdown-link-check -q",
          'External link validation'
        )
        findings_summary << { check: 'External links', **result }
      else
        puts '   ⚠️  markdown-link-check not installed'
        puts '   Install with: npm install -g markdown-link-check'
      end
    else
      puts '   ⏭️ Skipping external links (Node.js/npm not available)'
    end
  end

  # Advisory Check 7: Python code validation (if available)
  if File.exist?('tools/validate_python_examples.rb')
    puts ''
    puts '🐍 Python code example validation (advisory)...'
    result = run_advisory_command(
      "ruby tools/validate_python_examples.rb#{$verbose ? ' -v' : ''}",
      'Python code examples'
    )
    findings_summary << { check: 'Python examples', **result }
  end

  # Summary
  total_duration = (Time.now - start_time).round(3)
  puts ''
  puts '📊 Advisory Validation Summary'
  puts '============================='

  clean_checks = findings_summary.select { |check| check[:status] == :clean }
  findings_checks = findings_summary.select { |check| check[:status] == :findings }

  if findings_checks.empty?
    puts '✨ All advisory checks clean!'
    puts '🎉 No findings in comprehensive validation'
  else
    puts '📋 Advisory findings summary:'
    findings_checks.each do |check|
      puts "   • #{check[:check]}: findings available"
    end
    puts ''
    puts '💡 Findings are informational feedback, not blockers'
    puts '💡 Run with --verbose or individual tools for details'
  end

  puts ''
  puts '📈 Performance summary:'
  puts "   • Total checks run: #{findings_summary.length}"
  puts "   • Clean checks: #{clean_checks.length}"
  puts "   • Checks with findings: #{findings_checks.length}"
  puts "   • Total time: #{total_duration}s"

  puts ''
  puts '⚠️  Remember: All findings are ADVISORY ONLY'
  puts '🚀 Development workflow is never blocked by advisory validation'
  puts '📝 Use findings to improve content quality when desired'

  # Always exit 0 - advisory validation never fails the script
  exit 0
end

# Run main function
main
