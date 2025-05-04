#!/usr/bin/env ruby
# tools/reindex.rb - Regenerates index files for tenets and bindings

require 'yaml'

# Process each directory
%w[tenets bindings].each do |dir|
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
  File.write("#{dir}/00-index.md", index_content)
  puts "Updated #{dir}/00-index.md with #{entries.size} entries"
end