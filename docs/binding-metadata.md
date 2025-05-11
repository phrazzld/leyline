# Binding Metadata Schema

This document outlines the metadata schema for binding files, including the new
`applies_to` field for language and context filtering.

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

| Field | Description | Example | |-------|-------------|---------| | `id` | Unique
identifier for the binding. Should match filename. | `ts-no-any` | | `last_modified` |
Date of last modification in ISO format. | `"2025-05-02"` | | `derived_from` | ID of the
tenet this binding implements. | `simplicity` | | `enforced_by` | Description of how
this binding is enforced. | `eslint("no-explicit-any")` |

## Language and Context Applicability

To support automatic filtering based on repository language and context, bindings should
include the `applies_to` field:

```yaml
---
id: ts-no-any
last_modified: "2025-05-02"
derived_from: simplicity
enforced_by: eslint("no-explicit-any")
applies_to:
  - typescript
  - frontend
  - backend
---
```

### Valid `applies_to` Values

#### Languages

- `typescript`
- `javascript`
- `go`
- `rust`
- `python`
- `java`
- `csharp`
- `ruby`

#### Environments/Contexts

- `frontend`
- `backend`
- `mobile`
- `desktop`
- `cli`
- `library`
- `service`

#### Special Values

- `all` - Indicates the binding applies to all contexts/languages

### Naming Convention and Auto-detection

Binding filenames should follow this pattern:

```
[language-prefix]-[binding-name].md
```

The language prefix should correspond to the appropriate language in `applies_to`:

| Prefix | Language | |--------|----------| | `ts-` | typescript | | `js-` | javascript
| | `go-` | go | | `rust-` | rust | | `py-` | python | | `java-` | java | | `cs-` |
csharp | | `rb-` | ruby |

For language-agnostic bindings, omit the language prefix and include `all` in the
`applies_to` array.

### Examples

#### TypeScript-specific binding:

```yaml
---
id: ts-no-any
last_modified: "2025-05-02"
derived_from: simplicity
enforced_by: eslint("@typescript-eslint/no-explicit-any")
applies_to:
  - typescript
---
```

#### Language-agnostic binding:

```yaml
---
id: require-conventional-commits
last_modified: "2025-05-02"
derived_from: automation
enforced_by: commitlint
applies_to:
  - all
---
```

#### Multi-language binding:

```yaml
---
id: no-internal-mocking
last_modified: "2025-05-02"
derived_from: testability
enforced_by: code review
applies_to:
  - typescript
  - javascript
  - go
  - python
  - java
---
```

## Validation

The `tools/validate_front_matter.rb` script will validate:

- All required fields are present
- The `applies_to` field contains an array of strings
- The values in `applies_to` are from the list of valid contexts
- For bindings with language-specific prefixes, a warning is displayed if the
  corresponding language is not in `applies_to`
