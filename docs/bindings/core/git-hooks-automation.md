---
id: git-hooks-automation
last_modified: '2025-06-09'
version: '0.1.0'
derived_from: automation
enforced_by: 'pre-commit hooks, git hooks, CI/CD pipelines, automated quality gates'
---
# Binding: Establish Mandatory Git Hooks for Quality Automation

Implement automated git hooks that enforce quality standards at commit time, preventing low-quality code from entering the repository. Create systematic barriers that catch issues immediately when developers have full context, rather than later in the development cycle when fixes are more expensive and disruptive.

## Rationale

This binding directly implements our automation tenet by eliminating manual quality checks that are prone to human error and inconsistent application. Git hooks act as the first line of defense in your quality automation strategy, catching issues like formatting violations, linting errors, security vulnerabilities, and test failures before they can propagate through the development pipeline.

Think of git hooks as quality guardrails on a mountain road—they prevent you from going over the cliff before you even realize you're getting close to the edge. Without these automated checkpoints, developers must rely on memory and discipline to run quality checks manually, which inevitably leads to inconsistent application and quality degradation over time. By the time CI catches these issues, context has been lost and the fix requires more cognitive overhead to understand and resolve.

The investment in comprehensive git hooks pays immediate dividends by providing instant feedback when the developer's mental model of the code is still fresh and complete. This creates a tight feedback loop that helps developers internalize quality standards while dramatically reducing the time and effort required to maintain code quality across the entire team. Failed hooks are not obstacles—they are learning opportunities that prevent future problems.

## Rule Definition

Mandatory git hooks must implement these core quality checkpoints:

- **Pre-commit Validation**: Every commit must pass automated checks for code formatting, linting, security scanning, and basic correctness before it can be recorded in git history.

- **Commit Message Enforcement**: All commit messages must follow conventional commit standards to enable automated changelog generation and semantic versioning.

- **Secret Detection**: Scan all staged changes for potential secrets, API keys, passwords, or other sensitive information before they can be committed to version control.

- **Fast Feedback**: Hooks must complete quickly (typically under 30 seconds) to avoid disrupting developer workflow while still providing comprehensive validation.

- **Bypass Prevention**: Hooks cannot be easily bypassed through git options like `--no-verify` except in documented emergency procedures with full audit trails.

- **Incremental Validation**: Hooks should validate only changed files when possible to minimize execution time and provide focused feedback.

**Quality Gate Categories for Git Hooks:**
- Code formatting and style consistency
- Syntax validation and linting
- Security scanning and secret detection
- Commit message format validation
- Basic test execution for changed components
- Documentation and comment quality checks

**Emergency Override Procedures:**
- Documented process for bypass in genuine emergencies
- Required approval from team lead or senior developer
- Automatic issue creation for follow-up remediation
- Audit logging of all bypasses with justification

## Tiered Implementation Approach

This binding supports incremental adoption through three complexity tiers, allowing teams to start simple and progressively enhance their automation:

### **🚀 Tier 1: Essential Setup (Must Have)**
*Start here for immediate impact with minimal setup complexity*

**Scope**: Basic quality gates that catch the most common issues
**Time to implement**: 30 minutes
**Team impact**: Low friction, immediate value

**Essential Components:**
- ✅ **Secret detection** - Prevents credential leaks (highest security risk)
- ✅ **Basic formatting** - Ensures consistent code appearance
- ✅ **Commit message validation** - Enables automated changelog generation
- ✅ **Syntax checking** - Catches obvious compilation errors

### **⚡ Tier 2: Enhanced Automation (Should Have)**
*Add after team adaptation to Tier 1 (2-4 weeks)*

**Scope**: Comprehensive quality validation with language-specific checks
**Time to implement**: 2-3 hours
**Team impact**: Moderate setup, significant quality improvement

**Enhanced Components:**
- ✅ **Code linting** - Enforces coding standards and best practices
- ✅ **Test execution** - Validates that changes don't break existing functionality
- ✅ **Dependency auditing** - Scans for security vulnerabilities in dependencies
- ✅ **Documentation validation** - Ensures code changes include proper documentation

### **🏆 Tier 3: Comprehensive Integration (Nice to Have)**
*Add after mastering Tier 2 (4-8 weeks)*

**Scope**: Advanced automation with full CI/CD integration
**Time to implement**: 4-6 hours
**Team impact**: Complex setup, enterprise-grade automation

**Advanced Components:**
- ✅ **Performance testing** - Validates performance regression prevention
- ✅ **Architecture validation** - Enforces design patterns and architectural constraints
- ✅ **Multi-language support** - Comprehensive validation across polyglot codebases
- ✅ **Custom business rules** - Project-specific validation and compliance checks

## Practical Implementation

### Starting with Tier 1: Essential Setup

1. **Choose a Pre-commit Framework**: Select based on your team's primary language:
   - **Node.js projects**: Husky (widely adopted, simple setup)
   - **Multi-language projects**: pre-commit (extensive ecosystem)
   - **Performance-focused**: lefthook (fastest execution)

2. **Implement Security-First Approach**: Start with secret detection as it has the highest impact and lowest false-positive rate.

3. **Add Basic Quality Gates**: Focus on formatting and commit message validation as they provide immediate value with minimal configuration.

4. **Test with Small Changes**: Validate the setup works correctly before rolling out to the entire team.

### Progressing to Tier 2: Enhanced Automation

1. **Add Language-Specific Linting**: Configure linters for your primary languages with project-appropriate rules.

2. **Integrate Basic Testing**: Add hooks that run fast unit tests for changed components only.

3. **Enable Dependency Scanning**: Add vulnerability scanning for package managers used in your project.

4. **Monitor Performance Impact**: Ensure hooks complete within 30 seconds to maintain developer productivity.

### Advancing to Tier 3: Comprehensive Integration

1. **Synchronize with CI/CD**: Ensure git hooks use identical tools and configurations as your CI/CD pipeline.

2. **Add Custom Validation**: Implement project-specific rules that enforce your architectural decisions.

3. **Enable Full Test Suites**: Run comprehensive test suites for critical changes when performance allows.

4. **Implement Bypass Auditing**: Add logging and approval processes for emergency hook bypasses.

```yaml
# Tier 1: Essential Setup
default_install_hook_types: [pre-commit, commit-msg]
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.2
    hooks:
      - id: trufflehog
        entry: trufflehog git file://. --since-commit HEAD --only-verified --fail

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-added-large-files
        args: ['--maxkb=500']

  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.0.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
```

```yaml
# Tier 2: Enhanced Automation (add to above)
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.56.0
    hooks:
      - id: eslint
        files: \.(js|jsx|ts|tsx)$
        args: [--fix]

  - repo: local
    hooks:
      - id: fast-tests
        entry: npm run test:changed
        language: system
```

## Migration Guide

**From No Automation:**
- Week 1: Tier 1 essential setup (secret detection, formatting, commit messages)
- Week 3: Add language-specific linting
- Week 6: Add testing hooks and full Tier 2
- Month 3: Evaluate Tier 3 based on team maturity

**From Basic Git Hooks:**
- Standardize with framework (pre-commit/husky) for consistency
- Add security scanning immediately
- Version hook configuration in repository
- Progressive enhancement with validation

**From CI-Only Validation:**
- Implement local-first approach with git hooks
- Synchronize hook and CI configurations
- Move fastest checks to git hooks for immediate feedback
- Keep comprehensive testing in CI

## Related Bindings

- [automated-quality-gates.md](../../docs/bindings/core/automated-quality-gates.md): First layer of quality automation with immediate feedback
- [require-conventional-commits.md](../../docs/bindings/core/require-conventional-commits.md): Enforces commit message standards
- [no-lint-suppression.md](../../docs/bindings/core/no-lint-suppression.md): Prevents lint violations through systematic enforcement
- [use-structured-logging.md](../../docs/bindings/core/use-structured-logging.md): Validates logging practices
