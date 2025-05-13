# Tenet and Binding Front-Matter Standard

## Introduction

Front-matter is the metadata section at the beginning of Markdown files that provides
structured information about the document. In this project, we use YAML front-matter as
the standard format for all tenet and binding documents.

This document establishes YAML front-matter as the official standard, replacing the
older horizontal rule format that used underscores and bold text. The YAML format
provides better tool integration, clearer structure, and improved maintainability.

## Front-Matter Format

For all tenet and binding documents, you must use YAML front-matter at the beginning of
the file:

```markdown
---
id: tenet-id
last_modified: '2025-05-08'
---
```

The format consists of:

- Triple dashes (`---`) to delimit the YAML front-matter block
- Key-value pairs in YAML syntax
- A closing triple dash line

All front-matter must be at the very beginning of the file with no preceding whitespace
or other content.

## Required Fields

Different document types require different metadata fields. Below are the mandatory
fields for each type.

### For Tenets

- **id**: Unique identifier in kebab-case (e.g., `document-decisions`,
  `no-secret-suppression`)

  - Must be unique across all documents
  - Should match the filename (without the `.md` extension)
  - Use lowercase letters, numbers, and hyphens only

- **last_modified**: Date of last modification in ISO format (YYYY-MM-DD)

  - Must be enclosed in quotes (e.g., `'2025-05-08'`)
  - Use the current date when creating or updating documents

### For Bindings

- **id**: Unique identifier in kebab-case

  - Same rules as tenet IDs
  - Should indicate the specific rule or requirement

- **last_modified**: Date of last modification in ISO format (YYYY-MM-DD)

  - Same format as tenet dates

- **derived_from**: The tenet this binding implements

  - Must match an existing tenet ID
  - Creates a linkage between bindings and their parent tenets

- **enforced_by**: Description of how this binding is enforced

  - Examples: "Linter rules", "Code review", "CI checks"

### Deprecated Fields

- **applies_to**: This field is now deprecated
  - Binding applicability is now determined by directory location
  - Core bindings (applicable to all) go in `docs/bindings/core/`
  - Category-specific bindings go in `docs/bindings/categories/<category>/`
  - See [binding-metadata.md](docs/binding-metadata.md) for more details

## Examples with Comments

### Tenet Front-Matter Example

```markdown
---
# Unique identifier matching the filename
id: modularity
# Last modified date in ISO format with quotes
last_modified: '2025-05-08'
---

# Tenet: Modularity

The tenet content begins here...
```

### Binding Front-Matter Example

```markdown
---
# Unique identifier for this binding (must match filename without .md)
id: automate-changelog
# Last modified date with quotes
last_modified: '2025-05-08'
# The parent tenet for this binding
derived_from: automation
# How this binding is enforced
enforced_by: CI checks & pre-release hooks
---

# Binding: Automate Changelog Generation

The binding content begins here...
```

Note: This binding would be saved as `docs/bindings/core/automate-changelog.md` since it applies to all projects.

## Converting from Horizontal Rule Format

If you encounter documents using the older horizontal rule format:

```markdown
______________________________________________________________________

id: old-format last_modified: "2025-05-05" derived_from: some-tenet
enforced_by: code review applies_to:

- typescript
- frontend

______________________________________________________________________

# Document title
```

You should convert them to the YAML format as follows:

```markdown
---
id: old-format
last_modified: '2025-05-05'
derived_from: some-tenet
enforced_by: code review
---

# Document title
```

Note: After converting, move the file to the appropriate directory based on its applicability:
- If it's a core binding: `docs/bindings/core/`
- If it's category-specific: `docs/bindings/categories/<category>/`
  (e.g., `docs/bindings/categories/typescript/` in this example)

Note the key differences:

- Each field is on a separate line
- Values are properly indented under their keys
- Dates are enclosed in quotes
- No horizontal rules with underscores

## Rationale

YAML front-matter has been chosen as our standard for several reasons:

1. **Industry Standard**: YAML front-matter is widely used in static site generators and
   documentation systems
1. **Tool Compatibility**: Integrates well with our validation, indexing, and
   documentation generation tools
1. **Clear Structure**: Provides a visually distinct section for metadata that's
   separate from content
1. **Machine Readability**: Easier to parse and process with automated tools
1. **Extensibility**: Allows easy addition of new metadata fields as project needs
   evolve

## Validation

### Validation Tool

Our validation tool (`tools/validate_front_matter.rb`) checks for front-matter
compliance:

```bash
# Normal mode - warns about non-YAML format files
ruby tools/validate_front_matter.rb

# Strict mode - enforces YAML format only
ruby tools/validate_front_matter.rb --strict
```

The validator checks:

1. Presence of YAML front-matter enclosed by triple dashes
1. All required fields for the document type (tenet or binding)
1. Valid date format for `last_modified`
1. Unique `id` across all documents
1. Valid `derived_from` references for bindings (must reference an existing tenet)
1. Correct format for `applies_to` arrays

### Pre-commit Hooks

Our pre-commit configuration includes hooks to validate and preserve front-matter:

1. **mdformat** with the **mdformat-frontmatter** plugin preserves YAML front-matter
   during Markdown formatting
1. Custom validation hooks ensure all required metadata is present

## Common Issues and Solutions

### Issue: "No front-matter found"

**Solution**: Ensure your document starts with `---`, followed by YAML properties,
followed by another `---`

### Issue: "Using deprecated horizontal rule format for metadata"

**Solution**: Convert to YAML front-matter format as described in the "Converting"
section above

### Issue: "Missing required keys in YAML front-matter"

**Solution**: Add all required fields for your document type (see Required Fields
section)

### Issue: "Invalid date format in 'last_modified' field"

**Solution**: Ensure dates are in ISO format (YYYY-MM-DD) and enclosed in quotes (e.g.,
`'2025-05-08'`)

### Issue: "File in incorrect directory or missing applies_to field"

**Solution**:
- The `applies_to` field is deprecated
- Move the binding file to the appropriate directory:
  - Core bindings go in `docs/bindings/core/`
  - Category-specific bindings go in `docs/bindings/categories/<category>/`

### Issue: "Invalid YAML in front-matter"

**Solution**: Verify YAML syntax, especially:

- Proper indentation for nested properties
- Quotes around values with special characters
- No tabs (use spaces for indentation)
- No trailing commas

### Issue: "Front-matter is converted after formatting"

**Solution**: Ensure your `.mdformat.toml` and `.pre-commit-config.yaml` files include
proper configuration for preserving front-matter

## Command-Line Tools

These tools help manage and validate front-matter:

1. **Validation tool**: Check front-matter format and required fields

   ```bash
   ruby tools/validate_front_matter.rb
   ```

1. **Reindexing tool**: Generate indexes based on front-matter

   ```bash
   ruby tools/reindex.rb
   ```

1. **Markdown formatter with front-matter preservation**:

   ```bash
   mdformat --wrap 88 path/to/file.md
   ```

## Implementation Recommendations

When creating or updating tenet/binding files:

1. Always begin with proper YAML front-matter including all required fields
1. Keep the front-matter concise and focused on metadata only
1. Run validation tools to verify format before committing
1. Do not add custom front-matter fields without discussion
1. Maintain consistent YAML formatting across all documents
1. When in doubt, refer to existing documents for examples

## Tooling Integration

Our toolchain is fully configured to work with YAML front-matter:

1. **Validation**: `validate_front_matter.rb` verifies front-matter format and required
   fields
1. **Indexing**: `reindex.rb` extracts front-matter and first paragraphs to build index
   files
1. **Formatting**: `mdformat` with the frontmatter plugin preserves front-matter during
   formatting
1. **Pre-commit hooks**: Validate and preserve front-matter during the commit process
1. **Templates**: Template files include the correct front-matter structure to follow

## Further Resources

- [YAML Specification](https://yaml.org/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/) - A popular
  implementation of front-matter
- [MkDocs Meta-Data](https://www.mkdocs.org/user-guide/writing-your-docs/#meta-data) -
  How MkDocs uses front-matter
