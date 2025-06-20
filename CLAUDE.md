# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Leyline provides a centralized system for defining and enforcing development principles through:
- **Tenets**: Immutable truths and principles that guide development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

The repository uses standardized YAML front-matter in all tenet and binding Markdown files.

## Common Commands

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
