# CLI Sync Implementation TODO

## Phase 1: Foundation Setup

- [x] Create `lib/leyline/` directory structure for Ruby CLI implementation with subdirectories for `cli/`, `sync/`, `detection/`, and `reconciliation/`
- [x] Create `lib/leyline/version.rb` file that reads VERSION file and defines `Leyline::VERSION` constant for use in CLI version output
- [x] Create `lib/leyline/cli.rb` base class with Thor gem integration, defining main command structure with `sync` as primary command
- [x] Create `bin/leyline` executable script with proper shebang (`#!/usr/bin/env ruby`), loading path setup, and CLI invocation
- [x] Add Thor gem dependency to Gemfile with version constraint (~> 1.3) and run bundle install to update Gemfile.lock
- [x] Create `lib/leyline/cli/options.rb` module to define and validate all CLI options (--categories, --force, --path, --version, --dry-run) with proper type checking
- [x] Write comprehensive `spec/lib/leyline/cli_spec.rb` test file covering CLI initialization, option parsing, and command routing
- [x] Update `.gitignore` to exclude `tmp/leyline-sync-*` temporary directories used during sparse-checkout operations

## Phase 2: Git Operations

- [x] Create `lib/leyline/sync/git_client.rb` class implementing git sparse-checkout initialization with proper error handling for missing git binary
- [x] Implement `GitClient#setup_sparse_checkout` method that creates temp directory, initializes git repo, and configures sparse-checkout mode
- [x] Implement `GitClient#add_sparse_paths` method that accepts array of paths (e.g., ["docs/tenets", "docs/bindings/core"]) and adds them to sparse-checkout config
- [x] Implement `GitClient#fetch_version` method supporting branch names, tags, and commit SHAs with validation of remote existence
- [x] Create `GitClient#cleanup` method to safely remove temporary directories after sync completion or on error
- [ ] Write `spec/lib/leyline/sync/git_client_spec.rb` tests covering all git operations including error cases (network failures, invalid versions)
- [ ] Add integration test `spec/integration/git_sparse_checkout_spec.rb` that verifies actual git sparse-checkout behavior with real repository

## Phase 3: Language Detection

- [ ] Create `lib/leyline/detection/language_detector.rb` base class with abstract `detect` method returning array of detected languages
- [ ] Implement `lib/leyline/detection/node_detector.rb` checking for package.json, parsing it for typescript/react dependencies, returning ["typescript", "web"] categories
- [ ] Implement `lib/leyline/detection/go_detector.rb` checking for go.mod/go.sum files, returning ["go", "backend"] categories
- [ ] Implement `lib/leyline/detection/rust_detector.rb` checking for Cargo.toml, parsing for web frameworks (actix, rocket), returning appropriate categories
- [ ] Implement `lib/leyline/detection/python_detector.rb` checking for pyproject.toml, requirements.txt, setup.py, detecting frameworks (django, fastapi)
- [ ] Create `lib/leyline/detection/detector_registry.rb` that runs all detectors and merges results, removing duplicates
- [ ] Write comprehensive tests in `spec/lib/leyline/detection/` for each detector with fixture files representing real project structures
- [ ] Add `--verbose` flag support to output detected languages and reasoning to help users understand category selection

## Phase 4: File Synchronization

- [ ] Create `lib/leyline/sync/file_syncer.rb` class responsible for copying files from sparse-checkout temp directory to target location
- [ ] Implement `FileSyncer#calculate_checksum` method using SHA256 for consistent file comparison across platforms
- [ ] Create `lib/leyline/sync/sync_state.rb` class to read/write `.leyline-sync.yml` tracking file with version, checksums, and last sync timestamp
- [ ] Implement `FileSyncer#compare_files` method that returns status (:unchanged, :modified, :new, :deleted) for each file
- [ ] Implement `FileSyncer#sync_file` method with conflict resolution logic: preserve local changes by default, overwrite with --force
- [ ] Create `FileSyncer#generate_sync_report` returning structured data about added/modified/skipped files for user feedback
- [ ] Write tests in `spec/lib/leyline/sync/file_syncer_spec.rb` covering all sync scenarios including permission errors
- [ ] Add Windows-specific path handling tests to ensure cross-platform compatibility

## Phase 5: Integration with Existing Tools

- [ ] Create `lib/leyline/sync/reindexer.rb` wrapper class that safely invokes `tools/reindex.rb` with proper error handling
- [ ] Implement `Reindexer#run` method that captures stdout/stderr, handles non-zero exit codes, and provides meaningful error messages
- [ ] Create `lib/leyline/sync/validator.rb` wrapper for `tools/validate_front_matter.rb` to verify synced files are valid
- [ ] Add `--skip-validation` flag to bypass validation for faster syncing in trusted environments
- [ ] Implement progress reporting that shows "Validating front matter..." and "Regenerating indexes..." during these operations
- [ ] Write integration tests verifying reindex.rb is called correctly and indexes are properly updated after sync
- [ ] Add error recovery logic to restore previous state if reindexing fails after file sync

## Phase 6: User Experience

- [ ] Implement colorized output using Rainbow gem for success (green), warnings (yellow), and errors (red) messages
- [ ] Create `lib/leyline/cli/reporter.rb` class formatting sync results in human-readable table showing file counts by category
- [ ] Add spinner/progress indicator for long-running operations (git fetch, file sync) using TTY::Spinner gem
- [ ] Implement `--json` flag for machine-readable output containing sync report data for CI integration
- [ ] Create detailed error messages with actionable suggestions (e.g., "Network error: Check internet connection and try again")
- [ ] Add `--quiet` flag that suppresses all output except errors, useful for cron jobs and CI
- [ ] Implement confirmation prompt for destructive operations when --force is used: "This will overwrite 3 local modifications. Continue? (y/N)"
- [ ] Write end-to-end tests in `spec/e2e/user_experience_spec.rb` verifying all output scenarios

## Phase 7: Advanced Features

- [ ] Implement `leyline sync --dry-run` that shows what would be synced without making changes, including diff preview
- [ ] Add `leyline sync --categories list` subcommand that shows all available categories with descriptions
- [ ] Implement offline caching in `~/.leyline/cache/` storing last successful sync for offline development
- [ ] Add `leyline sync --from-cache` flag to use cached content when offline or for faster repeated syncs
- [ ] Create `leyline sync status` subcommand showing current sync state, version, last sync time, and modification status
- [ ] Implement `leyline sync --exclude` option accepting glob patterns to skip specific files (e.g., --exclude "**/experimental-*")
- [ ] Add telemetry collection (opt-in) to understand usage patterns and improve auto-detection accuracy
- [ ] Create `leyline config` subcommand for managing persistent settings like default categories and sync path

## Phase 8: Documentation

- [ ] Write comprehensive `docs/cli/sync-command.md` documenting all flags, options, and usage examples
- [ ] Create `docs/cli/migration-from-workflow.md` guide for users transitioning from GitHub workflow approach
- [ ] Add troubleshooting section to documentation covering common issues (git not found, network errors, permission denied)
- [ ] Update main README.md with new "Quick Start" section showcasing `leyline sync` as primary integration method
- [ ] Create `examples/cli-integration/` directory with example scripts for various CI systems (GitHub Actions, GitLab CI, Jenkins)
- [ ] Write `docs/cli/architecture.md` explaining internal design for contributors with sequence diagrams
- [ ] Add inline code comments throughout implementation explaining design decisions and edge cases
- [ ] Create man page `man/leyline.1` for Unix systems with proper formatting and sections

## Phase 9: Testing & Quality

- [ ] Achieve 90%+ test coverage for all new code, verified by SimpleCov with detailed HTML reports
- [ ] Add performance benchmarks in `spec/benchmarks/sync_performance_spec.rb` ensuring sync completes in < 5 seconds for typical projects
- [ ] Create fixture repositories in `spec/fixtures/test-repos/` representing different project types for integration testing
- [ ] Implement mutation testing using Mutant gem to verify test effectiveness and catch missing edge cases
- [ ] Add memory profiling tests to ensure no memory leaks during large sync operations
- [ ] Create stress tests syncing hundreds of files to verify scalability and proper resource cleanup
- [ ] Write compatibility tests for Ruby 2.7, 3.0, 3.1, and 3.2 ensuring broad version support
- [ ] Add CI matrix testing across macOS, Linux, and Windows with different git versions

## Phase 10: Release Preparation

- [ ] Update `VERSION` file following semantic versioning for new minor version (e.g., 1.3.0)
- [ ] Write detailed CHANGELOG.md entry documenting new CLI sync feature with migration notes
- [ ] Create GitHub release PR template specifically for CLI feature releases with checklist
- [ ] Add announcement template in `docs/announcements/cli-sync-launch-YYYY-MM.md` for user communication
- [ ] Update all example repositories to demonstrate both workflow and CLI approaches during transition
- [ ] Create feature flag `LEYLINE_ENABLE_CLI_SYNC` for gradual rollout and easy rollback if needed
- [ ] Plan deprecation timeline for workflow approach with 6-month transition period
- [ ] Prepare user survey to gather feedback on CLI experience after 1-month usage period

## Phase 11: Post-Launch

- [ ] Monitor GitHub issues for bug reports and feature requests related to CLI sync
- [ ] Create `leyline doctor` diagnostic command to help users troubleshoot sync issues
- [ ] Implement analytics dashboard to track adoption rate of CLI vs workflow approach
- [ ] Plan v2 features based on user feedback (parallel syncing, partial updates, conflict UI)
- [ ] Create automated migration tool to convert workflow configurations to CLI commands
- [ ] Document lessons learned and update contribution guidelines based on implementation experience
