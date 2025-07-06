# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Leyline provides a centralized system for defining and enforcing development principles through:
- **Tenets**: Immutable truths and principles that guide development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

The repository uses standardized YAML front-matter in all tenet and binding Markdown files.

## Common Commands

### Leyline CLI Commands
The transparency commands provide visibility into sync operations and changes:

```bash
# Synchronization and Management
leyline sync                      # Download leyline standards to current project
leyline sync -c typescript,go    # Sync specific categories only
leyline sync --dry-run           # Preview sync without making changes
leyline sync --stats            # Show detailed performance metrics

# Transparency Commands (added in transparency commands implementation)
leyline status                    # Show sync status and local modifications
leyline status -c typescript     # Check status for specific category only
leyline status --json           # Output status as JSON for automation
leyline diff                     # Show differences without applying changes
leyline diff --format json      # Output diff as JSON for scripts
leyline update                   # Preview and apply updates with conflict detection
leyline update --dry-run        # Show what would be updated without applying
leyline update --force          # Override conflicts (use carefully)

# Discovery Commands
leyline categories               # List all available categories
leyline show typescript         # Show documents in TypeScript category
leyline search "error handling" # Search leyline documents by content
leyline search testing --limit 5 # Limit search results

# Utility Commands
leyline version                  # Show version information
leyline version -v              # Verbose with system details
leyline help                    # Show comprehensive command overview
leyline help status             # Show detailed help for specific command
```

**Performance Tips:**
- Use category filtering (`-c`) for faster operations on large projects
- Add `--stats` to monitor cache efficiency and performance
- Target response times: <2s for all transparency operations
- Cache hit ratio >80% indicates optimal performance

**Common Workflows:**
1. **Initial Setup:** `leyline sync` → `leyline status`
2. **Change Detection:** `leyline diff` → `leyline update --dry-run` → `leyline update`
3. **Discovery:** `leyline categories` → `leyline show <category>` → `leyline search <query>`

### Ruby Documentation Tools
Location: `tools/`

```bash
# Validate YAML front-matter in all files
ruby tools/validate_front_matter.rb

# Validate a specific file
ruby tools/validate_front_matter.rb -f path/to/file.md

# Generate index files based on document metadata
ruby tools/reindex.rb

# Run reindex in strict mode (fails on YAML errors)
ruby tools/reindex.rb --strict

# Fix cross-references in documentation
ruby tools/fix_cross_references.rb

# Essential CI validation (fast mode for daily development)
ruby tools/run_ci_checks.rb --essential

# Full CI validation (comprehensive mode including advisory checks)
ruby tools/run_ci_checks.rb --full

# Essential validation with verbose output for debugging
ruby tools/run_ci_checks.rb --essential --verbose

# Optional advisory validation for interested authors (never blocks development)
ruby tools/run_advisory_checks.rb

# Advisory validation with verbose output
ruby tools/run_advisory_checks.rb --verbose

# Validate TypeScript binding configurations
ruby tools/validate_typescript_bindings.rb

# Validate TypeScript bindings with verbose output
ruby tools/validate_typescript_bindings.rb --verbose
```


## Architecture & Structure

### Repository Layout
```
docs/
├── tenets/                # Foundational principles
├── bindings/              # Enforceable rules
│   ├── core/              # Universal bindings
│   └── categories/        # Language/platform-specific
│       ├── go/
│       ├── rust/
│       ├── typescript/
│       ├── frontend/
│       └── backend/
tools/
├── *.rb                  # Ruby maintenance scripts
│   ├── validate_front_matter.rb  # Validates YAML front-matter
│   ├── reindex.rb                # Rebuilds document indexes
│   ├── fix_cross_references.rb   # Fixes internal cross-references
│   ├── run_ci_checks.rb          # Local CI simulation for pre-push validation
│   └── validate_typescript_bindings.rb  # Validates TypeScript binding configurations
```

### Repository Architecture

All tenet and binding files use YAML front-matter for metadata, which provides a standardized, machine-readable way to define document properties.

The repository follows a structured architecture with:

1. **Tenets**: Located in `docs/tenets/` - represent core principles
2. **Bindings**: Located in `docs/bindings/` with categories:
   - Core bindings in `docs/bindings/core/` - apply to all projects
   - Category-specific bindings in `docs/bindings/categories/<category>/`
3. **Tools**: Ruby scripts to validate and maintain documents:
   - `validate_front_matter.rb` - Ensures metadata follows YAML standards
   - `reindex.rb` - Creates index files based on document metadata
   - `fix_cross_references.rb` - Maintains link integrity

All tools strictly enforce YAML front-matter standards and follow proper error handling.

### Task Management System

The project uses a detailed TODO.md with task dependencies:
- Tasks are labeled with ID (T001, T002, etc.), type (Feature/Chore), and priority
- Dependencies are explicitly tracked with `Depends-on` fields
- To find the next unblocked task:
  ```bash
  grep -E '^\- \[ \].*' TODO.md | grep -vE 'Depends‑on.*\[' | head -1
  ```

### Testing Strategy

- Unit tests are co-located with source files (*.test.ts)
- Test fixtures are stored in `test/fixtures/`
- Tests focus on public APIs and behavior
- Coverage target: 85%+
- No internal mocking - refactor for testability instead

### Test Commands

The repository uses RSpec for testing with different test categories:

```bash
# Fast unit tests (recommended for daily development and quality gates)
bundle exec rspec                        # Runs unit tests only (excludes performance/benchmark)

# Specific test categories
bundle exec rspec --tag performance      # Run performance tests only
bundle exec rspec --tag benchmark        # Run benchmark tests only
bundle exec rspec --tag integration      # Run integration tests only

# Combined test runs
bundle exec rspec --tag performance --tag benchmark  # Run all slow tests
bundle exec rspec --exclude-tag integration         # Exclude integration tests only

# All tests (including slow performance and benchmark tests)
bundle exec rspec --tag performance --tag benchmark --tag integration
```

**Test Categories:**
- **Unit tests**: Fast tests for core functionality (default)
- **Performance tests**: Statistical performance benchmarks with multiple iterations
- **Benchmark tests**: Micro/macro benchmarks for specific components
- **Integration tests**: End-to-end workflow testing

**Performance Notes:**
- Default `bundle exec rspec` runs in <10 seconds (unit tests only)
- Performance tests can take 2-5 minutes (statistical measurement with warmup)
- Benchmark tests include memory usage and scalability analysis

### Development Workflow

1. Pre-commit hooks automatically:
   - Fix trailing whitespace
   - Ensure files end with newline
   - Validate YAML syntax
   - Check for large files

2. Conventional commits are enforced:
   - Format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore
   - Include meaningful body explaining the "why"

3. Task completion process:
   - Run all tests and linting before marking complete
   - Update TODO.md to mark task as [x]
   - Commit with descriptive conventional commit message

## Performance & Cache Optimization

### Cache-Aware Sync Performance

Leyline implements intelligent cache-aware syncing to dramatically improve performance for repeated sync operations:

**Performance Targets:**
- First sync (cold cache): Normal git fetch time (~2-5 seconds)
- Second sync (warm cache): <1 second when cache hit ratio >80%
- Cache hit ratio: >80% for typical development workflows

### Cache Configuration

**Environment Variables:**
```bash
# Cache hit ratio threshold (default: 0.8 = 80%)
export LEYLINE_CACHE_THRESHOLD=0.8

# Disable cache warnings (default: enabled)
export LEYLINE_CACHE_WARNINGS=false

# Enable structured JSON logging (default: human-readable)
export LEYLINE_STRUCTURED_LOGGING=true

# Enable debug mode for detailed logging
export LEYLINE_DEBUG=true

# Enable automatic cache recovery (experimental)
export LEYLINE_CACHE_AUTO_RECOVERY=true
```

### CLI Performance Flags

```bash
# Force git operations even when cache is sufficient
leyline sync --force-git

# Show detailed cache and performance statistics
leyline sync --stats

# Bypass cache entirely (force fresh fetch)
leyline sync --no-cache

# Combine for detailed analysis
leyline sync --stats --verbose
```

### Performance Monitoring

**Example Stats Output:**
```
Cache Performance:
  Cache hits: 45
  Cache misses: 5
  Hit ratio: 90.0%
  Cache puts: 5
  Cache operations: 55

Timing Performance:
  Total sync time: 0.8s
  Cache check time: 0.1s
  Git operations: SKIPPED (cache sufficient)
  File operations: 0.7s

Cache Directory Stats:
  Files: 1,250
  Size: 15.2 MB
  Path: ~/.cache/leyline
```

**Performance Benchmarks:**
- Cache-aware sync typically achieves 70-90% performance improvement on subsequent runs
- Git operations are automatically skipped when cache hit ratio exceeds threshold
- Smart cache invalidation ensures content consistency

### Cache Directory Management

**Default Cache Location:** `~/.cache/leyline/`

**Cache Structure:**
```
~/.cache/leyline/
├── content/        # SHA256-addressed content files
│   ├── ab/         # First 2 chars of hash
│   │   └── cd...   # Remaining hash as filename
└── metadata/       # Cache metadata and stats
```

**Cache Health Monitoring:**
- Automatic corruption detection and cleanup
- Health status reporting in verbose mode
- Graceful fallback to git operations on cache failures

## CI Failure Prevention

### Recommended Daily Development Workflow

**Essential Validation (Recommended for Daily Use):**
```bash
# Fast essential validation (~0.3 seconds) - YAML + Index only
ruby tools/run_ci_checks.rb --essential
```

**Comprehensive Validation (Optional for Thorough Checking):**
```bash
# Full validation with advisory checks (20-60 seconds)
ruby tools/run_ci_checks.rb --full

# Full validation with verbose output for debugging
ruby tools/run_ci_checks.rb --full --verbose
```

**Validation Modes Explained:**
- `--essential`: Fast validation of critical quality gates (YAML front-matter, Index consistency)
- `--full`: Comprehensive validation including advisory checks (cross-references, TypeScript, security)

### Common CI Failure Types & Prevention

**YAML Front-matter Issues:**
```bash
# Validate specific file
ruby tools/validate_front_matter.rb -f docs/bindings/categories/typescript/your-binding.md

# Validate all files
ruby tools/validate_front_matter.rb
```

**Advisory Validation (Available in Full Mode):**
```bash
# TypeScript binding configurations (advisory only - educational examples)
ruby tools/validate_typescript_bindings.rb --verbose

# Cross-reference validation (advisory only - not blocking)
ruby tools/validate_cross_references.rb
ruby tools/fix_cross_references.rb

# Security scanning (advisory only - educational content may trigger false positives)
gitleaks detect --source=. --no-git --verbose

# Dependency auditing (advisory only - example projects are educational)
cd examples/typescript-full-toolchain && pnpm audit --audit-level=moderate
```

**Note:** Advisory validations are available in `--full` mode but do not block CI builds.
Educational documentation prioritizes clarity and knowledge transfer over production-grade validation.

### Pre-Push Integration (Recommended)

Add to your local `.git/hooks/pre-push` for automatic fast validation:
```bash
#!/bin/bash
echo "🚀 Running essential validation before push..."
ruby tools/run_ci_checks.rb --essential
if [ $? -ne 0 ]; then
    echo "❌ Essential validation failed. Fix issues before pushing."
    echo "💡 Run 'ruby tools/run_ci_checks.rb --essential --verbose' for details"
    exit 1
fi
echo "✅ Essential validation passed (~0.3s). Proceeding with push."
```

Make executable: `chmod +x .git/hooks/pre-push`

**Alternative for comprehensive checking:**
```bash
# For authors who want thorough validation (slower)
ruby tools/run_ci_checks.rb --full
```
