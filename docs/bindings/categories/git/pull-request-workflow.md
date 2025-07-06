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

This binding implements our Git workflow conventions tenet by establishing streamlined, automated pull request workflows. Manual PR processes create bottlenecks through waiting for reviewers, forgotten checks, and style debates.

Automated PR workflows eliminate friction by handling mechanical checks automatically, letting humans focus on architecture, logic, and knowledge sharing. The result is faster, safer deployments and more meaningful code review discussions.

## Rule Definition

**Required Components:**
- **PR Templates**: Standardize description, testing, breaking changes, checklists
- **Automated Checks**: CI/CD pipeline, coverage, security scanning, documentation
- **Review Assignment**: CODEOWNERS, round-robin, expertise-based routing
- **Merge Requirements**: Required approvals, up-to-date branch, all checks passed
- **PR Lifecycle**: Draft PRs, stale notifications, auto-close, conflict detection
- **Review Guidelines**: Focus on architecture, logic, performance, security

## Practical Implementation

Here's how to implement efficient PR workflows:

1. **PR Template**:
   ```markdown
   <!-- .github/pull_request_template.md -->
   ## Description
   Brief description of changes. Fixes #(issue)

   ## Type
   - [ ] Bug fix  - [ ] New feature  - [ ] Breaking change

   ## Checklist
   - [ ] Tests pass  - [ ] Code reviewed  - [ ] Documentation updated
   ```

2. **CODEOWNERS**:
   ```gitignore
   # .github/CODEOWNERS
   * @org/maintainers
   /src/frontend/ @org/frontend-team
   /src/api/ @org/backend-team
   /terraform/ @org/infrastructure
   /src/auth/ @org/security-team
   ```

3. **PR Automation**:
   ```yaml
   # .github/workflows/pr-automation.yml
   name: PR Automation
   on: [pull_request]
   jobs:
     validate:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/labeler@v4
         - uses: amannn/action-semantic-pull-request@v5
         - uses: CodelyTV/pr-size-labeler@v1
   ```

4. **Review Configuration**:
   ```yaml
   # .github/auto-assign.yml
   addReviewers: true
   reviewers: [TeamA, TeamB]
   numberOfReviewers: 2

   # .github/labeler.yml
   frontend: ["src/frontend/**", "**/*.css"]
   backend: ["src/api/**", "src/services/**"]
   ```

5. **Review Guidelines**: Focus human effort on:
   - Architecture and design decisions
   - Business logic correctness
   - Performance implications
   - Security considerations
   - Knowledge sharing opportunities

## Examples

```yaml
# ❌ BAD: Manual process
# Create PR → manually tag → wait → style issues → delays

# ✅ GOOD: Automated process
# Template → auto-assign → CI checks → focus on logic → merge
```

```markdown
# ❌ BAD: Vague description
Title: "Fix bug"
Description: "Fixed the thing that was broken"

# ✅ GOOD: Clear template
Title: "fix(auth): prevent race condition during token refresh"
Description: Fixes race condition during token refresh. Fixes #456
- [x] Bug fix  - [x] Tests added  - [x] Manual testing complete
```

## Related Bindings

- [trunk-based-development.md](trunk-based-development.md): Short-lived branches require efficient PR processes

- [branch-naming-standards.md](branch-naming-standards.md): Branch names enable PR automation and categorization

- [commit-message-conventions.md](commit-message-conventions.md): Conventional commits enable automated PR validation

- [../../../core/code-review-excellence.md](../../../core/code-review-excellence.md): Excellence in reviews supported by good tooling

- [../../../core/ci-cd-pipeline-standards.md](../../../core/ci-cd-pipeline-standards.md): CI/CD integration ensures quality before review

- [../../../core/automated-quality-gates.md](../../../core/automated-quality-gates.md): Quality gates prevent merging substandard code
