#!/usr/bin/env ruby
# tools/run_ci_checks.rb - Local CI simulation script
# Replicates CI validation pipeline locally to catch issues before remote execution
#
# This script executes the same validation steps as the CI pipeline:
# 1. YAML front-matter validation
# 2. Cross-reference validation
# 3. Index consistency check
# 4. Optional external link checking (if markdown-link-check available)
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

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: run_ci_checks.rb [options]"
  opts.separator ""
  opts.separator "Local CI simulation script that replicates CI validation pipeline"
  opts.separator ""
  opts.separator "Options:"

  opts.on("--skip-external-links", "Skip external link checking (faster execution)") do
    $skip_external_links = true
  end

  opts.on("-v", "--verbose", "Show detailed output from validation tools") do
    $verbose = true
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end

  opts.separator ""
  opts.separator "Environment Variables:"
  opts.separator "  LEYLINE_STRUCTURED_LOGGING=true  Enable JSON structured logging to STDERR"
  opts.separator ""
  opts.separator "Exit Codes:"
  opts.separator "  0 - All validations passed"
  opts.separator "  1 - One or more validations failed"
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

    STDERR.puts JSON.generate(log_entry)
  rescue => e
    # Graceful degradation if structured logging fails
    STDERR.puts "Warning: Structured logging failed: #{e.message}"
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
  if $verbose
    success = system(env, command)
  else
    success = system(env, command, out: '/dev/null', err: '/dev/null')
  end

  duration = (Time.now - start_time).round(3)

  if success
    puts "✅ #{description} passed (#{duration}s)"
    log_structured('validation_step_success', {
      step: description,
      duration_seconds: duration
    })
    return true
  else
    exit_code = $?.exitstatus
    puts "❌ #{description} failed (exit code #{exit_code})"
    log_structured('validation_step_failure', {
      step: description,
      duration_seconds: duration,
      exit_code: exit_code
    })

    if required
      puts "   💡 Run the command manually for detailed error output:"
      puts "   #{command}"
    end

    return false
  end
end

def check_tool_availability(tool, install_hint = nil)
  if system("command -v #{tool} >/dev/null 2>&1")
    puts "✅ #{tool} is available"
    return true
  else
    puts "⚠️  #{tool} not found"
    puts "   #{install_hint}" if install_hint
    return false
  end
end

def main
  log_structured('ci_simulation_start', {
    tool: 'run_ci_checks',
    verbose: $verbose,
    skip_external_links: $skip_external_links
  })

  puts "🚀 Local CI Validation Pipeline"
  puts "================================"
  puts "Correlation ID: #{$correlation_id}"
  puts "Structured Logging: #{$structured_logging ? 'enabled' : 'disabled'}"
  puts ""

  start_time = Time.now
  failed_validations = []

  # Step 1: YAML front-matter validation
  command = "ruby tools/validate_front_matter.rb#{$verbose ? ' -v' : ''}"
  unless run_command(command, "YAML front-matter validation")
    failed_validations << "YAML validation"
  end

  # Step 2: Cross-reference validation
  command = "ruby tools/validate_cross_references.rb#{$verbose ? ' -v' : ''}"
  unless run_command(command, "Cross-reference validation")
    failed_validations << "Cross-reference validation"
  end

  # Step 3: Index consistency check
  puts "🔄 Index consistency validation..."
  index_start = Time.now

  # First run reindex to check for errors
  if run_command("ruby tools/reindex.rb --strict", "Index generation check")
    # Then check if index file would change
    if system("git diff --exit-code docs/bindings/00-index.md >/dev/null 2>&1")
      duration = (Time.now - index_start).round(3)
      puts "✅ Index consistency validation passed (#{duration}s)"
      log_structured('validation_step_success', {
        step: "Index consistency validation",
        duration_seconds: duration
      })
    else
      duration = (Time.now - index_start).round(3)
      puts "❌ Index file is out of date (#{duration}s)"
      puts "   💡 Run 'ruby tools/reindex.rb' to update the index file"
      log_structured('validation_step_failure', {
        step: "Index consistency validation",
        duration_seconds: duration,
        reason: "index_file_outdated"
      })
      failed_validations << "Index consistency"
    end
  else
    failed_validations << "Index generation"
  end

  # Step 4: External link checking (optional)
  unless $skip_external_links
    puts ""
    puts "📡 Checking external link validation tool availability..."

    if check_tool_availability("node", "Install Node.js from https://nodejs.org/") &&
       check_tool_availability("npm", "Install npm (usually comes with Node.js)")

      # Check if markdown-link-check is installed
      if system("npm list -g markdown-link-check >/dev/null 2>&1")
        puts "✅ markdown-link-check is available"

        command = "find . -name '*.md' | grep -v 'node_modules\\|venv\\|site' | xargs markdown-link-check -q -c ./.mlc-config"
        unless run_command(command, "External link validation", required: false)
          failed_validations << "External link validation"
        end
      else
        puts "⚠️  markdown-link-check not installed globally"
        puts "   Install with: npm install -g markdown-link-check"
        puts "   Skipping external link validation"

        log_structured('validation_step_skipped', {
          step: "External link validation",
          reason: "tool_not_installed"
        })
      end
    else
      puts "   Skipping external link validation (Node.js/npm not available)"
      log_structured('validation_step_skipped', {
        step: "External link validation",
        reason: "nodejs_not_available"
      })
    end
  else
    puts "⏭️  Skipping external link validation (--skip-external-links)"
    log_structured('validation_step_skipped', {
      step: "External link validation",
      reason: "user_requested_skip"
    })
  end

  # Summary
  total_duration = (Time.now - start_time).round(3)
  puts ""
  puts "📊 Validation Summary"
  puts "==================="

  if failed_validations.empty?
    puts "✅ All validations passed!"
    puts "🎉 Your changes are ready for CI"
    puts "⏱️  Total time: #{total_duration}s"

    log_structured('ci_simulation_success', {
      duration_seconds: total_duration,
      validations_run: 4 - ($skip_external_links ? 1 : 0),
      failed_validations: []
    })

    exit 0
  else
    puts "❌ #{failed_validations.length} validation(s) failed:"
    failed_validations.each { |validation| puts "   • #{validation}" }
    puts ""
    puts "💡 Fix the issues above before pushing to remote"
    puts "⏱️  Total time: #{total_duration}s"

    log_structured('ci_simulation_failure', {
      duration_seconds: total_duration,
      validations_run: 4 - ($skip_external_links ? 1 : 0),
      failed_validations: failed_validations,
      failed_count: failed_validations.length
    })

    exit 1
  end
end

# Run main function
main
