# Leyline Integration Examples

This directory contains example configuration files and workflows for integrating Leyline into your repository using the pull-based content synchronization model.

## 📖 Primary Example

**Start here:** [`consumer-workflows/sync-leyline-example.yml`](consumer-workflows/sync-leyline-example.yml)

This comprehensive example includes:
- Complete configuration with all available options
- Extensive inline documentation and best practices
- Multiple trigger strategies (scheduled, manual, event-driven)
- Troubleshooting tips and common issues
- Post-sync actions and advanced patterns

## Directory Structure

```
examples/
├── consumer-workflows/    # Primary workflow examples (START HERE)
│   └── sync-leyline-example.yml
├── github-workflows/      # Additional workflow patterns
│   ├── sync-leyline-content.yml    # Minimal quick-start example
│   ├── language-specific-sync.yml  # Auto-detect languages example
│   ├── vendor-docs.yml            # DEPRECATED - old pattern
│   └── correct-vendor-docs.yml    # DEPRECATED - old pattern
├── pre-commit/           # Pre-commit hook configurations
└── renovate/             # Automated dependency update configurations
```

## Integration Guide

### Quick Start

1. **Copy the workflow example** to your repository:
   ```bash
   # Create the workflows directory
   mkdir -p .github/workflows

   # Copy the comprehensive example
   cp examples/consumer-workflows/sync-leyline-example.yml .github/workflows/sync-leyline.yml
   ```

2. **Customize the configuration**:
   - Set your desired `leyline_ref` version
   - Choose relevant `categories` for your tech stack
   - Adjust trigger schedule or events
   - Review optional parameters

3. **Commit and push** to activate the workflow

4. **Review the created PR** with Leyline content

### Available Examples

#### 🌟 Comprehensive Example
- **File:** `consumer-workflows/sync-leyline-example.yml`
- **Use case:** Full-featured integration with all options documented
- **Best for:** Production use, learning all features

#### 🚀 Minimal Example
- **File:** `github-workflows/sync-leyline-content.yml`
- **Use case:** Quick start with basic configuration
- **Best for:** Simple projects, getting started quickly

#### 🔍 Language Detection Example
- **File:** `github-workflows/language-specific-sync.yml`
- **Use case:** Automatically detect and sync only relevant language bindings
- **Best for:** Multi-language projects, dynamic teams

### Additional Integrations

#### Pre-commit Hooks
Add validation to ensure Leyline content isn't manually modified:
```yaml
# In .pre-commit-config.yaml
- repo: local
  hooks:
    - id: validate-leyline-content
      name: Validate Leyline content not modified
      entry: scripts/check-leyline.sh
      language: script
      files: ^docs/leyline/
```

See [`pre-commit/pre-commit-config.yaml`](pre-commit/pre-commit-config.yaml) for a complete example.

#### Automated Updates with Renovate
Configure Renovate to automatically update Leyline versions:
```json
{
  "extends": ["config:base"],
  "regexManagers": [{
    "fileMatch": ["^\\.github/workflows/.*\\.ya?ml$"],
    "matchStrings": ["leyline_ref:\\s*(?<currentValue>v\\d+\\.\\d+\\.\\d+)"],
    "datasourceTemplate": "github-releases",
    "depNameTemplate": "phrazzld/leyline"
  }]
}
```

See [`renovate/renovate.json`](renovate/renovate.json) for the complete configuration.

## Migration from Legacy Patterns

If you're using the old `vendor.yml` workflow pattern:

1. **Review the migration guide**: [docs/migration-guide.md](../docs/migration-guide.md)
2. **Update your workflow** to use `sync-leyline-content.yml@v1`
3. **Update configuration** to use new input parameters
4. **Test the migration** in a feature branch first

### Key Changes
- **Workflow name:** `vendor.yml` → `sync-leyline-content.yml`
- **Version reference:** Use `@v1` tag instead of specific versions in workflow reference
- **Required inputs:** Now requires `token` parameter
- **Output structure:** Content now synced to `target_path` (default: `docs/leyline`)

## Best Practices

1. **Version Pinning**: Always pin to specific Leyline versions (e.g., `v1.0.0`)
2. **PR Review**: Use `create_pr: true` to review changes before merging
3. **Selective Sync**: Only sync categories relevant to your project
4. **Regular Updates**: Use scheduled triggers for automatic updates
5. **Token Security**: Use `GITHUB_TOKEN` or secured PATs with minimal scopes

## Troubleshooting

For common issues and solutions, see the comprehensive example's troubleshooting section:
[`consumer-workflows/sync-leyline-example.yml`](consumer-workflows/sync-leyline-example.yml#L200)

## Need Help?

- 📚 **Full Documentation**: [docs/integration/pull-model-guide.md](../docs/integration/pull-model-guide.md)
- 🏷️ **Versioning Guide**: [docs/integration/versioning-guide.md](../docs/integration/versioning-guide.md)
- 🐛 **Questions & Issues**: [GitHub Issues](https://github.com/phrazzld/leyline/issues)
