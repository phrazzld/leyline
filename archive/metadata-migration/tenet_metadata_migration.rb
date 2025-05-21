#!/usr/bin/env ruby
# Script to convert legacy horizontal rule metadata to YAML front-matter in tenet files

require 'yaml'

def convert_file(file_path)
  puts "Converting #{file_path}..."
  content = File.read(file_path)

  # Skip files that already have YAML front-matter
  if content.start_with?('---')
    puts "  File already has YAML front-matter, skipping"
    return false
  end

  # Skip files that don't have the legacy format
  unless content.start_with?('______________________________________________________________________')
    puts "  File doesn't have legacy format, skipping"
    return false
  end

  # Extract metadata from legacy format
  # The pattern is a horizontal rule followed by metadata in the format: ## id: value last_modified: 'date'
  metadata_line = content.lines[2].strip

  # Parse id and last_modified from the metadata line
  id_match = metadata_line.match(/id:\s*([\w-]+)/)
  last_modified_match = metadata_line.match(/last_modified:\s*'([^']+)'/)

  if !id_match || !last_modified_match
    puts "  Failed to extract metadata from file"
    return false
  end

  id = id_match[1]
  last_modified = last_modified_match[1]

  # Prepare YAML front-matter as a string directly
  yaml_front_matter = "---\nid: #{id}\nlast_modified: '#{last_modified}'\n---\n"

  # Remove the horizontal rule and metadata line from the content
  # The content starts after the metadata line (index 3 in lines array)
  new_content = content.lines[3..-1].join

  # Combine YAML front-matter with content
  final_content = yaml_front_matter + new_content

  # Write back to file
  File.write(file_path, final_content)
  puts "  Successfully converted"
  true
end

def main
  # Get all tenet files
  tenet_files = Dir.glob('docs/tenets/*.md')

  converted_count = 0
  skipped_count = 0

  tenet_files.each do |file|
    success = convert_file(file)
    success ? converted_count += 1 : skipped_count += 1
  end

  puts "\nMigration complete!"
  puts "Files converted: #{converted_count}"
  puts "Files skipped: #{skipped_count}"
end

# Run the script
main
