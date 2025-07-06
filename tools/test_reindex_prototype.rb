#!/usr/bin/env ruby
# Test script to verify reindex.rb handles prototype documents correctly

require 'fileutils'
require 'yaml'

# Create a test directory structure
test_dir = 'test_reindex_prototypes'
test_tenets_dir = "#{test_dir}/tenets"
test_bindings_dir = "#{test_dir}/bindings"

FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
FileUtils.mkdir_p(test_tenets_dir)
FileUtils.mkdir_p("#{test_bindings_dir}/core")
FileUtils.mkdir_p("#{test_bindings_dir}/categories/typescript")

# Copy prototype documents to test directory
FileUtils.cp('docs/tenets/simplicity.md', "#{test_tenets_dir}/simplicity.md")
FileUtils.cp('docs/bindings/categories/typescript/no-any.md', "#{test_bindings_dir}/categories/typescript/no-any.md")

# Create a modified copy of reindex.rb to use our test directories
reindex_content = File.read('tools/reindex.rb')
reindex_test = reindex_content.gsub(
  'def get_docs_base_path',
  'def get_docs_base_path_original'
).gsub(
  'base_path = ENV[\'LEYLINE_DOCS_PATH\'] || \'docs\'',
  "base_path = '#{test_dir}'"
).gsub(
  'def get_docs_base_path_original',
  "def get_docs_base_path\n  '#{test_dir}'\nend\n\ndef get_docs_base_path_original"
)
File.write("#{test_dir}/reindex_test.rb", reindex_test)

# Run the test reindex script
system("ruby #{test_dir}/reindex_test.rb")

# Verify the results
tenet_index = File.exist?("#{test_tenets_dir}/00-index.md")
binding_index = File.exist?("#{test_bindings_dir}/00-index.md")

tenet_content = File.read("#{test_tenets_dir}/00-index.md") if tenet_index
binding_content = File.read("#{test_bindings_dir}/00-index.md") if binding_index

# Check for the prototype documents in the index files
tenet_includes_prototype = tenet_content.include?('simplicity') if tenet_content
binding_includes_prototype = binding_content.include?('no-any') if binding_content

# Print results
puts '===== Test Results ====='
puts "Tenet index file created: #{tenet_index ? 'Yes' : 'No'}"
puts "Binding index file created: #{binding_index ? 'Yes' : 'No'}"
puts "Tenet index includes prototype: #{tenet_includes_prototype ? 'Yes' : 'No'}" if tenet_content
puts "Binding index includes prototype: #{binding_includes_prototype ? 'Yes' : 'No'}" if binding_content

# Check the first paragraph extraction
if tenet_content && tenet_includes_prototype
  tenet_summary = begin
    tenet_content.match(%r{\| \[simplicity\]\(\./simplicity\.md\) \| (.*?) \|})[1]
  rescue StandardError
    'Not found'
  end
  puts "\nTenet summary extracted: #{tenet_summary}"
end

if binding_content && binding_includes_prototype
  binding_summary = begin
    binding_content.match(%r{\| \[no-any\]\(\./categories/typescript/no-any\.md\) \| (.*?) \|})[1]
  rescue StandardError
    'Not found'
  end
  puts "\nBinding summary extracted: #{binding_summary}"
end

# Compare with actual first paragraphs
tenet_first_para = begin
  File.read('docs/tenets/simplicity.md').match(/# Tenet:.*?\n\n(.*?)(\n\n|\n#|$)/m)[1].strip.gsub(
    /\s+/, ' '
  )
rescue StandardError
  'Not found'
end
binding_first_para = begin
  File.read('docs/bindings/categories/typescript/no-any.md').match(/# Binding:.*?\n\n(.*?)(\n\n|\n#|$)/m)[1].strip.gsub(
    /\s+/, ' '
  )
rescue StandardError
  'Not found'
end

puts "\nActual tenet first paragraph: #{tenet_first_para}"
puts "Actual binding first paragraph: #{binding_first_para}"

puts "\nTest completed successfully!"

# Clean up test directory
FileUtils.rm_rf(test_dir)
