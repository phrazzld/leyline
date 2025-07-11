---
id: automated-release-workflow
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: git-workflow-conventions
enforced_by: 'CI/CD pipelines, semantic-release, conventional-changelog, git tags'
---
# Binding: Automate Releases Through Convention

Transform releases from manual, error-prone ceremonies into automated, predictable processes driven by commit conventions. Like Rails' database migrations that version schema changes automatically, your releases should version and document themselves based on the work you've already described in commits.

## Rationale

Manual release processes compound human errors: forgotten version updates, missed changelog entries, mismatched tags, vague release notes. Each manual step wastes developer time and frustrates users.

Automated releases driven by commit conventions harvest information that already exists in commits, eliminating errors while producing better documentation than manual processes.

## Rule Definition

**Requirements:**

- **Version Determination**: `feat:`→MINOR, `fix:`→PATCH, `BREAKING CHANGE:`→MAJOR
- **Changelog Generation**: Group by type, highlight breaking changes, auto-link commits/issues
- **Release Triggers**: On main merge, manual trigger, or schedule
- **Artifacts**: Git tags, releases with notes, package publications, docs updates, notifications
- **Version Sync**: package.json, Cargo.toml, setup.py, etc.
  - Cargo.toml (Rust)
  - pyproject.toml (Python)
  - VERSION file
  - Git tags
  - All updated automatically

- **Pre-release Handling**: Support controlled rollouts
  - Alpha/beta releases from specific branches
  - Release candidates before major versions
  - Automated pre-release versioning

## Practical Implementation

Here's how to implement automated releases effectively:

1. **Set Up Semantic Release**: Core automation tool

   ```bash
   # Install semantic-release and plugins
   npm install --save-dev \
     semantic-release \
     @semantic-release/changelog \
     @semantic-release/git \
     @semantic-release/github \
     @semantic-release/npm

   # Create .releaserc.json
   {
     "branches": ["main"],
     "plugins": [
       "@semantic-release/commit-analyzer",
       "@semantic-release/release-notes-generator",
       "@semantic-release/changelog",
       "@semantic-release/npm",
       "@semantic-release/github",
       ["@semantic-release/git", {
         "assets": ["CHANGELOG.md", "package.json"],
         "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
       }]
     ]
   }
   ```

2. **Configure GitHub Actions**: Automate on every merge

   ```yaml
   # .github/workflows/release.yml
   name: Release
   on:
     push:
       branches: [main]

   jobs:
     release:
       name: Release
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
           with:
             fetch-depth: 0
             persist-credentials: false

         - uses: actions/setup-node@v3
           with:
             node-version: 18
             cache: npm

         - run: npm ci

         - run: npm run build

         - run: npm test

         - name: Release
# 5. Create GitHub release
# 6. Publish to npm
# 7. Hope you didn't miss anything

# ✅ GOOD: Automated release process
git commit -m "feat: add user authentication"
git commit -m "fix: resolve memory leak in cache"
git push origin main
# Automation handles everything else
```

```yaml
# ❌ BAD: Manual version management
version: 1.2.3  # Developer must remember to update

# ✅ GOOD: Version determined by commits
# No manual version anywhere - calculated from git history
```

```markdown
# ❌ BAD: Manually written changelog
## v1.2.0 - 2024-01-15
- Added some features (which ones?)
- Fixed some bugs (what bugs?)
- John did something (what? why?)

# ✅ GOOD: Generated changelog
## [1.2.0](https://github.com/org/repo/compare/v1.1.0...v1.2.0) (2024-01-15)

### ✨ Features
* **auth:** add OAuth2 support ([#123](https://github.com/org/repo/issues/123)) ([a1b2c3d](https://github.com/org/repo/commit/a1b2c3d))
* **api:** implement pagination ([#124](https://github.com/org/repo/issues/124)) ([d4e5f6g](https://github.com/org/repo/commit/d4e5f6g))

### 🐛 Bug Fixes
* **cache:** resolve memory leak on timeout ([#125](https://github.com/org/repo/issues/125)) ([h7i8j9k](https://github.com/org/repo/commit/h7i8j9k))
```

## Related Bindings

- [commit-message-conventions.md](commit-message-conventions.md): Conventional commits provide the data that drives automated releases

- [../../../core/semantic-versioning.md](../../../core/semantic-versioning.md): Automated releases implement semantic versioning based on commit types

- [../../../core/automate-changelog.md](../../../core/automate-changelog.md): Changelog automation is a key component of automated releases

- [trunk-based-development.md](trunk-based-development.md): Continuous integration to main enables continuous deployment

- [../../../core/ci-cd-pipeline-standards.md](../../../core/ci-cd-pipeline-standards.md): Release automation integrates with CI/CD for full deployment

- [git-hooks-enforcement.md](git-hooks-enforcement.md): Local hooks ensure commits follow conventions that enable automation
