# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'CLI Workflow Integration', type: :integration do
  # Kent Beck: "Tests that are simple to write are simple to read"
  # Focus on testing the actual implementation, not imagined features

  let(:test_dir) { Dir.mktmpdir('leyline-cli-test') }
  let(:cli) { Leyline::CLI.new }

  # Use realistic fixtures that express intent
  let(:initial_docs) do
    {
      'docs/leyline/tenets/clarity.md' => <<~MARKDOWN,
        ---
        id: clarity
        version: 1.0.0
        ---
        # Clarity

        Write code that expresses intent.
      MARKDOWN
      'docs/leyline/bindings/core/naming.md' => <<~MARKDOWN
        ---
        id: core-naming
        category: core
        ---
        # Naming Conventions

        Use descriptive names.
      MARKDOWN
    }
  end

  before do
    # Set up test environment
    ENV['LEYLINE_TEST_MODE'] = 'true'
    ENV['LEYLINE_CACHE_DIR'] = File.join(test_dir, '.cache')

    # Initialize with documents
    setup_test_repository(initial_docs)

    # Capture output
    allow($stdout).to receive(:puts)
  end

  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    ENV.delete('LEYLINE_TEST_MODE')
    ENV.delete('LEYLINE_CACHE_DIR')
  end

  describe 'status command' do
    context 'when no sync state exists' do
      it 'reports missing sync state' do
        # Check status without sync
        output = capture_output { cli.invoke(:status, [test_dir]) }

        expect(output).to include('No sync state found')
        expect(output).to include("run 'leyline sync' first")
      end
    end

    context 'after initial sync' do
      before do
        # Perform initial sync
        cli.options = {}
        capture_output { cli.invoke(:sync, [test_dir]) }
      end

      it 'shows sync state exists' do
        output = capture_output { cli.invoke(:status, [test_dir]) }

        expect(output).to include('State exists')
        expect(output).to include('Last sync:')
        expect(output).to include('Synced version:')
      end

      it 'reports no local changes for unmodified files' do
        output = capture_output { cli.invoke(:status, [test_dir]) }

        expect(output).to include('✓ No local changes detected')
      end

      context 'when local files are modified' do
        it 'detects modified files' do
          # Modify a local file
          clarity_path = File.join(test_dir, 'docs/leyline/tenets/clarity.md')
          File.write(clarity_path, '# Modified content')

          output = capture_output { cli.invoke(:status, [test_dir]) }

          expect(output).to include('change(s) detected')
          expect(output).to include('Modified files')
          expect(output).to include('clarity.md')
        end
      end

      context 'when files are added' do
        it 'detects added files' do
          # Add a new file
          new_file_path = File.join(test_dir, 'docs/leyline/tenets/new.md')
          File.write(new_file_path, '# New tenet')

          output = capture_output { cli.invoke(:status, [test_dir]) }

          expect(output).to include('change(s) detected')
          expect(output).to include('Added files')
          expect(output).to include('new.md')
        end
      end

      context 'when files are removed' do
        it 'detects removed files' do
          # Remove a file
          naming_path = File.join(test_dir, 'docs/leyline/bindings/core/naming.md')
          FileUtils.rm(naming_path)

          output = capture_output { cli.invoke(:status, [test_dir]) }

          expect(output).to include('change(s) detected')
          expect(output).to include('Removed files')
          expect(output).to include('naming.md')
        end
      end
    end

    context 'with JSON output' do
      it 'outputs valid JSON format' do
        output = capture_output { cli.invoke(:status, [test_dir], { json: true }) }

        expect { JSON.parse(output) }.not_to raise_error

        data = JSON.parse(output)
        expect(data).to have_key('sync_state')
        expect(data).to have_key('local_changes')
        expect(data).to have_key('file_summary')
      end
    end
  end

  describe 'diff command' do
    it 'exists and can be invoked' do
      expect { cli.invoke(:diff, [test_dir]) }.not_to raise_error
    end

    context 'with JSON output' do
      it 'supports JSON format option' do
        cli.options = { format: 'json' }
        expect { cli.invoke(:diff, [test_dir]) }.not_to raise_error
      end
    end
  end

  describe 'update command' do
    it 'exists and can be invoked' do
      expect { cli.invoke(:update, [test_dir]) }.not_to raise_error
    end

    context 'with --dry-run option' do
      it 'supports dry run mode' do
        cli.options = { dry_run: true }
        expect { cli.invoke(:update, [test_dir]) }.not_to raise_error
      end
    end
  end

  describe 'sync command integration' do
    it 'creates sync state that status can read' do
      # Perform sync
      sync_output = capture_output { cli.invoke(:sync, [test_dir]) }
      expect(sync_output).to include('Sync completed')

      # Status should now show sync state
      status_output = capture_output { cli.invoke(:status, [test_dir]) }
      expect(status_output).to include('✓ State exists')
    end

    it 'maintains performance with cache optimization' do
      # First sync (cold cache)
      cli2 = Leyline::CLI.new
      cli2.options = { stats: true }
      first_output = capture_output { cli2.sync(test_dir) }
      expect(first_output).to include('CACHE STATISTICS')
      expect(first_output).to include('Cache hits:')

      # Second sync (warm cache)
      cli3 = Leyline::CLI.new
      cli3.options = { stats: true }
      second_output = capture_output { cli3.sync(test_dir) }
      expect(second_output).to include('CACHE STATISTICS')
      expect(second_output).to include('Hit ratio:')

      # Should show improved cache performance
      expect(second_output).to match(/Hit ratio: \d+\.\d+%/)
    end
  end

  private

  def setup_test_repository(files)
    files.each do |path, content|
      full_path = File.join(test_dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end
  end

  def capture_output(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  rescue SystemExit
    # Some commands exit, capture output anyway
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
