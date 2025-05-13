# Migration Guide

This guide covers two migration scenarios:
1. **[Migrating from Symlinks to Leyline](#migrating-from-symlinks-to-leyline)** - For repositories using symlinked philosophy documents
2. **[Migrating to Directory-Based Structure](#migrating-to-directory-based-structure)** - For existing Leyline users updating to the new directory-based structure

---

# Migrating from Symlinks to Leyline

## Step-by-Step Migration Process

1. **Delete the old symlinks**

   ```bash
   git rm docs/DEVELOPMENT_PHILOSOPHY*.md
   ```

1. **Create a GitHub workflow file** Create `.github/workflows/vendor-docs.yml` with:

   ```yaml
   name: Leyline Sync
   on:
     pull_request:
     push:
       branches:
         - master  # Change this if your default branch has a different name
   permissions:
     contents: write
     pull-requests: write
   jobs:
     docs:
       uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0
       with:
         ref: v1.0.0
         categories: go,typescript,frontend  # Specify your required categories
   ```

1. **Push these changes**

   ```bash
   git add .github/workflows/vendor-docs.yml
   git commit -m "chore: migrate from symlinks to Leyline"
   git push
   ```

1. **Wait for the workflow to run**

   - GitHub Actions will clone the Leyline repo
   - The workflow will create `/docs/tenets` and `/docs/bindings` directories with appropriate structure
   - A PR will be created automatically with these directories

1. **Merge the PR**

   - The PR contains the vendored Leyline files
   - Merging it completes the migration

## That's it!

Your repository will now use the vendored tenets and bindings from Leyline instead of
the old symlinks. When Leyline is updated, you'll automatically receive a PR with the
updates.

---

# Migrating to Directory-Based Structure

## What's Changing?

Leyline has undergone an architectural change in how bindings are organized:

**Old Structure:**
- Flat organization in `docs/bindings/`
- Language/context identification via filename prefixes (e.g., `ts-no-any.md`, `go-error-wrapping.md`)
- Filtering via detection-based approach using `applies_to` front matter

**New Structure:**
- Hierarchical organization with `core/` and `categories/` directories
- Language/context identification via directory placement
- Explicit category selection via the new `categories` input
- Core bindings always synced to all consumers

This change provides better organization, more explicit control, and cleaner integration for all consumers.

## Migration Steps

### Step 1: Update Your Workflow YAML

Update your GitHub Actions workflow file to include the new `categories` input:

```yaml
# .github/workflows/vendor-docs.yml
name: Leyline Sync
on:
  pull_request:
  push:
jobs:
  docs:
    uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0  # Use appropriate version
    with:
      ref: v1.0.0  # Use appropriate version
      categories: go,typescript,frontend  # Specify your required categories
```

The `categories` parameter accepts a comma-separated list with no spaces.

> **Note:** The `override_languages` and `override_contexts` parameters are deprecated and will be removed in a future version. Use `categories` instead.

### Step 2: Select Appropriate Categories

Choose which categories are relevant for your project from:

| Category | Description | Contains Bindings For |
|----------|-------------|------------------------|
| `go` | Go language | Go-specific patterns and practices |
| `rust` | Rust language | Rust-specific patterns and practices |
| `typescript` | TypeScript language | TypeScript and JavaScript patterns |
| `cli` | Command-line interfaces | CLI application design patterns |
| `frontend` | Frontend applications | Web/UI application patterns |
| `backend` | Backend applications | Server-side application patterns |

Guidelines for selection:
- Select categories matching your project technologies
- Specify only the categories you need (reduces noise)
- Core bindings are always synced regardless of selection

### Step 3: Run the Updated Workflow

When you run the updated workflow:

1. The workflow will automatically clean up any old-format binding files
2. Core bindings will be synced to `docs/bindings/core/`
3. Requested categories will be synced to `docs/bindings/categories/<category>/`
4. The bindings index will be regenerated to reflect the new structure
5. A pull request will be created with:
   - Details of which categories were synced
   - Warnings for any requested categories that don't exist
   - Information about cleanup operations performed

## Understanding the New Structure

### Directory Structure

```
docs/bindings/
  ├── core/                # Core bindings (always synced)
  ├── categories/
  │   ├── go/              # Go-specific bindings
  │   ├── rust/            # Rust-specific bindings
  │   ├── typescript/      # TypeScript-specific bindings
  │   ├── cli/             # CLI-specific bindings
  │   ├── frontend/        # Frontend-specific bindings
  │   └── backend/         # Backend-specific bindings
  └── 00-index.md          # Auto-generated index of all bindings
```

### Core vs. Category Bindings

- **Core Bindings**: Apply to all projects regardless of language or environment. These bindings represent fundamental principles that transcend specific technologies.

- **Category Bindings**: Apply specifically to certain languages or contexts. These bindings often use language-specific syntax or address concerns unique to particular development environments.

### Cleanup Process

When the workflow runs:
- It identifies any `.md` files directly in `docs/bindings/` (old structure)
- These files are removed to prevent conflicts and confusion
- A count of removed files is included in the PR description

### Reindexing Process

The workflow automatically runs `reindex.rb` to:
- Generate a new `docs/bindings/00-index.md` file
- Include proper sections for core and each category
- Create correct relative links to all binding files
- Ensure the index reflects the current state of all bindings

## Troubleshooting

### Common Issues

**Missing categories warning**
- **Symptom**: PR shows warnings about requested categories not found
- **Solution**: Check spelling of categories; verify they exist in the current Leyline version

**No category-specific bindings synced**
- **Symptom**: PR shows only core bindings were synced, but no category-specific bindings
- **Solution**: Verify you specified categories in the input parameter; check if you need to update to a newer Leyline version

**Binding links are broken in documentation**
- **Symptom**: Internal documentation links to binding files return 404
- **Solution**: Update internal references to use new paths (`docs/bindings/core/` or `docs/bindings/categories/<category>/`)

**Workflow fails with "This run likely failed because of a workflow file issue"**
- Check that you're using `uses` correctly. It should be at the job level, not the step level.
- Make sure to add the `permissions` section as shown above.

**No PR is created after the workflow runs**
- Check if your repository allows GitHub Actions to create pull requests. Go to Settings > Actions > General and ensure "Workflow permissions" is set to "Read and write permissions".
- Verify that the permissions are correctly set in the workflow file.

**Error about "not finding ref" or similar reference errors**
- The Leyline repository must have the tag (e.g., `v1.0.0`) you're referencing published on GitHub.
- Check available tags at https://github.com/phrazzld/leyline/tags

**Invalid format for categories input**
- **Symptom**: Workflow fails with error about invalid format for categories input
- **Solution**: Ensure the categories input contains only alphanumeric characters, commas, and hyphens (no spaces)

### Verifying Successful Migration

A successful migration should result in:
1. No `.md` files directly in `docs/bindings/` (except `00-index.md`)
2. Core bindings in `docs/bindings/core/`
3. Category-specific bindings in `docs/bindings/categories/<category>/`
4. An up-to-date `docs/bindings/00-index.md` file with proper sections and links

## Need Help?

If you encounter any issues during migration, please:
1. Check this guide's troubleshooting section
2. Review the [Leyline documentation](https://github.com/phrazzld/leyline)
3. Open an issue with the "migration" label if you need additional assistance

---

**Note**: This migration is a one-time process. Once completed, all future syncs will use the new directory structure automatically.
