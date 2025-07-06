#!/usr/bin/env ruby
# test_add_version_to_metadata.rb - Test the version migration script
#
# This script tests the add_version_to_metadata.rb migration tool to ensure
# it correctly adds version fields while preserving YAML validity.

require 'yaml'
require 'tmpdir'
require 'fileutils'

def create_test_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def test_migration_script
  Dir.mktmpdir do |tmpdir|
    # Create test VERSION file
    File.write(File.join(tmpdir, 'VERSION'), '0.1.0')

    # Create test directory structure
    docs_dir = File.join(tmpdir, 'docs')
    tenets_dir = File.join(docs_dir, 'tenets')
    bindings_dir = File.join(docs_dir, 'bindings', 'core')

    # Test case 1: Simple tenet
    create_test_file(File.join(tenets_dir, 'test1.md'), <<~CONTENT)
      ---
      id: test1
      last_modified: '2025-06-08'
      ---

      # Test Tenet 1
      Content here.
    CONTENT

    # Test case 2: Binding with more fields
    create_test_file(File.join(bindings_dir, 'test2.md'), <<~CONTENT)
      ---
      id: test2
      derived_from: test1
      enforced_by: automation
      last_modified: '2025-06-08'
      ---

      # Test Binding 2
      Content here.
    CONTENT

    # Test case 3: File with existing version (should be skipped)
    create_test_file(File.join(tenets_dir, 'test3.md'), <<~CONTENT)
      ---
      id: test3
      last_modified: '2025-06-08'
      version: '0.0.9'
      ---

      # Test Tenet 3
      Already has version.
    CONTENT

    # Change to temp directory for test
    original_dir = Dir.pwd
    Dir.chdir(tmpdir)

    begin
      # Run migration
      script_path = File.join(original_dir, 'tools', 'add_version_to_metadata.rb')
      output = `ruby #{script_path} 2>&1`
      success = $?.success?

      unless success
        puts 'ERROR: Migration script failed'
        puts output
        return false
      end

      # Verify results
      errors = []

      # Check test1.md
      content1 = File.read(File.join(tenets_dir, 'test1.md'))
      yaml1 = YAML.safe_load(content1.split('---')[1])
      errors << "test1.md: version not added correctly (got: #{yaml1['version']})" unless yaml1['version'] == '0.1.0'

      # Check test2.md
      content2 = File.read(File.join(bindings_dir, 'test2.md'))
      yaml2 = YAML.safe_load(content2.split('---')[1])
      errors << "test2.md: version not added correctly (got: #{yaml2['version']})" unless yaml2['version'] == '0.1.0'

      # Check test3.md (should still have old version)
      content3 = File.read(File.join(tenets_dir, 'test3.md'))
      yaml3 = YAML.safe_load(content3.split('---')[1])
      errors << "test3.md: existing version was changed (got: #{yaml3['version']})" unless yaml3['version'] == '0.0.9'

      # Check that content after YAML is preserved
      errors << 'test1.md: content after YAML was lost' unless content1.include?('# Test Tenet 1')

      if errors.empty?
        puts '✅ All tests passed!'
        puts '   - Version field added correctly'
        puts '   - Existing versions preserved'
        puts '   - YAML remains valid'
        puts '   - Content preserved'
        return true
      else
        puts '❌ Tests failed:'
        errors.each { |e| puts "   - #{e}" }
        return false
      end
    ensure
      Dir.chdir(original_dir)
    end
  end
end

# Run tests
if test_migration_script
  exit 0
else
  exit 1
end
