---
id: secure-coding-checklist
last_modified: '2025-06-11'
version: '0.2.0'
derived_from: automation
enforced_by: pre-commit hooks + automated security scanning + CI/CD security gates + code review automation
---

# Binding: Implement Automated Secure Coding Checklist

Establish comprehensive, automated security validation that systematically prevents vulnerabilities through integrated development workflow enforcement.

## Rationale

This binding implements automation by transforming manual security reviews into systematic validation. It embodies fix-broken-windows by ensuring security issues are detected and addressed immediately rather than accumulating as technical debt.

## Rule Definition

**Security Validation Categories:**
- **Static Application Security Testing (SAST)**: Automated detection of vulnerability patterns
- **Secret Detection**: Real-time detection of credentials and sensitive data in code
- **Dependency Security**: Automated vulnerability scanning of project dependencies
- **Input Validation**: Automated verification of external input validation and sanitization
- **Cryptographic Standards**: Automated validation of secure algorithms
- **Infrastructure Security**: Automated security configuration checking

## Practical Implementation

**1. Pre-Commit Security Automation:**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
  - repo: https://github.com/returntocorp/semgrep
    rev: v1.45.0
    hooks:
      - id: semgrep
        args: ['--config=auto', '--error']
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.67.7
    hooks:
      - id: trufflehog
        args: ['--only-verified']
```

**2. Security Pattern Validation:**

```python
# scripts/security-validator.py
import re
import sys
from pathlib import Path

class SecurityValidator:
    def __init__(self):
        self.patterns = [
            {
                'name': 'Hardcoded Secret',
                'pattern': re.compile(r'(password|secret|key)\s*=\s*["\'][^"\'{8,}["\']', re.IGNORECASE),
                'remediation': 'Use environment variables'
            },
            {
                'name': 'SQL Injection Risk',
                'pattern': re.compile(r'(execute|query)\s*\(.*\+.*', re.IGNORECASE),
                'remediation': 'Use parameterized queries'
            }
        ]

    def validate_file(self, file_path: Path):
        violations = []
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            for pattern in self.patterns:
                for match in pattern['pattern'].finditer(content):
                    line_number = content[:match.start()].count('\n') + 1
                    violations.append({
                        'file': str(file_path),
                        'line': line_number,
                        'pattern': pattern['name'],
                        'remediation': pattern['remediation']
                    })
        except Exception:
            pass
        return violations
```

**3. Security Checklist Configuration:**

```yaml
# .security-checklist.yaml
security_checklist:
  categories:
    secrets_management:
      items:
        - id: "no-hardcoded-secrets"
          validation_method: "secret_detection"
          tools: ["trufflehog"]
    input_validation:
      items:
        - id: "sql-injection-prevention"
          validation_method: "static_analysis"
          tools: ["semgrep"]

validation_rules:
  commit:
    required_categories: ["secrets_management"]
  pull_request:
    required_categories: ["secrets_management", "input_validation"]
```
## Examples

```bash
# ❌ BAD: Manual security review with no enforcement
echo "Remember to check for SQL injection, XSS, secrets"
# No enforcement - can be bypassed
```

```bash
# ✅ GOOD: Automated security checklist with enforcement
set -e  # Exit on any error

# Pre-commit security validation
pre-commit run --all-files

# Secret detection
trufflehog filesystem . --only-verified --fail

# Static security analysis
semgrep --config=auto --error .
bandit -r . -f json

# Security checklist validation
python scripts/checklist-validator.py --stage commit

echo "✅ Security checklist passed!"
```
## Related Bindings

- [automation](../../tenets/automation.md): Transforms manual security review processes into systematic, automated validation
- [fix-broken-windows](../../tenets/fix-broken-windows.md): Prevents security "broken windows" by catching issues immediately
- [secrets-management-practices](secrets-management-practices.md): Includes comprehensive secret detection as core checklist items
- [secure-by-design-principles](secure-by-design-principles.md): Implements security validation throughout development lifecycle
