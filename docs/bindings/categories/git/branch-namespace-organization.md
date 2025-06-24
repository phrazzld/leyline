---
id: branch-namespace-organization
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: distributed-first
enforced_by: 'git hooks, branch protection rules, CI validation'
---
# Binding: Organize Branch Namespaces Systematically

Structure branch names using hierarchical namespaces that convey intent, ownership, and lifecycle. Use consistent patterns that enable efficient ref operations, clear team communication, and automated workflow integration.

## Rationale

Git stores branches as refs—simple files containing commit SHAs. This minimalist design provides maximum flexibility but no inherent organization. Without systematic naming, repositories devolve into chaos with branches like "fix", "test2", "johns-work", making it impossible to understand purpose, ownership, or status.

From a systems perspective, well-organized namespaces provide multiple benefits. Git's ref storage uses the filesystem, so hierarchical names like "feature/auth/oauth" create directory structures that improve performance for large numbers of branches. Many Git operations accept ref patterns, so consistent namespacing enables powerful automation—deleting all merged feature branches, protecting all release branches, or fetching only specific team's work.

More importantly, branch names are communication tools. A branch named "feature/123-user-authentication" immediately conveys its purpose, associated issue, and lifecycle stage. This reduces cognitive overhead and enables developers to work efficiently even in repositories with hundreds of active branches.

The distributed nature of Git makes namespace organization even more critical. Without central coordination, consistent naming conventions are the only way to maintain order across multiple remotes and developers.

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

**Git Configuration for Branch Namespaces:**

```bash
#!/bin/bash
# configure-branch-namespaces.sh

# Prevent direct creation of improperly named branches
git config branch.autosetupmerge always
git config branch.autosetuprebase always

# Configure fetch to prune deleted remote branches
git config remote.origin.prune true

# Set up branch namespace shortcuts
git config alias.fb '!f() { git checkout -b feature/$1; }; f'
git config alias.hf '!f() { git checkout -b hotfix/$1; }; f'
git config alias.fx '!f() { git checkout -b fix/$1; }; f'

# List branches by namespace
git config alias.features 'branch -r --list "origin/feature/*"'
git config alias.fixes 'branch -r --list "origin/fix/*"'
git config alias.releases 'branch -r --list "origin/release/*"'

# Cleanup merged branches by namespace
git config alias.cleanup '!f() { git branch --merged | grep "^  $1/" | xargs -n 1 git branch -d; }; f'
```

**Pre-receive Hook for Branch Validation:**

```bash
#!/bin/bash
# .git/hooks/pre-receive - Validate branch names

while read oldrev newrev refname; do
    # Extract branch name
    branch=$(echo $refname | sed 's/refs\/heads\///')

    # Skip deletions
    if [ "$newrev" = "0000000000000000000000000000000000000000" ]; then
        continue
    fi

    # Validate branch name format
    if ! echo "$branch" | grep -qE '^(feature|fix|hotfix|release|chore|experiment|revert)/[a-z0-9-]+$'; then
        echo "❌ Invalid branch name: $branch"
        echo "Expected format: <type>/<issue>-<description>"
        echo "Valid types: feature, fix, hotfix, release, chore, experiment, revert"
        echo "Example: feature/123-user-authentication"
        exit 1
    fi

    # Check length
    if [ ${#branch} -gt 60 ]; then
        echo "❌ Branch name too long: $branch (${#branch} chars)"
        echo "Maximum length: 60 characters"
        exit 1
    fi

    # Prevent reserved names
    if [[ "$branch" =~ ^(main|master|develop|staging|production)$ ]]; then
        echo "❌ Cannot create branch with reserved name: $branch"
        exit 1
    fi
done
```

**Automated Branch Management:**

```bash
#!/bin/bash
# branch-manager.sh - Automated branch namespace management

# Function to analyze branch namespaces
analyze_branches() {
    echo "📊 Branch Namespace Analysis"
    echo "============================"

    for namespace in feature fix hotfix release chore experiment; do
        count=$(git branch -r | grep -c "origin/$namespace/")
        echo "$namespace: $count branches"
    done

    # Find old branches
    echo ""
    echo "⚠️  Branches older than 30 days:"
    for branch in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin/); do
        age=$(git log -1 --format=%cr "$branch" 2>/dev/null | head -1)
        if [[ $age == *"month"* ]] || [[ $age == *"year"* ]]; then
            echo "  $branch ($age)"
        fi
    done
}

# Function to clean up merged branches
cleanup_merged() {
    echo "🧹 Cleaning up merged branches..."

    for namespace in feature fix chore experiment; do
        echo "Checking $namespace branches..."
        for branch in $(git branch -r --merged origin/main | grep "origin/$namespace/"); do
            branch_name=${branch#origin/}
            echo "  Deleting $branch_name"
            git push origin --delete "$branch_name"
        done
    done
}

# Function to archive old branches
archive_old_branches() {
    archive_date=$(date -v-90d +%Y-%m-%d)
    echo "📦 Archiving branches older than $archive_date..."

    for branch in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin/); do
        last_commit=$(git log -1 --format=%cd --date=short "$branch" 2>/dev/null)
        if [[ "$last_commit" < "$archive_date" ]]; then
            branch_name=${branch#origin/}
            tag_name="archive/$branch_name-$(date +%Y%m%d)"
            echo "  Archiving $branch_name as $tag_name"
            git tag "$tag_name" "$branch"
            git push origin "$tag_name"
            git push origin --delete "$branch_name"
        fi
    done
}

# Main menu
case "$1" in
    analyze)
        analyze_branches
        ;;
    cleanup)
        cleanup_merged
        ;;
    archive)
        archive_old_branches
        ;;
    *)
        echo "Usage: $0 {analyze|cleanup|archive}"
        exit 1
        ;;
esac
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
# ❌ BAD: Unclear branch names
git checkout -b fix
git checkout -b test-something
git checkout -b johns-branch
git checkout -b new-stuff

# ✅ GOOD: Clear, systematic names
git checkout -b fix/456-login-timeout
git checkout -b feature/123-oauth-integration
git checkout -b hotfix/789-payment-processing
git checkout -b experiment/websocket-transport
```

```bash
# ❌ BAD: Inconsistent naming
git branch -r
  origin/Feature/UserAuth
  origin/bugfix_login
  origin/RELEASE-2.0
  origin/dev-mary-work

# ✅ GOOD: Consistent namespace organization
git branch -r
  origin/feature/123-user-authentication
  origin/feature/124-password-reset
  origin/fix/456-login-validation
  origin/release/2.0.0
```

```bash
# ❌ BAD: Personal namespaces in shared repo
git checkout -b john/working-on-stuff
git checkout -b mary/my-feature

# ✅ GOOD: Purpose-driven namespaces
git checkout -b feature/890-dashboard-redesign
git checkout -b fix/891-chart-rendering
```

## Namespace Patterns for Automation

```bash
# Delete all merged feature branches
git branch -r --merged main |
  grep 'origin/feature/' |
  sed 's/origin\///' |
  xargs -n 1 git push origin --delete

# Fetch only specific namespace
git fetch origin 'refs/heads/feature/*:refs/remotes/origin/feature/*'

# List all hotfixes
git for-each-ref --format='%(refname:short)' 'refs/remotes/origin/hotfix/'

# Find stale experiment branches
git for-each-ref --format='%(refname:short) %(committerdate:relative)' \
  'refs/remotes/origin/experiment/' |
  grep -E 'months|years'
```

## Performance Benefits

Organized namespaces improve Git performance:

- **Ref Advertisement**: Hierarchical refs reduce network overhead during fetch
- **Packed Refs**: Namespace organization improves packed-refs compression
- **Ref Iteration**: Namespace filtering reduces refs Git must examine
- **Filesystem Cache**: Directory structure improves filesystem caching

## Related Bindings

- [trunk-based-development](./trunk-based-development.md): Short-lived branches benefit from clear namespace organization.

- [automated-release-workflow](./automated-release-workflow.md): Release namespaces enable automated version management.

- [merge-strategy-selection](./merge-strategy-selection.md): Branch namespaces help determine appropriate merge strategies.

- [pull-request-workflow](./pull-request-workflow.md): Consistent naming improves PR automation and review processes.

- [git-hooks-automation](../../../core/git-hooks-automation.md): Hooks can enforce namespace conventions automatically.
