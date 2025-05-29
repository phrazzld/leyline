# Leyline Versioning Guide

This guide explains Leyline's versioning strategy and provides best practices for consumers when specifying the `leyline_ref` parameter in the `sync-leyline-content.yml` workflow.

## Leyline's Versioning Strategy

Leyline follows [Semantic Versioning (SemVer) 2.0.0](https://semver.org/) for all releases. This means version numbers communicate the nature of changes explicitly:

- **MAJOR** (e.g., `1.0.0` → `2.0.0`): Breaking changes to tenets, bindings, or directory structure
- **MINOR** (e.g., `1.0.0` → `1.1.0`): New tenets, bindings, or categories added in a backward-compatible way
- **PATCH** (e.g., `1.0.0` → `1.0.1`): Bug fixes, clarifications, or improvements to existing content

### Current Version

The current stable version is: **v0.1.2**

⚠️ **Pre-1.0 Notice**: Leyline is currently in initial development (0.x.y versions). During this phase, breaking changes may occur in minor versions as we stabilize the tenet and binding structure.

## Best Practices for `leyline_ref`

When using Leyline's `sync-leyline-content.yml` workflow, the `leyline_ref` parameter determines which version of Leyline content to sync. Follow these guidelines:

### ✅ Recommended: Pin to Specific Tags

**Always use specific version tags for production workflows:**

```yaml
- name: Sync Leyline Content
  uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    leyline_ref: "v0.1.2"  # ✅ GOOD: Specific version tag
```

**Benefits:**
- **Predictable builds**: Your content sync won't change unexpectedly
- **Reproducible environments**: Different team members get identical content
- **Controlled updates**: You decide when to adopt new tenets or bindings
- **Rollback capability**: Easy to revert to previous versions if needed

### ❌ Avoid: Floating References

**Never use branch names or moving references in production:**

```yaml
- name: Sync Leyline Content
  uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    leyline_ref: "main"      # ❌ BAD: Branch reference changes over time
    leyline_ref: "master"    # ❌ BAD: Branch reference changes over time
    leyline_ref: "latest"    # ❌ BAD: Not a real Git reference
```

**Why floating refs are problematic:**
- **Inconsistent builds**: Content may differ between runs
- **Surprise breaking changes**: New incompatible tenets could appear
- **Debugging difficulties**: Hard to reproduce issues
- **Security risks**: Unvetted changes could be introduced

### Acceptable for Development

Floating references are acceptable for development or testing environments:

```yaml
# Development workflow - acceptable for testing
- name: Sync Latest Leyline Content (Dev)
  if: github.ref == 'refs/heads/develop'
  uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@main
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    leyline_ref: "main"  # OK for development testing
```

## Automated Dependency Management

### Using Dependabot

Configure GitHub Dependabot to automatically update your Leyline references:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    # This will create PRs when new Leyline versions are released
```

### Using Renovate

Configure Renovate to manage Leyline version updates:

```json
{
  "github-actions": {
    "fileMatch": ["\\.github/workflows/.*\\.ya?ml$"],
    "pinDigests": true
  },
  "regexManagers": [
    {
      "fileMatch": ["\\.github/workflows/.*\\.ya?ml$"],
      "matchStrings": ["leyline_ref:\\s*[\"'](?<currentValue>v?[0-9]+\\.[0-9]+\\.[0-9]+)[\"']"],
      "datasourceTemplate": "github-tags",
      "depNameTemplate": "phrazzld/leyline"
    }
  ]
}
```

### Manual Update Process

When updating Leyline versions manually:

1. **Review Release Notes**: Check the [Leyline releases](https://github.com/phrazzld/leyline/releases) for changes
2. **Test in Development**: Update a development branch first
3. **Review Changes**: Examine what tenets/bindings are added, modified, or removed
4. **Update Documentation**: Adapt your project's implementation if needed
5. **Deploy Gradually**: Update staging before production

## Version Compatibility Matrix

| Leyline Version | Breaking Changes | Notes |
|----------------|------------------|-------|
| v0.1.0 - v0.1.2 | Potential in minor versions | Initial development phase |
| v1.0.0+ | Only in major versions | Stable API commitment |

## Example Workflow Configurations

### Conservative Approach (Recommended for Production)

```yaml
name: Sync Leyline Content

on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Leyline Content
        uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          leyline_ref: "v0.1.2"  # Pinned to specific version
          categories: "go,typescript"
```

### Development/Testing Approach

```yaml
name: Sync Latest Leyline (Development)

on:
  push:
    branches: [develop]

jobs:
  sync-latest:
    runs-on: ubuntu-latest
    steps:
      - name: Sync Latest Leyline Content
        uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          leyline_ref: "main"  # Latest content for testing
          create_pr: false      # Direct commit for development
```

## Troubleshooting

### Invalid Reference Error

If you see an error like "Invalid `leyline_ref` provided", check:

1. **Tag exists**: Verify the tag exists in the [Leyline repository](https://github.com/phrazzld/leyline/tags)
2. **Correct format**: Use the exact tag name (e.g., `v0.1.2`, not `0.1.2`)
3. **Typos**: Double-check the version number spelling

### Unexpected Content Changes

If content changes unexpectedly:

1. **Check your `leyline_ref`**: Ensure you're using a specific tag, not a branch
2. **Review recent commits**: Look at what changed in the Leyline repository
3. **Pin to known good version**: Temporarily revert to a previously working version

### Breaking Changes

When a new major version introduces breaking changes:

1. **Read migration guide**: Check the release notes for migration instructions
2. **Test incrementally**: Update in a feature branch first
3. **Plan adapter patterns**: Use wrapper patterns to maintain compatibility
4. **Coordinate team updates**: Ensure all team members understand the changes

## Migration Between Versions

### From v0.x to v1.0

When Leyline reaches v1.0.0:

- **API stability**: Tenets and core bindings will have stable structure
- **Breaking changes**: Only in major versions (2.0.0, 3.0.0, etc.)
- **Deprecation process**: Features will be deprecated before removal

### Handling Breaking Changes

When updating across major versions:

1. **Create feature branch**: Never update major versions directly in main
2. **Review changelog**: Understand what changed and why
3. **Update gradually**: Address one breaking change at a time
4. **Test thoroughly**: Ensure your implementation still works
5. **Update documentation**: Reflect any changes in your project's docs

## Related Documentation

- [Leyline Semantic Versioning Binding](../bindings/core/semantic-versioning.md): Detailed SemVer implementation
- [Pull Model Integration Guide](./pull-model-guide.md): Complete integration setup
- [GitHub Releases](https://github.com/phrazzld/leyline/releases): Release notes and changelogs

## Summary

- **Always pin to specific version tags** (e.g., `v0.1.2`) for production
- **Never use floating references** (e.g., `main`, `master`) in production
- **Use automation tools** (Dependabot, Renovate) for safe updates
- **Test updates** in development environments first
- **Review release notes** before updating to understand changes
- **Plan for breaking changes** during the 0.x development phase
