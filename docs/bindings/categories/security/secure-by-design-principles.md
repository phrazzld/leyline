---
id: secure-by-design-principles
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: threat modeling process + security architecture review + design documentation requirements
---

# Binding: Integrate Security into Architecture from the Beginning

Build security into system architecture from the earliest design phases, making security assumptions, boundaries, and requirements explicitly visible rather than treating security as an afterthought.

## Rationale

Implements explicit-over-implicit by requiring security concerns be visible, documented architectural decisions rather than hidden assumptions. Security-by-design creates inherent protection that's stronger and more maintainable than retrofitted security. When security is implicit, it creates cognitive debt where developers must independently discover security requirements for each component.

## Rule Definition

**Architecture Requirements:**
- **Threat Modeling**: Systematically identify threats, attack vectors, and security requirements before implementation
- **Security Boundaries**: Define trust boundaries, security zones, and data flow restrictions in architecture diagrams
- **Authentication/Authorization**: Plan identity management and access control as core architectural components
- **Data Protection**: Design encryption, secure storage, and data handling into architecture
- **Security Monitoring**: Plan logging, alerting, and observability for security events

**Documentation Standards:**
- Document security assumptions for each component
- Create and maintain threat models for critical flows
- Make security boundaries visible in architecture diagrams
- Specify data classification and protection requirements
- Plan security testing during design

**Core Principles:**
- **Defense in Depth**: Multiple independent security layers
- **Least Privilege**: Minimal necessary access by default
- **Fail Secure**: Secure failure states
- **Security by Default**: Secure default configurations
- **Separation of Concerns**: Clear security responsibility boundaries

## Practical Implementation

1. **Threat Modeling Process**: Use STRIDE methodology to identify threats early:

   ```markdown
   # Threat Model: User Authentication Service
   ## Trust Boundaries: Internet → Load Balancer → Auth Service → Database
   ## STRIDE Analysis
   - **Spoofing**: MFA, strong password policies
   - **Tampering**: Cryptographic signatures, secure storage
   - **Information Disclosure**: Encryption in transit/rest, secure logging
   ## Requirements
   - bcrypt hashing (12+ rounds), 24h token expiry, rate limiting
   ```

2. **Security Boundaries**: Define explicit trust zones and validation requirements:

   ```yaml
   security_zones:
     public:
       trust_level: "untrusted"
       protocols: ["HTTPS"]
       validation: ["input_sanitization", "rate_limiting"]
     application:
       trust_level: "semi-trusted"
       protocols: ["HTTPS", "gRPC-TLS"]
       validation: ["authentication", "authorization"]
   ```

3. **Security-First Components**: Design interfaces with explicit security contracts:

   ```typescript
   interface SecureUserService {
     createUser(data: ValidatedUserData, context: SecurityContext): Promise<User>;
     authenticateUser(credentials: SanitizedCredentials): Promise<AuthResult>;
   }

   class UserService implements SecureUserService {
     constructor(
       private validator: InputValidator,
       private audit: AuditLogger,
       private permissions: PermissionManager
     ) {}

     async createUser(data: ValidatedUserData, context: SecurityContext): Promise<User> {
       this.audit.logUserCreation(context.requestId, context.userId);
       const hashedPassword = await this.hasher.hash(data.password);
       return this.sanitizeUserForResponse(user, context.permissions);
     }
   }
   ```

4. **Security Testing Strategy**: Integrate security validation into development:

   ```yaml
   security_testing:
     unit_tests: ["input_validation", "authorization", "cryptography"]
     integration_tests: ["authentication_flow", "data_protection", "audit_logging"]
     security_scans: ["static_analysis", "dependency_scanning", "infrastructure"]
     penetration_testing: "Quarterly for critical systems"
   ```

5. **Document Security Decisions**: Maintain ADRs for security choices:

   ```markdown
   # ADR: JWT Session Management
   ## Decision: JWT tokens (15min expiry) + refresh token rotation
   ## Rationale: Reduces blast radius of token compromise
   ## Requirements: RS256 signatures, secure refresh storage, proper claims
   ```

## Examples

```python
# ❌ BAD: Security as afterthought
class UserAPI:
    def create_user(self, user_data):
        user = User(**user_data)  # No validation, auth, or audit
        return self.db.save(user)

    def get_user(self, user_id):
        return self.db.get_user(user_id)  # Anyone can access any data

# ✅ GOOD: Security-by-design
class SecureUserAPI:
    def __init__(self, validator, auth_service, permission_service, audit_logger):
        self.validator = validator
        self.permission_service = permission_service
        self.audit_logger = audit_logger

    @require_authentication
    @validate_input(CreateUserSchema)
    @require_permission("user:create")
    def create_user(self, user_data: ValidatedUserData, context: SecurityContext):
        self.audit_logger.log_user_creation(context.user_id, user_data.email)
        hashed_password = self.hash_password(user_data.password)

        user = User(
            email=user_data.email,
            password_hash=hashed_password,
            created_by=context.user_id
        )
        return self.db.save(user)

    @require_authentication
    @require_permission("user:read")
    def get_user(self, user_id: str, context: SecurityContext):
        if not self.permission_service.can_access_user(context.user_id, user_id):
            raise UnauthorizedError("Cannot access user data")

        user = self.db.get_user(user_id)
        return self.sanitize_user_data(user, context.permissions)
```
## Related Bindings

- [explicit-over-implicit](../../docs/tenets/explicit-over-implicit.md): Makes security assumptions visible in architecture rather than hidden in implementation
- [fail-fast-validation](../../docs/bindings/core/fail-fast-validation.md): Input validation as foundational component of secure architecture
- [external-configuration](../../docs/bindings/core/external-configuration.md): Externalized security configuration for different threat models
- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Structured logging for security monitoring and incident response
- [comprehensive-security-automation](../../docs/bindings/core/comprehensive-security-automation.md): Automated enforcement of secure-by-design principles
