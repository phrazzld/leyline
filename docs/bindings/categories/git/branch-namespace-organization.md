---
id: branch-namespace-organization
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: distributed-first
enforced_by: 'git hooks, branch protection rules, CI validation'
---
# Binding: Organize Branch Namespaces Systematically

Structure branch names using hierarchical namespaces that convey intent, ownership, and lifecycle. Use consistent patterns that enable efficient ref operations, clear team communication, and automated workflow integration.

## Rationale

Git stores branches as refs—simple files containing commit SHAs. Without systematic naming, repositories devolve into chaos with branches like "fix", "test2", "johns-work".

Hierarchical namespaces enable automation (deleting merged features, protecting releases), improve Git performance through filesystem organization, and serve as communication tools. Branch "feature/123-user-authentication" immediately conveys purpose, issue, and lifecycle stage.

## Rule Definition

**Namespace Structure:**

```
<type>/<issue>-<description>
<type>/<subtype>/<issue>-<description>
<user>/<type>/<description>
```

**Standard Type Prefixes:**
- `feature/` - New functionality
- `fix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `release/` - Release preparation branches
- `chore/` - Maintenance tasks
- `experiment/` - Experimental work
- `revert/` - Revert branches

**Naming Requirements:**

- **Lowercase Only**: Branch names must be lowercase for cross-platform compatibility
- **Hyphen Separated**: Use hyphens, not underscores or spaces
- **Issue References**: Include ticket/issue numbers when available
- **Descriptive Names**: Clearly indicate the branch purpose
- **No Personal Names**: Avoid developer names in shared branches
- **Length Limits**: Keep total length under 60 characters

**Reserved Namespaces:**
- `main`, `master` - Primary branch
- `develop` - Integration branch (if used)
- `staging` - Pre-production environment
- `production` - Production releases

## Practical Implementation

**Git Configuration:**

```bash
# Branch namespace shortcuts
git config alias.fb '!f() { git checkout -b feature/$1; }; f'
git config alias.hf '!f() { git checkout -b hotfix/$1; }; f'
git config alias.fx '!f() { git checkout -b fix/$1; }; f'

# List by namespace
git config alias.features 'branch -r --list "origin/feature/*"'
git config alias.fixes 'branch -r --list "origin/fix/*"'

# Cleanup merged branches
git config alias.cleanup '!f() { git branch --merged | grep "^  $1/" | xargs -n 1 git branch -d; }; f'
```

**Pre-receive Hook:**

```bash
#!/bin/bash
while read oldrev newrev refname; do
    branch=$(echo $refname | sed 's/refs\/heads\///')
    [[ "$newrev" = "0000000000000000000000000000000000000000" ]] && continue

    # Validate format
    if ! echo "$branch" | grep -qE '^(feature|fix|hotfix|release|chore|experiment|revert)/[a-z0-9-]+$'; then
        echo "❌ Invalid: $branch. Expected: <type>/<issue>-<description>"
        exit 1
    fi

    # Check length and reserved names
    [[ ${#branch} -gt 60 ]] && echo "❌ Too long: $branch" && exit 1
    [[ "$branch" =~ ^(main|master|develop|staging|production)$ ]] && echo "❌ Reserved: $branch" && exit 1
done
```

**Branch Management:**

```bash
#!/bin/bash
# Analyze namespaces
analyze_branches() {
    for namespace in feature fix hotfix release chore experiment; do
        count=$(git branch -r | grep -c "origin/$namespace/")
        echo "$namespace: $count branches"
    done
}

# Clean merged branches
cleanup_merged() {
    for namespace in feature fix chore experiment; do
        git branch -r --merged origin/main | grep "origin/$namespace/" |
        sed 's/origin\///' | xargs -n 1 git push origin --delete
    done
}

# Archive old branches (90+ days)
archive_old() {
    archive_date=$(date -v-90d +%Y-%m-%d)
    git for-each-ref --format='%(refname:short) %(committerdate:short)' refs/remotes/origin/ |
    while read branch date; do
        [[ "$date" < "$archive_date" ]] && {
            tag="archive/${branch#origin/}-$(date +%Y%m%d)"
            git tag "$tag" "$branch" && git push origin "$tag" && git push origin --delete "${branch#origin/}"
        }
    done
}
```

**Branch Protection by Namespace:**

```yaml
# .github/branch-protection.yml
protection_rules:
  - pattern: "main"
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    include_administrators: false

  - pattern: "release/*"
    required_reviews: 2
    restrict_push_access:
      teams: ["release-managers"]
    require_up_to_date: true

  - pattern: "hotfix/*"
    required_reviews: 1
    require_status_checks:
      contexts: ["security-scan", "critical-tests"]
    allow_force_pushes: false

  - pattern: "feature/*"
    required_reviews: 1
    delete_branch_on_merge: true
    allow_force_pushes: true
```

## Examples

```bash
# ❌ BAD: Unclear, inconsistent names
git checkout -b fix
git checkout -b Feature/UserAuth
git checkout -b johns-branch

# ✅ GOOD: Clear, systematic naming
git checkout -b fix/456-login-timeout
git checkout -b feature/123-oauth-integration
git checkout -b hotfix/789-payment-processing
```

## Automation Patterns

```bash
# Delete merged features
git branch -r --merged main | grep 'origin/feature/' | sed 's/origin\///' | xargs -n 1 git push origin --delete

# Fetch namespace
git fetch origin 'refs/heads/feature/*:refs/remotes/origin/feature/*'

# Find stale experiments
git for-each-ref --format='%(refname:short) %(committerdate:relative)' 'refs/remotes/origin/experiment/' | grep -E 'months|years'
```

## Performance Benefits

- Hierarchical refs reduce network overhead during fetch
- Namespace organization improves packed-refs compression
- Filtering reduces refs Git must examine
- Directory structure improves filesystem caching

## Related Bindings

- [trunk-based-development](./trunk-based-development.md): Short-lived branches benefit from clear namespace organization.

- [automated-release-workflow](./automated-release-workflow.md): Release namespaces enable automated version management.

- [merge-strategy-selection](./merge-strategy-selection.md): Branch namespaces help determine appropriate merge strategies.

- [pull-request-workflow](./pull-request-workflow.md): Consistent naming improves PR automation and review processes.

- [git-hooks-automation](../../../core/git-hooks-automation.md): Hooks can enforce namespace conventions automatically.
