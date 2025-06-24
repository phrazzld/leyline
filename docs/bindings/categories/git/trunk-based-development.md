---
id: trunk-based-development
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-workflow-conventions
enforced_by: 'branch protection rules, CI/CD integration, automated branch cleanup'
---
# Binding: Practice Trunk-Based Development

Adopt trunk-based development as your primary branching strategy, keeping all developers working on short-lived feature branches that integrate with the main branch frequently. This convention eliminates complex branching strategies in favor of continuous integration, reducing merge conflicts and enabling rapid delivery.

## Rationale

This binding implements our Git workflow conventions tenet by establishing trunk-based development as the default branching strategy. Just as Rails chose RESTful routing as its convention, removing endless debates about URL structures, trunk-based development removes endless debates about branching strategies. It's an opinionated choice that works well for most teams and enables powerful automation.

The beauty of trunk-based development lies in its simplicity. Instead of managing multiple long-lived branches with complex merge procedures, you have one source of truth—the main branch—and short-lived feature branches that exist only as long as needed. This simplicity isn't just aesthetic; it has profound practical benefits. Frequent integration catches conflicts early when they're small and easy to resolve. It enables continuous deployment because the main branch is always deployable. It reduces the cognitive overhead of understanding which branch contains which features.

Think of trunk-based development like a highway versus a maze of side streets. Complex branching strategies create a maze where developers must constantly think about which branch they're on, where to merge, and how changes flow between branches. Trunk-based development creates a highway where everyone knows the direction of travel and merges happen at predictable on-ramps. The occasional traffic (merge conflict) is quickly resolved because everyone's traveling in the same direction.

## Rule Definition

This binding establishes trunk-based development as the standard workflow:

- **Single Source of Truth**: The main branch (main/master) is the single source of truth and must always be in a deployable state

- **Short-Lived Feature Branches**: Feature branches should live no longer than 2-3 days
  - Create branches from main: `git checkout -b feature/issue-123-description`
  - Push changes frequently to enable collaboration
  - Merge back to main as soon as the feature is complete

- **Continuous Integration**: Integrate with main at least daily
  - Pull latest changes from main into your feature branch daily
  - Resolve conflicts immediately while they're small
  - Use `git pull --rebase origin main` to maintain linear history

- **Branch Protection**: Enforce quality gates on the main branch
  - Require pull request reviews before merging
  - Require all CI checks to pass
  - Prevent direct pushes to main
  - Automatically delete merged branches

- **Feature Flags Over Feature Branches**: For larger features that can't be completed in 2-3 days
  - Use feature flags to hide incomplete functionality
  - Continue integrating code into main behind flags
  - Gradually roll out features by toggling flags

- **No Long-Lived Branches**: Avoid GitFlow-style develop, staging, or release branches
  - Deploy from main using tags for versioning
  - Use automated deployment pipelines instead of deployment branches
  - Handle hotfixes as regular feature branches with expedited review

## Practical Implementation

Here's how to implement trunk-based development effectively:

1. **Configure Branch Protection**: Set up automated enforcement

   ```yaml
   # .github/branch-protection.yml
   main:
     protection_rules:
       - require_pull_request_reviews:
           required_approving_review_count: 1
           dismiss_stale_reviews: true
       - require_status_checks:
           strict: true
           contexts: ["build", "test", "lint"]
       - enforce_admins: false
       - restrictions: null
       - allow_force_pushes: false
       - allow_deletions: false
       - required_linear_history: true
       - delete_branch_on_merge: true
   ```

2. **Establish Branch Naming Convention**: Create predictable patterns

   ```bash
   # Branch naming pattern: type/issue-description
   feature/123-user-authentication
   fix/456-login-timeout
   chore/789-update-dependencies

   # Git alias for creating branches
   git config --global alias.feature '!f() { git checkout -b feature/$1; }; f'
   git config --global alias.fix '!f() { git checkout -b fix/$1; }; f'

   # Usage
   git feature 123-user-authentication
   git fix 456-login-timeout
   ```

3. **Automate Daily Integration**: Keep branches fresh

   ```bash
   # .githooks/pre-push
   #!/bin/bash
   # Warn if branch is older than 2 days
   BRANCH_AGE=$(git log -1 --format=%cr)
   if [[ $BRANCH_AGE == *"days"* ]] && [[ ${BRANCH_AGE%% *} -gt 2 ]]; then
     echo "⚠️  Warning: This branch is $BRANCH_AGE old"
     echo "Consider merging soon to avoid conflicts"
   fi
   ```

4. **Implement Feature Flags**: Enable continuous integration of large features

   ```typescript
   // Simple feature flag implementation
   const features = {
     newUserDashboard: process.env.FEATURE_NEW_DASHBOARD === 'true',
     enhancedSearch: process.env.FEATURE_ENHANCED_SEARCH === 'true'
   };

   // Usage in code
   if (features.newUserDashboard) {
     return <NewDashboard />;
   } else {
     return <LegacyDashboard />;
   }
   ```

5. **Create Merge Checklist**: Standardize the integration process

   ```markdown
   <!-- .github/pull_request_template.md -->
   ## Pre-Merge Checklist
   - [ ] Branch is up-to-date with main
   - [ ] All CI checks pass
   - [ ] Code has been reviewed
   - [ ] No console.log or debug code remains
   - [ ] Documentation updated if needed
   - [ ] Commits follow conventional format
   ```

## Examples

```bash
# ❌ BAD: Long-lived feature branch
git checkout -b feature/major-redesign
# ... 3 weeks of development ...
# Massive conflicts when trying to merge

# ✅ GOOD: Series of small, focused branches
git checkout -b feature/123-update-header
# Complete in 1 day, merge
git checkout -b feature/124-update-navigation
# Complete in 2 days, merge
git checkout -b feature/125-update-footer
# Complete in 1 day, merge
```

```bash
# ❌ BAD: Complex branching with staging
main -> develop -> feature/big-feature
              \-> staging
              \-> feature/another-feature

# ✅ GOOD: Simple trunk-based flow
main -> feature/123-small-change (1 day)
    \-> feature/124-another-change (2 days)
    \-> fix/125-bug-fix (4 hours)
```

```bash
# ❌ BAD: Resolving conflicts after weeks
git checkout feature/old-branch
git merge main
# 47 conflicts in 23 files

# ✅ GOOD: Daily integration prevents conflicts
git checkout feature/current-work
git pull --rebase origin main
# 1 minor conflict, resolved in 30 seconds
```

## Related Bindings

- [commit-message-conventions.md](commit-message-conventions.md): Structured commits work seamlessly with trunk-based development by providing clear history on the main branch

- [automated-release-workflow.md](automated-release-workflow.md): Trunk-based development enables automated releases by maintaining a always-deployable main branch

- [pull-request-workflow.md](pull-request-workflow.md): Short-lived branches in trunk-based development require efficient PR processes for rapid integration

- [merge-strategy-conventions.md](merge-strategy-conventions.md): Linear history and rebase workflows complement trunk-based development's simplicity

- [../../../core/feature-flag-management.md](../../../core/feature-flag-management.md): Feature flags enable trunk-based development for larger features that can't complete in 2-3 days

- [../../../core/ci-cd-pipeline-standards.md](../../../core/ci-cd-pipeline-standards.md): Continuous integration pipelines are essential for maintaining quality in trunk-based development
