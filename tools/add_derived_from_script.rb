#!/usr/bin/env ruby
# Script to add derived_from field to binding files based on mapping CSV

require 'csv'
require 'yaml'

# Read the mapping CSV
mapping_file = 't025_binding_to_tenet_map.csv'

unless File.exist?(mapping_file)
  puts "Error: Mapping file #{mapping_file} not found"
  exit 1
end

success_count = 0
error_count = 0

CSV.foreach(mapping_file, headers: true) do |row|
  file_path = row['binding_file_path']
  tenet_id = row['derived_tenet_id']

  puts "Processing: #{file_path} -> derived_from: #{tenet_id}"

  unless File.exist?(file_path)
    puts "  Error: File not found: #{file_path}"
    error_count += 1
    next
  end

  # Read the file content
  content = File.read(file_path)

  # Extract the YAML front-matter
  if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)/m
    front_matter_str = $1
    body = $2

    begin
      # Parse the YAML
      front_matter = YAML.load(front_matter_str)

      # Add the derived_from field
      front_matter['derived_from'] = tenet_id

      # Sort keys alphabetically
      sorted_front_matter = Hash[front_matter.sort_by { |key, _value| key.to_s }]

      # Generate clean YAML
      new_yaml = YAML.dump(sorted_front_matter).lines[1..-1].join  # Skip the --- from dump

      # Reconstruct the file
      new_content = "---\n#{new_yaml}---\n#{body}"

      # Write back to file
      File.write(file_path, new_content)

      puts "  Success: Added derived_from: #{tenet_id}"
      success_count += 1

    rescue => e
      puts "  Error parsing YAML: #{e.message}"
      error_count += 1
    end
  else
    puts "  Error: Could not parse YAML front-matter"
    error_count += 1
  end
end

puts "\nSummary:"
puts "  Successfully updated: #{success_count} files"
puts "  Errors: #{error_count} files"
puts "\nRun 'ruby tools/validate_front_matter.rb' to verify all changes."
