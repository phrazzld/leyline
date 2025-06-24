---
id: pull-request-workflow
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-workflow-conventions
enforced_by: 'PR templates, CODEOWNERS, branch protection, automated checks'
---
# Binding: Streamline Pull Requests Through Automation

Transform pull requests from bureaucratic checkpoints into efficient collaboration tools through templates, automation, and clear conventions. Like Rails' scaffold generators that create consistent CRUD interfaces, PR workflows should provide consistent, low-friction paths from code to production.

## Rationale

This binding implements our Git workflow conventions tenet by establishing streamlined, automated pull request workflows. Just as Rails recognized that most web applications need similar CRUD operations and provided generators to eliminate boilerplate, we recognize that most pull requests need similar reviews and checks, so we automate the repetitive parts while preserving valuable human insight.

Pull requests are where individual work becomes team achievement, but they're also where velocity goes to die if not properly managed. Manual PR processes create bottlenecks: waiting for reviewers, forgetting to run tests, missing documentation updates, or endless back-and-forth about style issues. Automated PR workflows eliminate this friction by handling the mechanical checks automatically, letting humans focus on architecture, logic, and knowledge sharing.

Think of PR automation like a pre-flight checklist for pilots. Pilots don't debate whether to check fuel levels or test control surfaces—the checklist ensures nothing is forgotten. Similarly, automated PR workflows ensure consistent quality checks without relying on human memory or discipline. The result is faster, safer deployments and more time for meaningful code review discussions.

## Rule Definition

This binding establishes efficient PR workflows:

- **PR Templates**: Standardize PR information
  - Description of changes and motivation
  - Testing performed and test coverage
  - Breaking changes and migration guides
  - Checklist for common requirements
  - Auto-linking to related issues

- **Automated Checks**: Validate before human review
  - CI/CD pipeline must pass (tests, linting, building)
  - Code coverage requirements met
  - Security scanning completed
  - Documentation builds successfully
  - Commit message validation

- **Review Assignment**: Route PRs intelligently
  - CODEOWNERS for automatic assignment
  - Round-robin for load balancing
  - Expertise-based routing
  - Skip review for trivial changes (with rules)

- **Merge Requirements**: Enforce quality gates
  - Required approvals (based on change scope)
  - Up-to-date with target branch
  - All conversations resolved
  - All checks passed
  - No merge until ready

- **PR Lifecycle**: Keep PRs moving
  - Draft PRs for early feedback
  - Automatic stale PR notifications
  - Auto-close abandoned PRs
  - Automatic conflict detection
  - Post-merge branch cleanup

- **Review Guidelines**: Focus human attention
  - Architecture and design decisions
  - Business logic correctness
  - Performance implications
  - Security considerations
  - Knowledge sharing opportunities

## Practical Implementation

Here's how to implement efficient PR workflows:

1. **Create Comprehensive PR Template**: Guide contributors

   ```markdown
   <!-- .github/pull_request_template.md -->
   ## Description
   Brief description of what this PR accomplishes.

   Fixes #(issue number)

   ## Type of Change
   - [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
   - [ ] ✨ New feature (non-breaking change that adds functionality)
   - [ ] 💥 Breaking change (fix or feature that breaks existing functionality)
   - [ ] 📚 Documentation update
   - [ ] 🎨 Code style update (formatting, renaming)
   - [ ] ♻️ Refactoring (no functional changes)
   - [ ] ⚡ Performance improvement
   - [ ] ✅ Test update
   - [ ] 🔧 Configuration change

   ## Testing
   - [ ] Unit tests pass locally
   - [ ] Integration tests pass locally
   - [ ] Manual testing completed
   - [ ] Added tests for new functionality

   ## Checklist
   - [ ] Code follows project style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex logic
   - [ ] Documentation updated if needed
   - [ ] No console.log or debug code
   - [ ] Breaking changes documented
   - [ ] Commits follow conventional format

   ## Screenshots (if applicable)
   <!-- Add screenshots for UI changes -->

   ## Additional Notes
   <!-- Any additional context for reviewers -->
   ```

2. **Configure CODEOWNERS**: Automate review assignment

   ```gitignore
   # .github/CODEOWNERS
   # Global owners (fallback)
   * @org/maintainers

   # Frontend code
   /src/frontend/ @org/frontend-team
   /src/components/ @org/frontend-team
   *.css @org/frontend-team
   *.scss @org/frontend-team

   # Backend code
   /src/api/ @org/backend-team
   /src/services/ @org/backend-team
   /src/database/ @org/backend-team @DatabaseExpert

   # Infrastructure
   /terraform/ @org/infrastructure
   /.github/workflows/ @org/devops
   /Dockerfile @org/devops

   # Documentation
   /docs/ @org/technical-writing
   README.md @org/technical-writing

   # Security-sensitive files
   /src/auth/ @org/security-team
   /src/crypto/ @org/security-team
   ```

3. **Implement PR Automation**: Reduce manual work

   ```yaml
   # .github/workflows/pr-automation.yml
   name: PR Automation
   on:
     pull_request:
       types: [opened, edited, synchronize, ready_for_review]

   jobs:
     label:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/labeler@v4
           with:
             repo-token: "${{ secrets.GITHUB_TOKEN }}"
             configuration-path: .github/labeler.yml

     assign:
       runs-on: ubuntu-latest
       steps:
         - uses: kentaro-m/auto-assign-action@v1.2.5
           with:
             configuration-path: .github/auto-assign.yml

     size:
       runs-on: ubuntu-latest
       steps:
         - uses: CodelyTV/pr-size-labeler@v1
           with:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
             xs_max_size: 10
             s_max_size: 100
             m_max_size: 500
             l_max_size: 1000

     validate:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Validate PR Title
           uses: amannn/action-semantic-pull-request@v5
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

4. **Set Up Review Automation**: Streamline review process

   ```yaml
   # .github/auto-assign.yml
   addReviewers: true
   addAssignees: false

   reviewers:
     - TeamA
     - TeamB

   numberOfReviewers: 2

   skipKeywords:
     - wip
     - draft

   # .github/labeler.yml
   frontend:
     - src/frontend/**
     - '**/*.css'
     - '**/*.scss'

   backend:
     - src/api/**
     - src/services/**

   documentation:
     - docs/**
     - '**/*.md'

   tests:
     - '**/*.test.js'
     - '**/*.spec.js'
     - test/**
   ```

5. **Create Review Guidelines**: Focus human effort

   ```markdown
   # docs/REVIEWING.md

   ## Code Review Guidelines

   ### What Automated Checks Handle
   ✅ Code formatting and style
   ✅ Test coverage thresholds
   ✅ Build success
   ✅ Linting errors
   ✅ Security vulnerabilities

   ### What Humans Should Review

   #### Architecture & Design
   - Does this align with our architecture?
   - Are the abstractions appropriate?
   - Will this scale with our growth?

   #### Business Logic
   - Does this correctly implement requirements?
   - Are edge cases handled?
   - Are there missing scenarios?

   #### Performance
   - Are there potential bottlenecks?
   - Is caching used appropriately?
   - Are database queries optimized?

   #### Security
   - Is user input validated?
   - Are permissions checked?
   - Is sensitive data protected?

   #### Maintainability
   - Will others understand this code?
   - Is it well-documented where needed?
   - Does it follow team patterns?
   ```

## Examples

```yaml
# ❌ BAD: Manual PR process
# 1. Create PR with minimal description
# 2. Manually tag reviewers
# 3. Wait for someone to notice
# 4. Reviewer asks about testing
# 5. Back and forth about missing info
# 6. Style issues caught in review
# 7. Eventually merged after delays

# ✅ GOOD: Automated PR process
# 1. Create PR with template
# 2. Automation assigns reviewers
# 3. CI runs all checks
# 4. Labels applied automatically
# 5. Reviewers focus on logic/design
# 6. Merged quickly with confidence
```

```markdown
# ❌ BAD: Vague PR description
Title: "Fix bug"
Description: "Fixed the thing that was broken"

# ✅ GOOD: Informative PR with template
Title: "fix(auth): prevent race condition during token refresh"
Description:
## Description
Fixes race condition where multiple token refresh requests could be
initiated simultaneously, causing authentication errors.

Fixes #456

## Type of Change
- [x] 🐛 Bug fix (non-breaking change that fixes an issue)

## Testing
- [x] Unit tests pass locally
- [x] Added test for concurrent refresh scenario
- [x] Manually tested with simulated slow network
```

## Related Bindings

- [trunk-based-development.md](trunk-based-development.md): Short-lived branches require efficient PR processes

- [branch-naming-standards.md](branch-naming-standards.md): Branch names enable PR automation and categorization

- [commit-message-conventions.md](commit-message-conventions.md): Conventional commits enable automated PR validation

- [../../../core/code-review-excellence.md](../../../core/code-review-excellence.md): Excellence in reviews supported by good tooling

- [../../../core/ci-cd-pipeline-standards.md](../../../core/ci-cd-pipeline-standards.md): CI/CD integration ensures quality before review

- [../../../core/automated-quality-gates.md](../../../core/automated-quality-gates.md): Quality gates prevent merging substandard code
