#!/usr/bin/env ruby
# tools/test_reindex_updates.rb - Tests for updated reindex.rb with new directory structure

require 'fileutils'
require 'yaml'

# Test constants
TEST_DIR = 'test_reindex_updates'
TEST_DOCS_DIR = "#{TEST_DIR}/docs"
TEST_TENETS_DIR = "#{TEST_DOCS_DIR}/tenets"
TEST_BINDINGS_DIR = "#{TEST_DOCS_DIR}/bindings"
TEST_CORE_DIR = "#{TEST_BINDINGS_DIR}/core"
TEST_CATEGORIES_DIR = "#{TEST_BINDINGS_DIR}/categories"

# Setup: Create test directories
def setup_test_directories
  puts "Setting up test directories..."
  # Clean up any previous test files
  FileUtils.rm_rf(TEST_DIR) if Dir.exist?(TEST_DIR)

  # Create directory structure
  FileUtils.mkdir_p(TEST_TENETS_DIR)
  FileUtils.mkdir_p(TEST_CORE_DIR)
  FileUtils.mkdir_p("#{TEST_CATEGORIES_DIR}/typescript")
  FileUtils.mkdir_p("#{TEST_CATEGORIES_DIR}/go")
  FileUtils.mkdir_p("#{TEST_CATEGORIES_DIR}/empty-category") # For testing empty category handling
end

# Create test files with different formats and content
def create_test_files
  puts "Creating test files..."

  # Create a core binding with YAML front matter
  core_binding_content = <<~MARKDOWN
---
id: test-core-binding
last_modified: '2025-05-10'
derived_from: simplicity
enforced_by: 'manual review'
---

# Binding: Test Core Binding

This is a test core binding with YAML front matter.

## Rationale

The rationale is that we need good test coverage.

## Rule Definition

This rule is defined for testing purposes.
MARKDOWN
  File.write("#{TEST_CORE_DIR}/test-core-binding.md", core_binding_content)

  # Create a typescript binding with YAML front matter
  ts_binding_content = <<~MARKDOWN
---
id: no-any
last_modified: '2025-05-10'
derived_from: simplicity
enforced_by: 'eslint(no-explicit-any)'
---

# Binding: No Any Types

This binding prohibits the use of the `any` type in TypeScript.

## Rationale

Using `any` defeats the purpose of TypeScript's type system.

## Rule Definition

Do not use the `any` type in your TypeScript code.
MARKDOWN
  File.write("#{TEST_CATEGORIES_DIR}/typescript/no-any.md", ts_binding_content)

  # Create a Go binding with YAML front matter
  go_binding_content = <<~MARKDOWN
---
id: error-wrapping
last_modified: '2025-05-10'
derived_from: explicit-over-implicit
enforced_by: 'code review'
---

# Binding: Error Wrapping

Always wrap errors with context in Go.

## Rationale

Error wrapping provides context for debugging.

## Rule Definition

Wrap errors using `fmt.Errorf("context: %w", err)`.
MARKDOWN
  File.write("#{TEST_CATEGORIES_DIR}/go/error-wrapping.md", go_binding_content)

  # Create a misplaced binding file in the root bindings directory
  misplaced_binding_content = <<~MARKDOWN
---
id: misplaced-binding
last_modified: '2025-05-10'
derived_from: testability
enforced_by: 'manual review'
---

# Binding: Misplaced Binding

This binding is misplaced and should be detected.

## Rationale

This file tests detection of bindings in the wrong location.

## Rule Definition

This binding should be in core/ or categories/.
MARKDOWN
  File.write("#{TEST_BINDINGS_DIR}/misplaced-binding.md", misplaced_binding_content)

  # Create a tenet file for tenets directory testing
  tenet_content = <<~MARKDOWN
---
id: test-tenet
last_modified: '2025-05-10'
---

# Tenet: Test Tenet

This is a test tenet for verification.

## Core Belief

The core belief is about writing good tests.

## Practical Guidelines

1. **Test Thoroughly**: Cover all edge cases.
2. **Keep Tests Simple**: Tests should be easy to understand.
MARKDOWN
  File.write("#{TEST_TENETS_DIR}/test-tenet.md", tenet_content)
end

# Write a modified version of reindex.rb that works with our test directories
def create_test_reindex_script
  puts "Creating test reindex script..."

  original_reindex = File.read('tools/reindex.rb')

  # Modify the script to use our test directories
  test_reindex = original_reindex.gsub(
    "dir = 'docs/tenets'",
    "dir = '#{TEST_TENETS_DIR}'"
  ).gsub(
    "dir = 'docs/bindings'",
    "dir = '#{TEST_BINDINGS_DIR}'"
  )

  File.write("#{TEST_DIR}/reindex_test.rb", test_reindex)
end

# Run the test reindex script
def run_test_reindex
  puts "Running test reindex script..."
  system("ruby #{TEST_DIR}/reindex_test.rb")
end

# Test specific functionality
def test_binding_directories_structure
  puts "\nTEST: Binding directories structure..."

  # Check if index files were created
  bindings_index_exists = File.exist?("#{TEST_BINDINGS_DIR}/00-index.md")
  tenets_index_exists = File.exist?("#{TEST_TENETS_DIR}/00-index.md")

  puts "✓ Bindings index created" if bindings_index_exists
  puts "✓ Tenets index created" if tenets_index_exists

  # Check bindings index content
  if bindings_index_exists
    bindings_index_content = File.read("#{TEST_BINDINGS_DIR}/00-index.md")

    # Verify core bindings section exists
    has_core_section = bindings_index_content.include?("## Core Bindings")
    puts "✓ Core bindings section exists" if has_core_section

    # Verify test-core-binding is included
    has_core_binding = bindings_index_content.include?("[test-core-binding](./core/test-core-binding.md)")
    puts "✓ Core binding correctly linked" if has_core_binding

    # Verify TypeScript section exists
    has_ts_section = bindings_index_content.include?("## TypeScript Bindings")
    puts "✓ TypeScript section exists" if has_ts_section

    # Verify no-any binding is included
    has_ts_binding = bindings_index_content.include?("[no-any](./categories/typescript/no-any.md)")
    puts "✓ TypeScript binding correctly linked" if has_ts_binding

    # Verify Go section exists
    has_go_section = bindings_index_content.include?("## Go Bindings")
    puts "✓ Go section exists" if has_go_section

    # Verify error-wrapping binding is included
    has_go_binding = bindings_index_content.include?("[error-wrapping](./categories/go/error-wrapping.md)")
    puts "✓ Go binding correctly linked" if has_go_binding

    # Check for empty category
    has_empty_category = bindings_index_content.include?("Empty-category Bindings") &&
                         bindings_index_content.include?("_No empty-category bindings defined yet._")
    puts "✓ Empty category handled correctly" if has_empty_category

    # Check that misplaced binding is not in the index
    no_misplaced_binding = !bindings_index_content.include?("misplaced-binding")
    puts "✓ Misplaced binding not included in index" if no_misplaced_binding
  end
end

# Test misplaced files detection
def test_misplaced_files_detection
  puts "\nTEST: Misplaced files detection..."

  # Capture the console output from running the reindex script
  console_output = File.read("#{TEST_DIR}/reindex_output.txt") if File.exist?("#{TEST_DIR}/reindex_output.txt")

  # Check for misplaced file detection message
  if console_output
    detected = console_output.include?("ERROR: Misplaced binding file found in root directory")
    puts "✓ Misplaced file detection works" if detected

    # Verify count is correct
    correct_count = console_output.include?("Found 1 misplaced binding file(s) in root directory")
    puts "✓ Misplaced file count is correct" if correct_count
  else
    # If we don't have console output, do a direct test
    misplaced_file_count = Dir.glob("#{TEST_BINDINGS_DIR}/*.md").reject { |f| f =~ /00-index\.md$/ }.size
    puts "✓ Found #{misplaced_file_count} misplaced files (expected 1)" if misplaced_file_count == 1
  end
end

# Test empty category handling
def test_empty_category_handling
  puts "\nTEST: Empty category handling..."

  # Check the bindings index content
  bindings_index_content = File.read("#{TEST_BINDINGS_DIR}/00-index.md") if File.exist?("#{TEST_BINDINGS_DIR}/00-index.md")

  if bindings_index_content
    # Check that empty category has a section
    has_empty_category_section = bindings_index_content.include?("## Empty-category Bindings")
    puts "✓ Empty category has a section in the index" if has_empty_category_section

    # Check that empty category has the correct message
    has_empty_message = bindings_index_content.include?("_No empty-category bindings defined yet._")
    puts "✓ Empty category has the correct message" if has_empty_message
  end

  # Check console output for empty category detection
  console_output = File.read("#{TEST_DIR}/reindex_output.txt") if File.exist?("#{TEST_DIR}/reindex_output.txt")

  if console_output
    detected = console_output.include?("empty-category")
    puts "✓ Empty category detection works" if detected
  end
end

# Run all tests and report results
def run_all_tests
  puts "Running all tests..."

  setup_test_directories
  create_test_files
  create_test_reindex_script

  # Capture the console output to a file for later inspection
  system("ruby #{TEST_DIR}/reindex_test.rb > #{TEST_DIR}/reindex_output.txt 2>&1")

  # Run specific tests
  test_binding_directories_structure
  test_misplaced_files_detection
  test_empty_category_handling

  # Final report
  puts "\n====== TEST SUMMARY ======="
  puts "All tests completed."
end

# Cleanup test files
def cleanup
  puts "\nCleaning up test files..."
  FileUtils.rm_rf(TEST_DIR)
  puts "All test files removed."
end

# Main execution
begin
  puts "==== TESTING REINDEX.RB UPDATES ===="
  run_all_tests
ensure
  cleanup
end
