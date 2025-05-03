# Setup Reminder

This file contains manual steps that need to be completed after initial repository setup.

## Required Manual Configuration

### 1. Set up branch protection rules
Follow the instructions in `docs/github-branch-protection.md` to configure branch protection rules for the `master` branch.

### 2. Configure merge settings
In repository settings, ensure:
- Allow merge commits: ✓
- Allow squash merging: ✗ 
- Allow rebase merging: ✗
- Automatically delete head branches: ✓

These configurations should be done directly on GitHub.com after pushing the repository.