---
id: secrets-management-practices
last_modified: '2025-06-11'
version: '0.2.0'
derived_from: no-secret-suppression
enforced_by: secret detection tools (trufflehog, detect-secrets, gitleaks) + pre-commit hooks + automated scanning + security code review
---

# Binding: Implement Comprehensive Secrets Management Practices

Establish secure handling of credentials, API keys, and sensitive configuration throughout development and deployment. Never suppress secret detection mechanisms.

## Rationale

This binding implements no-secret-suppression by preventing hardcoding or improper handling of secrets. It builds upon external-configuration principles by ensuring sensitive data is externalized, secured, and managed throughout its lifecycle.

## Rule Definition

**Secrets Classification:**
- High Sensitivity: Production passwords, encryption keys, write-access API keys
- Medium Sensitivity: Development credentials, read-only API keys
- Low Sensitivity: Public endpoints, non-sensitive configuration

**Zero Suppression Policy:**
- Never suppress or bypass secret detection tools
- All detections must be investigated and remediated immediately
- Resolve through proper configuration, not suppression

**Lifecycle Management:**
- Use dedicated secrets management systems (Vault, AWS Secrets Manager)
- Implement environment-specific isolation with role-based access
- Log all secret access and modifications
- Implement automated rotation with explicit expiration dates

## Practical Implementation

**1. Secret Detection Pipeline:**

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

**2. Secure Secrets Management:**

```typescript
interface SecretMetadata {
  id: string;
  name: string;
  sensitivity: 'high' | 'medium' | 'low';
  environment: string;
  expiresAt: Date;
}

class SecureSecretsManager {
  async storeSecret(name: string, value: string, metadata: Partial<SecretMetadata>): Promise<SecretMetadata> {
    this.validateSecretValue(value, name);
    await this.accessControl.canStoreSecret(name);

    const completeMetadata = {
      ...metadata,
      id: generateId(),
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
    const problematicPatterns = [/^(test|demo|example|placeholder)/i, /^.{1,7}$/];
    for (const pattern of problematicPatterns) {
      if (pattern.test(value)) {
        throw new InvalidSecretError(`Invalid secret value for ${name}`);
      }
    }
  }
}
```

**3. Secrets Monitoring:**

```typescript
class SecretsMonitoringService {
  async monitorSecretUsage(event: SecretUsageEvent): Promise<void> {
    await this.auditLogger.logSecretAccess(event);

    if (await this.isSuspiciousAccess(event)) {
      await this.alertManager.triggerAlert({
        severity: 'high',
        message: `Suspicious secret access: ${event.secretName}`
      });
    }
  }

  async validateCompliance(environment: string): Promise<ComplianceReport> {
    const secrets = await this.secretsProvider.listSecrets(environment);
    const violations = secrets.filter(s => this.isRotationOverdue(s)).map(s => ({
      type: 'rotation_overdue',
      secretName: s.name,
      severity: 'high'
    }));

    return {
      environment,
      totalSecrets: secrets.length,
      violations,
      compliancePercentage: this.calculateCompliance(violations, secrets.length)
    };
  }
}
```

## Documentation Security Patterns

**Secure Example Patterns:**
- Use explicit redaction markers: `[REDACTED]`, `[EXAMPLE]`, `[PLACEHOLDER]`
- Avoid realistic-looking secrets that trigger detection tools

```typescript
// ✅ GOOD: Secure documentation examples
const config = {
  apiKey: process.env.API_KEY,           // Retrieved from environment
  endpoint: 'https://api.example.com'    // Public endpoint
};

// ✅ GOOD: Clear redaction in examples
const apiConfig = {
  apiKey: 'sk_live_[REDACTED]',          // Use explicit redaction markers
  webhookSecret: 'whsec_[EXAMPLE]',      // Clear example indicator
  token: '[YOUR_API_TOKEN_HERE]'         // Template-style placeholder
};
```

## Examples

```python
# ❌ BAD: Hardcoded secrets with suppressed detection
# GitLeaks:ignore - "temporary" suppression that becomes permanent
API_KEY = "sk-[REDACTED]"  # Never hardcode real API keys!
DATABASE_URL = "postgresql://admin:[PASSWORD]@db.production.com:5432/app"
```

```typescript
// ✅ GOOD: Secure secrets management with proper externalization
class SecureConfigurationManager {
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
}
```

## Related Bindings

- [no-secret-suppression](../../tenets/no-secret-suppression.md): Requires all secret detection warnings be addressed rather than bypassed
- [external-configuration](../../core/external-configuration.md): Ensures sensitive data is externalized and properly secured
- [secure-by-design-principles](secure-by-design-principles.md): Provides secure credential handling foundation
- [comprehensive-security-automation](../../core/comprehensive-security-automation.md): Enforces practices through automated detection and monitoring
- [use-structured-logging](../../core/use-structured-logging.md): Requires comprehensive logging while protecting secret values
