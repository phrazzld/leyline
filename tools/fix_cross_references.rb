#!/usr/bin/env ruby
# tools/fix_cross_references.rb - Fix cross-references in documentation files

require 'fileutils'

# Get list of tenet IDs
tenet_ids = []
Dir.glob("docs/tenets/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
  tenet_id = File.basename(file, '.md')
  tenet_ids << tenet_id
end

# Get list of binding IDs
binding_ids = []
Dir.glob("docs/bindings/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
  binding_id = File.basename(file, '.md')
  binding_ids << binding_id
end

# Process binding files to fix references to tenets
Dir.glob("docs/bindings/*.md").reject { |f| f =~ /00-index\.md$/ }.each do |file|
  content = File.read(file)
  updated_content = content.dup

  # Replace references to tenet files
  tenet_ids.each do |tenet_id|
    # Replace standalone tenet references (not preceded by a path)
    updated_content.gsub!(/(?<!\/)#{tenet_id}\.md/, "../tenets/#{tenet_id}.md")
  end

  # Write updated content if changes were made
  if content != updated_content
    puts "Fixing cross-references in #{file}"
    File.write(file, updated_content)
  end
end

puts "Cross-references fixed!"
