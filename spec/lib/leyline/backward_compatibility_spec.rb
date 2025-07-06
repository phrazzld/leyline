# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe 'Backward compatibility validation' do
  let(:temp_source_dir) { Dir.mktmpdir('leyline-compat-source') }
  let(:temp_target_dir) { Dir.mktmpdir('leyline-compat-target') }

  before do
    # Create test files in source directory
    FileUtils.mkdir_p(File.join(temp_source_dir, 'docs'))
    File.write(File.join(temp_source_dir, 'docs', 'test.md'), 'test content')
    File.write(File.join(temp_source_dir, 'docs', 'test2.md'), 'test content 2')
  end

  after do
    FileUtils.rm_rf(temp_source_dir) if Dir.exist?(temp_source_dir)
    FileUtils.rm_rf(temp_target_dir) if Dir.exist?(temp_target_dir)
  end

  describe 'FileSyncer backward compatibility' do
    context 'constructor compatibility' do
      it 'works with original two-argument constructor' do
        # Original usage without cache or stats
        syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir)
        expect(syncer).to be_a(Leyline::Sync::FileSyncer)
      end

      it 'works with positional arguments (legacy style)' do
        # Ensure positional arguments still work
        syncer = Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir)
        results = syncer.sync
        expect(results).to have_key(:copied)
        expect(results[:copied]).to include('docs/test.md', 'docs/test2.md')
      end
    end

    context 'sync method compatibility' do
      let(:file_syncer) { Leyline::Sync::FileSyncer.new(temp_source_dir, temp_target_dir) }

      it 'works with no arguments (original behavior)' do
        results = file_syncer.sync
        expect(results[:copied]).to include('docs/test.md', 'docs/test2.md')
        expect(results[:skipped]).to be_empty
        expect(results[:errors]).to be_empty
      end

      it 'works with original force flag only' do
        # First sync
        file_syncer.sync

        # Modify target file
        File.write(File.join(temp_target_dir, 'docs', 'test.md'), 'modified content')

        # Second sync without force - should skip
        results = file_syncer.sync(force: false)
        expect(results[:skipped]).to include('docs/test.md')

        # Third sync with force - should overwrite
        results = file_syncer.sync(force: true)
        expect(results[:copied]).to include('docs/test.md')
      end

      it 'works with verbose flag' do
        # Verbose flag is passed through but FileSyncer itself doesn't produce output
        # unless cache operations are involved. The main thing is it doesn't crash.
        expect { file_syncer.sync(verbose: true) }.not_to raise_error

        # Verify sync still works correctly with verbose flag
        results = file_syncer.sync(verbose: true)
        expect(results[:copied]).to include('docs/test.md', 'docs/test2.md')
      end

      it 'preserves sync results structure' do
        results = file_syncer.sync

        # Verify original result structure is maintained
        expect(results).to be_a(Hash)
        expect(results.keys).to match_array(%i[copied skipped errors])
        expect(results[:copied]).to be_a(Array)
        expect(results[:skipped]).to be_a(Array)
        expect(results[:errors]).to be_a(Array)
      end
    end

    context 'error handling compatibility' do
      it 'raises SyncError for missing source directory (original behavior)' do
        syncer = Leyline::Sync::FileSyncer.new('/nonexistent', temp_target_dir)
        expect { syncer.sync }.to raise_error(
          Leyline::Sync::FileSyncer::SyncError,
          'Source directory does not exist: /nonexistent'
        )
      end
    end
  end

  describe 'CLI backward compatibility' do
    let(:cli) { Leyline::CLI.new }

    context 'basic sync command' do
      it 'accepts path argument without options' do
        output = capture_stdout do
          # Mock the actual sync to avoid git operations
          allow_any_instance_of(Leyline::CLI).to receive(:perform_sync).and_return(true)
          cli.sync(temp_target_dir)
        end

        expect(output).to include('Synchronizing leyline standards to:')
        expect(output).to include(temp_target_dir)
      end

      it 'uses current directory when no path specified' do
        output = capture_stdout do
          # Mock the actual sync to avoid git operations
          allow_any_instance_of(Leyline::CLI).to receive(:perform_sync).and_return(true)
          cli.sync
        end

        expect(output).to include('Synchronizing leyline standards to:')
        expect(output).to include('/docs/leyline')
      end

      it 'accepts original flags without new cache flags' do
        output = capture_stdout do
          # Mock the actual sync to avoid git operations
          allow_any_instance_of(Leyline::CLI).to receive(:perform_sync).and_return(true)

          # Simulate Thor options
          allow(cli).to receive(:options).and_return({
                                                       categories: ['typescript'],
                                                       force: true,
                                                       verbose: true,
                                                       dry_run: false
                                                     })

          cli.sync(temp_target_dir)
        end

        expect(output).to include('Categories: typescript')
        expect(output).to include('Options: categories, force, verbose')
      end
    end

    context 'version command compatibility' do
      it 'outputs version without changes' do
        output = capture_stdout { cli.version }
        expect(output).to match(/\d+\.\d+\.\d+/)
      end
    end

    context 'help command compatibility' do
      it 'includes all original commands' do
        output = capture_stdout do
          # Use Thor's help mechanism
          Leyline::CLI.start(['help'])
        end

        expect(output).to include('sync')
        expect(output).to include('version')
        expect(output).to include('help')
      end
    end
  end

  describe 'Integration backward compatibility' do
    context 'existing workflows continue to function' do
      it 'basic sync workflow works unchanged' do
        # Create a minimal git repo for testing
        git_repo = Dir.mktmpdir('leyline-git-repo')
        begin
          Dir.chdir(git_repo) do
            system('git init', out: '/dev/null', err: '/dev/null')
            FileUtils.mkdir_p('docs/tenets')
            FileUtils.mkdir_p('docs/bindings/core')
            File.write('docs/tenets/test.md', '# Test Tenet')
            File.write('docs/bindings/core/test.md', '# Test Binding')
            system('git add .', out: '/dev/null', err: '/dev/null')
            system('git commit -m "test"', out: '/dev/null', err: '/dev/null')
          end

          # Mock git operations to use local repo
          allow_any_instance_of(Leyline::Sync::GitClient).to receive(:fetch_version) do |instance|
            working_dir = instance.instance_variable_get(:@working_directory)
            FileUtils.cp_r(File.join(git_repo, 'docs'), working_dir) if working_dir && Dir.exist?(working_dir)
          end

          # Run sync without any cache options
          output = capture_stdout do
            Leyline::CLI.start(['sync', temp_target_dir])
          end

          expect(output).to include('Sync completed')
          expect(File.exist?(File.join(temp_target_dir, 'docs', 'leyline', 'tenets', 'test.md'))).to be true
          expect(File.exist?(File.join(temp_target_dir, 'docs', 'leyline', 'bindings', 'core', 'test.md'))).to be true
        ensure
          FileUtils.rm_rf(git_repo) if Dir.exist?(git_repo)
        end
      end
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
end
