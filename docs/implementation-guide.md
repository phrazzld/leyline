# Leyline Implementation Guide

## Language-Specific Integration

To ensure repositories only receive relevant bindings, Leyline uses a directory-based organizational approach:

### 1. Directory-Based Binding Organization

Bindings are organized in a hierarchical directory structure that makes filtering and syncing easier:

- Core bindings (applicable to all contexts) are stored in the `docs/bindings/core/` directory
- Category-specific bindings are stored in appropriate subdirectories under `docs/bindings/categories/`:
  - `docs/bindings/categories/typescript/` - TypeScript-specific bindings
  - `docs/bindings/categories/go/` - Go-specific bindings
  - `docs/bindings/categories/rust/` - Rust-specific bindings
  - `docs/bindings/categories/frontend/` - Frontend-specific bindings
  - etc.

This structure allows workflows to easily sync only the relevant categories of bindings for a specific repository.

### 2. Using Category-Specific Workflows

The example workflow in `examples/github-workflows/vendor.yml` demonstrates how to:

1. Specify which binding categories to sync using the `categories` input parameter
2. Sync only the selected binding categories to the target repository
3. Always sync core bindings that apply to all projects
4. Clean up any old bindings that no longer exist in the source

This approach ensures that a TypeScript project doesn't receive Go-specific bindings,
while still receiving all relevant tenets and core bindings.

### 3. Cross-Cutting Bindings

Some bindings might apply to multiple categories but not all repositories. For these:

1. Place the binding in the most appropriate category directory
2. When syncing, include all relevant categories in the `categories` parameter
3. In the binding, clearly document all the contexts where it applies

## Implementation for Binding Authors

When creating a new binding:

1. Place the binding in the appropriate directory:
   - `docs/bindings/core/` for universally applicable bindings
   - `docs/bindings/categories/<category>/` for category-specific bindings
2. Use a descriptive filename without language prefixes (e.g., `no-any.md` instead of `ts-no-any.md`)
3. Ensure the `id` in the front-matter matches the filename (without `.md`)
4. The directory structure itself defines the binding's applicability - no `applies_to` field is needed

By following these conventions, consumer repositories will only receive bindings
relevant to their context, making the integration more valuable and reducing noise.
