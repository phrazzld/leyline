# Changelog

All notable changes to the Leyline project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- **BREAKING**: Removed deprecated `applies_to` metadata field from bindings
  - Directory structure is now the single source of truth for binding categorization
  - Files in `docs/bindings/core/` apply to all projects
  - Files in `docs/bindings/categories/<category>/` apply to specific categories
  - Updated validation tools to reject `applies_to` field if present
  - Updated documentation to reflect directory-based categorization approach

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
- Removed legacy metadata conversion tools (moved to archive)
- Removed `--strict` flag from `validate_front_matter.rb` (now always strict)

### Added

- Added archive directory with migration history documentation
- Added more robust error handling for YAML validation in tools

## [1.0.0] - 2025-05-01

### Added

- Initial release of Leyline
- Core tenets and bindings framework
- Directory-based binding categories
- Automated synchronization workflow for repositories
- Pre-commit hook support
- YAML front-matter and legacy format support
