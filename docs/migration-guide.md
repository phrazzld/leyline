# Migration Guide: Symlinks to Leyline

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
       uses: phrazzld/leyline/.github/workflows/vendor.yml@v0.1.1
       with:
         ref: v0.1.1
         # Optional: Override auto-detected languages
         # override_languages: typescript,javascript
         # Optional: Override auto-detected contexts
         # override_contexts: frontend,backend
   ```

1. **Push these changes**

   ```bash
   git add .github/workflows/vendor-docs.yml
   git commit -m "chore: migrate from symlinks to Leyline"
   git push
   ```

1. **Wait for the workflow to run**

   - GitHub Actions will clone the Leyline repo
   - The workflow will create `/docs/tenets` and `/docs/bindings` directories
   - A PR will be created automatically with these directories

1. **Merge the PR**

   - The PR contains the vendored Leyline files
   - Merging it completes the migration

## That's it!

Your repository will now use the vendored tenets and bindings from Leyline instead of
the old symlinks. When Leyline is updated, you'll automatically receive a PR with the
updates.

## Language-Specific Filtering

The Leyline workflow now automatically detects the languages and contexts in your
repository and only syncs the relevant bindings:

1. **Auto-detection**:

   - Languages are detected based on file extensions and config files
   - Contexts (frontend, backend, etc.) are inferred from code patterns
   - All tenets are always synced, as they are language-agnostic

1. **Overriding detection**: If you need to override the automatic detection, add
   parameters to the workflow:

   ```yaml
   jobs:
     docs:
       uses: phrazzld/leyline/.github/workflows/vendor.yml@v0.1.1
       with:
         ref: v0.1.1
         override_languages: typescript,go  # Only sync TypeScript and Go bindings
         override_contexts: frontend,cli    # Only sync frontend and CLI contexts
   ```

1. **Pull Request Summary**: The PR created by the workflow will include a summary of:

   - Detected languages and contexts
   - Number of synced tenets and bindings

## Troubleshooting

### Common Issues

**Workflow fails with "This run likely failed because of a workflow file issue"**

- Check that you're using `uses` correctly. It should be at the job level, not the step
  level.
- Make sure to add the `permissions` section as shown above.

**No PR is created after the workflow runs**

- Check if your repository allows GitHub Actions to create pull requests. Go to Settings
  \> Actions > General and ensure "Workflow permissions" is set to "Read and write
  permissions".
- Verify that the permissions are correctly set in the workflow file.

**Error about "not finding ref" or similar reference errors**

- The Leyline repository must have the `v0.1.0` tag (or whichever tag you're
  referencing) published on GitHub.
- Check available tags at https://github.com/phrazzld/leyline/tags
- If you need to use the latest version, use `v0.1.1` which contains improved
  documentation.

If files aren't created correctly:

1. Check the GitHub Actions logs for specific error messages
1. Verify the workflow file is in the correct location
1. Ensure your GitHub token has proper permissions
