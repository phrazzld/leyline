# CI Failure Prevention Guide

This guide helps developers catch and resolve CI issues locally before pushing to remote repositories, preventing CI failures and maintaining development velocity.

## Quick Start

Run the local CI simulation before pushing any changes:

```bash
# Full validation (recommended before important pushes)
ruby tools/run_ci_checks.rb

# Fast validation (daily development)
ruby tools/run_ci_checks.rb --skip-external-links

# Detailed troubleshooting
ruby tools/run_ci_checks.rb --verbose
```

## Common CI Failure Patterns

### 1. TypeScript Configuration Issues

**Symptoms:**
- ESLint parsing errors: "Unexpected token"
- TypeScript compilation failures
- Package validation failures

**Local Detection:**
```bash
ruby tools/validate_typescript_bindings.rb --verbose
```

**Common Fixes:**
- Ensure `@typescript-eslint/parser` is configured for `.ts` files
- Verify `tsconfig.json` includes all necessary source directories
- Check that `packageManager` field uses exact versions (e.g., `pnpm@10.12.1`)

### 2. Security Scan False Positives

**Symptoms:**
- Gitleaks detecting example API keys
- Security warnings on documentation examples

**Local Detection:**
```bash
gitleaks detect --source=. --no-git
```

**Common Fixes:**
- Replace example secrets with `[REDACTED]` or `[EXAMPLE]` format
- Use environment variable patterns in documentation
- Avoid realistic-looking API keys in examples

### 3. Package Manager Version Issues

**Symptoms:**
- "Cannot switch to pnpm" warnings
- Package manager installation failures

**Local Detection:**
```bash
# Check for semver ranges in packageManager field
grep -r "packageManager.*\\^" . --include="*.json"
```

**Common Fixes:**
- Use exact versions: `"packageManager": "pnpm@10.12.1"`
- Avoid semver ranges in packageManager field
- Keep versions consistent across all package.json files

### 4. Security Vulnerabilities

**Symptoms:**
- Dependency audit failures
- Known vulnerabilities in transitive dependencies

**Local Detection:**
```bash
# From TypeScript project directory
pnpm audit --audit-level=moderate
```

**Common Fixes:**
- Use pnpm overrides for transitive dependency vulnerabilities:
  ```json
  {
    "pnpm": {
      "overrides": {
        "vulnerable-package": ">=secure-version"
      }
    }
  }
  ```
- Update direct dependencies to secure versions
- Document security override decisions

## Pre-Push Checklist

Before pushing changes, ensure:

- [ ] Local CI simulation passes: `ruby tools/run_ci_checks.rb`
- [ ] No security vulnerabilities: `pnpm audit --audit-level=moderate`
- [ ] No secrets detected: `gitleaks detect --source=. --no-git`
- [ ] TypeScript configurations valid: `ruby tools/validate_typescript_bindings.rb`
- [ ] All tests pass locally
- [ ] Code formatting applied

## Troubleshooting Tips

### Fast Feedback Loop
1. Run specific validation for your changes
2. Fix issues incrementally
3. Re-run validation to confirm fixes
4. Only run full CI simulation when ready

### Common Commands
```bash
# Validate specific changes
ruby tools/validate_front_matter.rb          # YAML front-matter
ruby tools/validate_cross_references.rb      # Internal links
ruby tools/validate_typescript_bindings.rb   # TypeScript configs

# Security checks
gitleaks detect --source=docs/ --no-git      # Document security scan
pnpm audit --audit-level=moderate           # Dependency vulnerabilities

# Index maintenance
ruby tools/reindex.rb                       # Update index files
```

### Getting Help
- **Detailed Errors**: Use `--verbose` flag for more information
- **Manual Commands**: Failed validations show exact commands to run
- **Documentation**: Check binding documentation for configuration examples
- **Logs**: Enable structured logging with `LEYLINE_STRUCTURED_LOGGING=true`

## Integration with Development Workflow

### Pre-Commit Hook (Recommended)
```bash
#!/bin/sh
# .git/hooks/pre-commit
ruby tools/run_ci_checks.rb --skip-external-links
```

### IDE Integration
- Configure ESLint to use project configurations
- Set up security scanning plugins (gitleaks, Snyk)
- Enable automatic formatting on save

### Team Practices
- Run local CI simulation daily during development
- Address security issues immediately
- Keep dependencies updated regularly
- Document any override decisions

This proactive approach prevents CI failures, reduces feedback time, and maintains development velocity while ensuring code quality and security standards.
