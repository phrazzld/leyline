# Release Notes

## v0.1.0 - Initial Release

This is the first stable release of Leyline, a system for centralizing development standards across repositories through tenets and bindings.

### Features

- **Core Structure**: Established tenets and bindings directory structure
- **Initial Tenets**: 
  - Simplicity - Prefer the simplest design that works
  - Testability - Structure code for easy verification
  - Maintainability - Code for humans first
  - Automation - Eliminate toil, ensure consistency
  - Modularity - Build small, focused components
  - Explicit over Implicit - Clarity trumps magic
  - Document Decisions - Explain the why, not the how
  - No Secret Suppression - Never hardcode secrets

- **Initial Bindings**:
  - ts-no-any - Forbid TypeScript 'any' type
  - hex-domain-purity - Keep domain logic free of infrastructure concerns
  - go-error-wrapping - Structure errors with context
  - require-conventional-commits - Enforce commit format standards
  - no-internal-mocking - Never mock internal collaborators
  - no-lint-suppression - Fix the root cause of linting issues

- **Tooling**:
  - Front-matter validation
  - Index generation
  - GitHub Actions workflows

- **Documentation**:
  - Browsable GitHub Pages site
  - Comprehensive README
  - Contributing guidelines
  - Maintenance documentation

### Setup & Integration

- Repository can now be tagged at v0.1.0
- Third-party repositories can integrate via GitHub Actions workflows
- See README.md for integration instructions

This release provides the foundation for consistent development standards that can be synced across multiple repositories through the Warden system.