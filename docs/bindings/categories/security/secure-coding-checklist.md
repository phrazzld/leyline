---
id: secure-coding-checklist
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: automation
enforced_by: pre-commit hooks + automated security scanning + CI/CD security gates + code review automation
---

# Binding: Implement Automated Secure Coding Checklist

Establish a comprehensive, automated checklist for development security reviews that systematically prevents security vulnerabilities through automated validation, immediate issue detection, and integrated development workflow enforcement. Never allow security issues to accumulate or be deferred, ensuring consistent application of security standards across all code changes.

## Rationale

This binding directly implements our automation tenet by transforming manual security review processes into automated, systematic validation that runs consistently across all development activities. Additionally, it embodies our fix-broken-windows principle by ensuring that security issues are detected and addressed immediately rather than being allowed to accumulate as technical debt that creates an environment where security problems become normalized.

Think of a secure coding checklist like an automated quality control system in manufacturing that checks every product at multiple stages of production rather than relying on end-of-line inspections. Just as manufacturers use automated systems to ensure consistent quality and catch defects early when they're cheaper to fix, automated secure coding checklists ensure that security standards are consistently applied and security issues are caught immediately when they're introduced, not weeks later during manual security reviews.

Manual security reviews—especially those conducted infrequently or inconsistently—create dangerous gaps where security vulnerabilities can be introduced and persist. These gaps compound over time, creating a culture where security issues feel acceptable and urgent deadlines justify skipping security checks. When security validation is automated and integrated into the development workflow, it becomes impossible to bypass, ensuring that security standards are maintained regardless of time pressure or human error.

The automation aspect ensures that security checks happen consistently without relying on human memory or discipline, while the fix-broken-windows aspect ensures that when security issues are detected, they must be resolved immediately rather than being added to a backlog where they can be forgotten or deprioritized. Together, these principles create a development environment where security is built-in rather than bolted-on.

## Rule Definition

Secure coding checklist implementation must provide comprehensive automated security validation integrated throughout the development lifecycle:

**Automated Security Validation Categories:**

**Pre-Development Security Checks:**
- **Dependency Security Scanning**: Automated vulnerability scanning of all project dependencies before they're added
- **License Compliance Validation**: Automated checking of dependency licenses for security and legal compliance
- **Configuration Security Assessment**: Automated validation of development environment and tool configurations for security settings

**Code Development Security Automation:**
- **Static Application Security Testing (SAST)**: Automated security-focused code analysis that detects common vulnerability patterns
- **Secret Detection and Prevention**: Real-time detection of credentials, API keys, and sensitive data in code
- **Security-Focused Linting**: Automated enforcement of secure coding patterns and prevention of dangerous programming practices
- **Input Validation Verification**: Automated checking that all external inputs are properly validated and sanitized

**Pre-Commit Security Gates:**
- **Vulnerability Pattern Detection**: Automated scanning for injection vulnerabilities, authentication bypasses, and authorization flaws
- **Cryptographic Standards Enforcement**: Automated validation that cryptographic operations use secure algorithms and proper implementation
- **Error Handling Security**: Automated verification that error handling doesn't leak sensitive information
- **Access Control Verification**: Automated checking that access controls are properly implemented and cannot be bypassed

**Integration and Deployment Security Automation:**
- **Infrastructure Security Validation**: Automated security configuration checking for deployment environments
- **Container Security Scanning**: Automated vulnerability and misconfiguration detection in container images
- **API Security Testing**: Automated security testing of API endpoints for authentication, authorization, and input validation
- **Security Regression Testing**: Automated testing to ensure security fixes don't introduce new vulnerabilities

## Practical Implementation

1. **Establish Comprehensive Pre-Commit Security Automation**: Implement automated security checks that run before any code can be committed:

   Create security validation that operates as an integral part of the development workflow, making it impossible to introduce code without passing security checks.

   ```yaml
   # .pre-commit-config.yaml - Comprehensive security automation
   repos:
     # Static Application Security Testing
     - repo: https://github.com/PyCQA/bandit
       rev: 1.7.5
       hooks:
         - id: bandit
           name: Security linting for Python
           description: Find common security issues in Python code
           args: ['-f', 'json', '-o', 'bandit-report.json']
           stages: [commit, push]

     # Security-focused code analysis
     - repo: https://github.com/returntocorp/semgrep
       rev: v1.45.0
       hooks:
         - id: semgrep
           name: Static analysis for security vulnerabilities
           description: Detect OWASP Top 10 and security anti-patterns
           args: ['--config=auto', '--error', '--strict', '--verbose']
           stages: [commit, push]

     # Secret detection and prevention
     - repo: https://github.com/trufflesecurity/trufflehog
       rev: v3.67.7
       hooks:
         - id: trufflehog
           name: Detect hardcoded secrets
           description: Scan for credentials and sensitive data
           entry: trufflehog filesystem --fail
           args: ['--only-verified']
           stages: [commit, push]

     # Dependency vulnerability scanning
     - repo: https://github.com/pyupio/safety
       rev: 2.3.4
       hooks:
         - id: safety
           name: Python dependency vulnerability scanning
           description: Check Python dependencies for known vulnerabilities
           args: ['--output', 'json', '--save-json', 'safety-report.json']
           stages: [commit, push]

     # Infrastructure security validation
     - repo: https://github.com/tfsec/tfsec
       rev: v1.28.1
       hooks:
         - id: tfsec
           name: Terraform security scanning
           description: Static analysis of Terraform for security issues
           args: ['--format', 'json', '--out', 'tfsec-report.json']
           files: \\.tf$
           stages: [commit, push]

     # Container security scanning
     - repo: local
       hooks:
         - id: container-security-scan
           name: Container security scanning
           description: Scan container images for vulnerabilities
           entry: scripts/container-security-check.py
           language: python
           files: (Dockerfile|docker-compose\\.ya?ml)$
           stages: [commit, push]

     # Custom security pattern detection
     - repo: local
       hooks:
         - id: security-pattern-check
           name: Custom security pattern validation
           description: Check for organization-specific security patterns
           entry: scripts/security-pattern-validator.py
           language: python
           args: ['--config', '.security-patterns.yaml']
           stages: [commit, push]
   ```

   ```python
   # scripts/security-pattern-validator.py - Custom security validation
   import re
   import sys
   import yaml
   import argparse
   from pathlib import Path
   from typing import List, Dict, Any, Tuple

   class SecurityPatternValidator:
       def __init__(self, config_path: str):
           with open(config_path, 'r') as f:
               self.config = yaml.safe_load(f)
           self.security_patterns = self._load_security_patterns()

       def _load_security_patterns(self) -> List[Dict[str, Any]]:
           """Load security patterns from configuration."""
           patterns = []

           for pattern_config in self.config.get('security_patterns', []):
               pattern = {
                   'name': pattern_config['name'],
                   'pattern': re.compile(pattern_config['regex'], re.IGNORECASE | re.MULTILINE),
                   'severity': pattern_config.get('severity', 'high'),
                   'description': pattern_config['description'],
                   'remediation': pattern_config['remediation'],
                   'file_types': pattern_config.get('file_types', ['*']),
                   'category': pattern_config.get('category', 'general')
               }
               patterns.append(pattern)

           return patterns

       def validate_file(self, file_path: Path) -> List[Dict[str, Any]]:
           """Validate a single file against security patterns."""
           violations = []

           try:
               with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                   content = f.read()
           except Exception as e:
               return [{'error': f'Failed to read {file_path}: {e}'}]

           for pattern in self.security_patterns:
               # Check if pattern applies to this file type
               if not self._file_matches_pattern(file_path, pattern['file_types']):
                   continue

               matches = pattern['pattern'].finditer(content)
               for match in matches:
                   line_number = content[:match.start()].count('\n') + 1

                   violation = {
                       'file': str(file_path),
                       'line': line_number,
                       'pattern': pattern['name'],
                       'severity': pattern['severity'],
                       'category': pattern['category'],
                       'description': pattern['description'],
                       'remediation': pattern['remediation'],
                       'match': match.group()[:100],  # First 100 chars
                       'context': self._get_line_context(content, match.start())
                   }
                   violations.append(violation)

           return violations

       def _file_matches_pattern(self, file_path: Path, file_types: List[str]) -> bool:
           """Check if file matches the pattern's file type filters."""
           if '*' in file_types:
               return True

           file_extension = file_path.suffix.lower()
           file_name = file_path.name.lower()

           for file_type in file_types:
               if file_type.startswith('.') and file_extension == file_type:
                   return True
               if file_name.endswith(file_type):
                   return True

           return False

       def _get_line_context(self, content: str, match_start: int) -> str:
           """Get line context around the match for better debugging."""
           lines = content.splitlines()
           line_number = content[:match_start].count('\n')

           start_line = max(0, line_number - 1)
           end_line = min(len(lines), line_number + 2)

           context_lines = []
           for i in range(start_line, end_line):
               prefix = '>>> ' if i == line_number else '    '
               context_lines.append(f'{prefix}{lines[i]}')

           return '\n'.join(context_lines)

   def main():
       parser = argparse.ArgumentParser(description='Validate security patterns in files')
       parser.add_argument('--config', required=True, help='Security patterns configuration file')
       parser.add_argument('files', nargs='*', help='Files to validate')

       args = parser.parse_args()

       validator = SecurityPatternValidator(args.config)
       all_violations = []

       for file_path_str in args.files:
           file_path = Path(file_path_str)
           if file_path.is_file():
               violations = validator.validate_file(file_path)
               all_violations.extend(violations)

       # Report violations
       if all_violations:
           print("SECURITY VIOLATIONS DETECTED:")
           print("=" * 50)

           # Group by severity
           violations_by_severity = {}
           for violation in all_violations:
               severity = violation.get('severity', 'unknown')
               if severity not in violations_by_severity:
                   violations_by_severity[severity] = []
               violations_by_severity[severity].append(violation)

           # Report in order of severity
           severity_order = ['critical', 'high', 'medium', 'low']
           for severity in severity_order:
               if severity in violations_by_severity:
                   print(f"\n{severity.upper()} SEVERITY VIOLATIONS:")
                   print("-" * 40)

                   for violation in violations_by_severity[severity]:
                       print(f"File: {violation['file']}:{violation['line']}")
                       print(f"Pattern: {violation['pattern']} ({violation['category']})")
                       print(f"Description: {violation['description']}")
                       print(f"Match: {violation['match']}")
                       print(f"Remediation: {violation['remediation']}")
                       print(f"Context:\n{violation['context']}")
                       print()

           print(f"TOTAL VIOLATIONS: {len(all_violations)}")
           print("All security violations must be resolved before committing.")
           sys.exit(1)

       print("✓ No security violations detected.")
       return 0

   if __name__ == '__main__':
       main()
   ```

2. **Implement Automated Security Testing Integration**: Create comprehensive security testing that integrates with CI/CD pipelines:

   Build security testing automation that validates security controls continuously throughout the development and deployment process.

   ```typescript
   // Security testing automation framework
   interface SecurityTestSuite {
     name: string;
     category: 'authentication' | 'authorization' | 'input_validation' | 'crypto' | 'infrastructure';
     severity: 'critical' | 'high' | 'medium' | 'low';
     tests: SecurityTest[];
   }

   interface SecurityTest {
     id: string;
     name: string;
     description: string;
     implementation: () => Promise<SecurityTestResult>;
     remediation: string;
   }

   interface SecurityTestResult {
     passed: boolean;
     message: string;
     evidence?: any;
     cve_references?: string[];
   }

   class AutomatedSecurityTesting {
     private testSuites: SecurityTestSuite[] = [];
     private auditLogger: SecurityAuditLogger;

     constructor(auditLogger: SecurityAuditLogger) {
       this.auditLogger = auditLogger;
       this.initializeSecurityTestSuites();
     }

     private initializeSecurityTestSuites(): void {
       // Authentication security tests
       this.testSuites.push({
         name: 'Authentication Security',
         category: 'authentication',
         severity: 'critical',
         tests: [
           {
             id: 'auth-001',
             name: 'Password Policy Enforcement',
             description: 'Verify password complexity requirements are enforced',
             implementation: this.testPasswordPolicyEnforcement.bind(this),
             remediation: 'Implement strong password policy with minimum length, complexity, and entropy requirements'
           },
           {
             id: 'auth-002',
             name: 'Session Management Security',
             description: 'Verify secure session handling and timeout enforcement',
             implementation: this.testSessionManagementSecurity.bind(this),
             remediation: 'Implement secure session tokens with proper expiration and invalidation'
           },
           {
             id: 'auth-003',
             name: 'Multi-Factor Authentication',
             description: 'Verify MFA is properly implemented and cannot be bypassed',
             implementation: this.testMultiFactorAuthentication.bind(this),
             remediation: 'Ensure MFA is required for sensitive operations and cannot be bypassed'
           }
         ]
       });

       // Input validation security tests
       this.testSuites.push({
         name: 'Input Validation Security',
         category: 'input_validation',
         severity: 'high',
         tests: [
           {
             id: 'input-001',
             name: 'SQL Injection Prevention',
             description: 'Verify SQL injection vulnerabilities are prevented',
             implementation: this.testSQLInjectionPrevention.bind(this),
             remediation: 'Use parameterized queries and input validation for all database operations'
           },
           {
             id: 'input-002',
             name: 'XSS Prevention',
             description: 'Verify cross-site scripting vulnerabilities are prevented',
             implementation: this.testXSSPrevention.bind(this),
             remediation: 'Implement proper output encoding and Content Security Policy'
           },
           {
             id: 'input-003',
             name: 'Command Injection Prevention',
             description: 'Verify command injection vulnerabilities are prevented',
             implementation: this.testCommandInjectionPrevention.bind(this),
             remediation: 'Validate and sanitize all input used in system commands'
           }
         ]
       });

       // Cryptographic security tests
       this.testSuites.push({
         name: 'Cryptographic Security',
         category: 'crypto',
         severity: 'high',
         tests: [
           {
             id: 'crypto-001',
             name: 'Strong Encryption Standards',
             description: 'Verify strong encryption algorithms are used',
             implementation: this.testEncryptionStandards.bind(this),
             remediation: 'Use AES-256, ChaCha20-Poly1305, or other approved encryption algorithms'
           },
           {
             id: 'crypto-002',
             name: 'Secure Random Number Generation',
             description: 'Verify cryptographically secure random number generation',
             implementation: this.testSecureRandomGeneration.bind(this),
             remediation: 'Use cryptographically secure random number generators for all security-sensitive operations'
           },
           {
             id: 'crypto-003',
             name: 'Key Management Security',
             description: 'Verify encryption keys are properly managed and protected',
             implementation: this.testKeyManagementSecurity.bind(this),
             remediation: 'Implement proper key rotation, storage, and access controls'
           }
         ]
       });
     }

     async runAllSecurityTests(): Promise<SecurityTestReport> {
       const report: SecurityTestReport = {
         timestamp: new Date().toISOString(),
         totalTests: 0,
         passedTests: 0,
         failedTests: 0,
         suiteResults: [],
         criticalFailures: [],
         summary: ''
       };

       for (const suite of this.testSuites) {
         const suiteResult = await this.runSecurityTestSuite(suite);
         report.suiteResults.push(suiteResult);
         report.totalTests += suiteResult.tests.length;
         report.passedTests += suiteResult.tests.filter(t => t.result.passed).length;
         report.failedTests += suiteResult.tests.filter(t => !t.result.passed).length;

         // Track critical failures
         const criticalFailures = suiteResult.tests
           .filter(t => !t.result.passed && suite.severity === 'critical')
           .map(t => ({ suite: suite.name, test: t.test, result: t.result }));
         report.criticalFailures.push(...criticalFailures);
       }

       // Generate summary
       report.summary = this.generateSecurityTestSummary(report);

       // Audit the security test execution
       await this.auditLogger.logSecurityTestExecution(report);

       return report;
     }

     private async runSecurityTestSuite(suite: SecurityTestSuite): Promise<SecurityTestSuiteResult> {
       const suiteResult: SecurityTestSuiteResult = {
         suite: suite.name,
         category: suite.category,
         severity: suite.severity,
         tests: [],
         startTime: new Date().toISOString(),
         endTime: '',
         duration: 0
       };

       const startTime = Date.now();

       for (const test of suite.tests) {
         try {
           const result = await test.implementation();
           suiteResult.tests.push({
             test: test,
             result: result,
             executionTime: Date.now() - startTime
           });

           // Log failed security tests immediately
           if (!result.passed) {
             await this.auditLogger.logSecurityTestFailure({
               testId: test.id,
               testName: test.name,
               suite: suite.name,
               severity: suite.severity,
               message: result.message,
               remediation: test.remediation
             });
           }

         } catch (error) {
           const errorResult: SecurityTestResult = {
             passed: false,
             message: `Test execution failed: ${error.message}`,
             evidence: { error: error.stack }
           };

           suiteResult.tests.push({
             test: test,
             result: errorResult,
             executionTime: Date.now() - startTime
           });

           await this.auditLogger.logSecurityTestError({
             testId: test.id,
             testName: test.name,
             suite: suite.name,
             error: error.message
           });
         }
       }

       suiteResult.endTime = new Date().toISOString();
       suiteResult.duration = Date.now() - startTime;

       return suiteResult;
     }

     // Example security test implementations
     private async testPasswordPolicyEnforcement(): Promise<SecurityTestResult> {
       try {
         // Test weak passwords are rejected
         const weakPasswords = ['password', '12345678', 'qwerty', 'admin', 'test'];

         for (const weakPassword of weakPasswords) {
           const isAccepted = await this.testPasswordAcceptance(weakPassword);
           if (isAccepted) {
             return {
               passed: false,
               message: `Weak password "${weakPassword}" was accepted`,
               evidence: { rejectedPassword: weakPassword }
             };
           }
         }

         // Test strong passwords are accepted
         const strongPassword = this.generateStrongPassword();
         const isStrongPasswordAccepted = await this.testPasswordAcceptance(strongPassword);

         if (!isStrongPasswordAccepted) {
           return {
             passed: false,
             message: 'Strong password was rejected',
             evidence: { strongPasswordLength: strongPassword.length }
           };
         }

         return {
           passed: true,
           message: 'Password policy enforcement is working correctly'
         };

       } catch (error) {
         return {
           passed: false,
           message: `Password policy test failed: ${error.message}`,
           evidence: { error: error.stack }
         };
       }
     }

     private async testSQLInjectionPrevention(): Promise<SecurityTestResult> {
       try {
         // Test common SQL injection payloads
         const sqlInjectionPayloads = [
           "'; DROP TABLE users; --",
           "' OR '1'='1",
           "admin'--",
           "'; EXEC xp_cmdshell('dir'); --",
           "' UNION SELECT password FROM users WHERE username='admin'--"
         ];

         for (const payload of sqlInjectionPayloads) {
           const isVulnerable = await this.testDatabaseQueryWithPayload(payload);
           if (isVulnerable) {
             return {
               passed: false,
               message: `SQL injection vulnerability detected with payload: ${payload.substring(0, 50)}...`,
               evidence: { payload: payload },
               cve_references: ['CWE-89']
             };
           }
         }

         return {
           passed: true,
           message: 'SQL injection prevention is working correctly'
         };

       } catch (error) {
         return {
           passed: false,
           message: `SQL injection test failed: ${error.message}`,
           evidence: { error: error.stack }
         };
       }
     }

     private async testXSSPrevention(): Promise<SecurityTestResult> {
       try {
         // Test common XSS payloads
         const xssPayloads = [
           "<script>alert('XSS')</script>",
           "<img src=x onerror=alert('XSS')>",
           "javascript:alert('XSS')",
           "<iframe src='javascript:alert(\"XSS\")'></iframe>",
           "<svg onload=alert('XSS')>"
         ];

         for (const payload of xssPayloads) {
           const isVulnerable = await this.testXSSPayloadExecution(payload);
           if (isVulnerable) {
             return {
               passed: false,
               message: `XSS vulnerability detected with payload: ${payload.substring(0, 50)}...`,
               evidence: { payload: payload },
               cve_references: ['CWE-79']
             };
           }
         }

         return {
           passed: true,
           message: 'XSS prevention is working correctly'
         };

       } catch (error) {
         return {
           passed: false,
           message: `XSS prevention test failed: ${error.message}`,
           evidence: { error: error.stack }
         };
       }
     }

     private generateSecurityTestSummary(report: SecurityTestReport): string {
       const passRate = (report.passedTests / report.totalTests * 100).toFixed(1);
       const criticalFailureCount = report.criticalFailures.length;

       let summary = `Security Test Summary: ${report.passedTests}/${report.totalTests} tests passed (${passRate}%)`;

       if (criticalFailureCount > 0) {
         summary += `\nCRITICAL: ${criticalFailureCount} critical security failures detected!`;
       }

       return summary;
     }

     // Helper methods for testing (would integrate with actual application)
     private async testPasswordAcceptance(password: string): Promise<boolean> {
       // Implementation would test actual password validation logic
       return password.length >= 12 && /[A-Z]/.test(password) && /[a-z]/.test(password) && /[0-9]/.test(password) && /[^A-Za-z0-9]/.test(password);
     }

     private generateStrongPassword(): string {
       const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
       let password = '';
       for (let i = 0; i < 16; i++) {
         password += chars.charAt(Math.floor(Math.random() * chars.length));
       }
       return password;
     }

     private async testDatabaseQueryWithPayload(payload: string): Promise<boolean> {
       // Implementation would test actual database queries with injection payloads
       // Return true if vulnerable, false if properly protected
       return false; // Assume protected for example
     }

     private async testXSSPayloadExecution(payload: string): Promise<boolean> {
       // Implementation would test actual XSS payload execution
       // Return true if vulnerable, false if properly protected
       return false; // Assume protected for example
     }
   }

   // Types for security test reporting
   interface SecurityTestReport {
     timestamp: string;
     totalTests: number;
     passedTests: number;
     failedTests: number;
     suiteResults: SecurityTestSuiteResult[];
     criticalFailures: any[];
     summary: string;
   }

   interface SecurityTestSuiteResult {
     suite: string;
     category: string;
     severity: string;
     tests: SecurityTestExecution[];
     startTime: string;
     endTime: string;
     duration: number;
   }

   interface SecurityTestExecution {
     test: SecurityTest;
     result: SecurityTestResult;
     executionTime: number;
   }
   ```

3. **Create Security-Focused Code Review Automation**: Implement automated code review checks that focus specifically on security concerns:

   Build automated code review systems that can identify security issues and provide specific guidance for remediation before human reviewers see the code.

   ```python
   import ast
   import re
   from typing import List, Dict, Any, Optional
   from dataclasses import dataclass
   from pathlib import Path

   @dataclass
   class SecurityCodeIssue:
       file_path: str
       line_number: int
       column: int
       severity: str  # critical, high, medium, low
       category: str  # authentication, authorization, input_validation, crypto, etc.
       rule_id: str
       description: str
       remediation: str
       code_snippet: str
       cwe_reference: Optional[str] = None

   class SecurityCodeReviewAutomation:
       def __init__(self):
           self.security_rules = self._initialize_security_rules()

       def _initialize_security_rules(self) -> List[Dict[str, Any]]:
           """Initialize comprehensive security rules for automated review."""
           return [
               {
                   'id': 'hardcoded-secret',
                   'name': 'Hardcoded Secret Detection',
                   'severity': 'critical',
                   'category': 'secrets_management',
                   'pattern': re.compile(r'(password|secret|key|token)\s*=\s*["\']([^"\']{8,})["\']', re.IGNORECASE),
                   'description': 'Hardcoded secret or credential detected',
                   'remediation': 'Use environment variables or secure secret management system',
                   'cwe': 'CWE-798'
               },
               {
                   'id': 'sql-injection-risk',
                   'name': 'SQL Injection Risk',
                   'severity': 'high',
                   'category': 'input_validation',
                   'pattern': re.compile(r'(execute|query|sql)\s*\(\s*["\'].*\+.*["\']', re.IGNORECASE),
                   'description': 'Potential SQL injection vulnerability from string concatenation',
                   'remediation': 'Use parameterized queries or prepared statements',
                   'cwe': 'CWE-89'
               },
               {
                   'id': 'weak-crypto',
                   'name': 'Weak Cryptographic Algorithm',
                   'severity': 'high',
                   'category': 'cryptography',
                   'pattern': re.compile(r'(md5|sha1|des|rc4)\s*\(', re.IGNORECASE),
                   'description': 'Weak cryptographic algorithm detected',
                   'remediation': 'Use strong cryptographic algorithms like SHA-256, AES-256, or ChaCha20',
                   'cwe': 'CWE-327'
               },
               {
                   'id': 'insecure-random',
                   'name': 'Insecure Random Number Generation',
                   'severity': 'medium',
                   'category': 'cryptography',
                   'pattern': re.compile(r'(random\.|Math\.random|rand\(\))', re.IGNORECASE),
                   'description': 'Insecure random number generation for security-sensitive operations',
                   'remediation': 'Use cryptographically secure random number generators',
                   'cwe': 'CWE-338'
               },
               {
                   'id': 'debug-mode-production',
                   'name': 'Debug Mode in Production',
                   'severity': 'medium',
                   'category': 'configuration',
                   'pattern': re.compile(r'debug\s*=\s*true', re.IGNORECASE),
                   'description': 'Debug mode enabled, potentially exposing sensitive information',
                   'remediation': 'Disable debug mode in production environments',
                   'cwe': 'CWE-489'
               }
           ]

       def review_file(self, file_path: Path) -> List[SecurityCodeIssue]:
           """Perform automated security review of a single file."""
           issues = []

           try:
               with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                   content = f.read()

               # Pattern-based security analysis
               issues.extend(self._analyze_with_patterns(file_path, content))

               # AST-based security analysis for Python files
               if file_path.suffix == '.py':
                   issues.extend(self._analyze_python_ast(file_path, content))

               return issues

           except Exception as e:
               return [SecurityCodeIssue(
                   file_path=str(file_path),
                   line_number=1,
                   column=1,
                   severity='low',
                   category='analysis_error',
                   rule_id='file-analysis-error',
                   description=f'Failed to analyze file: {e}',
                   remediation='Check file encoding and syntax',
                   code_snippet=''
               )]

       def _analyze_with_patterns(self, file_path: Path, content: str) -> List[SecurityCodeIssue]:
           """Analyze file content using pattern-based security rules."""
           issues = []
           lines = content.splitlines()

           for rule in self.security_rules:
               for line_num, line in enumerate(lines, 1):
                   matches = rule['pattern'].finditer(line)
                   for match in matches:
                       # Skip if this looks like a comment or documentation
                       if self._is_in_comment_or_doc(line, match.start()):
                           continue

                       issue = SecurityCodeIssue(
                           file_path=str(file_path),
                           line_number=line_num,
                           column=match.start() + 1,
                           severity=rule['severity'],
                           category=rule['category'],
                           rule_id=rule['id'],
                           description=rule['description'],
                           remediation=rule['remediation'],
                           code_snippet=line.strip(),
                           cwe_reference=rule.get('cwe')
                       )
                       issues.append(issue)

           return issues

       def _analyze_python_ast(self, file_path: Path, content: str) -> List[SecurityCodeIssue]:
           """Perform AST-based security analysis for Python files."""
           issues = []

           try:
               tree = ast.parse(content)
               visitor = SecurityASTVisitor(str(file_path))
               visitor.visit(tree)
               issues.extend(visitor.get_issues())
           except SyntaxError:
               # Skip files with syntax errors
               pass
           except Exception as e:
               issues.append(SecurityCodeIssue(
                   file_path=str(file_path),
                   line_number=1,
                   column=1,
                   severity='low',
                   category='analysis_error',
                   rule_id='ast-analysis-error',
                   description=f'AST analysis failed: {e}',
                   remediation='Check Python syntax and structure',
                   code_snippet=''
               ))

           return issues

       def _is_in_comment_or_doc(self, line: str, position: int) -> bool:
           """Check if the position is within a comment or documentation."""
           # Simple heuristic - check if line starts with comment markers
           stripped = line.strip()
           return (stripped.startswith('#') or
                   stripped.startswith('//') or
                   stripped.startswith('/*') or
                   stripped.startswith('*') or
                   'TODO' in line or
                   'FIXME' in line or
                   'example' in line.lower())

   class SecurityASTVisitor(ast.NodeVisitor):
       """AST visitor for detecting security issues in Python code."""

       def __init__(self, file_path: str):
           self.file_path = file_path
           self.issues: List[SecurityCodeIssue] = []

       def get_issues(self) -> List[SecurityCodeIssue]:
           return self.issues

       def visit_Call(self, node: ast.Call):
           """Visit function calls to detect security issues."""

           # Check for dangerous function calls
           if isinstance(node.func, ast.Name):
               func_name = node.func.id

               # Detect eval() and exec() calls
               if func_name in ['eval', 'exec']:
                   self.issues.append(SecurityCodeIssue(
                       file_path=self.file_path,
                       line_number=node.lineno,
                       column=node.col_offset,
                       severity='critical',
                       category='code_injection',
                       rule_id='dangerous-eval',
                       description=f'Dangerous {func_name}() call detected',
                       remediation='Avoid eval() and exec(). Use safer alternatives like ast.literal_eval() for data parsing',
                       code_snippet=f'{func_name}(...)',
                       cwe_reference='CWE-95'
                   ))

               # Detect subprocess calls without shell=False
               elif func_name == 'subprocess' and len(node.args) > 0:
                   # Check if shell=True is used
                   has_shell_true = any(
                       isinstance(kw, ast.keyword) and kw.arg == 'shell' and
                       isinstance(kw.value, ast.Constant) and kw.value.value is True
                       for kw in node.keywords
                   )

                   if has_shell_true:
                       self.issues.append(SecurityCodeIssue(
                           file_path=self.file_path,
                           line_number=node.lineno,
                           column=node.col_offset,
                           severity='high',
                           category='command_injection',
                           rule_id='subprocess-shell-injection',
                           description='subprocess call with shell=True detected',
                           remediation='Use shell=False and pass command as list to prevent shell injection',
                           code_snippet='subprocess(..., shell=True)',
                           cwe_reference='CWE-78'
                       ))

           self.generic_visit(node)

       def visit_Import(self, node: ast.Import):
           """Visit import statements to detect insecure libraries."""
           for alias in node.names:
               if alias.name in ['pickle', 'cPickle']:
                   self.issues.append(SecurityCodeIssue(
                       file_path=self.file_path,
                       line_number=node.lineno,
                       column=node.col_offset,
                       severity='medium',
                       category='deserialization',
                       rule_id='insecure-pickle',
                       description='Pickle module import detected',
                       remediation='Avoid pickle for untrusted data. Use JSON or other safe serialization formats',
                       code_snippet=f'import {alias.name}',
                       cwe_reference='CWE-502'
                   ))

           self.generic_visit(node)

   def generate_security_review_report(issues: List[SecurityCodeIssue]) -> str:
       """Generate a comprehensive security review report."""
       if not issues:
           return "✓ No security issues detected in automated review."

       # Group issues by severity
       issues_by_severity = {}
       for issue in issues:
           if issue.severity not in issues_by_severity:
               issues_by_severity[issue.severity] = []
           issues_by_severity[issue.severity].append(issue)

       report_lines = ["AUTOMATED SECURITY CODE REVIEW REPORT", "=" * 50, ""]

       # Report critical issues first
       severity_order = ['critical', 'high', 'medium', 'low']
       for severity in severity_order:
           if severity not in issues_by_severity:
               continue

           severity_issues = issues_by_severity[severity]
           report_lines.append(f"{severity.upper()} SEVERITY ISSUES ({len(severity_issues)}):")
           report_lines.append("-" * 40)

           for issue in severity_issues:
               report_lines.extend([
                   f"File: {issue.file_path}:{issue.line_number}:{issue.column}",
                   f"Rule: {issue.rule_id} ({issue.category})",
                   f"Description: {issue.description}",
                   f"Code: {issue.code_snippet}",
                   f"Remediation: {issue.remediation}",
               ])

               if issue.cwe_reference:
                   report_lines.append(f"CWE Reference: {issue.cwe_reference}")

               report_lines.append("")

       # Summary
       total_issues = len(issues)
       critical_count = len(issues_by_severity.get('critical', []))
       high_count = len(issues_by_severity.get('high', []))

       report_lines.extend([
           "SUMMARY:",
           f"Total Issues: {total_issues}",
           f"Critical: {critical_count}",
           f"High: {high_count}",
           f"Medium: {len(issues_by_severity.get('medium', []))}",
           f"Low: {len(issues_by_severity.get('low', []))}",
           "",
           "REQUIRED ACTIONS:",
           "- All critical and high severity issues must be resolved before merge",
           "- Medium severity issues should be addressed or documented",
           "- Low severity issues can be addressed in follow-up work",
           "",
           "All security issues must be resolved - suppression is not permitted."
       ])

       return "\n".join(report_lines)

   # CLI integration for automated security review
   def main():
       import argparse
       import sys

       parser = argparse.ArgumentParser(description='Automated security code review')
       parser.add_argument('files', nargs='*', help='Files to review')
       parser.add_argument('--format', choices=['text', 'json'], default='text', help='Output format')
       parser.add_argument('--fail-on-issues', action='store_true', help='Exit with error code if issues found')

       args = parser.parse_args()

       reviewer = SecurityCodeReviewAutomation()
       all_issues = []

       for file_path_str in args.files:
           file_path = Path(file_path_str)
           if file_path.is_file():
               issues = reviewer.review_file(file_path)
               all_issues.extend(issues)

       if args.format == 'json':
           import json
           issue_dicts = [
               {
                   'file': issue.file_path,
                   'line': issue.line_number,
                   'column': issue.column,
                   'severity': issue.severity,
                   'category': issue.category,
                   'rule_id': issue.rule_id,
                   'description': issue.description,
                   'remediation': issue.remediation,
                   'code_snippet': issue.code_snippet,
                   'cwe_reference': issue.cwe_reference
               }
               for issue in all_issues
           ]
           print(json.dumps(issue_dicts, indent=2))
       else:
           print(generate_security_review_report(all_issues))

       # Fail if critical or high severity issues found
       if args.fail_on_issues:
           critical_or_high = [i for i in all_issues if i.severity in ['critical', 'high']]
           if critical_or_high:
               sys.exit(1)

       return 0

   if __name__ == '__main__':
       main()
   ```

4. **Implement Comprehensive Security Checklist Validation**: Create automated validation that ensures all security checklist items are properly addressed:

   Build systems that automatically verify that security requirements are met and provide clear guidance when they're not.

   ```yaml
   # .security-checklist.yaml - Comprehensive security requirements
   security_checklist:
     metadata:
       version: "1.0"
       last_updated: "2025-06-11"
       required_for: ["commit", "pull_request", "deployment"]

     categories:
       authentication:
         name: "Authentication Security"
         required: true
         items:
           - id: "auth-strong-passwords"
             name: "Strong Password Policy"
             description: "Password complexity requirements enforced"
             validation_method: "automated_test"
             test_command: "python scripts/test-password-policy.py"

           - id: "auth-mfa-enforcement"
             name: "Multi-Factor Authentication"
             description: "MFA required for sensitive operations"
             validation_method: "automated_test"
             test_command: "python scripts/test-mfa-enforcement.py"

           - id: "auth-session-security"
             name: "Secure Session Management"
             description: "Sessions properly secured and expired"
             validation_method: "automated_test"
             test_command: "python scripts/test-session-security.py"

       input_validation:
         name: "Input Validation Security"
         required: true
         items:
           - id: "input-sql-injection"
             name: "SQL Injection Prevention"
             description: "All database queries use parameterized statements"
             validation_method: "static_analysis"
             tools: ["semgrep", "bandit"]
             patterns: ["sql-injection-risk"]

           - id: "input-xss-prevention"
             name: "XSS Prevention"
             description: "Output encoding and CSP implemented"
             validation_method: "automated_test"
             test_command: "python scripts/test-xss-prevention.py"

           - id: "input-command-injection"
             name: "Command Injection Prevention"
             description: "System commands properly validated"
             validation_method: "static_analysis"
             tools: ["semgrep"]
             patterns: ["command-injection-risk"]

       secrets_management:
         name: "Secrets Management"
         required: true
         items:
           - id: "secrets-no-hardcoding"
             name: "No Hardcoded Secrets"
             description: "No credentials or secrets in source code"
             validation_method: "secret_detection"
             tools: ["trufflehog", "detect-secrets", "gitleaks"]

           - id: "secrets-external-config"
             name: "External Configuration"
             description: "All secrets stored in secure external systems"
             validation_method: "manual_verification"
             checklist:
               - "Verify all secrets use environment variables or secret management"
               - "Confirm no secrets in configuration files"
               - "Validate secret rotation is implemented"

       cryptography:
         name: "Cryptographic Security"
         required: true
         items:
           - id: "crypto-strong-algorithms"
             name: "Strong Cryptographic Algorithms"
             description: "Only approved cryptographic algorithms used"
             validation_method: "static_analysis"
             tools: ["semgrep"]
             patterns: ["weak-crypto"]

           - id: "crypto-secure-random"
             name: "Secure Random Generation"
             description: "Cryptographically secure random numbers used"
             validation_method: "static_analysis"
             tools: ["semgrep", "bandit"]
             patterns: ["insecure-random"]

       infrastructure:
         name: "Infrastructure Security"
         required: true
         items:
           - id: "infra-https-only"
             name: "HTTPS Only"
             description: "All communications use HTTPS/TLS"
             validation_method: "automated_test"
             test_command: "python scripts/test-https-enforcement.py"

           - id: "infra-security-headers"
             name: "Security Headers"
             description: "Proper security headers configured"
             validation_method: "automated_test"
             test_command: "python scripts/test-security-headers.py"

   validation_rules:
     commit:
       required_categories: ["secrets_management", "input_validation"]
       failure_action: "block_commit"

     pull_request:
       required_categories: ["authentication", "input_validation", "secrets_management", "cryptography"]
       failure_action: "block_merge"

     deployment:
       required_categories: ["authentication", "input_validation", "secrets_management", "cryptography", "infrastructure"]
       failure_action: "block_deployment"
   ```

   ```python
   # scripts/security-checklist-validator.py - Automated checklist validation
   import yaml
   import subprocess
   import json
   import sys
   from pathlib import Path
   from typing import Dict, List, Any, Optional
   from dataclasses import dataclass

   @dataclass
   class ChecklistValidationResult:
       item_id: str
       item_name: str
       category: str
       passed: bool
       message: str
       evidence: Optional[Dict[str, Any]] = None

   class SecurityChecklistValidator:
       def __init__(self, checklist_config_path: str):
           with open(checklist_config_path, 'r') as f:
               self.config = yaml.safe_load(f)
           self.checklist = self.config['security_checklist']

       def validate_for_stage(self, stage: str) -> List[ChecklistValidationResult]:
           """Validate security checklist for a specific stage (commit, pull_request, deployment)."""
           validation_rules = self.config.get('validation_rules', {}).get(stage, {})
           required_categories = validation_rules.get('required_categories', [])

           results = []

           for category_name in required_categories:
               if category_name not in self.checklist['categories']:
                   continue

               category = self.checklist['categories'][category_name]
               category_results = self.validate_category(category_name, category)
               results.extend(category_results)

           return results

       def validate_category(self, category_name: str, category: Dict[str, Any]) -> List[ChecklistValidationResult]:
           """Validate all items in a security category."""
           results = []

           for item in category.get('items', []):
               result = self.validate_checklist_item(category_name, item)
               results.append(result)

           return results

       def validate_checklist_item(self, category_name: str, item: Dict[str, Any]) -> ChecklistValidationResult:
           """Validate a single checklist item."""
           item_id = item['id']
           item_name = item['name']
           validation_method = item['validation_method']

           try:
               if validation_method == 'automated_test':
                   return self._validate_with_automated_test(category_name, item)
               elif validation_method == 'static_analysis':
                   return self._validate_with_static_analysis(category_name, item)
               elif validation_method == 'secret_detection':
                   return self._validate_with_secret_detection(category_name, item)
               elif validation_method == 'manual_verification':
                   return self._validate_with_manual_checklist(category_name, item)
               else:
                   return ChecklistValidationResult(
                       item_id=item_id,
                       item_name=item_name,
                       category=category_name,
                       passed=False,
                       message=f"Unknown validation method: {validation_method}"
                   )

           except Exception as e:
               return ChecklistValidationResult(
                   item_id=item_id,
                   item_name=item_name,
                   category=category_name,
                   passed=False,
                   message=f"Validation failed with error: {e}",
                   evidence={'error': str(e)}
               )

       def _validate_with_automated_test(self, category_name: str, item: Dict[str, Any]) -> ChecklistValidationResult:
           """Validate using automated test execution."""
           test_command = item['test_command']

           try:
               result = subprocess.run(
                   test_command.split(),
                   capture_output=True,
                   text=True,
                   timeout=300  # 5 minute timeout
               )

               passed = result.returncode == 0
               message = "Test passed" if passed else f"Test failed: {result.stderr.strip()}"

               evidence = {
                   'exit_code': result.returncode,
                   'stdout': result.stdout.strip(),
                   'stderr': result.stderr.strip()
               }

               return ChecklistValidationResult(
                   item_id=item['id'],
                   item_name=item['name'],
                   category=category_name,
                   passed=passed,
                   message=message,
                   evidence=evidence
               )

           except subprocess.TimeoutExpired:
               return ChecklistValidationResult(
                   item_id=item['id'],
                   item_name=item['name'],
                   category=category_name,
                   passed=False,
                   message="Test timed out after 5 minutes"
               )

       def _validate_with_static_analysis(self, category_name: str, item: Dict[str, Any]) -> ChecklistValidationResult:
           """Validate using static analysis tools."""
           tools = item.get('tools', [])
           patterns = item.get('patterns', [])

           violations_found = []

           for tool in tools:
               try:
                   if tool == 'semgrep':
                       violations = self._run_semgrep_validation(patterns)
                       violations_found.extend(violations)
                   elif tool == 'bandit':
                       violations = self._run_bandit_validation(patterns)
                       violations_found.extend(violations)
               except Exception as e:
                   return ChecklistValidationResult(
                       item_id=item['id'],
                       item_name=item['name'],
                       category=category_name,
                       passed=False,
                       message=f"Static analysis failed: {e}"
                   )

           passed = len(violations_found) == 0
           message = "No violations found" if passed else f"Found {len(violations_found)} violations"

           return ChecklistValidationResult(
               item_id=item['id'],
               item_name=item['name'],
               category=category_name,
               passed=passed,
               message=message,
               evidence={'violations': violations_found}
           )

       def _validate_with_secret_detection(self, category_name: str, item: Dict[str, Any]) -> ChecklistValidationResult:
           """Validate using secret detection tools."""
           tools = item.get('tools', [])
           secrets_found = []

           for tool in tools:
               try:
                   if tool == 'trufflehog':
                       secrets = self._run_trufflehog_scan()
                       secrets_found.extend(secrets)
                   elif tool == 'detect-secrets':
                       secrets = self._run_detect_secrets_scan()
                       secrets_found.extend(secrets)
                   elif tool == 'gitleaks':
                       secrets = self._run_gitleaks_scan()
                       secrets_found.extend(secrets)
               except Exception as e:
                   return ChecklistValidationResult(
                       item_id=item['id'],
                       item_name=item['name'],
                       category=category_name,
                       passed=False,
                       message=f"Secret detection failed: {e}"
                   )

           passed = len(secrets_found) == 0
           message = "No secrets detected" if passed else f"Found {len(secrets_found)} potential secrets"

           return ChecklistValidationResult(
               item_id=item['id'],
               item_name=item['name'],
               category=category_name,
               passed=passed,
               message=message,
               evidence={'secrets': secrets_found}
           )

       def _validate_with_manual_checklist(self, category_name: str, item: Dict[str, Any]) -> ChecklistValidationResult:
           """Validate items that require manual verification."""
           checklist_items = item.get('checklist', [])

           # For automated validation, we can only check if the manual checklist is documented
           # In practice, this would integrate with a manual review system
           documented = len(checklist_items) > 0

           message = (
               f"Manual verification required. Checklist has {len(checklist_items)} items to verify."
               if documented else "No manual verification checklist provided"
           )

           return ChecklistValidationResult(
               item_id=item['id'],
               item_name=item['name'],
               category=category_name,
               passed=documented,
               message=message,
               evidence={'checklist_items': checklist_items}
           )

       # Helper methods for tool integration
       def _run_semgrep_validation(self, patterns: List[str]) -> List[Dict[str, Any]]:
           """Run semgrep with specific patterns."""
           # Implementation would run actual semgrep scan
           return []  # No violations for example

       def _run_bandit_validation(self, patterns: List[str]) -> List[Dict[str, Any]]:
           """Run bandit with specific patterns."""
           # Implementation would run actual bandit scan
           return []  # No violations for example

       def _run_trufflehog_scan(self) -> List[Dict[str, Any]]:
           """Run TruffleHog secret detection."""
           # Implementation would run actual TruffleHog scan
           return []  # No secrets for example

       def _run_detect_secrets_scan(self) -> List[Dict[str, Any]]:
           """Run detect-secrets scan."""
           # Implementation would run actual detect-secrets scan
           return []  # No secrets for example

       def _run_gitleaks_scan(self) -> List[Dict[str, Any]]:
           """Run GitLeaks scan."""
           # Implementation would run actual GitLeaks scan
           return []  # No secrets for example

   def generate_checklist_report(results: List[ChecklistValidationResult], stage: str) -> str:
       """Generate comprehensive checklist validation report."""
       if not results:
           return f"✓ No security checklist items to validate for {stage}."

       passed_count = sum(1 for r in results if r.passed)
       total_count = len(results)

       report_lines = [
           f"SECURITY CHECKLIST VALIDATION REPORT - {stage.upper()}",
           "=" * 60,
           f"Status: {passed_count}/{total_count} items passed",
           ""
       ]

       # Group by category
       by_category = {}
       for result in results:
           if result.category not in by_category:
               by_category[result.category] = []
           by_category[result.category].append(result)

       for category, category_results in by_category.items():
           category_passed = sum(1 for r in category_results if r.passed)
           category_total = len(category_results)

           report_lines.extend([
               f"{category.upper().replace('_', ' ')} ({category_passed}/{category_total})",
               "-" * 40
           ])

           for result in category_results:
               status_icon = "✓" if result.passed else "✗"
               report_lines.append(f"{status_icon} {result.item_name}: {result.message}")

           report_lines.append("")

       # Summary and required actions
       failed_results = [r for r in results if not r.passed]
       if failed_results:
           report_lines.extend([
               "FAILED ITEMS REQUIRING ATTENTION:",
               "-" * 40
           ])

           for result in failed_results:
               report_lines.extend([
                   f"• {result.item_name} ({result.category})",
                   f"  Issue: {result.message}",
                   f"  Action: Review and resolve this security requirement",
                   ""
               ])

       return "\n".join(report_lines)

   def main():
       import argparse

       parser = argparse.ArgumentParser(description='Security checklist validation')
       parser.add_argument('--config', default='.security-checklist.yaml', help='Checklist configuration file')
       parser.add_argument('--stage', required=True, choices=['commit', 'pull_request', 'deployment'], help='Validation stage')
       parser.add_argument('--format', choices=['text', 'json'], default='text', help='Output format')

       args = parser.parse_args()

       validator = SecurityChecklistValidator(args.config)
       results = validator.validate_for_stage(args.stage)

       if args.format == 'json':
           result_dicts = [
               {
                   'item_id': r.item_id,
                   'item_name': r.item_name,
                   'category': r.category,
                   'passed': r.passed,
                   'message': r.message,
                   'evidence': r.evidence
               }
               for r in results
           ]
           print(json.dumps(result_dicts, indent=2))
       else:
           print(generate_checklist_report(results, args.stage))

       # Exit with error if any items failed
       failed_count = sum(1 for r in results if not r.passed)
       if failed_count > 0:
           print(f"\nERROR: {failed_count} security checklist items failed.")
           print("All security requirements must be satisfied before proceeding.")
           sys.exit(1)

       print(f"\n✓ All security checklist items passed for {args.stage}.")
       return 0

   if __name__ == '__main__':
       main()
   ```

## Examples

```bash
# ❌ BAD: Manual security review process with inconsistent application
#!/bin/bash
# Manual security review script - often skipped under pressure

echo "Remember to check for:"
echo "- SQL injection vulnerabilities"
echo "- XSS prevention"
echo "- Hardcoded secrets"
echo "- Weak cryptography"
echo "Please review manually and approve when ready"

# No enforcement mechanism - can be easily bypassed
# No consistent checklist - items often forgotten
# No automated validation - relies on human memory
# No immediate feedback - issues found weeks later
```

```bash
# ✅ GOOD: Comprehensive automated security checklist with enforcement
#!/bin/bash
# Automated security checklist with comprehensive validation

set -e  # Exit on any error - no bypassing security checks

echo "🔒 AUTOMATED SECURITY CHECKLIST VALIDATION"
echo "==========================================="

# 1. Pre-commit security validation (cannot be bypassed)
echo "▶ Running pre-commit security hooks..."
pre-commit run --all-files
if [ $? -ne 0 ]; then
    echo "❌ Pre-commit security checks failed!"
    echo "All security issues must be resolved before proceeding."
    exit 1
fi

# 2. Secret detection across all tools
echo "▶ Running comprehensive secret detection..."
python scripts/detect-custom-secrets.py --config .secrets-config.yaml $(find . -type f -name "*.py" -o -name "*.js" -o -name "*.yaml" -o -name "*.json")
if [ $? -ne 0 ]; then
    echo "❌ Secret detection failed!"
    echo "No secrets are permitted in source code - use environment variables or secret management."
    exit 1
fi

# 3. Static security analysis
echo "▶ Running static application security testing..."
semgrep --config=auto --error --strict .
bandit -r . -f json -o bandit-report.json
if [ $? -ne 0 ]; then
    echo "❌ Static security analysis detected vulnerabilities!"
    echo "Review and resolve all identified security issues."
    exit 1
fi

# 4. Security-focused code review automation
echo "▶ Running automated security code review..."
python scripts/security-code-review.py --fail-on-issues $(find . -type f -name "*.py" -o -name "*.js")
if [ $? -ne 0 ]; then
    echo "❌ Automated security review detected issues!"
    echo "Address all critical and high severity security findings."
    exit 1
fi

# 5. Comprehensive security checklist validation
echo "▶ Validating security checklist compliance..."
python scripts/security-checklist-validator.py --stage commit --config .security-checklist.yaml
if [ $? -ne 0 ]; then
    echo "❌ Security checklist validation failed!"
    echo "All security requirements must be satisfied."
    exit 1
fi

# 6. Security testing automation
echo "▶ Running automated security tests..."
python scripts/security-test-suite.py --critical-only
if [ $? -ne 0 ]; then
    echo "❌ Critical security tests failed!"
    echo "Security test failures must be resolved immediately."
    exit 1
fi

echo "✅ All security checklist items passed!"
echo "Code meets security standards and is ready for review."

# Generate security compliance report
python scripts/generate-security-report.py --output security-compliance-report.json
echo "📊 Security compliance report generated: security-compliance-report.json"
```

```yaml
# ❌ BAD: Inconsistent security workflow with bypass mechanisms
# .github/workflows/security.yml
name: Security Review (Optional)
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security-check:
    runs-on: ubuntu-latest
    continue-on-error: true  # Allows bypassing failures
    steps:
      - uses: actions/checkout@v3

      # Basic security scan - often skipped
      - name: Run basic security scan
        run: |
          # Simple script that can be easily bypassed
          echo "Running security scan..."
          if [ "$SKIP_SECURITY" = "true" ]; then
            echo "Security scan skipped"
            exit 0
          fi

          # Limited checking with no enforcement
          grep -r "password" . || true
          grep -r "secret" . || true
          echo "Security scan complete"

      # Manual approval process - inconsistent
      - name: Request manual security review
        run: |
          echo "Please review security manually"
          echo "Approve when ready - no validation required"
```

```yaml
# ✅ GOOD: Comprehensive automated security workflow with strict enforcement
# .github/workflows/security-enforcement.yml
name: Security Enforcement (Required)
on:
  pull_request:
    types: [opened, synchronize, ready_for_review]
  push:
    branches: [main, master]

jobs:
  security-validation:
    runs-on: ubuntu-latest
    # NO continue-on-error - security failures block pipeline
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for comprehensive scanning

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install security tools
        run: |
          pip install bandit semgrep safety detect-secrets
          curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
          curl -sSfL https://github.com/zricethezav/gitleaks/releases/latest/download/gitleaks_linux_x64.tar.gz | tar xzf - -C /usr/local/bin

      - name: Comprehensive secret detection
        run: |
          echo "🔍 Scanning for secrets with multiple tools..."

          # TruffleHog - verified secrets only
          trufflehog filesystem . --only-verified --fail --no-update

          # GitLeaks - comprehensive pattern matching
          gitleaks detect --source . --verbose --redact

          # detect-secrets - baseline comparison
          detect-secrets scan --all-files --baseline .secrets.baseline

          # Custom organization patterns
          python scripts/detect-custom-secrets.py --config .secrets-config.yaml $(find . -type f)

      - name: Static application security testing (SAST)
        run: |
          echo "🔬 Running static security analysis..."

          # Semgrep - OWASP Top 10 and security patterns
          semgrep --config=auto --error --strict --json --output=semgrep-results.json .

          # Bandit - Python security analysis
          bandit -r . -f json -o bandit-results.json

          # Safety - dependency vulnerability scanning
          safety check --json --output safety-results.json

          echo "All static analysis tools completed successfully"

      - name: Automated security code review
        run: |
          echo "👨‍💻 Running automated security code review..."

          # Custom security patterns and AST analysis
          python scripts/security-code-review.py \
            --fail-on-issues \
            --format json \
            --output security-review-results.json \
            $(find . -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go")

          echo "Automated security review completed"

      - name: Security checklist validation
        run: |
          echo "📋 Validating security checklist compliance..."

          # Comprehensive checklist validation for pull request stage
          python scripts/security-checklist-validator.py \
            --stage pull_request \
            --config .security-checklist.yaml \
            --format json > checklist-results.json

          echo "Security checklist validation completed"

      - name: Automated security testing
        run: |
          echo "🧪 Running automated security tests..."

          # Run security test suite
          python scripts/security-test-suite.py \
            --stage ci \
            --fail-on-critical \
            --output security-test-results.json

          echo "Security testing completed"

      - name: Infrastructure security validation
        run: |
          echo "🏗️ Validating infrastructure security..."

          # Terraform security scanning
          if find . -name "*.tf" | grep -q .; then
            tfsec --format json --out tfsec-results.json .
          fi

          # Docker security scanning
          if find . -name "Dockerfile" | grep -q .; then
            python scripts/container-security-check.py --output container-security-results.json
          fi

          echo "Infrastructure security validation completed"

      - name: Generate comprehensive security report
        run: |
          echo "📊 Generating comprehensive security report..."

          python scripts/generate-comprehensive-security-report.py \
            --semgrep-results semgrep-results.json \
            --bandit-results bandit-results.json \
            --safety-results safety-results.json \
            --security-review-results security-review-results.json \
            --checklist-results checklist-results.json \
            --security-test-results security-test-results.json \
            --output comprehensive-security-report.json

      - name: Upload security artifacts
        uses: actions/upload-artifact@v3
        if: always()  # Upload even if security checks fail for analysis
        with:
          name: security-analysis-results
          path: |
            *-results.json
            comprehensive-security-report.json

      - name: Security compliance enforcement
        run: |
          echo "🛡️ Enforcing security compliance..."

          # Parse comprehensive report and enforce compliance
          python scripts/enforce-security-compliance.py \
            --report comprehensive-security-report.json \
            --stage pull_request \
            --fail-on-non-compliance

          echo "✅ All security requirements satisfied!"
          echo "Code meets security standards and compliance requirements."

      - name: Comment security summary on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');

            // Read comprehensive security report
            const report = JSON.parse(fs.readFileSync('comprehensive-security-report.json', 'utf8'));

            // Generate security summary comment
            const summary = `## 🔒 Security Analysis Summary

            ✅ **All security checks passed!**

            - **Secrets Detection**: No hardcoded secrets found
            - **Static Analysis**: No security vulnerabilities detected
            - **Code Review**: No critical security issues found
            - **Security Tests**: All critical security tests passed
            - **Checklist**: All security requirements satisfied

            **Compliance Status**: ✅ COMPLIANT

            Full security report available in workflow artifacts.`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: summary
            });

  # Security deployment gate for production
  security-deployment-gate:
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
    needs: security-validation
    runs-on: ubuntu-latest
    steps:
      - name: Enhanced security validation for deployment
        run: |
          echo "🚀 Running enhanced security validation for deployment..."

          # Additional deployment-specific security checks
          python scripts/security-checklist-validator.py \
            --stage deployment \
            --config .security-checklist.yaml

          echo "✅ Deployment security requirements satisfied!"
```

## Related Bindings

- [automation](../../docs/tenets/automation.md): Secure coding checklist directly implements automation principles by transforming manual security review processes into systematic, automated validation that runs consistently across all development activities. Both approaches eliminate human error and ensure consistent application of standards.

- [fix-broken-windows](../../docs/tenets/fix-broken-windows.md): Security checklist automation prevents security "broken windows" by catching security issues immediately when they're introduced and requiring immediate resolution rather than allowing them to accumulate as technical debt. Both principles ensure that quality and security problems are addressed immediately.

- [comprehensive-security-automation](../../docs/bindings/core/comprehensive-security-automation.md): Secure coding checklist is a specific implementation of comprehensive security automation, focusing on development workflow integration and code-level security validation. Both bindings work together to create systematic security validation throughout the development pipeline.

- [input-validation-standards](../../docs/bindings/categories/security/input-validation-standards.md): Security checklist automation includes comprehensive validation of input security standards through automated testing and static analysis. Both bindings ensure that security validation is systematic and comprehensive rather than ad-hoc.

- [secrets-management-practices](../../docs/bindings/categories/security/secrets-management-practices.md): Security checklist automation includes comprehensive secret detection and validation as core checklist items that must be satisfied before code changes are accepted. Both bindings work together to prevent credential exposure through multiple layers of automated detection.

- [authentication-authorization-patterns](../../docs/bindings/categories/security/authentication-authorization-patterns.md): Security checklist automation includes comprehensive testing and validation of authentication and authorization controls as required checklist items. Both bindings ensure that identity and access management is properly implemented and continuously validated.

- [no-secret-suppression](../../docs/tenets/no-secret-suppression.md): Security checklist automation never allows bypassing or suppressing security controls, ensuring that all security validation must be completed successfully before code changes are accepted. Both approaches prevent the dangerous practice of suppressing security warnings or checks.
