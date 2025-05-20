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

  # Create a file with no front-matter
  no_front_matter = <<~MARKDOWN
# Binding: No Front Matter

This binding has no front-matter at all.
MARKDOWN
  File.write("#{TEST_DIR}/docs/bindings/core/no-front-matter.md", no_front_matter)

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
  ).gsub(
    "tenet_file = Dir.glob(\"docs/tenets/\#{front_matter['derived_from']}.md\").first",
    "tenet_file = Dir.glob(\"#{TEST_DIR}/docs/tenets/\#{front_matter['derived_from']}.md\").first"
  )

  # Save the modified validator
  File.write("#{TEST_DIR}/validate_front_matter_test.rb", test_validator_code)
  FileUtils.chmod(0755, "#{TEST_DIR}/validate_front_matter_test.rb")

  puts "Test validator created."
end

# Function to run the validator and return results
def run_validator(args = nil)
  command = "ruby #{TEST_DIR}/validate_front_matter_test.rb"
  command += " #{args}" if args

  puts "Running validator#{args ? " with args: #{args}" : ''}..."
  output = `#{command} 2>&1`
  exit_code = $?.exitstatus

  [output, exit_code]
end

# Function to verify the validator behavior
def verify_validator_behavior
  puts "\nVerifying validator behavior..."

  # Run validation test for valid files
  output, exit_code = run_validator

  # The regular validation will fail because of the no-front-matter file, so we'll test individual files
  valid_binding_output, _ = run_validator("-f #{TEST_DIR}/docs/bindings/core/valid-core-binding.md")
  category_binding_output, _ = run_validator("-f #{TEST_DIR}/docs/bindings/categories/typescript/valid-ts-binding.md")
  applies_to_output, _ = run_validator("-f #{TEST_DIR}/docs/bindings/core/binding-with-applies-to.md")

  # Check for specific behaviors with valid files
  valid_file_checks = {
    "Validates core bindings" => valid_binding_output.include?("[OK] #{TEST_DIR}/docs/bindings/core/valid-core-binding.md"),
    "Validates category bindings" => category_binding_output.include?("[OK] #{TEST_DIR}/docs/bindings/categories/typescript/valid-ts-binding.md"),
    "Warns about applies_to field" => applies_to_output.include?("Contains deprecated 'applies_to' field"),
    "Explains applies_to deprecation" => applies_to_output.include?("The 'applies_to' field is no longer used"),
    "Detects misplaced files" => output.include?("Found 1 binding file(s) directly in docs/bindings/ directory"),
    "Suggests correct locations" => output.include?("These should be moved to either docs/bindings/core/ or docs/bindings/categories"),
  }

  puts "\nValid file checks:"
  valid_passed = run_checks(valid_file_checks)

  # Test with no front-matter file
  no_front_matter_output, no_front_matter_exit_code = run_validator("-f #{TEST_DIR}/docs/bindings/core/no-front-matter.md")
  error_checks = {
    "Fails for files without front-matter" => no_front_matter_exit_code != 0 && no_front_matter_output.include?("No front-matter found")
  }

  puts "\nError case checks:"
  error_passed = run_checks(error_checks)

  total_passed = valid_passed + error_passed
  total = valid_file_checks.size + error_checks.size

  # Output overall results
  puts "\nTest Results: #{total_passed} of #{total} checks passed"

  if total_passed == total
    puts "\nAll checks passed! The validate_front_matter.rb script correctly:"
    puts "1. Validates bindings in the new directory structure (core/ and categories/)"
    puts "2. Warns about deprecated applies_to field"
    puts "3. Detects misplaced files in the root bindings directory"
    puts "4. Enforces YAML front-matter format only"
    puts "5. Fails validation for files without YAML front-matter"
  else
    puts "\nSome checks failed. Review the output for details."
    puts "Standard validation output:"
    puts output
    puts "\nNo front-matter validation output:"
    puts no_front_matter_output
  end
end

# Helper to run checks and count passed tests
def run_checks(checks)
  passed = 0
  checks.each do |check, result|
    if result
      puts "✓ #{check}"
      passed += 1
    else
      puts "✗ #{check}"
    end
  end
  passed
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
