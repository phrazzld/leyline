#!/usr/bin/env ruby
# tools/test_index_improvements.rb - Tests enhanced index generation

require 'fileutils'
require 'yaml'

# Create test directories if they don't exist
FileUtils.mkdir_p('test_index/tenets')
FileUtils.mkdir_p('test_index/bindings')

# Test cases for different formatting scenarios
test_files = [
  # Tenet with bracketed placeholder text
  {
    path: 'test_index/tenets/placeholder-tenet.md',
    content: <<~MARKDOWN
---
id: placeholder-tenet
last_modified: "2025-05-04"
---

# Tenet: Placeholder Tenet

[This is placeholder text that should not appear in the index]

## Core Belief

[This is also a placeholder that should not appear]

## Practical Guidelines

1. **Test Guideline**: This is just a test guideline.
MARKDOWN
  },

  # Tenet with real content
  {
    path: 'test_index/tenets/real-tenet.md',
    content: <<~MARKDOWN
---
id: real-tenet
last_modified: "2025-05-04"
---

# Tenet: Real Tenet

This is a real tenet that should be indexed correctly.

## Core Belief

The core belief is that indexing should work correctly.
This should not be in the index summary.

## Practical Guidelines

1. **Test Guideline**: This is just a test guideline.
MARKDOWN
  },

  # Tenet with placeholder main text but real core belief
  {
    path: 'test_index/tenets/mixed-tenet.md',
    content: <<~MARKDOWN
---
id: mixed-tenet
last_modified: "2025-05-04"
---

# Tenet: Mixed Tenet

[This is placeholder text that should not appear in the index]

## Core Belief

This is real content that should appear in the index.
This should not appear in the index summary.

## Practical Guidelines

1. **Test Guideline**: This is just a test guideline.
MARKDOWN
  },

  # Binding with placeholder text
  {
    path: 'test_index/bindings/placeholder-binding.md',
    content: <<~MARKDOWN
---
id: placeholder-binding
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: testing
---

# Binding: Placeholder Binding

[This is placeholder text that should not appear in the index]

## Rationale

[This is also a placeholder that should not appear]

## Rule Definition

This is a rule definition for testing purposes.
MARKDOWN
  },

  # Binding with real content
  {
    path: 'test_index/bindings/real-binding.md',
    content: <<~MARKDOWN
---
id: real-binding
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: testing
---

# Binding: Real Binding

This is a real binding that should be indexed correctly.

## Rationale

The rationale is that indexing should work correctly for bindings too.
This should not be in the index summary.

## Rule Definition

This is a rule definition for testing purposes.
MARKDOWN
  },

  # Binding with placeholder main text but real rationale
  {
    path: 'test_index/bindings/mixed-binding.md',
    content: <<~MARKDOWN
---
id: mixed-binding
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: testing
---

# Binding: Mixed Binding

[This is placeholder text that should not appear in the index]

## Rationale

This is real content that should appear in the index for mixed binding.
This should not appear in the index summary.

## Rule Definition

This is a rule definition for testing purposes.
MARKDOWN
  }
]

# Write the test files
test_files.each do |file|
  File.write(file[:path], file[:content])
end

puts "Created test files for enhanced indexing"

# Define the updated indexing logic
def generate_indexes
  %w[tenets bindings].each do |dir|
    entries = []

    # Get all markdown files except the index
    Dir.glob("test_index/#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }.sort.each do |file|
      content = File.read(file)

      # Extract front-matter and first paragraph after title
      if content =~ /^---\n(.*?)\n---\s*#[^#]+(.*?)\n\n(.*?)(\n\n|\n#|$)/m
        front_matter = YAML.safe_load($1) rescue {}
        title = $2.strip
        first_para = $3.strip.gsub(/\s+/, ' ')

        # Skip placeholder text that's enclosed in brackets
        if first_para =~ /^\[.*\]$/
          # Try to find the first real paragraph in the Core Belief/Rationale section
          if content =~ /## (Core Belief|Rationale)\s*\n\n(.*?)(\n\n|\n#|$)/m
            section_text = $2.strip.gsub(/\s+/, ' ')

            # Skip if this is also a placeholder
            if section_text =~ /^\[.*\]$/
              first_para = "See document for details."
            else
              first_para = section_text
            end
          else
            first_para = "See document for details."
          end
        end

        # Truncate if too long
        summary = first_para.length > 150 ? "#{first_para[0, 147]}..." : first_para

        # Add to entries
        entries << {
          id: front_matter['id'] || File.basename(file, '.md'),
          summary: summary
        }
      end
    end

    # Generate index content
    index_content = "# #{dir.capitalize} Index\n\n"
    index_content += "This file contains an automatically generated list of all #{dir} with their one-line summaries.\n\n"

    # Add entries in a table
    if entries.any?
      index_content += "| ID | Summary |\n"
      index_content += "|---|---|\n"
      entries.each do |entry|
        index_content += "| [#{entry[:id]}](./#{entry[:id]}.md) | #{entry[:summary]} |\n"
      end
    else
      index_content += "_No #{dir} defined yet._\n"
    end

    # Write index file
    File.write("test_index/#{dir}/00-index.md", index_content)
    puts "Generated test_index/#{dir}/00-index.md with #{entries.size} entries"
  end
end

# Generate and display the indexes with our improved logic
generate_indexes

# Display the generated indexes
puts "\nGenerated Tenet Index:"
puts File.read('test_index/tenets/00-index.md')

puts "\nGenerated Binding Index:"
puts File.read('test_index/bindings/00-index.md')

# Clean up
puts "\nCleaning up test files..."
FileUtils.rm_rf('test_index')
puts "Test complete"
