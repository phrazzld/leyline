# Tenet and Binding Metadata Formatting

## Introduction

Metadata is included at the beginning of Markdown files to provide structured information
about the document. This project exclusively uses YAML front-matter format for tenet and
binding documents, which provides a standardized, machine-readable way to define document
metadata.

YAML front-matter is an industry standard format that is widely used in static site
generators, documentation systems, and content management tools. It is essential for
our validation tools, indexing systems, and LLM integration.

## Metadata Format

All tenet and binding documents must use YAML front-matter at the beginning of the file:

```markdown
---
id: tenet-id
last_modified: '2025-05-08'
version: '0.2.0'
---

# Document Title
```

The YAML format consists of:
- Triple dashes (`---`) to delimit the block
- Key-value pairs in YAML syntax
- A closing triple dash line

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

- **version**: Repository version when this document was last modified

  - Must match the current VERSION file content (e.g., `'0.1.0'`)
  - Must be enclosed in quotes
  - Enables semantic versioning and breaking change detection

### For Bindings

- **id**: Unique identifier in kebab-case

  - Same rules as tenet IDs
  - Should indicate the specific rule or requirement

- **last_modified**: Date of last modification in ISO format (YYYY-MM-DD)

  - Same format as tenet dates

- **version**: Repository version when this document was last modified

  - Must match the current VERSION file content (e.g., `'0.1.0'`)
  - Must be enclosed in quotes
  - Same format and purpose as tenet version field

- **derived_from**: The tenet this binding implements

  - Must match an existing tenet ID
  - Creates a linkage between bindings and their parent tenets

- **enforced_by**: Description of how this binding is enforced

  - Examples: "Linter rules", "Code review", "CI checks"


## Examples with Comments

### Tenet Front-Matter Example

```markdown
---
# Unique identifier matching the filename
id: modularity
# Last modified date in ISO format with quotes
last_modified: '2025-05-08'
# Repository version when last modified
version: '0.2.0'
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
# Repository version when last modified
version: '0.2.0'
# The parent tenet for this binding
derived_from: automation
# How this binding is enforced
enforced_by: CI checks & pre-release hooks
---

# Binding: Automate Changelog Generation

The binding content begins here...
```

Note: This binding would be saved as `docs/bindings/core/automate-changelog.md` since it applies to all projects.

## File Location Standards

Binding files must be placed in the appropriate directory based on their applicability:

- `docs/bindings/core/` - For bindings that apply to all projects regardless of language or technology
- `docs/bindings/categories/<category>/` - For category-specific bindings

Valid categories include:
- `go`
- `rust`
- `typescript`
- `frontend`
- `backend`
- `cli`

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
# Validate all files
ruby tools/validate_front_matter.rb

# Validate a specific file
ruby tools/validate_front_matter.rb -f path/to/file.md

# Validate with detailed output
ruby tools/validate_front_matter.rb -v
```

The validator checks:

1. Presence of YAML front-matter enclosed by triple dashes
1. All required fields for the document type (tenet or binding)
1. Valid date format for `last_modified`
1. Unique `id` across all documents
1. Valid `derived_from` references for bindings (must reference an existing tenet)
1. Correct format for optional fields

### Pre-commit Hooks

Our pre-commit configuration includes hooks to validate front-matter:

1. Automatic validation of YAML front-matter in all markdown files
2. Blocking of commits that contain invalid front-matter

## Common Issues and Solutions

### Issue: "No front-matter found"

**Solution**: Ensure your document starts with `---`, followed by YAML properties,
followed by another `---`

### Issue: "Missing required keys in YAML front-matter"

**Solution**: Add all required fields for your document type (see Required Fields
section)

### Issue: "Invalid date format in 'last_modified' field"

**Solution**: Ensure dates are in ISO format (YYYY-MM-DD) and enclosed in quotes (e.g.,
`'2025-05-08'`)


### Issue: "Invalid YAML in front-matter"

**Solution**: Verify YAML syntax, especially:

- Proper indentation for nested properties
- Quotes around values with special characters
- No tabs (use spaces for indentation)
- No trailing commas

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
1. **Pre-commit hooks**: Validate front-matter during the commit process
1. **Templates**: Template files include the correct front-matter structure to follow

## Further Resources

- [YAML Specification](https://yaml.org/)
- [Jekyll Front Matter](https://jekyllrb.com/docs/front-matter/) - A popular
  implementation of front-matter
