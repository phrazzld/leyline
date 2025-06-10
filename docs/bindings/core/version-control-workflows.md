---
id: version-control-workflows
last_modified: '2025-06-09'
version: '0.1.0'
derived_from: automation
enforced_by: 'git branch protection, automated merge policies, CI/CD integration, pull request templates'
---
# Binding: Establish Systematic Version Control Workflows

Implement automated version control workflows that enforce consistent branching strategies, code review processes, and release management practices. Create systematic approaches to collaboration that maintain code quality while enabling rapid, safe iteration and deployment.

## Rationale

This binding applies our automation tenet to version control collaboration, transforming ad-hoc manual processes into systematic, automated workflows. Effective version control workflows serve as the coordination mechanism that enables multiple developers to work simultaneously without conflicts, while maintaining strict quality and security standards.

Think of version control workflows as traffic management systems for code changes. Just as traffic lights, lane markings, and intersection rules enable thousands of vehicles to navigate safely through complex road networks, systematic version control workflows enable dozens of developers to coordinate complex changes across shared codebases without collisions or quality degradation.

Manual version control processes—relying on developer memory, informal communication, and inconsistent review practices—inevitably break down as teams and codebases grow. Automated workflows eliminate this variability by enforcing consistent practices regardless of team size, time pressure, or individual experience levels. The result is predictable, high-quality collaboration that scales effectively from small teams to large organizations.

## Rule Definition

Systematic version control workflows must implement these core automation principles:

- **Trunk-Based Development**: Use short-lived feature branches that integrate frequently with the main branch, enabling continuous integration and reducing merge complexity. Avoid long-lived branches that accumulate conflicts and integration debt.

- **Automated Branch Protection**: Configure branch protection rules that prevent direct commits to main branches, require status checks to pass, and enforce review requirements before merging. These protections cannot be bypassed without explicit administrative approval.

- **Conventional Commit Standards**: Enforce structured commit message formats that enable automated changelog generation, semantic versioning, and release automation. Every commit must follow consistent patterns that machines can parse and process.

- **Systematic Code Review**: Implement automated pull request workflows with required reviewers, review templates, and integration with quality gates. Code review becomes a systematic process rather than an optional or inconsistent practice.

- **Automated Release Management**: Use conventional commits and automated tools to generate changelogs, determine version numbers, and create releases without manual intervention. This eliminates human error in release processes and enables frequent, reliable releases.

- **Merge Conflict Prevention**: Implement strategies and tooling that minimize merge conflicts through frequent integration, automated rebasing, and conflict detection before changes reach the main branch.

**Required Workflow Components:**
- Branch protection rules with required status checks
- Pull request templates and automated reviewer assignment
- Conventional commit message validation
- Automated changelog generation and semantic versioning
- Merge queue management for high-velocity teams
- Release automation with deployment integration

**Branching Strategy Requirements:**
- Main branch always deployable and protected
- Feature branches short-lived (typically 1-3 days)
- Direct commits to main branch prohibited
- All changes via pull requests with review requirements

## Practical Implementation

1. **Configure Branch Protection Rules**: Set up automated branch protection that requires pull requests, passing status checks, and code review before merging. Include administrator enforcement to prevent bypassing of critical protections.

2. **Implement Pull Request Automation**: Create templates and automated workflows that guide contributors through consistent review processes, including automated reviewer assignment based on code ownership and expertise.

3. **Establish Conventional Commit Enforcement**: Use automated tools to validate commit message formats at both local (git hooks) and remote (CI/CD) levels, ensuring consistent standards that enable automated processing.

4. **Enable Automated Release Processes**: Implement tools that analyze conventional commits to automatically generate changelogs, determine semantic version numbers, and create releases with appropriate deployment triggers.

5. **Create Merge Conflict Resolution Strategies**: Establish clear processes and tooling for handling merge conflicts, including automated rebasing, conflict detection, and guidance for manual resolution when automation is insufficient.

## Examples

```yaml
# ❌ BAD: Minimal branch protection without comprehensive automation
# GitHub branch protection (basic)
branch_protection:
  required_status_checks:
    strict: true
    contexts: ["ci/tests"]
  enforce_admins: false
  required_pull_request_reviews:
    required_approving_review_count: 1

# Problems:
# 1. Administrators can bypass protection rules
# 2. No commit message validation
# 3. Minimal status check requirements
# 4. No automated reviewer assignment
# 5. No integration with release automation
```

```yaml
# ✅ GOOD: Comprehensive branch protection with automated workflows
# GitHub branch protection (comprehensive)
branch_protection:
  required_status_checks:
    strict: true
    contexts:
      - "ci/code-quality"
      - "ci/security-scan"
      - "ci/tests"
      - "ci/coverage"
      - "ci/performance"
  enforce_admins: true
  required_pull_request_reviews:
    required_approving_review_count: 2
    require_code_owner_reviews: true
    dismiss_stale_reviews: true
    restrict_pushes: true
  restrictions:
    users: []
    teams: ["core-maintainers"]
  allow_squash_merge: true
  allow_merge_commit: false
  allow_rebase_merge: true
  delete_branch_on_merge: true

# .github/CODEOWNERS
# Global ownership
* @team/core-maintainers

# Security-critical files require security team review
/security/ @team/security-team
/.github/workflows/ @team/devops-team
/docs/bindings/core/ @team/architecture-team

# Language-specific ownership
*.go @team/backend-team
*.ts @team/frontend-team
*.rs @team/systems-team
```

```yaml
# ✅ GOOD: Automated pull request workflow with quality gates
# .github/workflows/pr-automation.yml
name: Pull Request Automation

on:
  pull_request:
    types: [opened, edited, synchronize, reopened]

jobs:
  pr-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Validate PR title
        uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            perf
            test
            chore
            ci
          requireScope: false
          subjectPattern: ^(?![A-Z]).+$
          subjectPatternError: |
            The subject "{subject}" found in the pull request title "{title}"
            didn't match the configured pattern. Please ensure that the subject
            doesn't start with an uppercase character.

      - name: Validate commit messages
        run: |
          npx commitlint --from=origin/main --to=HEAD

      - name: Auto-assign reviewers
        uses: kentaro-m/auto-assign-action@v1.2.5
        with:
          configuration-path: .github/auto-assign.yml

      - name: Add size label
        uses: pascalgn/size-label-action@v0.4.3
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          sizes: |
            {
              "0": "XS",
              "20": "S",
              "100": "M",
              "500": "L",
              "1000": "XL"
            }

      - name: Check for breaking changes
        run: |
          if git log --oneline origin/main..HEAD | grep -i "breaking\|BREAKING"; then
            echo "::warning::This PR contains breaking changes"
            gh pr edit --add-label "breaking-change"
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  merge-queue:
    if: github.event.action == 'synchronize' && github.event.pull_request.mergeable_state == 'blocked'
    runs-on: ubuntu-latest
    steps:
      - name: Add to merge queue
        uses: pascalgn/merge-queue-action@v0.1.5
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          merge_method: squash
          update_branch: true
```

```json
{
  "auto_assign": {
    "add_reviewers": true,
    "add_assignees": true,
    "number_of_assignees": 1,
    "number_of_reviewers": 2,
    "skip_keywords": ["wip", "draft"],
    "reviewers": [
      "senior-dev-1",
      "senior-dev-2",
      "tech-lead"
    ],
    "assignees": [
      "product-owner",
      "tech-lead"
    ],
    "review_drafts": false
  }
}
```

```yaml
# ✅ GOOD: GitLab merge request automation
# .gitlab-ci.yml (merge request validation)
mr-validation:
  stage: validate
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - |
      # Validate MR title follows conventional format
      if ! echo "$CI_MERGE_REQUEST_TITLE" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|ci|perf|revert)(\(.+\))?: .{1,50}"; then
        echo "❌ Merge request title must follow conventional format"
        exit 1
      fi
    - |
      # Validate all commit messages
      git log --oneline origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME..HEAD | while read commit; do
        if ! echo "$commit" | grep -qE "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore|ci|perf|revert)(\(.+\))?: .+"; then
          echo "❌ Invalid commit message format: $commit"
          exit 1
        fi
      done
    - |
      # Check for large files
      if git diff-tree --no-commit-id --name-only -r HEAD | xargs -I {} stat -c%s {} | awk '$1 > 1048576 {exit 1}'; then
        echo "❌ Large files detected"
        exit 1
      fi

# Automated semantic versioning and changelog
semantic-release:
  stage: release
  image: node:18
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  before_script:
    - npm install -g semantic-release @semantic-release/changelog @semantic-release/git
  script:
    - semantic-release
  artifacts:
    reports:
      dotenv: version.env
```

```javascript
// ✅ GOOD: Automated release configuration
// .releaserc.js
module.exports = {
  branches: ['main'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    [
      '@semantic-release/changelog',
      {
        changelogFile: 'CHANGELOG.md',
      },
    ],
    [
      '@semantic-release/npm',
      {
        npmPublish: false,
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: ['CHANGELOG.md', 'package.json'],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
      },
    ],
    [
      '@semantic-release/github',
      {
        assets: [
          { path: 'dist/*.tgz', label: 'Distribution packages' },
        ],
      },
    ],
  ],
  preset: 'conventionalcommits',
  presetConfig: {
    types: [
      { type: 'feat', section: 'Features' },
      { type: 'fix', section: 'Bug Fixes' },
      { type: 'perf', section: 'Performance Improvements' },
      { type: 'revert', section: 'Reverts' },
      { type: 'docs', section: 'Documentation', hidden: true },
      { type: 'style', section: 'Styles', hidden: true },
      { type: 'chore', section: 'Miscellaneous Chores', hidden: true },
      { type: 'refactor', section: 'Code Refactoring', hidden: true },
      { type: 'test', section: 'Tests', hidden: true },
      { type: 'build', section: 'Build System', hidden: true },
      { type: 'ci', section: 'Continuous Integration', hidden: true },
    ],
  },
};

// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 72],
    'body-leading-blank': [1, 'always'],
    'body-max-line-length': [2, 'always', 100],
    'footer-leading-blank': [1, 'always'],
    'footer-max-line-length': [2, 'always', 100],
  },
};
```

## Related Bindings

- [require-conventional-commits.md](../../docs/bindings/core/require-conventional-commits.md): Version control workflows enforce conventional commit standards through automated validation and integration with release processes. Both bindings ensure consistent commit practices that enable reliable automation.

- [automate-changelog.md](../../docs/bindings/core/automate-changelog.md): Version control workflows integrate with automated changelog generation through conventional commits and semantic versioning. Together they eliminate manual release management and ensure accurate, comprehensive release documentation.

- [git-hooks-automation.md](../../docs/bindings/core/git-hooks-automation.md): Git hooks provide local validation of commit standards while version control workflows enforce the same standards at the remote repository level. Both bindings create comprehensive commit quality assurance.

- [ci-cd-pipeline-standards.md](../../docs/bindings/core/ci-cd-pipeline-standards.md): Version control workflows trigger and integrate with CI/CD pipelines through pull request automation and branch protection. Together they create end-to-end automation from code changes through production deployment.
