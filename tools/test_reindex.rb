#!/usr/bin/env ruby
# tools/test_reindex.rb - Tests index generation with template files

require 'fileutils'

# Create test directories
FileUtils.mkdir_p('test_reindex/tenets')
FileUtils.mkdir_p('test_reindex/bindings')

begin
  # Copy templates to test directories
  FileUtils.cp('docs/templates/tenet_template.md', 'test_reindex/tenets/tenet_template.md')
  FileUtils.cp('docs/templates/binding_template.md', 'test_reindex/bindings/binding_template.md')

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

  # Write the comparison files
  File.write('test_reindex/tenets/real-tenet.md', real_tenet_content)
  File.write('test_reindex/bindings/real-binding.md', real_binding_content)

  # Run the indexing script (use our real script, not a copy)
  puts "Testing reindex.rb with template files and actual content..."

  # Temporarily modify the script to use our test directories
  original_reindex = File.read('tools/reindex.rb')
  test_reindex = original_reindex.gsub(
    'Dir.glob("#{dir}/*.md")',
    'Dir.glob("test_reindex/#{dir}/*.md")'
  ).gsub(
    'File.write("#{dir}/00-index.md"',
    'File.write("test_reindex/#{dir}/00-index.md"'
  )
  File.write('tools/reindex_test.rb', test_reindex)

  # Run the modified script
  system('ruby tools/reindex_test.rb')

  # Show the results
  puts "\nGenerated Tenet Index:"
  puts File.read('test_reindex/tenets/00-index.md')

  puts "\nGenerated Binding Index:"
  puts File.read('test_reindex/bindings/00-index.md')

  puts "\n✅ Index generation test complete!"
ensure
  # Clean up
  FileUtils.rm_f('tools/reindex_test.rb')
  FileUtils.rm_rf('test_reindex')
end
