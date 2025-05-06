# Setting Up GitHub Branch Protection Rules

This document outlines the steps to configure branch protection rules for the `master` branch of the `phrazzld/leyline` repository.

## Configuration Steps

1. Navigate to the repository on GitHub: [https://github.com/phrazzld/leyline](https://github.com/phrazzld/leyline)

1. Go to the "Settings" tab of the repository

1. In the left sidebar, click on "Branches"

1. Under "Branch protection rules", click "Add rule"

1. Configure the branch protection rule with these settings:

   - Branch name pattern: `master`
   - Require a pull request before merging: ✓
     - Require approvals: Not required initially (per simplified governance model)
   - Require status checks to pass before merging: ✓ (once CI is set up)
   - Require conversation resolution before merging: ✓
   - Do not allow bypassing the above settings: ✓
   - Allow force pushes: ✗
   - Allow deletions: ✗

1. Click "Create" to apply the branch protection rule

## Additional Repository Settings

1. In the "Settings" > "General" section, ensure:
   - Merge button settings:
     - Allow merge commits: ✓
     - Allow squash merging: ✗
     - Allow rebase merging: ✗
   - Automatically delete head branches: ✓

## Rationale

These branch protection rules implement our simplified governance model while ensuring code quality:

- Requiring pull requests prevents direct pushes to master
- Disabling force pushes maintains a clean, linear history
- Not requiring approvals initially supports a lightweight process for early development
- Once CI is set up, requiring status checks will ensure all PRs pass automated tests
- Only allowing merge commits (not squash or rebase) maintains a clear commit history

These rules can be strengthened later as the repository grows and matures.
