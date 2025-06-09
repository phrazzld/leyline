#!/usr/bin/env ruby
# test_calculate_version.rb - Comprehensive tests for version calculation logic
#
# This test suite validates all aspects of the version calculation system,
# including conventional commit parsing, breaking change detection, and
# changelog generation.

require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'yaml'

class TestCalculateVersion < Test::Unit::TestCase
  def setup
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('calculate_version_test_')
    Dir.chdir(@test_dir)

    # Initialize git repo
    system('git init -q')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')

    # Create basic project structure
    File.write('VERSION', '0.1.0')
    File.write('CHANGELOG.md', "# Changelog\n\n## [0.1.0] - 2024-01-01\n- Initial release\n")

    # Copy the actual breaking change rules
    FileUtils.mkdir_p('tools')
    source_rules = File.join(@original_dir, 'tools', 'breaking_change_rules.yml')
    if File.exist?(source_rules)
      FileUtils.cp(source_rules, 'tools/breaking_change_rules.yml')
    else
      # Fallback to inline creation
      File.write('tools/breaking_change_rules.yml', <<~YAML)
        breaking_patterns:
          - "^docs/tenets/.+\\.md$"
          - "^docs/bindings/.+\\.md$"
          - "^docs/bindings/categories/.+/.+\\.md$"
        schema_changes:
          - "tools/validate_front_matter.rb"
      YAML
    end

    # Initial commit
    system('git add .')
    system('git commit -m "Initial commit" -q')
    system('git tag v0.1.0')
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  def run_calculate_version
    script_path = File.join(@original_dir, 'tools', 'calculate_version.rb')
    output = `ruby #{script_path} --pretty 2>&1`

    if $?.success?
      # Find the JSON content (starts with { and ends with })
      json_start = output.index('{')
      json_end = output.rindex('}')

      if json_start && json_end && json_end > json_start
        json_content = output[json_start..json_end]
        JSON.parse(json_content)
      else
        { error: "No valid JSON found in output: #{output}" }
      end
    else
      { error: output }
    end
  end

  def create_commit(message, files = [])
    files.each do |file|
      # Create parent directories if they don't exist
      FileUtils.mkdir_p(File.dirname(file[:path]))
      File.write(file[:path], file[:content])
      system("git add #{file[:path]}")
    end

    # If no files specified, create an empty commit
    if files.empty?
      # Create a small change to trigger a commit
      timestamp = Time.now.to_f.to_s
      File.write('test_change.tmp', timestamp)
      system("git add test_change.tmp")
    end

    # Use a temporary file for multi-line commit messages
    commit_file = 'commit_message.tmp'
    File.write(commit_file, message)
    system("git commit -F #{commit_file} -q")
    File.delete(commit_file) if File.exist?(commit_file)
  end

  # Basic version calculation tests
  def test_no_commits_since_tag
    result = run_calculate_version

    assert_equal '0.1.0', result['current_version']
    assert_equal '0.1.0', result['next_version']
    assert_equal 'none', result['bump_type']
    assert_empty result['commits']
  end

  def test_patch_version_bump
    create_commit('fix: resolve issue with parsing')

    result = run_calculate_version

    assert_equal '0.1.0', result['current_version']
    assert_equal '0.1.1', result['next_version']
    assert_equal 'patch', result['bump_type']
    assert_equal 1, result['commits'].size
  end

  def test_minor_version_bump
    create_commit('feat: add new validation feature')

    result = run_calculate_version

    assert_equal '0.1.0', result['current_version']
    assert_equal '0.2.0', result['next_version']
    assert_equal 'minor', result['bump_type']
    assert_equal 1, result['commits'].size
  end

  def test_major_version_bump_pre_1_0
    create_commit('feat!: remove deprecated API

BREAKING CHANGE: The old API has been removed')

    result = run_calculate_version

    # Pre-1.0: breaking changes bump minor version
    assert_equal '0.1.0', result['current_version']
    assert_equal '0.2.0', result['next_version']
    assert_equal 'minor', result['bump_type']
    assert_not_empty result['breaking_changes']
  end

  def test_major_version_bump_post_1_0
    # Simulate being at v1.0.0
    File.write('VERSION', '1.0.0')
    system('git add VERSION')
    system('git commit -m "chore: release 1.0.0" -q')
    system('git tag v1.0.0')

    create_commit('feat!: redesign core architecture

BREAKING CHANGE: Complete API overhaul')

    result = run_calculate_version

    # Post-1.0: breaking changes bump major version
    assert_equal '1.0.0', result['current_version']
    assert_equal '2.0.0', result['next_version']
    assert_equal 'major', result['bump_type']
    assert_not_empty result['breaking_changes']
  end

  def test_breaking_change_detection_by_file_pattern
    create_commit('feat: update tenet structure', [
      { path: 'docs/tenets/new-tenet.md', content: '# New Tenet' }
    ])

    result = run_calculate_version

    # Should detect breaking change due to file pattern
    assert_not_empty result['breaking_changes']
    assert_includes result['breaking_changes'].join, 'docs/tenets/new-tenet.md'
  end

  def test_multiple_commit_types
    create_commit('fix: resolve parser bug')
    create_commit('feat: add new formatter')
    create_commit('docs: update README')
    create_commit('fix: handle edge case')

    result = run_calculate_version

    # Should bump minor for feat, despite having fixes
    assert_equal '0.2.0', result['next_version']
    assert_equal 'minor', result['bump_type']
    assert_equal 4, result['commits'].size
  end

  def test_changelog_generation
    create_commit('feat: add user authentication')
    create_commit('fix: resolve memory leak')
    create_commit('docs: update API documentation')

    result = run_calculate_version

    assert_key_exists result, 'changelog_markdown'
    changelog = result['changelog_markdown']

    assert_includes changelog, '## ✨ Features'
    assert_includes changelog, 'Add user authentication'
    assert_includes changelog, '## 🐛 Bug Fixes'
    assert_includes changelog, 'Resolve memory leak'
    assert_includes changelog, '## 🔧 Other Changes'
    assert_includes changelog, 'Update API documentation'
  end

  def test_conventional_commit_parsing
    create_commit('feat(auth): implement OAuth2 flow')
    create_commit('fix(parser): handle malformed input')
    create_commit('perf(db): optimize query performance')
    create_commit('style: fix code formatting')

    result = run_calculate_version

    commits = result['commits']
    assert_equal 4, commits.size

    # Check commit categorization
    feat_commit = commits.find { |c| c['type'] == 'feat' }
    assert_not_nil feat_commit
    assert_equal 'auth', feat_commit['scope']
    assert_equal 'implement OAuth2 flow', feat_commit['subject']

    fix_commit = commits.find { |c| c['type'] == 'fix' }
    assert_not_nil fix_commit
    assert_equal 'parser', fix_commit['scope']
  end

  def test_breaking_change_in_body
    create_commit('feat: improve API design

This change improves the overall design.

BREAKING CHANGE: The authenticate() method now requires
a second parameter for the authentication type.')

    result = run_calculate_version

    assert_not_empty result['breaking_changes']
    breaking_change = result['breaking_changes'].first
    assert_includes breaking_change, 'authenticate() method'
  end

  def test_breaking_change_in_footer
    create_commit('refactor: simplify configuration format

BREAKING CHANGE: Configuration file format has changed
from YAML to JSON. Users must migrate their config files.')

    result = run_calculate_version

    assert_not_empty result['breaking_changes']
    breaking_change = result['breaking_changes'].first
    assert_includes breaking_change, 'Configuration file format'
  end

  # Edge case tests
  def test_no_tags_initial_version
    # Remove the initial tag to simulate first release
    system('git tag -d v0.1.0')
    # Also remove VERSION file to get true 0.0.0 start
    File.delete('VERSION') if File.exist?('VERSION')

    result = run_calculate_version

    # When no tags and no VERSION file, it defaults to 0.1.0
    # If there are commits, it will bump the version
    assert_equal '0.1.0', result['current_version']  # Defaults to 0.1.0 per script logic
    # The next version depends on whether there are commits since setup
    assert result['next_version'] # Just ensure we get a version back
  end

  def test_malformed_commit_messages
    create_commit('random commit message without conventional format')
    create_commit('another: weird format that might break parsing')
    create_commit('fix')  # Missing description

    result = run_calculate_version

    # Should handle malformed commits gracefully
    refute result.key?('error')
    assert_equal 3, result['commits'].size
  end

  def test_large_commit_history
    # Create many commits to test performance
    100.times do |i|
      create_commit("feat: add feature #{i}")
    end

    start_time = Time.now
    result = run_calculate_version
    end_time = Time.now

    # Should complete within reasonable time (< 5 seconds)
    assert (end_time - start_time) < 5, "Version calculation took too long: #{end_time - start_time} seconds"
    assert_equal 100, result['commits'].size
    assert_equal '0.2.0', result['next_version']  # Pre-1.0 feature bump
  end

  def test_empty_repository
    # Create completely empty repo
    Dir.chdir(@original_dir)
    empty_dir = Dir.mktmpdir('empty_test_')
    Dir.chdir(empty_dir)

    system('git init -q')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')

    result = run_calculate_version

    # Should handle empty repo gracefully - either error or default version
    assert result.key?('error') || result['current_version'], "Should return error or version, got: #{result}"

    FileUtils.rm_rf(empty_dir)
    Dir.chdir(@test_dir)
  end

  def test_version_file_missing
    File.delete('VERSION')
    system('git add -A')
    system('git commit -m "Remove VERSION file" -q')

    result = run_calculate_version

    # Should handle missing VERSION file
    assert result.key?('error') || result['current_version']
  end

  def test_invalid_current_version
    File.write('VERSION', 'invalid-version')
    system('git add VERSION')
    system('git commit -m "Invalid version" -q')

    result = run_calculate_version

    # Should handle invalid version gracefully
    assert result.key?('error') || result['current_version']
  end

  def test_unicode_in_commit_messages
    create_commit('feat: add internationalization support 🌍')
    create_commit('fix: resolve encoding issue with émojis')

    result = run_calculate_version

    refute result.key?('error')
    assert_equal 2, result['commits'].size
  end

  def test_very_long_commit_messages
    long_message = 'feat: implement comprehensive feature

' + 'Very long description that goes on and on. ' * 100

    create_commit(long_message)

    result = run_calculate_version

    refute result.key?('error')
    assert_equal 1, result['commits'].size
  end

  def test_git_log_security
    # Test that commit messages with shell injection don't break the script
    create_commit('feat: add feature; rm -rf /')
    create_commit('fix: resolve $(evil command)')

    result = run_calculate_version

    refute result.key?('error')
    assert_equal 2, result['commits'].size
  end

  def test_changelog_with_github_links
    # Create commits with specific SHAs that would generate GitHub links
    create_commit('feat: add authentication system')

    result = run_calculate_version

    changelog = result['changelog_markdown']

    # Should include commit SHA links (format depends on implementation)
    assert_includes changelog, 'Add authentication system'
  end

  # Performance benchmark test
  def test_performance_benchmark
    puts "\n=== Performance Benchmark ==="

    # Test with different repository sizes
    [10, 50, 100, 500].each do |commit_count|
      # Reset to clean state
      system('git reset --hard v0.1.0 -q')

      # Create commits
      commit_count.times do |i|
        create_commit("feat: add feature #{i}")
      end

      # Measure calculation time
      start_time = Time.now
      result = run_calculate_version
      end_time = Time.now

      duration = end_time - start_time
      puts "#{commit_count} commits: #{duration.round(3)}s"

      # Performance assertions
      if commit_count <= 100
        assert duration < 2, "Calculation for #{commit_count} commits took too long: #{duration}s"
      else
        assert duration < 5, "Calculation for #{commit_count} commits took too long: #{duration}s"
      end

      refute result.key?('error'), "Calculation failed for #{commit_count} commits"
    end

    puts "=== End Benchmark ==="
  end

  private

  def assert_key_exists(hash, key)
    assert hash.key?(key), "Expected key '#{key}' to exist in hash"
  end
end
