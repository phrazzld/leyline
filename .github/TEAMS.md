# GitHub Repository Setup

This document provides simplified guidance for setting up the Leyline GitHub repository.

## Basic Repository Setup

### Repository Settings
- **Name**: `leyline`
- **Visibility**: Public
- **Description**: "Tenets & Bindings for development standards"

### Branch Protection (Simplified)
Set up basic branch protection for the master branch:
- Require pull requests before merging
- Require status checks to pass before merging
- Do not allow force pushes

### CODEOWNERS File (Optional)
For future use as the team grows, you can define code ownership:
```
/tenets/ @phrazzld
/bindings/ @phrazzld
```

## Implementation

When creating the repository:

```bash
# Create the repository
gh repo create phrazzld/leyline --public --description "Tenets & Bindings for development standards"

# Clone and push initial content
git remote add origin https://github.com/phrazzld/leyline.git
git push -u origin master

# Enable GitHub Pages (after repository exists)
gh api -X PUT repos/phrazzld/leyline/pages -f source='{"branch":"gh-pages","path":"/"}'
```

## Labels

A simplified set of labels can be created to track changes:
- `tenet`: Changes to tenets
- `binding`: Changes to bindings
- `documentation`: Documentation changes