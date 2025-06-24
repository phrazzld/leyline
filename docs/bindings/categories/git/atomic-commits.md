---
id: atomic-commits
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: content-addressable-history
enforced_by: 'commit hooks, code review, CI validation'
---
# Binding: Enforce Atomic Commits

Structure every commit as a single, complete, reversible unit of change that transforms the repository from one valid state to another. Each commit must represent exactly one logical change with all its necessary parts.

## Rationale

This binding leverages Git's content-addressable architecture to create a history that serves as a powerful debugging and development tool. When commits are atomic—containing exactly one logical change with all necessary modifications—the repository history becomes a precise record of project evolution that enables surgical operations like bisecting, cherry-picking, and reverting.

Think of commits like database transactions. Just as a database transaction must be atomic (all-or-nothing), consistent (maintaining validity), isolated (independent), and durable (permanent once committed), Git commits should exhibit these same ACID properties. A commit that changes an API must include the implementation change, test updates, and documentation updates—all the modifications needed to maintain system consistency.

Non-atomic commits—those that mix multiple changes or split single changes across commits—create a history full of broken states. This defeats Git's powerful debugging tools. You cannot bisect to find a regression if commits contain broken intermediate states. You cannot cleanly revert a problematic change if it's tangled with unrelated modifications. You cannot cherry-pick a fix if it's incomplete without its companion commits.

The performance implications are significant too. Git's delta compression works best when related changes are grouped together. Atomic commits improve compression ratios and make operations like log, blame, and diff more efficient by maintaining logical locality.

## Rule Definition

**Atomic Commit Requirements:**

- **Single Logical Change**: Each commit must represent exactly one feature, bug fix, refactoring, or other logical change. If you need "and" to describe your commit, it's not atomic.

- **Complete Change**: The commit must include all modifications necessary for the change—source code, tests, documentation, configuration. Checking out any commit should yield a working system.

- **Independently Reversible**: Each commit must be revertable without breaking the system or requiring reversion of unrelated changes.

- **Build-Safe**: Every commit must compile and pass all existing tests. No commit should introduce a broken state, even temporarily.

- **Self-Contained Context**: The commit message must provide complete context for the change without requiring examination of other commits or external references.

**Enforcement Mechanisms:**
- Pre-commit hooks validate that changes are related
- CI ensures every commit builds independently
- Code review process checks for atomic boundaries
- Automated tools detect commits touching unrelated subsystems

## Practical Implementation

**Creating Atomic Commits:**

1. **Stage Changes Thoughtfully**: Use `git add -p` to stage specific hunks, ensuring only related changes are included:
   ```bash
   # Interactively stage parts of files
   git add -p

   # Stage specific lines while reviewing
   git add -i
   ```

2. **Split Mixed Work**: If you've made multiple changes, split them into separate commits:
   ```bash
   # Create first atomic commit
   git add src/auth.js tests/auth.test.js docs/auth.md
   git commit -m "feat(auth): add OAuth2 authentication support"

   # Create second atomic commit
   git add src/logging.js tests/logging.test.js
   git commit -m "fix(logging): prevent memory leak in log rotation"
   ```

3. **Use Fixup for Maintaining Atomicity**: When addressing review feedback, maintain atomicity:
   ```bash
   # Create a fixup commit
   git commit --fixup=<original-commit-sha>

   # Later, before merging
   git rebase -i --autosquash
   ```

4. **Validate Commit Completeness**: Before committing, verify the change is complete:
   ```bash
   # Stash unrelated changes
   git stash --keep-index

   # Run tests on staged changes only
   npm test

   # If tests pass, commit; then restore stashed changes
   git commit
   git stash pop
   ```

**Commit Message Structure for Atomic Commits:**

```
type(scope): concise description of the single change

Explain why this change is being made and what specific problem
it solves. For atomic commits, this should describe one coherent
modification to the system.

- Detail specific implementation decisions if non-obvious
- List all component changes (code, tests, docs) included
- Note any important limitations or follow-up work needed

Closes #123
```

**Pre-commit Validation Hook:**

```bash
#!/bin/bash
# .git/hooks/pre-commit - Validate commit atomicity

# Check for mixed subsystem changes
SUBSYSTEMS=$(git diff --cached --name-only | cut -d'/' -f1-2 | sort -u)
SUBSYSTEM_COUNT=$(echo "$SUBSYSTEMS" | wc -l)

if [ $SUBSYSTEM_COUNT -gt 2 ]; then
    echo "⚠️  Warning: Commit touches multiple subsystems:"
    echo "$SUBSYSTEMS"
    echo "Consider splitting into atomic commits."
    # Prompt for confirmation
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ensure tests pass with only staged changes
git stash -q --keep-index
npm test --silent
TEST_RESULT=$?
git stash pop -q
exit $TEST_RESULT
```

## Examples

```bash
# ❌ BAD: Mixed changes in one commit
git add .
git commit -m "Update authentication and fix logging bug"
# Problems: Cannot revert just the logging fix, bisect may land on broken auth state

# ✅ GOOD: Separate atomic commits
git add src/auth/*.js tests/auth/*.test.js docs/api/auth.md
git commit -m "feat(auth): implement JWT refresh token rotation"

git add src/utils/logger.js tests/utils/logger.test.js
git commit -m "fix(logging): correct timestamp formatting in UTC mode"
```

```bash
# ❌ BAD: Incomplete change
git add src/api/users.js
git commit -m "Add user validation"
# Missing: tests, error handling, documentation

# ✅ GOOD: Complete atomic change
git add src/api/users.js \
        src/api/errors.js \
        tests/api/users.test.js \
        docs/api/users.md
git commit -m "feat(api): add email validation for user registration

- Validates email format using RFC 5322 regex
- Returns 400 with specific error messages
- Includes unit tests for edge cases
- Updates API documentation with examples"
```

```bash
# ❌ BAD: Partial refactoring
git commit -m "Start refactoring database layer"
# Some modules updated, others still use old pattern

# ✅ GOOD: Complete refactoring in atomic chunks
git commit -m "refactor(db): extract connection pooling to separate module

Completes first phase of database layer refactoring:
- Moves pool management from inline to db/pool.js
- Updates all consumers to use new module
- Maintains backward compatibility
- Next: Extract query builder (tracked in #456)"
```

## Performance Benefits

Atomic commits directly improve Git performance:

- **Efficient Delta Compression**: Related changes in one commit compress better than scattered changes
- **Faster Operations**: `git log -p`, `git blame`, and `git show` operate on coherent change sets
- **Optimal Bisection**: Binary search for bugs works efficiently with atomic commits
- **Clean Cherry-picks**: Single-purpose commits transplant cleanly between branches

## Related Bindings

- [require-conventional-commits](../../docs/bindings/core/require-conventional-commits.md): Conventional commits provide structure for describing atomic changes. The type and scope naturally encourage thinking about change atomicity.

- [no-internal-mocking](../../docs/bindings/core/no-internal-mocking.md): Atomic commits often require refactoring to maintain testability, aligning with principles of testing without internal mocks.

- [continuous-refactoring](../../docs/bindings/core/continuous-refactoring.md): Small, atomic refactoring commits enable continuous improvement without disrupting feature development.

- [git-hooks-automation](../../docs/bindings/core/git-hooks-automation.md): Automated validation of commit atomicity through pre-commit hooks ensures consistent application of this binding.

- [version-control-workflows](../../docs/bindings/core/version-control-workflows.md): Trunk-based development with short-lived branches naturally encourages atomic commits by limiting scope.
