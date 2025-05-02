# GitHub Teams Configuration

This document defines the teams needed for the Leyline repository governance model.

## Core Maintainers Team

### Team Configuration
- **Name**: `core-maintainers`
- **Visibility**: Visible
- **Permission Level**: Maintain
- **Parent Team**: None

### Repository Access
The core-maintainers team should be granted the following permissions:
- **Repo Permissions**: Maintain
- **Code Review Limits**: Can be review approvers for PRs that modify tenets and bindings

### Required Settings
To implement the governance model described in PLAN.md, ensure:

1. Branch protection rules reference this team for:
   - Required reviews on tenets (minimum 2 approvals from team members)
   - Required reviews on bindings (minimum 1 approval from team members)

2. A CODEOWNERS file designates this team as owners for critical paths:
   ```
   /tenets/ @phrazzld/core-maintainers
   /bindings/ @phrazzld/core-maintainers
   ```

## Implementation Instructions

When creating the GitHub repository:

1. Create the organization team:
   ```
   gh api -X POST orgs/phrazzld/teams \
      -f name='core-maintainers' \
      -f description='Core maintainers for Leyline tenets and bindings' \
      -f privacy='closed' \
      -f permission='maintain'
   ```

2. Add the team to the repository:
   ```
   gh api -X PUT teams/phrazzld/core-maintainers/repos/phrazzld/leyline \
      -f permission='maintain'
   ```

3. Add members to the team:
   ```
   gh api -X PUT teams/phrazzld/core-maintainers/memberships/USERNAME \
      -f role='maintainer'
   ```

Replace `USERNAME` with the GitHub usernames of team members listed in MAINTAINERS.md.