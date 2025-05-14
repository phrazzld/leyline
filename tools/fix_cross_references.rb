#!/usr/bin/env ruby
# tools/fix_cross_references.rb - Fix cross-references in documentation files after directory restructuring

require 'fileutils'

# Build a mapping of binding names to their new locations
def build_binding_map
  binding_map = {}

  # Map core bindings
  Dir.glob("docs/bindings/core/*.md").each do |path|
    next if path.end_with?("00-index.md")
    name = File.basename(path, ".md")
    binding_map[name] = path
  end

  # Map category bindings
  Dir.glob("docs/bindings/categories/*/*.md").each do |path|
    next if path.end_with?("00-index.md")
    name = File.basename(path, ".md")
    category = path.split("/")[-2]

    # Store both with and without prefixes
    binding_map[name] = path

    # For prefixed names (e.g., go-package-design, ts-no-any)
    prefixed_name = "#{category}-#{name}"
    binding_map[prefixed_name] = path
  end

  puts "Created mapping for #{binding_map.size} bindings"
  binding_map
end

# Fix links in markdown files
def fix_links(binding_map)
  # Find all markdown files
  markdown_files = Dir.glob("**/*.md").reject do |file|
    file.start_with?("venv/") ||
    file.start_with?("node_modules/") ||
    file.start_with?("site/")
  end

  puts "Processing #{markdown_files.size} markdown files"

  fixed_files = 0

  markdown_files.each do |file|
    content = File.read(file)
    original = content.dup
    updated = false

    # Fix absolute tenet links: /tenets/X.md -> docs/tenets/X.md
    if content.match(%r{(?<!\./)\]/tenets/([a-z0-9-]+\.md)})
      content.gsub!(%r{(?<!\./)\]/tenets/([a-z0-9-]+\.md)}i, '](docs/tenets/\1')
      updated = true
    end

    # Fix absolute binding links: /bindings/X.md -> new path from mapping
    if content.match(%r{(?<!\./)\]/bindings/([a-z0-9-]+\.md)})
      content.gsub!(%r{(?<!\./)\]/bindings/([a-z0-9-]+\.md)}i) do |match|
        binding_name = $1.sub(".md", "")
        if binding_map[binding_name]
          "](#{binding_map[binding_name]})"
        else
          puts "  Warning: Could not find binding '#{binding_name}' in map for file #{file}"
          match # Keep original if not found
        end
      end
      updated = true
    end

    # Fix relative links between bindings (files in docs/bindings/core and docs/bindings/categories/*)
    binding_directories = [
      "docs/bindings/core",
      *Dir.glob("docs/bindings/categories/*")
    ]

    if binding_directories.any? { |dir| file.start_with?(dir) }
      # This is a binding file, fix references to other bindings

      # Fix relative links to tenets from bindings
      if content.match(%r{\]\(\.\./tenets/([a-z0-9-]+\.md)\)})
        content.gsub!(%r{\]\(\.\./tenets/([a-z0-9-]+\.md)\)}, "](../../docs/tenets/\\1)")
        updated = true
      end

      # Fix relative links to bindings
      content.gsub!(%r{\]\(docs/bindings/([^)]+)\)}) do |match|
        puts "  Fixed absolute binding path in #{file}: #{match}"
        "](../../docs/bindings/#{$1})"
      end

      # Fix simple relative bindings like "](name.md)"
      binding_map.each do |name, path|
        if content.match(/\]\(#{Regexp.escape(name)}\.md\)/)
          content.gsub!(/\]\(#{Regexp.escape(name)}\.md\)/, "](../../#{path})")
          updated = true
        end
      end

      # Fix directory-based references like "./name.md"
      if content.match(%r{\]\(\./([a-z0-9-]+)\.md\)})
        content.gsub!(%r{\]\(\./([a-z0-9-]+)\.md\)}) do |match|
          name = $1
          if binding_map[name]
            "](../../#{binding_map[name]})"
          else
            puts "  Warning: Could not find binding for ./#{name}.md in #{file}"
            match
          end
        end
        updated = true
      end
    end

    # Write back if updated
    if content != original
      File.write(file, content)
      fixed_files += 1
      puts "Updated links in #{file}"
    end
  end

  puts "Fixed links in #{fixed_files} files"
end

# Main execution
binding_map = build_binding_map
fix_links(binding_map)
puts "Cross-references fixed!"
