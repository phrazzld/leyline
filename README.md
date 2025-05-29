# Leyline

Tenets & Bindings for consistent development standards across repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing
development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation
  guidance

For example, the [simplicity](./docs/tenets/simplicity.md) tenet establishes the
principle that we should "prefer the simplest design that works," while the
[no-any](./docs/bindings/categories/typescript/no-any.md) binding is a specific, enforceable rule
derived from that tenet.

## Repository Structure

```
docs/
  ├── tenets/                     # Foundational principles (immutable truths)
  ├── bindings/                   # Enforceable rules (derived from tenets)
  │   ├── core/                   # Core bindings applicable to all projects
  │   └── categories/             # Category-specific bindings
  │       ├── go/                 # Go language bindings
  │       ├── rust/               # Rust language bindings
  │       ├── typescript/         # TypeScript language bindings
  │       ├── cli/                # CLI application bindings
  │       ├── frontend/           # Frontend application bindings
  │       └── backend/            # Backend application bindings
  ├── announcements/              # Important announcements for contributors
  ├── data/                       # Data files for the project
  └── templates/                  # Templates for creating new tenets and bindings
tools/                            # Validation and maintenance scripts
archive/                          # Archived tools and documentation
.github/                          # Automation workflows
```

## How It Works

### Leyline Philosophy: The Warden System

The Warden System represents Leyline's philosophy of standardized development principles.
It's not an automated push mechanism, but rather a structured approach to maintaining
consistent tenets (foundational principles) and bindings (enforceable rules) that teams
can adopt on their own schedule through consumer-initiated synchronization.

### Integration: Pull-Based Content Sync

Leyline uses a consumer-initiated pull model. You control when and what to sync from Leyline
into your repository using our reusable GitHub Actions workflow.

### Migrating from Symlinks

**Are you using symlinked philosophy documents?** See the
[Migration Guide](./docs/migration-guide.md) for a simple 5-step process to switch to
Leyline.

### New Repository Integration

To integrate Leyline into your repository:

1. Create a workflow that calls our reusable sync workflow:

```yaml
# .github/workflows/sync-leyline.yml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays
  workflow_dispatch:  # Allow manual triggers

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0  # Pin to a specific Leyline version
      categories: go,typescript  # Optional: only sync specific categories
      target_path: docs/leyline  # Optional: customize target directory
      create_pr: true  # Optional: create a PR instead of direct commit
```

2. The workflow will:
   - Pull the specified version of Leyline content
   - Copy tenets, core bindings, and requested category bindings
   - Create a pull request with the changes (or commit directly)

3. Review and merge the PR to adopt the standards

**For detailed integration instructions**, see the [Integration Guide](./docs/integration/pull-model-guide.md).

**For versioning best practices**, see the [Versioning Guide](./docs/integration/versioning-guide.md).

For complete integration examples, including pre-commit hooks and Renovate
configurations, see the [examples directory](./examples/). These examples provide
templates and best practices for maintaining synchronized copies of tenets and bindings.

### Category-Specific Integration

To ensure repositories only receive relevant bindings (e.g., TypeScript projects don't
pull Go bindings), Leyline provides category-specific integration options:

- Binding files are organized by category directories (e.g., `categories/typescript/`, `categories/go/`) for clean organization
- Use the `categories` input parameter to specify which categories to sync:
  ```yaml
  with:
    ref: master
    categories: go,typescript,frontend
  ```
- The workflow will always sync core bindings (applicable to all projects) and tenets, along with the categories you specify
- See the [implementation guide](./docs/implementation-guide.md) for detailed
  instructions on category-specific integration

## Contributing

We welcome contributions to both tenets and bindings:

1. **For tenets**: Focus on fundamental principles that stand the test of time
1. **For bindings**: Create specific, enforceable rules that implement tenets

See [CONTRIBUTING.md](./docs/CONTRIBUTING.md) for detailed guidelines on proposing
changes.

## Examples

Here are some example tenets and their derived bindings:

- **[Simplicity](./docs/tenets/simplicity.md)** →
  [hex-domain-purity](./docs/bindings/core/hex-domain-purity.md),
  [no-any](./docs/bindings/categories/typescript/no-any.md)
- **[Automation](./docs/tenets/automation.md)** →
  [error-wrapping](./docs/bindings/categories/go/error-wrapping.md),
  [require-conventional-commits](./docs/bindings/core/require-conventional-commits.md)
- **[Testability](./docs/tenets/testability.md)** →
  [no-internal-mocking](./docs/bindings/core/no-internal-mocking.md)

## Documentation

Browse through the tenets and bindings directories in this repository for the complete
documentation. Note that the site URL will change when the project is fully deployed.
