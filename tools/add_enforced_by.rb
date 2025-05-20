#!/usr/bin/env ruby

require 'yaml'
require 'csv'

# List of files missing enforced_by field
missing_enforced_by = [
  "docs/bindings/categories/go/package-design.md",
  "docs/bindings/categories/typescript/async-patterns.md",
  "docs/bindings/core/automate-changelog.md",
  "docs/bindings/core/code-size.md",
  "docs/bindings/core/external-configuration.md",
  "docs/bindings/core/hex-domain-purity.md",
  "docs/bindings/core/pure-functions.md"
]

# Default enforced_by value
default_enforced_by = "code review & style guides"

# Process each binding file
missing_enforced_by.each do |binding_path|
  puts "Processing #{binding_path}..."

  # Read the file
  content = File.read(binding_path)

  # Extract YAML front-matter
  if content =~ /\A---\n(.*?)\n---\n(.*)/m
    front_matter = $1
    body = $2

    # Parse YAML
    metadata = YAML.load(front_matter)

    # Add enforced_by field if not present
    if !metadata['enforced_by']
      metadata['enforced_by'] = default_enforced_by

      # Convert back to YAML (maintaining consistent style)
      new_front_matter = metadata.to_yaml
      # Remove the document separator that to_yaml adds
      new_front_matter = new_front_matter.gsub(/^---\n/, '')

      # Reconstruct the file
      new_content = "---\n#{new_front_matter}---\n#{body}"

      # Write back
      File.write(binding_path, new_content)
      puts "  Added enforced_by: #{default_enforced_by}"
    else
      puts "  Already has enforced_by: #{metadata['enforced_by']}"
    end
  else
    puts "  ERROR: No YAML front-matter found"
  end
end
