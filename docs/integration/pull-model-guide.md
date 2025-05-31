---
title: "Pull-Based Integration Guide"
description: "Comprehensive guide for integrating Leyline using the consumer-initiated pull model"
category: "integration"
tags: ["github-actions", "workflow", "sync", "integration"]
difficulty: "beginner"
audience: "consumers"
---

# Pull-Based Integration Guide

This guide provides comprehensive instructions for integrating Leyline into your repository using the consumer-initiated pull model via the `sync-leyline-content.yml` reusable workflow.

## Table of Contents

- [Understanding the Pull Model](#understanding-the-pull-model)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Integration Patterns](#integration-patterns)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Migration & Adoption](#migration--adoption)

## Understanding the Pull Model

### Philosophy vs Implementation

**The Warden System** is Leyline's *philosophy* of maintaining standardized development principles across projects. It represents the conceptual framework for consistent tenets (foundational principles) and bindings (enforceable rules).

**Pull-Based Sync** is the *technical implementation* that allows consumer repositories to adopt Leyline content on their own schedule. This is consumer-initiated, not a push mechanism.

### Key Benefits

- **Version Control**: Pin to specific Leyline versions for stability
- **Selective Adoption**: Sync only categories relevant to your project
- **Team Review**: Changes arrive as pull requests for review
- **No Surprises**: Updates only occur when you explicitly request them
- **CI/CD Ready**: Integrates seamlessly with existing automation

### Prerequisites

- GitHub repository with Actions enabled
- GitHub token with `contents:write` and `pull-requests:write` permissions
- Basic understanding of GitHub Actions workflows

## Quick Start

### Minimal Integration

Create `.github/workflows/sync-leyline.yml` in your repository:

```yaml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays
  workflow_dispatch:      # Allow manual triggers

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0  # Pin to specific version
```

### What Happens on First Run

1. **Content Checkout**: Workflow checks out the specified Leyline version
2. **File Synchronization**: Copies tenets and core bindings to your repository
3. **Pull Request**: Creates a PR with the synced content (default behavior)
4. **Review & Merge**: Team reviews and merges the PR to adopt standards

### Immediate Next Steps

1. **Review the PR**: Check what content was synced
2. **Customize Configuration**: Add categories specific to your tech stack
3. **Set Up Automation**: Consider automated dependency updates
4. **Read Versioning Guide**: Understand version pinning best practices

## Configuration Reference

### Required Inputs

#### `token`
```yaml
token: ${{ secrets.GITHUB_TOKEN }}
```

**Purpose**: GitHub token for repository operations
**Requirements**: Must have `contents:write` and `pull-requests:write` scopes
**Setup**: For organization repositories, may require SSO enablement

#### `leyline_ref`
```yaml
leyline_ref: v1.0.0  # Use specific version tags
```

**Purpose**: Specifies which version of Leyline to sync from
**Best Practice**: Always pin to specific version tags (never `main` or `master`)
**See Also**: [Versioning Guide](versioning-guide.md) for detailed version management

### Optional Inputs

#### `categories`
```yaml
categories: go,typescript,frontend  # Comma-separated list
```

**Purpose**: Sync only specific category bindings
**Available Categories**:
- **Languages**: `go`, `rust`, `typescript`
- **Contexts**: `frontend`, `backend`

**Default**: None (only core bindings and tenets synced)

#### `target_path`
```yaml
target_path: docs/leyline  # Custom destination directory
```

**Purpose**: Customize where Leyline content is placed
**Default**: `docs/leyline`
**Note**: Directory will be created if it doesn't exist

#### `create_pr`
```yaml
create_pr: false  # Commit directly instead of creating PR
```

**Purpose**: Control whether changes create a PR or commit directly
**Default**: `true` (creates PR)
**Use Cases**: Direct commit for automated environments

#### PR Customization
```yaml
commit_message: "docs: Update Leyline content to v1.0.0"
pr_title: "Update Development Standards"
pr_branch_name: "leyline-update-v1.0.0"
```

**Purpose**: Customize commit and PR details
**Defaults**: Auto-generated based on `leyline_ref`

### Outputs

#### `pr_url`
**Content**: URL of created pull request (if `create_pr: true`)
**Use Case**: Link to PR in subsequent workflow steps or notifications

#### `commit_sha`
**Content**: SHA of commit containing synced content
**Use Case**: Tracking changes, triggering dependent workflows

## Integration Patterns

### Trigger Strategies

#### Scheduled Updates
```yaml
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Monday at 9 AM
```

**Best For**: Regular maintenance, staying current with updates
**Frequency**: Weekly or monthly depending on change tolerance

#### Manual Triggers
```yaml
on:
  workflow_dispatch:
    inputs:
      leyline_version:
        description: 'Leyline version to sync'
        required: false
        default: 'v1.0.0'
```

**Best For**: Controlled updates, urgent standard changes
**Pattern**: Allow version override for testing

#### Event-Driven
```yaml
on:
  pull_request:
    paths:
      - '.github/workflows/sync-leyline.yml'
```

**Best For**: Testing workflow changes
**Use Case**: Validate configuration updates

### Repository Organization

#### Standard Structure
```
docs/leyline/
├── tenets/
│   ├── 00-index.md
│   ├── simplicity.md
│   └── testability.md
└── bindings/
    ├── core/
    │   ├── 00-index.md
    │   └── pure-functions.md
    └── categories/
        ├── go/
        └── typescript/
```

#### Gitignore Considerations
```gitignore
# Option 1: Track all Leyline content (recommended)
# No specific ignores needed

# Option 2: Ignore and regenerate (advanced)
docs/leyline/
!docs/leyline/.gitkeep
```

### CI/CD Integration

#### Pre-commit Validation
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: validate-leyline-content
        name: Validate Leyline Content
        entry: scripts/validate-standards.sh
        language: script
        files: ^docs/leyline/
```

#### Automated Dependency Updates
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/.github/workflows"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore"
      include: "scope"
```

## Troubleshooting

### Common Issues

#### Permission Errors
```
Error: Resource not accessible by integration
```

**Causes**:
- Token missing required scopes
- Organization SSO not enabled for token
- Repository settings restrict Actions

**Solutions**:
1. Ensure token has `contents:write` and `pull-requests:write` scopes
2. Enable SSO for personal access tokens in organization settings
3. Check repository Actions permissions under Settings → Actions

#### Invalid leyline_ref
```
Error: Invalid `leyline_ref` provided: v99.99.99
```

**Causes**:
- Version tag doesn't exist
- Typo in version number
- Using branch name instead of tag

**Solutions**:
1. Check [Leyline releases](https://github.com/phrazzld/leyline/releases) for valid versions
2. Verify spelling and format (e.g., `v1.0.0` not `1.0.0`)
3. Use tagged versions, not branch names

#### Missing Categories
```
Warning: Category 'python' not found in Leyline ref 'v1.0.0'. Skipping.
```

**Causes**:
- Requested category not available in specified Leyline version
- Typo in category name

**Solutions**:
1. Check available categories in the Leyline version you're using
2. Verify category names: `go`, `rust`, `typescript`, `frontend`, `backend`
3. Update to newer Leyline version if category was added later

#### Workflow Failures
```
Error: Unable to create pull request
```

**Causes**:
- Base branch doesn't exist
- Branch conflicts with existing branch
- No changes to commit

**Solutions**:
1. Ensure base branch exists (usually `main` or `master`)
2. Delete conflicting branches manually
3. Check if content is already up-to-date (no changes needed)

### Debug Strategies

#### Reading Workflow Logs
1. **Go to Actions tab** in your repository
2. **Click on failed workflow run**
3. **Expand job steps** to see detailed output
4. **Look for error messages** in red text
5. **Check the "Sync Leyline Content" step** for specific failures

#### Test Environment Setup
```yaml
# .github/workflows/test-leyline-sync.yml
name: Test Leyline Sync
on:
  workflow_dispatch:
    inputs:
      test_ref:
        description: 'Leyline ref to test'
        required: true
        default: 'v1.0.0'

jobs:
  test-sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: ${{ github.event.inputs.test_ref }}
      target_path: docs/leyline-test  # Separate test directory
      pr_branch_name: test-leyline-sync-${{ github.run_number }}
```

#### Version Validation
Before updating `leyline_ref`, verify the version exists:
```bash
# Check available versions
curl -s https://api.github.com/repos/phrazzld/leyline/releases | jq '.[].tag_name'
```

### Getting Help

#### Information to Include
When reporting issues, include:
- Complete workflow configuration
- Error messages from workflow logs
- Leyline version being used
- Repository and organization settings (if relevant)

#### Resources
- **Issues**: [Report bugs, questions, or feature requests](https://github.com/phrazzld/leyline/issues)
- **Examples**: See `examples/consumer-workflows/` for working configurations

## Advanced Configuration

### Multi-Repository Management

#### Organization Template
```yaml
# Template: .github/workflows/sync-leyline-template.yml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 9 * * 1'
  workflow_dispatch:

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: ${{ vars.LEYLINE_VERSION }}  # Organization variable
      categories: ${{ vars.LEYLINE_CATEGORIES }}  # Per-repo variable
```

#### Centralized Version Management
Use organization or repository variables:
- `LEYLINE_VERSION`: Centrally managed version
- `LEYLINE_CATEGORIES`: Repository-specific categories

### Custom Workflows

#### Conditional Category Selection
```yaml
jobs:
  detect-languages:
    runs-on: ubuntu-latest
    outputs:
      categories: ${{ steps.detect.outputs.categories }}
    steps:
      - uses: actions/checkout@v4
      - id: detect
        run: |
          categories=""
          [[ -f "go.mod" ]] && categories="${categories},go"
          [[ -f "package.json" ]] && categories="${categories},typescript"
          [[ -d "frontend/" ]] && categories="${categories},frontend"
          echo "categories=${categories#,}" >> $GITHUB_OUTPUT

  sync:
    needs: detect-languages
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0
      categories: ${{ needs.detect-languages.outputs.categories }}
```

#### Multi-Version Support
```yaml
strategy:
  matrix:
    environment: [development, staging, production]
    include:
      - environment: development
        leyline_version: main
        target_path: docs/leyline-dev
      - environment: staging
        leyline_version: v1.1.0-rc.1
        target_path: docs/leyline-staging
      - environment: production
        leyline_version: v1.0.0
        target_path: docs/leyline
```

### Security Considerations

#### Token Management
- **Use fine-grained tokens** when possible
- **Rotate tokens regularly** (90-day maximum)
- **Limit token scope** to minimum required permissions
- **Store in secrets** never in code

#### Content Validation
```yaml
steps:
  - name: Validate Synced Content
    run: |
      # Check file integrity
      find docs/leyline -name "*.md" -exec head -1 {} \; | grep -v "^---$" && exit 1

      # Validate YAML front-matter
      ruby -r yaml -e 'Dir["docs/leyline/**/*.md"].each {|f| YAML.load_file(f) rescue (puts f; exit 1)}'
```

## Migration & Adoption

### From Legacy Methods

#### Symlink Migration
If currently using symlinks, see the [Migration Guide](../migration-guide.md) for step-by-step transition instructions.

#### Manual Process Migration
1. **Remove manual copies** of Leyline content
2. **Set up automated sync** using this guide
3. **Verify content matches** previous manual sync
4. **Update team documentation** with new process

### Team Adoption Strategy

#### Gradual Rollout
1. **Start with one repository** as pilot
2. **Document lessons learned** from pilot implementation
3. **Create organization-specific guide** based on this guide
4. **Roll out to additional repositories** with proven configuration

#### Training & Documentation
- **Share this guide** with team members
- **Provide hands-on training** for workflow setup
- **Document organization-specific** configuration decisions
- **Establish** review and approval processes for updates

---

## Related Guides

- **[Versioning Guide](versioning-guide.md)**: Best practices for managing Leyline versions
- **[Migration Guide](../migration-guide.md)**: Transitioning from legacy integration methods

## Need Help?

- **Questions or Issues?** Report them in [GitHub Issues](https://github.com/phrazzld/leyline/issues)
- **Examples?** See [consumer workflow examples](../../examples/consumer-workflows/)
