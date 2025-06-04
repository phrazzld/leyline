# Migration Guide

This guide covers migration scenarios for adopting or upgrading your Leyline integration:

1. **[Migrating from Symlinks to Leyline](#migrating-from-symlinks-to-leyline)** - For repositories using symlinked philosophy documents
2. **[Migrating from Legacy Workflows](#migrating-from-legacy-workflows)** - For repositories using the old vendor.yml workflow
3. **[Migrating to Directory-Based Structure](#migrating-to-directory-based-structure)** - For existing Leyline users updating to the new directory-based structure
4. **[Migrating to Enhanced Pragmatic Programming Tenets](#migrating-to-enhanced-pragmatic-programming-tenets)** - For existing Leyline users adopting the expanded 12-tenet system

For comprehensive integration instructions, see the [Pull-Based Integration Guide](integration/pull-model-guide.md).

---

# Migrating from Symlinks to Leyline

If your repository currently uses symlinked philosophy documents, follow this guide to migrate to Leyline's pull-based content synchronization.

## Step-by-Step Migration Process

### 1. Remove Old Symlinks

```bash
# Remove the old symlinked files
git rm docs/DEVELOPMENT_PHILOSOPHY*.md

# Commit the removal
git commit -m "chore: remove symlinked philosophy documents"
```

### 2. Create Leyline Sync Workflow

Create `.github/workflows/sync-leyline.yml`:

```yaml
name: Sync Leyline Content
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Mondays
  workflow_dispatch:     # Allow manual triggers

jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0  # Pin to specific version
      categories: go,typescript,frontend  # Customize for your tech stack
      target_path: docs/leyline
      create_pr: true
```

### 3. Configure Workflow

**Required Configuration:**
- `token`: GitHub token with repo write permissions
- `leyline_ref`: Specific Leyline version (never use `main`)

**Optional Configuration:**
- `categories`: Comma-separated list of relevant categories
- `target_path`: Where to place Leyline content (default: `docs/leyline`)
- `create_pr`: Whether to create PR (recommended: `true`)

**Available Categories:**
- **Languages**: `go`, `rust`, `typescript`
- **Contexts**: `frontend`, `backend`

### 4. Activate the Workflow

```bash
# Add and commit the workflow
git add .github/workflows/sync-leyline.yml
git commit -m "feat: add Leyline content synchronization"
git push
```

### 5. Review and Merge Initial Sync

1. **Automatic Sync**: The workflow runs and creates a PR with Leyline content
2. **Review PR**: Check the synced tenets and bindings
3. **Merge PR**: Complete the migration by merging the PR

## What Happens Next

- **Scheduled Updates**: Workflow runs weekly to check for updates
- **Manual Updates**: Trigger via GitHub Actions UI when needed
- **Version Control**: Team reviews all changes via pull requests
- **Selective Sync**: Only categories relevant to your project are included

For detailed configuration options, see the [comprehensive workflow example](../examples/consumer-workflows/sync-leyline-example.yml).

---

# Migrating from Legacy Workflows

If your repository uses the old `vendor.yml` workflow, follow this guide to migrate to the new `sync-leyline-content.yml` workflow.

## Why Migrate?

The new workflow provides:
- **Enhanced Security**: Explicit token management
- **Better Control**: More configuration options and outputs
- **Improved Reliability**: Better error handling and logging
- **Future Support**: Active development and maintenance

## Before and After Comparison

### Old Workflow (vendor.yml)
```yaml
jobs:
  docs:
    uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0
    with:
      ref: v1.0.0
      categories: go,typescript
```

### New Workflow (sync-leyline-content.yml)
```yaml
jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}  # Now required
      leyline_ref: v1.0.0                # Renamed from 'ref'
      categories: go,typescript           # Same format
      target_path: docs/leyline          # New: customizable path
      create_pr: true                    # New: PR control
```

## Migration Steps

### Step 1: Update Workflow Reference

In your `.github/workflows/*.yml` file:

**Change:**
```yaml
uses: phrazzld/leyline/.github/workflows/vendor.yml@v1.0.0
```

**To:**
```yaml
uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
```

### Step 2: Update Input Parameters

| Old Parameter | New Parameter | Notes |
|---------------|---------------|-------|
| `ref` | `leyline_ref` | Renamed for clarity |
| N/A | `token` | **Required**: `${{ secrets.GITHUB_TOKEN }}` |
| `categories` | `categories` | Same format |
| N/A | `target_path` | Optional: customize destination |
| N/A | `create_pr` | Optional: control PR creation |

### Step 3: Add Required Token

Add the token parameter to your workflow:

```yaml
with:
  token: ${{ secrets.GITHUB_TOKEN }}
  # ... other parameters
```

### Step 4: Test the Migration

1. **Create Feature Branch**: Test changes before applying to main
2. **Manual Trigger**: Use `workflow_dispatch` to test manually
3. **Verify Output**: Check that sync works as expected
4. **Review PR**: Ensure content is synced correctly

### Step 5: Update Additional Configurations

**Optional Enhancements:**
```yaml
with:
  token: ${{ secrets.GITHUB_TOKEN }}
  leyline_ref: v1.0.0
  categories: go,typescript,frontend
  target_path: docs/leyline                    # Customize location
  create_pr: true                             # Enable PR workflow
  commit_message: "docs: update standards"    # Custom commit message
  pr_title: "Update Development Standards"    # Custom PR title
```

## Migration Troubleshooting

### Common Issues

**"Resource not accessible by integration"**
- **Cause**: Missing or insufficient token permissions
- **Solution**: Ensure `token: ${{ secrets.GITHUB_TOKEN }}` is included

**"Invalid leyline_ref provided"**
- **Cause**: Using old parameter name or invalid version
- **Solution**: Use `leyline_ref` (not `ref`) with valid version

**"Workflow file seems to have an issue"**
- **Cause**: Syntax error in updated workflow
- **Solution**: Validate YAML syntax and parameter format

**No PR created after migration**
- **Cause**: `create_pr` disabled or permission issues
- **Solution**: Set `create_pr: true` and check repo permissions

### Validation Checklist

After migration, verify:
- [ ] Workflow runs without errors
- [ ] Content syncs to expected location
- [ ] PR is created with appropriate title
- [ ] All requested categories are included
- [ ] No old-format files remain

---

# Migrating to Directory-Based Structure

For existing Leyline users updating to the new hierarchical directory structure.

## What's Changing?

### Old Structure (Flat)
```
docs/bindings/
├── 00-index.md
├── pure-functions.md           # Core binding
├── ts-no-any.md               # TypeScript binding
└── go-error-wrapping.md       # Go binding
```

### New Structure (Hierarchical)
```
docs/bindings/
├── core/
│   ├── 00-index.md
│   └── pure-functions.md      # Core bindings
├── categories/
│   ├── typescript/
│   │   └── no-any.md          # TypeScript-specific
│   └── go/
│       └── error-wrapping.md  # Go-specific
└── 00-index.md               # Combined index
```

## Migration Process

### Step 1: Update Workflow Configuration

Add explicit `categories` parameter to your workflow:

```yaml
jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.0.0
      categories: go,typescript,frontend  # Specify your categories
```

### Step 2: Run Updated Workflow

The workflow automatically:
1. **Cleans up** old flat-structure files
2. **Syncs core** bindings to `docs/bindings/core/`
3. **Syncs categories** to `docs/bindings/categories/<category>/`
4. **Regenerates index** to reflect new structure
5. **Creates PR** with migration details

### Step 3: Review Migration PR

The PR will show:
- Files removed from old structure
- New hierarchical organization
- Updated index with proper sections
- Any warnings for missing categories

### Step 4: Update Internal References

If your project references binding files directly:

**Update paths:**
```markdown
<!-- Old -->
[Pure Functions](docs/bindings/pure-functions.md)

<!-- New -->
[Pure Functions](docs/bindings/core/pure-functions.md)
```

## Understanding the New Structure

### Core vs. Category Bindings

**Core Bindings** (`docs/bindings/core/`):
- Apply universally across all projects
- Technology-agnostic principles
- Always synced regardless of categories

**Category Bindings** (`docs/bindings/categories/<category>/`):
- Apply to specific languages or contexts
- Technology-specific implementations
- Synced only when category is requested

### Benefits of New Structure

1. **Explicit Control**: Choose exactly which categories to sync
2. **Cleaner Organization**: Clear separation of concerns
3. **Reduced Noise**: Only relevant bindings in your project
4. **Better Scaling**: Easy to add new categories without conflicts

---

# Migrating to Enhanced Pragmatic Programming Tenets

For existing Leyline users upgrading from the original 8-tenet system to the enhanced 12-tenet system with pragmatic programming integration.

## What's Changing?

### Philosophy Expansion: 8 to 12 Tenets

Leyline has evolved from 8 foundational tenets to 12, incorporating insights from "The Pragmatic Programmer" and modern software engineering practices.

#### Original 8 Tenets (Enhanced)
- [Simplicity](../tenets/simplicity.md) - Enhanced with YAGNI principles and tracer bullets
- [Explicit over Implicit](../tenets/explicit-over-implicit.md) - Enhanced with crash early patterns
- [Maintainability](../tenets/maintainability.md) - Enhanced with knowledge portfolio investment
- [Testability](../tenets/testability.md) - Enhanced with property-based testing
- [Modularity](../tenets/modularity.md) - Unchanged
- [Automation](../tenets/automation.md) - Unchanged
- [Document Decisions](../tenets/document-decisions.md) - Unchanged
- [No Secret Suppression](../tenets/no-secret-suppression.md) - Unchanged

#### New 4 Tenets (Pragmatic Programming)
- [Orthogonality](../tenets/orthogonality.md) - Component independence and isolation
- [DRY (Don't Repeat Yourself)](../tenets/dry-dont-repeat-yourself.md) - Knowledge representation management
- [Adaptability and Reversibility](../tenets/adaptability-and-reversibility.md) - Change management and flexible architecture
- [Fix Broken Windows](../tenets/fix-broken-windows.md) - Quality management and immediate action

### New and Enhanced Bindings

The enhanced philosophy includes new bindings that implement pragmatic programming concepts:

#### New Core Bindings
- [yagni-pattern-enforcement](../bindings/core/yagni-pattern-enforcement.md) - YAGNI implementation patterns
- [fail-fast-validation](../bindings/core/fail-fast-validation.md) - Crash early patterns
- [continuous-learning-investment](../bindings/core/continuous-learning-investment.md) - Knowledge portfolio management
- [property-based-testing](../bindings/core/property-based-testing.md) - Property-based testing approaches
- [system-boundaries](../bindings/core/system-boundaries.md) - Component isolation and orthogonality
- [extract-common-logic](../bindings/core/extract-common-logic.md) - DRY implementation patterns
- [feature-flag-management](../bindings/core/feature-flag-management.md) - Adaptability patterns
- [automated-quality-gates](../bindings/core/automated-quality-gates.md) - Quality management automation

#### Enhanced Category-Specific Bindings
- [functional-composition-patterns](../bindings/categories/typescript/functional-composition-patterns.md) - TypeScript functional patterns
- [dependency-injection-patterns](../bindings/categories/go/dependency-injection-patterns.md) - Go dependency management
- [trait-composition-patterns](../bindings/categories/rust/trait-composition-patterns.md) - Rust trait composition

## Breaking Changes and Considerations

### No Breaking Changes to Existing Content
- **Existing tenets remain valid**: The original 8 tenets are enhanced, not replaced
- **Existing bindings continue to work**: No changes to established binding patterns
- **Backward compatibility maintained**: Teams can adopt new concepts incrementally

### Philosophical Considerations

#### Enhanced Tenet Content
Some existing tenets now include additional concepts that teams should be aware of:

- **Simplicity**: Now emphasizes YAGNI principles more strongly
- **Explicit over Implicit**: Includes crash early patterns that may require validation strategy changes
- **Maintainability**: Emphasizes knowledge portfolio investment and continuous learning
- **Testability**: Introduces property-based testing concepts alongside existing approaches

#### New Tenet Integration
The four new tenets introduce concepts that may overlap with existing practices:

- **Orthogonality vs. Modularity**: Both focus on separation, but orthogonality emphasizes eliminating effects between unrelated components
- **DRY vs. Simplicity**: DRY focuses on knowledge representation, while simplicity focuses on design clarity
- **Adaptability vs. Maintainability**: Both support long-term sustainability, but adaptability emphasizes change management

## Migration Process

### Step 1: Update Leyline Version

Update your workflow to use the latest Leyline version that includes the enhanced tenets:

```yaml
jobs:
  sync:
    uses: phrazzld/leyline/.github/workflows/sync-leyline-content.yml@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      leyline_ref: v1.1.0  # Update to version with enhanced tenets
      categories: go,typescript,frontend
```

### Step 2: Review Enhanced Content

The sync will automatically pull:
- Enhanced versions of existing tenets with new pragmatic concepts
- Four new tenets with foundational content
- New and enhanced bindings implementing pragmatic patterns

### Step 3: Assess Team Readiness

Consider your team's readiness for the expanded philosophy:

#### Immediate Adoption (Low Risk)
- Enhanced existing tenets - build on familiar concepts
- Fix Broken Windows - immediately actionable quality management
- Core bindings for crash early and YAGNI patterns

#### Gradual Adoption (Medium Risk)
- Orthogonality principles - may require architectural discussions
- DRY implementation - may require refactoring analysis
- Property-based testing - may require tooling and training

#### Strategic Planning (Long-term)
- Adaptability patterns - architectural planning and feature flag infrastructure
- Knowledge portfolio investment - learning and development planning
- Advanced composition patterns - requires language-specific expertise

### Step 4: Create Adoption Plan

**Phase 1: Enhanced Existing Tenets (Weeks 1-2)**
1. Review enhanced simplicity guidance for YAGNI opportunities
2. Implement crash early patterns from enhanced explicitness
3. Apply immediate quality management from fix broken windows
4. Assess property-based testing opportunities

**Phase 2: New Core Concepts (Weeks 3-6)**
1. Analyze system boundaries for orthogonality improvements
2. Identify DRY opportunities in current codebase
3. Plan adaptability infrastructure (feature flags, configuration)
4. Implement automated quality gates

**Phase 3: Advanced Integration (Months 2-3)**
1. Apply language-specific composition patterns
2. Establish knowledge portfolio practices
3. Integrate adaptability patterns into architecture decisions
4. Validate philosophical alignment across all practices

### Step 5: Validate Adoption

Use these criteria to assess successful migration:

- [ ] Team understands distinctions between all 12 tenets
- [ ] Enhanced existing tenets are integrated into current practices
- [ ] New bindings are applied appropriately to relevant code
- [ ] No conflicts between pragmatic concepts and existing standards
- [ ] Team can articulate when to apply each tenet and binding

## Common Migration Concerns

### "Too Many Tenets - Overwhelming Complexity"
**Concern**: 12 tenets seem like too many to manage effectively

**Response**: The 8 original tenets remain unchanged in spirit, with pragmatic enhancements that make them more actionable. The 4 new tenets address gaps in architectural thinking and quality management that most teams already practice informally.

**Solution**: Adopt incrementally, starting with enhanced existing tenets

### "Philosophical Conflicts with Current Practices"
**Concern**: New tenets might conflict with established team practices

**Response**: Pragmatic programming tenets are designed to complement, not replace, existing good practices. They formalize patterns that effective teams already use.

**Solution**: Map current practices to new tenets to identify alignment and gaps

### "Implementation Overhead"
**Concern**: New bindings require significant implementation effort

**Response**: Bindings provide implementation guidance, not mandatory requirements. Teams can adopt patterns that provide value in their context.

**Solution**: Prioritize bindings based on current pain points and improvement opportunities

### "Learning Curve for New Concepts"
**Concern**: Team needs training on pragmatic programming concepts

**Response**: Most concepts align with existing industry best practices. The tenets provide structured guidance for familiar challenges.

**Solution**: Use enhanced tenets as learning opportunities and gradual skill development

## Validation Checklist

After completing the migration:

- [ ] All 12 tenets are accessible and understood by the team
- [ ] Enhanced existing tenets are integrated into code review processes
- [ ] New bindings are applied to appropriate areas of the codebase
- [ ] Team can explain the relationship between tenets and practical implementation
- [ ] No regression in existing quality practices or philosophical alignment
- [ ] Team has a plan for ongoing adoption of advanced pragmatic concepts

---

# Troubleshooting

## Common Issues

### Workflow Errors

**"Token permission issues"**
- **Symptoms**: "Resource not accessible by integration"
- **Solutions**:
  - Ensure `token: ${{ secrets.GITHUB_TOKEN }}` is included
  - Check repository Actions permissions
  - Verify organization SSO settings

**"Invalid workflow reference"**
- **Symptoms**: "Could not resolve to a Repository"
- **Solutions**:
  - Use `sync-leyline-content.yml@v1` (not `vendor.yml`)
  - Verify workflow file syntax
  - Check for typos in repository reference

### Content Issues

**"Missing requested categories"**
- **Symptoms**: Warnings in PR about non-existent categories
- **Solutions**:
  - Check category spelling: `go`, `rust`, `typescript`, `frontend`, `backend`
  - Verify categories exist in the Leyline version you're using
  - Update to newer Leyline version if category was added later

**"No changes detected"**
- **Symptoms**: Workflow runs but no PR is created
- **Solutions**:
  - Content is already up-to-date (normal behavior)
  - Check if workflow is configured correctly
  - Verify `leyline_ref` points to different version

### Repository Setup Issues

**"Workflow doesn't trigger"**
- **Symptoms**: Scheduled workflow never runs
- **Solutions**:
  - Ensure workflow is on main/default branch
  - Check Actions are enabled for repository
  - Verify cron syntax in schedule trigger

**"PRs aren't created"**
- **Symptoms**: Workflow runs but no PR appears
- **Solutions**:
  - Verify `create_pr: true` in workflow
  - Check repository allows Actions to create PRs
  - Ensure no branch protection conflicts

## Getting Help

### Self-Service Resources

1. **Check workflow logs** in GitHub Actions tab
2. **Review this migration guide** for common scenarios
3. **Consult the comprehensive guide**: [Pull-Based Integration Guide](integration/pull-model-guide.md)
4. **See working examples**: [Consumer Workflow Examples](../examples/consumer-workflows/)

### Community Support

- **Questions & Bug Reports**: [GitHub Issues](https://github.com/phrazzld/leyline/issues)
- **Feature Requests**: [GitHub Issues](https://github.com/phrazzld/leyline/issues) with "enhancement" label

### When Reporting Issues

Include:
- Complete workflow configuration
- Error messages from workflow logs
- Leyline version being used (`leyline_ref`)
- Repository settings (if relevant)

---

## Related Documentation

- **[Pull-Based Integration Guide](integration/pull-model-guide.md)**: Comprehensive setup instructions
- **[Versioning Guide](integration/versioning-guide.md)**: Version management best practices
- **[Consumer Workflow Examples](../examples/consumer-workflows/)**: Working configuration examples

---

**Note**: All migrations are one-time processes. Once completed, future syncs will use the current workflow and structure automatically.
