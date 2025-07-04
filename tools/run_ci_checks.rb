#!/usr/bin/env ruby
# tools/run_ci_checks.rb - Local CI simulation script
# Replicates CI validation pipeline locally to catch issues before remote execution
#
# This script supports two validation modes:
# Essential mode: Fast validation for daily development (YAML + Index)
# Full mode: Comprehensive validation including advisory checks
#
# Essential validation steps:
# 1. YAML front-matter validation
# 2. Index consistency check
#
# Full validation steps (additional):
# 3. Cross-reference validation (advisory)
# 4. TypeScript binding validation (advisory)
# 5. Security scanning (advisory)
# 6. Optional external link checking (if markdown-link-check available)
#
# Requirements:
# - Ruby 2.1+ (for Time.now.iso8601 and JSON support)
# - Standard library: time, json, fileutils, optparse
# - Optional: Node.js with markdown-link-check for external link validation
#
# Usage:
# - Full validation: ruby tools/run_ci_checks.rb
# - Skip external links: ruby tools/run_ci_checks.rb --skip-external-links
# - Verbose output: ruby tools/run_ci_checks.rb --verbose

require 'time'
require 'json'
require 'fileutils'
require 'optparse'

# Configuration for structured logging
$structured_logging = ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
$correlation_id = "ci-simulation-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{rand(1000)}"
$verbose = false
$skip_external_links = false
$validation_mode = :full # :essential or :full

# Parse command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: run_ci_checks.rb [options]'
  opts.separator ''
  opts.separator 'Local CI simulation script with essential and full validation modes'
  opts.separator ''
  opts.separator 'Validation Modes:'
  opts.separator '  --essential  Fast validation for daily development (YAML + Index only)'
  opts.separator '  --full       Comprehensive validation including advisory checks (default)'
  opts.separator ''
  opts.separator 'Options:'

  opts.on('--essential', 'Run essential validation only (YAML + Index, ~10 seconds)') do
    $validation_mode = :essential
  end

  opts.on('--full', 'Run full validation including advisory checks (default)') do
    $validation_mode = :full
  end

  opts.on('--skip-external-links', 'Skip external link checking (faster execution)') do
    $skip_external_links = true
  end

  opts.on('-v', '--verbose', 'Show detailed output from validation tools') do
    $verbose = true
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit 0
  end

  opts.separator ''
  opts.separator 'Environment Variables:'
  opts.separator '  LEYLINE_STRUCTURED_LOGGING=true  Enable JSON structured logging to STDERR'
  opts.separator ''
  opts.separator 'Exit Codes:'
  opts.separator '  0 - All validations passed'
  opts.separator '  1 - One or more validations failed'
end.parse!

def log_structured(event, data = {})
  return unless $structured_logging

  begin
    log_entry = {
      event: event,
      correlation_id: $correlation_id,
      timestamp: Time.now.iso8601,
      **data
    }

    warn JSON.generate(log_entry)
  rescue StandardError => e
    # Graceful degradation if structured logging fails
    warn "Warning: Structured logging failed: #{e.message}"
  end
end

def run_command(command, description, required: true)
  log_structured('validation_step_start', {
                   step: description,
                   command: command,
                   required: required
                 })

  puts "🔄 #{description}..."
  start_time = Time.now

  # Set structured logging environment for validation tools
  env = ENV.to_h.merge('LEYLINE_STRUCTURED_LOGGING' => $structured_logging.to_s)

  # Run command and capture output
  success = if $verbose
              system(env, command)
            else
              system(env, command, out: '/dev/null', err: '/dev/null')
            end

  duration = (Time.now - start_time).round(3)

  if success
    puts "✅ #{description} passed (#{duration}s)"
    log_structured('validation_step_success', {
                     step: description,
                     duration_seconds: duration
                   })
    true
  else
    exit_code = $?.exitstatus
    puts "❌ #{description} failed (exit code #{exit_code})"
    log_structured('validation_step_failure', {
                     step: description,
                     duration_seconds: duration,
                     exit_code: exit_code
                   })

    if required
      puts '   💡 Run the command manually for detailed error output:'
      puts "   #{command}"
    end

    false
  end
end

def check_tool_availability(tool, install_hint = nil)
  if system("command -v #{tool} >/dev/null 2>&1")
    puts "✅ #{tool} is available"
    true
  else
    puts "⚠️  #{tool} not found"
    puts "   #{install_hint}" if install_hint
    false
  end
end

def main
  log_structured('ci_simulation_start', {
                   tool: 'run_ci_checks',
                   validation_mode: $validation_mode,
                   verbose: $verbose,
                   skip_external_links: $skip_external_links
                 })

  puts '🚀 Local CI Validation Pipeline'
  puts '================================'
  puts "Mode: #{$validation_mode.to_s.capitalize} validation"
  puts "Correlation ID: #{$correlation_id}"
  puts "Structured Logging: #{$structured_logging ? 'enabled' : 'disabled'}"
  puts ''

  start_time = Time.now
  failed_validations = []

  # Step 1: YAML front-matter validation
  command = "ruby tools/validate_front_matter.rb#{$verbose ? ' -v' : ''}"
  failed_validations << 'YAML validation' unless run_command(command, 'YAML front-matter validation')

  # Step 2: Cross-reference validation (full mode only, advisory)
  if $validation_mode == :full
    puts ''
    puts '📋 Advisory validation (non-blocking)...'
    command = "ruby tools/validate_cross_references.rb#{$verbose ? ' -v' : ''}"
    unless run_command(command, 'Cross-reference validation (advisory)', required: false)
      puts '   ⚠️  Cross-reference issues found, but continuing (advisory only)'
      puts "   💡 Run 'ruby tools/fix_cross_references.rb' to fix common issues"
    end
  else
    puts '⏭️  Skipping cross-reference validation (essential mode)'
    log_structured('validation_step_skipped', {
                     step: 'Cross-reference validation',
                     reason: 'essential_mode'
                   })
  end

  # Step 3: Index consistency check
  puts '🔄 Index consistency validation...'
  index_start = Time.now

  # First run reindex to check for errors
  if run_command('ruby tools/reindex.rb --strict', 'Index generation check')
    # Then check if index file would change
    if system('git diff --exit-code docs/bindings/00-index.md >/dev/null 2>&1')
      duration = (Time.now - index_start).round(3)
      puts "✅ Index consistency validation passed (#{duration}s)"
      log_structured('validation_step_success', {
                       step: 'Index consistency validation',
                       duration_seconds: duration
                     })
    else
      duration = (Time.now - index_start).round(3)
      puts "❌ Index file is out of date (#{duration}s)"
      puts "   💡 Run 'ruby tools/reindex.rb' to update the index file"
      log_structured('validation_step_failure', {
                       step: 'Index consistency validation',
                       duration_seconds: duration,
                       reason: 'index_file_outdated'
                     })
      failed_validations << 'Index consistency'
    end
  else
    failed_validations << 'Index generation'
  end

  # Step 4: TypeScript binding configuration validation (full mode only, advisory)
  if $validation_mode == :full
    if Dir.exist?('docs/bindings/categories/typescript')
      command = "ruby tools/validate_typescript_bindings.rb#{$verbose ? ' --verbose' : ''}"
      unless run_command(command, 'TypeScript binding validation (advisory)', required: false)
        puts '   ⚠️  TypeScript binding issues found, but continuing (advisory only)'
        puts '   💡 Educational examples prioritize clarity over compilation perfection'
      end
    else
      puts '⏭️  Skipping TypeScript binding validation (no TypeScript bindings found)'
      log_structured('validation_step_skipped', {
                       step: 'TypeScript binding validation',
                       reason: 'no_typescript_bindings'
                     })
    end
  else
    puts '⏭️  Skipping TypeScript binding validation (essential mode)'
    log_structured('validation_step_skipped', {
                     step: 'TypeScript binding validation',
                     reason: 'essential_mode'
                   })
  end

  # Step 5: Security scanning (gitleaks, full mode only, advisory)
  if $validation_mode == :full
    puts ''
    puts '🔒 Security scanning (advisory)...'

    if check_tool_availability('gitleaks', 'Install gitleaks from https://github.com/gitleaks/gitleaks')
      # Scan current working directory files (not git history to avoid false positives)
      command = 'gitleaks detect --source=. --no-git'
      unless run_command(command, 'Security scan (gitleaks) - advisory', required: false)
        puts '   ⚠️  Security scanning found issues, but continuing (advisory only)'
        puts '   💡 Educational examples may contain patterns that trigger false positives'
      end
    else
      puts '   ⏭️ Skipping security scan (gitleaks not available)'
      log_structured('validation_step_skipped', {
                       step: 'Security scan',
                       reason: 'gitleaks_not_available'
                     })
    end
  else
    puts '⏭️  Skipping security scanning (essential mode)'
    log_structured('validation_step_skipped', {
                     step: 'Security scan',
                     reason: 'essential_mode'
                   })
  end

  # Step 6: Security audit for TypeScript projects (full mode only, advisory)
  if $validation_mode == :full
    if File.exist?('examples/typescript-full-toolchain/package.json')
      puts ''
      puts '🔐 Security audit (advisory)...'
      Dir.chdir('examples/typescript-full-toolchain') do
        command = 'pnpm audit --audit-level=moderate'
        unless run_command(command, 'Security audit (pnpm) - advisory', required: false)
          puts '   ⚠️  Dependency security issues found, but continuing (advisory only)'
          puts '   💡 Example projects are for education, not production deployment'
        end
      end
    else
      puts '⏭️  Skipping security audit (no TypeScript example project found)'
      log_structured('validation_step_skipped', {
                       step: 'Security audit',
                       reason: 'no_typescript_example'
                     })
    end
  else
    puts '⏭️  Skipping dependency security audit (essential mode)'
    log_structured('validation_step_skipped', {
                     step: 'Security audit',
                     reason: 'essential_mode'
                   })
  end

  # Step 7: GitHub Actions validation (both modes)
  puts ''
  puts '🔍 GitHub Actions validation...'

  if File.exist?('tools/validate_github_actions.rb')
    command = "ruby tools/validate_github_actions.rb#{$verbose ? ' --verbose' : ''}"
    failed_validations << 'GitHub Actions validation' unless run_command(command, 'GitHub Actions deprecation check')
  else
    puts '   ⏭️ Skipping GitHub Actions validation (validation tool not found)'
    log_structured('validation_step_skipped', {
                     step: 'GitHub Actions validation',
                     reason: 'tool_not_found'
                   })
  end

  # Step 8: External link checking (full mode only)
  if $validation_mode == :full && !$skip_external_links
    puts ''
    puts '📡 Checking external link validation tool availability...'

    if check_tool_availability('node', 'Install Node.js from https://nodejs.org/') &&
       check_tool_availability('npm', 'Install npm (usually comes with Node.js)')

      # Check if markdown-link-check is installed
      if system('npm list -g markdown-link-check >/dev/null 2>&1')
        puts '✅ markdown-link-check is available'

        command = "find . -name '*.md' | grep -v 'node_modules\\|venv\\|site' | xargs markdown-link-check -q -c ./.mlc-config"
        unless run_command(command, 'External link validation', required: false)
          failed_validations << 'External link validation'
        end
      else
        puts '⚠️  markdown-link-check not installed globally'
        puts '   Install with: npm install -g markdown-link-check'
        puts '   Skipping external link validation'

        log_structured('validation_step_skipped', {
                         step: 'External link validation',
                         reason: 'tool_not_installed'
                       })
      end
    else
      puts '   Skipping external link validation (Node.js/npm not available)'
      log_structured('validation_step_skipped', {
                       step: 'External link validation',
                       reason: 'nodejs_not_available'
                     })
    end
  elsif $validation_mode == :essential
    puts '⏭️  Skipping external link validation (essential mode)'
    log_structured('validation_step_skipped', {
                     step: 'External link validation',
                     reason: 'essential_mode'
                   })
  else
    puts '⏭️  Skipping external link validation (--skip-external-links)'
    log_structured('validation_step_skipped', {
                     step: 'External link validation',
                     reason: 'user_requested_skip'
                   })
  end

  # Summary
  total_duration = (Time.now - start_time).round(3)
  puts ''
  puts '📊 Validation Summary'
  puts '==================='

  if failed_validations.empty?
    puts '✅ All validations passed!'
    puts '🎉 Your changes are ready for CI'
    puts "⏱️  Total time: #{total_duration}s"

    # Calculate validations run based on mode
    if $validation_mode == :essential
      validations_count = 3  # YAML, index, GitHub Actions (essential mode)
    else
      validations_count = 4  # YAML, cross-reference, index, GitHub Actions (full mode)
      # TypeScript validation (full mode only)
      validations_count += 1 if Dir.exist?('docs/bindings/categories/typescript')
      validations_count += 1 if system('command -v gitleaks >/dev/null 2>&1') # Security scan (full mode only)
      # Security audit (full mode only)
      validations_count += 1 if File.exist?('examples/typescript-full-toolchain/package.json')
      validations_count += 1 unless $skip_external_links # External links (full mode only)
    end

    log_structured('ci_simulation_success', {
                     duration_seconds: total_duration,
                     validations_run: validations_count,
                     failed_validations: []
                   })

    exit 0
  else
    puts "❌ #{failed_validations.length} validation(s) failed:"
    failed_validations.each { |validation| puts "   • #{validation}" }
    puts ''
    puts '💡 Fix the issues above before pushing to remote'
    puts "⏱️  Total time: #{total_duration}s"

    # Calculate validations run based on mode (same logic as success case)
    if $validation_mode == :essential
      validations_count = 2  # YAML, index (essential mode)
    else
      validations_count = 3  # YAML, cross-reference, index (full mode)
      # TypeScript validation (full mode only)
      validations_count += 1 if Dir.exist?('docs/bindings/categories/typescript')
      validations_count += 1 if system('command -v gitleaks >/dev/null 2>&1') # Security scan (full mode only)
      # Security audit (full mode only)
      validations_count += 1 if File.exist?('examples/typescript-full-toolchain/package.json')
      validations_count += 1 unless $skip_external_links # External links (full mode only)
    end

    log_structured('ci_simulation_failure', {
                     duration_seconds: total_duration,
                     validations_run: validations_count,
                     failed_validations: failed_validations,
                     failed_count: failed_validations.length
                   })

    exit 1
  end
end

# Run main function
main
