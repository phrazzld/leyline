# CI Failure Prevention Guide

*Comprehensive guide to preventing CI failures through local validation and best practices.*

## Overview

CI failures interrupt development flow and create friction in the development process. This guide provides systematic approaches to prevent common CI failures by catching issues locally before they reach the CI pipeline.

Our local CI simulation tool (`tools/run_ci_checks.rb`) replicates the entire CI validation pipeline, enabling developers to catch and fix issues before pushing code.

## Quick Start

**Essential Command:**
```bash
# Run before every push to prevent CI failures
ruby tools/run_ci_checks.rb
```

**Development Iteration:**
```bash
# Faster feedback during development (skips external link checking)
ruby tools/run_ci_checks.rb --skip-external-links
```

## Common CI Failure Types

Based on our experience with CI001-CI004 failure patterns, here are the most common issues and their prevention:

### 1. YAML Front-matter Validation Failures

**Symptoms:**
- CI fails with "Invalid YAML front-matter" errors
- Missing or malformed metadata in binding/tenet files

**Root Causes:**
- Missing required fields (id, version, derived_from, etc.)
- YAML syntax errors (incorrect indentation, quotes, etc.)
- Invalid field values or formats

**Prevention:**
```bash
# Validate all YAML front-matter
ruby tools/validate_front_matter.rb

# Validate specific file during editing
ruby tools/validate_front_matter.rb -f docs/bindings/categories/typescript/your-binding.md

# Enable structured logging for detailed error information
LEYLINE_STRUCTURED_LOGGING=true ruby tools/validate_front_matter.rb
```

**Quick Fix Checklist:**
- [ ] All required fields present: `id`, `version`, `derived_from`, `enforced_by`
- [ ] Proper YAML syntax (indentation, quotes)
- [ ] Valid values for each field
- [ ] No trailing spaces or special characters

### 2. TypeScript Configuration Validation Failures

**Symptoms:**
- ESLint parser errors in CI
- TypeScript binding validation failures
- "Unexpected token" errors in configuration files

**Root Causes:**
- Incorrect ESLint parser configuration for TypeScript files
- Missing or misconfigured ignore patterns
- Invalid TypeScript/ESLint configuration syntax

**Prevention:**
```bash
# Validate TypeScript binding configurations
ruby tools/validate_typescript_bindings.rb

# Get detailed validation output
ruby tools/validate_typescript_bindings.rb --verbose

# Test specific ESLint configuration
cd examples/typescript-full-toolchain && pnpm run lint
```

**Configuration Validation Checklist:**
- [ ] ESLint parser correctly configured for .ts/.tsx files
- [ ] Proper ignore patterns for generated files (dist/, coverage/, etc.)
- [ ] Valid TypeScript configuration syntax
- [ ] All referenced packages installed in dependencies

### 3. Security Scan False Positives

**Symptoms:**
- Gitleaks detecting "secrets" in documentation examples
- Security scan failures on example code
- False positive API key detections

**Root Causes:**
- Realistic-looking example secrets triggering detection
- Documentation examples formatted like real credentials
- Missing .gitleaksignore patterns for test files

**Prevention:**
```bash
# Test security scanning locally
gitleaks detect --source=. --no-git

# Get detailed findings
gitleaks detect --source=. --no-git --verbose

# Test specific directory
gitleaks detect --source=docs/bindings/categories/typescript/ --no-git
```

**Secure Documentation Patterns:**
```typescript
// ✅ GOOD: Use explicit redaction markers
const config = {
  apiKey: 'sk_live_[REDACTED]',      // Clear redaction marker
  token: '[YOUR_API_TOKEN_HERE]',    // Template-style placeholder
  secret: 'whsec_[EXAMPLE]'          // Example indicator
};

// ❌ BAD: Realistic-looking secrets
const badConfig = {
  apiKey: 'sk_live_abc123xyz789',    // Looks like real Stripe key
  token: 'ghp_1a2b3c4d5e6f7g8h'      // Looks like real GitHub token
};
```

### 4. Dependency Security Vulnerabilities

**Symptoms:**
- pnpm audit failures
- Moderate/high severity vulnerabilities in dependencies
- Supply chain security issues

**Root Causes:**
- Outdated dependencies with known vulnerabilities
- Missing security overrides for transitive dependencies
- Inadequate dependency update processes

**Prevention:**
```bash
# Audit dependencies for security issues
cd examples/typescript-full-toolchain && pnpm audit --audit-level=moderate

# Check for available updates
pnpm outdated

# Verify license compliance
pnpm run security:licenses
```

**Security Maintenance:**
- Update dependencies regularly
- Use security overrides for known vulnerabilities
- Monitor security advisories for used packages
- Implement automated dependency scanning

### 5. Cross-reference Link Validation

**Symptoms:**
- Broken internal links in documentation
- References to non-existent tenet or binding files
- Navigation failures in rendered documentation

**Root Causes:**
- File paths changed without updating references
- Typos in link URLs
- Missing or moved documentation files

**Prevention:**
```bash
# Validate all cross-references
ruby tools/validate_cross_references.rb

# Fix broken internal links automatically
ruby tools/fix_cross_references.rb

# Verbose output for debugging
ruby tools/validate_cross_references.rb -v
```

## Troubleshooting Guide

### When run_ci_checks.rb Fails

1. **Identify the failing validation step** from the output
2. **Run the specific validation tool** with verbose output
3. **Fix the root cause** using the guidance above
4. **Re-run the local CI simulation** to verify the fix

**Example debugging workflow:**
```bash
# Step 1: Run full validation to identify failures
ruby tools/run_ci_checks.rb

# Step 2: If TypeScript validation fails, debug specifically
ruby tools/validate_typescript_bindings.rb --verbose

# Step 3: If security scan fails, check detailed findings
gitleaks detect --source=. --no-git --verbose

# Step 4: Re-run validation after fixes
ruby tools/run_ci_checks.rb --skip-external-links
```

### Common Error Patterns

**YAML Validation Errors:**
```
Error: Invalid YAML front-matter in docs/bindings/categories/typescript/binding.md
```
→ Check YAML syntax, required fields, and indentation

**Security Scan Errors:**
```
Warning: leaks found: 3
```
→ Check for realistic-looking secrets in documentation

**TypeScript Validation Errors:**
```
ESLint parsing error: Unexpected token
```
→ Check ESLint configuration and TypeScript parser setup

## Development Workflow Integration

### Daily Development Workflow

```bash
# 1. Before starting work
git pull origin main

# 2. Create feature branch
git checkout -b feature/your-feature

# 3. During development (frequent validation)
ruby tools/run_ci_checks.rb --skip-external-links

# 4. Before committing major changes
ruby tools/run_ci_checks.rb

# 5. Before pushing to remote
ruby tools/run_ci_checks.rb && git push
```

### Pre-commit Hook Integration

Create `.git/hooks/pre-push` for automatic validation:

```bash
#!/bin/bash
set -e

echo "🔄 Running local CI validation before push..."

# Run CI checks with fast feedback
if ! ruby tools/run_ci_checks.rb --skip-external-links; then
    echo ""
    echo "❌ Local CI validation failed!"
    echo "💡 Fix the issues above and try pushing again"
    echo "💡 For detailed debugging, run: ruby tools/run_ci_checks.rb --verbose"
    exit 1
fi

echo "✅ Local CI validation passed. Proceeding with push."
```

Make executable: `chmod +x .git/hooks/pre-push`

### IDE Integration

**VS Code Integration:**
Add to `.vscode/tasks.json`:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Validate CI Locally",
            "type": "shell",
            "command": "ruby",
            "args": ["tools/run_ci_checks.rb", "--skip-external-links"],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        }
    ]
}
```

Use `Ctrl+Shift+P` → "Tasks: Run Task" → "Validate CI Locally"

## Advanced Prevention Techniques

### Automated Validation in Development

**Watch Mode for Documentation:**
```bash
# Monitor documentation changes and validate continuously
while inotifywait -e modify docs/; do
    echo "🔄 Documentation changed, validating..."
    ruby tools/validate_front_matter.rb
done
```

**Parallel Validation for Speed:**
```bash
# Run multiple validation checks in parallel
(
    ruby tools/validate_front_matter.rb &
    gitleaks detect --source=. --no-git &
    wait
) && echo "✅ Fast validation passed"
```

### Custom Validation Scripts

Create project-specific validation helpers:

```bash
#!/bin/bash
# scripts/quick-validate.sh
set -e

echo "🚀 Quick Validation Pipeline"

# Run most critical validations only
ruby tools/validate_front_matter.rb
gitleaks detect --source=. --no-git
echo "✅ Quick validation complete"
```

### Performance Optimization

**Incremental Validation:**
```bash
# Only validate changed files
git diff --name-only HEAD | grep '\.md$' | while read file; do
    echo "Validating: $file"
    ruby tools/validate_front_matter.rb -f "$file"
done
```

**Parallel Security Scanning:**
```bash
# Scan only documentation directories for speed
gitleaks detect --source=docs/ --no-git &
gitleaks detect --source=examples/ --no-git &
wait
```

## Best Practices Summary

### Essential Practices

1. **Run `ruby tools/run_ci_checks.rb` before every push**
2. **Use secure documentation patterns** with `[REDACTED]` markers
3. **Validate YAML front-matter** during file editing
4. **Keep dependencies updated** and monitor security advisories
5. **Fix broken links immediately** when moving or renaming files

### Development Efficiency

1. **Use `--skip-external-links`** during development for faster feedback
2. **Enable verbose output** (`--verbose`) when debugging failures
3. **Integrate validation into your IDE** workflow
4. **Consider pre-commit hooks** for automatic validation

### Security Considerations

1. **Never suppress security warnings** - fix root causes
2. **Use appropriate `.gitleaksignore` patterns** for legitimate test files
3. **Regularly audit dependencies** for vulnerabilities
4. **Follow secure coding practices** in all documentation examples

## Support and Resources

- **Local CI simulation**: `ruby tools/run_ci_checks.rb --help`
- **YAML validation**: `ruby tools/validate_front_matter.rb --help`
- **TypeScript validation**: `ruby tools/validate_typescript_bindings.rb --help`
- **Security scanning**: `gitleaks detect --help`
- **Main documentation**: See `CLAUDE.md` for additional guidance

For additional support or to report issues with validation tools, see the project's main documentation and issue tracking system.
