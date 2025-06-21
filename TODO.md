# Leyline Cache Implementation TODO

*Make it fast. Ship it. No excuses.*

## Phase 1: Core Cache Infrastructure (PR #1)

### Cache Module Setup
- [x] Create `lib/leyline/cache/` directory structure
- [x] Create `lib/leyline/cache/file_cache.rb` with class skeleton including initialize method that accepts `cache_dir` parameter defaulting to `~/.leyline/cache`
- [x] Add `require 'digest'` and `require 'fileutils'` to file_cache.rb for SHA256 hashing and directory operations
- [x] Implement `ensure_directories` private method that creates `@content_dir = #{@cache_dir}/content` with FileUtils.mkdir_p
- [x] Add instance variables: `@cache_dir`, `@content_dir`, `@max_cache_size = 50 * 1024 * 1024` (50MB in bytes)

### Content Storage Implementation
- [ ] Implement `content_file_path(hash)` private method that returns `File.join(@content_dir, hash[0..1], hash[2..-1])` for git-style sharding
- [ ] Create `put(path, content)` method that computes SHA256 hash via `Digest::SHA256.hexdigest(content)`
- [ ] In `put` method, check if content file already exists at `content_file_path(hash)` before writing
- [ ] Implement atomic file writing in `put` using temp file + rename pattern: write to `#{path}.tmp.#{Process.pid}` then `File.rename`
- [ ] Add error handling in `put` to clean up temp files on failure using ensure block

### Content Retrieval Implementation
- [ ] Create `get(path, content_hash)` method that returns file content or nil if not found
- [ ] In `get` method, construct full path using `content_file_path(content_hash)`
- [ ] Add File.exist? check before reading in `get` method, return nil if missing
- [ ] Implement SHA256 verification in `get` by comparing `Digest::SHA256.hexdigest(content)` with expected hash parameter
- [ ] Return nil from `get` if checksum verification fails (corrupted cache)

### Basic Cache Maintenance
- [ ] Create `cache_size` private method that calculates total size using `Dir.glob("#{@content_dir}/**/*").sum { |f| File.size(f) if File.file?(f) }`
- [ ] Implement `enforce_size_limit` private method that returns early if `cache_size < @max_cache_size`
- [ ] Add LRU eviction logic to `enforce_size_limit` using File.atime to sort files by access time
- [ ] In eviction loop, delete oldest files until `cache_size < @max_cache_size * 0.9` (90% threshold)
- [ ] Add `clear_cache` method that runs `FileUtils.rm_rf(@content_dir)` followed by `ensure_directories`

### Cache Tests
- [ ] Create `spec/lib/leyline/cache/file_cache_spec.rb` with RSpec.describe block
- [ ] Write test "stores and retrieves content correctly" that puts content and verifies get returns same content
- [ ] Write test "returns nil for missing content" that calls get with non-existent hash
- [ ] Write test "deduplicates identical content" that puts same content twice and verifies single file on disk
- [ ] Write test "handles corrupted cache gracefully" that manually corrupts a cache file and verifies get returns nil
- [ ] Write test "enforces size limit with LRU eviction" that fills cache beyond limit and verifies oldest files deleted

## Phase 2: Cache Integration (PR #2)

### Cached Syncer Implementation
- [ ] Create `lib/leyline/sync/cached_file_syncer.rb` that inherits from `Leyline::Sync::FileSyncer`
- [ ] Add `initialize` method that calls super and creates `@cache = Leyline::Cache::FileCache.new`
- [ ] Add `@use_cache = true` instance variable with attr_accessor for toggling cache
- [ ] Override `sync` method to check `@use_cache` flag before attempting cache operations
- [ ] Create private `content_hash_for_file(path)` method that reads file and returns SHA256 hash

### Cache Check Logic
- [ ] Implement `check_cache_for_file(relative_path, expected_hash)` that calls @cache.get
- [ ] Create `sync_from_cache(cached_files)` method that copies cached content to target paths
- [ ] In `sync_from_cache`, maintain same sync_results structure: {:copied, :skipped, :errors}
- [ ] Add cache hit/miss tracking with `@cache_hits = 0` and `@cache_misses = 0` instance variables
- [ ] Increment counters appropriately in cache check logic

### Git Sync Cache Update
- [ ] Override `sync_file` to check cache first via `check_cache_for_file` before reading source
- [ ] After successful file copy in `sync_file`, call `@cache.put(relative_path, content)` to update cache
- [ ] Ensure cache update only happens for successfully copied files (not skipped or errors)
- [ ] Add begin/rescue around cache operations to prevent cache errors from breaking sync
- [ ] Log cache errors to `@sync_results[:cache_errors]` array for reporting

### Integration Tests
- [ ] Create `spec/lib/leyline/sync/cached_file_syncer_spec.rb`
- [ ] Write test "uses cache for unchanged files" that syncs twice and verifies second sync hits cache
- [ ] Write test "updates cache after successful sync" that verifies cache contains synced files
- [ ] Write test "falls back gracefully when cache fails" using mock to simulate cache errors
- [ ] Write test "respects use_cache flag" that disables cache and verifies normal sync behavior

## Phase 3: Version Management (PR #3)

### SQLite Database Setup
- [ ] Add `require 'sqlite3'` to file_cache.rb (standard library, no gem needed)
- [ ] Create `init_database` private method that opens SQLite connection to `#{@cache_dir}/cache.db`
- [ ] Execute CREATE TABLE in `init_database` for cache_entries with columns: path, version, content_hash, cached_at, size, accessed_at
- [ ] Add PRIMARY KEY constraint on (path, version) in CREATE TABLE statement
- [ ] Create indexes on content_hash and cached_at columns for query performance

### Version-Aware Cache Methods
- [ ] Modify `get` signature to accept `(path, version)` parameters
- [ ] Update `get` to query SQLite: `SELECT content_hash FROM cache_entries WHERE path = ? AND version = ?`
- [ ] Modify `put` signature to accept `(path, version, content)` parameters
- [ ] Update `put` to INSERT OR REPLACE into cache_entries with all fields
- [ ] Add `update_access_time(path, version)` to track cache hits for LRU

### Version Detection
- [ ] Create `lib/leyline/cache/version_detector.rb` class
- [ ] Implement `detect_version(directory)` that reads `VERSION` file from given directory
- [ ] Add fallback to git rev-parse if VERSION file missing: `git rev-parse --short HEAD`
- [ ] Cache detected version in instance variable to avoid repeated file reads
- [ ] Update CachedFileSyncer to use VersionDetector for current leyline version

### Version Cleanup
- [ ] Implement `cleanup_old_versions(keep_count = 3)` method in FileCache
- [ ] Query SQLite for unique versions ordered by MAX(cached_at) DESC
- [ ] Delete cache entries for versions beyond keep_count limit
- [ ] Remove orphaned content files with no remaining cache_entries references
- [ ] Add version cleanup call after successful sync with 10% probability

### Version Tests
- [ ] Write test "stores and retrieves version-specific content" with different content per version
- [ ] Write test "cleanup removes old versions" that creates 5 versions and verifies only 3 remain
- [ ] Write test "cleanup preserves orphaned content still referenced" with shared content across versions
- [ ] Write test "detects version from VERSION file" mocking file read
- [ ] Write test "falls back to git SHA when VERSION missing" mocking git command

## Phase 4: CLI Integration (PR #4)

### CLI Options
- [ ] Add `no_cache` option to `CLI::SYNC_OPTIONS` in `lib/leyline/cli/options.rb` with type: :boolean
- [ ] Add help description: "Bypass cache and fetch fresh content from git"
- [ ] Add `clear_cache` option with description: "Clear local cache before syncing"
- [ ] Update `validate_sync_options` to accept new cache-related options
- [ ] Pass cache options through to perform_sync method

### Cache Control Flow
- [ ] In `perform_sync`, check for `options[:clear_cache]` and call cache.clear_cache if true
- [ ] Create CachedFileSyncer instead of FileSyncer when not using `--no-cache`
- [ ] Set `file_syncer.use_cache = false` when `options[:no_cache]` is true
- [ ] Add cache statistics to sync results hash: cache_hits, cache_misses, cache_errors
- [ ] Update `report_sync_results` to display cache statistics when verbose

### Cache Commands
- [ ] Add `cache_stats` command to CLI that shows cache size, file count, hit rate
- [ ] Implement cache stats by querying SQLite for counts and sizes grouped by version
- [ ] Add `cache_clear` command that confirms with user then calls cache.clear_cache
- [ ] Add `--force` flag to cache_clear to skip confirmation prompt
- [ ] Format cache stats output as a nice ASCII table using printf formatting

### CLI Tests
- [ ] Write test "--no-cache flag bypasses cache" verifying no cache calls made
- [ ] Write test "--clear-cache flag empties cache" checking cache directory is empty
- [ ] Write test "cache stats command displays statistics" capturing stdout
- [ ] Write test "cache clear requires confirmation" simulating 'n' input
- [ ] Write test "--force flag skips cache clear confirmation"

## Phase 5: Performance Optimization (PR #5)

### Pre-scan Optimization
- [ ] Create `pre_scan_for_cached_files(expected_files)` method in CachedFileSyncer
- [ ] Query cache database for all expected files in single SELECT with IN clause
- [ ] Return hash of path => cache_hit_status for evaluation
- [ ] Calculate cache hit percentage: `cached_count.to_f / expected_files.size`
- [ ] Add threshold constant `CACHE_HIT_THRESHOLD = 0.8` for decision making

### Smart Fetch Decision
- [ ] Implement `should_use_git_sync?(cache_hit_rate)` returning true if hit rate < threshold
- [ ] Create `sync_subset_from_cache(cached_files, all_files)` for high cache hit scenarios
- [ ] In subset sync, only create temp directory if uncached files exist
- [ ] Build minimal sparse-checkout paths for only uncached files
- [ ] Log decision reasoning when verbose: "Using cache for 95% of files (38/40 cached)"

### Parallel Operations
- [ ] Add `require 'parallel'` to cached_file_syncer.rb (may need to add gem dependency)
- [ ] Implement `parallel_cache_check(files)` using Parallel.map with 4 threads
- [ ] Create thread-safe cache hit/miss counters using Mutex
- [ ] Implement `parallel_cache_update(files_and_contents)` for bulk cache writes
- [ ] Add error aggregation for parallel operations to avoid silent failures

### Progress Reporting
- [ ] Add `@progress_callback` instance variable for optional progress updates
- [ ] Call progress callback with (current, total, filename) during sync operations
- [ ] Create simple progress bar output when verbose: `[####----] 40% (16/40) core/api-design.md`
- [ ] Ensure progress works for both cache hits and git fetches
- [ ] Add timing output showing per-file and total sync duration

### Performance Tests
- [ ] Create `spec/performance/cache_benchmark_spec.rb` with benchmark/ips
- [ ] Write benchmark comparing sequential vs parallel cache operations
- [ ] Test "achieves <0.5s sync time with 90% cache hits" using fixture data
- [ ] Benchmark "handles 1000+ files efficiently" with large fixture set
- [ ] Profile memory usage to ensure cache doesn't bloat with large file sets

## Monitoring & Metrics

### Metrics Collection
- [ ] Create `lib/leyline/cache/metrics.rb` module
- [ ] Implement thread-safe metric counters using Mutex
- [ ] Add timing helpers using Process.clock_gettime(Process::CLOCK_MONOTONIC)
- [ ] Create `record_operation(type, duration, size)` method for consistent tracking
- [ ] Implement `to_json` for metrics export to monitoring systems

### Metric Integration Points
- [ ] Add metric recording to FileCache get method: type: :cache_get
- [ ] Add metric recording to FileCache put method: type: :cache_put
- [ ] Record cache hit/miss/error rates in CachedFileSyncer
- [ ] Track total bytes saved by cache hits
- [ ] Record cache eviction events and sizes

### Metrics Reporting
- [ ] Add `--json` flag to cache_stats command for machine-readable output
- [ ] Include percentiles (p50, p90, p99) for operation timings
- [ ] Add hourly/daily aggregation for hit rates
- [ ] Export Prometheus-compatible metrics format
- [ ] Write metrics to `~/.leyline/cache/metrics.json` for external collection

## Validation & Rollout

### Stress Testing Suite
- [ ] Create `tools/stress_test_cache.rb` script
- [ ] Implement concurrent sync test with 10 parallel processes
- [ ] Add rapid version change test (100 version switches)
- [ ] Create cache corruption test that randomly corrupts files
- [ ] Test cache behavior at exactly 50MB limit

### Production Validation
- [ ] Add `--enable-cache-experiment` hidden flag for gradual rollout
- [ ] Implement A/B test logging to compare cache vs non-cache performance
- [ ] Add cache integrity check on startup (sample 1% of entries)
- [ ] Create automated cache health report in CI
- [ ] Set up alerts for cache error rates > 1%

### Documentation
- [ ] Update README.md with cache behavior explanation
- [ ] Document cache location and structure in CONTRIBUTING.md
- [ ] Add troubleshooting section for cache issues
- [ ] Create cache architecture diagram with Mermaid
- [ ] Write migration guide for existing users

## Success Criteria Checklist

### Must Have (Ship PR #1)
- [ ] Cache stores and retrieves files correctly
- [ ] Second sync completes in <1 second
- [ ] No behavior change for users (transparent)
- [ ] All existing tests pass
- [ ] Zero configuration required

### Should Have (Ship by PR #3)
- [ ] Version-aware caching works correctly
- [ ] Cache size stays under 50MB
- [ ] 90%+ cache hit rate in typical usage
- [ ] --no-cache flag works as expected
- [ ] Clear performance improvement metrics

### Nice to Have (Future)
- [ ] GitHub API integration for single file fetches
- [ ] Compressed cache storage
- [ ] Network cache sharing between team members
- [ ] Pre-warming cache from CI builds
- [ ] Cache export/import commands

---

*Remember: Fast is a feature. Ship the minimum that makes sync fast, then iterate.*
