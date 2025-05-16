______________________________________________________________________

derived_from: simplicity enforced_by: code review

______________________________________________________________________

# Binding: Missing Required ID Field

This binding metadata is missing the required `id` field. The parser should detect
this as invalid metadata and handle it appropriately.

## Purpose

Tests the validation of required fields in metadata. The migration tool should
report this as an error since `id` is required for all documents.
