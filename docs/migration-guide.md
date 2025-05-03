# Migration Guide: Symlinks to Leyline

## Step-by-Step Migration Process

1. **Delete the old symlinks**
   ```bash
   git rm docs/DEVELOPMENT_PHILOSOPHY*.md
   ```

2. **Create a GitHub workflow file**
   Create `.github/workflows/vendor-docs.yml` with:
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
       uses: phrazzld/leyline/.github/workflows/vendor.yml@v0.1.0
       with:
         ref: v0.1.0
   ```

3. **Push these changes**
   ```bash
   git add .github/workflows/vendor-docs.yml
   git commit -m "chore: migrate from symlinks to Leyline"
   git push
   ```

4. **Wait for the workflow to run**
   - GitHub Actions will clone the Leyline repo
   - The workflow will create `/docs/tenets` and `/docs/bindings` directories
   - A PR will be created automatically with these directories

5. **Merge the PR**
   - The PR contains the vendored Leyline files
   - Merging it completes the migration

## That's it!

Your repository will now use the vendored tenets and bindings from Leyline instead of the old symlinks. When Leyline is updated, you'll automatically receive a PR with the updates.

## Troubleshooting

### Common Issues

**Workflow fails with "This run likely failed because of a workflow file issue"**
- Check that you're using `uses` correctly. It should be at the job level, not the step level.
- Make sure to add the `permissions` section as shown above.

**No PR is created after the workflow runs**
- Check if your repository allows GitHub Actions to create pull requests. Go to Settings > Actions > General and ensure "Workflow permissions" is set to "Read and write permissions".
- Verify that the permissions are correctly set in the workflow file.

**Error about "not finding ref" or similar reference errors**
- The Leyline repository must have the `v0.1.0` tag (or whichever tag you're referencing) published on GitHub.
- Check available tags at https://github.com/phrazzld/leyline/tags
- If you need to use the latest version, use `v0.1.1` which contains improved documentation.

If files aren't created correctly:
1. Check the GitHub Actions logs for specific error messages
2. Verify the workflow file is in the correct location
3. Ensure your GitHub token has proper permissions