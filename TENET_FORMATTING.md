# Tenet Formatting Standard

## Front-Matter Format

For all tenet and binding documents, we use YAML front-matter at the beginning of the file to store metadata:

```markdown
---
id: tenet-id
last_modified: '2025-05-08'
---
```

Where:
- Triple dashes (`---`) delimit the YAML front-matter
- `id` is a kebab-case identifier (required)
- `last_modified` is a date in ISO format (YYYY-MM-DD) (required)
- For bindings, `derived_from` and `enforced_by` are also required fields
- For bindings, `applies_to` is an optional array of relevant contexts

## Required Fields

### For Tenets
- **id**: Unique identifier in kebab-case (e.g., `document-decisions`, `no-secret-suppression`)
- **last_modified**: Date of last modification in ISO format (YYYY-MM-DD)

### For Bindings
- **id**: Unique identifier in kebab-case
- **last_modified**: Date of last modification in ISO format
- **derived_from**: The tenet this binding implements (must match an existing tenet id)
- **enforced_by**: Description of how this binding is enforced (e.g., "Linter rules", "Code review")
- **applies_to** (optional): Array of contexts where this binding applies (e.g., `["typescript", "frontend"]`)

## Examples

### Tenet Front-Matter Example
```markdown
---
id: modularity
last_modified: '2025-05-08'
---
```

### Binding Front-Matter Example
```markdown
---
id: automate-changelog
last_modified: '2025-05-08'
derived_from: automation
enforced_by: CI checks & pre-release hooks
applies_to:
  - all
---
```

## Rationale

This YAML front-matter format was chosen for:

1. **Industry Standard**: YAML front-matter is widely used in static site generators and documentation systems
2. **Tool Compatibility**: Works with our validation and indexing tools
3. **Clarity**: Makes metadata clearly separate from content
4. **Extensibility**: Easy to add new metadata fields when needed

## Validation

Our validation tool (`tools/validate_front_matter.rb`) checks:

1. Presence of YAML front-matter enclosed by triple dashes
2. All required fields for tenets and bindings
3. Valid date format for `last_modified`
4. Unique `id` across all documents
5. Valid `derived_from` references for bindings
6. Correct format for `applies_to` arrays

## Common Issues and Solutions

### Issue: "No front-matter found"
**Solution**: Ensure your document starts with `---`, followed by YAML properties, followed by another `---`

### Issue: "Missing required keys"
**Solution**: Check that your front-matter includes all required fields for the document type

### Issue: "Invalid date format"
**Solution**: Ensure dates are in ISO format (YYYY-MM-DD) and enclosed in quotes

### Issue: "Invalid YAML"
**Solution**: Verify YAML syntax, especially indentation for nested properties and quotes around values

## Implementation Notes

When creating or updating tenet/binding files:

1. Always include the required front-matter fields for the document type
2. Maintain consistent formatting with other documents
3. Run validation tools to verify format before committing
4. Do not add custom fields without discussion

## Tooling Integration

Our toolchain is configured to work with this format:

1. **Validation**: `validate_front_matter.rb` verifies front-matter format and required fields
2. **Indexing**: `reindex.rb` extracts front-matter and first paragraphs to build index files
3. **Templating**: Template files include the correct front-matter structure to follow
