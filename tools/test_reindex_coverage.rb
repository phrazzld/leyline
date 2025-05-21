#!/usr/bin/env ruby
# tools/test_reindex_coverage.rb - Test script specifically for ensuring code coverage

require 'fileutils'
require 'yaml'

TEST_DIR = "test_reindex_coverage"

begin
  # Clean up any existing test directories
  FileUtils.rm_rf(TEST_DIR) if Dir.exist?(TEST_DIR)

  # Create test directory structure
  FileUtils.mkdir_p("#{TEST_DIR}/tenets")
  FileUtils.mkdir_p("#{TEST_DIR}/bindings/core")
  FileUtils.mkdir_p("#{TEST_DIR}/bindings/categories/typescript")

  puts "Setting up test environment for code coverage..."

  # Create test files to cover all code paths

  # Test 1: A tenet with placeholder text in first paragraph but real text in Core Belief
  tenet_placeholder_with_core = <<~MARKDOWN
---
id: placeholder-with-core
last_modified: "2025-05-10"
---

# Tenet: Placeholder With Core

[This is a placeholder description]

## Core Belief

This is the actual core belief that should be used as summary.

## Practical Guidelines

1. Follow good practices
MARKDOWN

  # Test 2: A tenet with placeholder text in both first paragraph and Core Belief
  tenet_all_placeholders = <<~MARKDOWN
---
id: all-placeholders
last_modified: "2025-05-10"
---

# Tenet: All Placeholders

[This is a placeholder description]

## Core Belief

[This is a placeholder core belief]

## Practical Guidelines

1. [Placeholder guideline]
MARKDOWN

  # Test 3: A tenet with template-style text in first paragraph
  tenet_template_text = <<~MARKDOWN
---
id: template-text
last_modified: "2025-05-10"
---

# Tenet: Template Text

Write a paragraph explaining this tenet's purpose and include enough text to trigger the template text detection.

## Core Belief

The core belief goes here.
MARKDOWN

  # Test 4: A binding file with all empty categories to test empty category handling
  binding_empty_categories = <<~MARKDOWN
---
id: empty-categories
last_modified: "2025-05-10"
derived_from: simplicity
enforced_by: "code review"
applies_to: []
---

# Binding: Empty Categories

This binding has no categories specified to test empty category handling.

## Rationale

Categories should be handled gracefully when empty.
MARKDOWN

  # Write test files
  File.write("#{TEST_DIR}/tenets/placeholder-with-core.md", tenet_placeholder_with_core)
  File.write("#{TEST_DIR}/tenets/all-placeholders.md", tenet_all_placeholders)
  File.write("#{TEST_DIR}/tenets/template-text.md", tenet_template_text)
  File.write("#{TEST_DIR}/bindings/core/empty-categories.md", binding_empty_categories)

  # Create a modified version of reindex.rb for testing
  original_reindex = File.read('tools/reindex.rb')

  # Modify paths for test environment
  test_reindex = original_reindex.gsub(
    "dir = 'docs/tenets'",
    "dir = '#{TEST_DIR}/tenets'"
  ).gsub(
    "dir = 'docs/bindings'",
    "dir = '#{TEST_DIR}/bindings'"
  )

  # Write the modified script
  File.write("#{TEST_DIR}/reindex_test.rb", test_reindex)

  # Run coverage tests with different command line options
  puts "\n== Running Coverage Tests =="

  # Test 1: Default mode
  puts "\nTest 1: Default mode"
  system("ruby #{TEST_DIR}/reindex_test.rb > #{TEST_DIR}/default_output.txt 2>&1")

  # Test 2: Verbose mode
  puts "Test 2: Verbose mode"
  system("ruby #{TEST_DIR}/reindex_test.rb --verbose > #{TEST_DIR}/verbose_output.txt 2>&1")

  # Test 3: Strict mode
  puts "Test 3: Strict mode"
  system("ruby #{TEST_DIR}/reindex_test.rb --strict > #{TEST_DIR}/strict_output.txt 2>&1")

  # Test 4: Help option
  puts "Test 4: Help option"
  system("ruby #{TEST_DIR}/reindex_test.rb --help > #{TEST_DIR}/help_output.txt 2>&1")

  # Verify the test runs
  tenet_index_exists = File.exist?("#{TEST_DIR}/tenets/00-index.md")
  binding_index_exists = File.exist?("#{TEST_DIR}/bindings/00-index.md")

  # Verify the specific test cases
  if tenet_index_exists
    tenet_index = File.read("#{TEST_DIR}/tenets/00-index.md")
    puts "\n== Tenet Index Coverage Tests =="
    puts "✓ Index file generated: #{tenet_index_exists}"
    puts "✓ Core belief used for placeholder: #{tenet_index.include?('actual core belief')}"
    puts "✓ 'See document for details' used for all placeholders: #{tenet_index.include?('See document for details')}"
    puts "✓ Template text handled: #{tenet_index.include?('template-text')}"
  end

  if binding_index_exists
    binding_index = File.read("#{TEST_DIR}/bindings/00-index.md")
    puts "\n== Binding Index Coverage Tests =="
    puts "✓ Index file generated: #{binding_index_exists}"
    puts "✓ Empty categories handled: #{binding_index.include?('empty-categories')}"
  end

  # Check verbose output for warning messages
  verbose_output = File.read("#{TEST_DIR}/verbose_output.txt")
  puts "\n== Warning Message Coverage =="
  puts "Verbose output content:"
  puts verbose_output
  puts "\n✓ Placeholder warning: #{verbose_output.include?('Using placeholder text for summary')}"
  puts "✓ Template text warning: #{verbose_output.include?('template text') || verbose_output.include?('Write a paragraph')}"

  # Check help output
  help_output = File.read("#{TEST_DIR}/help_output.txt")
  puts "\n== Help Option Coverage =="
  puts "✓ Help info displayed: #{help_output.include?('Usage: reindex.rb')}"

  puts "\n✅ Coverage tests completed!"
ensure
  # Clean up
  FileUtils.rm_rf(TEST_DIR)
end
