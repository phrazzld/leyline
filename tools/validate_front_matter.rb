#!/usr/bin/env ruby
# tools/validate_front_matter.rb - Validates front-matter in Markdown files

require 'yaml'
require 'date'

# Configuration
REQUIRED_KEYS = {
  'tenets' => %w[id last_modified], 
  'bindings' => %w[id last_modified derived_from enforced_by]
}

# Track all ids to ensure uniqueness
all_ids = {}

# Process directories
%w[tenets bindings].each do |dir|
  puts "Validating #{dir}..."
  
  # Skip index files
  Dir.glob("#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
    content = File.read(file)
    
    # Extract front-matter
    if content =~ /^---\n(.*?)\n---/m
      yaml_content = $1
      begin
        front_matter = YAML.safe_load(yaml_content)
      rescue => e
        puts "  [ERROR] #{file}: Invalid YAML in front-matter: #{e.message}"
        puts "  YAML content: #{yaml_content.inspect}"
        exit 1
      end
      
      if front_matter.nil?
        puts "  [ERROR] #{file}: Empty YAML in front-matter"
        exit 1
      end
      
      # Check required keys
      missing_keys = REQUIRED_KEYS[dir] - front_matter.keys
      unless missing_keys.empty?
        puts "  [ERROR] #{file}: Missing required keys: #{missing_keys.join(', ')}"
        exit 1
      end
      
      # Check for unique ID
      id = front_matter['id']
      if all_ids[id]
        puts "  [ERROR] #{file}: Duplicate ID '#{id}' (already used in #{all_ids[id]})"
        exit 1
      end
      all_ids[id] = file
      
      # Validate date format
      date = front_matter['last_modified']
      unless date.is_a?(Date) || date.is_a?(String) && date =~ /^\d{4}-\d{2}-\d{2}$/
        puts "  [ERROR] #{file}: Invalid date format in 'last_modified'"
        exit 1
      end
      
      # For bindings, validate that derived_from exists
      if dir == 'bindings' && front_matter['derived_from']
        tenet_file = Dir.glob("tenets/#{front_matter['derived_from']}.md").first
        unless tenet_file
          puts "  [ERROR] #{file}: References non-existent tenet '#{front_matter['derived_from']}'"
          exit 1
        end
      end
      
      puts "  [OK] #{file}"
    else
      puts "  [ERROR] #{file}: No front-matter found"
      exit 1
    end
  end
end

puts "All files validated successfully!"