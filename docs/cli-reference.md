# CLI Reference

Complete reference for the Leyline CLI commands and options.

## Table of Contents

- [Installation](#installation)
- [Global Options](#global-options)
- [Command Categories](#command-categories)
- [Discovery Commands](#discovery-commands)
- [Sync Commands](#sync-commands)
- [Utility Commands](#utility-commands)
- [Configuration File](#configuration-file)
- [Performance & Caching](#performance--caching)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Installation

```bash
gem install leyline
```

## Global Options

All commands support these global options:

- `-v, --verbose` - Show detailed output
- `--stats` - Show cache performance statistics
- `--json` - Output in JSON format (where applicable)

## Command Categories

### Discovery Commands

Explore and search leyline documentation content.

#### `leyline discovery categories`

List all available categories for synchronization.

```bash
leyline discovery categories
leyline discovery categories --json
```

**Options:**
- `--json` - Output as JSON array

**Example Output:**
```
Available categories:
  typescript    TypeScript language bindings
  go           Go language bindings
  rust         Rust language bindings
  python       Python language bindings
  security     Security-focused bindings
  database     Database-related bindings
```

#### `leyline discovery show CATEGORY`

Show all documents in a specific category.

```bash
leyline discovery show typescript
leyline discovery show typescript --json
leyline discovery show typescript --verbose --stats
```

**Arguments:**
- `CATEGORY` - Category name (e.g., typescript, go, rust)

**Options:**
- `--json` - Output as JSON
- `--verbose` - Show detailed document information
- `--stats` - Show cache performance statistics

**Example Output:**
```
TypeScript Category Documents:
  Tenets: 12 documents
  Bindings: 8 documents

  Recent Documents:
    async-patterns.md (198 lines)
    avoid-type-gymnastics.md (189 lines)
    no-any.md (197 lines)

  Cache Performance:
    Hit ratio: 85.2%
    Response time: 0.3s
```

#### `leyline discovery search QUERY`

Search leyline documents by content.

```bash
leyline discovery search "error handling"
leyline discovery search "typescript async" --limit 5
leyline discovery search "testing" --json
```

**Arguments:**
- `QUERY` - Search query (supports partial matches)

**Options:**
- `--limit N` - Limit results to N documents
- `--json` - Output as JSON
- `--verbose` - Show document excerpts
- `--stats` - Show search performance statistics

**Example Output:**
```
Search Results for "error handling":
  3 documents found

  1. rust/error-handling.md (143 lines)
     "Comprehensive error handling patterns for Rust applications..."

  2. python/error-handling.md (135 lines)
     "Python error handling best practices and patterns..."

  3. core/fail-fast-validation.md (184 lines)
     "Implement fail-fast validation patterns for early error detection..."
```

### Sync Commands

Manage leyline standards synchronization and changes.

#### `leyline sync [PATH]`

Download and synchronize leyline standards to your project.

```bash
leyline sync
leyline sync -c typescript
leyline sync -c go,rust,security
leyline sync --dry-run
leyline sync --verbose --stats
```

**Arguments:**
- `PATH` - Target directory (default: current directory)

**Options:**
- `-c, --categories` - Specific categories to sync (comma-separated)
- `-n, --dry-run` - Show what would be synced without making changes
- `-v, --verbose` - Show detailed output
- `--no-cache` - Bypass cache and fetch fresh content
- `--force-git` - Force git operations even when cache is sufficient
- `--stats` - Show detailed cache and performance statistics

**Behavior:**
- Always rebuilds from remote (no local caching conflicts)
- Uses `.leyline` file configuration if present
- Command-line categories override config file categories
- Core bindings are always included

**Example Output:**
```
Syncing leyline standards...
Categories: typescript, go (from .leyline file)
Target: docs/leyline/

Fetching latest standards...
✓ Tenets: 12 documents synced
✓ Core bindings: 45 documents synced
✓ TypeScript bindings: 8 documents synced
✓ Go bindings: 7 documents synced

Sync completed in 2.3s
Cache hit ratio: 78.5%
Total documents: 72
```

#### `leyline status [PATH]`

Show sync status and local modifications.

```bash
leyline status
leyline status -c typescript
leyline status --json
leyline status --verbose --stats
```

**Arguments:**
- `PATH` - Target directory (default: current directory)

**Options:**
- `-c, --categories` - Filter status by specific categories
- `-v, --verbose` - Show detailed status information
- `--stats` - Show cache performance statistics
- `--json` - Output status in JSON format

**Example Output:**
```
Leyline Status:
  Last sync: 2025-07-09 15:30:42
  Categories: typescript, go, core
  Target: docs/leyline/

  Local Modifications:
    ✓ docs/leyline/tenets/simplicity.md (modified)
    ✓ docs/leyline/bindings/typescript/no-any.md (modified)

  Available Updates:
    • docs/leyline/bindings/core/automated-quality-gates.md
    • docs/leyline/tenets/automation.md

  Summary:
    Total documents: 72
    Local modifications: 2
    Available updates: 2
    Up to date: 68
```

#### `leyline diff [PATH]`

Show differences between local and remote leyline standards.

```bash
leyline diff
leyline diff -c typescript
leyline diff --format json
leyline diff --verbose --stats
```

**Arguments:**
- `PATH` - Target directory (default: current directory)

**Options:**
- `-c, --categories` - Filter diff by specific categories
- `-v, --verbose` - Show detailed diff output
- `--stats` - Show cache performance statistics
- `--format` - Output format (text, json)

**Example Output:**
```
Differences found:

Modified: docs/leyline/tenets/simplicity.md
--- remote
+++ local
@@ -15,7 +15,7 @@

 ## Key Principle

-Prefer the simplest design that works.
+Prefer the simplest design that works for our use case.

 ## Implementation

Updated: docs/leyline/bindings/core/automated-quality-gates.md
  • Remote version has 3 new lines
  • Local version is 2 commits behind
```

#### `leyline update [PATH]`

Preview and apply updates with conflict detection.

```bash
leyline update --dry-run
leyline update -c typescript
leyline update --force
leyline update --verbose --stats
```

**Arguments:**
- `PATH` - Target directory (default: current directory)

**Options:**
- `-c, --categories` - Update specific categories only
- `-f, --force` - Force updates even with conflicts
- `-n, --dry-run` - Show what would be updated without making changes
- `-v, --verbose` - Show detailed update information
- `--stats` - Show cache performance statistics

**Example Output:**
```
Update Preview:
  2 files would be updated
  1 conflict detected

  Safe Updates:
    ✓ docs/leyline/tenets/automation.md

  Conflicts:
    ⚠ docs/leyline/bindings/core/automated-quality-gates.md
      Local changes would be overwritten

  Use --force to override conflicts
  Use --dry-run to preview without applying
```

### Utility Commands

General CLI utility commands.

#### `leyline version`

Show version and system information.

```bash
leyline version
leyline version --verbose
leyline version --json
```

**Options:**
- `-v, --verbose` - Show detailed system information
- `--json` - Output version information as JSON

**Example Output:**
```
Leyline CLI v2.1.0
Ruby version: 3.1.4
Platform: darwin (macOS 14.5.0)
Cache directory: ~/.cache/leyline
```

#### `leyline help [COMMAND]`

Show help information for commands.

```bash
leyline help
leyline help sync
leyline help discovery
leyline help discovery show
```

**Arguments:**
- `COMMAND` - Specific command to show help for

## Configuration File

The `.leyline` file allows you to configure default settings for your project.

### File Format

```yaml
# .leyline configuration file
categories:
  - typescript
  - go
  - security
version: ">=2.0.0"
docs_path: "docs/leyline"
```

### Configuration Options

#### `categories`
**Type:** Array of strings
**Default:** `[]`
**Description:** List of categories to sync by default

```yaml
categories:
  - typescript
  - go
  - rust
```

#### `version`
**Type:** String
**Default:** `null`
**Description:** Version constraint for leyline compatibility

```yaml
version: ">=2.0.0"
version: "~>2.1.0"
```

#### `docs_path`
**Type:** String
**Default:** `"docs/leyline"`
**Description:** Target directory for synced documents

```yaml
docs_path: "standards/leyline"
docs_path: "docs/dev-standards"
```

### Configuration Precedence

1. Command-line options (highest precedence)
2. `.leyline` file configuration
3. Default values (lowest precedence)

### Configuration Validation

The CLI validates configuration files and provides helpful error messages:

```bash
$ leyline sync
Error: Invalid .leyline configuration
  - categories must be an array
  - Invalid version constraint: 2.0.0

Suggestions:
  • Check .leyline file syntax (must be valid YAML)
  • Ensure categories is an array of strings
  • Validate version constraint format (e.g., ">=2.0.0")
  • Run leyline discovery categories to see available categories
```

## Performance & Caching

### Cache System

Leyline uses intelligent caching to improve performance:

- **Cache Location:** `~/.cache/leyline`
- **Cache Strategy:** Content-addressed storage with SHA256 hashing
- **Cache Invalidation:** Automatic based on remote content changes
- **Cache Statistics:** Available via `--stats` flag

### Performance Flags

#### `--stats`
Show detailed performance and cache statistics:

```bash
leyline sync --stats
```

**Output:**
```
Cache Performance:
  Cache hits: 45
  Cache misses: 5
  Hit ratio: 90.0%
  Cache operations: 55

Timing Performance:
  Total sync time: 0.8s
  Cache check time: 0.1s
  Git operations: SKIPPED (cache sufficient)
  File operations: 0.7s
```

#### `--no-cache`
Bypass cache entirely and fetch fresh content:

```bash
leyline sync --no-cache
```

#### `--force-git`
Force git operations even when cache is sufficient:

```bash
leyline sync --force-git
```

### Performance Targets

- **Startup time:** <1 second
- **Sync operations:** <2 seconds (cached)
- **Cache hit ratio:** >80% for typical workflows

## Examples

### Basic Workflow

```bash
# Initial setup
leyline sync -c typescript

# Check status
leyline status

# View changes
leyline diff

# Apply updates
leyline update --dry-run
leyline update
```

### Configuration-Driven Workflow

```bash
# Create .leyline file
cat > .leyline <<EOF
categories:
  - typescript
  - go
  - security
version: ">=2.0.0"
EOF

# Sync using configuration
leyline sync

# Check status with statistics
leyline status --stats
```

### Discovery Workflow

```bash
# Explore available categories
leyline discovery categories

# Examine specific category
leyline discovery show typescript

# Search for specific content
leyline discovery search "async patterns"
leyline discovery search "error handling" --limit 3
```

### Automation Workflow

```bash
# JSON output for scripts
leyline discovery categories --json
leyline status --json
leyline diff --format json

# Automated update checking
if leyline diff --format json | jq -e '.changes | length > 0'; then
  echo "Updates available"
  leyline update --dry-run
fi
```

## Troubleshooting

### Common Issues

#### Cache Issues
```bash
# Clear cache and retry
rm -rf ~/.cache/leyline
leyline sync --no-cache
```

#### Configuration Problems
```bash
# Validate configuration
leyline sync --verbose

# Check available categories
leyline discovery categories
```

#### Performance Issues
```bash
# Check cache performance
leyline status --stats

# Force fresh content
leyline sync --no-cache --force-git
```

### Debug Information

Use verbose mode for detailed troubleshooting:

```bash
leyline sync --verbose --stats
```

### Getting Help

- Run `leyline help` for general help
- Run `leyline help COMMAND` for specific command help
- Check the [GitHub repository](https://github.com/phrazzld/leyline) for issues and documentation

## Legacy Command Support

For backward compatibility, these legacy commands are still supported:

```bash
# Legacy commands (still work)
leyline categories        # Same as: leyline discovery categories
leyline show typescript   # Same as: leyline discovery show typescript
leyline search "query"    # Same as: leyline discovery search "query"
```

**Recommendation:** Use the new `discovery` subcommands for better organization and future compatibility.
