# Leyline

Tenets & Bindings for consistent development standards across repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing
development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation
  guidance

For example, the [simplicity](tenets/simplicity.md) tenet establishes the principle that
we should "prefer the simplest design that works," while the
[no-any](bindings/categories/typescript/no-any.md) binding is a specific, enforceable rule derived from
that tenet.

## Repository Structure

```
tenets/                        # Foundational principles (immutable truths)
bindings/                      # Enforceable rules (derived from tenets)
  ├── core/                    # Core bindings applicable to all projects
  └── categories/              # Category-specific bindings
      ├── go/                  # Go language bindings
      ├── rust/                # Rust language bindings
      ├── typescript/          # TypeScript language bindings
      ├── cli/                 # CLI application bindings
      ├── frontend/            # Frontend application bindings
      └── backend/             # Backend application bindings
tools/                         # Validation and maintenance scripts
.github/                       # Automation workflows
```

## How It Works

### The Warden System: Philosophy vs Implementation

The Warden System represents Leyline's core philosophy of maintaining standardized development
principles across projects. It's important to understand that this is not an automated push
system, but rather a conceptual framework:

- **Philosophy**: The Warden System embodies the idea that development standards should be
  consistent, versioned, and enforceable across all projects in an organization
- **Implementation**: Consumer repositories pull Leyline content on their own schedule using
  the `sync-leyline-content.yml` reusable workflow
- **Control**: Teams maintain full control over when and how they adopt updates
- **Flexibility**: Selective synchronization allows teams to adopt only relevant standards

### Integration: Pull-Based Content Synchronization

Leyline uses a consumer-initiated pull model for content distribution. This approach provides
maximum flexibility and control over when and how your projects adopt Leyline standards.

#### Quick Start

Create a workflow in your repository that calls Leyline's reusable sync workflow:

```yaml
# .github/workflows/sync-leyline.yml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly check for updates
  workflow_dispatch:      # Manual trigger option

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0  # Pin to specific version
      categories: go,typescript,frontend  # Optional: sync only what you need
```

#### Workflow Inputs

The `sync-leyline-content.yml` workflow accepts these inputs:

**Required:**
- `token`: GitHub token with repo write permissions
- `leyline_ref`: Version/tag/branch of Leyline to sync from

**Optional:**
- `categories`: Comma-separated list of category bindings to sync
  - Available: `go`, `rust`, `typescript`, `frontend`, `backend`
  - Default: none (only core bindings synced)
- `target_path`: Where to place synced content (default: `docs/leyline`)
- `create_pr`: Create PR instead of direct commit (default: `true`)
- `commit_message`: Custom commit message
- `pr_title`: Custom PR title
- `pr_branch_name`: Custom branch name for PR

#### Workflow Outputs

- `pr_url`: URL of created pull request (if applicable)
- `commit_sha`: SHA of the commit with synced content

#### Integration Guides

- **[Pull Model Integration Guide](integration/pull-model-guide.md)**: Step-by-step setup instructions,
  troubleshooting, and best practices for consumer repositories
- **[Versioning Guide](integration/versioning-guide.md)**: How to manage Leyline versions,
  set up automated updates with Dependabot/Renovate, and version pinning strategies
- **[Migration Guide](migration-guide.md)**: For teams moving from symlinks or other
  legacy integration methods

#### Benefits of Pull-Based Sync

1. **Version Control**: Pin to specific Leyline versions for stability
2. **Selective Adoption**: Sync only the categories relevant to your project
3. **Review Process**: Changes arrive as PRs for team review
4. **Automation Ready**: Integrate with existing CI/CD pipelines
5. **No Surprises**: Updates only when you explicitly request them

## Contributing

We welcome contributions to both tenets and bindings:

1. **For tenets**: Focus on fundamental principles that stand the test of time
1. **For bindings**: Create specific, enforceable rules that implement tenets

See the [Contributing](CONTRIBUTING.md) section for detailed guidelines on proposing
changes.

## Examples

Here are some example tenets and their derived bindings:

- **[Simplicity](tenets/simplicity.md)** →
  [hex-domain-purity](bindings/core/hex-domain-purity.md),
  [no-any](bindings/categories/typescript/no-any.md)
- **[Automation](tenets/automation.md)** →
  [error-wrapping](bindings/categories/go/error-wrapping.md),
  [require-conventional-commits](bindings/core/require-conventional-commits.md)
- **[Testability](tenets/testability.md)** →
  [no-internal-mocking](bindings/core/no-internal-mocking.md)

## Documentation

Browse through the tenets and bindings sections for a complete listing of all available
standards.
