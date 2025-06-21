# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'benchmark'

RSpec.describe 'Cache-aware sync flow integration', type: :integration do
  let(:source_repo_dir) { Dir.mktmpdir('leyline-source-repo') }
  let(:target_dir) { Dir.mktmpdir('leyline-target') }
  let(:cache_dir) { Dir.mktmpdir('leyline-cache') }
  let(:cli) { Leyline::CLI.new }

  before do
    # Set custom cache directory for isolation
    allow(Leyline::Cache::FileCache).to receive(:new).and_return(
      Leyline::Cache::FileCache.new(cache_dir)
    )
  end

  after do
    FileUtils.rm_rf(source_repo_dir) if Dir.exist?(source_repo_dir)
    FileUtils.rm_rf(target_dir) if Dir.exist?(target_dir)
    FileUtils.rm_rf(cache_dir) if Dir.exist?(cache_dir)
  end

  def create_realistic_leyline_repository
    Dir.chdir(source_repo_dir) do
      system('git init', out: '/dev/null', err: '/dev/null')
      system('git config user.email "test@example.com"')
      system('git config user.name "Test User"')

      # Create leyline-like directory structure
      FileUtils.mkdir_p('docs/tenets')
      FileUtils.mkdir_p('docs/bindings/core')
      FileUtils.mkdir_p('docs/bindings/categories/typescript')
      FileUtils.mkdir_p('docs/bindings/categories/go')
      FileUtils.mkdir_p('docs/bindings/categories/rust')

      # Create realistic content files
      create_tenet_files
      create_core_binding_files
      create_category_binding_files

      # Add and commit all files
      system('git add .', out: '/dev/null', err: '/dev/null')
      system('git commit -m "Initial leyline content"', out: '/dev/null', err: '/dev/null')
    end
  end

  def create_tenet_files
    File.write('docs/tenets/simplicity.md', <<~CONTENT)
      ---
      title: Simplicity
      version: "1.0"
      category: tenet
      ---

      # Simplicity

      Simplicity is the ultimate sophistication. Always choose the simpler solution when it adequately solves the problem.
    CONTENT

    File.write('docs/tenets/testability.md', <<~CONTENT)
      ---
      title: Testability
      version: "1.0"
      category: tenet
      ---

      # Testability

      Design for testability from the beginning. Code that is hard to test is usually poorly designed.
    CONTENT

    File.write('docs/tenets/maintainability.md', <<~CONTENT)
      ---
      title: Maintainability
      version: "1.0"
      category: tenet
      ---

      # Maintainability

      Write code that your future self and teammates can easily understand and modify.
    CONTENT
  end

  def create_core_binding_files
    File.write('docs/bindings/core/automated-quality-gates.md', <<~CONTENT)
      ---
      title: Automated Quality Gates
      version: "1.0"
      category: binding
      applies_to: ["all"]
      ---

      # Automated Quality Gates

      Every project must have automated quality gates in CI/CD.
    CONTENT

    File.write('docs/bindings/core/code-review-excellence.md', <<~CONTENT)
      ---
      title: Code Review Excellence
      version: "1.0"
      category: binding
      applies_to: ["all"]
      ---

      # Code Review Excellence

      Code reviews are mandatory and must focus on architecture, correctness, and maintainability.
    CONTENT
  end

  def create_category_binding_files
    File.write('docs/bindings/categories/typescript/modern-typescript-toolchain.md', <<~CONTENT)
      ---
      title: Modern TypeScript Toolchain
      version: "1.0"
      category: binding
      applies_to: ["typescript"]
      ---

      # Modern TypeScript Toolchain

      Use TypeScript 5.0+, strict mode, and modern build tools.
    CONTENT

    File.write('docs/bindings/categories/go/error-wrapping.md', <<~CONTENT)
      ---
      title: Error Wrapping
      version: "1.0"
      category: binding
      applies_to: ["go"]
      ---

      # Error Wrapping

      Always wrap errors with context using fmt.Errorf with %w verb.
    CONTENT

    File.write('docs/bindings/categories/rust/ownership-patterns.md', <<~CONTENT)
      ---
      title: Ownership Patterns
      version: "1.0"
      category: binding
      applies_to: ["rust"]
      ---

      # Ownership Patterns

      Leverage Rust's ownership system for memory safety and performance.
    CONTENT
  end

  def capture_stdout_and_measure_time
    original_stdout = $stdout
    captured_output = StringIO.new
    $stdout = captured_output

    time_taken = Benchmark.realtime { yield }

    [captured_output.string, time_taken]
  ensure
    $stdout = original_stdout
  end

  def mock_git_client_to_use_local_repo
    # Mock git client to use our local test repository instead of fetching from remote
    allow_any_instance_of(Leyline::Sync::GitClient).to receive(:fetch_version) do |instance, remote_url, branch|
      # Copy content from our test repo to the git client's working directory
      working_dir = instance.instance_variable_get(:@working_directory)
      if working_dir && Dir.exist?(working_dir)
        source_docs = File.join(source_repo_dir, 'docs')
        target_docs = File.join(working_dir, 'docs')
        FileUtils.cp_r(source_docs, File.dirname(target_docs))
      end
    end
  end

  describe 'cold vs warm cache performance' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'demonstrates significant performance improvement with warm cache' do
      # Test cold cache (first sync)
      cold_output, cold_time = capture_stdout_and_measure_time do
        cli.sync(target_dir)
      end

      expect(cold_time).to be > 0
      expect(cold_output).to include('Sync completed')

      # Verify files were copied
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'tenets', 'simplicity.md'))).to be true
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'bindings', 'core', 'automated-quality-gates.md'))).to be true

      # Test warm cache (second sync)
      warm_output, warm_time = capture_stdout_and_measure_time do
        cli.sync(target_dir)
      end

      expect(warm_time).to be > 0
      expect(warm_output).to include('Sync completed')

      # Performance assertion: warm cache should be significantly faster
      performance_improvement = ((cold_time - warm_time) / cold_time) * 100

      if performance_improvement <= 30
        puts "Performance improvement was only #{performance_improvement.round(1)}% (cold: #{cold_time.round(3)}s, warm: #{warm_time.round(3)}s)"
        puts "Cold cache output: #{cold_output}"
        puts "Warm cache output: #{warm_output}"
      end

      expect(performance_improvement).to be > 30

      # Verify cache was used (should see cache-related messages or skip operations)
      second_sync_output = warm_output.downcase
      cache_indicators = [
        'serving from cache',
        'cache hit ratio',
        'skipped',
      ]

      has_cache_indicator = cache_indicators.any? { |indicator| second_sync_output.include?(indicator) }

      unless has_cache_indicator
        puts "Expected cache usage indicators in output, but got: #{warm_output}"
      end

      expect(has_cache_indicator).to be true
    end
  end

  describe '--stats flag integration' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'provides accurate cache statistics' do
      # First sync to populate cache
      cli.sync(target_dir)

      # Second sync with stats
      output, _time = capture_stdout_and_measure_time do
        cli.invoke(:sync, [target_dir], { stats: true })
      end

      # Verify stats section is present
      expect(output).to include('CACHE STATISTICS')
      expect(output).to include('Cache Performance:')
      expect(output).to include('Cache hits:')
      expect(output).to include('Cache misses:')
      expect(output).to include('Hit ratio:')
      expect(output).to include('Timing:')
      expect(output).to include('Cache Directory:')
      expect(output).to include('Location:')
      expect(output).to include('Size:')
      expect(output).to include('Files:')
      expect(output).to include('Utilization:')

      # Verify cache hit ratio is reasonable for second sync
      hit_ratio_match = output.match(/Hit ratio: ([\d.]+)%/)
      expect(hit_ratio_match).not_to be_nil
      hit_ratio = hit_ratio_match[1].to_f
      expect(hit_ratio).to be > 50, "Expected cache hit ratio >50%, got #{hit_ratio}%"
    end
  end

  describe 'multi-category cache behavior' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'handles partial cache hits with different categories' do
      # First sync with only typescript category
      output1, _time1 = capture_stdout_and_measure_time do
        cli.invoke(:sync, [target_dir], { categories: ['typescript'] })
      end

      puts "Output1: #{output1}" if output1.empty?
      # Don't require specific output format, just verify files are created
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'bindings', 'categories', 'typescript', 'modern-typescript-toolchain.md'))).to be true

      # Second sync with typescript + go categories (partial cache)
      output2, _time2 = capture_stdout_and_measure_time do
        cli.invoke(:sync, [target_dir], { categories: ['typescript', 'go'], verbose: true })
      end

      puts "Output2: #{output2}" if output2.empty?
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'bindings', 'categories', 'go', 'error-wrapping.md'))).to be true

      # Verify both category files exist
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'bindings', 'categories', 'typescript', 'modern-typescript-toolchain.md'))).to be true
      expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'bindings', 'categories', 'go', 'error-wrapping.md'))).to be true
    end
  end

  describe 'force-git override functionality' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'bypasses cache optimization when --force-git is used' do
      # First sync to populate cache
      cli.sync(target_dir)

      # Second sync with force-git flag
      output, _time = capture_stdout_and_measure_time do
        cli.invoke(:sync, [target_dir], { force_git: true, verbose: true })
      end

      # Should not see cache optimization messages
      expect(output.downcase).not_to include('serving from cache')

      # Should still complete successfully
      expect(output).to include('Sync completed')
    end
  end

  describe 'cache directory utilization' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'tracks cache directory growth and utilization' do
      # Check initial cache state (should be empty or minimal)
      cache = Leyline::Cache::FileCache.new(cache_dir)
      initial_stats = cache.directory_stats
      expect(initial_stats[:file_count]).to eq(0)
      expect(initial_stats[:size]).to eq(0)

      # First sync to populate cache
      cli.sync(target_dir)

      # Check cache state after population
      final_stats = cache.directory_stats
      expect(final_stats[:file_count]).to be > 0
      expect(final_stats[:size]).to be > 0
      expect(final_stats[:utilization_percent]).to be >= 0
      expect(final_stats[:path]).to eq(cache_dir)

      # Verify cache contains expected content
      expect(Dir.exist?(File.join(cache_dir, 'content'))).to be true
      cache_files = Dir.glob(File.join(cache_dir, 'content', '**', '*')).select { |f| File.file?(f) }
      expect(cache_files.length).to be > 0
    end
  end

  describe 'error handling and fallback behavior' do
    before do
      create_realistic_leyline_repository
      mock_git_client_to_use_local_repo
    end

    it 'falls back gracefully when cache operations fail' do
      # Populate cache first
      cli.sync(target_dir)

      # Simulate cache corruption by making cache directory read-only
      cache_content_dir = File.join(cache_dir, 'content')
      File.chmod(0444, cache_content_dir) if Dir.exist?(cache_content_dir)

      begin
        # Second sync should still succeed despite cache issues
        output, _time = capture_stdout_and_measure_time do
          cli.sync(target_dir)
        end

        expect(output).to include('Sync completed')

        # Files should still be synced correctly
        expect(File.exist?(File.join(target_dir, 'docs', 'leyline', 'tenets', 'simplicity.md'))).to be true
      ensure
        # Restore permissions for cleanup
        File.chmod(0755, cache_content_dir) if Dir.exist?(cache_content_dir)
      end
    end
  end
end
