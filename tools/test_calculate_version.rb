#!/usr/bin/env ruby
# test_calculate_version.rb - Tests for version calculation script

require 'test/unit'
require 'json'
require_relative 'calculate_version'

class TestVersionCalculation < Test::Unit::TestCase
  def test_script_outputs_valid_json
    # This test should pass when the script is implemented
    output = `ruby tools/calculate_version.rb 2>/dev/null`
    assert_not_nil output
    assert_not_empty output.strip

    # Should be valid JSON
    result = JSON.parse(output)
    assert result.is_a?(Hash)

    # Should have required fields
    assert result.key?('current_version')
    assert result.key?('next_version')
    assert result.key?('bump_type')
    assert result.key?('commits')
    assert result.key?('breaking_changes')
  end

  def test_current_version_detection
    # Should detect current version from git tags
    result = calculate_version_for_test
    assert_match /^\d+\.\d+\.\d+$/, result['current_version']
  end

  def test_version_bump_logic_pre_1_0
    # In pre-1.0, breaking changes should bump minor version
    # Features should bump minor version
    # Fixes should bump patch version
    result = calculate_version_for_test
    current = result['current_version']
    assert current.start_with?('0.'), "Expected pre-1.0 version, got #{current}"
  end

  def test_changelog_markdown_field_exists
    # Should include changelog_markdown field in output
    result = calculate_version_for_test
    assert result.key?('changelog_markdown')
    assert result['changelog_markdown'].is_a?(String)
  end

  def test_changelog_markdown_has_sections
    # Should have proper markdown sections for different commit types
    result = calculate_version_for_test
    changelog = result['changelog_markdown']

    # Should have sections for features and fixes (based on current commit history)
    assert changelog.include?('## '), "Expected markdown headers in changelog"

    # Should have commit links
    assert changelog.include?('['), "Expected markdown links in changelog"
  end

  private

  def calculate_version_for_test
    output = `ruby tools/calculate_version.rb 2>/dev/null`
    JSON.parse(output)
  end
end
