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

## Practical Implementation

1. **Establish Pre-commit Framework**: Use a standardized pre-commit framework (pre-commit, husky, lefthook) to manage hook configuration and versioning. This ensures consistent hook behavior across all developer environments and simplifies maintenance.

2. **Implement Progressive Validation**: Start with basic checks (formatting, linting) and gradually add more comprehensive validation (security scanning, testing) as the team adapts to the workflow. This reduces initial friction while building toward comprehensive quality gates.

3. **Configure Language-Specific Hooks**: Set up appropriate hooks for each technology in your stack, ensuring comprehensive coverage without redundancy. Focus on the highest-impact checks that catch the most common quality issues.

4. **Enable Security-First Scanning**: Implement secret detection and security scanning as mandatory hooks that cannot be bypassed. These represent the highest-risk quality issues with the most severe consequences.

5. **Integrate with CI/CD Pipeline**: Ensure git hooks use the same tools and configurations as your CI/CD pipeline to prevent "works on my machine" issues and maintain consistency across environments.

## Examples

```yaml
# ❌ BAD: Minimal or missing pre-commit configuration
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer

# Problems:
# 1. No security scanning for secrets
# 2. No linting or code quality checks
# 3. No language-specific validation
# 4. Easily bypassable with --no-verify
# 5. No integration with project-specific quality standards
```

```yaml
# ✅ GOOD: Comprehensive pre-commit configuration with security focus
repos:
  # Security and secrets scanning (highest priority)
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.2
    hooks:
      - id: trufflehog
        name: TruffleHog OSS
        entry: trufflehog git file://. --since-commit HEAD --only-verified --fail

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: package-lock.json

  # Code quality and formatting
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: check-case-conflict
      - id: check-json
      - id: check-yaml
        args: [--allow-multiple-documents]

  # Language-specific linting and formatting
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3.11

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
        additional_dependencies: [flake8-docstrings]

  # Commit message validation
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.0.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]

  # Documentation and markdown quality
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.37.0
    hooks:
      - id: markdownlint
        args: ['--fix']

# Prevent bypass attempts
fail_fast: true
default_stages: [commit, push]
```

```javascript
// ❌ BAD: Basic husky setup without comprehensive validation
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.js": "eslint --fix"
  }
}

// Problems:
# 1. Only JavaScript linting, no security scanning
# 2. No commit message validation
# 3. No test execution or broader quality checks
# 4. Easy to bypass or disable
```

```javascript
// ✅ GOOD: Comprehensive husky configuration with security and quality gates
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged && npm run test:changed && npm run security:scan",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS",
      "pre-push": "npm run test:full && npm run security:audit"
    }
  },
  "lint-staged": {
    "*.{js,ts,tsx}": [
      "eslint --fix --max-warnings 0",
      "prettier --write",
      "jest --bail --findRelatedTests --passWithNoTests"
    ],
    "*.{json,md,yaml,yml}": [
      "prettier --write"
    ],
    "*.{js,ts,tsx,json,md}": [
      "secretlint"
    ]
  },
  "scripts": {
    "test:changed": "jest --bail --onlyChanged --passWithNoTests",
    "test:full": "jest --coverage --watchAll=false",
    "security:scan": "npm audit --audit-level high && secretlint '**/*'",
    "security:audit": "npm audit --audit-level moderate"
  }
}

// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor',
      'test', 'chore', 'ci', 'perf', 'revert'
    ]],
    'subject-case': [2, 'never', ['start-case', 'pascal-case', 'upper-case']]
  }
};
```

```yaml
# ✅ GOOD: Lefthook configuration for multi-language projects
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    secrets-detection:
      glob: "*"
      run: trufflehog git file://. --since-commit HEAD --only-verified --fail
      fail_text: "🚨 Secrets detected! Remove before committing."

    go-format:
      glob: "*.go"
      run: gofmt -w {staged_files} && goimports -w {staged_files}
      stage_fixed: true

    go-lint:
      glob: "*.go"
      run: golangci-lint run {staged_files}

    go-test:
      glob: "*.go"
      run: go test -short ./...

    javascript-format:
      glob: "*.{js,ts,tsx,jsx}"
      run: prettier --write {staged_files}
      stage_fixed: true

    javascript-lint:
      glob: "*.{js,ts,tsx,jsx}"
      run: eslint --fix --max-warnings 0 {staged_files}
      stage_fixed: true

    rust-format:
      glob: "*.rs"
      run: cargo fmt -- {staged_files}
      stage_fixed: true

    rust-lint:
      glob: "*.rs"
      run: cargo clippy -- -D warnings

commit-msg:
  commands:
    conventional-commit:
      run: |
        # Validate conventional commit format
        if ! grep -qE "^(feat|fix|docs|style|refactor|test|chore|ci|perf|revert)(\(.+\))?: .{1,50}" "{1}"; then
          echo "❌ Commit message must follow conventional commit format"
          echo "Format: type(scope): description"
          echo "Example: feat(api): add user authentication endpoint"
          exit 1
        fi

pre-push:
  commands:
    security-audit:
      run: |
        echo "🔍 Running comprehensive security audit..."
        if command -v npm >/dev/null 2>&1; then npm audit --audit-level high; fi
        if command -v cargo >/dev/null 2>&1; then cargo audit; fi
        if command -v go >/dev/null 2>&1; then govulncheck ./...; fi
```

## Related Bindings

- [automated-quality-gates.md](../../docs/bindings/core/automated-quality-gates.md): Git hooks provide the first layer of automated quality gates, focusing on immediate feedback at commit time. Both bindings work together to create comprehensive quality automation throughout the development pipeline.

- [require-conventional-commits.md](../../docs/bindings/core/require-conventional-commits.md): Git hooks enforce conventional commit message standards that enable automated changelog generation and semantic versioning. Commit message validation in hooks ensures consistency before code reaches the repository.

- [no-lint-suppression.md](../../docs/bindings/core/no-lint-suppression.md): Git hooks prevent lint rule violations from being committed, supporting the principle of addressing root causes rather than suppressing warnings. Both bindings maintain code quality through systematic enforcement.

- [use-structured-logging.md](../../docs/bindings/core/use-structured-logging.md): Git hooks can validate that logging practices follow structured patterns, ensuring observability standards are maintained from the earliest stages of development.
