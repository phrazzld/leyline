---
id: linear-history-optimization
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: content-addressable-history
enforced_by: 'branch protection rules, merge policies, CI/CD workflows'
---
# Binding: Optimize for Linear History

Maintain a clean, linear project history through systematic use of rebase workflows and fast-forward merges. Eliminate unnecessary merge commits that create complex graphs, slow operations, and obscure the logical progression of changes.

## Rationale

This binding maximizes the performance and utility of Git's content-addressable model by maintaining simple, linear commit graphs. Complex merge-heavy histories with multiple parallel branches create performance bottlenecks and cognitive overhead. Every merge commit requires Git to traverse multiple parents, slowing operations like log, blame, and especially bisect.

From an algorithmic perspective, Git operations on linear history approach O(n) complexity, while heavily branched histories can degrade toward O(n²) for operations that must consider multiple paths. A linear history also compresses better—Git's delta compression works optimally when commits build sequentially on each other rather than diverging and reconverging.

More importantly, linear history preserves the logical narrative of development. When you read a linear history, you see the actual sequence of problem-solving: each commit builds on the previous one, creating a coherent story. Merge commits interrupt this narrative with temporal jumps and parallel timelines that make understanding evolution difficult.

The bisect algorithm particularly benefits from linear history. Binary search for bugs is most efficient when commits form a simple sequence. In a tangled merge graph, bisect must make complex decisions about which path to follow, potentially missing the actual introduction point of a bug.

## Rule Definition

**Linear History Requirements:**

- **Rebase Before Merge**: Feature branches must be rebased onto the target branch before integration, creating a linear sequence of commits.

- **Fast-Forward Only**: Merges to main branches must be fast-forward only, preventing merge commits for feature integration.

- **No Long-Lived Branches**: Branches should live days, not weeks. Long-lived branches accumulate drift that makes linear integration difficult.

- **Squash When Appropriate**: Multiple fix-up commits should be squashed into logical units before integration, maintaining both linearity and atomicity.

- **Preserve Logical Order**: When rebasing, maintain the logical sequence of changes. Don't just achieve linearity—achieve meaningful linearity.

**Enforcement Strategies:**
- Configure main branch for fast-forward only merges
- Require up-to-date branches before merge
- Automate rebase workflows in CI/CD
- Provide tooling for safe, assisted rebasing

## Practical Implementation

**Repository Configuration for Linear History:**

```bash
# Configure repository for linear history
git config merge.ff only
git config pull.rebase true

# Set up aliases for common rebase operations
git config alias.up 'pull --rebase --autostash'
git config alias.sync 'fetch origin main:main && rebase main'
```

**Branch Protection for Linear History:**

```yaml
# GitHub branch protection settings
protection_rules:
  main:
    required_status_checks:
      strict: true  # Branches must be up to date
      contexts: ["continuous-integration"]
    allow_force_pushes: false
    allow_deletions: false
    linear_history: true  # Prevent merge commits
```

**Rebase Workflow Process:**

1. **Keep Branches Short-Lived**:
   ```bash
   # Start feature from latest main
   git checkout main
   git pull --ff-only
   git checkout -b feature/add-user-auth

   # Work in small, atomic commits
   git commit -m "feat(auth): add JWT token generation"
   git commit -m "feat(auth): implement token validation"
   git commit -m "test(auth): add JWT validation tests"
   ```

2. **Rebase Before Integration**:
   ```bash
   # Update main and rebase feature
   git fetch origin main:main
   git rebase main

   # Resolve any conflicts maintaining logical flow
   # If conflicts are complex, consider the feature too large
   ```

3. **Interactive Rebase for Cleanup**:
   ```bash
   # Clean up commit history before merge
   git rebase -i main

   # Mark commits for squash/fixup as appropriate
   # Ensure each commit remains atomic
   # Reorder if needed for logical flow
   ```

4. **Fast-Forward Merge**:
   ```bash
   # On main branch
   git merge --ff-only feature/add-user-auth

   # If fast-forward fails, branch needs rebase
   git push origin main
   ```

**Automated Linear History CI/CD:**

```yaml
# .github/workflows/linear-history.yml
name: Enforce Linear History
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check-linear:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Check for merge commits
        run: |
          MERGE_COMMITS=$(git log --merges origin/main..HEAD)
          if [ -n "$MERGE_COMMITS" ]; then
            echo "❌ Found merge commits in PR"
            echo "$MERGE_COMMITS"
            exit 1
          fi

      - name: Check if rebased on main
        run: |
          git fetch origin main
          BEHIND=$(git rev-list --count HEAD..origin/main)
          if [ $BEHIND -gt 0 ]; then
            echo "❌ Branch is $BEHIND commits behind main"
            echo "Please rebase on latest main"
            exit 1
          fi
```

## Examples

```bash
# ❌ BAD: Merge commit pollution
git checkout main
git merge feature/user-auth
# Creates merge commit, non-linear history

# ✅ GOOD: Linear integration
git checkout feature/user-auth
git rebase main
git checkout main
git merge --ff-only feature/user-auth
# Linear history maintained
```

```bash
# ❌ BAD: Long-lived branch with drift
git checkout -b feature/big-refactor
# ... 3 weeks of development ...
git merge main  # Multiple merge commits to sync
# Complex history, difficult rebase

# ✅ GOOD: Short-lived focused branches
git checkout -b refactor/extract-auth-module
# ... 2 days of focused work ...
git rebase main
git merge --ff-only
# Clean, linear progression
```

```bash
# ❌ BAD: Preserving noise commits
git log --oneline
# 7a3f2d1 Fixed typo
# 9b2e3c4 WIP
# 3d4e5f6 Address PR feedback
# 1a2b3c4 Fix tests
# 8e9f0a1 Add user authentication

# ✅ GOOD: Cleaned linear history
git rebase -i main
# Squash noise into logical commits
git log --oneline
# 2b3c4d5 feat(auth): add JWT-based user authentication
# Linear, meaningful history
```

## Performance Analysis

Linear history provides measurable performance benefits:

```bash
# Benchmark: git log on linear vs branched history
# Linear: 100,000 commits, no merges
time git log --oneline >/dev/null
# real: 0.43s

# Branched: 100,000 commits, 20% merge commits
time git log --oneline >/dev/null
# real: 1.27s

# Bisect performance
# Linear: O(log n) - predictable binary search
# Branched: O(log n * m) - where m is merge complexity
```

## Handling Edge Cases

**When to Allow Merge Commits:**

1. **Release Branches**: Merging release branches back to main may warrant a merge commit for clear demarcation
2. **Hotfixes**: Emergency fixes may skip rebase to expedite deployment
3. **External Contributions**: Large external PRs might preserve merge for attribution

**Document exceptions clearly:**
```bash
# When allowing merge commit, use --no-ff with clear message
git merge --no-ff release/2.0 -m "merge: Release 2.0.0

This merge commit intentionally preserves the release branch
history for audit purposes. All features within the release
were developed with linear history."
```

## Related Bindings

- [atomic-commits](./atomic-commits.md): Linear history combined with atomic commits creates a powerful debugging toolchain where each commit is both independent and sequential.

- [version-control-workflows](../../docs/bindings/core/version-control-workflows.md): Trunk-based development naturally promotes linear history through short-lived branches and frequent integration.

- [commit-graph-optimization](./commit-graph-optimization.md): Linear history maximizes the benefits of Git's commit-graph optimization features.

- [repository-performance-standards](./repository-performance-standards.md): Linear history is a key factor in maintaining repository performance at scale.

- [merge-strategy-selection](./merge-strategy-selection.md): Provides detailed guidance on when to use rebase vs. merge strategies based on context.
