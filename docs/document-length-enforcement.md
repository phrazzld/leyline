# Document Length Enforcement Rules

This document explains Leyline's document length enforcement system, which ensures all tenets and bindings remain concise and focused for optimal AI agent consumption and human readability.

## Overview

Leyline enforces strict line limits on documentation to maintain clarity and prevent document bloat:

- **Tenets**: Maximum 100 lines (warning), 150 lines (failure)
- **Bindings**: Maximum 200 lines (warning), 300 lines (failure)

These limits apply to content lines only, excluding:
- YAML front-matter
- Empty lines
- Whitespace-only lines

## Enforcement Script

The enforcement is handled by `tools/enforce_doc_limits.rb`, which:

1. Scans all documents in `docs/tenets/` and `docs/bindings/`
2. Counts content lines (excluding front-matter and empty lines)
3. Reports warnings for documents approaching limits
4. Fails CI for documents exceeding hard limits

### Usage

```bash
# Check all documents
ruby tools/enforce_doc_limits.rb

# Check with verbose output (shows all files)
ruby tools/enforce_doc_limits.rb --verbose

# Check specific file
ruby tools/enforce_doc_limits.rb docs/tenets/simplicity.md
```

### Output Examples

**Success (verbose mode)**:
```
Checking tenets...
✓ docs/tenets/simplicity.md: 54 lines (OK)
✓ docs/tenets/testability.md: 89 lines (OK)

Checking bindings...
✓ docs/bindings/core/api-design.md: 178 lines (OK)

✅ All documents within limits!
```

**Warnings**:
```
⚠️  Warnings (approaching limits):
  docs/tenets/complex-topic.md: 95 lines (warn at 100)
  docs/bindings/core/large-binding.md: 195 lines (warn at 200)
```

**Failures**:
```
❌ Violations (exceeding limits):
  docs/tenets/oversized-tenet.md: 160 lines (limit: 150)
  docs/bindings/core/verbose-binding.md: 320 lines (limit: 300)

Summary:
  2 files exceed limits
  0 files approaching limits
```

## CI Integration

The enforcement script runs automatically in GitHub Actions on:
- Every push to master/main
- Every pull request

The CI workflow (`/.github/workflows/validate.yml`) includes:

1. **Pre-check phase**: Validates environment and tools
2. **Essential validation**: YAML and index consistency
3. **Document length enforcement**: Runs with verbose output
4. **Annotations**: Creates warnings/errors on specific files

### CI Behavior

- **Warnings**: Shown in CI logs but don't block merge
- **Failures**: Block PR merge until resolved
- **Annotations**: Appear directly on PR files tab

## Handling Violations

When a document exceeds limits:

### 1. Understand the Current Length

```bash
# Get exact line count
ruby tools/enforce_doc_limits.rb docs/bindings/core/my-binding.md
```

### 2. Apply Reduction Strategies

**For Tenets (target: <100 lines)**:
- Focus on one core principle
- Remove implementation details (save for bindings)
- Eliminate redundant examples
- Condense rationale to 1-2 paragraphs

**For Bindings (target: <200 lines)**:
- Keep one comprehensive example
- Convert verbose explanations to bullet points
- Remove duplicate configuration samples
- Link to external resources instead of embedding

### 3. Common Reduction Patterns

**Before**:
```markdown
## Why This Matters

This principle is important because...
[10 lines of explanation]

Furthermore, it helps with...
[8 more lines]

In practice, this means...
[12 lines of elaboration]
```

**After**:
```markdown
## Why This Matters

This principle ensures code maintainability by enforcing clear boundaries
between components, reducing coupling, and enabling independent evolution.
```

### 4. Validate Changes

```bash
# Verify reduction
ruby tools/enforce_doc_limits.rb docs/bindings/core/my-binding.md

# Run full CI validation locally
ruby tools/run_ci_checks.rb --essential
```

## Exemption Process

In rare cases where a document legitimately requires more lines:

### 1. Temporary Exemptions (Not Recommended)

Currently, the enforcement script does not support exemptions. All documents must meet the limits.

### 2. Requesting Permanent Exemptions

If you believe a document requires an exemption:

1. **Justify the need**: Document why standard limits cannot work
2. **Attempt reduction first**: Show what was tried and why it failed
3. **Create an issue**: Tag with `enforcement-exemption`
4. **Propose alternatives**:
   - Split into multiple documents
   - Move details to external references
   - Create supplementary guides

### 3. Future Exemption Support

A future enhancement may add exemption support via:
- `.enforcement-exemptions.yml` configuration file
- YAML front-matter exemption flags
- Category-specific limit overrides

## Best Practices

### Writing Within Limits

1. **Start concise**: Write to target length from the beginning
2. **One example rule**: Use one comprehensive example instead of many
3. **Bullet points**: Prefer lists over prose paragraphs
4. **External links**: Reference detailed guides instead of embedding
5. **Focus sharply**: Each document should have one clear purpose

### Regular Maintenance

```bash
# Check all documents periodically
ruby tools/enforce_doc_limits.rb --verbose

# Monitor approaching limits
ruby tools/enforce_doc_limits.rb | grep "warn at"
```

### Pre-Commit Validation

Add to your workflow:
```bash
# Before committing documentation changes
ruby tools/enforce_doc_limits.rb || echo "Fix document lengths before commit"
```

## Rationale

These limits ensure:

1. **AI Agent Efficiency**: Shorter documents process faster and fit better in context windows
2. **Human Readability**: Concise documents are easier to scan and understand
3. **Maintenance**: Shorter documents are easier to keep accurate and up-to-date
4. **Consistency**: Uniform expectations across all documentation
5. **Quality**: Forces authors to distill content to essential information

## Troubleshooting

### Script Not Found

```bash
# Ensure you're in repository root
pwd  # Should show .../leyline

# Check script exists
ls -la tools/enforce_doc_limits.rb
```

### Different Results Locally vs CI

- Ensure you're checking the same files
- Verify no uncommitted changes
- Check for differences in line endings (CRLF vs LF)

### Need Help?

- Review existing concise documents as examples
- Ask in PR comments for reduction suggestions
- Consult the [Systematic Refactoring Process](./systematic-refactoring-process.md)
