# Tenet Formatting Standard

## Front-Matter Format

For all tenet and binding documents, we use a consistent front-matter format at the beginning of the file to store metadata:

```markdown
______________________________________________________________________

## id: tenet-id last_modified: "YYYY-MM-DD"
```

Where:
- The horizontal rule provides clear visual separation
- The metadata is in a level-2 heading
- `tenet-id` is a kebab-case identifier
- The date is in ISO format (YYYY-MM-DD)

## Rationale

This front-matter format was chosen for:

1. **Consistency**: All tenet files use this standard format
2. **Clear Visual Separation**: The horizontal rule clearly separates metadata from content
3. **Compatibility**: Works with our existing tooling and validation
4. **Visibility**: Makes metadata visible when rendered as markdown

## Tooling

Our toolchain is configured to work with this format:

1. **Validation**: `validate_front_matter.rb` verifies front-matter format and required fields
2. **Indexing**: `reindex.rb` extracts front-matter to build index files
3. **Formatting**: Our markdown formatting tools preserve this front-matter format

## Implementation

When creating or updating tenet files:

1. Always include the required front-matter fields (id, last_modified)
2. Keep the format consistent exactly as shown above
3. Use the exact number of underscores in the horizontal rule
4. Maintain the level-2 heading format for metadata

For any issues with the front-matter format:
- Check existing files for reference examples
- Run validation tools to verify format
- Manually verify front-matter after automated formatting
