# CI Resolution Tasks

## Priority Tasks

### 1. Fix Markdown Formatting Issues

- **T082 · Fix · P0: Apply mdformat to all markdown files**
  - **Context:** CI lint-docs job fails due to inconsistent markdown formatting across
    49 files
  - **Action:**
    1. Install mdformat locally with front-matter support:
       `pip install mdformat mdformat-frontmatter`
    1. Format all markdown files: `mdformat --wrap 88 .`
    1. Verify formatting has been applied correctly
  - **Done‑when:**
    1. All markdown files have consistent formatting
    1. mdformat runs without errors
  - **Verification:**
    1. Run `mdformat --check .` to confirm no formatting issues remain
  - **Depends‑on:** none

### 2. Standardize YAML Front-matter

- **T083 · Fix · P0: Update tenet_template.md with proper YAML front-matter comments**
  - **Context:** The template file has explanatory comments mixed into YAML which breaks
    validation
  - **Action:**
    1. Update the tenet_template.md file to place explanatory comments outside the YAML
       front-matter section
    1. Use proper YAML syntax for all front-matter fields
    1. Ensure the template demonstrates the correct format for others to follow
  - **Done‑when:**
    1. Template file has valid YAML front-matter
    1. Explanatory comments appear outside the YAML block
  - **Verification:**
    1. Run validation tool to verify the template passes front-matter validation
  - **Depends‑on:** none

### 3. Fix Index Generation

- **T084 · Fix · P0: Ensure tenets index file is properly formatted**
  - **Context:** The docs/tenets/00-index.md file appears to have formatting issues
  - **Action:**
    1. Check the format of docs/tenets/00-index.md
    1. Apply proper markdown formatting to the file
    1. Ensure any links in the index file are correctly formatted
  - **Done‑when:**
    1. Index file passes the formatting check
    1. All links in the index file work correctly
  - **Verification:**
    1. Run mdformat check on the index file
    1. Run markdown-link-check to verify links
  - **Depends‑on:** none

## Validation Tasks

- **T085 · Test · P0: Run full CI validation locally**
  - **Context:** Need to verify all fixes will pass the CI before pushing changes
  - **Action:**
    1. Run mdformat check on all files: `mdformat --check .`
    1. Run markdown link validation: `markdown-link-check -q -c ./.mlc-config '**/*.md'`
    1. Run mkdocs build to verify site generation: `mkdocs build --strict`
  - **Done‑when:**
    1. All validation tools pass without errors
    1. Site builds successfully without warnings
  - **Verification:**
    1. All tests run without errors
  - **Depends‑on:** \[T082, T083, T084\]

## Implementation Plan

1. First complete tasks T082, T083, and T084 to fix the formatting issues
1. Then run task T085 to validate that all issues have been fixed
1. Commit the changes with a conventional commit message noting the formatting fixes
1. Push changes to the PR branch to trigger a new CI run
