# CLI Sync Implementation TODO

What would John Carmack do? Ship the simplest thing that works. Delete everything else.

## Phase 1: Delete Overengineered Code ✅ COMPLETED

- [x] Remove entire `lib/leyline/detection/` directory - we don't need language detection
- [x] Remove entire `spec/lib/leyline/detection/` directory - we don't need these tests
- [x] Simplify `lib/leyline/cli.rb` - remove all detection methods, just use explicit --categories
- [x] Update `spec/lib/leyline/cli_spec.rb` - remove language detection tests
- [x] Remove 'data-science' from VALID_CATEGORIES if not needed

## Phase 2: Ship Core Value ✅ COMPLETED

- [x] Implement actual file sync in `lib/leyline/sync/file_syncer.rb` - just copy files from git to target
- [x] Wire up GitClient + FileSyncer in CLI - make `leyline sync --categories typescript` actually work
- [x] Add basic conflict handling - skip modified files by default, overwrite with --force
- [x] Write minimal tests to verify it works
- [x] Ship it. Get user feedback. Iterate.

## What's Working Now

```bash
# Sync TypeScript standards
leyline sync --categories typescript

# Sync multiple categories
leyline sync --categories go,rust

# Force overwrite local changes
leyline sync --categories typescript --force

# See what's happening
leyline sync --categories typescript --verbose
```

**Features:**
- Syncs tenets + requested category bindings
- Smart conflict detection (skips identical files)
- Preserves local modifications by default
- Force flag to overwrite when needed
- Clear output about what was synced

**Next:** Get real user feedback before adding more features.

## Phase 3: Maybe Later (If Users Actually Ask)

- [ ] Add progress indicators (but text output is probably fine)
- [ ] Add --dry-run flag (users can just look at the files)
- [ ] Add .leyline-sync.yml state tracking (or just use git)
- [ ] Integration with reindex.rb (can be manual for now)

## What We're NOT Building (Until Proven Necessary)

- ❌ Auto-detection of languages (users know their stack)
- ❌ Complex UI with colors and spinners (this is a CLI tool)
- ❌ Offline caching (git already caches)
- ❌ Telemetry (privacy matters)
- ❌ Config files (command line flags are sufficient)
- ❌ Multiple subcommands (one command, one job)
- ❌ 90% test coverage (test what breaks, ship what works)

## Success Metric

Can a user type `leyline sync --categories typescript,react` and get their standards synced? That's it.

Everything else is negotiable.
