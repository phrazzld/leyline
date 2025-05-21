# Important Announcement: Migration to YAML-Only Metadata Format

## Summary

**Effective immediately**, Leyline now exclusively supports **YAML front-matter** for all tenet and binding metadata. The legacy horizontal rule format has been removed from all validation tools, indexing tools, and documentation.

## What Changed

- All tenet and binding files must now use YAML front-matter format
- All validation and indexing tools now enforce YAML-only format
- Pre-commit hooks and CI workflows now enforce YAML-only metadata
- Legacy horizontal rule format is no longer supported
- All documentation has been updated to reflect this change

## Why We Made This Change

The standardization to YAML-only front-matter offers several key benefits:

1. **Industry Standard**: YAML front-matter is widely used in static site generators and documentation systems
2. **Tool Compatibility**: Better integration with validation, indexing, and documentation generation tools
3. **Clear Structure**: Provides a visually distinct section for metadata that's separate from content
4. **Machine Readability**: Easier to parse and process with automated tools
5. **Reduced Complexity**: Simplified tooling by eliminating dual-format support
6. **Consistency**: All files now follow the same format convention

## Impact on Contributors

### What You Need to Do

If you're working with Leyline files:

1. Ensure any new tenet or binding files use YAML front-matter
2. Update your local workflows or tools to handle YAML format exclusively
3. If you have any custom scripts that parse tenet/binding files, update them to handle YAML-only format

### YAML Front-Matter Format

All tenet and binding files must follow this format:

```markdown
---
id: example-id
last_modified: '2025-05-21'
# Additional fields for bindings
derived_from: parent-tenet  # For bindings only
enforced_by: description    # For bindings only
---

# Document Title

Document content here...
```

See [TENET_FORMATTING.md](TENET_FORMATTING.md) for complete format requirements.

## Tools and Validation

The following tools have been updated to enforce YAML-only validation:

- `validate_front_matter.rb` - Now enforces YAML front-matter in all files
- `reindex.rb` - Now processes only YAML front-matter metadata
- CI workflows and pre-commit hooks - Now enforce YAML-only format

## Questions or Issues?

If you encounter any issues with this change or have questions about the YAML format:

1. Refer to [TENET_FORMATTING.md](TENET_FORMATTING.md) for format documentation
2. Open an issue on the repository with the label "metadata-format"
3. Contact the maintainers through the usual support channels

We appreciate your understanding and cooperation as we standardize our metadata format to improve the overall quality and maintainability of the Leyline project.
