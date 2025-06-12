---
id: authentication-authorization-patterns
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: authentication audit tools + access control testing + security code review + compliance checks
---

# Binding: Implement Explicit Authentication and Authorization Patterns

Establish clear, explicit identity verification and access control mechanisms that make authentication and authorization decisions visible, auditable, and enforceable. Never suppress or bypass security controls without proper documentation and approval, ensuring all security decisions are transparent and can be systematically validated.

## Rationale

This binding directly implements our explicit-over-implicit tenet by requiring that all authentication and authorization decisions be visible, documented, and intentional rather than hidden behind implicit assumptions or default behaviors. Additionally, it embodies our no-secret-suppression tenet by preventing the bypass or suppression of security controls without proper justification and documentation.

Think of authentication and authorization like a secure building's access control system that has explicit badges, clear entry points, and visible security checkpoints rather than relying on informal recognition or assumptions about who belongs where. Just as a well-designed building makes it obvious who has access to which areas and why, explicit authentication and authorization patterns make it clear who can access what resources under which circumstances, with all decisions being auditable and verifiable.

Implicit authentication patterns—such as assuming user context from global state, making authorization decisions based on hidden application logic, or bypassing security checks through backdoors—create significant security vulnerabilities and compliance risks. These hidden patterns make it impossible to audit access decisions, difficult to detect privilege escalation attacks, and nearly impossible to ensure consistent security policies across the application. When authentication and authorization logic is explicit, security teams can verify proper implementation, compliance auditors can trace access decisions, and developers can confidently make changes without inadvertently breaking security controls.

The no-secret-suppression aspect is equally critical: authentication and authorization systems must never allow bypassing security controls through hidden flags, secret parameters, or undocumented overrides. All exceptions to security policies must be explicit, documented, and subject to the same auditing processes as normal security decisions. This prevents the creation of security backdoors that could be exploited by attackers or misused by authorized users.

## Rule Definition

Authentication and authorization patterns must implement comprehensive identity and access control with full transparency and auditability:

**Authentication Requirements:**

**Identity Verification Standards:**
- **Multi-Factor Authentication**: Implement strong identity verification using multiple authentication factors (something you know, have, or are)
- **Session Management**: Establish secure session handling with explicit timeouts, invalidation, and lifecycle management
- **Credential Standards**: Enforce strong credential policies with proper hashing, storage, and rotation requirements
- **Authentication Context**: Maintain explicit context about authentication state, trust level, and verification methods used

**Authorization Requirements:**

**Access Control Implementation:**
- **Role-Based Access Control (RBAC)**: Define explicit roles and permissions with clear hierarchies and inheritance rules
- **Attribute-Based Access Control (ABAC)**: Implement context-aware access decisions based on user attributes, resource properties, and environmental factors
- **Least Privilege Principle**: Default to minimal access with explicit elevation for specific operations
- **Permission Boundaries**: Establish clear boundaries between different privilege levels and security domains

**Security Control Transparency:**

**Decision Auditability:**
- **Authentication Logging**: Log all authentication attempts, successes, failures, and context information
- **Authorization Tracing**: Record all access control decisions with user context, requested resources, and decision rationale
- **Security Event Monitoring**: Implement real-time monitoring of authentication and authorization patterns to detect anomalies
- **Compliance Reporting**: Generate audit trails that meet regulatory and organizational compliance requirements

**No Security Suppression:**
- **No Backdoors**: Prohibit any authentication or authorization bypass mechanisms not subject to the same auditing and control standards
- **Documented Exceptions**: Any security control exceptions must be explicitly documented, approved, and time-limited
- **Explicit Overrides**: Administrative overrides must be transparent, logged, and subject to additional verification requirements
- **Regular Access Review**: Implement systematic review processes to identify and remediate inappropriate access patterns

## Practical Implementation

1. **Establish Explicit Authentication Architecture**: Create clear authentication flows that make identity verification requirements and processes visible:

   Design authentication systems where every verification step is explicit and auditable. This means avoiding implicit authentication based on IP addresses, browser fingerprints, or other ambient factors without explicit verification.

   ```typescript
   interface AuthenticationContext {
     userId: string;
     sessionId: string;
     authenticationFactors: AuthFactor[];
     authenticationTimestamp: Date;
     trustLevel: TrustLevel;
     sessionTimeout: Date;
     requiresReauth: boolean;
   }

   interface AuthFactor {
     type: 'password' | 'totp' | 'webauthn' | 'sms' | 'email';
     verifiedAt: Date;
     strength: 'weak' | 'medium' | 'strong';
     metadata: Record<string, any>;
   }

   class ExplicitAuthenticationService {
     async authenticateUser(credentials: AuthCredentials, context: SecurityContext): Promise<AuthenticationResult> {
       // 1. Explicit credential validation with full audit trail
       const validationResult = await this.validateCredentials(credentials, context);
       if (!validationResult.isValid) {
         await this.auditService.logAuthenticationFailure(
           credentials.username,
           context.ipAddress,
           context.userAgent,
           validationResult.failureReason
         );
         throw new AuthenticationError(validationResult.failureReason);
       }

       // 2. Explicit multi-factor authentication requirement
       const mfaResult = await this.requireMultiFactorAuth(credentials.username, context);
       if (!mfaResult.completed) {
         return {
           status: 'mfa_required',
           challenge: mfaResult.challenge,
           sessionToken: mfaResult.temporaryToken
         };
       }

       // 3. Create explicit authentication context
       const authContext: AuthenticationContext = {
         userId: validationResult.userId,
         sessionId: this.generateSecureSessionId(),
         authenticationFactors: [
           { type: 'password', verifiedAt: new Date(), strength: 'medium', metadata: {} },
           { type: mfaResult.factorType, verifiedAt: new Date(), strength: 'strong', metadata: mfaResult.metadata }
         ],
         authenticationTimestamp: new Date(),
         trustLevel: this.calculateTrustLevel(validationResult, mfaResult, context),
         sessionTimeout: this.calculateSessionTimeout(context),
         requiresReauth: false
       };

       // 4. Establish secure session with explicit expiration
       await this.sessionService.createSession(authContext, context);

       // 5. Audit successful authentication with full context
       await this.auditService.logAuthenticationSuccess(authContext, context);

       return {
         status: 'authenticated',
         authContext: authContext,
         sessionToken: this.createSessionToken(authContext)
       };
     }

     async requireReauthentication(authContext: AuthenticationContext, reason: string): Promise<void> {
       // Explicit re-authentication requirement - no bypassing
       authContext.requiresReauth = true;
       await this.auditService.logReauthenticationRequired(authContext, reason);
       await this.sessionService.markSessionForReauth(authContext.sessionId);
     }
   }
   ```

2. **Implement Explicit Authorization Controls**: Create authorization systems that make access control decisions transparent and auditable:

   Design authorization logic where every access decision is explicit, documented, and can be traced back to specific policies and user attributes. Avoid implicit authorization based on code location or environmental assumptions.

   ```python
   from dataclasses import dataclass
   from typing import Dict, List, Optional, Set
   from enum import Enum

   @dataclass
   class AuthorizationContext:
       user_id: str
       user_roles: Set[str]
       user_attributes: Dict[str, any]
       resource_id: str
       resource_type: str
       resource_attributes: Dict[str, any]
       operation: str
       environment_context: Dict[str, any]
       request_timestamp: datetime
       session_trust_level: str

   @dataclass
   class AuthorizationDecision:
       permitted: bool
       decision_reason: str
       applicable_policies: List[str]
       decision_timestamp: datetime
       requires_additional_auth: bool
       audit_context: Dict[str, any]

   class ExplicitAuthorizationService:
       def __init__(self, policy_engine: PolicyEngine, audit_service: AuditService):
           self.policy_engine = policy_engine
           self.audit_service = audit_service

       async def authorize_operation(self, auth_context: AuthorizationContext) -> AuthorizationDecision:
           """Make explicit authorization decision with full audit trail."""

           # 1. Explicit policy evaluation - no hidden rules
           applicable_policies = await self.policy_engine.find_applicable_policies(
               user_roles=auth_context.user_roles,
               resource_type=auth_context.resource_type,
               operation=auth_context.operation
           )

           if not applicable_policies:
               # Explicit denial when no policies apply (fail-safe default)
               decision = AuthorizationDecision(
                   permitted=False,
                   decision_reason="No applicable authorization policies found",
                   applicable_policies=[],
                   decision_timestamp=datetime.utcnow(),
                   requires_additional_auth=False,
                   audit_context=self._create_audit_context(auth_context)
               )
               await self._audit_authorization_decision(auth_context, decision)
               return decision

           # 2. Evaluate each policy explicitly with detailed reasoning
           policy_results = []
           for policy in applicable_policies:
               try:
                   result = await self.policy_engine.evaluate_policy(policy, auth_context)
                   policy_results.append(result)
               except PolicyEvaluationError as e:
                   # Policy evaluation failures are explicit denials
                   await self.audit_service.log_policy_evaluation_error(
                       policy.id, auth_context.user_id, str(e)
                   )
                   policy_results.append(PolicyResult(permitted=False, reason=f"Policy evaluation failed: {e}"))

           # 3. Combine policy results with explicit decision logic
           final_decision = self._combine_policy_results(policy_results, applicable_policies)

           # 4. Check for additional authentication requirements
           if final_decision.permitted and self._requires_additional_auth(auth_context, applicable_policies):
               final_decision.requires_additional_auth = True
               final_decision.decision_reason += " (additional authentication required)"

           # 5. Audit the authorization decision with full context
           await self._audit_authorization_decision(auth_context, final_decision)

           return final_decision

       def _combine_policy_results(self, results: List[PolicyResult], policies: List[Policy]) -> AuthorizationDecision:
           """Explicit policy combination logic - deny overrides allow."""

           # Explicit deny-wins logic
           deny_results = [r for r in results if not r.permitted]
           if deny_results:
               return AuthorizationDecision(
                   permitted=False,
                   decision_reason=f"Access denied by policies: {[r.reason for r in deny_results]}",
                   applicable_policies=[p.id for p in policies],
                   decision_timestamp=datetime.utcnow(),
                   requires_additional_auth=False,
                   audit_context={}
               )

           # All policies must explicitly permit
           allow_results = [r for r in results if r.permitted]
           if len(allow_results) == len(results) and allow_results:
               return AuthorizationDecision(
                   permitted=True,
                   decision_reason=f"Access granted by policies: {[r.reason for r in allow_results]}",
                   applicable_policies=[p.id for p in policies],
                   decision_timestamp=datetime.utcnow(),
                   requires_additional_auth=False,
                   audit_context={}
               )

           # Default to denial if no explicit permission
           return AuthorizationDecision(
               permitted=False,
               decision_reason="No explicit permission granted",
               applicable_policies=[p.id for p in policies],
               decision_timestamp=datetime.utcnow(),
               requires_additional_auth=False,
               audit_context={}
           )

   class PolicyEngine:
       async def evaluate_policy(self, policy: Policy, context: AuthorizationContext) -> PolicyResult:
           """Evaluate single policy with explicit logic and no hidden rules."""

           # 1. Explicit attribute matching
           if not self._matches_user_attributes(policy.user_conditions, context.user_attributes):
               return PolicyResult(
                   permitted=False,
                   reason=f"User attributes do not match policy {policy.id}"
               )

           # 2. Explicit resource matching
           if not self._matches_resource_attributes(policy.resource_conditions, context.resource_attributes):
               return PolicyResult(
                   permitted=False,
                   reason=f"Resource attributes do not match policy {policy.id}"
               )

           # 3. Explicit operation authorization
           if context.operation not in policy.allowed_operations:
               return PolicyResult(
                   permitted=False,
                   reason=f"Operation {context.operation} not permitted by policy {policy.id}"
               )

           # 4. Explicit environmental checks
           if not self._evaluate_environmental_conditions(policy.environmental_conditions, context):
               return PolicyResult(
                   permitted=False,
                   reason=f"Environmental conditions not met for policy {policy.id}"
               )

           # All conditions explicitly met
           return PolicyResult(
               permitted=True,
               reason=f"All conditions satisfied for policy {policy.id}"
           )
   ```

3. **Create Comprehensive Security Audit Infrastructure**: Implement detailed logging and monitoring that makes all authentication and authorization activities visible:

   Build audit systems that capture every security decision with sufficient context to understand, investigate, and verify proper access control implementation.

   ```go
   package security

   import (
       "context"
       "encoding/json"
       "time"
   )

   type SecurityAuditService struct {
       logger StructuredLogger
       config AuditConfig
       storage AuditStorage
   }

   type AuthenticationAuditEvent struct {
       EventType        string                 `json:"event_type"`
       UserID           string                 `json:"user_id"`
       Username         string                 `json:"username"`
       SessionID        string                 `json:"session_id"`
       IPAddress        string                 `json:"ip_address"`
       UserAgent        string                 `json:"user_agent"`
       AuthFactors      []string               `json:"auth_factors"`
       TrustLevel       string                 `json:"trust_level"`
       Success          bool                   `json:"success"`
       FailureReason    string                 `json:"failure_reason,omitempty"`
       Timestamp        time.Time              `json:"timestamp"`
       SecurityContext  map[string]interface{} `json:"security_context"`
       CorrelationID    string                 `json:"correlation_id"`
   }

   type AuthorizationAuditEvent struct {
       EventType        string                 `json:"event_type"`
       UserID           string                 `json:"user_id"`
       UserRoles        []string               `json:"user_roles"`
       ResourceID       string                 `json:"resource_id"`
       ResourceType     string                 `json:"resource_type"`
       Operation        string                 `json:"operation"`
       Decision         bool                   `json:"decision"`
       DecisionReason   string                 `json:"decision_reason"`
       ApplicablePolicies []string             `json:"applicable_policies"`
       TrustLevel       string                 `json:"trust_level"`
       Timestamp        time.Time              `json:"timestamp"`
       SecurityContext  map[string]interface{} `json:"security_context"`
       CorrelationID    string                 `json:"correlation_id"`
   }

   func (s *SecurityAuditService) LogAuthenticationAttempt(ctx context.Context, event AuthenticationAuditEvent) error {
       // Explicit audit logging with structured data
       event.EventType = "authentication_attempt"
       event.Timestamp = time.Now().UTC()
       event.CorrelationID = s.extractCorrelationID(ctx)

       // Log to structured logger for real-time monitoring
       s.logger.LogSecurityEvent(ctx, "authentication", map[string]interface{}{
           "event":          event,
           "severity":       s.calculateSeverity(event),
           "risk_score":     s.calculateRiskScore(event),
           "requires_alert": s.shouldTriggerAlert(event),
       })

       // Store in audit storage for compliance and investigation
       if err := s.storage.StoreAuditEvent(ctx, event); err != nil {
           s.logger.LogError(ctx, "Failed to store authentication audit event", err)
           // Never fail the operation due to audit logging issues
           // but ensure the failure is visible
       }

       return nil
   }

   func (s *SecurityAuditService) LogAuthorizationDecision(ctx context.Context, event AuthorizationAuditEvent) error {
       // Explicit authorization decision logging
       event.EventType = "authorization_decision"
       event.Timestamp = time.Now().UTC()
       event.CorrelationID = s.extractCorrelationID(ctx)

       // Enhanced logging for denied access attempts
       if !event.Decision {
           s.logger.LogSecurityEvent(ctx, "authorization_denied", map[string]interface{}{
               "event":              event,
               "severity":           "warning",
               "investigation_flag": true,
               "alert_security":     s.shouldAlertSecurityTeam(event),
           })
       }

       // Store detailed authorization trail for compliance
       return s.storage.StoreAuditEvent(ctx, event)
   }

   func (s *SecurityAuditService) LogSecurityControlBypass(ctx context.Context, userID, operation, justification string) error {
       // Explicit logging of any security control bypasses
       bypassEvent := SecurityBypassEvent{
           EventType:     "security_control_bypass",
           UserID:        userID,
           Operation:     operation,
           Justification: justification,
           Timestamp:     time.Now().UTC(),
           RequiresReview: true,
           ApprovedBy:    "", // Must be filled in by approval process
           CorrelationID: s.extractCorrelationID(ctx),
       }

       // All bypasses trigger immediate security team notification
       s.logger.LogSecurityEvent(ctx, "security_bypass", map[string]interface{}{
           "event":          bypassEvent,
           "severity":       "critical",
           "immediate_alert": true,
           "requires_approval": true,
       })

       return s.storage.StoreAuditEvent(ctx, bypassEvent)
   }

   // Example of explicit access review process
   func (s *SecurityAuditService) GenerateAccessReviewReport(ctx context.Context, userID string, timeRange TimeRange) (*AccessReviewReport, error) {
       // Generate comprehensive access review with explicit evidence

       authEvents, err := s.storage.GetAuthenticationEvents(ctx, userID, timeRange)
       if err != nil {
           return nil, fmt.Errorf("failed to retrieve authentication events: %w", err)
       }

       authzEvents, err := s.storage.GetAuthorizationEvents(ctx, userID, timeRange)
       if err != nil {
           return nil, fmt.Errorf("failed to retrieve authorization events: %w", err)
       }

       report := &AccessReviewReport{
           UserID:                userID,
           ReviewPeriod:          timeRange,
           TotalAuthAttempts:     len(authEvents),
           SuccessfulAuths:       s.countSuccessfulAuths(authEvents),
           FailedAuths:          s.countFailedAuths(authEvents),
           ResourcesAccessed:    s.extractUniqueResources(authzEvents),
           UnusualActivityFlags: s.detectUnusualActivity(authEvents, authzEvents),
           PolicyViolations:     s.detectPolicyViolations(authzEvents),
           RecommendedActions:   s.generateRecommendations(authEvents, authzEvents),
           GeneratedAt:         time.Now().UTC(),
       }

       return report, nil
   }
   ```

4. **Implement Security Testing and Validation**: Create comprehensive testing strategies that validate authentication and authorization logic:

   Build test suites that verify security controls work correctly, can't be bypassed, and maintain their effectiveness over time. Security tests should be as rigorous as functional tests.

   ```javascript
   describe('Authentication and Authorization Security Controls', () => {
     let authService;
     let authzService;
     let auditService;
     let testUsers;

     beforeEach(async () => {
       authService = new AuthenticationService();
       authzService = new AuthorizationService();
       auditService = new SecurityAuditService();
       testUsers = await setupTestUsers();
     });

     describe('Authentication Security', () => {
       test('should require multi-factor authentication for sensitive operations', async () => {
         const user = testUsers.standardUser;

         // First factor authentication
         const firstFactorResult = await authService.authenticatePassword(
           user.username,
           user.password
         );
         expect(firstFactorResult.status).toBe('mfa_required');
         expect(firstFactorResult.authContext).toBeUndefined();

         // Attempt to access sensitive operation without MFA
         expect(async () => {
           await authzService.authorize({
             userId: user.id,
             operation: 'delete_all_data',
             resourceType: 'user_data'
           });
         }).rejects.toThrow('Multi-factor authentication required');

         // Complete MFA
         const mfaResult = await authService.completeMFA(
           firstFactorResult.sessionToken,
           user.totpCode
         );
         expect(mfaResult.status).toBe('authenticated');
         expect(mfaResult.authContext.authenticationFactors).toHaveLength(2);
       });

       test('should prevent authentication bypass attempts', async () => {
         const maliciousInputs = [
           { username: 'admin\' OR \'1\'=\'1', password: 'anything' },
           { username: 'admin', password: 'password\'; DROP TABLE users; --' },
           { username: '../../../etc/passwd', password: 'test' },
           { username: 'admin', password: '', bypassAuth: true }, // Hidden bypass flag
         ];

         for (const input of maliciousInputs) {
           const result = await authService.authenticate(input);
           expect(result.success).toBe(false);
           expect(result.error).toMatch(/invalid credentials|authentication failed/i);

           // Verify security audit logging
           const auditEvents = await auditService.getRecentEvents('authentication_attempt');
           const latestEvent = auditEvents[0];
           expect(latestEvent.success).toBe(false);
           expect(latestEvent.failure_reason).toBeDefined();
         }
       });

       test('should enforce session timeouts and require re-authentication', async () => {
         const user = testUsers.standardUser;
         const authResult = await authService.authenticate({
           username: user.username,
           password: user.password,
           totpCode: user.totpCode
         });

         // Simulate session timeout
         await testUtils.advanceTime(authResult.authContext.sessionTimeout + 1000);

         // Attempt to use expired session
         expect(async () => {
           await authzService.authorize({
             userId: user.id,
             sessionId: authResult.authContext.sessionId,
             operation: 'read',
             resourceType: 'user_profile'
           });
         }).rejects.toThrow('Session expired');
       });
     });

     describe('Authorization Security', () => {
       test('should enforce role-based access control without exceptions', async () => {
         const regularUser = testUsers.regularUser;
         const adminUser = testUsers.adminUser;

         // Regular user should not access admin resources
         const regularUserAuthz = await authzService.authorize({
           userId: regularUser.id,
           userRoles: ['user'],
           operation: 'delete',
           resourceType: 'user_account',
           resourceId: 'any_user_account'
         });

         expect(regularUserAuthz.permitted).toBe(false);
         expect(regularUserAuthz.decision_reason).toMatch(/insufficient privileges|not authorized/i);

         // Admin user should access admin resources
         const adminUserAuthz = await authzService.authorize({
           userId: adminUser.id,
           userRoles: ['admin'],
           operation: 'delete',
           resourceType: 'user_account',
           resourceId: 'any_user_account'
         });

         expect(adminUserAuthz.permitted).toBe(true);
       });

       test('should prevent privilege escalation through parameter manipulation', async () => {
         const user = testUsers.regularUser;

         // Attempt privilege escalation through role manipulation
         const maliciousAuthzAttempts = [
           {
             userId: user.id,
             userRoles: ['user', 'admin'], // Trying to add admin role
             operation: 'delete',
             resourceType: 'user_account'
           },
           {
             userId: user.id,
             userRoles: ['user'],
             operation: 'delete',
             resourceType: 'user_account',
             bypassRoleCheck: true // Hidden bypass flag
           },
           {
             userId: 'admin_user_id', // Trying to impersonate admin
             userRoles: ['user'],
             operation: 'delete',
             resourceType: 'user_account'
           }
         ];

         for (const attempt of maliciousAuthzAttempts) {
           const result = await authzService.authorize(attempt);
           expect(result.permitted).toBe(false);
           expect(result.decision_reason).toMatch(/role mismatch|unauthorized|invalid user context/i);

           // Verify security audit captured the attempt
           const auditEvents = await auditService.getRecentEvents('authorization_decision');
           const latestEvent = auditEvents[0];
           expect(latestEvent.decision).toBe(false);
           expect(latestEvent.user_id).toBe(user.id); // Should record actual user, not attempted impersonation
         }
       });

       test('should require explicit permission for resource access', async () => {
         const user = testUsers.regularUser;

         // Test access to resource without explicit permission
         const unauthorizedResource = await authzService.authorize({
           userId: user.id,
           userRoles: ['user'],
           operation: 'read',
           resourceType: 'financial_data',
           resourceId: 'sensitive_financial_report'
         });

         expect(unauthorizedResource.permitted).toBe(false);
         expect(unauthorizedResource.decision_reason).toMatch(/no applicable policies|insufficient permissions/i);

         // Verify no implicit access granted
         expect(unauthorizedResource.applicable_policies).toHaveLength(0);
       });
     });

     describe('Security Audit and Compliance', () => {
       test('should maintain complete audit trail for all security decisions', async () => {
         const user = testUsers.regularUser;

         // Perform authentication
         await authService.authenticate({
           username: user.username,
           password: user.password,
           totpCode: user.totpCode
         });

         // Perform several authorization checks
         await authzService.authorize({
           userId: user.id,
           userRoles: ['user'],
           operation: 'read',
           resourceType: 'user_profile'
         });

         await authzService.authorize({
           userId: user.id,
           userRoles: ['user'],
           operation: 'write',
           resourceType: 'admin_settings'
         });

         // Verify complete audit trail
         const authEvents = await auditService.getEvents('authentication_attempt', { userId: user.id });
         const authzEvents = await auditService.getEvents('authorization_decision', { userId: user.id });

         expect(authEvents.length).toBeGreaterThan(0);
         expect(authzEvents.length).toBeGreaterThan(0);

         // Verify all required audit fields are present
         authEvents.forEach(event => {
           expect(event).toHaveProperty('user_id');
           expect(event).toHaveProperty('timestamp');
           expect(event).toHaveProperty('ip_address');
           expect(event).toHaveProperty('success');
           expect(event).toHaveProperty('correlation_id');
         });

         authzEvents.forEach(event => {
           expect(event).toHaveProperty('user_id');
           expect(event).toHaveProperty('resource_type');
           expect(event).toHaveProperty('operation');
           expect(event).toHaveProperty('decision');
           expect(event).toHaveProperty('decision_reason');
           expect(event).toHaveProperty('applicable_policies');
         });
       });

       test('should detect and flag unusual authentication patterns', async () => {
         const user = testUsers.regularUser;

         // Simulate unusual authentication pattern (multiple rapid attempts from different IPs)
         const unusualAttempts = [
           { username: user.username, password: 'wrong1', ipAddress: '192.168.1.1' },
           { username: user.username, password: 'wrong2', ipAddress: '10.0.0.1' },
           { username: user.username, password: 'wrong3', ipAddress: '172.16.0.1' },
           { username: user.username, password: 'wrong4', ipAddress: '203.0.113.1' },
           { username: user.username, password: 'wrong5', ipAddress: '198.51.100.1' }
         ];

         for (const attempt of unusualAttempts) {
           await authService.authenticate(attempt);
         }

         // Check for security alerts
         const securityAlerts = await auditService.getSecurityAlerts({ userId: user.id });
         expect(securityAlerts.some(alert => alert.type === 'suspicious_authentication_pattern')).toBe(true);
       });
     });
   });
   ```

## Examples

```python
# ❌ BAD: Implicit authentication with hidden security bypasses
class ImplicitAuthService:
    def login(self, username, password):
        # Hidden global state dependency
        if current_app.debug_mode:  # Implicit bypass in debug mode
            return {"user_id": username, "admin": True}  # Dangerous default

        # No audit trail
        user = db.query(f"SELECT * FROM users WHERE username='{username}'")  # SQL injection risk
        if user and user.password == password:  # Weak password comparison
            session["user_id"] = user.id  # Implicit session creation
            return {"success": True}

        return {"success": False}  # No failure details

    def check_permission(self, operation):
        # Implicit authentication state
        user_id = session.get("user_id")  # Could be None
        if not user_id:
            return False

        # Hidden admin bypass
        if user_id == "admin" or session.get("override"):  # Secret override flag
            return True

        # No explicit permission logic or audit
        return operation in ["read"]  # Hardcoded permissions
```

```python
# ✅ GOOD: Explicit authentication and authorization with comprehensive security controls
class ExplicitSecureAuthService:
    def __init__(self, audit_service: AuditService, session_manager: SessionManager, policy_engine: PolicyEngine):
        self.audit_service = audit_service
        self.session_manager = session_manager
        self.policy_engine = policy_engine

    async def authenticate_user(self, credentials: AuthCredentials, security_context: SecurityContext) -> AuthenticationResult:
        """Authenticate user with explicit security controls and full audit trail."""
        correlation_id = generate_correlation_id()

        try:
            # 1. Explicit input validation
            validation_result = await self.validate_credentials(credentials, security_context)
            if not validation_result.is_valid:
                await self.audit_service.log_authentication_failure(
                    username=credentials.username,
                    ip_address=security_context.ip_address,
                    failure_reason=validation_result.error,
                    correlation_id=correlation_id
                )
                raise AuthenticationError(validation_result.error)

            # 2. Explicit credential verification (no SQL injection risk)
            user = await self.user_repository.find_by_username(credentials.username)
            if not user or not await self.verify_password_secure(credentials.password, user.password_hash):
                await self.audit_service.log_authentication_failure(
                    username=credentials.username,
                    ip_address=security_context.ip_address,
                    failure_reason="Invalid username or password",
                    correlation_id=correlation_id
                )
                raise AuthenticationError("Invalid username or password")

            # 3. Explicit multi-factor authentication requirement
            mfa_result = await self.require_multi_factor_authentication(user, security_context)
            if not mfa_result.completed:
                return AuthenticationResult(
                    status="mfa_required",
                    challenge=mfa_result.challenge,
                    temporary_token=mfa_result.temporary_token
                )

            # 4. Create explicit authentication context
            auth_context = AuthenticationContext(
                user_id=user.id,
                username=user.username,
                session_id=generate_secure_session_id(),
                authentication_factors=[
                    AuthFactor(type="password", verified_at=datetime.utcnow(), strength="medium"),
                    AuthFactor(type=mfa_result.factor_type, verified_at=datetime.utcnow(), strength="strong")
                ],
                trust_level=self.calculate_trust_level(user, security_context, mfa_result),
                session_expires_at=datetime.utcnow() + timedelta(hours=8),
                requires_reauth=False,
                security_context=security_context
            )

            # 5. Create secure session with explicit expiration
            session_token = await self.session_manager.create_session(auth_context)

            # 6. Audit successful authentication with full context
            await self.audit_service.log_authentication_success(
                auth_context=auth_context,
                correlation_id=correlation_id
            )

            return AuthenticationResult(
                status="authenticated",
                auth_context=auth_context,
                session_token=session_token
            )

        except Exception as e:
            # 7. Audit unexpected failures
            await self.audit_service.log_authentication_error(
                username=credentials.username,
                error=str(e),
                correlation_id=correlation_id
            )
            raise

    async def authorize_operation(self, auth_context: AuthenticationContext, resource: Resource, operation: str) -> AuthorizationResult:
        """Authorize operation with explicit permission checking and audit trail."""
        correlation_id = generate_correlation_id()

        try:
            # 1. Explicit session validation
            if not await self.session_manager.is_session_valid(auth_context.session_id):
                await self.audit_service.log_authorization_failure(
                    user_id=auth_context.user_id,
                    resource_id=resource.id,
                    operation=operation,
                    reason="Invalid or expired session",
                    correlation_id=correlation_id
                )
                raise AuthorizationError("Session invalid or expired")

            # 2. Check for re-authentication requirements
            if auth_context.requires_reauth:
                await self.audit_service.log_authorization_failure(
                    user_id=auth_context.user_id,
                    resource_id=resource.id,
                    operation=operation,
                    reason="Re-authentication required",
                    correlation_id=correlation_id
                )
                raise AuthorizationError("Re-authentication required")

            # 3. Explicit permission evaluation
            authorization_context = AuthorizationContext(
                user_id=auth_context.user_id,
                user_roles=await self.get_user_roles(auth_context.user_id),
                user_attributes=await self.get_user_attributes(auth_context.user_id),
                resource_id=resource.id,
                resource_type=resource.type,
                resource_attributes=resource.attributes,
                operation=operation,
                trust_level=auth_context.trust_level,
                security_context=auth_context.security_context
            )

            # 4. Policy engine evaluation (explicit, no hidden rules)
            authorization_decision = await self.policy_engine.evaluate_authorization(authorization_context)

            # 5. Audit authorization decision
            await self.audit_service.log_authorization_decision(
                authorization_context=authorization_context,
                decision=authorization_decision,
                correlation_id=correlation_id
            )

            # 6. Handle additional authentication requirements
            if authorization_decision.requires_additional_auth:
                return AuthorizationResult(
                    permitted=False,
                    reason="Additional authentication required",
                    required_auth_level=authorization_decision.required_auth_level
                )

            return AuthorizationResult(
                permitted=authorization_decision.permitted,
                reason=authorization_decision.reason,
                applicable_policies=authorization_decision.applicable_policies
            )

        except Exception as e:
            # 7. Audit authorization errors
            await self.audit_service.log_authorization_error(
                user_id=auth_context.user_id,
                resource_id=resource.id,
                operation=operation,
                error=str(e),
                correlation_id=correlation_id
            )
            raise

    async def handle_security_override(self, admin_context: AuthenticationContext, target_operation: str, justification: str) -> OverrideResult:
        """Handle security overrides with explicit approval and audit trail - NO SECRET BYPASSES."""
        correlation_id = generate_correlation_id()

        # 1. Explicit admin verification
        if not await self.is_security_admin(admin_context.user_id):
            await self.audit_service.log_security_violation(
                user_id=admin_context.user_id,
                violation_type="unauthorized_override_attempt",
                correlation_id=correlation_id
            )
            raise SecurityError("Insufficient privileges for security override")

        # 2. Require explicit justification
        if not justification or len(justification.strip()) < 50:
            raise SecurityError("Detailed justification required for security overrides")

        # 3. Create explicit override record
        override_request = SecurityOverrideRequest(
            admin_user_id=admin_context.user_id,
            target_operation=target_operation,
            justification=justification,
            requested_at=datetime.utcnow(),
            requires_approval=True,
            expires_at=datetime.utcnow() + timedelta(hours=24),  # Explicit expiration
            correlation_id=correlation_id
        )

        # 4. Audit override request
        await self.audit_service.log_security_override_request(override_request)

        # 5. Trigger approval workflow (no automatic approvals)
        approval_token = await self.security_approval_service.request_approval(override_request)

        return OverrideResult(
            approved=False,  # Never immediately approved
            approval_token=approval_token,
            message="Security override request submitted for approval"
        )
```

```javascript
// ❌ BAD: Hidden authentication state and authorization bypasses
class ImplicitAuthClient {
  login(username, password) {
    // No explicit validation or security context
    if (username && password) {
      // Hidden global state modification
      window.currentUser = { username, isAdmin: username === 'admin' };
      localStorage.setItem('authToken', btoa(username + ':' + password)); // Insecure token
      return true;
    }
    return false;
  }

  canAccess(resource) {
    // Implicit authentication check
    const user = window.currentUser; // Could be undefined or tampered
    if (!user) return false;

    // Hidden admin bypass
    if (user.isAdmin || localStorage.getItem('debugMode')) return true; // Secret bypass

    // No explicit permission logic
    return resource !== 'admin'; // Hardcoded logic
  }

  makeRequest(url, data) {
    // Implicit token usage
    return fetch(url, {
      headers: { 'Authorization': localStorage.getItem('authToken') }, // No validation
      body: JSON.stringify(data)
    });
  }
}
```

```javascript
// ✅ GOOD: Explicit authentication and authorization with security controls
class ExplicitSecureAuthClient {
  constructor(config) {
    this.config = config;
    this.authContext = null;
    this.sessionManager = new SecureSessionManager(config);
    this.auditLogger = new ClientAuditLogger(config);
  }

  async authenticate(credentials, securityContext) {
    /**
     * Explicit authentication with comprehensive security controls
     */
    const correlationId = this.generateCorrelationId();

    try {
      // 1. Explicit input validation
      const validationResult = this.validateCredentials(credentials);
      if (!validationResult.isValid) {
        await this.auditLogger.logAuthenticationFailure({
          username: credentials.username,
          failureReason: validationResult.error,
          correlationId: correlationId
        });
        throw new AuthenticationError(validationResult.error);
      }

      // 2. Secure authentication request
      const authRequest = {
        username: credentials.username,
        password: credentials.password, // Will be sent over HTTPS only
        clientContext: {
          userAgent: navigator.userAgent,
          ipAddress: await this.getClientIP(),
          timestamp: new Date().toISOString(),
          correlationId: correlationId
        }
      };

      // 3. Explicit authentication call with proper error handling
      const response = await this.makeSecureRequest('/auth/login', authRequest);

      if (response.status === 'mfa_required') {
        // 4. Handle explicit MFA requirement
        return {
          status: 'mfa_required',
          challenge: response.challenge,
          temporaryToken: response.temporaryToken
        };
      }

      if (response.status !== 'authenticated') {
        await this.auditLogger.logAuthenticationFailure({
          username: credentials.username,
          failureReason: response.error || 'Authentication failed',
          correlationId: correlationId
        });
        throw new AuthenticationError(response.error || 'Authentication failed');
      }

      // 5. Create explicit authentication context
      this.authContext = {
        userId: response.authContext.userId,
        username: response.authContext.username,
        sessionId: response.authContext.sessionId,
        authenticationFactors: response.authContext.authenticationFactors,
        trustLevel: response.authContext.trustLevel,
        sessionExpiresAt: new Date(response.authContext.sessionExpiresAt),
        permissions: response.authContext.permissions || [],
        securityContext: securityContext
      };

      // 6. Store secure session token
      await this.sessionManager.storeSecureSession(response.sessionToken, this.authContext);

      // 7. Audit successful authentication
      await this.auditLogger.logAuthenticationSuccess({
        authContext: this.authContext,
        correlationId: correlationId
      });

      return {
        status: 'authenticated',
        authContext: this.authContext
      };

    } catch (error) {
      await this.auditLogger.logAuthenticationError({
        username: credentials.username,
        error: error.message,
        correlationId: correlationId
      });
      throw error;
    }
  }

  async authorizeOperation(resource, operation) {
    /**
     * Explicit authorization checking with audit trail
     */
    const correlationId = this.generateCorrelationId();

    try {
      // 1. Explicit authentication state validation
      if (!this.authContext || !await this.sessionManager.isSessionValid()) {
        await this.auditLogger.logAuthorizationFailure({
          resource: resource,
          operation: operation,
          reason: 'No valid authentication context',
          correlationId: correlationId
        });
        throw new AuthorizationError('Authentication required');
      }

      // 2. Check session expiration explicitly
      if (new Date() > this.authContext.sessionExpiresAt) {
        await this.auditLogger.logAuthorizationFailure({
          userId: this.authContext.userId,
          resource: resource,
          operation: operation,
          reason: 'Session expired',
          correlationId: correlationId
        });
        this.clearAuthContext();
        throw new AuthorizationError('Session expired - please re-authenticate');
      }

      // 3. Explicit authorization request
      const authzRequest = {
        userId: this.authContext.userId,
        sessionId: this.authContext.sessionId,
        resource: {
          id: resource.id,
          type: resource.type,
          attributes: resource.attributes || {}
        },
        operation: operation,
        clientContext: {
          timestamp: new Date().toISOString(),
          correlationId: correlationId
        }
      };

      // 4. Server-side authorization check (never trust client-side permissions)
      const authzResponse = await this.makeSecureRequest('/auth/authorize', authzRequest);

      // 5. Audit authorization decision
      await this.auditLogger.logAuthorizationDecision({
        authzRequest: authzRequest,
        decision: authzResponse,
        correlationId: correlationId
      });

      if (!authzResponse.permitted) {
        throw new AuthorizationError(authzResponse.reason || 'Operation not permitted');
      }

      return {
        permitted: true,
        reason: authzResponse.reason,
        applicablePolicies: authzResponse.applicablePolicies || []
      };

    } catch (error) {
      await this.auditLogger.logAuthorizationError({
        userId: this.authContext?.userId,
        resource: resource,
        operation: operation,
        error: error.message,
        correlationId: correlationId
      });
      throw error;
    }
  }

  async makeSecureRequest(endpoint, data) {
    /**
     * Make authenticated request with explicit security controls
     */
    // 1. Explicit session token validation
    const sessionToken = await this.sessionManager.getValidSessionToken();
    if (!sessionToken) {
      throw new AuthenticationError('No valid session token');
    }

    // 2. Explicit security headers
    const secureHeaders = {
      'Authorization': `Bearer ${sessionToken}`,
      'Content-Type': 'application/json',
      'X-Correlation-ID': this.generateCorrelationId(),
      'X-Client-Version': this.config.clientVersion,
      'X-Request-Timestamp': new Date().toISOString()
    };

    // 3. Explicit HTTPS enforcement
    const url = new URL(endpoint, this.config.apiBaseUrl);
    if (url.protocol !== 'https:') {
      throw new SecurityError('HTTPS required for all authentication requests');
    }

    try {
      const response = await fetch(url.toString(), {
        method: 'POST',
        headers: secureHeaders,
        body: JSON.stringify(data),
        credentials: 'same-origin', // Explicit credential policy
        cache: 'no-cache' // No caching of sensitive requests
      });

      if (!response.ok) {
        if (response.status === 401) {
          this.clearAuthContext();
          throw new AuthenticationError('Authentication failed');
        }
        if (response.status === 403) {
          throw new AuthorizationError('Operation not permitted');
        }
        throw new Error(`Request failed with status ${response.status}`);
      }

      return await response.json();

    } catch (error) {
      await this.auditLogger.logRequestError({
        endpoint: endpoint,
        error: error.message,
        userId: this.authContext?.userId
      });
      throw error;
    }
  }

  clearAuthContext() {
    /**
     * Explicit authentication context cleanup
     */
    this.authContext = null;
    this.sessionManager.clearSession();
  }

  async logout() {
    /**
     * Explicit logout with server-side session invalidation
     */
    if (this.authContext) {
      try {
        await this.makeSecureRequest('/auth/logout', {
          sessionId: this.authContext.sessionId
        });

        await this.auditLogger.logLogout({
          userId: this.authContext.userId,
          sessionId: this.authContext.sessionId
        });
      } catch (error) {
        // Always clear local context even if server logout fails
        await this.auditLogger.logLogoutError({
          userId: this.authContext.userId,
          error: error.message
        });
      }
    }

    this.clearAuthContext();
  }
}
```

## Related Bindings

- [explicit-over-implicit](../../docs/tenets/explicit-over-implicit.md): Authentication and authorization patterns implement explicit-over-implicit by making all security decisions visible, documented, and auditable rather than relying on hidden assumptions or implicit trust relationships. Both approaches ensure that system behavior is clear and predictable.

- [no-secret-suppression](../../docs/tenets/no-secret-suppression.md): Authentication and authorization patterns prevent the suppression or bypassing of security controls by requiring explicit justification and documentation for any security overrides. Both tenets work together to maintain security integrity and prevent hidden vulnerabilities.

- [secure-by-design-principles](../../docs/bindings/categories/security/secure-by-design-principles.md): Authentication and authorization patterns are foundational components of secure-by-design architecture, providing the identity and access control layer that enables all other security controls. Both bindings work together to create systems where security is built into the architecture from the beginning.

- [input-validation-standards](../../docs/bindings/categories/security/input-validation-standards.md): Authentication credentials and authorization parameters must be validated using the same security-focused validation standards to prevent injection attacks and data corruption. Both bindings create complementary layers of security validation.

- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Authentication and authorization events require comprehensive structured logging to enable security monitoring, incident response, and compliance auditing. Both bindings create systematic observability for security-critical operations.

- [external-configuration](../../docs/bindings/core/external-configuration.md): Authentication and authorization policies, security rules, and configuration parameters should be externally configurable to adapt to changing security requirements without code changes. Both bindings support environment-specific security controls and policy management.

- [comprehensive-security-automation](../../docs/bindings/core/comprehensive-security-automation.md): Authentication and authorization patterns are enforced through automated security testing, policy validation, and continuous monitoring. Both bindings create systematic security validation that ensures consistent application of security controls throughout the development and deployment pipeline.
