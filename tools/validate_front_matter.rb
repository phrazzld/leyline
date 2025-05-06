#!/usr/bin/env ruby
# tools/validate_front_matter.rb - Validates front-matter in Markdown files

require 'yaml'
require 'date'

# Configuration
REQUIRED_KEYS = {
  'tenets' => %w[id last_modified], 
  'bindings' => %w[id last_modified derived_from enforced_by]
}

# Optional keys that have validation rules when present
OPTIONAL_KEYS = {
  'bindings' => {
    'applies_to' => ->(value) { value.is_a?(Array) && value.all? { |v| v.is_a?(String) } }
  }
}

# Valid values for applies_to field
VALID_CONTEXTS = [
  # Languages
  'typescript', 'javascript', 'go', 'rust', 'python', 'java', 'csharp', 'ruby',
  # Environments
  'frontend', 'backend', 'mobile', 'desktop', 'cli', 'library', 'service',
  # Special values
  'all'
]

# Track all ids to ensure uniqueness
all_ids = {}

# Process directories
%w[docs/tenets docs/bindings].each do |dir|
  dir_base = dir.split('/').last
  puts "Validating #{dir_base}..."
  
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
      missing_keys = REQUIRED_KEYS[dir_base] - front_matter.keys
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
      if dir_base == 'bindings' && front_matter['derived_from']
        tenet_file = Dir.glob("docs/tenets/#{front_matter['derived_from']}.md").first
        unless tenet_file
          puts "  [ERROR] #{file}: References non-existent tenet '#{front_matter['derived_from']}'"
          exit 1
        end
      end
      
      # Validate optional keys if present
      if dir_base == 'bindings' && OPTIONAL_KEYS['bindings']
        OPTIONAL_KEYS['bindings'].each do |key, validator|
          if front_matter.key?(key)
            unless validator.call(front_matter[key])
              puts "  [ERROR] #{file}: Invalid format for '#{key}'"
              exit 1
            end
            
            # Additional validation for applies_to values
            if key == 'applies_to'
              invalid_contexts = front_matter[key] - VALID_CONTEXTS
              unless invalid_contexts.empty?
                puts "  [WARNING] #{file}: Unknown context(s) in 'applies_to': #{invalid_contexts.join(', ')}"
                puts "  Valid contexts are: #{VALID_CONTEXTS.join(', ')}"
              end
              
              # Auto-detect language specific bindings without proper applies_to
              if file =~ /\/(ts|js|go|rust|py|java|cs|rb)-/ && !front_matter[key].any? { |v| v =~ /^(typescript|javascript|go|rust|python|java|csharp|ruby)$/ }
                prefix = $1
                language_map = {
                  'ts' => 'typescript', 'js' => 'javascript', 'go' => 'go', 
                  'rust' => 'rust', 'py' => 'python', 'java' => 'java', 
                  'cs' => 'csharp', 'rb' => 'ruby'
                }
                puts "  [WARNING] #{file}: Has prefix '#{prefix}-' but doesn't include '#{language_map[prefix]}' in applies_to"
              end
            end
          end
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