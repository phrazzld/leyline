# Changelog

All notable changes to the Leyline project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Discovery subcommand structure** for exploring leyline documents
  - `leyline discovery categories` - List available leyline categories
  - `leyline discovery show <category>` - Show documents in specific category
  - `leyline discovery search <query>` - Search leyline documents by content
  - JSON output support with `--json` flag for all discovery commands
  - Verbose mode with `--verbose` flag for detailed information
  - Performance statistics with `--stats` flag

- **.leyline configuration file** support for project-specific settings
  - YAML configuration file defining categories, version constraints, and docs path
  - Command-line categories override configuration file settings
  - Comprehensive validation with helpful error messages
  - Documentation at `docs/leyline-file-format.md`

- **Enhanced CLI infrastructure** with shared BaseCommand pattern
  - Consistent error handling and recovery suggestions across all commands
  - Unified output formatting (JSON and human-readable)
  - Shared helper methods and option parsing
  - Platform detection and time measurement utilities

- **Performance optimizations**
  - Cache-aware operations with performance monitoring
  - Background cache warming for discovery commands
  - Startup time under 1 second for all commands
  - Memory usage optimization

- **Comprehensive documentation**
  - Complete CLI reference at `docs/cli-reference.md`
  - .leyline file format specification
  - Performance optimization guides
  - Troubleshooting documentation

### Changed

- **CLI architecture refactored** to clean router pattern
  - Main CLI class reduced from 420 to 155 lines (63% reduction)
  - All commands now inherit from BaseCommand for consistency
  - Removed code duplication across command implementations
  - Simplified option passing and error handling

- **Enhanced version command** with detailed system information
  - Verbose mode shows platform details, Ruby version, cache status
  - JSON output support for automation
  - Git availability detection

- **Improved help system** with comprehensive command documentation
  - Custom help command with categorized command overview
  - Quick start guide and troubleshooting tips
  - Performance optimization recommendations

- **Sync command simplified** for more predictable behavior
  - Always rebuilds local state (no --force flag needed)
  - Reads .leyline configuration file automatically
  - Shows configuration source in output

### Removed

- **BREAKING**: Removed deprecated `applies_to` metadata field from bindings
  - Directory structure is now the single source of truth for binding categorization
  - Files in `docs/bindings/core/` apply to all projects
  - Files in `docs/bindings/categories/<category>/` apply to specific categories
  - Updated validation tools to reject `applies_to` field if present
  - Updated documentation to reflect directory-based categorization approach

- **BREAKING**: Removed `--force` flag from sync command
  - Sync command now always rebuilds for consistency
  - Use `--dry-run` to preview changes without applying

### Fixed

- Thor string/symbol key compatibility issues across all commands
- JSON output format consistency for automation scripts
- Error handling for missing sync state and cache failures
- Cross-reference validation in documentation tools

### Deprecated

- **Legacy discovery commands** (backward compatible but deprecated)
  - `leyline categories` → use `leyline discovery categories`
  - `leyline show <category>` → use `leyline discovery show <category>`
  - `leyline search <query>` → use `leyline discovery search <query>`
  - Legacy commands still work but show deprecation notices in help

## [1.1.0] - 2025-05-21

### Changed

- **BREAKING**: Standardized to YAML-only front-matter for all tenet and binding metadata
  - Removed support for legacy horizontal rule format
  - All tools now enforce YAML-only metadata validation
  - Updated pre-commit hooks and CI workflows to enforce YAML format
  - Added strict validation mode to `reindex.rb` and `validate_front_matter.rb`
  - See [TENET_FORMATTING.md](TENET_FORMATTING.md) for format requirements

### Removed

- Removed legacy horizontal rule metadata format support
- Removed legacy metadata conversion tools (migration history preserved in git)
- Removed `--strict` flag from `validate_front_matter.rb` (now always strict)

### Added

- Added more robust error handling for YAML validation in tools

## [1.0.0] - 2025-05-01

### Added

- Initial release of Leyline
- Core tenets and bindings framework
- Directory-based binding categories
- Automated synchronization workflow for repositories
- Pre-commit hook support
- YAML front-matter and legacy format support
