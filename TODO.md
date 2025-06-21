# TODO: Smart Git Operations & Cache Integration

*Next focused PR: Cache-aware git operations for 10x performance improvement*

## PR 2: Cache-Aware Git Sync Flow (Target: <1 second cached sync)

### Core Implementation Tasks

- [x] **Add cache hit ratio calculation to FileSyncer**
  - Create `calculate_cache_hit_ratio(target_files, cache)` method in `lib/leyline/sync/file_syncer.rb`
  - Method should return float 0.0-1.0 representing percentage of files available in cache
  - Use existing `files_different?` logic but check cache first before file system
  - Add unit tests covering edge cases (empty cache, partial hits, full hits)

- [x] **Implement smart git operation detection**
  - Add `git_sync_needed?(cache_hit_ratio)` method with 20% threshold
  - If cache_hit_ratio > 0.8, skip git operations entirely
  - Add `--force-git` flag to override smart detection when needed
  - Document threshold rationale and make configurable via environment variable

- [x] **Modify sync flow to check cache before git operations**
  - Update `FileSyncer#sync` to call cache hit calculation first
  - When git operations skipped, log "Serving from cache (X% hit ratio)" message
  - Ensure existing git flow unchanged when cache hit ratio below threshold
  - Preserve all existing error handling and force flag behavior

- [x] **Add cache statistics to verbose output**
  - Track and display: cache hits, cache misses, git operations skipped, total time saved
  - Add `--stats` flag for detailed performance breakdown
  - Include cache directory size and file count in stats
  - Format output similar to existing verbose sync output

### Testing & Validation Tasks

- [x] **Create integration test for cache-aware sync flow**
  - Test scenario: First sync (cold cache) vs second sync (warm cache)
  - Measure and assert performance improvement (target: >50% faster on second run)
  - Verify git operations actually skipped when cache hit ratio high
  - Test with multiple categories and varying file sets

- [x] **Add unit tests for cache hit ratio calculation**
  - Test empty cache scenario (0% hit ratio)
  - Test partial cache scenario (mixed hit/miss)
  - Test full cache scenario (100% hit ratio)
  - Test corrupted cache files (should fallback gracefully)

- [x] **Performance benchmark test suite**
  - Create `spec/performance/cache_sync_benchmark_spec.rb`
  - Benchmark current git-only sync vs cache-aware sync
  - Measure and log actual time improvements
  - Assert minimum performance improvements met

### Code Quality Tasks

- [x] **Ensure backward compatibility maintained**
  - All existing CLI commands work unchanged
  - FileSyncer can operate without cache parameter (existing functionality)
  - No breaking changes to CLI interface or sync behavior
  - Existing tests continue to pass without modification

- [x] **Add comprehensive error handling**
  - Handle cache read failures gracefully (fallback to git)
  - Handle cache corruption scenarios (regenerate cache)
  - Log warnings for cache issues without failing sync
  - Ensure sync always succeeds even if cache completely broken

- [x] **Documentation updates**
  - Update CLI help text to mention cache optimizations
  - Document new flags (`--force-git`, `--stats`) in help output
  - Add performance section to CLAUDE.md with new benchmarks
  - Document cache hit ratio threshold and environment variable

### Success Criteria Validation

- [x] **Performance validation**
  - Second sync of same content completes in <1 second (target from BACKLOG.md)
  - Cache hit ratio >80% for typical development workflows
  - Git operations successfully skipped when cache sufficient
  - No performance regression on first sync (cache miss scenario)

- [x] **Quality validation**
  - All existing tests pass
  - New tests provide >90% coverage of new functionality
  - Ruby linting passes with no new violations
  - Manual testing on macOS, Linux confirms cross-platform compatibility

---

*Focus: Make the most common case (repeated sync) dramatically faster while maintaining reliability*
