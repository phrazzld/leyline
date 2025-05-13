#!/usr/bin/env ruby
# tools/test_validate_front_matter.rb - Tests for updated validate_front_matter.rb with new directory structure

require 'fileutils'
require 'yaml'

# Test directory name
TEST_DIR = "test_validate_front_matter"

# Function to create the test environment
def setup_test_environment
  puts "Setting up test environment..."
  FileUtils.rm_rf(TEST_DIR) if Dir.exist?(TEST_DIR)

  # Create the directory structure
  FileUtils.mkdir_p("#{TEST_DIR}/docs/tenets")
  FileUtils.mkdir_p("#{TEST_DIR}/docs/bindings/core")
  FileUtils.mkdir_p("#{TEST_DIR}/docs/bindings/categories/typescript")
  FileUtils.mkdir_p("#{TEST_DIR}/docs/bindings/categories/go")

  # Create a tenet file for reference
  tenet_content = <<~MARKDOWN
---
id: test-tenet
last_modified: '2025-05-10'
---

# Tenet: Test Tenet

This is a test tenet.
MARKDOWN
  File.write("#{TEST_DIR}/docs/tenets/test-tenet.md", tenet_content)

  # Create a valid core binding
  valid_core_binding = <<~MARKDOWN
---
id: valid-core-binding
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'manual review'
---

# Binding: Valid Core Binding

This is a valid core binding.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/core/valid-core-binding.md", valid_core_binding)

  # Create a valid category binding
  valid_category_binding = <<~MARKDOWN
---
id: valid-ts-binding
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'eslint'
---

# Binding: Valid TypeScript Binding

This is a valid TypeScript binding.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/categories/typescript/valid-ts-binding.md", valid_category_binding)

  # Create a binding with deprecated applies_to field
  applies_to_binding = <<~MARKDOWN
---
id: binding-with-applies-to
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'manual review'
applies_to: ['typescript']
---

# Binding: With Applies To

This binding has the deprecated applies_to field.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/core/binding-with-applies-to.md", applies_to_binding)

  # Create a misplaced binding
  misplaced_binding = <<~MARKDOWN
---
id: misplaced-binding
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'manual review'
---

# Binding: Misplaced

This binding is misplaced in the root bindings directory.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/misplaced-binding.md", misplaced_binding)

  # Create an old-format binding using horizontal rules
  old_format_binding = <<~MARKDOWN
______________________________________________________________________

# Unique identifier for this binding (must be kebab-case, matching the filename without .md)

id: old-format-binding

# Date of last modification in ISO format (YYYY-MM-DD) with single quotes

last_modified: '2025-05-10'

# ID of the parent tenet this binding implements (must be an existing tenet ID)

derived_from: test-tenet

# Tool, rule, or process that enforces this binding

enforced_by: 'manual review'

______________________________________________________________________

# Binding: Old Format

This binding uses the old horizontal rule format.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/core/old-format-binding.md", old_format_binding)

  puts "Test environment setup complete."
end

# Function to create a modified validator for testing
def create_test_validator
  puts "Creating test validator..."

  # Read the original validator code using an absolute path
  validator_code = File.read("/Users/phaedrus/Development/leyline/tools/validate_front_matter.rb")

  # Modify paths to use our test directory
  test_validator_code = validator_code.gsub(
    "dir = 'docs/tenets'",
    "dir = '#{TEST_DIR}/docs/tenets'"
  ).gsub(
    "core_glob = \"docs/bindings/core/*.md\"",
    "core_glob = \"#{TEST_DIR}/docs/bindings/core/*.md\""
  ).gsub(
    "categories_glob = \"docs/bindings/categories/*/*.md\"",
    "categories_glob = \"#{TEST_DIR}/docs/bindings/categories/*/*.md\""
  ).gsub(
    "root_files = Dir.glob(\"docs/bindings/*.md\")",
    "root_files = Dir.glob(\"#{TEST_DIR}/docs/bindings/*.md\")"
  )

  # Save the modified validator
  File.write("#{TEST_DIR}/validate_front_matter_test.rb", test_validator_code)
  FileUtils.chmod(0755, "#{TEST_DIR}/validate_front_matter_test.rb")

  puts "Test validator created."
end

# Function to run the validator and return results
def run_validator(strict_mode = false)
  command = "ruby #{TEST_DIR}/validate_front_matter_test.rb"
  command += " --strict" if strict_mode

  puts "Running validator#{strict_mode ? ' in strict mode' : ''}..."
  output = `#{command} 2>&1`
  exit_code = $?.exitstatus

  [output, exit_code]
end

# Function to verify the validator behavior
def verify_validator_behavior
  puts "\nVerifying validator behavior..."

  # Normal mode test
  output, exit_code = run_validator

  # Check for specific behaviors in normal mode
  normal_mode_checks = {
    "Finds core bindings" => output.include?("#{TEST_DIR}/docs/bindings/core/valid-core-binding.md"),
    "Finds category bindings" => output.include?("#{TEST_DIR}/docs/bindings/categories/typescript/valid-ts-binding.md"),
    "Warns about applies_to field" => output.include?("Contains deprecated 'applies_to' field"),
    "Explains applies_to deprecation" => output.include?("The 'applies_to' field is no longer used"),
    "Detects misplaced files" => output.include?("Found 1 binding file(s) directly in docs/bindings/ directory"),
    "Suggests correct locations" => output.include?("These should be moved to either docs/bindings/core/ or docs/bindings/categories"),
    "Warns about horizontal rule format" => output.include?("Using deprecated horizontal rule format"),
    "Normal mode passes with warnings" => exit_code == 0
  }

  passed = 0
  total = normal_mode_checks.size

  puts "\nNormal mode checks:"
  normal_mode_checks.each do |check, result|
    if result
      puts "✓ #{check}"
      passed += 1
    else
      puts "✗ #{check}"
    end
  end

  # Strict mode test
  strict_output, strict_exit_code = run_validator(true)

  # Check for specific behaviors in strict mode
  strict_mode_checks = {
    "Strict mode fails for old format files" => strict_exit_code != 0 && strict_output.include?("horizontal rule format")
  }

  puts "\nStrict mode checks:"
  strict_mode_checks.each do |check, result|
    if result
      puts "✓ #{check}"
      passed += 1
    else
      puts "✗ #{check}"
    end
  end

  total += strict_mode_checks.size

  # Output overall results
  puts "\nTest Results: #{passed} of #{total} checks passed"

  if passed == total
    puts "\nAll checks passed! The validate_front_matter.rb script correctly:"
    puts "1. Validates bindings in the new directory structure (core/ and categories/)"
    puts "2. Warns about but doesn't error on deprecated applies_to field"
    puts "3. Detects misplaced files in the root bindings directory"
    puts "4. Supports both formats in normal mode but enforces YAML in strict mode"
  else
    puts "\nSome checks failed. Review the output for details."
    puts "Output from normal mode:"
    puts output
    puts "\nOutput from strict mode:"
    puts strict_output
  end
end

# Function to clean up test files
def cleanup
  puts "\nCleaning up test files..."
  FileUtils.rm_rf(TEST_DIR)
  puts "Test files removed."
end

# Main execution
begin
  puts "==== TESTING VALIDATE_FRONT_MATTER.RB ===="
  setup_test_environment
  create_test_validator
  verify_validator_behavior
ensure
  cleanup
end
