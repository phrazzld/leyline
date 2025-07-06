# Required Status Checks Configuration

This document explains the required status checks configured for the leyline repository to ensure quality and consistency of all contributions.

## Overview

The leyline repository uses automated validation workflows that must pass before any pull request can be merged. This ensures that all documentation maintains high quality standards and adheres to our conciseness guidelines.

## Required Workflows

### 1. Content Validation (`validate`)

**Workflow**: `.github/workflows/validate.yml`
**Purpose**: Validates documentation structure, format, and length limits

**What it checks:**
- YAML front-matter validation in all markdown files
- Document length enforcement (tenets ≤100 lines, bindings ≤200 lines)
- Index file consistency
- GitHub Actions deprecation detection

**Key Features:**
- Content-only line counting (excludes YAML front-matter and empty lines)
- Warning levels at 100/200 lines, failure levels at 150/300 lines
- File-specific annotations for violations
- Detailed job summaries with validation results

### 2. Documentation Linting (`lint-docs`)

**Workflow**: `.github/workflows/ci.yml`
**Purpose**: Validates markdown structure and links

**What it checks:**
- Markdown syntax and structure
- Link validation (internal and external)
- File organization and naming conventions

## Configuration Details

### Repository Settings

The required status checks are configured via `.github/settings.yml` using the [probot/settings](https://github.com/probot/settings) GitHub App approach. This provides:

- **Version Control**: All repository settings are tracked in git
- **Transparency**: Changes to requirements are visible in pull requests
- **Consistency**: Settings can be replicated across multiple repositories
- **Automation**: No manual configuration required

### Status Check Requirements

```yaml
required_status_checks:
  strict: true  # Require branches to be up to date before merging
  checks:
    - context: "validate"      # Content validation workflow
      app_id: 15368           # GitHub Actions app ID
    - context: "lint-docs"     # Documentation linting workflow
      app_id: 15368           # GitHub Actions app ID
```

### Branch Protection Features

In addition to required status checks, the master branch includes:

- **Conversation Resolution**: All conversations must be resolved
- **Delete Branch on Merge**: Automatic cleanup of merged branches

Note: PR reviews are not required since this is a solo-maintained repository.

## Developer Workflow

### For Contributors

1. **Create Feature Branch**: Work on your changes in a dedicated branch
2. **Run Local Validation**: Use `ruby tools/enforce_doc_limits.rb --verbose` to check compliance
3. **Submit Pull Request**: All required checks run automatically
4. **Address Failures**: Fix any validation errors reported in PR comments
5. **Request Review**: Once checks pass, request review from maintainers

### For Maintainer

1. **Check Status**: Verify all required status checks are passing
2. **Resolve Conversations**: Address any feedback or questions
3. **Merge**: Use appropriate merge strategy (see [merge-strategy-selection.md](../docs/bindings/categories/git/merge-strategy-selection.md))

## Troubleshooting

### Common Validation Failures

**Document Length Violations:**
```
❌ Document length violation: 245 lines (exceeds 200 line limit)
```
**Solution**: Reduce document length by condensing examples, removing verbose explanations, or splitting into multiple focused documents.

**YAML Front-matter Errors:**
```
❌ Invalid YAML front-matter in docs/bindings/example.md
```
**Solution**: Ensure all binding and tenet files have valid YAML front-matter with required fields.

**Index Inconsistency:**
```
❌ Index file is out of date
```
**Solution**: Run `ruby tools/reindex.rb` to regenerate index files.

### Local Testing

Before submitting a pull request, run local validation:

```bash
# Essential validation (fast)
ruby tools/run_ci_checks.rb --essential

# Document length check
ruby tools/enforce_doc_limits.rb --verbose

# Full validation (comprehensive)
ruby tools/run_ci_checks.rb --full
```

## Exemption Process

In rare cases, exemptions may be granted for specific requirements:

1. **Document Length**: For complex technical topics that require detailed explanation
2. **Link Validation**: For references to private or development resources
3. **Special Cases**: Other justified technical requirements

**To request an exemption:**
1. Create an issue explaining the need for exemption
2. Tag repository maintainers for review
3. Provide detailed justification and alternative approaches considered
4. Wait for maintainer approval before proceeding

## Modification Process

Changes to required status checks should follow this process:

1. **Propose Changes**: Create an issue discussing the proposed changes
2. **Update Configuration**: Modify `.github/settings.yml` with new requirements
3. **Update Documentation**: Update this file to reflect changes
4. **Test Thoroughly**: Ensure new requirements work as expected
5. **Communicate Changes**: Notify contributors of requirement changes

## Related Documentation

- [Enforcement Script Documentation](../tools/enforce_doc_limits.rb)
- [CI Validation Pipeline](../tools/run_ci_checks.rb)
- [Document Length Guidelines](../TODO.md#overview)
- [Contributing Guidelines](../README.md)

## Support

For questions about required status checks or validation failures:

1. Check this documentation first
2. Review existing issues for similar problems
3. Create a new issue with detailed error information
4. Tag maintainers if urgent resolution is needed
