# TODO: Transparency Commands Implementation

*Next focused PR: Implement core transparency commands (diff, status, update) to provide visibility into sync operations*

## PR 1: Core Transparency Commands (Target: <2 second response times, maintain >80% cache hit ratio)

### Foundation Tasks
- [x] **[Core Infrastructure] T001: Implement FileComparator service**: Create `lib/leyline/file_comparator.rb` with methods `#compare_with_remote(local_path, category)`, `#detect_modifications(base_manifest, current_files)`, and `#generate_diff_data(file_a, file_b)`. Leverage existing FileSyncer SHA256 logic for content comparison. Must support category filtering and cache-aware operations. *Depends-on: None (foundational)* **COMPLETED**: 34 test cases passing, performance targets met (<500ms for 100 files)

- [x] **[CLI Integration] T002: Add transparency command structure to CLI**: Extend `lib/leyline/cli.rb` with `desc` and `method_option` definitions for `diff`, `status`, and `update` commands. Follow existing sync command patterns for option handling (--categories, --verbose, --stats). Register commands with Thor and add help documentation. *Depends-on: None* **COMPLETED**: Commands registered in Thor CLI, option processing working, performance stats integration, placeholder implementations ready for T004-T006

- [ ] **[Metadata] T003: Implement sync state tracking**: Create `lib/leyline/sync_state.rb` to track sync metadata (timestamp, version, synced categories, file manifest) in `~/.cache/leyline/sync_state.yaml`. Provide methods `#save_sync_state(metadata)`, `#load_sync_state`, and `#state_exists?`. Use YAML for human-readable format. *Depends-on: None*

### Core Command Implementation
- [ ] **[Status Command] T004: Implement leyline status command**: Create `lib/leyline/commands/status_command.rb` with status comparison logic. Show current leyline version, locally modified files vs sync baseline, available updates count, and summary statistics. Support `--json` output format and `--categories` filtering. Use existing MetadataCache for performance. *Depends-on: T001, T003*

- [ ] **[Diff Command] T005: Implement leyline diff command**: Create `lib/leyline/commands/diff_command.rb` showing what would change without syncing. Generate unified diff format output with file additions/deletions/modifications. Support `--categories` filtering and `--format` options (text, json). Integrate with existing GitClient for remote content access. *Depends-on: T001, T002*

- [ ] **[Update Command] T006: Implement leyline update command**: Create `lib/leyline/commands/update_command.rb` for safe, preview-first updates. Show pending changes, detect conflicts between local modifications and remote updates, provide clear resolution guidance. Include `--dry-run` mode and `--force` for conflict resolution. *Depends-on: T001, T003, T004*

### Testing & Validation
- [ ] **[Unit Testing] T007: Create FileComparator specs**: Add comprehensive tests in `spec/lib/leyline/file_comparator_spec.rb` covering SHA256 comparison, manifest diffing, category filtering, and cache integration. Include performance benchmarks ensuring <500ms for 100-file comparisons. Target >85% code coverage. *Depends-on: T001*

- [ ] **[Integration Testing] T008: Create transparency commands integration specs**: Add end-to-end tests in `spec/integration/transparency_commands_spec.rb` testing full workflows: status → diff → update. Use realistic test fixtures with git repositories, modified files, and category structures. Validate output formats and error handling. *Depends-on: T004, T005, T006*

- [ ] **[Performance Testing] T009: Add transparency performance benchmarks**: Create `spec/performance/transparency_performance_spec.rb` validating <2 second response times for all commands with 1000+ files. Test cache hit ratio maintenance >80%, memory usage bounds, and parallel processing benefits. Include degradation testing for cache failures. *Depends-on: T007, T008*

### Code Quality & Documentation
- [ ] **[Error Handling] T010: Implement comprehensive error handling**: Add specific error classes in `lib/leyline/errors.rb` for transparency operations (ConflictDetectedError, InvalidSyncStateError, ComparisonFailedError). Provide actionable error messages with resolution steps. Follow existing error patterns from FileSyncer. *Depends-on: T004, T005, T006*

- [ ] **[CLI Help] T011: Add command documentation and examples**: Update CLI help text with detailed usage examples, common workflows, and troubleshooting tips. Follow existing patterns from sync command help. Include performance tips and cache optimization guidance. Add man page-style documentation. *Depends-on: T002*

- [ ] **[Backward Compatibility] T012: Validate existing command compatibility**: Ensure all existing commands (sync, categories, show, search) continue working unchanged. Run full regression test suite and verify no performance degradation. Update CLAUDE.md with new command documentation. *Depends-on: T008*

## Success Criteria
1. ✅ `leyline status` shows current sync state with modification detection
2. ✅ `leyline diff` displays pending changes without syncing
3. ✅ `leyline update` handles safe updates with conflict detection
4. ✅ All commands complete in <2 seconds for typical repositories
5. ✅ Cache hit ratio maintained >80% during transparency operations
6. ✅ >85% test coverage with comprehensive error handling
7. ✅ Zero regression in existing command functionality

## Files to be Created/Modified
- **New Files**: `lib/leyline/file_comparator.rb`, `lib/leyline/sync_state.rb`, `lib/leyline/commands/status_command.rb`, `lib/leyline/commands/diff_command.rb`, `lib/leyline/commands/update_command.rb`
- **Modified Files**: `lib/leyline/cli.rb`, `lib/leyline/errors.rb`
- **Test Files**: `spec/lib/leyline/file_comparator_spec.rb`, `spec/integration/transparency_commands_spec.rb`, `spec/performance/transparency_performance_spec.rb`

## Performance Targets
- Status command: <1 second (cache hit), <2 seconds (cache miss)
- Diff command: <1.5 seconds (100 files), <2 seconds (1000+ files)
- Update command: <2 seconds for conflict detection and preview
- Cache hit ratio: Maintain >80% throughout transparency operations
- Memory usage: Bounded to <50MB regardless of repository size

---

*This implementation provides essential transparency features that users need to confidently manage their leyline syncs while maintaining the performance and simplicity standards established in previous work.*
