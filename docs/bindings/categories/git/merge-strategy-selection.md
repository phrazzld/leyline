---
id: merge-strategy-selection
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: content-addressable-history
enforced_by: 'git configuration, team conventions, automated tooling'
---
# Binding: Select Merge Strategies Algorithmically

Choose Git merge strategies based on objective criteria rather than personal preference or habit. Apply rebase, merge, or squash systematically based on branch lifetime, change scope, and the intended use of the resulting history.

## Rationale

Arbitrary merge strategy selection creates inconsistent history that's harder to navigate and debug. Each strategy optimizes for different constraints:
- **Rebase**: Linear history, O(log n) debugging
- **Merge**: Preserves temporal relationships and collaboration context
- **Squash**: Logical atomicity, clean mainline

Optimal strategy depends on change characteristics, not developer preference.

## Rule Definition

**Algorithm:**
```
IF branch_lifetime <= 3 days AND single_author THEN REBASE
ELSE IF external_contribution OR cross_team_collaboration THEN MERGE
ELSE IF multiple_fixup_commits OR experimental_changes THEN SQUASH
ELSE IF preserving_context_critical THEN MERGE
ELSE DEFAULT to REBASE
```

**Use REBASE**: <3 days, single author, linear commits, atomic structure
**Use MERGE**: External contributions, cross-team, context preservation
**Use SQUASH**: Fixup commits, experimental changes, cleanup needed

- **Use MERGE when:**
  - Multiple authors collaborated
  - External pull requests
  - Branch represents significant feature work (>1 week)
  - Preserving development context is valuable
  - Parallel development streams need documentation

- **Use SQUASH when:**
  - Multiple small fix commits ("fixed typo", "update", "WIP")
  - Experimental development with many dead ends
  - PR feedback resulted in many adjustment commits
  - Final result matters more than journey
  - Cleaning up before adding to permanent history

**Enforcement:**
- Document strategy choice in PR description
- Automate strategy recommendation in PR templates
- Configure repository defaults based on project type
- Monitor history quality metrics

## Practical Implementation

**Strategy Recommendation Script:**

```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
BASE_BRANCH=${1:-main}

BRANCH_AGE_DAYS=$(( ($(date +%s) - $(git log -1 --format=%ct $(git merge-base HEAD $BASE_BRANCH))) / 86400 ))
AUTHOR_COUNT=$(git log $BASE_BRANCH..HEAD --format=%ae | sort -u | wc -l)
COMMIT_COUNT=$(git rev-list --count $BASE_BRANCH..HEAD)
FIXUP_COMMITS=$(git log $BASE_BRANCH..HEAD --oneline | grep -iE "(fix|typo|wip)" | wc -l)
FIXUP_RATIO=$(echo "scale=2; $FIXUP_COMMITS / $COMMIT_COUNT" | bc)

echo "Branch: $BRANCH | Age: $BRANCH_AGE_DAYS days | Authors: $AUTHOR_COUNT | Commits: $COMMIT_COUNT | Fixup: $FIXUP_RATIO"

if [ $BRANCH_AGE_DAYS -le 3 ] && [ $AUTHOR_COUNT -eq 1 ]; then
    echo "REBASE: git rebase $BASE_BRANCH"
elif [ $AUTHOR_COUNT -gt 1 ]; then
    echo "MERGE: git merge --no-ff $BRANCH"
elif (( $(echo "$FIXUP_RATIO > 0.5" | bc -l) )); then
    echo "SQUASH: git merge --squash $BRANCH"
else
    echo "REBASE: git rebase $BASE_BRANCH"
fi
```

**PR Template:**

```markdown
## Merge Strategy
- [ ] **REBASE** - <3 days, single author
- [ ] **MERGE** - Multi-author/collaboration
- [ ] **SQUASH** - Fixup commits/cleanup
```

**Git Aliases:**

```bash
git config --global alias.integrate-rebase '!f() { git fetch && git rebase origin/main && git push --force-with-lease; }; f'
git config --global alias.integrate-merge '!f() { git fetch && git merge origin/main && git push; }; f'
git config --global alias.integrate-squash '!f() { git checkout main && git merge --squash $1 && git commit; }; f'
```

**Repository Configuration by Project Type:**

```yaml
# .github/merge-strategy.yml
project_type: web_application
default_strategy: rebase

rules:
  - name: external_contributions
    condition: author_not_in_team
    strategy: merge

  - name: hotfixes
    condition: target_branch == "production"
    strategy: rebase
    require_squash: true

  - name: feature_branches
    condition: branch_prefix == "feature/"
    strategy: rebase
    max_age_days: 7

  - name: experimental
    condition: branch_prefix == "experiment/"
    strategy: squash
```

## Examples

```bash
# ❌ BAD: Arbitrary strategy choice
git checkout feature/update-ui
git merge main  # Why merge? No clear reason

# ✅ GOOD: Strategy based on analysis
git checkout feature/update-ui
# Analysis: 2 days old, 1 author, 3 atomic commits
git rebase main  # Linear history for short feature
```

```bash
# ❌ BAD: Squashing collaborative work
git checkout feature/team-refactor
# 5 authors, 50 commits over 2 weeks
git merge --squash  # Loses attribution and context

# ✅ GOOD: Preserving collaboration context
git checkout main
git merge --no-ff feature/team-refactor
# Merge commit documents parallel development
```

```bash
# ❌ BAD: Rebasing experimental work
git checkout experiment/new-approach
# 30 commits including "try this", "revert", "another attempt"
git rebase main  # Pollutes history with noise

# ✅ GOOD: Squashing experimental work
git checkout main
git merge --squash experiment/new-approach
git commit -m "feat: implement new approach (after experimentation)"
# Clean history shows final result
```

## Performance Impact

Different strategies have measurable performance impacts:

```bash
# Linear history (rebase): Optimal for bisect
git bisect start
# O(log n) iterations to find bug

# Merge-heavy history: Slower bisect
git bisect start
# O(log n * m) where m is merge complexity

# Squashed history: Fast operations but less granular
git log --oneline
# Fewer commits to process, but less debugging detail
```

## Strategy Decision Tree

```
Start
  │
  ├─> External PR? ──Yes──> MERGE (preserve attribution)
  │        │
  │        No
  │        ↓
  ├─> Multi-author? ──Yes──> MERGE (preserve collaboration)
  │        │
  │        No
  │        ↓
  ├─> Many fixups? ──Yes──> SQUASH (clean history)
  │        │
  │        No
  │        ↓
  ├─> Long-lived? ──Yes──> MERGE (document parallel work)
  │        │
  │        No
  │        ↓
  └─> REBASE (default for linear history)
```

## Related Bindings

- [linear-history-optimization](./linear-history-optimization.md): Provides detailed guidance on maintaining linear history through rebase workflows.

- [atomic-commits](./atomic-commits.md): Well-structured atomic commits make rebase strategies more effective.

- [trunk-based-development](./trunk-based-development.md): Short-lived branches in trunk-based development typically benefit from rebase strategy.

- [commit-message-conventions](./commit-message-conventions.md): Clear commit messages help determine appropriate merge strategy.

- [pull-request-workflow](./pull-request-workflow.md): PR templates can enforce strategy selection based on objective criteria.
