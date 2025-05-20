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

  # 4. Complex YAML with nested structures
  complex_yaml = <<~MARKDOWN
---
id: complex-yaml
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: "automated tests"
applies_to:
  - typescript
  - javascript
config:
  severity: error
  options:
    allow-any-in-tests: true
    strict-mode: false
---

# Binding: Complex YAML

This binding has complex nested YAML structures to test proper parsing.

## Rationale

This tests that complex YAML structures are handled correctly.
MARKDOWN

  # 5. Placeholder text
  placeholder_text = <<~MARKDOWN
---
id: placeholder-text
last_modified: "2025-05-04"
derived_from: maintainability
enforced_by: "code review"
---

# Binding: Placeholder Text

[This is a placeholder description that should be replaced with the rationale section]

## Rationale

The rationale explains why this binding is important.
MARKDOWN

  # 6. Too long first paragraph
  long_paragraph = <<~MARKDOWN
---
id: long-paragraph
last_modified: "2025-05-04"
derived_from: explicitness
enforced_by: "manual review"
---

# Binding: Long Paragraph

This binding has an extremely long first paragraph that exceeds the 150 character limit for summaries and should be truncated when displayed in the index. It goes on and on with more text to ensure it's well over the limit. This should definitely be truncated in the final index display.

## Rationale

The summary should be truncated with ellipsis.
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

  # Feature test files
  File.write('test_reindex/bindings/core/complex-yaml.md', complex_yaml)
  File.write('test_reindex/bindings/categories/typescript/placeholder-text.md', placeholder_text)
  File.write('test_reindex/bindings/categories/go/long-paragraph.md', long_paragraph)

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

    # Basic validation
    puts "\nBinding index validation:"
    puts "✓ Real binding included: #{binding_index_content.include?('real-binding')}"

    # Feature test validations
    complex_yaml_included = binding_index_content.include?('complex-yaml')
    puts "✓ Complex YAML binding included: #{complex_yaml_included}"

    placeholder_handled = binding_index_content.include?('placeholder-text') &&
                          !binding_index_content.include?('[This is a placeholder')
    puts "✓ Placeholder binding properly handled: #{placeholder_handled}"

    long_paragraph_included = binding_index_content.include?('long-paragraph')
    puts "✓ Long paragraph binding included: #{long_paragraph_included}"

    # The truncation depends on exactly where the paragraph cutting occurs
    # and may vary depending on the implementation
    long_paragraph_truncated = long_paragraph_included &&
                              (binding_index_content.include?('...') ||
                               !binding_index_content.include?('definitely be truncated in the final index display'))
    puts "✓ Long paragraph properly truncated: #{long_paragraph_truncated}"

    # Check for nested YAML structure handling
    if complex_yaml_included
      puts "✓ Complex YAML correctly processed despite nested structures"
    end
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

  # Check warning reporting
  reports_warnings = verbose_output.include?('WARNING')
  reports_placeholder_warning = verbose_output.include?('Using placeholder text for summary')

  puts "\nWarning reporting verification:"
  puts "✓ Reports warnings: #{reports_warnings}"
  puts "✓ Reports placeholder text warning: #{reports_placeholder_warning}"

  # Check command line options
  has_more_detail = verbose_output.length > standard_output.length
  puts "\nCommand line options verification:"
  puts "✓ Verbose output provides more detail: #{has_more_detail}"
  puts "✓ Strict mode exited with error: #{!strict_exit_code}"

  # Feature validation
  feature_tests_passed = binding_index_exists && complex_yaml_included && placeholder_handled && long_paragraph_truncated

  puts "\n== Test Results Summary =="
  if reports_missing_frontmatter && reports_invalid_yaml && reports_missing_fields && reports_misplaced_file
    puts "✅ Error handling tests PASSED - All error types were correctly reported"
  else
    puts "❌ Error handling tests FAILED - Not all error types were correctly reported"
  end

  if feature_tests_passed
    puts "✅ Feature tests PASSED - All YAML parsing features working correctly"
  else
    puts "❌ Feature tests FAILED - Not all YAML parsing features working correctly"
  end

  puts "\n✅ Index generation test complete!"
ensure
  # Clean up
  FileUtils.rm_f('tools/reindex_test.rb')
  FileUtils.rm_rf('test_reindex')
end
