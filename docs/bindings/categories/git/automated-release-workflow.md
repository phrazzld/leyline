---
id: automated-release-workflow
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-workflow-conventions
enforced_by: 'CI/CD pipelines, semantic-release, conventional-changelog, git tags'
---
# Binding: Automate Releases Through Convention

Transform releases from manual, error-prone ceremonies into automated, predictable processes driven by commit conventions. Like Rails' database migrations that version schema changes automatically, your releases should version and document themselves based on the work you've already described in commits.

## Rationale

This binding implements our Git workflow conventions tenet by automating the entire release process through conventions. Just as Rails eliminated manual SQL schema management with migrations, we eliminate manual version bumping, changelog writing, and release tagging. The information needed for releases already exists in your conventional commits—automation simply harvests it.

Manual release processes are where human errors compound. Someone forgets to update the version number. The changelog misses important changes. Tags don't match package versions. Release notes are vague or missing. Each manual step is an opportunity for mistakes that frustrate users and waste developer time. Automated releases driven by commit conventions eliminate these errors while actually producing better documentation than most manual processes.

Think of automated releases like a self-checkout system at a grocery store. In a manual process, you'd tell the cashier about each item, they'd enter it, calculate the total, and process payment—multiple opportunities for miscommunication. With self-checkout (automated releases), you scan items (write conventional commits) and the system handles the rest. The result is faster, more accurate, and frees humans for more valuable work.

## Rule Definition

This binding establishes automated release workflows:

- **Version Determination**: Semantic versioning based on commit types
  - `feat:` commits trigger MINOR version bumps (1.2.0 → 1.3.0)
  - `fix:` commits trigger PATCH version bumps (1.2.0 → 1.2.1)
  - `BREAKING CHANGE:` triggers MAJOR version bumps (1.2.0 → 2.0.0)
  - Multiple commits: highest change wins (feat + fix = MINOR)

- **Changelog Generation**: Automated from commit messages
  - Group commits by type with clear headings
  - Include breaking changes prominently
  - Link to commits and issues automatically
  - Generate upgrade guides from breaking change descriptions

- **Release Triggers**: Define when releases happen
  - On merge to main (continuous deployment)
  - On manual trigger (controlled releases)
  - On schedule (regular release cadence)
  - Never require manual version updates

- **Release Artifacts**: Automate all release outputs
  - Git tags with version numbers
  - GitHub/GitLab releases with notes
  - Package registry publications
  - Documentation site updates
  - Notification to stakeholders

- **Version Locations**: Keep versions synchronized
  - package.json (Node.js)
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
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
             NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
           run: npx semantic-release
   ```

3. **Create Release Configuration**: Define release behavior

   ```javascript
   // release.config.js
   module.exports = {
     branches: [
       'main',
       {name: 'beta', prerelease: true},
       {name: 'alpha', prerelease: true}
     ],
     plugins: [
       ['@semantic-release/commit-analyzer', {
         preset: 'conventionalcommits',
         releaseRules: [
           {type: 'refactor', release: 'patch'},
           {type: 'perf', release: 'patch'},
           {scope: 'no-release', release: false}
         ]
       }],
       ['@semantic-release/release-notes-generator', {
         preset: 'conventionalcommits',
         presetConfig: {
           types: [
             {type: 'feat', section: '✨ Features'},
             {type: 'fix', section: '🐛 Bug Fixes'},
             {type: 'perf', section: '⚡ Performance'},
             {type: 'docs', section: '📚 Documentation', hidden: false}
           ]
         }
       }],
       '@semantic-release/changelog',
       '@semantic-release/npm',
       '@semantic-release/github'
     ]
   };
   ```

4. **Implement Version Synchronization**: Keep versions consistent

   ```json
   // package.json
   {
     "scripts": {
       "version": "echo 'Version managed by semantic-release'",
       "prepare-release": "npm run build && npm test",
       "release:dry": "semantic-release --dry-run",
       "release:preview": "semantic-release --dry-run --debug"
     }
   }
   ```

5. **Add Release Documentation**: Make process transparent

   ```markdown
   # RELEASING.md

   ## Automated Release Process

   Releases are fully automated based on commit messages:

   ### Version Bumps
   - `fix:` → Patch release (1.0.0 → 1.0.1)
   - `feat:` → Minor release (1.0.0 → 1.1.0)
   - `BREAKING CHANGE:` → Major release (1.0.0 → 2.0.0)

   ### Release Triggers
   - Every merge to main triggers a release
   - Pre-releases from beta/alpha branches
   - Manual releases: Run "Release" workflow

   ### What Gets Updated
   - ✅ Version in package.json
   - ✅ CHANGELOG.md with all changes
   - ✅ Git tag with version
   - ✅ GitHub release with notes
   - ✅ NPM package publication
   - ✅ Documentation site
   ```

## Examples

```bash
# ❌ BAD: Manual release process
# 1. Remember to update version in package.json
# 2. Write changelog entries manually
# 3. Create git tag
# 4. Push tag
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
