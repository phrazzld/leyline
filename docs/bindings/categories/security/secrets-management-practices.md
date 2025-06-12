---
id: secrets-management-practices
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: no-secret-suppression
enforced_by: secret detection tools (trufflehog, detect-secrets, gitleaks) + pre-commit hooks + automated scanning + security code review
---

# Binding: Implement Comprehensive Secrets Management Practices

Establish secure handling of all credentials, API keys, certificates, and sensitive configuration throughout the entire development and deployment lifecycle. Never suppress or bypass secret detection mechanisms, ensuring all sensitive data is properly managed, rotated, and monitored with comprehensive audit trails and access controls.

## Rationale

This binding directly implements our no-secret-suppression tenet by preventing the suppression, hardcoding, or improper handling of secrets and credentials in any part of your development workflow. Additionally, it builds upon external-configuration principles by ensuring that sensitive configuration is not only externalized but also properly secured, monitored, and managed throughout its lifecycle.

Think of secrets management like a secure vault system in a bank that has multiple layers of protection: physical security, access controls, audit logging, time-limited access, and regular inspections. Just as a bank wouldn't store cash in unlocked drawers or allow employees to bypass security protocols, your application shouldn't store secrets in source code, logs, or configuration files, and should never allow developers to suppress or bypass secret detection mechanisms "just this once."

Poor secrets management practices—such as hardcoding API keys in source code, storing passwords in configuration files, suppressing secret detection warnings, or bypassing credential rotation policies—create systemic security vulnerabilities that compound over time. Each suppressed warning or bypassed security control potentially represents a credential compromise that could lead to data breaches, unauthorized access, or complete system takeover. When secrets management is explicit and comprehensive, security teams can verify proper implementation, auditors can trace credential usage, and developers can confidently make changes without inadvertently exposing sensitive information.

The critical aspect of never suppressing secret detection tools aligns with our no-secret-suppression principle: when these automated guardians identify potential credential exposures, the proper response is always to investigate and remediate the root cause, never to silence the warning. Secret detection tools represent your first line of defense against credential leaks, and suppressing their alerts creates dangerous blind spots in your security posture.

## Rule Definition

Secrets management practices must implement comprehensive protection throughout the entire credential lifecycle with zero tolerance for suppression of security controls:

**Credential Definition and Scope:**

**Secrets Classification:**
- **High Sensitivity**: Production database passwords, encryption keys, OAuth client secrets, API keys with write access, signing certificates
- **Medium Sensitivity**: Development environment credentials, read-only API keys, service account tokens, webhook secrets
- **Low Sensitivity**: Public API endpoints, non-sensitive configuration tokens, rate limiting keys

**Complete Secrets Inventory:**
- **Authentication Credentials**: Passwords, private keys, OAuth tokens, JWT signing keys, SAML certificates
- **External Service Credentials**: API keys, webhooks secrets, third-party integration tokens, payment processor credentials
- **Infrastructure Secrets**: Database connection strings, cloud provider access keys, container registry credentials, VPN certificates
- **Encryption Materials**: Symmetric encryption keys, asymmetric key pairs, certificate authorities, key derivation salts
- **Application Secrets**: Session signing keys, CSRF tokens, application-specific secret values, feature flag credentials

**Never Suppress Secret Detection:**

**Zero Suppression Policy:**
- **No Secret Detection Bypasses**: Never suppress, ignore, or bypass secret detection tools through command-line flags, configuration overrides, or code comments
- **No False Positive Suppression**: All potential secret detections must be investigated and properly remediated, not suppressed as "false positives"
- **No Temporary Bypasses**: Never use "temporary" suppression with intentions to fix later - address secret detection immediately
- **Documented Exceptions Only**: Any legitimate non-secret detected by tools must be resolved through proper configuration or tool tuning, not suppression

**Secure Secrets Lifecycle Management:**

**Secrets Storage and Retrieval:**
- **Dedicated Secrets Management**: Use specialized secrets management systems (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, etc.) for all sensitive credentials
- **Environment-Specific Isolation**: Maintain complete separation between development, staging, and production secrets with no cross-environment access
- **Access Control Enforcement**: Implement role-based access control for secret retrieval with principle of least privilege
- **Audit Trail Maintenance**: Log all secret access, modification, and usage with comprehensive context and correlation identifiers

**Secrets Rotation and Expiration:**
- **Automated Rotation**: Implement automatic rotation for all credentials with configurable rotation periods based on sensitivity levels
- **Expiration Enforcement**: Set explicit expiration dates for all secrets with automated alerts before expiration
- **Rotation Verification**: Validate that rotation processes work correctly and don't break dependent services
- **Emergency Rotation**: Maintain capabilities for immediate credential rotation in case of suspected compromise

## Practical Implementation

1. **Establish Comprehensive Secret Detection Pipeline**: Implement multi-layered secret detection that catches credentials at every stage of development:

   Create detection systems that operate continuously throughout the development lifecycle, catching secrets before they reach production and maintaining ongoing monitoring for credential leaks or mishandling.

   ```yaml
   # .pre-commit-config.yaml - Comprehensive secret detection
   repos:
     - repo: https://github.com/trufflesecurity/trufflehog
       rev: v3.67.7
       hooks:
         - id: trufflehog
           name: Detect secrets with TruffleHog
           description: Detect hardcoded secrets in code
           entry: trufflehog filesystem
           language: system
           types: [text]
           args: ['--only-verified', '--fail']

     - repo: https://github.com/Yelp/detect-secrets
       rev: v1.4.0
       hooks:
         - id: detect-secrets
           name: Detect secrets
           description: Detect secrets in staged files
           entry: detect-secrets-hook
           language: python
           types: [text]
           args: ['--baseline', '.secrets.baseline', '--force-use-all-plugins']

     - repo: https://github.com/zricethezav/gitleaks
       rev: v8.18.0
       hooks:
         - id: gitleaks
           name: GitLeaks secret detection
           description: Detect hardcoded secrets using GitLeaks
           entry: gitleaks protect
           language: system
           args: ['--verbose', '--redact', '--staged']

     - repo: local
       hooks:
         - id: custom-secret-patterns
           name: Custom secret pattern detection
           description: Detect organization-specific secret patterns
           entry: scripts/detect-custom-secrets.py
           language: python
           types: [text]
           args: ['--config', '.secrets-config.yaml']
   ```

   ```python
   # scripts/detect-custom-secrets.py - Custom secret detection
   import re
   import sys
   import yaml
   from typing import List, Dict, Any

   class CustomSecretDetector:
       def __init__(self, config_path: str):
           with open(config_path, 'r') as f:
               self.config = yaml.safe_load(f)
           self.patterns = self._compile_patterns()

       def _compile_patterns(self) -> List[Dict[str, Any]]:
           """Compile organization-specific secret patterns."""
           compiled_patterns = []

           for pattern_config in self.config['patterns']:
               compiled_pattern = {
                   'name': pattern_config['name'],
                   'regex': re.compile(pattern_config['regex'], re.IGNORECASE),
                   'severity': pattern_config.get('severity', 'high'),
                   'description': pattern_config.get('description', ''),
                   'remediation': pattern_config.get('remediation', '')
               }
               compiled_patterns.append(compiled_pattern)

           return compiled_patterns

       def scan_file(self, file_path: str) -> List[Dict[str, Any]]:
           """Scan file for custom secret patterns."""
           findings = []

           try:
               with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                   content = f.read()

               for line_num, line in enumerate(content.splitlines(), 1):
                   for pattern in self.patterns:
                       matches = pattern['regex'].finditer(line)
                       for match in matches:
                           # Skip if this looks like a placeholder or example
                           if self._is_placeholder(match.group()):
                               continue

                           finding = {
                               'file': file_path,
                               'line': line_num,
                               'pattern': pattern['name'],
                               'severity': pattern['severity'],
                               'description': pattern['description'],
                               'match': match.group(),
                               'remediation': pattern['remediation']
                           }
                           findings.append(finding)

           except Exception as e:
               print(f"Error scanning {file_path}: {e}", file=sys.stderr)

           return findings

       def _is_placeholder(self, text: str) -> bool:
           """Check if detected text is a placeholder rather than real secret."""
           placeholder_patterns = [
               r'^(your|my|test|demo|example|placeholder|sample)[-_]',
               r'[-_](key|secret|token|password|here|value)$',
               r'^(xxx|yyy|zzz|abc|123)+',
               r'^\${[A-Z_]+}$',  # ${ENV_VAR} format
               r'^<[A-Z_]+>$',    # <PLACEHOLDER> format
               r'^(sk-)?[a-f0-9]{32,}$',  # All hex patterns
           ]

           for pattern in placeholder_patterns:
               if re.search(pattern, text, re.IGNORECASE):
                   return True
           return False

   def main():
       import argparse
       parser = argparse.ArgumentParser(description='Detect custom secret patterns')
       parser.add_argument('--config', required=True, help='Configuration file path')
       parser.add_argument('files', nargs='*', help='Files to scan')

       args = parser.parse_args()

       detector = CustomSecretDetector(args.config)
       total_findings = 0

       for file_path in args.files:
           findings = detector.scan_file(file_path)

           for finding in findings:
               print(f"SECRET DETECTED: {finding['file']}:{finding['line']}")
               print(f"  Pattern: {finding['pattern']} (severity: {finding['severity']})")
               print(f"  Description: {finding['description']}")
               print(f"  Match: {finding['match'][:50]}...")
               print(f"  Remediation: {finding['remediation']}")
               print()

           total_findings += len(findings)

       if total_findings > 0:
           print(f"CRITICAL: {total_findings} potential secrets detected!", file=sys.stderr)
           print("All detected secrets must be remediated - suppression is not permitted.", file=sys.stderr)
           sys.exit(1)

       print("No secrets detected.")
       return 0

   if __name__ == '__main__':
       main()
   ```

2. **Implement Secure Secrets Management Architecture**: Create comprehensive secrets management infrastructure that handles the entire credential lifecycle:

   Design secrets management systems that provide secure storage, controlled access, automated rotation, and comprehensive auditing for all credentials throughout their lifecycle.

   ```typescript
   interface SecretMetadata {
     id: string;
     name: string;
     sensitivity: 'high' | 'medium' | 'low';
     environment: string;
     createdAt: Date;
     expiresAt: Date;
     rotationPeriod: number; // days
     lastRotated: Date;
     accessPermissions: string[];
     auditContext: Record<string, any>;
   }

   interface SecretValue {
     value: string;
     version: number;
     createdAt: Date;
     metadata: SecretMetadata;
   }

   class SecureSecretsManager {
     private secretsProvider: SecretsProvider;
     private auditLogger: SecurityAuditLogger;
     private accessControl: AccessControlService;
     private rotationScheduler: RotationScheduler;

     constructor(config: SecretsManagerConfig) {
       this.secretsProvider = this.createSecretsProvider(config);
       this.auditLogger = new SecurityAuditLogger(config.audit);
       this.accessControl = new AccessControlService(config.access);
       this.rotationScheduler = new RotationScheduler(config.rotation);
     }

     async storeSecret(
       secretName: string,
       secretValue: string,
       metadata: Partial<SecretMetadata>,
       context: SecurityContext
     ): Promise<SecretMetadata> {
       const correlationId = generateCorrelationId();

       try {
         // 1. Validate secret storage request
         await this.validateSecretRequest(secretName, secretValue, metadata, context);

         // 2. Check permissions for secret storage
         if (!await this.accessControl.canStoreSecret(context.userId, secretName, metadata.environment)) {
           await this.auditLogger.logUnauthorizedSecretAccess(
             context.userId, secretName, 'store', correlationId
           );
           throw new UnauthorizedError('Insufficient permissions to store secret');
         }

         // 3. Validate secret value doesn't contain common mistakes
         this.validateSecretValue(secretValue, secretName);

         // 4. Create complete metadata
         const completeMetadata: SecretMetadata = {
           id: generateSecretId(),
           name: secretName,
           sensitivity: metadata.sensitivity || 'medium',
           environment: metadata.environment || 'development',
           createdAt: new Date(),
           expiresAt: this.calculateExpirationDate(metadata.sensitivity),
           rotationPeriod: this.getRotationPeriod(metadata.sensitivity),
           lastRotated: new Date(),
           accessPermissions: await this.deriveAccessPermissions(secretName, context),
           auditContext: {
             createdBy: context.userId,
             correlationId: correlationId,
             sourceSystem: context.sourceSystem
           }
         };

         // 5. Store secret securely with encryption
         await this.secretsProvider.storeSecret(secretName, secretValue, completeMetadata);

         // 6. Schedule automatic rotation
         await this.rotationScheduler.scheduleRotation(secretName, completeMetadata);

         // 7. Audit secret creation
         await this.auditLogger.logSecretCreated(completeMetadata, context, correlationId);

         return completeMetadata;

       } catch (error) {
         await this.auditLogger.logSecretOperationError(
           context.userId, secretName, 'store', error.message, correlationId
         );
         throw error;
       }
     }

     async retrieveSecret(secretName: string, context: SecurityContext): Promise<SecretValue> {
       const correlationId = generateCorrelationId();

       try {
         // 1. Check permissions for secret retrieval
         if (!await this.accessControl.canRetrieveSecret(context.userId, secretName, context.environment)) {
           await this.auditLogger.logUnauthorizedSecretAccess(
             context.userId, secretName, 'retrieve', correlationId
           );
           throw new UnauthorizedError('Insufficient permissions to retrieve secret');
         }

         // 2. Check if secret exists and is not expired
         const metadata = await this.secretsProvider.getSecretMetadata(secretName);
         if (!metadata) {
           throw new NotFoundError(`Secret ${secretName} not found`);
         }

         if (metadata.expiresAt < new Date()) {
           await this.auditLogger.logExpiredSecretAccess(
             context.userId, secretName, metadata.expiresAt, correlationId
           );
           throw new ExpiredSecretError(`Secret ${secretName} has expired`);
         }

         // 3. Retrieve secret value
         const secretValue = await this.secretsProvider.retrieveSecret(secretName);

         // 4. Audit secret access
         await this.auditLogger.logSecretAccessed(
           metadata, context.userId, correlationId
         );

         // 5. Check if rotation is needed
         if (this.shouldRotateSecret(metadata)) {
           await this.rotationScheduler.triggerRotation(secretName, 'approaching_expiration');
         }

         return {
           value: secretValue,
           version: metadata.version || 1,
           createdAt: metadata.createdAt,
           metadata: metadata
         };

       } catch (error) {
         await this.auditLogger.logSecretOperationError(
           context.userId, secretName, 'retrieve', error.message, correlationId
         );
         throw error;
       }
     }

     async rotateSecret(secretName: string, context: SecurityContext, reason: string): Promise<SecretMetadata> {
       const correlationId = generateCorrelationId();

       try {
         // 1. Check permissions for secret rotation
         if (!await this.accessControl.canRotateSecret(context.userId, secretName)) {
           await this.auditLogger.logUnauthorizedSecretAccess(
             context.userId, secretName, 'rotate', correlationId
           );
           throw new UnauthorizedError('Insufficient permissions to rotate secret');
         }

         // 2. Get current secret metadata
         const currentMetadata = await this.secretsProvider.getSecretMetadata(secretName);
         if (!currentMetadata) {
           throw new NotFoundError(`Secret ${secretName} not found`);
         }

         // 3. Generate new secret value
         const newSecretValue = await this.generateNewSecretValue(currentMetadata);

         // 4. Update secret with new value and metadata
         const updatedMetadata: SecretMetadata = {
           ...currentMetadata,
           lastRotated: new Date(),
           expiresAt: this.calculateExpirationDate(currentMetadata.sensitivity),
           version: (currentMetadata.version || 1) + 1,
           auditContext: {
             ...currentMetadata.auditContext,
             rotatedBy: context.userId,
             rotationReason: reason,
             correlationId: correlationId
           }
         };

         // 5. Store rotated secret
         await this.secretsProvider.storeSecret(secretName, newSecretValue, updatedMetadata);

         // 6. Schedule next rotation
         await this.rotationScheduler.scheduleRotation(secretName, updatedMetadata);

         // 7. Audit secret rotation
         await this.auditLogger.logSecretRotated(updatedMetadata, reason, context, correlationId);

         // 8. Notify dependent services of rotation
         await this.notifySecretRotation(secretName, updatedMetadata, context);

         return updatedMetadata;

       } catch (error) {
         await this.auditLogger.logSecretOperationError(
           context.userId, secretName, 'rotate', error.message, correlationId
         );
         throw error;
       }
     }

     private validateSecretValue(secretValue: string, secretName: string): void {
       // Validate secret doesn't contain common mistakes or patterns that suggest it's not a real secret

       const problematicPatterns = [
         { pattern: /^(test|demo|example|placeholder|sample)/, message: 'Secret appears to be a placeholder' },
         { pattern: /^(password|secret|key)$/i, message: 'Secret value is too generic' },
         { pattern: /^(123|abc|xxx|yyy|zzz)+$/i, message: 'Secret appears to be a test value' },
         { pattern: /\s/, message: 'Secret contains whitespace characters' },
         { pattern: /^.{1,7}$/, message: 'Secret is too short (minimum 8 characters)' },
       ];

       for (const { pattern, message } of problematicPatterns) {
         if (pattern.test(secretValue)) {
           throw new InvalidSecretError(`Invalid secret value for ${secretName}: ${message}`);
         }
       }

       // Check for potential credential exposure in the secret name
       if (secretValue.toLowerCase().includes(secretName.toLowerCase())) {
         throw new InvalidSecretError(`Secret value contains the secret name - potential misconfiguration`);
       }
     }

     private shouldRotateSecret(metadata: SecretMetadata): boolean {
       const rotationThreshold = metadata.rotationPeriod * 0.8; // Rotate at 80% of rotation period
       const daysSinceRotation = (Date.now() - metadata.lastRotated.getTime()) / (1000 * 60 * 60 * 24);
       return daysSinceRotation >= rotationThreshold;
     }

     private calculateExpirationDate(sensitivity: string): Date {
       const daysToAdd = sensitivity === 'high' ? 30 : sensitivity === 'medium' ? 60 : 90;
       return new Date(Date.now() + daysToAdd * 24 * 60 * 60 * 1000);
     }
   }
   ```

3. **Create Secrets Validation and Monitoring Systems**: Implement comprehensive validation and monitoring for secrets throughout their lifecycle:

   Build systems that continuously monitor secret usage, detect anomalies, validate proper handling, and maintain comprehensive audit trails for compliance and security investigations.

   ```python
   from dataclasses import dataclass
   from typing import List, Dict, Any, Optional
   from datetime import datetime, timedelta
   import hashlib
   import re

   @dataclass
   class SecretUsageEvent:
       secret_name: str
       user_id: str
       operation: str  # retrieve, store, rotate, delete
       timestamp: datetime
       source_ip: str
       user_agent: str
       success: bool
       error_message: Optional[str]
       correlation_id: str
       environment: str

   class SecretsMonitoringService:
       def __init__(self, config: MonitoringConfig):
           self.config = config
           self.usage_tracker = SecretUsageTracker()
           self.anomaly_detector = SecretAnomalyDetector()
           self.audit_logger = SecurityAuditLogger()
           self.alert_manager = SecurityAlertManager()

       async def monitor_secret_usage(self, usage_event: SecretUsageEvent) -> None:
           """Monitor and analyze secret usage patterns for security anomalies."""

           try:
               # 1. Record usage event
               await self.usage_tracker.record_usage(usage_event)

               # 2. Check for immediate security concerns
               await self._check_immediate_threats(usage_event)

               # 3. Analyze usage patterns for anomalies
               anomalies = await self.anomaly_detector.detect_anomalies(usage_event)

               # 4. Process any detected anomalies
               for anomaly in anomalies:
                   await self._handle_anomaly(anomaly, usage_event)

               # 5. Update usage statistics and trends
               await self.usage_tracker.update_statistics(usage_event)

           except Exception as e:
               await self.audit_logger.log_monitoring_error(
                   f"Failed to monitor secret usage: {e}",
                   usage_event.correlation_id
               )

       async def _check_immediate_threats(self, usage_event: SecretUsageEvent) -> None:
           """Check for immediate security threats that require immediate action."""

           # Check for suspicious IP addresses
           if await self._is_suspicious_ip(usage_event.source_ip):
               await self.alert_manager.trigger_immediate_alert(
                   severity='critical',
                   title=f'Secret access from suspicious IP: {usage_event.source_ip}',
                   details={
                       'secret_name': usage_event.secret_name,
                       'user_id': usage_event.user_id,
                       'ip_address': usage_event.source_ip,
                       'correlation_id': usage_event.correlation_id
                   }
               )

           # Check for off-hours access to highly sensitive secrets
           if await self._is_off_hours_sensitive_access(usage_event):
               await self.alert_manager.trigger_immediate_alert(
                   severity='high',
                   title=f'Off-hours access to sensitive secret: {usage_event.secret_name}',
                   details={
                       'secret_name': usage_event.secret_name,
                       'user_id': usage_event.user_id,
                       'timestamp': usage_event.timestamp.isoformat(),
                       'correlation_id': usage_event.correlation_id
                   }
               )

           # Check for failed authentication attempts
           if not usage_event.success and usage_event.operation == 'retrieve':
               await self._track_failed_access(usage_event)

       async def validate_secrets_compliance(self, environment: str) -> Dict[str, Any]:
           """Validate that all secrets meet compliance requirements."""

           compliance_report = {
               'environment': environment,
               'validation_timestamp': datetime.utcnow().isoformat(),
               'violations': [],
               'warnings': [],
               'summary': {}
           }

           try:
               # 1. Get all secrets for environment
               secrets = await self.secrets_provider.list_secrets(environment)

               # 2. Validate each secret against compliance rules
               for secret in secrets:
                   violations = await self._validate_secret_compliance(secret)
                   compliance_report['violations'].extend(violations)

               # 3. Check for secrets nearing expiration
               expiring_secrets = await self._find_expiring_secrets(secrets)
               for secret in expiring_secrets:
                   compliance_report['warnings'].append({
                       'type': 'expiring_secret',
                       'secret_name': secret.name,
                       'expires_at': secret.expires_at.isoformat(),
                       'days_remaining': (secret.expires_at - datetime.utcnow()).days
                   })

               # 4. Check rotation compliance
               rotation_violations = await self._check_rotation_compliance(secrets)
               compliance_report['violations'].extend(rotation_violations)

               # 5. Generate summary
               compliance_report['summary'] = {
                   'total_secrets': len(secrets),
                   'violation_count': len(compliance_report['violations']),
                   'warning_count': len(compliance_report['warnings']),
                   'compliance_percentage': self._calculate_compliance_percentage(compliance_report)
               }

               # 6. Audit compliance check
               await self.audit_logger.log_compliance_check(compliance_report)

               return compliance_report

           except Exception as e:
               await self.audit_logger.log_monitoring_error(
                   f"Failed to validate secrets compliance: {e}",
                   f"compliance_check_{environment}"
               )
               raise

       async def _validate_secret_compliance(self, secret: SecretMetadata) -> List[Dict[str, Any]]:
           """Validate individual secret against compliance rules."""
           violations = []

           # Check naming conventions
           if not self._validates_naming_convention(secret.name):
               violations.append({
                   'type': 'naming_violation',
                   'secret_name': secret.name,
                   'description': 'Secret name does not follow naming conventions',
                   'severity': 'medium'
               })

           # Check rotation schedule compliance
           if self._is_rotation_overdue(secret):
               violations.append({
                   'type': 'rotation_overdue',
                   'secret_name': secret.name,
                   'last_rotated': secret.last_rotated.isoformat(),
                   'rotation_period_days': secret.rotation_period,
                   'description': f'Secret rotation is overdue by {self._days_overdue(secret)} days',
                   'severity': 'high'
               })

           # Check access permissions
           if await self._has_excessive_permissions(secret):
               violations.append({
                   'type': 'excessive_permissions',
                   'secret_name': secret.name,
                   'description': 'Secret has more access permissions than necessary',
                   'severity': 'medium'
               })

           # Check for unused secrets
           if await self._is_unused_secret(secret):
               violations.append({
                   'type': 'unused_secret',
                   'secret_name': secret.name,
                   'last_accessed': await self._get_last_access_time(secret.name),
                   'description': 'Secret has not been accessed recently and may be unused',
                   'severity': 'low'
               })

           return violations

   class SecretAnomalyDetector:
       def __init__(self):
           self.baseline_calculator = UsageBaselineCalculator()
           self.pattern_analyzer = UsagePatternAnalyzer()

       async def detect_anomalies(self, usage_event: SecretUsageEvent) -> List[Dict[str, Any]]:
           """Detect anomalies in secret usage patterns."""
           anomalies = []

           # 1. Unusual access frequency
           frequency_anomaly = await self._detect_frequency_anomaly(usage_event)
           if frequency_anomaly:
               anomalies.append(frequency_anomaly)

           # 2. Unusual access timing
           timing_anomaly = await self._detect_timing_anomaly(usage_event)
           if timing_anomaly:
               anomalies.append(timing_anomaly)

           # 3. Unusual access location
           location_anomaly = await self._detect_location_anomaly(usage_event)
           if location_anomaly:
               anomalies.append(location_anomaly)

           # 4. Unusual user behavior
           behavior_anomaly = await self._detect_behavior_anomaly(usage_event)
           if behavior_anomaly:
               anomalies.append(behavior_anomaly)

           return anomalies

       async def _detect_frequency_anomaly(self, usage_event: SecretUsageEvent) -> Optional[Dict[str, Any]]:
           """Detect unusual frequency of secret access."""

           # Get baseline access frequency for this secret and user
           baseline = await self.baseline_calculator.get_access_frequency_baseline(
               usage_event.secret_name,
               usage_event.user_id
           )

           # Get recent access count
           recent_access_count = await self._get_recent_access_count(
               usage_event.secret_name,
               usage_event.user_id,
               hours=1
           )

           # Check if recent access exceeds baseline threshold
           if recent_access_count > baseline.threshold * 3:  # 3x normal frequency
               return {
                   'type': 'frequency_anomaly',
                   'secret_name': usage_event.secret_name,
                   'user_id': usage_event.user_id,
                   'recent_count': recent_access_count,
                   'baseline_threshold': baseline.threshold,
                   'severity': 'high' if recent_access_count > baseline.threshold * 5 else 'medium',
                   'description': f'User accessed secret {recent_access_count} times in 1 hour (baseline: {baseline.threshold})'
               }

           return None
   ```

4. **Implement Secrets Testing and Validation**: Create comprehensive testing strategies that validate secrets management without exposing real credentials:

   Build test suites that verify secrets management logic works correctly, handles failures gracefully, and maintains security properties without using real credentials in test environments.

   ```go
   package secrets_test

   import (
       "context"
       "testing"
       "time"
       "github.com/stretchr/testify/assert"
       "github.com/stretchr/testify/mock"
   )

   func TestSecretsManagement(t *testing.T) {
       testCases := []struct {
           name string
           test func(t *testing.T)
       }{
           {"TestSecretStorage", testSecretStorage},
           {"TestSecretRetrieval", testSecretRetrieval},
           {"TestSecretRotation", testSecretRotation},
           {"TestSecretAccessControl", testSecretAccessControl},
           {"TestSecretValidation", testSecretValidation},
           {"TestSecretMonitoring", testSecretMonitoring},
       }

       for _, tc := range testCases {
           t.Run(tc.name, tc.test)
       }
   }

   func testSecretStorage(t *testing.T) {
       ctx := context.Background()
       secretsManager := setupTestSecretsManager(t)

       t.Run("should store valid secret successfully", func(t *testing.T) {
           testSecret := generateTestSecret()
           securityContext := createTestSecurityContext("test-user-id", "development")

           metadata, err := secretsManager.StoreSecret(
               ctx,
               "test-api-key",
               testSecret,
               SecretMetadata{
                   Sensitivity: "medium",
                   Environment: "development",
               },
               securityContext,
           )

           assert.NoError(t, err)
           assert.Equal(t, "test-api-key", metadata.Name)
           assert.Equal(t, "medium", metadata.Sensitivity)
           assert.Equal(t, "development", metadata.Environment)
           assert.NotZero(t, metadata.CreatedAt)
           assert.NotZero(t, metadata.ExpiresAt)
       })

       t.Run("should reject secrets that appear to be placeholders", func(t *testing.T) {
           placeholderSecrets := []string{
               "your-api-key-here",
               "test-secret-value",
               "example-password",
               "placeholder-token",
               "sample-key",
               "demo-secret",
               "xxx-api-key",
               "123456789",
               "password",
               "secret",
           }

           securityContext := createTestSecurityContext("test-user-id", "development")

           for _, placeholderSecret := range placeholderSecrets {
               t.Run(fmt.Sprintf("reject_%s", placeholderSecret), func(t *testing.T) {
                   _, err := secretsManager.StoreSecret(
                       ctx,
                       "test-secret",
                       placeholderSecret,
                       SecretMetadata{Sensitivity: "medium", Environment: "development"},
                       securityContext,
                   )

                   assert.Error(t, err)
                   assert.Contains(t, err.Error(), "Invalid secret value")
               })
           }
       })

       t.Run("should reject secrets that are too short", func(t *testing.T) {
           shortSecrets := []string{"", "a", "ab", "abc", "1234567"}
           securityContext := createTestSecurityContext("test-user-id", "development")

           for _, shortSecret := range shortSecrets {
               _, err := secretsManager.StoreSecret(
                   ctx,
                   "test-secret",
                   shortSecret,
                   SecretMetadata{Sensitivity: "medium", Environment: "development"},
                   securityContext,
               )

               assert.Error(t, err)
               assert.Contains(t, err.Error(), "too short")
           }
       })

       t.Run("should enforce access control on secret storage", func(t *testing.T) {
           testSecret := generateTestSecret()
           unauthorizedContext := createTestSecurityContext("unauthorized-user", "production")

           _, err := secretsManager.StoreSecret(
               ctx,
               "production-secret",
               testSecret,
               SecretMetadata{Sensitivity: "high", Environment: "production"},
               unauthorizedContext,
           )

           assert.Error(t, err)
           assert.Contains(t, err.Error(), "Insufficient permissions")
       })
   }

   func testSecretRetrieval(t *testing.T) {
       ctx := context.Background()
       secretsManager := setupTestSecretsManager(t)

       t.Run("should retrieve valid secret successfully", func(t *testing.T) {
           // Setup: Store a test secret
           testSecret := generateTestSecret()
           securityContext := createTestSecurityContext("test-user-id", "development")

           storedMetadata, err := secretsManager.StoreSecret(
               ctx,
               "test-retrieval-secret",
               testSecret,
               SecretMetadata{Sensitivity: "medium", Environment: "development"},
               securityContext,
           )
           assert.NoError(t, err)

           // Test: Retrieve the secret
           retrievedSecret, err := secretsManager.RetrieveSecret(
               ctx,
               "test-retrieval-secret",
               securityContext,
           )

           assert.NoError(t, err)
           assert.Equal(t, testSecret, retrievedSecret.Value)
           assert.Equal(t, storedMetadata.ID, retrievedSecret.Metadata.ID)
       })

       t.Run("should enforce access control on secret retrieval", func(t *testing.T) {
           // Setup: Store a secret with specific user
           testSecret := generateTestSecret()
           ownerContext := createTestSecurityContext("owner-user", "development")

           _, err := secretsManager.StoreSecret(
               ctx,
               "owner-only-secret",
               testSecret,
               SecretMetadata{Sensitivity: "high", Environment: "development"},
               ownerContext,
           )
           assert.NoError(t, err)

           // Test: Try to retrieve with unauthorized user
           unauthorizedContext := createTestSecurityContext("unauthorized-user", "development")

           _, err = secretsManager.RetrieveSecret(
               ctx,
               "owner-only-secret",
               unauthorizedContext,
           )

           assert.Error(t, err)
           assert.Contains(t, err.Error(), "Insufficient permissions")
       })

       t.Run("should reject retrieval of expired secrets", func(t *testing.T) {
           // This test would use time manipulation to test expiration
           // In real implementation, you'd use time mocking
           testSecret := generateTestSecret()
           securityContext := createTestSecurityContext("test-user-id", "development")

           // Store secret with very short expiration
           metadata := SecretMetadata{
               Sensitivity: "medium",
               Environment: "development",
               ExpiresAt:   time.Now().Add(-1 * time.Hour), // Already expired
           }

           // Mock the secrets provider to return an expired secret
           mockProvider := secretsManager.secretsProvider.(*MockSecretsProvider)
           mockProvider.On("GetSecretMetadata", "expired-secret").Return(metadata, nil)

           _, err := secretsManager.RetrieveSecret(
               ctx,
               "expired-secret",
               securityContext,
           )

           assert.Error(t, err)
           assert.Contains(t, err.Error(), "has expired")
       })
   }

   func testSecretRotation(t *testing.T) {
       ctx := context.Background()
       secretsManager := setupTestSecretsManager(t)

       t.Run("should rotate secret successfully", func(t *testing.T) {
           // Setup: Store initial secret
           initialSecret := generateTestSecret()
           securityContext := createTestSecurityContext("test-user-id", "development")

           initialMetadata, err := secretsManager.StoreSecret(
               ctx,
               "rotation-test-secret",
               initialSecret,
               SecretMetadata{Sensitivity: "medium", Environment: "development"},
               securityContext,
           )
           assert.NoError(t, err)

           // Test: Rotate the secret
           rotatedMetadata, err := secretsManager.RotateSecret(
               ctx,
               "rotation-test-secret",
               securityContext,
               "scheduled_rotation",
           )

           assert.NoError(t, err)
           assert.Equal(t, initialMetadata.Name, rotatedMetadata.Name)
           assert.Greater(t, rotatedMetadata.Version, initialMetadata.Version)
           assert.True(t, rotatedMetadata.LastRotated.After(initialMetadata.LastRotated))

           // Verify the secret value has changed
           rotatedSecret, err := secretsManager.RetrieveSecret(
               ctx,
               "rotation-test-secret",
               securityContext,
           )
           assert.NoError(t, err)
           assert.NotEqual(t, initialSecret, rotatedSecret.Value)
       })

       t.Run("should enforce access control on secret rotation", func(t *testing.T) {
           unauthorizedContext := createTestSecurityContext("unauthorized-user", "production")

           _, err := secretsManager.RotateSecret(
               ctx,
               "production-secret",
               unauthorizedContext,
               "manual_rotation",
           )

           assert.Error(t, err)
           assert.Contains(t, err.Error(), "Insufficient permissions")
       })
   }

   func testSecretValidation(t *testing.T) {
       t.Run("should validate secret detection tools configuration", func(t *testing.T) {
           // Test that secret detection tools are properly configured
           detectionTools := []string{"trufflehog", "detect-secrets", "gitleaks"}

           for _, tool := range detectionTools {
               t.Run(fmt.Sprintf("validate_%s_config", tool), func(t *testing.T) {
                   config, err := loadSecretDetectionConfig(tool)
                   assert.NoError(t, err, "Secret detection tool %s should be properly configured", tool)
                   assert.NotEmpty(t, config.Patterns, "Tool %s should have detection patterns", tool)
                   assert.True(t, config.Enabled, "Tool %s should be enabled", tool)
               })
           }
       })

       t.Run("should validate that no real secrets exist in test files", func(t *testing.T) {
           // Scan test files for potential real secrets
           testFiles := []string{
               "secrets_test.go",
               "test_fixtures.go",
               "integration_test.go",
           }

           detector := NewSecretDetector()

           for _, testFile := range testFiles {
               findings := detector.ScanFile(testFile)

               // Filter out known test patterns
               realSecretFindings := filterTestPatterns(findings)

               assert.Empty(t, realSecretFindings,
                   "Test file %s should not contain real secrets: %v", testFile, realSecretFindings)
           }
       })
   }

   // Helper functions for testing
   func generateTestSecret() string {
       // Generate a cryptographically secure test secret that doesn't match common patterns
       return fmt.Sprintf("test-secret-%s-%d",
           generateRandomString(16),
           time.Now().UnixNano())
   }

   func createTestSecurityContext(userID, environment string) SecurityContext {
       return SecurityContext{
           UserID:       userID,
           Environment:  environment,
           IPAddress:    "127.0.0.1",
           UserAgent:    "test-agent",
           SourceSystem: "unit-test",
       }
   }

   func setupTestSecretsManager(t *testing.T) *SecretsManager {
       // Create mock implementations for testing
       mockProvider := new(MockSecretsProvider)
       mockAuditLogger := new(MockAuditLogger)
       mockAccessControl := new(MockAccessControl)

       // Configure mocks with test behavior
       setupMockBehavior(mockProvider, mockAuditLogger, mockAccessControl)

       return &SecretsManager{
           secretsProvider: mockProvider,
           auditLogger:     mockAuditLogger,
           accessControl:   mockAccessControl,
       }
   }
   ```

## Examples

```python
# ❌ BAD: Hardcoded secrets with suppressed detection
import os
# GitLeaks:ignore - "temporary" suppression that becomes permanent
API_KEY = "sk-1a2b3c4d5e6f7g8h9i0j"  # Real API key hardcoded!
DATABASE_URL = "postgresql://admin:super_secret_password@db.production.com:5432/app"

class DatabaseService:
    def __init__(self):
        # More hardcoded secrets
        self.redis_password = "redis_prod_password_2023"  # detect-secrets:disable-line
        self.jwt_secret = "my-super-secret-jwt-key"

    def connect(self):
        # Using hardcoded credentials
        return psycopg2.connect(DATABASE_URL)

def send_analytics(data):
    # Hardcoded webhook secret
    webhook_secret = "whsec_test12345"  # This is actually production!
    headers = {"Authorization": f"Bearer {API_KEY}"}
    requests.post("https://api.service.com/events", json=data, headers=headers)
```

```python
# ✅ GOOD: Comprehensive secrets management with detection and monitoring
import os
import secrets
from datetime import datetime, timedelta
from typing import Optional

class SecureConfigurationManager:
    def __init__(self, secrets_manager: SecretsManager, environment: str):
        self.secrets_manager = secrets_manager
        self.environment = environment
        self.audit_logger = SecurityAuditLogger()

    async def get_database_config(self, user_context: SecurityContext) -> DatabaseConfig:
        """Retrieve database configuration using secure secrets management."""

        try:
            # Retrieve database credentials from secrets manager
            db_credentials = await self.secrets_manager.retrieve_secret(
                secret_name=f"database-credentials-{self.environment}",
                context=user_context
            )

            # Parse structured secret value
            db_config = json.loads(db_credentials.value)

            return DatabaseConfig(
                host=db_config['host'],
                port=db_config['port'],
                database=db_config['database'],
                username=db_config['username'],
                password=db_config['password'],  # Retrieved securely, not hardcoded
                ssl_mode='require'
            )

        except Exception as e:
            await self.audit_logger.log_config_retrieval_error(
                config_type='database',
                environment=self.environment,
                user_id=user_context.user_id,
                error=str(e)
            )
            raise ConfigurationError(f"Failed to retrieve database configuration: {e}")

    async def get_api_credentials(self, service_name: str, user_context: SecurityContext) -> APICredentials:
        """Retrieve API credentials with validation and monitoring."""

        secret_name = f"{service_name}-api-credentials-{self.environment}"

        try:
            # Retrieve API credentials
            api_secret = await self.secrets_manager.retrieve_secret(
                secret_name=secret_name,
                context=user_context
            )

            # Parse and validate credentials
            credentials_data = json.loads(api_secret.value)
            api_credentials = APICredentials(
                api_key=credentials_data['api_key'],
                api_secret=credentials_data.get('api_secret'),
                endpoint=credentials_data['endpoint']
            )

            # Validate credentials are not placeholder values
            self._validate_credentials_not_placeholder(api_credentials, secret_name)

            # Check if credentials are approaching expiration
            if self._credentials_need_rotation(api_secret.metadata):
                await self._schedule_credential_rotation(secret_name, user_context)

            return api_credentials

        except Exception as e:
            await self.audit_logger.log_config_retrieval_error(
                config_type='api_credentials',
                service_name=service_name,
                environment=self.environment,
                user_id=user_context.user_id,
                error=str(e)
            )
            raise ConfigurationError(f"Failed to retrieve {service_name} API credentials: {e}")

    def _validate_credentials_not_placeholder(self, credentials: APICredentials, secret_name: str):
        """Validate that retrieved credentials are not placeholder values."""

        placeholder_patterns = [
            'your-api-key-here',
            'test-api-key',
            'example-key',
            'placeholder',
            'sample-key',
            'demo-secret',
            'xxx-api-key'
        ]

        for pattern in placeholder_patterns:
            if pattern.lower() in credentials.api_key.lower():
                raise InvalidCredentialsError(
                    f"Secret {secret_name} contains placeholder value: {pattern}"
                )

class SecureDatabaseService:
    def __init__(self, config_manager: SecureConfigurationManager):
        self.config_manager = config_manager
        self.connection_pool = None

    async def initialize(self, user_context: SecurityContext):
        """Initialize database service with secure configuration."""

        try:
            # Get database configuration securely
            db_config = await self.config_manager.get_database_config(user_context)

            # Create connection pool with secure configuration
            self.connection_pool = await asyncpg.create_pool(
                host=db_config.host,
                port=db_config.port,
                database=db_config.database,
                user=db_config.username,
                password=db_config.password,
                ssl='require',
                min_size=5,
                max_size=20,
                command_timeout=30
            )

            await self.audit_logger.log_database_connection_established(
                environment=self.config_manager.environment,
                user_id=user_context.user_id
            )

        except Exception as e:
            await self.audit_logger.log_database_connection_error(
                environment=self.config_manager.environment,
                user_id=user_context.user_id,
                error=str(e)
            )
            raise DatabaseConnectionError(f"Failed to initialize database service: {e}")

class SecureAnalyticsService:
    def __init__(self, config_manager: SecureConfigurationManager):
        self.config_manager = config_manager
        self.api_credentials = None

    async def initialize(self, user_context: SecurityContext):
        """Initialize analytics service with secure API credentials."""

        try:
            # Retrieve analytics API credentials securely
            self.api_credentials = await self.config_manager.get_api_credentials(
                service_name='analytics',
                user_context=user_context
            )

            # Validate credentials work
            await self._validate_credentials()

            await self.audit_logger.log_service_initialization(
                service_name='analytics',
                environment=self.config_manager.environment,
                user_id=user_context.user_id
            )

        except Exception as e:
            await self.audit_logger.log_service_initialization_error(
                service_name='analytics',
                environment=self.config_manager.environment,
                user_id=user_context.user_id,
                error=str(e)
            )
            raise ServiceInitializationError(f"Failed to initialize analytics service: {e}")

    async def send_event(self, event_data: dict, user_context: SecurityContext):
        """Send analytics event using secure credentials."""

        if not self.api_credentials:
            raise ServiceNotInitializedError("Analytics service not initialized")

        try:
            headers = {
                'Authorization': f'Bearer {self.api_credentials.api_key}',
                'Content-Type': 'application/json',
                'X-Service-Version': '1.0',
                'X-Environment': self.config_manager.environment
            }

            # Sign request if secret key available
            if self.api_credentials.api_secret:
                signature = self._generate_request_signature(event_data, self.api_credentials.api_secret)
                headers['X-Signature'] = signature

            response = await aiohttp.post(
                self.api_credentials.endpoint,
                json=event_data,
                headers=headers,
                timeout=aiohttp.ClientTimeout(total=30)
            )

            if response.status == 200:
                await self.audit_logger.log_analytics_event_sent(
                    event_type=event_data.get('type', 'unknown'),
                    user_id=user_context.user_id,
                    environment=self.config_manager.environment
                )
            else:
                await self.audit_logger.log_analytics_event_error(
                    event_type=event_data.get('type', 'unknown'),
                    status_code=response.status,
                    user_id=user_context.user_id,
                    environment=self.config_manager.environment
                )

        except Exception as e:
            await self.audit_logger.log_analytics_event_error(
                event_type=event_data.get('type', 'unknown'),
                error=str(e),
                user_id=user_context.user_id,
                environment=self.config_manager.environment
            )
            raise AnalyticsEventError(f"Failed to send analytics event: {e}")

# Example of secure application initialization
async def initialize_application():
    """Initialize application with comprehensive secrets management."""

    # Create security context for application initialization
    system_context = SecurityContext(
        user_id='system',
        environment=os.getenv('ENVIRONMENT', 'development'),
        source_system='application_startup'
    )

    try:
        # Initialize secrets manager
        secrets_manager = SecretsManager(
            provider=create_secrets_provider(),
            audit_logger=SecurityAuditLogger(),
            access_control=AccessControlService()
        )

        # Initialize configuration manager
        config_manager = SecureConfigurationManager(
            secrets_manager=secrets_manager,
            environment=system_context.environment
        )

        # Initialize services with secure configuration
        database_service = SecureDatabaseService(config_manager)
        await database_service.initialize(system_context)

        analytics_service = SecureAnalyticsService(config_manager)
        await analytics_service.initialize(system_context)

        # Audit successful application initialization
        await audit_logger.log_application_initialized(
            environment=system_context.environment,
            services=['database', 'analytics']
        )

        return {
            'database': database_service,
            'analytics': analytics_service,
            'config_manager': config_manager
        }

    except Exception as e:
        await audit_logger.log_application_initialization_error(
            environment=system_context.environment,
            error=str(e)
        )
        raise ApplicationInitializationError(f"Failed to initialize application: {e}")

# Example environment variable configuration (no real secrets)
# .env.example file (checked into version control)
"""
# Database Configuration
DATABASE_SECRET_NAME=database-credentials-${ENVIRONMENT}

# Analytics Configuration
ANALYTICS_SECRET_NAME=analytics-api-credentials-${ENVIRONMENT}

# Secrets Manager Configuration
SECRETS_PROVIDER=aws-secrets-manager
SECRETS_REGION=us-west-2

# Audit Configuration
AUDIT_LOG_LEVEL=info
AUDIT_CORRELATION_ENABLED=true

# Security Configuration
SECRET_DETECTION_ENABLED=true
ROTATION_MONITORING_ENABLED=true
"""
```

```javascript
// ❌ BAD: Client-side secrets exposure and suppression
const config = {
  // eslint-disable-next-line no-hardcoded-secrets -- "temporary" bypass
  apiKey: "pk_live_51234567890abcdef",  // Real Stripe key!
  // detect-secrets:disable-line
  databaseUrl: "mongodb://admin:prod_password@cluster.mongodb.net/prod",

  // Stored in localStorage - exposed to XSS attacks
  jwtSecret: localStorage.getItem('jwt_secret') || "fallback-secret-key"
};

function makeAPICall(data) {
  // Secret exposed in client-side code
  return fetch('/api/endpoint', {
    headers: {
      'Authorization': `Bearer ${config.apiKey}`,  // Secret in network logs
      'X-Database-Token': config.databaseUrl       // Credentials exposed
    },
    body: JSON.stringify(data)
  });
}
```

```javascript
// ✅ GOOD: Secure client-side configuration with server-side secrets management
class SecureAPIClient {
  constructor(config) {
    this.baseUrl = config.baseUrl;
    this.environment = config.environment;
    this.sessionManager = new SecureSessionManager(config);
    this.auditLogger = new ClientAuditLogger(config);
    this.credentialsCache = new Map();
  }

  async initialize(userContext) {
    /**
     * Initialize API client with secure session-based authentication
     * No secrets stored client-side
     */
    try {
      // Establish secure session with server
      const sessionResult = await this.sessionManager.establishSecureSession(userContext);

      if (!sessionResult.success) {
        throw new AuthenticationError('Failed to establish secure session');
      }

      // Get server-provided configuration (no secrets)
      const clientConfig = await this.getClientConfiguration();
      this.validateClientConfiguration(clientConfig);

      await this.auditLogger.logClientInitialization({
        environment: this.environment,
        userId: userContext.userId,
        sessionId: sessionResult.sessionId
      });

      return {
        sessionId: sessionResult.sessionId,
        configuration: clientConfig
      };

    } catch (error) {
      await this.auditLogger.logClientInitializationError({
        environment: this.environment,
        userId: userContext.userId,
        error: error.message
      });
      throw error;
    }
  }

  async makeSecureAPICall(endpoint, data, options = {}) {
    /**
     * Make API call using server-managed credentials
     * No client-side secret handling
     */
    const correlationId = this.generateCorrelationId();

    try {
      // Get current session token (no secrets, just session identifier)
      const sessionToken = await this.sessionManager.getValidSessionToken();
      if (!sessionToken) {
        throw new AuthenticationError('No valid session available');
      }

      // Prepare secure request headers
      const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Session ${sessionToken}`,  // Session token, not API secret
        'X-Correlation-ID': correlationId,
        'X-Client-Version': this.getClientVersion(),
        'X-Request-Timestamp': new Date().toISOString()
      };

      // Make request to backend (backend handles all secret management)
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: options.method || 'POST',
        headers: headers,
        body: JSON.stringify(data),
        credentials: 'same-origin',
        signal: AbortSignal.timeout(options.timeout || 30000)
      });

      await this.auditLogger.logAPIRequest({
        endpoint: endpoint,
        method: options.method || 'POST',
        statusCode: response.status,
        correlationId: correlationId
      });

      if (!response.ok) {
        if (response.status === 401) {
          await this.sessionManager.clearSession();
          throw new AuthenticationError('Session expired');
        }
        throw new APIError(`Request failed: ${response.status}`);
      }

      return await response.json();

    } catch (error) {
      await this.auditLogger.logAPIRequestError({
        endpoint: endpoint,
        error: error.message,
        correlationId: correlationId
      });
      throw error;
    }
  }

  async getClientConfiguration() {
    /**
     * Retrieve client configuration from server
     * Configuration contains no secrets, only public settings
     */
    const response = await fetch(`${this.baseUrl}/api/client/config`, {
      headers: {
        'Authorization': `Session ${await this.sessionManager.getValidSessionToken()}`,
        'X-Environment': this.environment
      }
    });

    if (!response.ok) {
      throw new ConfigurationError('Failed to retrieve client configuration');
    }

    return await response.json();
  }

  validateClientConfiguration(config) {
    /**
     * Validate that client configuration contains no secrets
     */
    const suspiciousPatterns = [
      /api[_-]?key/i,
      /secret/i,
      /password/i,
      /token/i,
      /credential/i,
      /auth[_-]?key/i
    ];

    const configString = JSON.stringify(config);

    for (const pattern of suspiciousPatterns) {
      if (pattern.test(configString)) {
        // Log potential security issue but don't expose the content
        this.auditLogger.logSecurityWarning({
          type: 'potential_secret_in_client_config',
          pattern: pattern.source
        });

        // In development, throw error to catch misconfigurations
        if (this.environment === 'development') {
          throw new SecurityError(
            `Client configuration contains potential secrets matching pattern: ${pattern.source}`
          );
        }
      }
    }
  }
}

// Secure backend API that manages all secrets
class SecureBackendAPIHandler {
  constructor(secretsManager, auditLogger) {
    this.secretsManager = secretsManager;
    this.auditLogger = auditLogger;
    this.credentialsCache = new TTLCache({ maxAge: 300000 }); // 5 minute cache
  }

  async handleThirdPartyAPICall(request, userContext) {
    /**
     * Handle third-party API calls using server-managed secrets
     * Clients never see or handle actual API credentials
     */
    const correlationId = request.headers['x-correlation-id'];

    try {
      // Validate user session and permissions
      await this.validateUserSession(userContext, request.endpoint);

      // Retrieve API credentials from secrets manager
      const apiCredentials = await this.getAPICredentials(
        request.serviceProvider,
        userContext
      );

      // Make third-party API call with actual credentials
      const thirdPartyResponse = await this.callThirdPartyAPI(
        request.endpoint,
        request.data,
        apiCredentials,
        correlationId
      );

      // Return sanitized response (no credential information)
      const sanitizedResponse = this.sanitizeResponse(thirdPartyResponse);

      await this.auditLogger.logThirdPartyAPICall({
        serviceProvider: request.serviceProvider,
        endpoint: request.endpoint,
        userId: userContext.userId,
        statusCode: thirdPartyResponse.status,
        correlationId: correlationId
      });

      return sanitizedResponse;

    } catch (error) {
      await this.auditLogger.logThirdPartyAPIError({
        serviceProvider: request.serviceProvider,
        endpoint: request.endpoint,
        userId: userContext.userId,
        error: error.message,
        correlationId: correlationId
      });
      throw error;
    }
  }

  async getAPICredentials(serviceProvider, userContext) {
    /**
     * Retrieve API credentials for service provider using secrets manager
     */
    const cacheKey = `${serviceProvider}-${userContext.environment}`;

    // Check cache first
    let credentials = this.credentialsCache.get(cacheKey);
    if (credentials) {
      return credentials;
    }

    // Retrieve from secrets manager
    const secretName = `${serviceProvider}-api-credentials-${userContext.environment}`;
    const secretValue = await this.secretsManager.retrieveSecret(
      secretName,
      userContext
    );

    credentials = JSON.parse(secretValue.value);

    // Validate credentials are not placeholders
    this.validateCredentialsNotPlaceholder(credentials, secretName);

    // Cache credentials for short period
    this.credentialsCache.set(cacheKey, credentials);

    return credentials;
  }

  validateCredentialsNotPlaceholder(credentials, secretName) {
    /**
     * Validate that retrieved credentials are not placeholder values
     */
    const placeholderPatterns = [
      'your-api-key-here',
      'example-key',
      'test-key',
      'placeholder',
      'sample-',
      'demo-',
      'xxx-'
    ];

    const credentialString = JSON.stringify(credentials).toLowerCase();

    for (const pattern of placeholderPatterns) {
      if (credentialString.includes(pattern)) {
        throw new InvalidCredentialsError(
          `Secret ${secretName} contains placeholder value: ${pattern}`
        );
      }
    }
  }

  async callThirdPartyAPI(endpoint, data, credentials, correlationId) {
    /**
     * Make actual third-party API call using secure credentials
     */
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': this.buildAuthorizationHeader(credentials),
      'X-Correlation-ID': correlationId,
      'User-Agent': `SecureApp/1.0 (${process.env.ENVIRONMENT})`
    };

    // Add service-specific headers
    if (credentials.additionalHeaders) {
      Object.assign(headers, credentials.additionalHeaders);
    }

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(data),
      timeout: 30000
    });

    return response;
  }

  sanitizeResponse(response) {
    /**
     * Remove any credential information from third-party API responses
     */
    const responseData = response.data;

    // Remove common credential fields that might be echoed back
    const credentialFields = [
      'api_key', 'apiKey', 'api-key',
      'secret', 'token', 'password',
      'credential', 'auth_key', 'authKey'
    ];

    const sanitizedData = this.deepRemoveFields(responseData, credentialFields);

    return {
      status: response.status,
      data: sanitizedData,
      headers: this.sanitizeHeaders(response.headers)
    };
  }
}

// Environment configuration (no secrets in environment variables)
const environment = {
  API_BASE_URL: process.env.API_BASE_URL || 'https://api.yourservice.com',
  ENVIRONMENT: process.env.ENVIRONMENT || 'development',

  // Secrets manager configuration (no actual secrets)
  SECRETS_PROVIDER: process.env.SECRETS_PROVIDER || 'aws-secrets-manager',
  SECRETS_REGION: process.env.SECRETS_REGION || 'us-west-2',

  // Security configuration
  SESSION_TIMEOUT_MINUTES: parseInt(process.env.SESSION_TIMEOUT_MINUTES || '30'),
  AUDIT_LOGGING_ENABLED: process.env.AUDIT_LOGGING_ENABLED === 'true',
  SECRET_DETECTION_ENABLED: process.env.SECRET_DETECTION_ENABLED !== 'false'
};
```

## Related Bindings

- [no-secret-suppression](../../docs/tenets/no-secret-suppression.md): Secrets management practices directly implement no-secret-suppression by requiring that all secret detection warnings and security controls be addressed rather than bypassed or ignored. Both approaches ensure that security safeguards remain effective and are never compromised through suppression or avoidance.

- [external-configuration](../../docs/bindings/core/external-configuration.md): Secrets management builds upon external configuration principles by ensuring that sensitive configuration is not only externalized but also properly secured, encrypted, and managed throughout its lifecycle. Both bindings work together to eliminate hardcoded values while adding security-specific protections for sensitive data.

- [secure-by-design-principles](../../docs/bindings/categories/security/secure-by-design-principles.md): Secrets management practices are a foundational component of secure-by-design architecture, providing the secure credential handling layer that enables all other security controls. Both bindings work together to create systems where security is built into the architecture from the beginning.

- [authentication-authorization-patterns](../../docs/bindings/categories/security/authentication-authorization-patterns.md): Authentication and authorization systems depend on secrets management practices for secure credential storage, rotation, and access control. Both bindings work together to create comprehensive identity and access management with proper credential lifecycle management.

- [comprehensive-security-automation](../../docs/bindings/core/comprehensive-security-automation.md): Secrets management practices are enforced through automated secret detection, scanning, and monitoring systems that continuously validate proper credential handling. Both bindings create systematic security validation that prevents credential exposure and ensures consistent application of security controls.

- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Secrets management operations require comprehensive structured logging to enable security monitoring, incident response, and compliance auditing while ensuring that actual secret values are never logged. Both bindings create systematic observability for security-critical operations with appropriate data protection.
