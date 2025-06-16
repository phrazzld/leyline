---
id: secrets-management-practices
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: no-secret-suppression
enforced_by: secret detection tools (trufflehog, detect-secrets, gitleaks) + pre-commit hooks + automated scanning + security code review
---

# Binding: Implement Comprehensive Secrets Management Practices

Establish secure handling of credentials, API keys, and sensitive configuration throughout development and deployment. Never suppress secret detection mechanisms, ensuring proper management, rotation, and monitoring of all sensitive data.

## Rationale

This binding implements no-secret-suppression by preventing hardcoding or improper handling of secrets. It builds upon external-configuration principles by ensuring sensitive data is externalized, secured, and managed throughout its lifecycle.

Secrets management works like a secure vault with multiple protection layers: access controls, audit logging, and time-limited access. Applications must never store secrets in source code or suppress detection mechanisms.

Poor secrets management creates systemic vulnerabilities that compound over time. Each suppressed warning potentially represents a credential compromise leading to data breaches.

## Rule Definition

Secrets management must implement comprehensive protection with zero tolerance for suppression:

**Secrets Classification:**
- High Sensitivity: Production passwords, encryption keys, write-access API keys
- Medium Sensitivity: Development credentials, read-only API keys
- Low Sensitivity: Public endpoints, non-sensitive configuration

**Zero Suppression Policy:**
- Never suppress or bypass secret detection tools
- All detections must be investigated and remediated
- Address detection immediately, never defer
- Resolve through proper configuration, not suppression

**Lifecycle Management:**
- Use dedicated secrets management systems (Vault, AWS Secrets Manager)
- Implement environment-specific isolation
- Enforce role-based access with least privilege
- Log all secret access and modifications
- Implement automated rotation with verification
- Set explicit expiration dates with alerts

## Practical Implementation

1. **Establish Secret Detection Pipeline**: Implement multi-layered detection:

   ```yaml
   # .pre-commit-config.yaml
   repos:
     - repo: https://github.com/trufflesecurity/trufflehog
       rev: v3.67.7
       hooks:
         - id: trufflehog
           args: ['--only-verified', '--fail']
     - repo: https://github.com/Yelp/detect-secrets
       rev: v1.4.0
       hooks:
         - id: detect-secrets
           args: ['--baseline', '.secrets.baseline']
   ```

2. **Implement Secure Secrets Management**: Create infrastructure that handles the credential lifecycle:

   ```typescript
   interface SecretMetadata {
     id: string;
     name: string;
     sensitivity: 'high' | 'medium' | 'low';
     environment: string;
     createdAt: Date;
     expiresAt: Date;
     rotationPeriod: number;
   }

   class SecureSecretsManager {
     private secretsProvider: SecretsProvider;
     private auditLogger: SecurityAuditLogger;
     private accessControl: AccessControlService;

     async storeSecret(name: string, value: string, metadata: Partial<SecretMetadata>): Promise<SecretMetadata> {
       // Validate secret value
       this.validateSecretValue(value, name);

       // Check permissions
       await this.accessControl.canStoreSecret(name);

       // Store with metadata
       const completeMetadata = {
         ...metadata,
         id: generateId(),
         createdAt: new Date(),
         expiresAt: this.calculateExpiration(metadata.sensitivity)
       };

       await this.secretsProvider.store(name, value, completeMetadata);
       await this.auditLogger.logSecretCreated(completeMetadata);

       return completeMetadata;
     }

     async retrieveSecret(name: string): Promise<string> {
       await this.accessControl.canRetrieveSecret(name);

       const metadata = await this.secretsProvider.getMetadata(name);
       if (metadata.expiresAt < new Date()) {
         throw new ExpiredSecretError(`Secret ${name} has expired`);
       }

       const value = await this.secretsProvider.retrieve(name);
       await this.auditLogger.logSecretAccessed(name);

       return value;
     }

     private validateSecretValue(value: string, name: string): void {
       const problematicPatterns = [
         /^(test|demo|example|placeholder)/i,
         /^(password|secret|key)$/i,
         /^.{1,7}$/  // Too short
       ];

       for (const pattern of problematicPatterns) {
         if (pattern.test(value)) {
           throw new InvalidSecretError(`Invalid secret value for ${name}`);
         }
       }
     }
   }
   ```

3. **Create Secrets Monitoring System**: Implement validation and monitoring:

   ```typescript
   class SecretsMonitoringService {
     private auditLogger: SecurityAuditLogger;
     private alertManager: SecurityAlertManager;

     async monitorSecretUsage(event: SecretUsageEvent): Promise<void> {
       // Record usage event
       await this.auditLogger.logSecretAccess(event);

       // Check for immediate threats
       if (await this.isSuspiciousAccess(event)) {
         await this.alertManager.triggerAlert({
           severity: 'high',
           message: `Suspicious secret access: ${event.secretName}`,
           details: event
         });
       }

       // Check for anomalies
       const anomalies = await this.detectAnomalies(event);
       for (const anomaly of anomalies) {
         await this.alertManager.triggerAlert(anomaly);
       }
     }

     async validateCompliance(environment: string): Promise<ComplianceReport> {
       const secrets = await this.secretsProvider.listSecrets(environment);
       const violations = [];

       for (const secret of secrets) {
         if (this.isRotationOverdue(secret)) {
           violations.push({
             type: 'rotation_overdue',
             secretName: secret.name,
             severity: 'high'
           });
         }
       }

       return {
         environment,
         totalSecrets: secrets.length,
         violations,
         compliancePercentage: this.calculateCompliance(violations, secrets.length)
       };
     }
   }
   ```

4. **Implement Secrets Testing**: Create validation strategies without exposing real credentials:

   ```typescript
   describe('SecretsManager', () => {
     let secretsManager: SecretsManager;
     let mockProvider: MockSecretsProvider;

     beforeEach(() => {
       mockProvider = new MockSecretsProvider();
       secretsManager = new SecretsManager(mockProvider);
     });

     test('should store valid secret successfully', async () => {
       const testSecret = generateTestSecret();
       const metadata = {
         sensitivity: 'medium' as const,
         environment: 'test'
       };

       const result = await secretsManager.storeSecret('test-api-key', testSecret, metadata);

       expect(result.name).toBe('test-api-key');
       expect(result.sensitivity).toBe('medium');
     });

     test('should reject placeholder secrets', async () => {
       const placeholders = ['test-key', 'placeholder', 'example-secret'];

       for (const placeholder of placeholders) {
         await expect(
           secretsManager.storeSecret('test', placeholder, { sensitivity: 'medium' })
         ).rejects.toThrow('Invalid secret value');
       }
     });

     test('should enforce access control', async () => {
       mockProvider.shouldRejectAccess = true;

       await expect(
         secretsManager.retrieveSecret('restricted-secret')
       ).rejects.toThrow('Insufficient permissions');
     });
   });
   ```

## Examples

```python
# ❌ BAD: Hardcoded secrets with suppressed detection
# GitLeaks:ignore - "temporary" suppression that becomes permanent
API_KEY = "sk-1a2b3c4d5e6f7g8h9i0j"  # Real API key hardcoded!
DATABASE_URL = "postgresql://admin:password@db.production.com:5432/app"
```

```typescript
// ✅ GOOD: Secure secrets management with proper externalization
class SecureConfigurationManager {
  private secretsManager: SecretsManager;
  private auditLogger: SecurityAuditLogger;

  async getDatabaseConfig(): Promise<DatabaseConfig> {
    try {
      const dbSecret = await this.secretsManager.retrieveSecret(
        `database-credentials-${this.environment}`
      );
      const config = JSON.parse(dbSecret);
      return {
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password, // Retrieved securely, not hardcoded
        ssl: 'require'
      };
    } catch (error) {
      await this.auditLogger.logError('database_config_retrieval', error);
      throw new ConfigurationError('Failed to retrieve database configuration');
    }
  }

  private validateCredentials(credentials: any, secretName: string): void {
    const placeholders = ['test-key', 'example', 'placeholder', 'demo'];
    for (const placeholder of placeholders) {
      if (credentials.apiKey?.toLowerCase().includes(placeholder)) {
        throw new InvalidCredentialsError(
          `Secret ${secretName} contains placeholder: ${placeholder}`
        );
      }
    }
  }
}
```

## Related Bindings

- [no-secret-suppression](../../tenets/no-secret-suppression.md): Secrets management directly implements no-secret-suppression by requiring all secret detection warnings be addressed rather than bypassed.

- [external-configuration](../core/external-configuration.md): Secrets management builds upon external configuration by ensuring sensitive data is not only externalized but properly secured and managed.

- [secure-by-design-principles](./secure-by-design-principles.md): Secrets management provides the secure credential handling foundation that enables other security controls.

- [comprehensive-security-automation](../core/comprehensive-security-automation.md): Secrets management practices are enforced through automated detection, scanning, and monitoring systems.

- [use-structured-logging](../core/use-structured-logging.md): Secrets operations require comprehensive logging while ensuring actual secret values are never logged.
