---
id: unknown-fields-test
last_modified: '2025-05-10'
derived_from: test-tenet
enforced_by: 'manual review'
version: '0.1.0'
# Unknown fields that shouldn't exist
deprecated_field: 'this should not be here'
applies_to: 'typescript'
custom_metadata: 'unknown field'
priority: 'high'
tags: ['test', 'unknown']
---

# Unknown Fields Test

This file contains several unknown fields that are not part of the schema:
- deprecated_field
- applies_to (this was removed from the schema)
- custom_metadata
- priority
- tags
