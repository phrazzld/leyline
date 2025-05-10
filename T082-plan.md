# T082 Plan: Apply mdformat to all markdown files

## Approach

1. Install mdformat with front-matter support:

   ```bash
   pip install mdformat mdformat-frontmatter
   ```

1. Run mdformat on all markdown files with the wrap setting matching the project's
   configuration:

   ```bash
   mdformat --wrap 88 .
   ```

1. Verify the formatting has been applied correctly:

   ```bash
   mdformat --check .
   ```

1. Review the changes to ensure no content was corrupted, particularly focusing on:

   - YAML front-matter sections remain intact
   - Code blocks maintain proper formatting
   - Tables remain properly aligned

## Implementation Notes

- The .mdformat.toml file already specifies wrap=88, but we'll include it in the command
  to ensure consistency
- We'll use the mdformat-frontmatter plugin to properly handle YAML front-matter
  sections
- We need to be cautious about any files that might be intentionally excluded from
  formatting
