# CI Failure Audit for PR: Natural Language Rewrites of Tenets and Bindings

## Overview

The CI for the PR "Natural Language Rewrites of Tenets and Bindings" is currently failing. This document provides a detailed analysis of the failures and recommendations for fixing them.

## Failed Jobs

There are two main categories of failing jobs:

1. **lint-docs** - Markdown formatting and link checking
2. **deploy** - Building the documentation site in strict mode

## Detailed Analysis

### 1. lint-docs Failures

The `lint-docs` job is failing due to markdown formatting issues. The CI uses `mdformat` to check that all markdown files follow consistent formatting rules. Currently, virtually all markdown files in the repository are failing this check.

**Error example:**
```
Error: File "/home/runner/work/leyline/leyline/TODO.md" is not formatted.
```

This error is repeated for over 100 files across the codebase.

#### Root Cause
The files do not meet the formatting requirements enforced by `mdformat`. This could include issues with:
- Line spacing
- Heading formatting
- List indentation
- Code block formatting
- Table formatting

### 2. deploy Failures

The `deploy` job is failing because the MkDocs build process encounters warnings in strict mode, which causes it to abort.

**Specific warnings:**
1. `Doc file 'index.md' contains a link './docs/migration-guide.md', but the target 'docs/migration-guide.md' is not found among documentation files.`
2. `Doc file 'index.md' contains a link './examples/github-workflows/language-specific-sync.yml', but the target 'examples/github-workflows/language-specific-sync.yml' is not found among documentation files.`
3. `Doc file 'index.md' contains a link './docs/implementation-guide.md', but the target 'docs/implementation-guide.md' is not found among documentation files.`

#### Root Cause
The `index.md` file contains links that do not match the expected paths in the documentation structure. This is likely due to the recent reorganization of the file structure where files were moved to the `docs/` directory.

## Recommended Fixes

### 1. For lint-docs Failures

To fix the markdown formatting issues:

1. **Format all markdown files using mdformat:**
   ```bash
   # Install mdformat
   pip install mdformat
   
   # Format all markdown files
   mdformat .
   ```

2. **Commit the formatting changes:**
   Since this will affect many files, it would be best to make this a separate commit with a clear message indicating it's just formatting changes.

### 2. For deploy Failures

To fix the documentation build warnings:

1. **Update links in index.md:**
   - The file appears to be using prefixes like `./docs/` which are no longer needed since the content is already in the docs directory
   - Edit `index.md` to update these paths:
     - Change `./docs/migration-guide.md` to `migration-guide.md`
     - Change `./docs/implementation-guide.md` to `implementation-guide.md`
     - For external content like examples, make sure the paths are correctly relative to the documentation structure

## Execution Plan

1. First, fix the link issues in `index.md` to address the deploy failures.
2. Then, run the markdown formatter across all markdown files to fix the lint-docs failures.
3. Commit these changes separately for better clarity in the PR history.
4. Push the changes and verify that the CI passes.

## Long-term Recommendations

1. **Add pre-commit hooks** for markdown formatting to prevent these issues in the future.
2. **Update the contributor documentation** to mention the markdown formatting requirements.
3. **Consider adding a script** to the repository that can validate links locally before pushing.