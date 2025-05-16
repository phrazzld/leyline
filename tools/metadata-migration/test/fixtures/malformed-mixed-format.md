---
id: mixed-format
last_modified: '2025-01-15'
---

______________________________________________________________________

## This file mixes YAML and legacy formats above, which is invalid

# Tenet: Mixed Format Test

This file has both YAML front-matter and legacy horizontal rule metadata, which
should be detected as malformed. The parser needs to handle this case gracefully.

## Content

The migration tool should report this as an error case since mixing metadata
formats is not supported.
