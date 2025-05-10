# CI Resolution Plan

## Issue Summary

The CI is failing because many Markdown files don't meet the formatting requirements
enforced by the `mdformat` tool. Recent commits indicate work on implementing YAML
front-matter support, which suggests the project is transitioning to a new documentation
format standard.

## Resolution Strategy

### 1. Understand the New Format Requirements

- Review recent commits related to YAML front-matter (6fa5d3d, 5cef492, f936d11,
  e64bd38, 0bc99d3)
- Examine the simplicity tenet file that was updated to use YAML front-matter format
- Review any formatting configuration files to understand the expected format

### 2. Implement a Fix Script

- Create a script to format all Markdown files consistently
- Apply YAML front-matter format to all documentation files
- Run the script on all affected files

### 3. Fix Files in Batches

- Start with template files (`docs/templates/tenet_template.md`) to establish the
  correct pattern
- Apply the fix to core documentation files (tenets)
- Apply the fix to binding documentation files
- Fix any remaining Markdown files

### 4. Verify the Fix

- Run `mdformat --check .` locally to ensure all files pass formatting
- Test with any other linting tools in the pre-commit configuration
- Ensure the GitHub Pages build succeeds

## Implementation Steps

1. **Identify the correct format pattern**:

   - Examine `/docs/tenets/simplicity.md` which was recently updated
   - Review the `mdformat` configuration settings

1. **Apply format corrections**:

   - Update the YAML front-matter in each file
   - Ensure consistent formatting throughout all markdown files
   - Fix any specific issues found in the CI logs

1. **Test locally before pushing**:

   - Run the same formatting check that's failing in CI
   - Verify the GitHub Pages build process works locally if possible

1. **Commit and push fixes**:

   - Use conventional commit message format
   - Push the changes to trigger a new CI run
