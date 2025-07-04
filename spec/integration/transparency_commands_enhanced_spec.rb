# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'benchmark'
require 'json'

RSpec.describe 'Enhanced transparency commands integration', type: :integration do
  let(:source_repo_dir) { Dir.mktmpdir('leyline-source-repo') }
  let(:target_dir) { Dir.mktmpdir('leyline-target') }
  let(:cache_dir) { Dir.mktmpdir('leyline-cache') }
  let(:cli) { Leyline::CLI.new }

  before do
    # Set custom cache directory for isolation
    allow(Leyline::Cache::FileCache).to receive(:new).and_return(
      Leyline::Cache::FileCache.new(cache_dir)
    )

    # Mock environment to use test cache directory
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('LEYLINE_CACHE_DIR', '~/.cache/leyline').and_return(cache_dir)
  end

  after do
    FileUtils.rm_rf(source_repo_dir) if Dir.exist?(source_repo_dir)
    FileUtils.rm_rf(target_dir) if Dir.exist?(target_dir)
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
  end

  describe 'Real-world edge cases and platform-specific reliability' do
    describe 'Git repository state handling' do
      context 'partial/shallow clones' do
        it 'handles shallow clone repositories gracefully' do
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')
            system('git config user.email "test@example.com"')
            system('git config user.name "Test User"')

            # Create initial content
            FileUtils.mkdir_p('docs/tenets')
            File.write('docs/tenets/test.md', "# Test\n\nContent")
            system('git add .')
            system('git commit -m "Initial"', out: '/dev/null', err: '/dev/null')

            # Create more commits
            5.times do |i|
              File.write("docs/tenets/test#{i}.md", "# Test #{i}")
              system('git add .')
              system("git commit -m 'Commit #{i}'", out: '/dev/null', err: '/dev/null')
            end
          end

          # Simulate shallow clone
          shallow_repo = Dir.mktmpdir('shallow-clone')
          system("git clone --depth 1 file://#{source_repo_dir} #{shallow_repo}",
                 out: '/dev/null', err: '/dev/null')

          # Commands should work with shallow clones
          output, error = capture_output { cli.status(shallow_repo) }
          expect(output).to include('Leyline Status Report')
          expect(error).to be_empty
        ensure
          FileUtils.rm_rf(shallow_repo) if defined?(shallow_repo) && Dir.exist?(shallow_repo)
        end
      end

      context 'detached HEAD states' do
        it 'handles detached HEAD without crashing' do
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')
            system('git config user.email "test@example.com"')
            system('git config user.name "Test User"')

            File.write('test.txt', 'content')
            system('git add . && git commit -m "First"', out: '/dev/null', err: '/dev/null')
            first_commit = `git rev-parse HEAD`.strip

            File.write('test2.txt', 'content2')
            system('git add . && git commit -m "Second"', out: '/dev/null', err: '/dev/null')

            # Detach HEAD
            system("git checkout #{first_commit}", out: '/dev/null', err: '/dev/null')
          end

          # Commands should handle detached HEAD gracefully
          output, = capture_output { cli.sync(target_dir) }
          expect(output).to include('Synchronizing leyline standards')
        end
      end

      context 'corrupt git objects' do
        it 'provides helpful error messages for corrupt repositories' do
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')
            system('git config user.email "test@example.com"')
            system('git config user.name "Test User"')

            File.write('test.txt', 'content')
            system('git add . && git commit -m "Test"', out: '/dev/null', err: '/dev/null')

            # Corrupt a git object (simulate corruption)
            git_objects = Dir.glob('.git/objects/*/*')
            File.write(git_objects.first, 'CORRUPTED DATA') if git_objects.any?
          end

          # Should handle corruption gracefully
          output, error = capture_output { cli.sync(target_dir) }
          expect(output + error).to match(/error|fail/i)
        end
      end
    end

    describe 'File system edge cases' do
      context 'permission issues' do
        it 'handles read-only directories gracefully' do
          skip 'Permission tests require specific OS support' if RUBY_PLATFORM =~ /mswin|mingw/

          # Create read-only directory
          readonly_dir = Dir.mktmpdir('readonly')
          FileUtils.chmod(0o555, readonly_dir)

          output, error = capture_output { cli.sync(readonly_dir) }
          expect(output + error).to include('Error')
          expect { cli.status(readonly_dir) }.not_to raise_error
        ensure
          FileUtils.chmod(0o755, readonly_dir) if defined?(readonly_dir) && Dir.exist?(readonly_dir)
          FileUtils.rm_rf(readonly_dir) if defined?(readonly_dir)
        end
      end

      context 'filesystem limits' do
        it 'handles very long file paths gracefully' do
          # Create deeply nested directory structure
          deep_path = target_dir
          20.times do |i|
            deep_path = File.join(deep_path, "very_long_directory_name_number_#{i}")
          end

          FileUtils.mkdir_p(deep_path)

          # Should handle long paths without crashing
          output, = capture_output { cli.sync(target_dir) }
          expect(output).to include('Synchronizing leyline standards')
        end

        it 'handles filenames with special characters' do
          skip 'Windows has different filename rules' if RUBY_PLATFORM =~ /mswin|mingw/

          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')

            # Create files with special characters (valid on Unix)
            special_files = [
              'docs/tenets/test:colon.md',
              'docs/tenets/test|pipe.md',
              'docs/tenets/test"quote.md'
            ]

            special_files.each do |file|
              FileUtils.mkdir_p(File.dirname(file))
              begin
                File.write(file, "# Test\n\nContent")
              rescue StandardError
                next
              end
            end
          end

          # Should handle special characters appropriately
          expect { cli.sync(target_dir) }.not_to raise_error
        end
      end

      context 'disk space issues' do
        it 'handles out of disk space gracefully' do
          # Mock disk full scenario
          allow(File).to receive(:write).and_raise(Errno::ENOSPC)

          output, error = capture_output { cli.sync(target_dir) }
          expect(output + error).to match(/space|disk|error/i)
        end
      end
    end

    describe 'Cache corruption and recovery' do
      context 'cache file corruption' do
        it 'auto-recovers from corrupted cache files' do
          # Initial sync to populate cache
          cli.sync(target_dir)

          # Corrupt random cache files
          cache_files = Dir.glob(File.join(cache_dir, 'content', '**', '*'))
          cache_files.sample(3).each do |file|
            File.write(file, 'CORRUPTED') if File.file?(file)
          end

          # Should recover and continue working
          output, = capture_output { cli.status(target_dir) }
          expect(output).to include('Leyline Status Report')

          # Diff should still work
          output, = capture_output { cli.diff(target_dir) }
          expect(output).to include('Leyline Diff Report')
        end
      end

      context 'cache directory corruption' do
        it 'handles missing cache directories' do
          cli.sync(target_dir)

          # Remove cache directory
          FileUtils.rm_rf(cache_dir)

          # Commands should still work (slower, but functional)
          output, = capture_output { cli.status(target_dir) }
          expect(output).to include('Leyline Status Report')
        end

        it 'handles cache permission issues' do
          skip 'Permission tests require specific OS support' if RUBY_PLATFORM =~ /mswin|mingw/

          cli.sync(target_dir)

          # Make cache read-only
          FileUtils.chmod(0o444, cache_dir)

          # Should fall back gracefully
          output, = capture_output { cli.status(target_dir) }
          expect(output).to include('Leyline Status Report')
        ensure
          FileUtils.chmod(0o755, cache_dir) if Dir.exist?(cache_dir)
        end
      end
    end

    describe 'Network and timing issues' do
      context 'network failures' do
        it 'provides clear error messages for network issues' do
          # Mock network failure
          allow_any_instance_of(Leyline::Sync::GitClient).to receive(:fetch_version)
            .and_raise(Errno::ENETUNREACH, 'Network is unreachable')

          output, error = capture_output { cli.sync(target_dir) }
          expect(output + error).to match(/network|unreachable|connection/i)
        end

        it 'handles DNS resolution failures' do
          # Use invalid hostname
          allow_any_instance_of(Leyline::Sync::GitClient).to receive(:fetch_version)
            .and_raise(SocketError, 'getaddrinfo: Name or service not known')

          output, error = capture_output { cli.sync(target_dir) }
          expect(output + error).to match(/dns|resolve|hostname|service/i)
        end
      end

      context 'concurrent operations' do
        it 'handles concurrent sync operations safely' do
          # Simulate concurrent syncs
          threads = []
          errors = []

          3.times do |i|
            threads << Thread.new do
              dir = Dir.mktmpdir("concurrent-#{i}")
              cli.sync(dir)
              FileUtils.rm_rf(dir)
            rescue StandardError => e
              errors << e
            end
          end

          threads.each(&:join)

          # At least one should succeed
          expect(errors.size).to be < 3
        end
      end
    end

    describe 'Cross-platform compatibility' do
      context 'line ending handling' do
        it 'preserves platform-appropriate line endings' do
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')

            # Create files with different line endings
            File.write('docs/unix.md', "Line1\nLine2\nLine3")
            File.write('docs/windows.md', "Line1\r\nLine2\r\nLine3")
            File.write('docs/mixed.md', "Line1\nLine2\r\nLine3")
          end

          cli.sync(target_dir)

          # Check that line endings are handled appropriately
          unix_content = File.read(File.join(target_dir, 'docs', 'leyline', 'unix.md'))
          windows_content = File.read(File.join(target_dir, 'docs', 'leyline', 'windows.md'))

          if RUBY_PLATFORM =~ /mswin|mingw/
            # Windows should normalize to CRLF
            expect(windows_content).to include("\r\n")
          else
            # Unix should preserve LF
            expect(unix_content).not_to include("\r\n")
          end
        end
      end

      context 'path separator handling' do
        it 'handles mixed path separators correctly' do
          # Test paths with mixed separators
          mixed_path = target_dir.gsub('/', '\\')

          # Should normalize and work correctly
          expect { cli.status(mixed_path) }.not_to raise_error
        end
      end
    end

    describe 'Performance under stress' do
      context 'large file handling' do
        it 'handles very large individual files efficiently' do
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')

            # Create a large file (10MB)
            FileUtils.mkdir_p('docs')
            File.open('docs/large.md', 'w') do |f|
              1000.times { f.write('x' * 10_000 + "\n") }
            end
          end

          start_time = Time.now
          cli.sync(target_dir)
          sync_time = Time.now - start_time

          # Should complete in reasonable time
          expect(sync_time).to be < 10.0

          # Status should be fast even with large files
          start_time = Time.now
          cli.status(target_dir)
          status_time = Time.now - start_time

          expect(status_time).to be < 2.0
        end
      end

      context 'memory pressure' do
        it 'maintains bounded memory usage under load' do
          # Create many files
          Dir.chdir(source_repo_dir) do
            system('git init', out: '/dev/null', err: '/dev/null')

            500.times do |i|
              dir = "docs/category_#{i % 10}"
              FileUtils.mkdir_p(dir)
              File.write("#{dir}/file_#{i}.md", "Content #{i}" * 100)
            end
          end

          # Monitor memory during operations
          initial_memory = memory_usage_mb

          cli.sync(target_dir)
          cli.status(target_dir)
          cli.diff(target_dir)

          peak_memory = memory_usage_mb
          memory_increase = peak_memory - initial_memory

          # Memory usage should stay bounded
          expect(memory_increase).to be < 100.0
        end
      end
    end
  end

  private

  def capture_output(&block)
    original_stdout = $stdout
    original_stderr = $stderr
    captured_out = StringIO.new
    captured_err = StringIO.new
    $stdout = captured_out
    $stderr = captured_err

    block.call

    [captured_out.string, captured_err.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def memory_usage_mb
    # Cross-platform memory usage
    if RUBY_PLATFORM =~ /darwin/
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    elsif File.exist?("/proc/#{Process.pid}/status")
      File.read("/proc/#{Process.pid}/status").match(/VmRSS:\s+(\d+)/)[1].to_i / 1024.0
    else
      0.0
    end
  rescue StandardError
    0.0
  end
end
