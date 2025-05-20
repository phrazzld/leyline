#!/usr/bin/env ruby
# tools/test_reindex.rb - Tests index generation with template files

require 'fileutils'

# Create test directories
FileUtils.mkdir_p('test_reindex/tenets')
FileUtils.mkdir_p('test_reindex/bindings')
FileUtils.mkdir_p('test_reindex/bindings/core')
FileUtils.mkdir_p('test_reindex/bindings/categories/typescript')
FileUtils.mkdir_p('test_reindex/bindings/categories/go')

begin
  # Copy templates to test directories
  FileUtils.cp('docs/templates/tenet_template.md', 'test_reindex/tenets/tenet_template.md')
  FileUtils.cp('docs/templates/binding_template.md', 'test_reindex/bindings/core/binding_template.md')

  # Create a small tenet with actual content for comparison
  real_tenet_content = <<~MARKDOWN
---
id: real-tenet
last_modified: "2025-05-04"
---

# Tenet: Real Tenet

This is a real tenet that should be indexed correctly.

## Core Belief

The core belief is that indexing should work correctly.

## Practical Guidelines

1. **Test Guideline**: This is just a test guideline.
MARKDOWN

  # Create a small binding with actual content for comparison
  real_binding_content = <<~MARKDOWN
---
id: real-binding
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: testing
applies_to:
  - typescript
---

# Binding: Real Binding

This is a real binding that should be indexed correctly.

## Rationale

The rationale is that indexing should work correctly for bindings too.

## Rule Definition

This is a rule definition for testing purposes.
MARKDOWN

  # Create files with errors for testing error handling

  # 1. Missing YAML front-matter
  missing_frontmatter = <<~MARKDOWN
# Tenet: Missing Front-matter

This tenet is missing the required YAML front-matter.

## Core Belief

This should cause an error.
MARKDOWN

  # 2. Invalid YAML syntax
  invalid_yaml = <<~MARKDOWN
---
id: invalid-yaml
last_modified: "2025-05-04
derived_from: simplicity
---

# Binding: Invalid YAML

This binding has invalid YAML in the front-matter (missing closing quote).

## Rationale

This should cause a YAML parsing error.
MARKDOWN

  # 3. Missing required fields
  missing_fields = <<~MARKDOWN
---
id: missing-fields
# Missing the last_modified, derived_from, and enforced_by fields
---

# Binding: Missing Fields

This binding is missing required fields in the front-matter.

## Rationale

This should cause a validation error.
MARKDOWN

  # Write the test files
  File.write('test_reindex/tenets/real-tenet.md', real_tenet_content)
  File.write('test_reindex/bindings/core/real-binding.md', real_binding_content)

  # Error test files
  File.write('test_reindex/tenets/missing-frontmatter.md', missing_frontmatter)
  File.write('test_reindex/bindings/categories/typescript/invalid-yaml.md', invalid_yaml)
  File.write('test_reindex/bindings/categories/go/missing-fields.md', missing_fields)

  # Add a misplaced binding file
  File.write('test_reindex/bindings/misplaced-binding.md', real_binding_content.gsub('real-binding', 'misplaced-binding'))

  # Run the indexing script with test options
  puts "Testing reindex.rb with valid and invalid files..."

  # Temporarily modify the script to use our test directories
  original_reindex = File.read('tools/reindex.rb')
  test_reindex = original_reindex.gsub(
    'dir = \'docs/tenets\'',
    'dir = \'tenets\''
  ).gsub(
    'dir = \'docs/bindings\'',
    'dir = \'bindings\''
  ).gsub(
    'Dir.glob("#{dir}/*.md")',
    'Dir.glob("test_reindex/#{dir}/*.md")'
  ).gsub(
    'File.write("#{dir}/00-index.md"',
    'File.write("test_reindex/#{dir}/00-index.md"'
  ).gsub(
    'Dir.glob("#{dir}/core/*.md")',
    'Dir.glob("test_reindex/#{dir}/core/*.md")'
  ).gsub(
    'Dir.glob("#{dir}/categories/*")',
    'Dir.glob("test_reindex/#{dir}/categories/*")'
  )
  File.write('tools/reindex_test.rb', test_reindex)

  # Test 1: Run with default options
  puts "\n== Test 1: Standard Run (Should show errors but continue) =="
  system('ruby tools/reindex_test.rb > test_reindex/output_standard.txt 2>&1')

  # Test 2: Run with verbose output
  puts "\n== Test 2: Verbose Run (Should show detailed errors and warnings) =="
  system('ruby tools/reindex_test.rb --verbose > test_reindex/output_verbose.txt 2>&1')

  # Test 3: Run with strict mode (should exit with error code)
  puts "\n== Test 3: Strict Run (Should exit with error code) =="
  strict_exit_code = system('ruby tools/reindex_test.rb --strict > test_reindex/output_strict.txt 2>&1')
  puts "Strict mode exit code: #{strict_exit_code.nil? ? 'nil' : strict_exit_code}"

  # Verify outputs
  puts "\n== Verification =="

  # Check if index files were generated
  tenet_index_exists = File.exist?('test_reindex/tenets/00-index.md')
  binding_index_exists = File.exist?('test_reindex/bindings/00-index.md')

  puts "✓ Tenet index was generated: #{tenet_index_exists}"
  puts "✓ Binding index was generated: #{binding_index_exists}"

  # Check if real-tenet was included in the index
  if tenet_index_exists
    tenet_index_content = File.read('test_reindex/tenets/00-index.md')
    puts "✓ Real tenet was included: #{tenet_index_content.include?('real-tenet')}"
  end

  # Check if real-binding was included in the index
  if binding_index_exists
    binding_index_content = File.read('test_reindex/bindings/00-index.md')
    puts "✓ Real binding was included: #{binding_index_content.include?('real-binding')}"
  end

  # Analyze error reporting
  standard_output = File.read('test_reindex/output_standard.txt')
  verbose_output = File.read('test_reindex/output_verbose.txt')
  strict_output = File.read('test_reindex/output_strict.txt')

  # Check error reporting consistency
  reports_missing_frontmatter = standard_output.include?('No YAML front-matter found')
  reports_invalid_yaml = standard_output.include?('Invalid YAML in front-matter')
  reports_missing_fields = standard_output.include?('Missing required metadata fields')
  reports_misplaced_file = standard_output.include?('Misplaced binding file')

  puts "\nError reporting verification:"
  puts "✓ Reports missing front-matter: #{reports_missing_frontmatter}"
  puts "✓ Reports invalid YAML: #{reports_invalid_yaml}"
  puts "✓ Reports missing fields: #{reports_missing_fields}"
  puts "✓ Reports misplaced file: #{reports_misplaced_file}"

  # Check verbose output has more detail
  has_more_detail = verbose_output.length > standard_output.length
  puts "✓ Verbose output provides more detail: #{has_more_detail}"

  # Check strict mode exited with error
  strict_has_exit = !strict_exit_code
  puts "✓ Strict mode exited with error: #{strict_has_exit}"

  puts "\n== Test Results Summary =="
  if reports_missing_frontmatter && reports_invalid_yaml && reports_missing_fields && reports_misplaced_file
    puts "✅ Error handling tests PASSED - All error types were correctly reported"
  else
    puts "❌ Error handling tests FAILED - Not all error types were correctly reported"
  end

  puts "\n✅ Index generation test complete!"
ensure
  # Clean up
  FileUtils.rm_f('tools/reindex_test.rb')
  FileUtils.rm_rf('test_reindex')
end
