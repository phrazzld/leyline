# Leyline

Tenets & Bindings for consistent development standards across repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

For example, the [simplicity](tenets/simplicity.md) tenet establishes the principle that we should "prefer the simplest design that works," while the [ts-no-any](bindings/ts-no-any.md) binding is a specific, enforceable rule derived from that tenet.

## Repository Structure

```
tenets/       # Foundational principles (immutable truths)
bindings/     # Enforceable rules (derived from tenets)
tools/        # Validation and maintenance scripts
.github/      # Automation workflows
```

## How It Works

### The Warden System

The Leyline Warden is an automated system that synchronizes tenets and bindings across repositories:

1. When a new version of Leyline is tagged (e.g., `v0.1.0`)
2. Warden creates pull requests in all target repositories
3. Each PR updates the local copies of tenets and bindings
4. This ensures consistent standards across all codebases

### Integration

To integrate a repository with Leyline:

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
```

2. The first time the workflow runs, it will create `/docs/tenets` and `/docs/bindings` directories in your repository.

## Contributing

We welcome contributions to both tenets and bindings:

1. **For tenets**: Focus on fundamental principles that stand the test of time
2. **For bindings**: Create specific, enforceable rules that implement tenets

See the [Contributing](CONTRIBUTING.md) section for detailed guidelines on proposing changes.

## Examples

Here are some example tenets and their derived bindings:

- **[Simplicity](tenets/simplicity.md)** → [hex-domain-purity](bindings/hex-domain-purity.md), [ts-no-any](bindings/ts-no-any.md)
- **[Automation](tenets/automation.md)** → [go-error-wrapping](bindings/go-error-wrapping.md), [require-conventional-commits](bindings/require-conventional-commits.md)
- **[Testability](tenets/testability.md)** → [no-internal-mocking](bindings/no-internal-mocking.md)

## Documentation

Browse through the tenets and bindings sections for a complete listing of all available standards.