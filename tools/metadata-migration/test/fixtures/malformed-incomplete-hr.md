______________________________________________________________________

id: incomplete-metadata derived_from: testability enforced_by: code review

# Tenet: This Has Incomplete Metadata

The metadata section above is missing its closing horizontal rule delimiter.
This should be detected as malformed metadata.

## Content Section

The parser should handle this gracefully and report it as malformed rather than
crashing or misinterpreting the content.
