---
id: secure-by-design-principles
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: threat modeling process + security architecture review + design documentation requirements
---

# Binding: Integrate Security into Architecture from the Beginning

Build security considerations into your system architecture from the earliest design phases, making security assumptions, boundaries, and requirements explicitly visible rather than treating security as an add-on or afterthought. Every architectural decision must consider and document its security implications.

## Rationale

This binding directly implements our explicit-over-implicit tenet by requiring that security concerns be visible, documented, and intentional architectural decisions rather than hidden assumptions or bolt-on additions. When security is designed in from the beginning, its requirements, constraints, and trade-offs become explicit parts of your system's architecture that can be reasoned about, tested, and maintained over time.

Think of security-by-design like designing a house versus adding security features to an existing structure. When you design security into the foundation, walls, and layout from the beginning, you create inherent protection that's both stronger and more cost-effective than trying to retrofit security systems onto a house that wasn't designed with security in mind. Similarly, applications designed with security considerations from the start have more robust, maintainable, and comprehensible security postures than those where security is added later.

When security is an afterthought, it becomes implicit—hidden in implementation details, scattered across multiple layers, and dependent on developers remembering to apply security measures consistently. This creates cognitive debt where every developer must independently discover and understand the security requirements for each component they touch. Security-by-design makes these requirements explicit in the architecture, reducing the mental overhead and eliminating the guesswork about what security measures should be applied where.

## Rule Definition

Secure-by-design requires that security considerations be integrated into every phase of architectural decision-making through explicit documentation and systematic analysis:

**Architecture Phase Requirements:**
- **Threat Modeling**: Systematically identify potential threats, attack vectors, and security requirements before implementation begins
- **Security Boundaries**: Explicitly define trust boundaries, security zones, and data flow restrictions in your architecture diagrams
- **Authentication and Authorization Design**: Plan identity management, access control, and privilege separation as core architectural components
- **Data Protection Strategy**: Design encryption, secure storage, and data handling requirements into your data architecture
- **Security Monitoring**: Plan logging, alerting, and observability for security events as architectural requirements

**Design Documentation Standards:**
- Security assumptions must be explicitly documented for each component and service
- Threat models must be created and maintained for critical system flows
- Security boundaries and trust relationships must be visible in architecture diagrams
- Data classification and protection requirements must be specified in design documents
- Security testing and validation strategies must be planned during design

**Architectural Security Principles:**
- **Defense in Depth**: Design multiple, independent security layers rather than relying on single points of protection
- **Principle of Least Privilege**: Architecture should enforce minimal necessary access by default
- **Fail Secure**: Systems should fail into secure states when errors or attacks occur
- **Security by Default**: Default configurations and behaviors should be secure without additional configuration
- **Separation of Concerns**: Security responsibilities should be clearly separated and not mixed with business logic

## Practical Implementation

1. **Establish Threat Modeling Process**: Integrate systematic threat identification into your design workflow:

   Create a standardized process that identifies threats early and documents security requirements before implementation. Use structured methodologies like STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) to systematically analyze potential attack vectors for each component and data flow in your architecture.

   ```markdown
   # Example Threat Model Template

   ## System Overview
   - Component: User Authentication Service
   - Trust Boundaries: Internet → Load Balancer → Auth Service → Database

   ## Threat Analysis (STRIDE)
   - **Spoofing**: Attackers impersonating legitimate users
     - Mitigation: Multi-factor authentication, strong password policies
   - **Tampering**: Modification of authentication tokens
     - Mitigation: Cryptographic signatures, secure token storage
   - **Information Disclosure**: Exposure of user credentials
     - Mitigation: Encryption in transit and at rest, secure logging

   ## Security Requirements
   - All passwords must be hashed using bcrypt with minimum 12 rounds
   - Session tokens must expire within 24 hours
   - Failed login attempts must be rate-limited and logged
   ```

2. **Design Explicit Security Boundaries**: Make trust relationships and security zones visible in your architecture:

   Create clear documentation and diagrams that show where data crosses trust boundaries, what validation and authorization occurs at each boundary, and how different security zones communicate. This makes security assumptions explicit and prevents accidental violations of security policies.

   ```yaml
   # Example Security Zone Definition
   security_zones:
     public:
       description: "Internet-facing components"
       trust_level: "untrusted"
       allowed_protocols: ["HTTPS"]
       required_validation: ["input_sanitization", "rate_limiting"]

     application:
       description: "Business logic tier"
       trust_level: "semi-trusted"
       allowed_protocols: ["HTTPS", "gRPC-TLS"]
       required_validation: ["authentication", "authorization"]

     data:
       description: "Database and storage tier"
       trust_level: "trusted"
       allowed_protocols: ["TLS-encrypted database connections"]
       required_validation: ["parameterized_queries", "encryption_at_rest"]
   ```

3. **Implement Security-First Component Design**: Structure components with security as a primary architectural concern:

   Design each component with explicit security interfaces, clear security responsibilities, and built-in protection mechanisms. Security shouldn't be something you add to components—it should be how components are structured from the beginning.

   ```typescript
   // ✅ GOOD: Security-first component design
   interface SecureUserService {
     // Explicit security contract in interface
     createUser(data: ValidatedUserData, context: SecurityContext): Promise<User>;
     authenticateUser(credentials: SanitizedCredentials): Promise<AuthResult>;
     updateUser(id: UserId, data: ValidatedUserData, permissions: UserPermissions): Promise<User>;
   }

   class UserService implements SecureUserService {
     constructor(
       private validator: InputValidator,
       private hasher: PasswordHasher,
       private audit: AuditLogger,
       private permissions: PermissionManager
     ) {}

     async createUser(data: ValidatedUserData, context: SecurityContext): Promise<User> {
       // Security is explicitly part of the method signature and implementation
       this.audit.logUserCreation(context.requestId, context.userId);

       const hashedPassword = await this.hasher.hash(data.password);
       const user = await this.repository.create({
         ...data,
         password: hashedPassword,
         createdBy: context.userId
       });

       return this.sanitizeUserForResponse(user, context.permissions);
     }
   }
   ```

4. **Plan Security Testing and Validation**: Design security validation into your development and deployment processes:

   Security testing should be planned during architecture design, not discovered during implementation. Define what security tests will validate your threat model assumptions and how security validation will be integrated into your development workflow.

   ```yaml
   # Example Security Testing Plan
   security_testing:
     unit_tests:
       - input_validation: "Test all boundary validation logic"
       - authorization: "Test access control for each endpoint"
       - cryptography: "Test key generation and encryption/decryption"

     integration_tests:
       - authentication_flow: "Test complete login/logout cycles"
       - data_protection: "Test encryption across service boundaries"
       - audit_logging: "Test security event capture and storage"

     security_scans:
       - static_analysis: "SAST tools (semgrep, codeql) in CI pipeline"
       - dependency_scanning: "Check for vulnerable dependencies"
       - infrastructure_scanning: "Scan deployment configurations"

     penetration_testing:
       - scope: "External-facing components and APIs"
       - frequency: "Quarterly for critical systems"
       - focus_areas: ["authentication", "authorization", "input_validation"]
   ```

5. **Document Security Architecture Decisions**: Create explicit records of security choices and their rationale:

   Maintain architecture decision records (ADRs) that document security choices, trade-offs, and the reasoning behind security architectural decisions. This creates explicit knowledge that helps future developers understand and maintain security requirements.

   ```markdown
   # Architecture Decision Record: User Session Management

   ## Decision
   Use JWT tokens with short expiration (15 minutes) and refresh token rotation.

   ## Security Rationale
   - **Threat Addressed**: Token theft and replay attacks
   - **Trade-offs**: Increased complexity vs. reduced blast radius of token compromise
   - **Alternatives Considered**: Long-lived sessions (rejected: too risky),
     session store (rejected: adds infrastructure complexity)

   ## Implementation Requirements
   - JWT must be signed with RS256 algorithm
   - Refresh tokens must be stored securely and rotated on each use
   - Both token types must include proper audience and issuer claims

   ## Security Validation
   - Unit tests must verify token validation logic
   - Integration tests must verify token refresh flow
   - Security scans must check for hardcoded secrets in JWT implementation
   ```

## Examples

```python
# ❌ BAD: Security as an afterthought
class UserAPI:
    def create_user(self, user_data):
        # No input validation
        # No authentication check
        # No authorization check
        # No audit logging
        user = User(**user_data)
        return self.db.save(user)

    def get_user(self, user_id):
        # Anyone can access any user's data
        return self.db.get_user(user_id)

    def update_user(self, user_id, update_data):
        # No validation of what fields can be updated
        # No check if user can update this record
        return self.db.update_user(user_id, update_data)
```

```python
# ✅ GOOD: Security-by-design architecture
class SecureUserAPI:
    def __init__(self, validator, auth_service, permission_service, audit_logger):
        self.validator = validator
        self.auth_service = auth_service
        self.permission_service = permission_service
        self.audit_logger = audit_logger

    @require_authentication
    @validate_input(CreateUserSchema)
    @require_permission("user:create")
    def create_user(self, user_data: ValidatedUserData, context: SecurityContext):
        """Create a new user with full security validation."""
        # Security explicitly designed into the method flow
        self.audit_logger.log_user_creation(context.user_id, user_data.email)

        # Hash password using secure algorithm
        hashed_password = self.hash_password(user_data.password)

        user = User(
            email=user_data.email,
            password_hash=hashed_password,
            created_by=context.user_id,
            created_at=datetime.utcnow()
        )

        return self.db.save(user)

    @require_authentication
    @require_permission("user:read")
    def get_user(self, user_id: str, context: SecurityContext):
        """Get user data with proper authorization checks."""
        # Explicit permission check for data access
        if not self.permission_service.can_access_user(context.user_id, user_id):
            raise UnauthorizedError("Cannot access user data")

        user = self.db.get_user(user_id)

        # Return sanitized data based on user's permissions
        return self.sanitize_user_data(user, context.permissions)

    @require_authentication
    @validate_input(UpdateUserSchema)
    @require_permission("user:update")
    def update_user(self, user_id: str, update_data: ValidatedUpdateData, context: SecurityContext):
        """Update user with field-level security controls."""
        # Verify user can update this specific record
        if not self.permission_service.can_modify_user(context.user_id, user_id):
            raise UnauthorizedError("Cannot modify user")

        # Validate which fields this user can actually update
        allowed_fields = self.permission_service.get_updatable_fields(context.user_id, user_id)
        filtered_data = {k: v for k, v in update_data.items() if k in allowed_fields}

        self.audit_logger.log_user_update(context.user_id, user_id, filtered_data.keys())

        return self.db.update_user(user_id, filtered_data)
```

```go
// ❌ BAD: Implicit security assumptions
func (s *PaymentService) ProcessPayment(amount float64, cardNumber string) error {
    // Assumes card number is already validated (implicit)
    // No explicit fraud checks
    // No audit trail
    // No rate limiting
    payment := &Payment{
        Amount:     amount,
        CardNumber: cardNumber,
        Status:     "processed",
    }
    return s.db.Save(payment)
}
```

```go
// ✅ GOOD: Explicit security-by-design
type PaymentService struct {
    validator      InputValidator
    fraudDetector  FraudDetector
    encryptor      PaymentEncryptor
    auditLogger    AuditLogger
    rateLimiter    RateLimiter
}

func (s *PaymentService) ProcessPayment(
    ctx context.Context,
    request ValidatedPaymentRequest,
    securityContext SecurityContext,
) (*PaymentResult, error) {
    // Explicit security steps built into the method design

    // 1. Rate limiting to prevent abuse
    if !s.rateLimiter.Allow(securityContext.UserID) {
        s.auditLogger.LogRateLimitExceeded(securityContext)
        return nil, ErrRateLimitExceeded
    }

    // 2. Explicit fraud detection
    fraudScore, err := s.fraudDetector.AnalyzeTransaction(request, securityContext)
    if err != nil {
        return nil, fmt.Errorf("fraud analysis failed: %w", err)
    }

    if fraudScore > AcceptableRiskThreshold {
        s.auditLogger.LogSuspiciousTransaction(securityContext, fraudScore)
        return nil, ErrTransactionSuspicious
    }

    // 3. Explicit data protection
    encryptedCard, err := s.encryptor.EncryptCardData(request.CardNumber)
    if err != nil {
        return nil, fmt.Errorf("card encryption failed: %w", err)
    }

    // 4. Explicit audit trail
    s.auditLogger.LogPaymentAttempt(securityContext, request.Amount)

    payment := &Payment{
        ID:               generateSecureID(),
        Amount:          request.Amount,
        EncryptedCard:   encryptedCard,
        UserID:         securityContext.UserID,
        FraudScore:     fraudScore,
        Status:         "processing",
        CreatedAt:      time.Now().UTC(),
    }

    if err := s.db.Save(payment); err != nil {
        s.auditLogger.LogPaymentFailure(securityContext, err)
        return nil, fmt.Errorf("payment storage failed: %w", err)
    }

    s.auditLogger.LogPaymentSuccess(securityContext, payment.ID)

    return &PaymentResult{
        PaymentID: payment.ID,
        Status:    payment.Status,
    }, nil
}
```

## Related Bindings

- [explicit-over-implicit](../../docs/tenets/explicit-over-implicit.md): Secure-by-design directly implements explicitness by making security assumptions and requirements visible in architecture rather than hidden in implementation details. Both approaches reduce cognitive debt and make system behavior predictable.

- [fail-fast-validation](../../docs/bindings/core/fail-fast-validation.md): Input validation is a foundational component of secure-by-design architecture. Both bindings work together to create systems that explicitly validate assumptions at boundaries and fail securely when invalid conditions are detected.

- [external-configuration](../../docs/bindings/core/external-configuration.md): Secure architecture requires externalized security configuration for different environments and threat models. Both bindings support explicit, environment-specific security controls that can be validated and audited independently of application code.

- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Security monitoring and incident response require structured logging to enable automated threat detection and forensic analysis. Both bindings create comprehensive observability that supports both security operations and system debugging.

- [comprehensive-security-automation](../../docs/bindings/core/comprehensive-security-automation.md): Automated security validation ensures that secure-by-design principles are consistently enforced throughout the development and deployment pipeline. Both bindings create systematic security approaches that reduce human error and ensure consistent application of security controls.
