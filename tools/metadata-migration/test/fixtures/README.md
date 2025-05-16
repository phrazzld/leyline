# Test Fixtures

This directory contains test fixtures for the metadata migration script. Each file represents a specific test case:

## Legacy Format Files
- `legacy-basic-tenet.md` - Basic tenet with legacy horizontal rule format
- `legacy-basic-binding.md` - Basic binding with legacy horizontal rule format
- `legacy-with-applies-to.md` - Includes deprecated `appliesTo` field
- `legacy-multiline-values.md` - Tests multiline metadata values
- `legacy-special-chars.md` - Tests special characters in metadata

## YAML Front-matter Files
- `yaml-basic-tenet.md` - Already properly formatted tenet
- `yaml-basic-binding.md` - Already properly formatted binding
- `yaml-with-quoted-dates.md` - Dates in single quotes

## No Metadata Files
- `no-metadata-plain.md` - Simple markdown file without metadata
- `no-metadata-with-headers.md` - Markdown with headers but no metadata

## Malformed Metadata Files
- `malformed-incomplete-hr.md` - Missing closing horizontal rule
- `malformed-invalid-yaml.md` - Invalid YAML syntax
- `malformed-mixed-format.md` - Mix of YAML and legacy formats
- `malformed-missing-required.md` - Missing required `id` field

## Edge Cases
- `edge-crlf-endings.md` - Windows line endings (CRLF)
- `edge-unicode-content.md` - Unicode characters in metadata and content
- `edge-empty-file.md` - Empty file
- `edge-very-long-metadata.md` - Extremely long metadata values

These fixtures are used to test the robustness and correctness of the metadata migration tool.
