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
  # Get all category directories for processing
  category_dirs = Dir.glob("#{dir}/categories/*").select { |f| File.directory?(f) }

  # Track empty categories for informational purposes
  empty_categories = []

  category_dirs.each do |category_dir|
    category_name = File.basename(category_dir)
    category_entries[category_name] = []

    # Look for markdown files in this category directory
    binding_files = Dir.glob("#{category_dir}/*.md").sort

    # If no binding files found, track this as an empty category
    if binding_files.empty?
      empty_categories << category_name
    end

    # Process each binding file (if any)
    binding_files.each do |file|
      entry = process_binding_file(file)
      if entry
        entry[:path] = "./categories/#{category_name}/#{File.basename(file)}"
        category_entries[category_name] << entry
      end
    end
  end

  # Log empty categories if any were found
  unless empty_categories.empty?
    puts "NOTE: Found #{empty_categories.size} empty category directories: #{empty_categories.join(', ')}"
    puts "      These categories will appear in the index with an 'empty' message."
  end

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

  # Add empty backend and CLI sections
  index_content += "\n## Backend Bindings\n\n"
  index_content += "_No backend bindings defined yet._\n"

  index_content += "\n## Cli Bindings\n\n"
  index_content += "_No cli bindings defined yet._\n"

  # Category sections
  category_entries.keys.sort.each do |category|
    # Skip backend and cli categories as they're handled separately
    next if category == "backend" || category == "cli"

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

  # Extract front-matter (using the underscores format) and first paragraph after title
  # The format is:
  # ______________________________________________________________________
  #
  # id: some-id enforced_by: some-value
  #
  # ______________________________________________________________________
  if content =~ /^______________________________________________________________________\n\n(.*?)\n\n______________________________________________________________________\s*#[^#]+(.*?)\n\n(.*?)(\n\n|\n#|$)/m
    front_matter_text = $1
    title = $2.strip
    first_para = $3.strip.gsub(/\s+/, ' ')

    # Parse the front matter
    front_matter = {}
    front_matter_text.scan(/(\w+(?:-\w+)*): ([^:]*)(?=\s+\w+:|\s*$)/).each do |key, value|
      front_matter[key] = value.strip
    end

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

    # Return entry data
    return {
      id: front_matter['id'] || File.basename(file, '.md'),
      summary: summary
    }
  end

  # If we couldn't match the custom format, try the standard YAML format
  if content =~ /^---\n(.*?)\n---\s*#[^#]+(.*?)\n\n(.*?)(\n\n|\n#|$)/m
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
