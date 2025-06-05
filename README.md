# Leyline

Tenets & Bindings for consistent development standards across repositories.

## Overview

Leyline provides a centralized system for defining, documenting, and enforcing
development principles through two core concepts:

- **Tenets**: Immutable truths and principles that guide our development philosophy
- **Bindings**: Enforceable rules derived from tenets, with specific implementation
  guidance

Our philosophy is built on twelve foundational tenets, enhanced with insights from
"The Pragmatic Programmer" and modern software engineering best practices. These tenets
cover essential areas including simplicity, testability, maintainability, modularity,
automation, and adaptability.

For example, the [simplicity](./docs/tenets/simplicity.md) tenet establishes the
principle that we should "prefer the simplest design that works," while the
[no-any](./docs/bindings/categories/typescript/no-any.md) binding is a specific, enforceable rule
derived from that tenet.

## Repository Structure

```
docs/
  ├── tenets/                     # Foundational principles (immutable truths)
  ├── bindings/                   # Enforceable rules (derived from tenets)
  │   ├── core/                   # Core bindings applicable to all projects
  │   └── categories/             # Category-specific bindings
  │       ├── go/                 # Go language bindings
  │       ├── rust/               # Rust language bindings
  │       ├── typescript/         # TypeScript language bindings
  │       ├── cli/                # CLI application bindings
  │       ├── frontend/           # Frontend application bindings
  │       └── backend/            # Backend application bindings
  ├── announcements/              # Important announcements for contributors
  ├── data/                       # Data files for the project
  └── templates/                  # Templates for creating new tenets and bindings
tools/                            # Validation and maintenance scripts
archive/                          # Archived tools and documentation
.github/                          # Automation workflows
```

## How It Works

### Leyline Philosophy: The Warden System

The Warden System represents Leyline's philosophy of standardized development principles.
It's not an automated push mechanism, but rather a structured approach to maintaining
consistent tenets (foundational principles) and bindings (enforceable rules) that teams
can adopt on their own schedule through consumer-initiated synchronization.

### Integration: Pull-Based Content Sync

Leyline uses a consumer-initiated pull model. You control when and what to sync from Leyline
into your repository using our reusable GitHub Actions workflow.

### Migrating from Symlinks

**Are you using symlinked philosophy documents?** See the
[Migration Guide](./docs/migration-guide.md) for a simple 5-step process to switch to
Leyline.

### New Repository Integration

To integrate Leyline into your repository:

1. Create a workflow that calls our reusable sync workflow:

```yaml
# .github/workflows/sync-leyline.yml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays
  workflow_dispatch:  # Allow manual triggers

permissions:
  contents: write      # Required: Create commits and branches
  pull-requests: write # Required: Create pull requests

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v0.1.5
    with:
      leyline_ref: v0.1.5  # Pin to a specific Leyline version
      categories: go,typescript  # Optional: only sync specific categories
      target_path: docs/leyline  # Optional: customize target directory
      create_pr: true  # Optional: create a PR instead of direct commit
    secrets:
      token: ${{ secrets.GITHUB_TOKEN }}  # Required: GitHub token for repo access
```

2. **First-time setup**: After adding the workflow file, manually trigger it:
   - Go to your repository's **Actions** tab
   - Find **"Sync Leyline Content"** workflow
   - Click **"Run workflow"** → **"Run workflow"**

3. The workflow will:
   - Pull the specified version of Leyline content
   - Copy tenets, core bindings, and requested category bindings
   - Create a pull request with the changes (or commit directly)

4. Review and merge the PR to adopt the standards

### Common Setup Issues

If you encounter errors when setting up the workflow:

**"reference to workflow should be either a valid branch, tag, or commit"**
- Use `@v0.1.5` instead of `@v1` (check [releases](https://github.com/phrazzld/leyline/releases) for latest version)

**"Unrecognized named-value: 'secrets'. Located at position 1 within expression: secrets.GITHUB_TOKEN"**
- Move `token` from `with:` to `secrets:` section (see corrected template above)

**"Workflow doesn't run after pushing"**
- The workflow only runs on schedule or manual trigger, not on push
- Manually trigger it the first time via GitHub Actions UI

**"No such file or directory @ rb_sysopen - docs/tenets/00-index.md"**
- Update to `@v0.1.5` or later which includes the reindex.rb fix and change detection fix for initial syncs
- This error occurred with older versions when using non-default `target_path`

**"Permission to [repo] denied to github-actions[bot]" or "403 Forbidden"**
- The `GITHUB_TOKEN` has insufficient permissions to create branches and pull requests
- **Solution 1 (Recommended)**: Add permissions to your workflow:
  ```yaml
  permissions:
    contents: write
    pull-requests: write
  ```
- **Solution 2**: Use a Personal Access Token with `repo` scope instead of `GITHUB_TOKEN`

**"GitHub Actions is not permitted to create or approve pull requests"**
- Your repository's workflow permissions are set to read-only by default
- **Solution**: Update your repository's Actions permissions:
  1. Go to your repository → Settings → Actions → General
  2. Under "Workflow permissions", select "Read and write permissions"
  3. Check "Allow GitHub Actions to create and approve pull requests"
  4. Click "Save"
- **CLI Solution**: `gh api repos/OWNER/REPO/actions/permissions/workflow -X PUT --input - <<< '{"default_workflow_permissions":"write","can_approve_pull_request_reviews":true}'`

**For detailed integration instructions**, see the [Integration Guide](./docs/integration/pull-model-guide.md).

**For versioning best practices**, see the [Versioning Guide](./docs/integration/versioning-guide.md).

For complete integration examples, including pre-commit hooks and Renovate
configurations, see the [examples directory](./examples/). These examples provide
templates and best practices for maintaining synchronized copies of tenets and bindings.

### Category-Specific Integration

To ensure repositories only receive relevant bindings (e.g., TypeScript projects don't
pull Go bindings), Leyline provides category-specific integration options:

- Binding files are organized by category directories (e.g., `categories/typescript/`, `categories/go/`) for clean organization
- Use the `categories` input parameter to specify which categories to sync:
  ```yaml
  with:
    leyline_ref: v0.1.5
    categories: go,typescript,frontend
  ```
- The workflow will always sync core bindings (applicable to all projects) and tenets, along with the categories you specify
- See the [implementation guide](./docs/implementation-guide.md) for detailed
  instructions on category-specific integration

## Contributing

We welcome contributions to both tenets and bindings:

1. **For tenets**: Focus on fundamental principles that stand the test of time
1. **For bindings**: Create specific, enforceable rules that implement tenets

See [CONTRIBUTING.md](./docs/CONTRIBUTING.md) for detailed guidelines on proposing
changes.

## Examples

Here are some example tenets and their derived bindings:

- **[Simplicity](./docs/tenets/simplicity.md)** →
  [hex-domain-purity](./docs/bindings/core/hex-domain-purity.md),
  [yagni-pattern-enforcement](./docs/bindings/core/yagni-pattern-enforcement.md),
  [no-any](./docs/bindings/categories/typescript/no-any.md)
- **[Orthogonality](./docs/tenets/orthogonality.md)** →
  [system-boundaries](./docs/bindings/core/system-boundaries.md),
  [component-isolation](./docs/bindings/core/component-isolation.md)
- **[DRY (Don't Repeat Yourself)](./docs/tenets/dry-dont-repeat-yourself.md)** →
  [extract-common-logic](./docs/bindings/core/extract-common-logic.md),
  [normalized-data-design](./docs/bindings/core/normalized-data-design.md)
- **[Fix Broken Windows](./docs/tenets/fix-broken-windows.md)** →
  [automated-quality-gates](./docs/bindings/core/automated-quality-gates.md),
  [technical-debt-tracking](./docs/bindings/core/technical-debt-tracking.md)
- **[Testability](./docs/tenets/testability.md)** →
  [no-internal-mocking](./docs/bindings/core/no-internal-mocking.md),
  [property-based-testing](./docs/bindings/core/property-based-testing.md)

## Documentation

Leyline documentation is designed primarily for LLM consumption, with all tenets and bindings
available as structured Markdown files with YAML front-matter. Human readers can browse the
complete documentation directly in this GitHub repository.

**Navigate the documentation:**
- **[Tenets](./docs/tenets/)** - Foundational principles and philosophy
- **[Bindings](./docs/bindings/)** - Enforceable rules organized by category
- **[Integration guides](./docs/integration/)** - Implementation instructions
- **[Examples](./examples/)** - Practical integration templates

The repository structure is optimized for both programmatic access and GitHub's native
Markdown rendering, ensuring excellent readability without requiring additional tooling.
