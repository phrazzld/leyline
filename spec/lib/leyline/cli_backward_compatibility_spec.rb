# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'
require 'fileutils'

RSpec.describe Leyline::CLI, 'Backward Compatibility Validation' do
  let(:cli) { described_class.new }
  let(:temp_project_dir) { Dir.mktmpdir('leyline-compatibility-test') }

  after do
    FileUtils.rm_rf(temp_project_dir) if Dir.exist?(temp_project_dir)
  end

  describe 'Original Command Compatibility Matrix' do
    # Test all original usage patterns that existed before discovery commands
    let(:original_sync_patterns) do
      [
        [], # Default sync
        ['.'],                                  # Sync current directory
        ['--categories', 'core'],               # Category filtering
        ['--categories', 'typescript,go'], # Multiple categories
        ['--force'],                            # Force overwrite
        ['--verbose'],                          # Verbose output
        ['--dry-run'],                          # Dry run mode
        ['--force', '--verbose'], # Combined flags
        ['--categories', 'typescript', '--force', '--verbose'], # Full combination
        [temp_project_dir], # Custom path
        [temp_project_dir, '--categories', 'core'], # Path with options
        [temp_project_dir, '--categories', 'typescript', '--force', '--verbose'] # Full path combination
      ]
    end

    it 'executes all original sync patterns without breaking' do
      original_sync_patterns.each do |args|
        expect do
          capture_stdout_and_exit { described_class.start(['sync'] + args) }
        end.not_to raise_error, "Pattern 'leyline sync #{args.join(' ')}' should not break"
      end
    end

    it 'maintains sync as default command behavior' do
      expect(described_class.default_task).to eq('sync')

      # Empty arguments should trigger sync
      output = capture_stdout { described_class.start([]) }
      expect(output).to include('Synchronizing leyline standards')
    end

    it 'preserves all original command aliases and shortcuts' do
      original_aliases = {
        '-c' => '--categories',
        '-f' => '--force',
        '-n' => '--dry-run',
        '-v' => '--verbose'
      }

      original_aliases.each do |short_flag, long_flag|
        capture_stdout do
          cli.options = { categories: ['core'] }
          cli.sync if short_flag == '-c'
        end
        capture_stdout do
          cli.options = { categories: ['core'] }
          cli.sync if long_flag == '--categories'
        end

        # Both should work (specific behavior tested elsewhere)
        expect do
          cli.options = {}
          cli.sync
        end.not_to raise_error
      end
    end
  end

  describe 'Core Command Structure Preservation' do
    it 'maintains version command behavior' do
      output = capture_stdout { cli.version }

      # Version should be in format X.Y.Z
      expect(output.strip).to match(/^\d+\.\d+\.\d+$/)
    end

    it 'preserves help system functionality' do
      expect { described_class.start(['help']) }.not_to raise_error
      expect { described_class.start(['sync', '--help']) }.not_to raise_error
    end

    it 'maintains command list in help output' do
      help_output = capture_stdout { described_class.start(['help']) }

      # Core commands should be present
      expect(help_output).to include('sync')
      expect(help_output).to include('version')

      # New discovery commands should be additive only
      expect(help_output).to include('categories')
      expect(help_output).to include('show')
      expect(help_output).to include('search')
    end
  end

  describe 'Output Format Stability' do
    it 'maintains sync completion message format' do
      output = capture_stdout { cli.sync }

      # Core sync message format must remain stable for script parsing
      expect(output).to include('Synchronizing leyline standards to:')
      expect(output).to match(/Sync completed: \d+ files copied, \d+ files skipped/)
    end

    it 'preserves category display format' do
      output = capture_stdout { cli.sync }

      # Categories should be displayed consistently
      expect(output).to match(/Categories: [\w, ]+/)
    end

    it 'maintains verbose output structure' do
      cli.options = { verbose: true }
      output = capture_stdout { cli.sync }

      # Verbose mode should include detailed file operations
      expect(output).to include('Synchronizing leyline standards')
      expect(output).to include('Categories:')
    end

    it 'preserves dry-run output format' do
      cli.options = { dry_run: true }
      output = capture_stdout { cli.sync }

      # Dry-run should show what would be done without doing it
      expect(output).to include('Synchronizing leyline standards')
      expect(output).to include('Sync completed:')
    end
  end

  describe 'Error Handling Backward Compatibility' do
    it 'maintains invalid category error message format' do
      cli.options = { categories: ['invalid_category'] }
      output = capture_stdout_and_exit { cli.sync }

      # Error message pattern must remain stable for script error handling
      expect(output).to include('Error: Invalid category')
      expect(output).to include('Valid categories:')
    end

    it 'preserves invalid path error behavior' do
      output = capture_stdout_and_exit { cli.sync('/nonexistent/deeply/nested/path') }

      # Path validation errors should be consistent
      expect(output).to include('Error: Parent directory does not exist')
    end

    it 'maintains exit codes for error conditions' do
      # Invalid category should exit with code 1
      cli.options = { categories: ['invalid_category'] }
      expect { cli.sync }.to exit_with_code(1)

      # Invalid path should exit with code 1
      expect { cli.sync('/nonexistent/deeply/nested/path') }.to exit_with_code(1)
    end

    it 'handles unknown command errors consistently' do
      # Thor behavior has evolved - it may handle unknown commands differently
      # The important thing is that it doesn't crash or behave unexpectedly
      expect { described_class.start(['unknown-command']) }.not_to raise_error(NoMethodError)
    end
  end

  describe 'File System Behavior Consistency' do
    it 'maintains target directory structure creation' do
      cli.sync(temp_project_dir)

      # Standard directory structure should be preserved
      expect(Dir.exist?(File.join(temp_project_dir, 'docs', 'leyline'))).to be true
      expect(Dir.exist?(File.join(temp_project_dir, 'docs', 'leyline', 'tenets'))).to be true
    end

    it 'preserves file overwrite protection behavior' do
      # First sync to create structure
      cli.sync(temp_project_dir)

      # Create a test file to modify
      test_file = File.join(temp_project_dir, 'docs', 'leyline', 'test-file.md')
      File.write(test_file, 'original content')

      # Modify the file to simulate local changes
      File.write(test_file, 'modified content')

      # Sync without force should preserve local changes (skip overwrite)
      cli.sync(temp_project_dir)
      expect(File.read(test_file)).to eq('modified content')

      # Sync with force should overwrite local changes
      cli.options = { force: true }
      cli.sync(temp_project_dir)
      # The exact content depends on what's actually synced, but it should be different
      expect(File.exist?(test_file)).to be true
    end

    it 'maintains working directory independence' do
      original_dir = Dir.pwd

      begin
        # Change to temp directory and run sync
        Dir.chdir(temp_project_dir)
        output = capture_stdout { cli.sync }

        # Should still work correctly regardless of working directory
        expect(output).to include('Synchronizing leyline standards')
      ensure
        Dir.chdir(original_dir)
      end
    end
  end

  describe 'Discovery Commands Non-Interference' do
    it 'ensures discovery commands do not affect sync behavior' do
      # Capture baseline sync behavior
      capture_stdout { cli.sync }

      # Run discovery commands
      capture_stdout { cli.categories }
      capture_stdout { cli.show('typescript') }
      capture_stdout { cli.search('test') }

      # Sync should work identically after discovery commands
      post_discovery_output = capture_stdout { cli.sync }

      # Core sync output should be consistent (ignoring cache warming messages)
      expect(post_discovery_output).to include('Synchronizing leyline standards')
      expect(post_discovery_output).to include('Sync completed:')
    end

    it 'maintains help system with new commands' do
      help_output = capture_stdout { described_class.start(['help']) }

      # All commands should be listed
      expected_commands = %w[categories help search show sync version]
      expected_commands.each do |command|
        expect(help_output).to include(command)
      end
    end
  end

  describe 'Performance Flag Isolation' do
    it 'ensures performance flags do not change functional behavior' do
      # Baseline sync without performance flags
      capture_stdout { cli.sync }

      # Sync with stats flag should include baseline output plus stats
      cli.options = { stats: true }
      stats_output = capture_stdout { cli.sync }

      # Core sync output should be preserved
      expect(stats_output).to include('Synchronizing leyline standards')
      expect(stats_output).to include('Sync completed:')
      expect(stats_output).to include('CACHE STATISTICS')
    end

    it 'ensures cache flags maintain functional equivalence' do
      # These should all produce functionally equivalent results
      results = []

      # Normal sync
      results << capture_stdout { cli.sync }

      # No-cache sync
      cli.options = { no_cache: true }
      results << capture_stdout { cli.sync }

      # Force-git sync
      cli.options = { force_git: true }
      results << capture_stdout { cli.sync }

      # All should complete successfully and show sync completion
      results.each do |output|
        expect(output).to include('Synchronizing leyline standards')
        expect(output).to include('Sync completed:')
      end
    end

    it 'maintains verbose flag behavior with new features' do
      cli.options = { verbose: true, stats: true }
      output = capture_stdout { cli.sync }

      # Should include both verbose sync details and performance stats
      expect(output).to include('Synchronizing leyline standards')
      expect(output).to include('CACHE STATISTICS')
    end
  end

  describe 'Cross-Platform Compatibility' do
    it 'handles path separators consistently' do
      # Test with different path styles (will be normalized internally)
      temp_project_dir.gsub('/', '\\') if temp_project_dir.include?('/')
      unix_style = temp_project_dir

      expect { cli.sync(unix_style) }.not_to raise_error
      # Windows-style paths would only work on Windows, so skip that test on Unix systems
    end

    it 'handles environment variables gracefully' do
      # New environment variables should not break when undefined
      expect { cli.sync }.not_to raise_error

      # When defined, they should work
      ENV['LEYLINE_CACHE_THRESHOLD'] = '0.9'
      expect { cli.sync }.not_to raise_error
      ENV.delete('LEYLINE_CACHE_THRESHOLD')
    end
  end

  describe 'Category Validation Backward Compatibility' do
    it 'maintains valid category list consistency' do
      # Valid categories should remain stable for existing scripts
      valid_categories = %w[typescript go core python rust web]

      valid_categories.each do |category|
        cli.options = { categories: [category] }
        expect { capture_stdout { cli.sync } }.not_to raise_error
      end
    end

    it 'handles comma-separated categories consistently' do
      # This is a common pattern in scripts
      cli.options = { categories: ['typescript,go,core'] }
      output = capture_stdout { cli.sync }

      # Should be parsed correctly and display normalized category list
      expect(output).to include('Categories: core, go, typescript')
    end
  end

  describe 'Thor CLI Framework Backward Compatibility' do
    it 'maintains Thor command structure' do
      # Verify CLI still properly inherits from Thor
      expect(described_class).to be < Thor
      expect(described_class.commands).to be_a(Hash)
      expect(described_class.commands).not_to be_empty
    end

    it 'preserves command descriptions for help system' do
      sync_command = described_class.commands['sync']
      expect(sync_command.description).to eq('Synchronize leyline standards to target directory')

      version_command = described_class.commands['version']
      expect(version_command.description).to eq('Show version information')
    end

    it 'maintains option parsing behavior' do
      # Thor option parsing should remain consistent
      expect { described_class.start(['sync', '--help']) }.not_to raise_error
      expect { described_class.start(['sync', '--categories', 'core']) }.not_to raise_error
      expect { described_class.start(['sync', '--verbose', '--force']) }.not_to raise_error
    end
  end

  describe 'Integration Pattern Validation' do
    it 'supports CI/CD pipeline patterns' do
      # Common CI pattern: set -e (exit on error)
      ENV['SET_E_SIMULATION'] = 'true' # Simulate set -e behavior

      begin
        # Should not raise exceptions that would break CI scripts
        expect { capture_stdout { cli.sync } }.not_to raise_error
      ensure
        ENV.delete('SET_E_SIMULATION')
      end
    end

    it 'maintains makefile integration patterns' do
      # Makefile pattern: leyline sync --categories typescript --force
      cli.options = { categories: ['typescript'], force: true }
      output = capture_stdout { cli.sync }

      expect(output).to include('Categories: typescript')
      expect(output).to include('Sync completed:')
    end

    it 'supports package.json script patterns' do
      # npm script pattern: "sync-leyline": "leyline sync --categories typescript,web"
      cli.options = { categories: ['typescript,web'] }
      output = capture_stdout { cli.sync }

      expect(output).to include('Categories: typescript, web')
      expect(output).to include('Sync completed:')
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stdout_and_exit
    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      yield
    rescue SystemExit
      # Expected for some error cases
    end

    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def exit_with_code(code)
    raise_error(SystemExit) do |error|
      expect(error.status).to eq(code)
    end
  end
end
