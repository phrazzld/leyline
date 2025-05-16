______________________________________________________________________
id: crlf-test last_modified: '2025-01-15'
______________________________________________________________________

# Tenet: Windows Line Endings Test

This file uses CRLF line endings (Windows style) instead of LF (Unix style).
The parser should handle both line ending types correctly and preserve them
in the output.

## Purpose

Tests that the migration tool correctly handles different line ending types:
- LF (\n) - Unix/Linux/Mac
- CRLF (\r\n) - Windows
- CR (\r) - Old Mac (rare)

The tool should preserve the original line ending type in the migrated file.
