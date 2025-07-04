#!/usr/bin/env ruby
# frozen_string_literal: true

# Example of using Leyline's enhanced error handling
require_relative '../lib/leyline/errors'
require_relative '../lib/leyline/sync/git_client'

# Example 1: Basic error handling with recovery suggestions
def handle_git_error
  git_client = Leyline::Sync::GitClient.new
  git_client.setup_sparse_checkout('/tmp/test')
rescue Leyline::Sync::GitClient::GitNotAvailableError => e
  puts "Error: #{e.message}"
  puts "\nRecovery suggestions:"
  e.recovery_suggestions.each_with_index do |suggestion, i|
    puts "  #{i + 1}. #{suggestion}"
  end
end

# Example 2: Using formatted messages with context
def handle_git_command_error
  raise Leyline::Sync::GitClient::GitCommandError.new(
    'sparse-checkout init failed',
    'git sparse-checkout init',
    128
  )
rescue Leyline::GitError => e
  puts "Error Type: #{e.error_type}"
  puts "Formatted Message: #{e.formatted_message}"
  puts "\nContext:"
  e.context.each do |key, value|
    puts "  #{key}: #{value}"
  end
  puts "\nRecovery suggestions:"
  e.recovery_suggestions.each { |s| puts "  - #{s}" }
end

# Example 3: Serializing errors for logging
def log_error_as_json
  error = Leyline::CacheError.new(
    'Cache file corrupted',
    file: '/home/user/.cache/leyline/content/abc123',
    size: 1024
  )

  require 'json'
  puts JSON.pretty_generate(error.to_h)
end

# Example 4: Using error features in commands
class ExampleCommand
  def execute
    perform_operation
  rescue Leyline::LeylineError => e
    handle_leyline_error(e)
  rescue StandardError => e
    handle_generic_error(e)
  end

  private

  def perform_operation
    # Simulate an error
    raise Leyline::ConfigurationError.new(
      'Invalid cache threshold',
      key: 'cache_threshold',
      expected: 'between 0.0 and 1.0',
      actual: '2.0'
    )
  end

  def handle_leyline_error(error)
    if @verbose
      puts "#{error.error_type.to_s.capitalize} Error: #{error.formatted_message}"

      unless error.recovery_suggestions.empty?
        puts "\nWhat you can do:"
        error.recovery_suggestions.each { |s| puts "  • #{s}" }
      end
    else
      puts "Error: #{error.message}"
      puts 'Run with --verbose for recovery suggestions'
    end

    exit 1
  end

  def handle_generic_error(error)
    puts "Unexpected error: #{error.message}"
    puts error.backtrace.first(3).join("\n") if @verbose
    exit 1
  end
end

# Run examples
puts '=== Example 1: Git Not Available Error ==='
handle_git_error

puts "\n=== Example 2: Git Command Error ==="
handle_git_command_error

puts "\n=== Example 3: Error Serialization ==="
log_error_as_json

puts "\n=== Example 4: Command Error Handling ==="
command = ExampleCommand.new
command.instance_variable_set(:@verbose, true)
command.execute
