# Leyline Integration Examples

This directory contains comprehensive examples for integrating Leyline standards into your project using different approaches based on your team's needs and preferences.

## 🛠️ Integration Approaches

Choose the integration method that best fits your project:

### 1. 📦 Git Submodule Integration
- **Best for:** Teams wanting the full Leyline ecosystem with automatic updates
- **Location:** [`consumer-git-submodule/`](consumer-git-submodule/)
- **Features:** Complete validation toolchain, automatic updates, centralized management

### 2. 📋 Direct Copy Integration
- **Best for:** Teams wanting selective standards adoption with customization
- **Location:** [`consumer-direct-copy/`](consumer-direct-copy/)
- **Features:** Cherry-pick specific standards, local customization, version control

### 3. 🔄 Pull-Based Synchronization
- **Best for:** Teams wanting automated content updates via workflows
- **Primary Example:** [`consumer-workflows/sync-leyline-example.yml`](consumer-workflows/sync-leyline-example.yml)
- **Features:** GitHub Actions automation, PR-based updates, scheduled sync

## 📖 Quick Start by Use Case

### 🚀 "I want to get started quickly"
→ **Use Direct Copy Integration**
```bash
# Download and run the copy script
curl -L https://raw.githubusercontent.com/phrazzld/leyline/main/examples/consumer-direct-copy/scripts/copy-leyline-standards.rb -o copy-standards.rb
ruby copy-standards.rb --interactive
```

### 🏢 "My team wants comprehensive governance"
→ **Use Git Submodule Integration**
```bash
# Add Leyline as a submodule
git submodule add https://github.com/phrazzld/leyline.git leyline
# Copy configuration template
cp leyline/examples/consumer-git-submodule/leyline-config.yml .
```

### ⚙️ "I want automated workflow-based updates"
→ **Use Pull-Based Synchronization**
```bash
# Copy the comprehensive workflow example
cp examples/consumer-workflows/sync-leyline-example.yml .github/workflows/sync-leyline.yml
```

## Directory Structure

```
examples/
├── consumer-git-submodule/       # Git submodule integration example
│   ├── README.md                 # Complete submodule integration guide
│   ├── leyline-config.yml        # Project configuration template
│   └── .github/workflows/        # Validation workflows
│       └── leyline-validation.yml
├── consumer-direct-copy/         # Direct copy integration example
│   ├── README.md                 # Direct copy integration guide
│   ├── standards-selection.yml   # Standards selection configuration
│   ├── scripts/                  # Copy and management scripts
│   │   └── copy-leyline-standards.rb
│   └── .github/workflows/        # Validation workflows
│       └── validate-standards.yml
├── consumer-workflows/           # Pull-based synchronization examples
│   └── sync-leyline-example.yml  # Comprehensive workflow example
├── github-workflows/             # Additional workflow patterns
│   ├── sync-leyline-content.yml  # Minimal quick-start example
│   ├── language-specific-sync.yml # Auto-detect languages example
│   ├── vendor-docs.yml           # DEPRECATED - old pattern
│   └── correct-vendor-docs.yml   # DEPRECATED - old pattern
├── pre-commit/                   # Pre-commit hook configurations
└── renovate/                     # Automated dependency update configurations
```

## Integration Guide

### Choose Your Integration Method

Select the integration approach that best matches your team's workflow and requirements:

#### 🏗️ Git Submodule Integration
Perfect for teams that want the full Leyline ecosystem with automatic updates and comprehensive validation.

```bash
# Add Leyline as a submodule
git submodule add https://github.com/phrazzld/leyline.git leyline

# Copy configuration template
cp leyline/examples/consumer-git-submodule/leyline-config.yml .

# Copy validation workflow
mkdir -p .github/workflows
cp leyline/examples/consumer-git-submodule/.github/workflows/leyline-validation.yml .github/workflows/

# Initialize and update submodule
git submodule update --init --recursive
```

#### 📝 Direct Copy Integration
Ideal for teams that want to selectively adopt specific standards with customization options.

```bash
# Download the copy script
curl -L https://raw.githubusercontent.com/phrazzld/leyline/main/examples/consumer-direct-copy/scripts/copy-leyline-standards.rb -o scripts/copy-leyline-standards.rb
chmod +x scripts/copy-leyline-standards.rb

# Copy selection configuration template
curl -L https://raw.githubusercontent.com/phrazzld/leyline/main/examples/consumer-direct-copy/standards-selection.yml -o .leyline-selection.yml

# Run interactive selection or use config
ruby scripts/copy-leyline-standards.rb --interactive
# OR
ruby scripts/copy-leyline-standards.rb --config .leyline-selection.yml
```

#### ⚙️ Pull-Based Synchronization (GitHub Actions)
Great for teams that want automated workflow-based updates with PR review processes.

```bash
# Create the workflows directory
mkdir -p .github/workflows

# Copy the comprehensive example
cp examples/consumer-workflows/sync-leyline-example.yml .github/workflows/sync-leyline.yml

# Customize configuration and commit
```

### Available Examples

#### 🏗️ Git Submodule Integration Examples
- **Location:** `consumer-git-submodule/`
- **Use case:** Complete Leyline ecosystem integration with submodules
- **Best for:** Teams wanting full governance, automatic updates, comprehensive validation
- **Includes:** Configuration templates, validation workflows, team onboarding guides

#### 📝 Direct Copy Integration Examples
- **Location:** `consumer-direct-copy/`
- **Use case:** Selective standards adoption with local customization
- **Best for:** Teams wanting specific standards, customization control, version pinning
- **Includes:** Copy scripts, selection configuration, validation workflows, update management

#### ⚙️ Pull-Based Synchronization Examples

##### 🌟 Comprehensive Workflow Example
- **File:** `consumer-workflows/sync-leyline-example.yml`
- **Use case:** Full-featured GitHub Actions integration with all options documented
- **Best for:** Production use, learning all features, automated updates

##### 🚀 Minimal Workflow Example
- **File:** `github-workflows/sync-leyline-content.yml`
- **Use case:** Quick start with basic configuration
- **Best for:** Simple projects, getting started quickly

##### 🔍 Language Detection Example
- **File:** `github-workflows/language-specific-sync.yml`
- **Use case:** Automatically detect and sync only relevant language bindings
- **Best for:** Multi-language projects, dynamic teams

## 🤔 Which Integration Method Should I Choose?

| Factor | Git Submodule | Direct Copy | Pull-Based Sync |
|--------|---------------|-------------|-----------------|
| **Setup Complexity** | Medium | Low | Medium |
| **Maintenance** | Low | Medium | Low |
| **Customization** | Limited | High | Medium |
| **Update Control** | Automatic | Manual | Scheduled |
| **Team Onboarding** | Included | DIY | DIY |
| **Validation Tools** | Comprehensive | Basic | Custom |
| **Version Pinning** | Git-based | Explicit | Workflow-based |
| **Local Changes** | Not recommended | Supported | Not applicable |

### Decision Matrix

- **Choose Git Submodule if:** You want comprehensive governance, automatic updates, and don't need customization
- **Choose Direct Copy if:** You want selective adoption, need local customization, or have specific compliance requirements
- **Choose Pull-Based Sync if:** You want automated updates with PR review, or need to integrate with existing workflows

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
