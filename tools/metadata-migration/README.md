# Metadata Migration Tool

A TypeScript tool that converts legacy horizontal rule metadata format to standardized YAML front-matter in Markdown files.

## Overview

This tool is part of the "Eliminate Dual Metadata Formats" initiative in the Leyline project. It automatically detects and converts legacy horizontal rule (HR) metadata to YAML front-matter format while preserving document content and structure.

## Features

- **Automatic format detection**: Identifies files with legacy HR metadata, YAML front-matter, or no metadata
- **Safe conversion**: Creates backups before modifying files to prevent data loss
- **Dry-run mode**: Preview changes without modifying files
- **Idempotent operation**: Files already using YAML format are left unchanged
- **Comprehensive logging**: Structured JSON logs for debugging and monitoring
- **Flexible file selection**: Process individual files, directories, or multiple paths
- **Configurable backups**: Specify custom backup directory location

## Installation

```bash
# Navigate to the tool directory
cd tools/metadata-migration

# Install dependencies
pnpm install

# Build the TypeScript files
pnpm run build
```

## Usage

### Basic usage

Convert all markdown files in a directory:

```bash
node dist/index.js docs/tenets docs/bindings
```

### Dry-run mode

Preview conversions without making changes:

```bash
node dist/index.js --dry-run docs/
```

### Custom backup directory

Specify where backups should be stored:

```bash
node dist/index.js --backup-dir ./my-backups docs/
```

### Process specific files

Convert individual files:

```bash
node dist/index.js docs/tenets/simplicity.md docs/bindings/core/no-any.md
```

### Command-line options

- `paths...`: One or more file or directory paths to process
- `--dry-run`: Preview changes without modifying files
- `--backup-dir`: Directory for storing backup files (defaults to a timestamped directory under `backups/`)

## Development

### Project structure

```
metadata-migration/
├── src/
│   ├── index.ts              # CLI entry point
│   ├── types.ts              # TypeScript interfaces and types
│   ├── logger.ts             # Structured logging
│   ├── fileWalker.ts         # File discovery
│   ├── metadataInspector.ts  # Format detection
│   ├── legacyParser.ts       # Legacy metadata parsing
│   ├── metadataConverter.ts  # Legacy to YAML conversion
│   ├── yamlSerializer.ts     # YAML generation
│   ├── fileRewriter.ts       # File modification
│   ├── backupManager.ts      # Backup handling
│   ├── cliHandler.ts         # CLI argument parsing
│   ├── migrationEngine.ts    # Main migration logic
│   └── migrationOrchestrator.ts # Workflow orchestration
├── test/
│   └── fixtures/             # Test fixture files
├── dist/                     # Compiled JavaScript (gitignored)
├── package.json
├── tsconfig.json
└── README.md
```

### Development commands

```bash
# Run TypeScript compiler in watch mode
pnpm run dev

# Run tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Generate test coverage report
pnpm test:coverage

# Type-check without emitting files
pnpm run lint

# Format code with Prettier
pnpm run format

# Build for production
pnpm run build
```

### Testing

The tool includes comprehensive unit and integration tests:

- **Unit tests**: Test individual modules in isolation
- **Integration tests**: Test end-to-end workflows with realistic file operations

Run a specific test file:

```bash
pnpm test src/legacyParser.test.ts
```

## How it works

1. **Discovery**: Recursively finds all Markdown files in specified paths
2. **Detection**: Identifies metadata format (legacy HR, YAML, or none)
3. **Parsing**: Extracts metadata from legacy format
4. **Conversion**: Transforms legacy format to standardized YAML
5. **Validation**: Ensures required fields are present
6. **Backup**: Creates backup of original file
7. **Rewriting**: Updates file with YAML front-matter
8. **Verification**: Logs results and any errors

## Legacy format example

```markdown
# Example Tenet

Some content here.

___

**ID:** example-tenet
**Type:** tenet
**Category:** core
**Created:** 2024-03-15
**Updated:** 2024-03-16
**Priority:** high
```

## Converted YAML format

```markdown
---
id: example-tenet
type: tenet
category: core
created: 2024-03-15
updated: 2024-03-16
priority: high
---

# Example Tenet

Some content here.
```

## Error handling

The tool handles various error scenarios:

- **Malformed metadata**: Logs warnings and skips problematic files
- **Missing required fields**: Reports validation errors
- **File system errors**: Creates detailed error logs
- **Backup failures**: Prevents file modification if backup fails

## Logging

All operations are logged as structured JSON to stdout:

```json
{
  "level": "info",
  "message": "Successfully converted file",
  "context": {
    "filePath": "docs/tenets/example.md",
    "format": "legacy-hr",
    "backupPath": "backups/backup-20240315-143022/docs/tenets/example.md"
  }
}
```

## Important notes

- **Always backup your data** before running the migration
- The tool is idempotent - running it multiple times is safe
- Files already using YAML front-matter are not modified
- Content below metadata is preserved exactly as-is
- The tool preserves file permissions and timestamps

## Troubleshooting

### Common issues

1. **Permission denied errors**
   - Ensure you have read/write permissions for the target files
   - Check backup directory permissions

2. **Module not found errors**
   - Run `pnpm install` to install dependencies
   - Run `pnpm run build` to compile TypeScript files

3. **Invalid YAML errors**
   - Check for special characters in metadata values
   - Ensure proper date formatting (YYYY-MM-DD)

### Debug mode

Enable debug logging by setting the log level:

```bash
LOG_LEVEL=debug node dist/index.js docs/
```

## Contributing

When contributing to this tool:

1. Follow the TypeScript coding standards
2. Add tests for new functionality
3. Update documentation as needed
4. Run all tests before submitting PRs
5. Use conventional commits

## License

This tool is part of the Leyline project and shares its license.
