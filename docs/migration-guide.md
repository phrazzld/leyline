# Migration Guide

This guide covers migration scenarios for adopting or upgrading your Leyline integration:

1. **[Migrating from Symlinks to Leyline](#migrating-from-symlinks-to-leyline)** - For repositories using symlinked philosophy documents
2. **[Migrating from Legacy Workflows](#migrating-from-legacy-workflows)** - For repositories using the old vendor.yml workflow
3. **[Migrating to Directory-Based Structure](#migrating-to-directory-based-structure)** - For existing Leyline users updating to the new directory-based structure

For comprehensive integration instructions, see the [Pull-Based Integration Guide](integration/pull-model-guide.md).

---

# Migrating from Symlinks to Leyline

If your repository currently uses symlinked philosophy documents, follow this guide to migrate to Leyline's pull-based content synchronization.

## Step-by-Step Migration Process

### 1. Remove Old Symlinks

```bash
# Remove the old symlinked files
git rm docs/DEVELOPMENT_PHILOSOPHY*.md

# Commit the removal
git commit -m "chore: remove symlinked philosophy documents"
```

### 2. Create Leyline Sync Workflow

Create `.github/workflows/sync-leyline.yml`:

```yaml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Mondays
  workflow_dispatch:     # Allow manual triggers

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0  # Pin to specific version
      categories: go,typescript,frontend  # Customize for your tech stack
      target_path: docs/leyline
      create_pr: true
```

### 3. Configure Workflow

**Required Configuration:**
- `token`: GitHub token with repo write permissions
- `leyline_ref`: Specific Leyline version (never use `main`)

**Optional Configuration:**
- `categories`: Comma-separated list of relevant categories
- `target_path`: Where to place Leyline content (default: `docs/leyline`)
- `create_pr`: Whether to create PR (recommended: `true`)

**Available Categories:**
- **Languages**: `go`, `rust`, `typescript`
- **Contexts**: `frontend`, `backend`

### 4. Activate the Workflow

```bash
# Add and commit the workflow
git add .github/workflows/sync-leyline.yml
git commit -m "feat: add Leyline content synchronization"
git push
```

### 5. Review and Merge Initial Sync

1. **Automatic Sync**: The workflow runs and creates a PR with Leyline content
2. **Review PR**: Check the synced tenets and bindings
3. **Merge PR**: Complete the migration by merging the PR

## What Happens Next

- **Scheduled Updates**: Workflow runs weekly to check for updates
- **Manual Updates**: Trigger via GitHub Actions UI when needed
- **Version Control**: Team reviews all changes via pull requests
- **Selective Sync**: Only categories relevant to your project are included

For detailed configuration options, see the [comprehensive workflow example](../examples/consumer-workflows/sync-leyline-example.yml).

---

# Migrating from Legacy Workflows

If your repository uses the old `vendor.yml` workflow, follow this guide to migrate to the new `sync-leyline-content.yml` workflow.

## Why Migrate?

The new workflow provides:
- **Enhanced Security**: Explicit token management
- **Better Control**: More configuration options and outputs
- **Improved Reliability**: Better error handling and logging
- **Future Support**: Active development and maintenance

## Before and After Comparison

### Old Workflow (vendor.yml)
```yaml
jobs:
  docs:
    uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0
    with:
      ref: v1.0.0
      categories: go,typescript
```

### New Workflow (sync-leyline-content.yml)
```yaml
jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}  # Now required
      leyline_ref: v1.0.0                # Renamed from 'ref'
      categories: go,typescript           # Same format
      target_path: docs/leyline          # New: customizable path
      create_pr: true                    # New: PR control
```

## Migration Steps

### Step 1: Update Workflow Reference

In your `.github/workflows/*.yml` file:

**Change:**
```yaml
uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0
```

**To:**
```yaml
uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
```

### Step 2: Update Input Parameters

| Old Parameter | New Parameter | Notes |
|---------------|---------------|-------|
| `ref` | `leyline_ref` | Renamed for clarity |
| N/A | `token` | **Required**: `${{ secrets.GITHUB_TOKEN }}` |
| `categories` | `categories` | Same format |
| N/A | `target_path` | Optional: customize destination |
| N/A | `create_pr` | Optional: control PR creation |

### Step 3: Add Required Token

Add the token parameter to your workflow:

```yaml
with:
  token: ${{ secrets.GITHUB_TOKEN }}
  # ... other parameters
```

### Step 4: Test the Migration

1. **Create Feature Branch**: Test changes before applying to main
2. **Manual Trigger**: Use `workflow_dispatch` to test manually
3. **Verify Output**: Check that sync works as expected
4. **Review PR**: Ensure content is synced correctly

### Step 5: Update Additional Configurations

**Optional Enhancements:**
```yaml
with:
  token: ${{ secrets.GITHUB_TOKEN }}
  leyline_ref: v1.0.0
  categories: go,typescript,frontend
  target_path: docs/leyline                    # Customize location
  create_pr: true                             # Enable PR workflow
  commit_message: "docs: update standards"    # Custom commit message
  pr_title: "Update Development Standards"    # Custom PR title
```

## Migration Troubleshooting

### Common Issues

**"Resource not accessible by integration"**
- **Cause**: Missing or insufficient token permissions
- **Solution**: Ensure `token: ${{ secrets.GITHUB_TOKEN }}` is included

**"Invalid leyline_ref provided"**
- **Cause**: Using old parameter name or invalid version
- **Solution**: Use `leyline_ref` (not `ref`) with valid version

**"Workflow file seems to have an issue"**
- **Cause**: Syntax error in updated workflow
- **Solution**: Validate YAML syntax and parameter format

**No PR created after migration**
- **Cause**: `create_pr` disabled or permission issues
- **Solution**: Set `create_pr: true` and check repo permissions

### Validation Checklist

After migration, verify:
- [ ] Workflow runs without errors
- [ ] Content syncs to expected location
- [ ] PR is created with appropriate title
- [ ] All requested categories are included
- [ ] No old-format files remain

---

# Migrating to Directory-Based Structure

For existing Leyline users updating to the new hierarchical directory structure.

## What's Changing?

### Old Structure (Flat)
```
docs/bindings/
├── 00-index.md
├── pure-functions.md           # Core binding
├── ts-no-any.md               # TypeScript binding
└── go-error-wrapping.md       # Go binding
```

### New Structure (Hierarchical)
```
docs/bindings/
├── core/
│   ├── 00-index.md
│   └── pure-functions.md      # Core bindings
├── categories/
│   ├── typescript/
│   │   └── no-any.md          # TypeScript-specific
│   └── go/
│       └── error-wrapping.md  # Go-specific
└── 00-index.md               # Combined index
```

## Migration Process

### Step 1: Update Workflow Configuration

Add explicit `categories` parameter to your workflow:

```yaml
jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0
      categories: go,typescript,frontend  # Specify your categories
```

### Step 2: Run Updated Workflow

The workflow automatically:
1. **Cleans up** old flat-structure files
2. **Syncs core** bindings to `docs/bindings/core/`
3. **Syncs categories** to `docs/bindings/categories/<category>/`
4. **Regenerates index** to reflect new structure
5. **Creates PR** with migration details

### Step 3: Review Migration PR

The PR will show:
- Files removed from old structure
- New hierarchical organization
- Updated index with proper sections
- Any warnings for missing categories

### Step 4: Update Internal References

If your project references binding files directly:

**Update paths:**
```markdown
<!-- Old -->
[Pure Functions](docs/bindings/pure-functions.md)

<!-- New -->
[Pure Functions](docs/bindings/core/pure-functions.md)
```

## Understanding the New Structure

### Core vs. Category Bindings

**Core Bindings** (`docs/bindings/core/`):
- Apply universally across all projects
- Technology-agnostic principles
- Always synced regardless of categories

**Category Bindings** (`docs/bindings/categories/<category>/`):
- Apply to specific languages or contexts
- Technology-specific implementations
- Synced only when category is requested

### Benefits of New Structure

1. **Explicit Control**: Choose exactly which categories to sync
2. **Cleaner Organization**: Clear separation of concerns
3. **Reduced Noise**: Only relevant bindings in your project
4. **Better Scaling**: Easy to add new categories without conflicts

---

# Troubleshooting

## Common Issues

### Workflow Errors

**"Token permission issues"**
- **Symptoms**: "Resource not accessible by integration"
- **Solutions**:
  - Ensure `token: ${{ secrets.GITHUB_TOKEN }}` is included
  - Check repository Actions permissions
  - Verify organization SSO settings

**"Invalid workflow reference"**
- **Symptoms**: "Could not resolve to a Repository"
- **Solutions**:
  - Use `sync-leyline-content.yml@v1` (not `vendor.yml`)
  - Verify workflow file syntax
  - Check for typos in repository reference

### Content Issues

**"Missing requested categories"**
- **Symptoms**: Warnings in PR about non-existent categories
- **Solutions**:
  - Check category spelling: `go`, `rust`, `typescript`, `frontend`, `backend`
  - Verify categories exist in the Leyline version you're using
  - Update to newer Leyline version if category was added later

**"No changes detected"**
- **Symptoms**: Workflow runs but no PR is created
- **Solutions**:
  - Content is already up-to-date (normal behavior)
  - Check if workflow is configured correctly
  - Verify `leyline_ref` points to different version

### Repository Setup Issues

**"Workflow doesn't trigger"**
- **Symptoms**: Scheduled workflow never runs
- **Solutions**:
  - Ensure workflow is on main/default branch
  - Check Actions are enabled for repository
  - Verify cron syntax in schedule trigger

**"PRs aren't created"**
- **Symptoms**: Workflow runs but no PR appears
- **Solutions**:
  - Verify `create_pr: true` in workflow
  - Check repository allows Actions to create PRs
  - Ensure no branch protection conflicts

## Getting Help

### Self-Service Resources

1. **Check workflow logs** in GitHub Actions tab
2. **Review this migration guide** for common scenarios
3. **Consult the comprehensive guide**: [Pull-Based Integration Guide](integration/pull-model-guide.md)
4. **See working examples**: [Consumer Workflow Examples](../examples/consumer-workflows/)

### Community Support

- **Questions & Bug Reports**: [GitHub Issues](https://github.com/phrazzld/leyline/issues)
- **Feature Requests**: [GitHub Issues](https://github.com/phrazzld/leyline/issues) with "enhancement" label

### When Reporting Issues

Include:
- Complete workflow configuration
- Error messages from workflow logs
- Leyline version being used (`leyline_ref`)
- Repository settings (if relevant)

---

## Related Documentation

- **[Pull-Based Integration Guide](integration/pull-model-guide.md)**: Comprehensive setup instructions
- **[Versioning Guide](integration/versioning-guide.md)**: Version management best practices
- **[Consumer Workflow Examples](../examples/consumer-workflows/)**: Working configuration examples

---

**Note**: All migrations are one-time processes. Once completed, future syncs will use the current workflow and structure automatically.
