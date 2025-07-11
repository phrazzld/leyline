---
id: commit-message-conventions
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: git-workflow-conventions
enforced_by: 'git hooks, commitlint, CI validation, commit templates'
---
# Binding: Write Meaningful, Structured Commit Messages

Adopt Conventional Commits as your team's commit message standard, transforming commits from cryptic one-liners into structured, meaningful records that enable automation and improve collaboration. Like Rails' convention for RESTful routes, this removes debates about commit format while enabling powerful tooling.

## Rationale

This binding implements our Git workflow conventions tenet by establishing Conventional Commits as the default standard. Just as Rails made the opinionated choice to use REST conventions for routing, we make the opinionated choice to use Conventional Commits for version control. This isn't about being pedantic—it's about enabling automation and making commit history genuinely useful.

The power of structured commit messages extends far beyond aesthetics. When every commit follows a predictable pattern, you can automatically generate changelogs that users actually want to read. You can determine version bumps without human intervention. You can trace the evolution of features through git history. You can even automatically close issues and notify stakeholders. All of this automation flows from the simple decision to structure your commit messages consistently.

Think of commit messages like package labels in a warehouse. Unstructured commits are like packages with handwritten notes—you might understand what "fix stuff" means today, but six months later it's meaningless. Conventional commits are like packages with standardized barcodes—scannable, sortable, and processable by automated systems. The small effort of proper labeling pays massive dividends in organizational efficiency.

## Rule Definition

This binding establishes Conventional Commits as the team standard:

- **Commit Format**: Every commit must follow this pattern:
  ```
  <type>(<scope>): <subject>

  [optional body]

  [optional footer(s)]
  ```

- **Standard Types**: Use only these commit types:
  - `feat`: New feature (triggers MINOR version bump)
  - `fix`: Bug fix (triggers PATCH version bump)
  - `docs`: Documentation only changes
  - `style`: Code style changes (formatting, missing semicolons, etc)
  - `refactor`: Code changes that neither fix bugs nor add features
  - `perf`: Performance improvements
  - `test`: Adding or updating tests
  - `build`: Changes to build system or dependencies
  - `ci`: Changes to CI configuration
  - `chore`: Other changes that don't modify src or test files
  - `revert`: Reverts a previous commit

- **Breaking Changes**: Indicate breaking changes clearly:
  - Add `!` after type/scope: `feat!:` or `feat(api)!:`
  - Include `BREAKING CHANGE:` in the footer
  - Breaking changes trigger MAJOR version bumps

- **Scope Guidelines**: Keep scopes consistent and meaningful:
  - Use component names: `feat(auth):`, `fix(api):`
  - Use feature areas: `docs(readme):`, `test(e2e):`
  - Keep scopes short and lowercase

- **Subject Rules**: Write clear, imperative subjects:
  - Use imperative mood: "add" not "added" or "adds"
  - Don't capitalize the first letter
  - No period at the end
  - Limit to 50 characters
  - Complete the sentence: "If applied, this commit will..."

- **Body Guidelines**: Provide context when needed:
  - Explain what and why, not how
  - Wrap at 72 characters
  - Separate from subject with blank line
  - Use bullet points for multiple items

## Practical Implementation

Here's how to implement commit conventions effectively:

1. **Install Commit Validation Tools**: Enforce conventions automatically

   ```bash
   # Install commitlint
   npm install --save-dev @commitlint/cli @commitlint/config-conventional

   # Configure commitlint
   echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js

   # Install husky for git hooks
   npm install --save-dev husky
   npx husky install

   # Add commit-msg hook
   npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
   ```

2. **Provide Interactive Commit Tool**: Make it easy to follow conventions

   ```bash
   # Install commitizen
   npm install --save-dev commitizen cz-conventional-changelog

   # Configure commitizen
   echo '{"path": "cz-conventional-changelog"}' > .czrc

   # Add npm script
   npm pkg set scripts.commit="cz"

   # Usage
   npm run commit  # Interactive commit message creation
   ```

3. **Create Commit Message Template**: Guide developers with examples

   ```bash
   # .gitmessage
   # <type>(<scope>): <subject>
   #
   # <body>
   #
   # <footer>

   # Example:
   # feat(auth): add OAuth2 login support
   #
   # Implemented GitHub and Google OAuth providers with
   # automatic account linking for existing users.
   #
   # Closes #123

   # Configure git to use template
   git config --local commit.template .gitmessage
   ```

4. **Set Up Automated Changelog**: Leverage structured commits

   ```json
   // package.json
   {
     "scripts": {
       "version": "conventional-changelog -p angular -i CHANGELOG.md -s && git add CHANGELOG.md",
       "release": "standard-version",
       "release:minor": "standard-version --release-as minor",
       "release:patch": "standard-version --release-as patch",
       "release:major": "standard-version --release-as major"
     }
   }
   ```

5. **Create Git Aliases**: Streamline common commit patterns

   ```bash
   # Git aliases for conventional commits
   git config --global alias.feat '!f() { git commit -m "feat: $1"; }; f'
   git config --global alias.fix '!f() { git commit -m "fix: $1"; }; f'
   git config --global alias.docs '!f() { git commit -m "docs: $1"; }; f'
   git config --global alias.style '!f() { git commit -m "style: $1"; }; f'
   git config --global alias.refactor '!f() { git commit -m "refactor: $1"; }; f'
   git config --global alias.test '!f() { git commit -m "test: $1"; }; f'
   git config --global alias.chore '!f() { git commit -m "chore: $1"; }; f'

   # Usage
   git feat "add user authentication"
   git fix "resolve memory leak in data processor"
   ```

## Examples

```bash
# ❌ BAD: Vague, unstructured commits
git commit -m "fix"
git commit -m "Updated stuff"
git commit -m "JIRA-1234"
git commit -m "WIP"
git commit -m "done"

# ✅ GOOD: Clear, structured commits
git commit -m "fix(auth): resolve token expiration race condition"
git commit -m "feat(api): add pagination to user endpoints"
git commit -m "docs(readme): update installation instructions"
git commit -m "refactor(utils): extract common validation logic"
git commit -m "test(e2e): add coverage for checkout flow"
```

```bash
# ❌ BAD: No context for breaking changes
git commit -m "change api response format"

# ✅ GOOD: Clear breaking change indication
git commit -m "feat(api)!: change user endpoint response format

BREAKING CHANGE: The /api/users endpoint now returns
data in a paginated wrapper object instead of a raw array.

Migration guide:
- Old: response.data -> [{user}]
- New: response.data -> {users: [{user}], total: n}"
```

```bash
# ❌ BAD: Multiple changes in one commit
git commit -m "fix login bug, update styles, add tests"

# ✅ GOOD: Atomic commits with clear purpose
git commit -m "fix(auth): prevent duplicate login requests"
git commit -m "style(login): update button colors for accessibility"
git commit -m "test(auth): add test coverage for login flow"
```

## Related Bindings

- [../../../core/require-conventional-commits.md](../../../core/require-conventional-commits.md): Core binding that this extends with category-specific guidance

- [automated-release-workflow.md](automated-release-workflow.md): Conventional commits enable fully automated versioning and releases

- [branch-naming-standards.md](branch-naming-standards.md): Consistent branch names complement consistent commit messages

- [git-hooks-enforcement.md](git-hooks-enforcement.md): Git hooks enforce commit conventions at the local level

- [../../../core/automate-changelog.md](../../../core/automate-changelog.md): Automated changelogs depend on structured commit messages

- [../../../core/semantic-versioning.md](../../../core/semantic-versioning.md): Commit types map directly to semantic version bumps
