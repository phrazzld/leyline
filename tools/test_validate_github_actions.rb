#!/usr/bin/env ruby
# tools/test_validate_github_actions.rb - Test suite for GitHub Actions validation
#
# This test validates the deprecation detection tool to ensure it correctly
# identifies deprecated actions and provides appropriate upgrade guidance.
#
# Aligned with Leyline's testability tenet: "Build testability into your system
# from the ground up" - this provides comprehensive testing for the quality gate.

require 'yaml'
require 'json'
require 'tmpdir'
require 'fileutils'

# Load the validation tool
require_relative 'validate_github_actions'

$test_failures = 0
$test_successes = 0

def test_case(description)
  print "Testing: #{description}... "
  begin
    yield
    puts "✅ PASSED"
    $test_successes += 1
  rescue => e
    puts "❌ FAILED: #{e.message}"
    puts "  #{e.backtrace.first}" if $verbose
    $test_failures += 1
  end
end

def assert(condition, message = "Assertion failed")
  raise message unless condition
end

def assert_equal(expected, actual, message = nil)
  message ||= "Expected #{expected.inspect}, got #{actual.inspect}"
  raise message unless expected == actual
end

def create_test_workflow(content)
  Dir.mktmpdir do |dir|
    workflow_file = File.join(dir, 'test-workflow.yml')
    File.write(workflow_file, content)
    yield workflow_file
  end
end

# Test Cases

puts "🧪 GitHub Actions Validation Tool Test Suite"
puts "============================================"
puts ""

# Test 1: Database Loading
test_case("Load deprecation database") do
  database = load_deprecation_database
  assert database.is_a?(Hash), "Database should be a hash"
  assert database.keys.length > 0, "Database should contain entries"

  # Verify expected structure
  database.each do |action, info|
    assert info.key?('deprecated_since'), "Entry #{action} missing deprecated_since"
    assert info.key?('reason'), "Entry #{action} missing reason"
    assert info.key?('upgrade_to'), "Entry #{action} missing upgrade_to"
    assert info.key?('severity'), "Entry #{action} missing severity"
    assert ['high', 'medium', 'low'].include?(info['severity']), "Invalid severity for #{action}"
  end
end

# Test 2: Valid Workflow Parsing
test_case("Parse valid workflow file") do
  workflow_content = <<~YAML
    name: Test Workflow
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Setup Node.js
            uses: actions/setup-node@v4
            with:
              node-version: '20'
  YAML

  create_test_workflow(workflow_content) do |file|
    workflow = parse_workflow_file(file)
    assert workflow.is_a?(Hash), "Should parse valid YAML"
    assert workflow['name'] == 'Test Workflow', "Should preserve workflow name"
  end
end

# Test 3: Invalid YAML Handling
test_case("Handle invalid YAML gracefully") do
  invalid_yaml = <<~YAML
    name: Test Workflow
    on: [push
    jobs:
      invalid yaml structure
  YAML

  create_test_workflow(invalid_yaml) do |file|
    workflow = parse_workflow_file(file)
    assert workflow.nil?, "Should return nil for invalid YAML"
  end
end

# Test 4: Action Extraction
test_case("Extract actions from workflow") do
  workflow_content = <<~YAML
    name: Multi-Action Workflow
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - name: Setup Ruby
            uses: ruby/setup-ruby@v1
          - name: Run tests
            run: bundle exec rake test
      deploy:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v3
          - uses: actions/setup-node@v2
  YAML

  create_test_workflow(workflow_content) do |file|
    workflow = parse_workflow_file(file)
    actions = extract_actions_from_workflow(workflow)

    assert_equal 4, actions.length, "Should extract 4 actions"

    # Verify action extraction details
    checkout_actions = actions.select { |a| a[:action].start_with?('actions/checkout') }
    assert_equal 2, checkout_actions.length, "Should find 2 checkout actions"

    # Verify job and step information is captured
    test_job_actions = actions.select { |a| a[:job] == 'test' }
    assert_equal 2, test_job_actions.length, "Should find 2 actions in test job"
  end
end

# Test 5: Deprecation Detection
test_case("Detect deprecated actions") do
  database = load_deprecation_database

  # Test known deprecated action
  deprecated_info = check_action_deprecation('actions/checkout@v1', database)
  assert deprecated_info, "Should detect actions/checkout@v1 as deprecated"
  assert deprecated_info['severity'] == 'high', "Should have high severity"

  # Test current action (should not be deprecated)
  current_info = check_action_deprecation('actions/checkout@v4', database)
  assert current_info.nil?, "Should not detect actions/checkout@v4 as deprecated"
end

# Test 6: Workflow Validation with Deprecated Actions
test_case("Validate workflow with deprecated actions") do
  deprecated_workflow = <<~YAML
    name: Deprecated Actions Workflow
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v1
          - uses: actions/setup-node@v1
          - name: Run tests
            run: npm test
  YAML

  create_test_workflow(deprecated_workflow) do |file|
    database = load_deprecation_database
    result = validate_workflow_file(file, database)
    assert result == false, "Should fail validation with deprecated actions"
  end
end

# Test 7: Workflow Validation with Current Actions
test_case("Validate workflow with current actions") do
  current_workflow = <<~YAML
    name: Current Actions Workflow
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - uses: actions/setup-node@v4
          - name: Run tests
            run: npm test
  YAML

  create_test_workflow(current_workflow) do |file|
    database = load_deprecation_database
    result = validate_workflow_file(file, database)
    assert result == true, "Should pass validation with current actions"
  end
end

# Test 8: Edge Cases
test_case("Handle edge cases") do
  # Empty workflow
  empty_workflow = <<~YAML
    name: Empty Workflow
    on: [push]
  YAML

  create_test_workflow(empty_workflow) do |file|
    database = load_deprecation_database
    result = validate_workflow_file(file, database)
    assert result == true, "Should pass validation for workflow with no actions"
  end

  # Workflow with only run steps (no uses)
  run_only_workflow = <<~YAML
    name: Run Only Workflow
    on: [push]
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - name: Echo hello
            run: echo "Hello World"
          - name: List files
            run: ls -la
  YAML

  create_test_workflow(run_only_workflow) do |file|
    database = load_deprecation_database
    result = validate_workflow_file(file, database)
    assert result == true, "Should pass validation for workflow with only run steps"
  end
end

# Test 9: Action Reference Variations
test_case("Handle action reference variations") do
  database = load_deprecation_database

  # Test with commit SHA
  sha_ref = check_action_deprecation('actions/checkout@a81bbbf8298c0fa03ea29cdc473d45769f953675', database)
  assert sha_ref.nil?, "Should not match SHA references to deprecation patterns"

  # Test with different tag formats
  tag_ref = check_action_deprecation('actions/checkout@main', database)
  assert tag_ref.nil?, "Should not match branch/tag references to version patterns"
end

# Test 10: Database Fallback
test_case("Use fallback database when YAML file missing") do
  # Temporarily move the YAML file
  yaml_file = File.join(File.dirname(__FILE__), 'github-actions-deprecations.yml')
  backup_file = "#{yaml_file}.backup"

  if File.exist?(yaml_file)
    FileUtils.mv(yaml_file, backup_file)
  end

  begin
    database = load_deprecation_database
    assert database.is_a?(Hash), "Should return fallback database"
    assert database.keys.length > 0, "Fallback database should contain entries"
  ensure
    # Restore the file
    if File.exist?(backup_file)
      FileUtils.mv(backup_file, yaml_file)
    end
  end
end

# Test Results Summary
puts ""
puts "=" * 50
puts "📊 TEST RESULTS SUMMARY"
puts "=" * 50
puts "Total tests: #{$test_successes + $test_failures}"
puts "Passed: #{$test_successes}"
puts "Failed: #{$test_failures}"
puts ""

if $test_failures == 0
  puts "✅ ALL TESTS PASSED"
  puts "🎉 GitHub Actions validation tool is working correctly!"
  exit 0
else
  puts "❌ #{$test_failures} TEST(S) FAILED"
  puts "🔧 Fix the failing tests before deploying the validation tool"
  exit 1
end
