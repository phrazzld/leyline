# Leyline

Tenets & Bindings for consistent development standards across repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing
development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation
  guidance

For example, the [simplicity](docs/tenets/simplicity.md) tenet establishes the principle
that we should "prefer the simplest design that works," while the
[no-any](docs/bindings/categories/typescript/no-any.md) binding is a specific, enforceable rule derived
from that tenet.

## Repository Structure

```
docs/tenets/                     # Foundational principles (immutable truths)
docs/bindings/                   # Enforceable rules (derived from tenets)
  ├── core/                      # Bindings that apply to all contexts
  └── categories/                # Category-specific bindings
      ├── typescript/            # TypeScript-specific bindings
      ├── go/                    # Go-specific bindings
      ├── rust/                  # Rust-specific bindings
      └── frontend/              # Frontend-specific bindings
tools/                           # Validation and maintenance scripts
.github/                         # Automation workflows
```

## How It Works

### The Warden System

The Leyline Warden is an automated system that synchronizes tenets and bindings across
repositories:

1. When a new version of Leyline is tagged (e.g., `v0.1.0`)
1. Warden creates pull requests in all target repositories
1. Each PR updates the local copies of tenets and bindings
1. This ensures consistent standards across all codebases

### Integration

### Migrating from Symlinks

**Are you using symlinked philosophy documents?** See the
[Migration Guide](docs/migration-guide.md) for a simple 5-step process to switch to
Leyline.

### New Repository Integration

To integrate a new repository with Leyline:

1. Add this repository as a GitHub Actions workflow caller:

```yaml
# .github/workflows/vendor-docs.yml
name: Leyline Sync
on:
  pull_request:
  push:
jobs:
  docs:
    uses: phrazzld/leyline/.github/workflows/vendor.yml@v0.1.0
    with:
      ref: v0.1.0
      categories: "typescript,frontend"  # Specify categories relevant to your project
```

2. The first time the workflow runs, it will create `/docs/tenets` and `/docs/bindings`
   directories in your repository.

For complete integration examples, including pre-commit hooks and Renovate
configurations, see the [examples directory](examples/). These examples provide
templates and best practices for maintaining synchronized copies of tenets and bindings.

### Language-Specific Integration

To ensure repositories only receive relevant bindings (e.g., TypeScript projects don't
pull Go bindings), Leyline provides category-specific integration options:

- Bindings are organized in category-specific directories for easy filtering
- You can specify which categories to sync using the `categories` parameter
- The
  [language-specific workflow example](examples/github-workflows/language-specific-sync.yml)
  detects repository languages and syncs only relevant binding categories
- See the [implementation guide](docs/implementation-guide.md) for detailed instructions
  on category-specific integration

## Contributing

We welcome contributions to both tenets and bindings:

1. **For tenets**: Focus on fundamental principles that stand the test of time
1. **For bindings**: Create specific, enforceable rules that implement tenets

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines on proposing
changes.

## Examples

Here are some example tenets and their derived bindings:

- **[Simplicity](docs/tenets/simplicity.md)** →
  [hex-domain-purity](docs/bindings/core/hex-domain-purity.md),
  [no-any](docs/bindings/categories/typescript/no-any.md)
- **[Automation](docs/tenets/automation.md)** →
  [error-wrapping](docs/bindings/categories/go/error-wrapping.md),
  [require-conventional-commits](docs/bindings/core/require-conventional-commits.md)
- **[Testability](docs/tenets/testability.md)** →
  [no-internal-mocking](docs/bindings/core/no-internal-mocking.md)

## Documentation

Browse through the tenets and bindings sections for a complete listing of all available
standards.
