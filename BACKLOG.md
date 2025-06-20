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
- **Problem**: Currently clones entire repo via git (slow, ~3-5 seconds)
- **Solution**: Use GitHub API to fetch only needed files, cache locally
- **Implementation**:
  - Cache in `~/.leyline/cache/[version]/`
  - Check cache before fetching
  - `--no-cache` flag to force refresh
- **Success**: Sync completes in <0.5 seconds for cached content

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
