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
         - master
   jobs:
     docs:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Sync Leyline Docs
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

If files aren't created correctly:
1. Check the GitHub Actions logs
2. Verify the workflow file is in the correct location
3. Ensure your GitHub token has proper permissions