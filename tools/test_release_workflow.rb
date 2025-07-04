#!/usr/bin/env ruby
# test_release_workflow.rb - Integration tests for end-to-end release process
#
# This test suite validates the complete release workflow including
# release preparation, VERSION file updates, CHANGELOG generation,
# and integration between different release tools.

require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'yaml'

class TestReleaseWorkflow < Test::Unit::TestCase
  def setup
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir('release_workflow_test_')
    Dir.chdir(@test_dir)

    # Initialize git repo
    system('git init -q')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')

    # Copy necessary tools to test directory
    copy_release_tools

    # Create basic project structure
    create_project_structure

    # Initial commit and tag
    system('git add .')
    system('git commit -m "feat: initial leyline project" -q')
    system('git tag v0.1.0')
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  def copy_release_tools
    tools_dir = File.join(@original_dir, 'tools')
    FileUtils.mkdir_p('tools')

    # Copy release tools
    %w[
      calculate_version.rb
      prepare_release.rb
      validate_front_matter.rb
      reindex.rb
    ].each do |tool|
      source = File.join(tools_dir, tool)
      FileUtils.cp(source, File.join('tools', tool)) if File.exist?(source)
    end
  end

  def create_project_structure
    # Create VERSION file
    File.write('VERSION', '0.1.0')

    # Create initial CHANGELOG
    File.write('CHANGELOG.md', <<~CHANGELOG)
      # Changelog

      ## [0.1.0] - 2024-01-01
      - Initial release
    CHANGELOG

    # Copy the actual breaking change rules
    source_rules = File.join(@original_dir, 'tools', 'breaking_change_rules.yml')
    if File.exist?(source_rules)
      FileUtils.cp(source_rules, 'tools/breaking_change_rules.yml')
    else
      # Fallback to inline creation with simpler YAML
      File.write('tools/breaking_change_rules.yml', <<~YAML)
        breaking_patterns:
          - "^docs/tenets/.+\\.md$"
          - "^docs/bindings/.+\\.md$"
          - "^docs/bindings/categories/.+/.+\\.md$"
        schema_changes:
          - "tools/validate_front_matter.rb"
      YAML
    end

    # Create basic docs structure
    FileUtils.mkdir_p('docs/tenets')
    FileUtils.mkdir_p('docs/bindings/core')
    FileUtils.mkdir_p('docs/bindings/categories/typescript')

    # Create sample tenet
    File.write('docs/tenets/simplicity.md', <<~TENET)
      ---
      id: simplicity
      title: Simplicity
      version: '0.1.0'
      last_modified: '2024-01-01'
      ---

      # Simplicity

      Keep things simple and understandable.
    TENET

    # Create sample binding
    File.write('docs/bindings/core/api-design.md', <<~BINDING)
      ---
      id: api-design
      title: API Design
      version: '0.1.0'
      last_modified: '2024-01-01'
      category: core
      tenets:
        - simplicity
      ---

      # API Design

      Design clean and intuitive APIs.
    BINDING

    # Create index files
    File.write('docs/tenets/00-index.md', "# Tenets Index\n")
    File.write('docs/bindings/00-index.md', "# Bindings Index\n")
  end

  def create_commits_for_release
    # Create commits that would trigger a release
    create_commit('fix: resolve parsing edge case')
    create_commit('feat: add new validation rules')
    create_commit('docs: update API documentation')
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
      system('git add test_change.tmp')
    end

    # Use a temporary file for multi-line commit messages
    commit_file = 'commit_message.tmp'
    File.write(commit_file, message)
    system("git commit -F #{commit_file} -q")
    File.delete(commit_file) if File.exist?(commit_file)
  end

  def run_tool(tool_name, args = '')
    tool_path = File.join('tools', "#{tool_name}.rb")
    if File.exist?(tool_path)
      output = `ruby #{tool_path} #{args} 2>&1`
      { output: output, success: $?.success? }
    else
      { output: "Tool not found: #{tool_path}", success: false }
    end
  end

  # Test version calculation integration
  def test_version_calculation_with_commits
    create_commits_for_release

    result = run_tool('calculate_version')

    assert result[:success], "Version calculation failed: #{result[:output]}"

    data = JSON.parse(result[:output])

    assert_equal '0.1.0', data['current_version']
    assert_equal '0.2.0', data['next_version'] # feat should bump minor in pre-1.0
    assert_equal 'minor', data['bump_type']
    assert_equal 3, data['commits'].size
  end

  def test_release_preparation_end_to_end
    create_commits_for_release

    # Run release preparation
    result = run_tool('prepare_release', '--verbose')

    assert result[:success], "Release preparation failed: #{result[:output]}"

    # Verify VERSION file was updated
    new_version = File.read('VERSION').strip
    assert_equal '0.2.0', new_version

    # Verify CHANGELOG was updated
    changelog = File.read('CHANGELOG.md')
    assert_includes changelog, '## [0.2.0]'
    assert_includes changelog, 'add new validation rules'
    assert_includes changelog, 'resolve parsing edge case'
  end

  def test_changelog_generation_with_categorization
    # Create commits of different types
    create_commit('feat: implement user authentication system')
    create_commit('feat!: redesign core API

BREAKING CHANGE: The API has been completely redesigned for better usability.')
    create_commit('fix: resolve memory leak in parser')
    create_commit('perf: optimize database queries')
    create_commit('docs: update installation guide')
    create_commit('style: fix code formatting')
    create_commit('test: add integration tests')
    create_commit('chore: update dependencies')

    result = run_tool('prepare_release')

    assert result[:success], "Release preparation failed: #{result[:output]}"

    changelog = File.read('CHANGELOG.md')

    # Should have proper sections
    assert_includes changelog, '## [0.2.0]'
    assert_includes changelog, '### ⚠ BREAKING CHANGES'
    assert_includes changelog, '### 🚀 Features'
    assert_includes changelog, '### 🐛 Bug Fixes'
    assert_includes changelog, '### ⚡ Performance'
    assert_includes changelog, '### 📚 Documentation'
    assert_includes changelog, '### 🧪 Tests'

    # Should include specific commits
    assert_includes changelog, 'implement user authentication system'
    assert_includes changelog, 'resolve memory leak in parser'
    assert_includes changelog, 'optimize database queries'
  end

  def test_breaking_change_detection_and_version_bump
    # Create a breaking change by adding a new tenet file
    create_commit('feat: add new foundational tenet', [
                    { path: 'docs/tenets/reliability.md', content: <<~TENET }
                      ---
                      id: reliability
                      title: Reliability
                      version: '0.2.0'
                      last_modified: '2024-01-02'
                      ---

                      # Reliability

                      Build reliable and robust systems.
                    TENET
                  ])

    result = run_tool('prepare_release')

    assert result[:success], "Release preparation failed: #{result[:output]}"

    # Should detect breaking change and bump minor version (pre-1.0)
    new_version = File.read('VERSION').strip
    assert_equal '0.2.0', new_version

    changelog = File.read('CHANGELOG.md')
    assert_includes changelog, '### ⚠ BREAKING CHANGES'
    assert_includes changelog, 'docs/tenets/reliability.md'
  end

  def test_release_preparation_with_no_commits
    # No commits since last tag
    result = run_tool('prepare_release')

    # Should succeed but not change version
    assert result[:success], "Release preparation failed: #{result[:output]}"

    version = File.read('VERSION').strip
    assert_equal '0.1.0', version

    # Should not modify CHANGELOG
    changelog = File.read('CHANGELOG.md')
    refute_includes changelog, '## [0.2.0]'
  end

  def test_validation_integration
    # Create invalid front-matter to test validation
    create_commit('feat: add invalid tenet', [
                    { path: 'docs/tenets/invalid.md', content: <<~INVALID }
                      ---
                      id: invalid
                      # Missing required fields
                      ---

                      # Invalid Tenet
                    INVALID
                  ])

    # Test that validation catches the error
    validation_result = run_tool('validate_front_matter')

    refute validation_result[:success], 'Validation should have failed for invalid front-matter'
    assert_includes validation_result[:output], 'Missing required keys'
  end

  def test_reindex_integration
    # Test that reindexing works with the project structure
    result = run_tool('reindex')

    assert result[:success], "Reindexing failed: #{result[:output]}"

    # Check that index files were updated
    tenet_index = File.read('docs/tenets/00-index.md')
    binding_index = File.read('docs/bindings/00-index.md')

    assert_includes tenet_index, 'simplicity'
    assert_includes binding_index, 'api-design'
  end

  def test_major_version_migration_post_1_0
    # Simulate being at v1.0.0
    File.write('VERSION', '1.0.0')
    system('git add VERSION')
    system('git commit -m "chore: release 1.0.0" -q')
    system('git tag v1.0.0')

    # Create breaking change
    create_commit('feat!: complete API redesign

BREAKING CHANGE: All existing APIs have been removed and replaced.')

    result = run_tool('prepare_release')

    assert result[:success], "Release preparation failed: #{result[:output]}"

    # Should bump major version post-1.0
    new_version = File.read('VERSION').strip
    assert_equal '2.0.0', new_version

    changelog = File.read('CHANGELOG.md')
    assert_includes changelog, '## [2.0.0]'
    assert_includes changelog, '### ⚠ BREAKING CHANGES'
  end

  def test_release_preparation_error_handling
    # Create an invalid VERSION file
    File.write('VERSION', 'invalid-version-format')
    system('git add VERSION')
    system('git commit -m "Break version file" -q')

    result = run_tool('prepare_release')

    # Should handle error gracefully
    refute result[:success], 'Release preparation should have failed with invalid version'
    assert_includes result[:output].downcase, 'version'
  end

  def test_concurrent_tool_execution
    create_commits_for_release

    # Test that tools can run concurrently without interfering
    threads = []
    results = {}

    threads << Thread.new do
      results[:calculate] = run_tool('calculate_version')
    end

    threads << Thread.new do
      results[:validate] = run_tool('validate_front_matter')
    end

    threads.each(&:join)

    assert results[:calculate][:success], 'Concurrent version calculation failed'
    assert results[:validate][:success], 'Concurrent validation failed'
  end

  def test_large_repository_performance
    # Create a repository with many commits and files
    100.times do |i|
      create_commit("feat: add feature #{i}", [
                      { path: "docs/bindings/core/feature-#{i}.md", content: <<~BINDING }
                        ---
                        id: feature-#{i}
                        title: Feature #{i}
                        version: '0.1.0'
                        last_modified: '2024-01-01'
                        category: core
                        ---

                        # Feature #{i}
                      BINDING
                    ])
    end

    start_time = Time.now
    result = run_tool('prepare_release')
    end_time = Time.now

    duration = end_time - start_time

    assert result[:success], 'Release preparation failed on large repository'
    assert duration < 30, "Release preparation took too long: #{duration} seconds"

    # Verify the release was prepared correctly
    new_version = File.read('VERSION').strip
    assert_equal '0.2.0', new_version
  end

  def test_unicode_and_special_characters
    # Test with unicode and special characters in commit messages and files
    create_commit('feat: add 国际化 support with émojis 🌍')
    create_commit('fix: resolve "quotes" and $pecial chars')

    result = run_tool('prepare_release')

    assert result[:success], 'Release preparation failed with unicode characters'

    changelog = File.read('CHANGELOG.md')
    assert_includes changelog, '国际化'
    assert_includes changelog, 'émojis 🌍'
    assert_includes changelog, '"quotes"'
  end

  def test_release_workflow_integration_with_git_operations
    create_commits_for_release

    # Prepare release
    result = run_tool('prepare_release')
    assert result[:success], 'Release preparation failed'

    # Check that git state is clean after preparation
    git_status = `git status --porcelain`.strip
    assert_empty git_status, 'Git working directory should be clean after release preparation'

    # Check that changes were committed
    last_commit = `git log -1 --pretty=format:"%s"`.strip
    refute_includes last_commit, 'release 0.2.0' # prepare_release shouldn't auto-commit
  end

  # Mock GitHub API for testing release creation
  def test_github_integration_mock
    # This would test GitHub release creation with mocked API
    # For now, we'll test that the workflow would work

    create_commits_for_release
    result = run_tool('prepare_release')

    assert result[:success], 'Release preparation failed'

    # In a real scenario, this would:
    # 1. Create a GitHub release
    # 2. Upload release assets
    # 3. Update the release body with changelog

    # For testing, we verify the changelog format would be suitable for GitHub
    changelog = File.read('CHANGELOG.md')
    assert_includes changelog, '##'  # Proper markdown headers
    assert_includes changelog, '-'   # List items
  end

  private

  def refute_includes(collection, obj, msg = nil)
    assert !collection.include?(obj), msg || "Expected #{collection} to not include #{obj}"
  end
end
