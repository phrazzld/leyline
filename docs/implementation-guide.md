# Leyline Implementation Guide

## Language-Specific Integration

To ensure repositories only receive relevant bindings, Leyline provides two approaches:

### 1. Front-matter Tags for Bindings

All bindings should include language/context tags in their front-matter. This allows
workflow scripts to filter bindings appropriately:

```yaml
---
id: ts-no-any
last_modified: 2025-05-05
derived_from: simplicity
enforced_by: eslint("no-explicit-any") & tsconfig("noImplicitAny")
applies_to:
  - typescript
  - javascript
---
```

The `applies_to` field can contain one or more of:

- Language identifiers: `typescript`, `go`, `rust`, etc.
- Context identifiers: `frontend`, `backend`, `cli`, `library`, etc.

### 2. Binding File Naming Conventions

Binding files should follow a consistent naming convention that makes filtering easier:

- Language-specific bindings should have a prefix: `ts-`, `go-`, `rust-`, etc.
- General bindings applicable to all contexts should have no language prefix

### 3. Using Language-Specific Workflows

The example workflow in `examples/github-workflows/language-specific-sync.yml`
demonstrates how to:

1. Detect languages used in a repository
1. Sync only the relevant bindings based on language detection
1. Always sync universal bindings that apply to all projects

This approach ensures that a TypeScript project doesn't receive Go-specific bindings,
while still receiving all relevant tenets and universal bindings.

## Implementation for Binding Authors

When creating a new binding:

1. Use the appropriate file name prefix for language-specific bindings
1. Include the `applies_to` field in the front-matter
1. Be explicit about which languages and contexts the binding applies to
1. For universal bindings, either omit the `applies_to` field or include `"all"`

By following these conventions, consumer repositories will only receive bindings
relevant to their context, making the integration more valuable and reducing noise.
