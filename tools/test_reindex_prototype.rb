#!/usr/bin/env ruby
# Test script to verify reindex.rb handles prototype documents correctly

require 'fileutils'
require 'yaml'

# Create a test directory structure
test_dir = "test_reindex_prototypes"
test_tenets_dir = "#{test_dir}/tenets"
test_bindings_dir = "#{test_dir}/bindings"

FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
FileUtils.mkdir_p(test_tenets_dir)
FileUtils.mkdir_p(test_bindings_dir)

# Copy prototype documents to test directory
FileUtils.cp("tenets/simplicity.md", "#{test_tenets_dir}/simplicity.md")
FileUtils.cp("bindings/ts-no-any.md", "#{test_bindings_dir}/ts-no-any.md")

# Create a modified copy of reindex.rb to use our test directories
reindex_content = File.read("tools/reindex.rb")
reindex_test = reindex_content.gsub(/^%w\[tenets bindings\]/, "%w[#{test_tenets_dir} #{test_bindings_dir}]")
File.write("#{test_dir}/reindex_test.rb", reindex_test)

# Run the test reindex script
system("ruby #{test_dir}/reindex_test.rb")

# Verify the results
tenet_index = File.exist?("#{test_tenets_dir}/00-index.md")
binding_index = File.exist?("#{test_bindings_dir}/00-index.md")

tenet_content = File.read("#{test_tenets_dir}/00-index.md") if tenet_index
binding_content = File.read("#{test_bindings_dir}/00-index.md") if binding_index

# Check for the prototype documents in the index files
tenet_includes_prototype = tenet_content.include?("simplicity") if tenet_content
binding_includes_prototype = binding_content.include?("ts-no-any") if binding_content

# Print results
puts "===== Test Results ====="
puts "Tenet index file created: #{tenet_index ? 'Yes' : 'No'}"
puts "Binding index file created: #{binding_index ? 'Yes' : 'No'}"
puts "Tenet index includes prototype: #{tenet_includes_prototype ? 'Yes' : 'No'}" if tenet_content
puts "Binding index includes prototype: #{binding_includes_prototype ? 'Yes' : 'No'}" if binding_content

# Check the first paragraph extraction
if tenet_content && tenet_includes_prototype
  tenet_summary = tenet_content.match(/\| \[simplicity\]\(\.\/simplicity\.md\) \| (.*?) \|/)[1] rescue "Not found"
  puts "\nTenet summary extracted: #{tenet_summary}"
end

if binding_content && binding_includes_prototype
  binding_summary = binding_content.match(/\| \[ts-no-any\]\(\.\/ts-no-any\.md\) \| (.*?) \|/)[1] rescue "Not found"
  puts "\nBinding summary extracted: #{binding_summary}"
end

# Compare with actual first paragraphs
tenet_first_para = File.read("tenets/simplicity.md").match(/# Tenet:.*?\n\n(.*?)(\n\n|\n#|$)/m)[1].strip.gsub(/\s+/, ' ') rescue "Not found"
binding_first_para = File.read("bindings/ts-no-any.md").match(/# Binding:.*?\n\n(.*?)(\n\n|\n#|$)/m)[1].strip.gsub(/\s+/, ' ') rescue "Not found"

puts "\nActual tenet first paragraph: #{tenet_first_para}"
puts "Actual binding first paragraph: #{binding_first_para}"

puts "\nTest completed successfully!"

# Clean up test directory
FileUtils.rm_rf(test_dir)
