# Leyline CLI Backlog

*What would John Carmack do? Make it fast, reliable, and predictable.*

## Core Philosophy

1. **Speed is a feature** - Every command should complete in under 2 seconds
2. **No surprises** - Always show what will happen before doing it
3. **Progressive disclosure** - Simple by default, powerful when needed
4. **Fail loudly** - Clear errors with actionable fixes
5. **Zero config** - Works perfectly out of the box

## Priority 1: Performance (Make it Fast)

### Cache GitHub Content Locally

#### PR 1: Add Local File Cache Infrastructure
- **Problem**: No caching mechanism exists, causing repeated 3-5 second git operations
- **Solution**: Implement file-based cache using existing SHA256 hashing from FileSyncer
- **Implementation**:
  - Create `Leyline::Cache::FileCache` class
  - Store files in `~/.leyline/cache/content/[sha256]/`
  - Reuse `FileSyncer#files_different?` logic for cache validation
  - Add cache directory creation and cleanup utilities
  - Maximum cache size: 50MB with LRU eviction
- **Testing**: Unit tests for cache operations (store, retrieve, evict)
- **Success**: Cache hit/miss functionality working with existing git flow

#### PR 2: Integrate Cache with Git Sync Flow
- **Problem**: Git sync doesn't check cache before fetching
- **Solution**: Modify sync flow to check cache before git operations
- **Implementation**:
  - Update `FileSyncer#sync` to check cache before copying
  - Cache files after successful git fetch
  - Add cache statistics to verbose output
  - No changes to existing CLI interface
- **Testing**: Integration tests showing performance improvement
- **Success**: Second sync of same content completes in <1 second

#### PR 3: Add --no-cache Flag
- **Problem**: No way to bypass cache for fresh content
- **Solution**: Add `--no-cache` flag to sync command
- **Implementation**:
  - Add `no_cache` option to `CliOptions::SYNC_OPTIONS`
  - Pass flag through to `FileSyncer`
  - Clear relevant cache entries when flag is used
  - Update help documentation
- **Testing**: CLI tests for new flag behavior
- **Success**: Users can force fresh sync when needed

#### PR 4: Add Cache Version Management
- **Problem**: Cache doesn't handle different leyline versions
- **Solution**: Version-aware cache keys
- **Implementation**:
  - Read version from fetched `VERSION` file
  - Include version in cache key: `[version]-[sha256]`
  - Auto-cleanup old version caches (keep last 3)
  - Add version info to cache statistics
- **Testing**: Tests for version transitions and cleanup
- **Success**: Different versions don't conflict in cache

#### PR 5: Optimize Git Operations for Cache Misses
- **Problem**: Still doing full sparse-checkout even for single file updates
- **Solution**: Track which files need updates before git operations
- **Implementation**:
  - Pre-scan target directory for existing files
  - Compare with expected file list from categories
  - Only fetch if >20% files need updates
  - Otherwise, skip git entirely for cached files
- **Testing**: Performance tests with various cache hit ratios
- **Success**: Near-instant sync when most files are cached

#### Future Enhancement (Not Priority 1): GitHub API Integration
- **Problem**: Git operations still needed for cache misses
- **Solution**: Use GitHub API for individual file fetches
- **Note**: Separate feature requiring new dependencies and auth handling
- **Complexity**: Requires HTTP client, rate limiting, auth tokens
- **Decision**: Defer until cache proves insufficient

### Parallel File Operations
- **Problem**: Files copied sequentially
- **Solution**: Copy files in parallel
- **Success**: 50+ files sync in <0.2 seconds

## Priority 2: Discoverability (Know What's Available)

### List Available Categories
```bash
leyline categories
# Shows all categories with description and file count
```

### Show Category Contents
```bash
leyline show typescript
# Lists all bindings in typescript category
```

### Search Standards
```bash
leyline search "testing"
# Finds all tenets/bindings mentioning testing
```

## Priority 3: Transparency (See What Changed)

### Diff Before Sync
```bash
leyline diff --categories typescript
# Shows what would change without syncing
```

### Update Existing Standards
```bash
leyline update
# Shows which standards have updates available
# Preserves local modifications, shows conflicts
```

### Status Command
```bash
leyline status
# Shows:
# - Current leyline version synced
# - Which standards are modified locally
# - Which standards have updates available
```

## Priority 4: Better Integration

### Machine-Readable Output
```bash
leyline sync --categories typescript --json
# {"synced": 32, "skipped": 0, "errors": 0, "files": [...]}
```

### Exit Codes
- 0: Success
- 1: Sync failed
- 2: Conflicts detected
- 3: Network error

### CI Mode
```bash
leyline sync --ci
# No interactive prompts
# Fails if conflicts detected
# Machine-readable output
```

## Priority 5: Version Management

### Pin to Specific Version
```bash
leyline sync --version v0.1.5
# Syncs specific leyline version
```

### Version File
```yaml
# .leyline-version
version: v0.1.5
categories: [typescript, web]
```

### Check for Updates
```bash
leyline update-check
# Checks if newer version available
```

## Nice to Have (Maybe Later)

### Interactive Mode
```bash
leyline sync -i
# Shows each file, asks y/n/d (yes/no/diff)
```

### Custom Target Directory
```bash
leyline sync --target ./standards
# For teams with different structures
```

### Exclude Patterns
```bash
leyline sync --exclude "*experimental*"
# Skip certain files
```

### Generate Config
```bash
leyline init
# Creates .leyline-version file
```

## What We're NOT Building

- ❌ Complex configuration files (use flags/env vars)
- ❌ Plugin system (keep it simple)
- ❌ Custom remote sources (only official leyline)
- ❌ Modification tracking database (use git)
- ❌ Automated PR creation (that's a workflow concern)
- ❌ Language auto-detection (we already killed this)

## Success Metrics

1. Time from install to first sync: <30 seconds
2. Sync performance: <2 seconds (uncached), <0.5 seconds (cached)
3. Zero configuration required for 90% of users
4. Clear error messages that tell users how to fix issues
5. Works identically on macOS, Linux, Windows

## Technical Decisions

### Caching Strategy
- Use `~/.leyline/cache/[version]/` structure
- Cache invalidation via version tags
- Store cache metadata (fetch time, etag)
- Max cache size: 50MB (auto-cleanup old versions)

### API vs Git
- Use GitHub API for individual file fetches
- Fall back to git sparse-checkout if API fails
- API is faster for small sets, git better for full sync

### File Storage
- Keep current structure: `docs/leyline/docs/[tenets|bindings]/`
- Consider flattening in future: `docs/leyline/[tenets|bindings]/`
- But that's a breaking change, so maybe v2

### Error Handling
- Network errors: Suggest --no-cache or check connection
- Permission errors: Show exact file and permission needed
- Conflicts: Show diff and suggest --force or manual resolution

## Implementation Order

1. **Performance**: Cache system (biggest UX improvement)
2. **Discoverability**: categories/show/search commands
3. **Transparency**: diff/update/status commands
4. **Integration**: JSON output and proper exit codes
5. **Version Management**: Version pinning and checks

Each phase should be shippable independently. No big rewrites.

## Example Future Usage

```bash
# First time user
$ gem install leyline
$ cd my-project
$ leyline categories
typescript  - TypeScript best practices (13 bindings)
go          - Go idioms and patterns (8 bindings)
rust        - Rust safety and performance (5 bindings)
...

$ leyline sync --categories typescript
Synchronizing leyline v0.1.7 standards to: ./docs/leyline
Fetching from cache (last updated: 2 hours ago)
Synced: 32 files in 0.3s

# Returning user
$ leyline status
Leyline v0.1.5 (v0.1.7 available)
Modified: docs/leyline/docs/bindings/categories/typescript/no-any.md
Run 'leyline update' to see available updates

$ leyline update
Updates available for 3 files:
  tenets/simplicity.md
  bindings/categories/typescript/modern-typescript-toolchain.md
  bindings/categories/typescript/vitest-testing-framework.md

$ leyline diff
--- docs/leyline/docs/tenets/simplicity.md
+++ Updated version
@@ -15,6 +15,8 @@
+ New section on complexity metrics
+ Additional examples

Update? [y/N/d] y
Updated 3 files, skipped 1 modified file
```

This is the experience we're building toward. Fast, clear, predictable.
