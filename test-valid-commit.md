---
id: test-valid-commit
last_modified: '2025-06-05'
---

# Test: Valid Commit

This is a test file with valid YAML front-matter to verify that the pre-commit hook allows good commits to pass.

The file has:
- Valid YAML syntax
- Required `id` field
- Required `last_modified` field in correct format
- Unique ID that doesn't conflict with existing files

This test validates that our validation system works correctly for both error detection and acceptance of valid content.
