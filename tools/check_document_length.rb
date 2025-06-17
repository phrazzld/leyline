#!/usr/bin/env ruby
# frozen_string_literal: true

# Check that tenet and binding documents don't exceed maximum line counts
# Usage: ruby tools/check_document_length.rb [files...]

require 'optparse'

MAX_LINES = 400
TENET_MAX_LINES = 150

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: check_document_length.rb [options] [files...]"

  opts.on("-v", "--verbose", "Verbose output") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Get files to check
files = ARGV.empty? ? Dir.glob("docs/{tenets,bindings}/**/*.md") : ARGV

violations = []
checked_count = 0

files.each do |file|
  next unless File.exist?(file)
  next if file.include?("00-index.md") # Skip index files

  checked_count += 1
  line_count = File.readlines(file).size

  # Determine limit based on file type
  limit = if file.include?("/tenets/")
    TENET_MAX_LINES
  else
    MAX_LINES
  end

  if line_count > limit
    violations << {
      file: file,
      lines: line_count,
      limit: limit,
      excess: line_count - limit
    }
  elsif options[:verbose]
    puts "✓ #{file}: #{line_count} lines (limit: #{limit})"
  end
end

if violations.empty?
  puts "✅ All #{checked_count} documents are within length limits" if options[:verbose]
  exit 0
else
  puts "❌ #{violations.size} document(s) exceed length limits:\n\n"

  violations.each do |v|
    puts "  #{v[:file]}: #{v[:lines]} lines (#{v[:excess]} over #{v[:limit]} limit)"
  end

  puts "\nPlease refactor these documents to be more concise:"
  puts "  - Tenets should be ≤#{TENET_MAX_LINES} lines"
  puts "  - Bindings should be ≤#{MAX_LINES} lines"
  puts "  - Use ONE clear example instead of multiple languages"
  puts "  - Focus on principles over implementation details"

  exit 1
end
