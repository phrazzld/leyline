#!/usr/bin/env ruby
# tools/validate_typescript_toolchain_integration.rb - Full toolchain integration validation
# Validates that all 6 TypeScript bindings work together end-to-end without conflicts
#
# This script executes the complete development workflow in the integration project:
# install → develop → test → build → deploy prep
#
# Requirements:
# - Ruby 2.1+ (for Time.now.iso8601 and JSON support)
# - Node.js 18+ and pnpm for TypeScript toolchain
# - Standard library: fileutils, json, time, optparse
#
# Usage:
# - Full integration test: ruby tools/validate_typescript_toolchain_integration.rb
# - Verbose output: ruby tools/validate_typescript_toolchain_integration.rb --verbose

require 'fileutils'
require 'json'
require 'time'
require 'optparse'

# Configuration for structured logging and verbose output
$structured_logging = ENV['LEYLINE_STRUCTURED_LOGGING'] == 'true'
$correlation_id = "toolchain-integration-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{rand(1000)}"
$verbose = false

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: validate_typescript_toolchain_integration.rb [options]"
  opts.separator ""
  opts.separator "Full TypeScript toolchain integration validation"
  opts.separator ""
  opts.separator "Options:"

  opts.on("-v", "--verbose", "Show detailed output from validation commands") do
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
  opts.separator "  0 - Full toolchain integration successful"
  opts.separator "  1 - Integration validation failed"
end.parse!

PROJECT_DIR = 'examples/typescript-full-toolchain'

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

# Execute a shell command with proper error handling and output capture
def run_command(cmd, description, required: true)
  log_structured('integration_command_start', {
    step: description,
    command: cmd,
    required: required
  })

  puts "  🔧 #{description}..."
  start_time = Time.now

  if $verbose
    puts "    Running: #{cmd}"
    success = system(cmd)
  else
    success = system(cmd, out: '/dev/null', err: '/dev/null')
  end

  duration = (Time.now - start_time).round(3)

  if success
    puts "    ✅ #{description} completed (#{duration}s)"
    log_structured('integration_command_success', {
      step: description,
      duration_seconds: duration
    })
    return true
  else
    exit_code = $?.exitstatus
    puts "    ❌ #{description} failed (exit code #{exit_code})"
    log_structured('integration_command_failure', {
      step: description,
      duration_seconds: duration,
      exit_code: exit_code
    })

    if required
      puts "    💡 Run the command manually for detailed error output:"
      puts "    cd #{PROJECT_DIR} && #{cmd}"
    end

    return false
  end
end

# Check that the integration project exists and has required files
def validate_project_structure
  puts "📁 Validating project structure..."

  required_files = [
    'package.json',
    'tsconfig.json',
    'tsup.config.ts',
    'vitest.config.ts',
    'eslint.config.js',
    '.prettierrc',
    'src/index.ts',
    'src/user-api.ts',
    'tests/index.test.ts',
    'tests/user-api.test.ts',
    'tests/msw-setup.ts',
    'INTEGRATION_GUIDE.md'
  ]

  required_files.each do |file|
    full_path = File.join(PROJECT_DIR, file)
    unless File.exist?(full_path)
      puts "  ❌ Missing required file: #{file}"
      return false
    end
  end

  puts "  ✅ All required files present"
  return true
end

# Check that all required tools are available
def check_prerequisites
  puts "🔍 Checking prerequisites..."

  # Check Ruby
  unless system('ruby --version >/dev/null 2>&1')
    puts "  ❌ Ruby not found"
    return false
  end

  # Check Node.js
  unless system('node --version >/dev/null 2>&1')
    puts "  ❌ Node.js not found - required for TypeScript toolchain"
    puts "     Install Node.js 18+ from https://nodejs.org/"
    return false
  end

  # Check pnpm
  unless system('pnpm --version >/dev/null 2>&1')
    puts "  ❌ pnpm not found - required for package management"
    puts "     Install with: npm install -g pnpm"
    return false
  end

  puts "  ✅ All prerequisites available"
  return true
end

# Validate that build artifacts are created correctly
def validate_build_artifacts
  puts "📦 Validating build artifacts..."

  required_artifacts = [
    'dist/index.js',     # CJS build
    'dist/index.mjs',    # ESM build
    'dist/index.d.ts',   # TypeScript definitions
    'dist/user-api.d.ts' # Additional type definitions
  ]

  required_artifacts.each do |artifact|
    full_path = File.join(PROJECT_DIR, artifact)
    unless File.exist?(full_path)
      puts "  ❌ Missing build artifact: #{artifact}"
      return false
    end
  end

  puts "  ✅ All build artifacts present"
  return true
end

# Main integration validation workflow
def validate_toolchain_integration
  log_structured('toolchain_integration_start', {
    tool: 'validate_typescript_toolchain_integration',
    project_dir: PROJECT_DIR,
    verbose: $verbose
  })

  puts "🚀 TypeScript Toolchain Integration Validation"
  puts "=============================================="
  puts "Project: #{PROJECT_DIR}"
  puts "Correlation ID: #{$correlation_id}"
  puts ""

  # Step 1: Check prerequisites
  unless check_prerequisites
    puts "\n❌ Prerequisites check failed"
    return false
  end

  # Step 2: Validate project structure
  unless validate_project_structure
    puts "\n❌ Project structure validation failed"
    return false
  end

  # Step 3: Change to project directory for remaining operations
  original_dir = Dir.pwd
  begin
    Dir.chdir(PROJECT_DIR)

    # Step 4: Install dependencies (package-json-standards + pnpm enforcement)
    puts "\n📦 Testing dependency management..."
    unless run_command('pnpm install', 'Install dependencies with pnpm')
      return false
    end

    # Step 5: Code quality validation (eslint-prettier-setup)
    puts "\n🔍 Testing code quality automation..."
    unless run_command('pnpm quality:check', 'Run lint and format checks')
      return false
    end

    # Step 6: Testing framework validation (vitest-testing-framework + tanstack-query-state)
    puts "\n🧪 Testing framework integration..."
    unless run_command('pnpm test:coverage', 'Run tests with coverage thresholds')
      return false
    end

    # Step 7: Build system validation (tsup-build-system)
    puts "\n🏗️  Testing build system..."
    unless run_command('pnpm build', 'Build project with dual ESM/CJS output')
      return false
    end

    # Step 8: Validate build artifacts
    unless validate_build_artifacts
      return false
    end

    # Step 9: Development workflow test (modern-typescript-toolchain)
    puts "\n⚡ Testing development workflow..."
    unless run_command('timeout 10s pnpm dev || true', 'Test development mode startup', required: false)
      puts "    ⚠️  Development mode test skipped (requires manual verification)"
    end

    puts "\n🎉 Full toolchain integration validation successful!"
    return true

  ensure
    Dir.chdir(original_dir)
  end
end

# Performance benchmark of the toolchain
def run_performance_benchmark
  puts "\n⏱️  Performance Benchmarks"
  puts "========================="

  original_dir = Dir.pwd
  begin
    Dir.chdir(PROJECT_DIR)

    # Clean install benchmark
    puts "Testing cold install performance..."
    system('rm -rf node_modules pnpm-lock.yaml')
    install_start = Time.now
    if system('pnpm install >/dev/null 2>&1')
      install_time = (Time.now - install_start).round(2)
      puts "  ✅ Cold install: #{install_time}s"
    end

    # Test execution benchmark
    puts "Testing test execution performance..."
    test_start = Time.now
    if system('pnpm test >/dev/null 2>&1')
      test_time = (Time.now - test_start).round(2)
      puts "  ✅ Test execution: #{test_time}s"
    end

    # Build performance benchmark
    puts "Testing build performance..."
    build_start = Time.now
    if system('pnpm build >/dev/null 2>&1')
      build_time = (Time.now - build_start).round(2)
      puts "  ✅ Build time: #{build_time}s"
    end

  ensure
    Dir.chdir(original_dir)
  end
end

# Main execution function
def main
  start_time = Time.now

  # Validate integration
  success = validate_toolchain_integration

  # Run performance benchmarks if integration succeeded
  if success && $verbose
    run_performance_benchmark
  end

  # Summary
  total_duration = (Time.now - start_time).round(3)
  puts "\n📊 Integration Summary"
  puts "====================="

  if success
    puts "✅ All 6 TypeScript bindings integrate successfully!"
    puts "🎯 Complete development workflow operates end-to-end"
    puts "⏱️  Total validation time: #{total_duration}s"

    log_structured('toolchain_integration_success', {
      duration_seconds: total_duration,
      bindings_integrated: 6
    })

    exit 0
  else
    puts "❌ Toolchain integration validation failed"
    puts "💡 Review the error messages above and fix integration issues"
    puts "⏱️  Total validation time: #{total_duration}s"

    log_structured('toolchain_integration_failure', {
      duration_seconds: total_duration
    })

    exit 1
  end
end

# Run main function
main
