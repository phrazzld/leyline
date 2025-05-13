# Binding Metadata Schema

This document outlines the metadata schema for binding files and explains the directory-based approach to categorization.

## Directory-Based Categorization

Binding applicability is now determined by its location within the directory structure:

```
docs/bindings/
  ├── core/                # Core bindings (applicable to all projects)
  └── categories/          # Category-specific bindings
      ├── go/              # Go-specific bindings
      ├── rust/            # Rust-specific bindings
      ├── typescript/      # TypeScript-specific bindings
      ├── cli/             # CLI-specific bindings
      ├── frontend/        # Frontend-specific bindings
      └── backend/         # Backend-specific bindings
```

### Categorization Guidelines

When creating a new binding:

1. **Core Bindings**: Place in `docs/bindings/core/` if the binding:
   - Applies to all projects regardless of language or context
   - Represents a fundamental principle that transcends specific languages or environments
   - Can be described in language-agnostic terms

2. **Category-Specific Bindings**: Place in `docs/bindings/categories/<category>/` if the binding:
   - Applies primarily to a specific programming language or context
   - Uses language-specific syntax or features
   - Addresses concerns specific to a particular category

### Cross-Cutting Bindings Strategy

For bindings that apply to multiple categories:
- Identify the primary category where the binding is most relevant
- Place the binding in that primary category directory
- In the binding document, clearly explain its applicability to other categories

## Required Metadata

Every binding must include the following front-matter:

```yaml
---
id: unique-binding-id
last_modified: "YYYY-MM-DD"
derived_from: tenet-id
enforced_by: description of enforcement mechanism
---
```

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique identifier for the binding. Should match filename without extension. | `no-any` |
| `last_modified` | Date of last modification in ISO format. | `"2025-05-02"` |
| `derived_from` | ID of the tenet this binding implements. | `simplicity` |
| `enforced_by` | Description of how this binding is enforced. | `eslint("@typescript-eslint/no-explicit-any")` |

## Filename Conventions

Binding filenames should follow this pattern:

```
[binding-name].md
```

- Use descriptive, kebab-case names without language prefixes
- The `id` in the front-matter should match the filename (without the `.md` extension)
- For example, use `no-any.md` instead of `ts-no-any.md`

## Examples

### Core Binding:

```yaml
---
id: require-conventional-commits
last_modified: "2025-05-02"
derived_from: automation
enforced_by: commitlint
---
```

*Location: `/docs/bindings/core/require-conventional-commits.md`*

### Category-Specific Binding:

```yaml
---
id: no-any
last_modified: "2025-05-02"
derived_from: simplicity
enforced_by: eslint("@typescript-eslint/no-explicit-any")
---
```

*Location: `/docs/bindings/categories/typescript/no-any.md`*

### Cross-Cutting Binding (placed in primary category):

```yaml
---
id: error-wrapping
last_modified: "2025-05-02"
derived_from: modularity
enforced_by: linter and code review
---
```

*Location: `/docs/bindings/categories/go/error-wrapping.md`*
*Note: This file should contain explanation that while primarily for Go, the principles may be relevant to other languages.*

## Validation

The `tools/validate_front_matter.rb` script will validate:

- All required fields are present
- The `id` field matches the filename (without the `.md` extension)
- The location of the binding file matches the new directory structure
- The script will issue warnings for files found directly in `docs/bindings/` that don't follow the new structure
