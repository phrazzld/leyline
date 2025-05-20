#!/usr/bin/env ruby
# tools/reindex.rb - Regenerates index files for tenets and bindings

require 'yaml'

# Process tenets directory - unchanged
def process_tenets_dir
  dir = 'docs/tenets'
  dir_base = dir.split('/').last
  entries = []

  # Get all markdown files except the index
  Dir.glob("#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }.sort.each do |file|
    content = File.read(file)

    # Extract front-matter and first paragraph after title using YAML format
    if content =~ /^---\n(.*?)\n---\s*#[^#]+(.*?)\n\n(.*?)(\n\n|\n#|$)/m
      # Use safe_load for security
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
      # This handles the non-bracketed placeholder case that might appear in templates
      elsif first_para.include?("Write a") && (first_para.include?("paragraph") || first_para.include?("explanation"))
        first_para = "See document for details."
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
  index_content = "# #{dir_base.capitalize} Index\n\n"
  index_content += "This file contains an automatically generated list of all #{dir_base} with their one-line summaries.\n\n"

  # Add entries in a table
  if entries.any?
    index_content += "| ID | Summary |\n"
    index_content += "|---|---|\n"
    entries.each do |entry|
      index_content += "| [#{entry[:id]}](./#{entry[:id]}.md) | #{entry[:summary]} |\n"
    end
  else
    index_content += "_No #{dir_base} defined yet._\n"
  end

  # Write index file
  File.write("#{dir}/00-index.md", index_content)
  puts "Updated #{dir}/00-index.md with #{entries.size} entries"
end

# Process bindings with new directory structure
def process_bindings_dir
  dir = 'docs/bindings'

  # Check for misplaced files in the root directory
  misplaced_files = Dir.glob("#{dir}/*.md").reject { |f| f =~ /00-index\.md$/ }
  misplaced_files.each do |file|
    puts "ERROR: Misplaced binding file found in root directory: #{file}"
    puts "       This file should be moved to either:"
    puts "       - '#{dir}/core/' (if it's a core binding)"
    puts "       - '#{dir}/categories/<category>/' (if it's a category-specific binding)"
  end
  puts "Found #{misplaced_files.size} misplaced binding file(s) in root directory. These will be skipped." unless misplaced_files.empty?

  # Initialize category collections
  core_entries = []
  category_entries = {}

  # 1. Process core bindings
  Dir.glob("#{dir}/core/*.md").sort.each do |file|
    entry = process_binding_file(file)
    if entry
      entry[:path] = "./core/#{File.basename(file)}"
      core_entries << entry
    end
  end

  # 2. Process category bindings
  # Define standard categories that should always be included
  standard_categories = ['backend', 'cli', 'frontend', 'go', 'rust', 'typescript']

  # Initialize all standard categories
  standard_categories.each do |category|
    category_entries[category] = []
  end

  # Get all category directories for processing, adding any non-standard ones
  category_dirs = Dir.glob("#{dir}/categories/*").select { |f| File.directory?(f) }
  category_dirs.each do |category_dir|
    category_name = File.basename(category_dir)
    category_entries[category_name] ||= []
  end

  # Now process files in each category
  category_dirs.each do |category_dir|
    category_name = File.basename(category_dir)

    # Look for markdown files in this category directory
    binding_files = Dir.glob("#{category_dir}/*.md").sort

    # Process each binding file (if any)
    binding_files.each do |file|
      entry = process_binding_file(file)
      if entry
        entry[:path] = "./categories/#{category_name}/#{File.basename(file)}"
        category_entries[category_name] << entry
      end
    end
  end

  # Log the categories we found
  puts "Found #{category_entries.keys.size} category directories: #{category_entries.keys.sort.join(', ')}"
  puts "#{category_entries.values.flatten.size} binding files found across all categories"

  # Generate index content
  index_content = "# Bindings Index\n\n"
  index_content += "This file contains an automatically generated list of all bindings with their one-line summaries.\n\n"

  # Core bindings section
  index_content += "## Core Bindings\n\n"
  if core_entries.any?
    index_content += "| ID | Summary |\n"
    index_content += "|---|---|\n"
    core_entries.each do |entry|
      index_content += "| [#{entry[:id]}](#{entry[:path]}) | #{entry[:summary]} |\n"
    end
  else
    index_content += "_No core bindings defined yet._\n\n"
  end

  # Category sections - process all standard categories in fixed order, then any additional ones
  (standard_categories + (category_entries.keys - standard_categories).sort).each do |category|

    entries = category_entries[category]

    # Use proper title case for category names
    category_title = category.capitalize
    if category =~ /^(ts|go)$/i
      category_title = category.upcase
    elsif category =~ /typescript/i
      category_title = "TypeScript"
    end

    index_content += "\n## #{category_title} Bindings\n\n"

    if entries.any?
      index_content += "| ID | Summary |\n"
      index_content += "|---|---|\n"
      entries.each do |entry|
        index_content += "| [#{entry[:id]}](#{entry[:path]}) | #{entry[:summary]} |\n"
      end
    else
      # Handle empty category gracefully with an informative message
      # This ensures the section appears in the index but clearly indicates it's empty
      index_content += "_No #{category} bindings defined yet._\n"
    end
  end

  # Write index file
  File.write("#{dir}/00-index.md", index_content)
  puts "Updated #{dir}/00-index.md with #{core_entries.size} core entries and #{category_entries.values.flatten.size} category entries"
end

# Helper to process a single binding file and extract metadata
def process_binding_file(file)
  content = File.read(file)

  # Extract front-matter using YAML format
  if content =~ /^---\n(.*?)\n---\s*#[^#]+(.*?)\n\n(.*?)(\n\n|\n#|$)/m
    # Use safe_load for security
    front_matter = YAML.safe_load($1) rescue {}
    title = $2.strip
    first_para = $3.strip.gsub(/\s+/, ' ')

    # Handle placeholders
    if first_para =~ /^\[.*\]$/
      if content =~ /## (Core Belief|Rationale)\s*\n\n(.*?)(\n\n|\n#|$)/m
        section_text = $2.strip.gsub(/\s+/, ' ')
        first_para = section_text =~ /^\[.*\]$/ ? "See document for details." : section_text
      else
        first_para = "See document for details."
      end
    elsif first_para.include?("Write a") && (first_para.include?("paragraph") || first_para.include?("explanation"))
      first_para = "See document for details."
    end

    # Truncate if too long
    summary = first_para.length > 150 ? "#{first_para[0, 147]}..." : first_para

    # Return entry data
    return {
      id: front_matter['id'] || File.basename(file, '.md'),
      summary: summary
    }
  end

  # Return nil if we couldn't parse the file
  nil
end

# Process each directory type
process_tenets_dir
process_bindings_dir
