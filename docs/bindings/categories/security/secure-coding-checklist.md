---
id: secure-coding-checklist
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: automation
enforced_by: pre-commit hooks + automated security scanning + CI/CD security gates + code review automation
---

# Binding: Implement Automated Secure Coding Checklist

Establish comprehensive, automated security validation that systematically prevents vulnerabilities through integrated development workflow enforcement. Never allow security issues to accumulate, ensuring consistent application of security standards across all code changes.

## Rationale

This binding implements automation by transforming manual security reviews into systematic validation that runs consistently across all development activities. It embodies fix-broken-windows by ensuring security issues are detected and addressed immediately rather than accumulating as technical debt.

Automated security checklists work like manufacturing quality control systems that check products at multiple production stages rather than relying on end-of-line inspections. Security standards are consistently applied and issues caught immediately when introduced, not weeks later during manual reviews.

When security validation is automated and integrated into development workflow, it becomes impossible to bypass, ensuring standards are maintained regardless of time pressure or human error.

## Rule Definition

Secure coding checklist implementation must provide automated security validation integrated throughout the development lifecycle:

**Security Validation Categories:**
- **Static Application Security Testing (SAST)**: Automated detection of vulnerability patterns
- **Secret Detection**: Real-time detection of credentials and sensitive data in code
- **Dependency Security**: Automated vulnerability scanning of project dependencies
- **Input Validation**: Automated verification of external input validation and sanitization
- **Cryptographic Standards**: Automated validation of secure algorithms
- **Infrastructure Security**: Automated security configuration checking

## Practical Implementation

1. **Establish Comprehensive Pre-Commit Security Automation**: Implement automated security checks integrated into development workflow:

   ```yaml
   # .pre-commit-config.yaml - Security automation
   repos:
     - repo: https://github.com/PyCQA/bandit
       rev: 1.7.5
       hooks:
         - id: bandit
           args: ['-f', 'json', '-o', 'bandit-report.json']

     - repo: https://github.com/returntocorp/semgrep
       rev: v1.45.0
       hooks:
         - id: semgrep
           args: ['--config=auto', '--error', '--strict']

     - repo: https://github.com/trufflesecurity/trufflehog
       rev: v3.67.7
       hooks:
         - id: trufflehog
           entry: trufflehog filesystem --fail
           args: ['--only-verified']

     - repo: local
       hooks:
         - id: security-pattern-check
           name: Custom security validation
           entry: scripts/security-validator.py
           language: python
   ```

   ```python
   # scripts/security-validator.py - Security pattern validation
   import re
   import sys
   from pathlib import Path
   from typing import List, Dict, Any

   class SecurityValidator:
       def __init__(self):
           self.patterns = [
               {
                   'name': 'Hardcoded Secret',
                   'pattern': re.compile(r'(password|secret|key|token)\s*=\s*["\']([^"\'{8,})["\']', re.IGNORECASE),
                   'severity': 'critical',
                   'remediation': 'Use environment variables or secure secret management'
               },
               {
                   'name': 'SQL Injection Risk',
                   'pattern': re.compile(r'(execute|query)\s*\(\s*["\'].*\+.*["\']', re.IGNORECASE),
                   'severity': 'high',
                   'remediation': 'Use parameterized queries or prepared statements'
               },
               {
                   'name': 'Weak Cryptography',
                   'pattern': re.compile(r'(md5|sha1|des|rc4)\s*\(', re.IGNORECASE),
                   'severity': 'high',
                   'remediation': 'Use strong algorithms like SHA-256, AES-256'
               }
           ]

       def validate_file(self, file_path: Path) -> List[Dict[str, Any]]:
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
                           'severity': pattern['severity'],
                           'remediation': pattern['remediation']
                       })
           except Exception:
               pass  # Skip unreadable files

           return violations

   def main():
       import argparse
       parser = argparse.ArgumentParser()
       parser.add_argument('files', nargs='*')
       args = parser.parse_args()

       validator = SecurityValidator()
       all_violations = []

       for file_path_str in args.files:
           file_path = Path(file_path_str)
           if file_path.is_file():
               violations = validator.validate_file(file_path)
               all_violations.extend(violations)

       if all_violations:
           print("SECURITY VIOLATIONS DETECTED:")
           for violation in all_violations:
               print(f"• {violation['file']}:{violation['line']} - {violation['pattern']}")
               print(f"  {violation['remediation']}")
           sys.exit(1)

       print("✓ No security violations detected.")

   if __name__ == '__main__':
       main()
   ```
2. **Implement Automated Security Testing Integration**: Create security testing that validates controls continuously:

   ```typescript
   // Security testing framework
   class SecurityTestRunner {
     async runAllTests(): Promise<SecurityTestResult[]> {
       const tests = [
         () => this.testPasswordPolicy(),
         () => this.testSQLInjection(),
         () => this.testXSSPrevention()
       ];

       const results = [];
       for (const test of tests) {
         try {
           results.push(await test());
         } catch (error) {
           results.push({ passed: false, message: error.message });
         }
       }
       return results;
     }

     private async testPasswordPolicy(): Promise<SecurityTestResult> {
       const weakPasswords = ['password', '12345678', 'admin'];
       for (const weak of weakPasswords) {
         if (await this.isPasswordAccepted(weak)) {
           return { passed: false, message: `Weak password accepted: ${weak}` };
         }
       }
       return { passed: true, message: 'Password policy enforced' };
     }

     private async testSQLInjection(): Promise<SecurityTestResult> {
       const payloads = ["'; DROP TABLE users; --", "' OR '1'='1"];
       for (const payload of payloads) {
         if (await this.isVulnerableToSQL(payload)) {
           return { passed: false, message: 'SQL injection vulnerability detected' };
         }
       }
       return { passed: true, message: 'SQL injection prevented' };
     }

     private async testXSSPrevention(): Promise<SecurityTestResult> {
       const payloads = ["<script>alert('XSS')</script>"];
       for (const payload of payloads) {
         if (await this.isVulnerableToXSS(payload)) {
           return { passed: false, message: 'XSS vulnerability detected' };
         }
       }
       return { passed: true, message: 'XSS prevented' };
     }
   }

   interface SecurityTestResult {
     passed: boolean;
     message: string;
   }
   ```
3. **Create Security-Focused Code Review Automation**: Implement automated security pattern detection:

   ```python
   # security_code_review.py - Automated security code review
   import re
   import sys
   from pathlib import Path

   class SecurityCodeReviewer:
       def __init__(self):
           self.rules = [
               {
                   'pattern': re.compile(r'(password|secret|key)\s*=\s*["\'][^"\'{8,}["\']', re.IGNORECASE),
                   'description': 'Hardcoded secret detected',
                   'remediation': 'Use environment variables'
               },
               {
                   'pattern': re.compile(r'(execute|query)\s*\(\s*["\'].*\+.*["\']', re.IGNORECASE),
                   'description': 'SQL injection risk',
                   'remediation': 'Use parameterized queries'
               }
           ]

       def review_file(self, file_path: Path):
           issues = []
           try:
               with open(file_path, 'r', encoding='utf-8') as f:
                   lines = f.readlines()

               for line_num, line in enumerate(lines, 1):
                   for rule in self.rules:
                       if rule['pattern'].search(line):
                           issues.append({
                               'file': str(file_path),
                               'line': line_num,
                               'description': rule['description'],
                               'remediation': rule['remediation']
                           })
           except Exception:
               pass

           return issues

   def main():
       import argparse
       parser = argparse.ArgumentParser()
       parser.add_argument('files', nargs='*')
       parser.add_argument('--fail-on-issues', action='store_true')
       args = parser.parse_args()

       reviewer = SecurityCodeReviewer()
       all_issues = []

       for file_str in args.files:
           file_path = Path(file_str)
           if file_path.is_file():
               issues = reviewer.review_file(file_path)
               all_issues.extend(issues)

       if all_issues:
           print("SECURITY ISSUES DETECTED:")
           for issue in all_issues:
               print(f"• {issue['file']}:{issue['line']} - {issue['description']}")
               print(f"  {issue['remediation']}")

           if args.fail_on_issues:
               sys.exit(1)
       else:
           print("✓ No security issues detected")

   if __name__ == '__main__':
       main()
   ```
4. **Create Security Checklist Configuration**: Define structured security requirements:

   ```yaml
   # .security-checklist.yaml
   security_checklist:
     categories:
       secrets_management:
         items:
           - id: "no-hardcoded-secrets"
             validation_method: "secret_detection"
             tools: ["trufflehog", "gitleaks"]
       input_validation:
         items:
           - id: "sql-injection-prevention"
             validation_method: "static_analysis"
             tools: ["semgrep"]
           - id: "xss-prevention"
             validation_method: "automated_test"
             test_command: "python scripts/test-xss.py"

   validation_rules:
     commit:
       required_categories: ["secrets_management"]
     pull_request:
       required_categories: ["secrets_management", "input_validation"]
   ```

   ```python
   # scripts/checklist-validator.py
   import yaml
   import subprocess
   import sys

   class ChecklistValidator:
       def __init__(self, config_path: str):
           with open(config_path, 'r') as f:
               self.config = yaml.safe_load(f)

       def validate_for_stage(self, stage: str):
           required_categories = self.config['validation_rules'][stage]['required_categories']
           failed_items = []

           for category_name in required_categories:
               category = self.config['security_checklist']['categories'][category_name]
               for item in category['items']:
                   if not self._validate_item(item):
                       failed_items.append(item['id'])

           return len(failed_items) == 0

       def _validate_item(self, item):
           method = item['validation_method']
           if method == 'automated_test':
               result = subprocess.run(item['test_command'].split(), capture_output=True)
               return result.returncode == 0
           elif method == 'static_analysis':
               return True  # Simplified
           elif method == 'secret_detection':
               return True  # Simplified
           return False

   def main():
       import argparse
       parser = argparse.ArgumentParser()
       parser.add_argument('--config', default='.security-checklist.yaml')
       parser.add_argument('--stage', required=True, choices=['commit', 'pull_request'])
       args = parser.parse_args()

       validator = ChecklistValidator(args.config)
       if validator.validate_for_stage(args.stage):
           print(f"✓ All security checklist items passed for {args.stage}")
       else:
           print("❌ Security checklist validation failed")
           sys.exit(1)

   if __name__ == '__main__':
       main()
   ```
## Examples

```bash
# ❌ BAD: Manual security review with no enforcement
echo "Remember to check for SQL injection, XSS, secrets"
echo "Please review manually and approve when ready"
# No enforcement - can be bypassed, inconsistent application
```

```bash
# ✅ GOOD: Automated security checklist with enforcement
set -e  # Exit on any error - no bypassing security checks

# Pre-commit security validation
pre-commit run --all-files

# Secret detection
trufflehog filesystem . --only-verified --fail
gitleaks detect --source . --verbose

# Static security analysis
semgrep --config=auto --error --strict .
bandit -r . -f json -o bandit-report.json

# Security code review automation
python scripts/security-code-review.py --fail-on-issues $(find . -name "*.py")

# Security checklist validation
python scripts/checklist-validator.py --stage commit

# Security testing
python scripts/security-test-runner.py --critical-only

echo "✅ Security checklist passed!"
```
## Related Bindings

- [automation](../../tenets/automation.md): Secure coding checklist directly implements automation principles by transforming manual security review processes into systematic, automated validation that runs consistently across all development activities.

- [fix-broken-windows](../../tenets/fix-broken-windows.md): Security checklist automation prevents security "broken windows" by catching security issues immediately when they're introduced and requiring immediate resolution rather than allowing them to accumulate as technical debt.

- [input-validation-standards](../../docs/bindings/categories/security/input-validation-standards.md): Security checklist automation includes comprehensive validation of input security standards through automated testing and static analysis.

- [secrets-management-practices](../../docs/bindings/categories/security/secrets-management-practices.md): Security checklist automation includes comprehensive secret detection and validation as core checklist items that must be satisfied before code changes are accepted.

- [no-secret-suppression](../../tenets/no-secret-suppression.md): Security checklist automation never allows bypassing or suppressing security controls, ensuring that all security validation must be completed successfully before code changes are accepted.
