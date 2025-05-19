#!/bin/bash
# Script to fix metadata format for files with lastModified on separate line

cd /Users/phaedrus/Development/leyline

# Files that need fixing based on the migration errors
files=(
    "docs/bindings/core/use-structured-logging.md"
    "docs/bindings/core/semantic-versioning.md"
    "docs/bindings/core/require-conventional-commits.md"
    "docs/bindings/core/no-lint-suppression.md"
    "docs/bindings/core/no-internal-mocking.md"
    "docs/bindings/core/immutable-by-default.md"
    "docs/bindings/core/dependency-management.md"
    "docs/bindings/core/dependency-inversion.md"
    "docs/bindings/core/context-propagation.md"
    "docs/bindings/core/component-architecture.md"
    "docs/bindings/categories/typescript/no-any.md"
    "docs/bindings/categories/typescript/module-organization.md"
    "docs/bindings/categories/rust/ownership-patterns.md"
    "docs/bindings/categories/rust/error-handling.md"
    "docs/bindings/categories/go/interface-design.md"
    "docs/bindings/categories/go/error-wrapping.md"
    "docs/bindings/categories/go/concurrency-patterns.md"
    "docs/bindings/categories/frontend/web-accessibility.md"
    "docs/bindings/categories/frontend/state-management.md"
)

for file in "${files[@]}"; do
    echo "Processing: $file"

    # Create a temporary file with the fixed format
    awk '
        BEGIN { metadata = ""; in_metadata = 0; first_line = 1 }
        /^______/ {
            if (in_metadata == 0) {
                in_metadata = 1
                print
            } else {
                # End of metadata section, print the collected metadata
                if (metadata != "") {
                    print metadata
                    print ""
                }
                print
                in_metadata = 0
                metadata = ""
                first_line = 1
            }
            next
        }
        in_metadata == 1 {
            if ($0 ~ /^[[:space:]]*$/) {
                # Skip empty lines
                next
            } else if ($0 ~ /^lastModified:/) {
                # Add lastModified to existing metadata line
                gsub(/^lastModified: /, "", $0)
                metadata = metadata " lastModified: " $0
            } else {
                if (first_line) {
                    metadata = $0
                    first_line = 0
                }
            }
        }
        !in_metadata { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

echo "Completed fixing metadata format"
