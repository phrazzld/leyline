______________________________________________________________________

id: long-metadata-test description: This is an extremely long description field that goes on and on and on and contains many words and phrases that test the parser's ability to handle very long metadata values that might span multiple lines or contain special characters or repeated patterns of text that could potentially cause issues with memory allocation or buffer overflows in poorly written parsers but this migration tool should handle it gracefully without any problems whatsoever long_field: Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. another_field: This field also contains a substantial amount of text to ensure that the parser can handle multiple long fields in a single metadata section without any issues or performance degradation last_modified: '2025-01-15'

______________________________________________________________________

# Tenet: Very Long Metadata Values

This document tests the parser's ability to handle extremely long metadata values
that might challenge buffer limits or memory allocation strategies.

## Purpose

Some metadata fields in real documents can be quite long, especially description
fields or fields containing formatted text. The migration tool should handle these
cases without truncation or errors.

## Content

The content section is relatively short compared to the metadata, which is unusual
but valid.
