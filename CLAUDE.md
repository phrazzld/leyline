# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Leyline provides a centralized system for defining and enforcing development principles through:
- **Tenets**: Immutable truths and principles that guide development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

The repository includes a metadata migration tool in `tools/metadata-migration/` that converts legacy horizontal rule metadata to standardized YAML front-matter in all tenet and binding Markdown files.

## Common Commands

### Metadata Migration Tool (TypeScript)
Location: `tools/metadata-migration/`

```bash
# Build the TypeScript project
pnpm run build

# Run tests
pnpm test               # Run all tests once
pnpm test:watch        # Run tests in watch mode
pnpm test:coverage     # Run tests with coverage report

# Run a single test file
pnpm test src/legacyParser.test.ts

# Development
pnpm run dev           # Run TypeScript files directly with ts-node
pnpm run lint          # Type-check without emitting files
pnpm run format        # Format code with Prettier
```

### Legacy Ruby Tools
Location: `tools/`
- `validate_front_matter.rb` - Validates YAML front matter in markdown files
- `reindex.rb` - Rebuilds document indexes
- `fix_cross_references.rb` - Fixes internal cross-references in documentation

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
├── metadata-migration/    # TypeScript metadata conversion tool
│   ├── src/              # TypeScript source files
│   ├── test/fixtures/    # Test fixture files
│   └── dist/            # Compiled JavaScript (gitignored)
└── *.rb                  # Legacy Ruby maintenance scripts
```

### Metadata Migration Architecture

The TypeScript migration tool follows a modular pipeline architecture:

1. **FileWalker**: Recursively finds Markdown files
2. **MetadataInspector**: Detects metadata format (yaml, legacy-hr, none, unknown)
3. **LegacyParser**: Parses raw legacy metadata into structured objects
4. **MetadataConverter**: Transforms LegacyMetadata to StandardYamlMetadata
5. **YamlSerializer**: Generates valid YAML front-matter
6. **BackupManager**: Creates backups before file modification
7. **MigrationEngine**: Orchestrates the complete migration process

All modules use structured logging via the Logger module and follow strict TypeScript typing (no `any` types).

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
