# Leyline Integration Examples

This directory contains example configuration files that consumer repositories can use
to integrate with Leyline. These examples demonstrate best practices for maintaining
synchronized copies of tenets and bindings.

## Directory Structure

```
examples/
├── github-workflows/  # GitHub Actions workflow examples
├── pre-commit/        # Pre-commit hook configurations
└── renovate/          # Renovate bot configurations
```

## Integration Steps

To integrate your repository with Leyline, follow these steps:

1. **Set up GitHub Actions Workflow**

   - Copy `github-workflows/vendor-docs.yml` to your repository at
     `.github/workflows/vendor-docs.yml`
   - This workflow will sync tenets and bindings to your repository's `docs/` directory

1. **Add Pre-commit Hook (Optional but Recommended)**

   - Add the content from `pre-commit/pre-commit-config.yaml` to your repository's
     `.pre-commit-config.yaml`
   - This hook ensures that Leyline vendor files haven't been manually modified

1. **Configure Renovate (Optional)**

   - If you use Renovate bot, add the configuration from `renovate/renovate.json` to
     your repository
   - This will automatically update Leyline references in your workflows

## Usage Notes

- The first time the workflow runs, it will create `/docs/tenets` and `/docs/bindings`
  directories in your repository
- These directories should be committed to version control
- Do not manually edit files in these directories; all updates should come through the
  Leyline Warden

## Upgrading Leyline Versions

When a new version of Leyline is released, you can update your integration by:

1. Changing the `ref` parameter in your workflow file (e.g., from `v0.1.0` to `v0.2.0`)
1. Running the updated workflow, which will create a pull request with the new tenets
   and bindings

If you've configured Renovate, it will automatically create pull requests to update your
Leyline references.
