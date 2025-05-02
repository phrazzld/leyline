# Setting Up GitHub Repository Labels

This document explains how to set up the required labels in the GitHub repository.

## Manual Setup

To manually set up the labels defined in `labels.yml`:

1. Go to the repository on GitHub
2. Navigate to Issues → Labels
3. Click "New Label" for each label and enter:
   - Label name (e.g., "tenet")
   - Description (e.g., "Changes to tenets - requires 2 core maintainer approvals")
   - Color (e.g., "#0366d6")

## Automated Setup

For automated setup, you can use tools like [github-label-sync](https://github.com/Financial-Times/github-label-sync):

```bash
# Install the tool
npm install -g github-label-sync

# Use the labels.yml file to sync labels
github-label-sync --access-token YOUR_TOKEN --labels .github/labels.yml phrazzld/leyline
```

## Required Labels for Governance

The following labels are essential for the governance workflow:

| Label | Purpose | Approval Requirement |
|-------|---------|---------------------|
| tenet | PRs modifying tenets | 2 core maintainers |
| binding | PRs modifying bindings | 1 core maintainer |
| breaking-change | Major version changes | Extended review |
| leyline-sync | Automated Warden PRs | Auto-merge eligible |

## Workflow Integration

These labels integrate with the governance model described in `PLAN.md` and the contributing guidelines. GitHub branch protection rules should be configured to:

1. Require specific reviewers based on PR labels
2. Enable auto-merge for PRs with only the "leyline-sync" label (when CI passes)

## Maintenance

If you need to add or modify labels, update the `labels.yml` file and apply the changes using your preferred method.