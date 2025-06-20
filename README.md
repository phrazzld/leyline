# Leyline

A knowledge repository for sharing development principles and practical wisdom across teams.

## Overview

Leyline is a **knowledge management system** that helps teams share and adopt proven development principles through structured documentation:

- **Tenets**: Foundational principles and wisdom that guide effective development
- **Bindings**: Practical guidance for implementing principles in specific contexts

Our knowledge base contains twelve foundational tenets, enhanced with insights from
"The Pragmatic Programmer" and real-world software engineering experience. These principles
cover essential areas including simplicity, testability, maintainability, modularity,
automation, and adaptability.

**Focus:** Knowledge sharing and learning effectiveness over technical compliance.

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
into your repository. Choose the method that works best for your team:

#### Option 1: CLI Sync (Simple & Direct)

The Leyline CLI provides the simplest way to sync standards to your project:

```bash
# Install the Leyline gem
gem install leyline

# Sync TypeScript standards to your project
leyline sync --categories typescript

# Sync multiple categories
leyline sync --categories go,rust

# See what would be synced (dry run)
leyline sync --categories typescript --verbose

# Force overwrite local modifications
leyline sync --categories typescript --force
```

The CLI will:
- Fetch the latest Leyline standards from GitHub
- Copy relevant tenets and bindings to your project
- Skip files you've already modified (unless using --force)
- Show clear output about what was synced

#### Option 2: GitHub Actions Workflow (Automated)

For automated syncing, use our reusable GitHub Actions workflow:

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

We welcome contributions that share valuable development knowledge and wisdom:

1. **For tenets**: Share fundamental principles and insights that help teams build better software
1. **For bindings**: Provide practical, actionable guidance for implementing principles in real projects
1. **Focus on learning**: Prioritize clarity and knowledge transfer over technical perfection

**What we value in contributions:**
- Clear explanations that help others learn
- Practical examples and real-world guidance
- Insights from experience that benefit the community
- Content that enables teams to make better development decisions

See [CONTRIBUTING.md](./docs/CONTRIBUTING.md) for detailed guidelines, and [AUTHORING_WORKFLOW.md](./docs/AUTHORING_WORKFLOW.md) for content creation guidance.

## Contributing to Knowledge Sharing

Leyline prioritizes **knowledge sharing** over technical complexity. Our streamlined approach focuses on content quality and learning effectiveness rather than comprehensive technical validation.

**Getting started as a contributor:**
- **Focus on content:** Share valuable development wisdom and practical insights
- **Simple validation:** Essential checks ensure basic quality without blocking contributions
- **Fast feedback:** Quick validation enables rapid iteration and improvement

**For content creators:**
```bash
# Essential validation for knowledge contributors (fast feedback)
ruby tools/run_ci_checks.rb --essential

# Optional comprehensive feedback when desired
ruby tools/run_advisory_checks.rb
```

**Our philosophy:** CI should **enable** documentation work, not hinder it. We provide fast, essential validation that maintains automation while allowing you to focus on knowledge transfer.

For detailed authoring guidance, see [AUTHORING_WORKFLOW.md](./docs/AUTHORING_WORKFLOW.md) and [CONTRIBUTING.md](./docs/CONTRIBUTING.md).

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

Leyline documentation focuses on **knowledge sharing and learning**. All tenets and bindings
are written as clear, practical guidance that teams can understand and adopt. The content
is structured for both human learning and programmatic integration.

**Explore the knowledge base:**
- **[Tenets](./docs/tenets/)** - Foundational principles and development wisdom
- **[Bindings](./docs/bindings/)** - Practical implementation guidance by technology
- **[Integration guides](./docs/integration/)** - How to adopt these principles in your projects
- **[Examples](./examples/)** - Real-world integration patterns and templates

**For contributors and authors:**
- **[Authoring Workflow](./docs/AUTHORING_WORKFLOW.md)** - How to create effective knowledge content
- **[Migration Guide](./docs/MIGRATION_GUIDE.md)** - Understanding our knowledge-focused approach

The repository prioritizes **readability and learning effectiveness** over technical complexity, making development wisdom accessible to teams of all experience levels.
