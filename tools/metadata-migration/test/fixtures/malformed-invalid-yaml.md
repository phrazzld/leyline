---
id: invalid-yaml
last_modified: this is not a valid date
derived_from; missing-colon
- invalid yaml array item
unwrapped: string value without quotes that has: colons
---

# Binding: This Has Invalid YAML

The YAML front-matter above contains multiple syntax errors:
- Invalid date format
- Missing colon after key
- Improper array syntax
- Unquoted string with special characters

## Purpose

This fixture tests the parser's ability to handle malformed YAML gracefully and
provide helpful error messages rather than crashing.
