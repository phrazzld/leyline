# CI Compliance Verification Guide

This guide provides step-by-step instructions for verifying that your changes will pass CI validation before submitting a pull request. Following this checklist prevents CI failures and ensures smooth integration.

## Quick Pre-Submission Checklist

```bash
# 1. Document length compliance
ruby tools/enforce_doc_limits.rb

# 2. YAML front-matter validation
ruby tools/validate_front_matter.rb

# 3. Cross-references and indexes
ruby tools/fix_cross_references.rb
ruby tools/reindex.rb --strict

# 4. Pre-commit hook verification
git add . && git commit -m "test commit" --no-verify
git reset HEAD~1  # Shows formatting issues that need fixing
```

## Detailed Verification Steps

### 1. Document Length Validation

**Purpose**: Ensure all documents meet conciseness standards (≤100 lines for tenets, ≤200 lines for bindings)

```bash
# Check all documents
ruby tools/enforce_doc_limits.rb

# Check specific document
ruby tools/enforce_doc_limits.rb docs/bindings/core/api-design.md

# Check with verbose output (shows all files)
ruby tools/enforce_doc_limits.rb --verbose
```

**Expected Output**:
- ✅ `All documents are within length limits`
- ❌ If violations found, use systematic refactoring process

**If Violations Found**:
1. Review `docs/systematic-refactoring-process.md` for guidance
2. Review `docs/document-length-enforcement.md` for specific limits and strategies
3. Apply "one example rule" methodology
4. Focus on condensing verbose rationale sections
5. Convert prose rules to bullet points
6. Reduce to single comprehensive examples
7. Consider exemption process only as last resort

### 2. YAML Front-Matter Validation

**Purpose**: Verify all document metadata follows leyline standards

```bash
# Validate all documents
ruby tools/validate_front_matter.rb

# Validate specific document
ruby tools/validate_front_matter.rb -f docs/bindings/core/api-design.md
```

**Common Issues**:
- Missing required fields (`id`, `last_modified`, `version`, `derived_from`)
- Invalid date formats (must be YYYY-MM-DD)
- Incorrect YAML syntax
- Missing enforced_by field for bindings

**Quick Fix Examples**:
```yaml
---
id: my-binding-name
last_modified: '2025-06-17'
version: '0.1.0'
derived_from: modularity
enforced_by: 'Code review, linting tools'
---
```

### 3. Cross-Reference and Index Integrity

**Purpose**: Ensure all internal links work correctly and documents appear in indexes

```bash
# Fix cross-references automatically
ruby tools/fix_cross_references.rb

# Regenerate indexes with strict validation
ruby tools/reindex.rb --strict
```

**What This Checks**:
- Internal links resolve to existing documents
- Documents appear in appropriate index files
- Cross-reference formatting is correct
- No broken relative paths

### 4. Pre-Commit Hook Integration

**Purpose**: Verify changes will pass automated formatting checks

```bash
# Stage all changes
git add .

# Attempt commit with pre-commit hooks (use temporary message)
git commit -m "test commit for pre-commit verification"

# If hooks make changes, you'll see modified files to re-stage
git status

# If hooks passed, reset the temporary commit
git reset HEAD~1
```

**Common Pre-Commit Fixes**:
- Trailing whitespace removal
- Ensuring files end with newlines
- YAML formatting corrections
- Markdown formatting improvements

**If Pre-Commit Hooks Make Changes**:
1. Review what was changed: `git diff`
2. Re-stage the hook modifications: `git add .`
3. The changes are now ready for your actual commit

## Troubleshooting Common Issues

### Document Length Violations

**Problem**: Document exceeds length limits
**Solution**: Apply systematic refactoring methodology

```bash
# Check exact overage
ruby tools/enforce_doc_limits.rb docs/your-document.md

# Apply proven techniques:
# 1. Condense verbose rationale sections (most effective)
# 2. Single comprehensive examples (highly effective)
# 3. Convert prose rules to bullet points (effective)
# 4. Streamline related bindings (essential)

# If absolutely necessary, see exemption process:
# docs/enforcement-exemption-process.md
```

### YAML Front-Matter Errors

**Problem**: Invalid or missing metadata
**Solution**: Use consistent YAML format

```yaml
# For tenets
---
id: tenet-name
last_modified: '2025-06-17'
version: '0.1.0'
---

# For bindings
---
id: binding-name
last_modified: '2025-06-17'
version: '0.1.0'
derived_from: parent-tenet-name
enforced_by: 'Enforcement mechanism description'
---
```

### Cross-Reference Issues

**Problem**: Broken internal links after refactoring
**Solution**: Use fix_cross_references.rb tool

```bash
# Automatically fix common cross-reference issues
ruby tools/fix_cross_references.rb

# Verify fixes worked
ruby tools/reindex.rb --strict
```

### Pre-Commit Hook Failures

**Problem**: Formatting or validation failures during commit
**Solution**: Let hooks make corrections, then re-stage

```bash
# Common workflow for hook failures:
git add .
git commit -m "your commit message"
# Hooks run and may modify files
git add .  # Re-stage hook modifications
git commit -m "your commit message"  # Commit with corrections
```

## Best Practices for CI Success

### Prevention Strategies

1. **Monitor Document Growth**: Check lengths regularly during development
2. **Apply Conciseness Early**: Use "one example rule" from the start
3. **Regular Validation**: Run validation tools frequently, not just before PR
4. **Incremental Changes**: Make smaller, focused changes to reduce validation complexity

### Development Workflow Integration

```bash
# Daily development routine
git status  # Check current changes
ruby tools/enforce_doc_limits.rb  # Monitor document growth
ruby tools/validate_front_matter.rb  # Catch YAML issues early

# Before committing
git add .
git commit  # Let pre-commit hooks run and fix formatting

# Before PR submission
ruby tools/enforce_doc_limits.rb --verbose
ruby tools/validate_front_matter.rb
ruby tools/fix_cross_references.rb
ruby tools/reindex.rb --strict
```

### Emergency CI Fixes

If CI fails after PR submission:

```bash
# 1. Pull the latest changes
git pull origin main

# 2. Run full validation locally
ruby tools/enforce_doc_limits.rb
ruby tools/validate_front_matter.rb
ruby tools/fix_cross_references.rb
ruby tools/reindex.rb --strict

# 3. Fix any issues found
# (Use systematic refactoring process for length violations)

# 4. Commit fixes
git add .
git commit -m "fix: resolve CI validation issues"
git push
```

## Success Indicators

Your changes are ready for CI when:

- ✅ `ruby tools/enforce_doc_limits.rb` shows no violations
- ✅ `ruby tools/validate_front_matter.rb` passes without errors
- ✅ `ruby tools/fix_cross_references.rb` completes successfully
- ✅ `ruby tools/reindex.rb --strict` regenerates without issues
- ✅ Pre-commit hooks pass without making additional changes
- ✅ All modified documents maintain technical accuracy and essential content

## Related Documentation

- [Systematic Refactoring Process](systematic-refactoring-process.md) - Complete methodology for document refactoring
- [Document Length Enforcement](document-length-enforcement.md) - Detailed enforcement rules and strategies
- [Enforcement Exemption Process](enforcement-exemption-process.md) - How to request exemptions when necessary
- [CONTRIBUTING.md](../CONTRIBUTING.md) - General contribution guidelines
