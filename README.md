# Leyline

Tenets & Bindings for consistent development standards across all repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

## Architecture

```
tenets/       # Foundational principles (immutable truths)
bindings/     # Enforceable rules (derived from tenets)
tools/        # Validation and maintenance scripts
.github/      # Automation workflows
```

## The Warden

The Leyline Warden is an automated system that synchronizes tenets and bindings across all consuming repositories. When a new version of Leyline is tagged, the Warden:

1. Creates pull requests in all target repositories
2. Updates their local copies of tenets and bindings
3. Ensures consistency across the entire codebase ecosystem

## Integration

To integrate a repository with Leyline, add a `.github/workflows/vendor-docs.yml` file with:

```yaml
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

## Governance

- Changes to tenets require approval from at least 2 core maintainers
- Changes to bindings require approval from at least 1 core maintainer
- Patch releases for typo fixes and clarifications auto-merge when CI passes

## Documentation

Visit the [static site](https://phrazzld.github.io/leyline/) for browsable documentation.