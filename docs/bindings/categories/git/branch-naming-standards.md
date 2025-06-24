---
id: branch-naming-standards
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-workflow-conventions
enforced_by: 'git hooks, branch protection rules, CI validation'
---
# Binding: Use Predictable Branch Naming Patterns

Establish consistent branch naming conventions that make repository navigation effortless and enable powerful automation. Like Rails' RESTful resource naming, predictable branch names eliminate guesswork and enable tooling to understand your workflow automatically.

## Rationale

This binding implements our Git workflow conventions tenet by establishing clear, predictable branch naming patterns. Just as Rails chose plural resource names and RESTful routes as conventions, we choose structured branch names that communicate intent at a glance. This isn't bureaucracy—it's developer ergonomics.

When branch names follow predictable patterns, the entire team benefits. Developers can immediately understand what any branch contains without diving into its commits. Automated tools can parse branch names to link issues, categorize work, and even route pull requests to appropriate reviewers. Project managers can see work in progress at a glance. The branch list becomes a readable project status board rather than a cryptic mess of developer initials and timestamps.

Think of branch names like street addresses. Without a system, you'd have branches named like "john-work" or "new-stuff"—as helpful as naming streets "that one with the trees." With conventions, you have "feature/123-user-authentication"—as clear as "123 Main Street." The standardization enables both human navigation and automated delivery (CI/CD) systems to work efficiently.

## Rule Definition

This binding establishes systematic branch naming:

- **Branch Naming Format**: Use the pattern `<type>/<issue>-<description>`
  - Type: Indicates the purpose of the branch
  - Issue: Links to your issue tracking system
  - Description: Brief, kebab-case summary

- **Standard Branch Types**:
  - `feature/` - New features or enhancements
  - `fix/` - Bug fixes
  - `hotfix/` - Urgent production fixes
  - `docs/` - Documentation updates
  - `refactor/` - Code refactoring
  - `test/` - Test additions or updates
  - `chore/` - Maintenance tasks
  - `experiment/` - Experimental code not intended for production

- **Issue Reference Requirements**:
  - Always include issue/ticket number when available
  - Format: `<issue-tracker>-<number>` or just `<number>`
  - Examples: `jira-1234`, `gh-567`, `123`

- **Description Guidelines**:
  - Use kebab-case (words-separated-by-dashes)
  - Keep it brief but descriptive (3-5 words)
  - Use imperative mood matching the work
  - Avoid generic terms like "update" or "fix"

- **Special Branches**:
  - `main` or `master` - Primary branch
  - `develop` - Development branch (if not using trunk-based)
  - `release/<version>` - Release preparation branches
  - Never use personal names or dates in branch names

- **Validation Rules**:
  - Lowercase only
  - No spaces or special characters except `/` and `-`
  - Maximum 50 characters total length
  - Must match the regex pattern: `^(feature|fix|hotfix|docs|refactor|test|chore|experiment|release)\/[a-z0-9-]+$`

## Practical Implementation

Here's how to implement branch naming standards effectively:

1. **Create Git Aliases for Branch Creation**: Make conventions effortless

   ```bash
   # ~/.gitconfig or .git/config
   [alias]
     # Branch creation with issue number
     feature = "!f() { git checkout -b feature/$1-$2; }; f"
     fix = "!f() { git checkout -b fix/$1-$2; }; f"
     docs = "!f() { git checkout -b docs/$1-$2; }; f"
     chore = "!f() { git checkout -b chore/$1-$2; }; f"

     # Branch creation without issue number
     experiment = "!f() { git checkout -b experiment/$1; }; f"
     hotfix = "!f() { git checkout -b hotfix/$1; }; f"

   # Usage
   git feature 123 user-authentication
   git fix 456 memory-leak
   git experiment new-architecture
   ```

2. **Implement Branch Name Validation**: Enforce standards automatically

   ```bash
   #!/bin/bash
   # .githooks/pre-push

   # Validate branch name before push
   branch=$(git rev-parse --abbrev-ref HEAD)
   valid_pattern="^(main|master|develop|(feature|fix|hotfix|docs|refactor|test|chore|experiment|release)\/[a-z0-9-]+)$"

   if [[ ! "$branch" =~ $valid_pattern ]]; then
     echo "❌ Branch name '$branch' does not follow naming convention!"
     echo "📋 Expected format: <type>/<issue>-<description>"
     echo "📋 Valid types: feature|fix|hotfix|docs|refactor|test|chore|experiment"
     echo "📋 Example: feature/123-user-authentication"
     exit 1
   fi
   ```

3. **Configure Branch Protection Patterns**: Use naming for automation

   ```yaml
   # .github/settings.yml
   branches:
     - name: main
       protection:
         required_status_checks:
           contexts: ["build", "test"]
         required_pull_request_reviews:
           required_approving_review_count: 2

     # Auto-protection for release branches
     - name: "release/*"
       protection:
         required_status_checks:
           contexts: ["build", "test", "security-scan"]
         restrictions:
           teams: ["release-managers"]
   ```

4. **Automate PR Labels Based on Branch Names**: Link branches to workflows

   ```yaml
   # .github/workflows/pr-labeler.yml
   name: PR Labeler
   on:
     pull_request:
       types: [opened]

   jobs:
     label:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/labeler@v4
           with:
             configuration-path: .github/labeler.yml

   # .github/labeler.yml
   feature:
     - 'feature/*'
   bug:
     - 'fix/*'
     - 'hotfix/*'
   documentation:
     - 'docs/*'
   maintenance:
     - 'chore/*'
     - 'refactor/*'
   ```

5. **Create Branch Templates**: Provide clear examples

   ```markdown
   # docs/BRANCHING.md
   ## Branch Naming Examples

   ### Features
   - `feature/123-user-registration`
   - `feature/456-shopping-cart`
   - `feature/789-api-versioning`

   ### Fixes
   - `fix/234-login-timeout`
   - `fix/567-memory-leak`
   - `fix/890-data-validation`

   ### Documentation
   - `docs/345-api-guide`
   - `docs/678-setup-instructions`

   ### Experiments (no issue required)
   - `experiment/new-caching-strategy`
   - `experiment/graphql-api`
   ```

## Examples

```bash
# ❌ BAD: Unclear, inconsistent branch names
git checkout -b johns-work
git checkout -b fix-bug
git checkout -b new-feature
git checkout -b temp
git checkout -b JIRA-1234
git checkout -b feature_user_auth  # wrong separator

# ✅ GOOD: Clear, consistent branch names
git checkout -b feature/123-user-authentication
git checkout -b fix/456-payment-validation
git checkout -b docs/789-api-documentation
git checkout -b hotfix/890-critical-security-patch
git checkout -b experiment/websocket-integration
git checkout -b release/2.1.0
```

```bash
# ❌ BAD: Personal or time-based names
git checkout -b dave-monday
git checkout -b march-updates
git checkout -b v2-work

# ✅ GOOD: Purpose-driven names
git checkout -b feature/234-dashboard-redesign
git checkout -b fix/345-march-sales-report
git checkout -b feature/456-v2-api-endpoints
```

```bash
# ❌ BAD: Too vague or too detailed
git checkout -b update
git checkout -b fix-that-thing-where-users-cant-login-on-tuesdays

# ✅ GOOD: Balanced and descriptive
git checkout -b chore/567-dependency-updates
git checkout -b fix/678-tuesday-login-issue
```

## Related Bindings

- [trunk-based-development.md](trunk-based-development.md): Short branch names work well with short-lived branches

- [commit-message-conventions.md](commit-message-conventions.md): Branch names and commit messages work together to document work

- [pull-request-workflow.md](pull-request-workflow.md): Branch names enable automatic PR categorization and routing

- [git-hooks-enforcement.md](git-hooks-enforcement.md): Git hooks can enforce branch naming standards locally

- [automated-release-workflow.md](automated-release-workflow.md): Release branches follow naming conventions for automation

- [merge-strategy-conventions.md](merge-strategy-conventions.md): Branch types can determine appropriate merge strategies
