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

This binding implements explicit-over-implicit by requiring that all authentication and authorization decisions be visible, documented, and intentional rather than hidden behind implicit assumptions. It also embodies no-secret-suppression by preventing bypass of security controls without proper justification.

Authentication and authorization work like a secure building's access control system with explicit badges, clear entry points, and visible security checkpoints rather than relying on informal recognition or assumptions about who belongs where.

Implicit patterns—such as assuming user context from global state, making authorization decisions based on hidden application logic, or bypassing security checks through backdoors—create significant vulnerabilities and compliance risks.

## Rule Definition

Authentication and authorization patterns must implement comprehensive identity and access control with full transparency and auditability:

**Authentication Requirements:**
- Multi-factor authentication with explicit trust levels
- Secure session management with timeouts and lifecycle controls
- Strong credential policies with proper hashing and rotation
- Explicit authentication context and verification state

**Authorization Requirements:**
- Role-based access control with clear hierarchies
- Attribute-based decisions using user and resource context
- Least privilege principle with explicit elevation
- Clear permission boundaries between security domains

**Security Control Transparency:**
- Comprehensive authentication and authorization logging
- Real-time security event monitoring and anomaly detection
- Audit trails supporting compliance and incident investigation

## Practical Implementation

1. **Implement Explicit Authentication Flow**: Create clear authentication workflows with proper state management:

   ```typescript
   interface AuthenticationContext {
     userId: string;
     sessionId: string;
     authenticationMethods: AuthMethod[];
     trustLevel: TrustLevel;
     expiresAt: Date;
     lastActivity: Date;
   }

   enum AuthMethod {
     PASSWORD = 'password',
     TOTP = 'totp',
     SMS = 'sms',
     BIOMETRIC = 'biometric',
     CERTIFICATE = 'certificate'
   }

   enum TrustLevel {
     ANONYMOUS = 0,
     AUTHENTICATED = 1,
     VERIFIED = 2,
     HIGH_TRUST = 3
   }

   class AuthenticationService {
     async authenticate(credentials: LoginCredentials): Promise<AuthenticationResult> {
       const auditContext = {
         correlationId: generateCorrelationId(),
         ipAddress: credentials.ipAddress,
         timestamp: new Date()
       };

       try {
         const user = await this.validateCredentials(credentials);
         const requiredMethods = await this.getRequiredAuthMethods(user);

         if (requiredMethods.length > 1) {
           return {
             status: 'ADDITIONAL_FACTORS_REQUIRED',
             requiredMethods,
             partialToken: await this.createPartialToken(user, auditContext)
           };
         }

         const authContext = await this.createAuthenticationContext(user, [AuthMethod.PASSWORD]);

         await this.auditLogger.logAuthenticationSuccess({
           userId: user.id,
           methods: [AuthMethod.PASSWORD],
           trustLevel: authContext.trustLevel,
           ...auditContext
         });

         return {
           status: 'SUCCESS',
           authenticationContext: authContext,
           sessionToken: await this.createSessionToken(authContext)
         };
       } catch (error) {
         await this.auditLogger.logAuthenticationFailure({
           username: credentials.username,
           reason: error.message,
           ...auditContext
         });
         throw new AuthenticationError('Authentication failed');
       }
     }
   }
   ```

2. **Design Role-Based Access Control**: Create explicit permission structures with clear hierarchies:

   ```typescript
   interface Permission {
     id: string;
     resource: string;
     action: string;
     conditions?: AccessCondition[];
   }

   interface Role {
     id: string;
     name: string;
     permissions: Permission[];
     inheritsFrom?: string[];
   }

   interface AccessCondition {
     type: 'time' | 'location' | 'resource_owner' | 'approval';
     parameters: Record<string, any>;
   }

   class AuthorizationService {
     async authorize(
       authContext: AuthenticationContext,
       resource: string,
       action: string,
       context?: AccessContext
     ): Promise<AuthorizationResult> {
       const auditContext = {
         userId: authContext.userId,
         sessionId: authContext.sessionId,
         resource,
         action,
         timestamp: new Date()
       };

       try {
         const userRoles = await this.getUserRoles(authContext.userId);
         const effectivePermissions = await this.resolvePermissions(userRoles);

         const matchingPermission = this.findMatchingPermission(
           effectivePermissions,
           resource,
           action
         );

         if (!matchingPermission) {
           await this.auditLogger.logAuthorizationDenied({
             reason: 'NO_PERMISSION',
             ...auditContext
           });
           return { granted: false, reason: 'Insufficient permissions' };
         }

         const conditionResult = await this.evaluateConditions(
           matchingPermission.conditions || [],
           context
         );

         if (!conditionResult.satisfied) {
           await this.auditLogger.logAuthorizationDenied({
             reason: 'CONDITION_FAILED',
             ...auditContext
           });
           return { granted: false, reason: conditionResult.reason };
         }

         await this.auditLogger.logAuthorizationGranted({
           permission: matchingPermission.id,
           ...auditContext
         });

         return { granted: true, permission: matchingPermission };
       } catch (error) {
         await this.auditLogger.logAuthorizationError({
           error: error.message,
           ...auditContext
         });
         throw new AuthorizationError('Authorization check failed');
       }
     }
   }
   ```

3. **Security Middleware**: Create explicit security controls for web applications:

   ```typescript
   class SecurityMiddleware {
     authenticate() {
       return async (req: Request, res: Response, next: NextFunction) => {
         try {
           const token = this.extractToken(req);
           if (!token) {
             return res.status(401).json({ error: 'Authentication required' });
           }

           const authContext = await this.authService.validateSession(token);
           if (!authContext) {
             return res.status(401).json({ error: 'Invalid or expired session' });
           }

           req.authContext = authContext;
           await this.auditLogger.logSecurityEvent({
             type: 'AUTHENTICATION_SUCCESS',
             userId: authContext.userId,
             path: req.path,
             method: req.method
           });
           next();
         } catch (error) {
           await this.auditLogger.logSecurityEvent({
             type: 'AUTHENTICATION_FAILURE',
             path: req.path,
             error: error.message
           });
           res.status(401).json({ error: 'Authentication failed' });
         }
       };
     }

     authorize(resource: string, action: string) {
       return async (req: Request, res: Response, next: NextFunction) => {
         const authResult = await this.authzService.authorize(
           req.authContext,
           resource,
           action,
           { path: req.path, method: req.method, ipAddress: req.ip }
         );

         if (!authResult.granted) {
           return res.status(403).json({
             error: 'Access denied',
             reason: authResult.reason
           });
         }

         req.authzContext = authResult;
         next();
       };
     }
   }

   // Usage example
   app.get('/admin/users',
     security.authenticate(),
     security.authorize('users', 'read'),
     async (req, res) => {
       const users = await userService.getAllUsers();
       res.json(users);
     }
   );
   ```

## Examples

```typescript
// ❌ BAD: Implicit authentication with global state
let currentUser: User | null = null;

function createPost(data: PostData) {
  const user = getCurrentUser(); // Implicit authentication
  if (user.role === 'admin') { // Hidden authorization logic
    return postService.create(data);
  }
  throw new Error('Access denied');
}

// ✅ GOOD: Explicit authentication and authorization
interface AuthenticatedRequest extends Request {
  authContext: AuthenticationContext;
}

async function createPost(req: AuthenticatedRequest, res: Response) {
  const { authContext } = req;

  const authResult = await authzService.authorize(
    authContext,
    'posts',
    'create'
  );

  if (!authResult.granted) {
    await auditLogger.logAuthorizationDenied({
      userId: authContext.userId,
      resource: 'posts',
      action: 'create',
      reason: authResult.reason
    });

    return res.status(403).json({
      error: 'Access denied',
      reason: authResult.reason
    });
  }

  await auditLogger.logResourceAccess({
    userId: authContext.userId,
    resource: 'posts',
    action: 'create',
    granted: true
  });

  const post = await postService.create(req.body, {
    createdBy: authContext.userId
  });

  res.json(post);
}
```

## Related Bindings

- [explicit-over-implicit](../../tenets/explicit-over-implicit.md): Authentication and authorization patterns directly implement this tenet by making all security decisions visible, documented, and intentional rather than hidden behind implicit assumptions.

- [no-secret-suppression](../../tenets/no-secret-suppression.md): This binding prevents bypass of security controls without proper justification, ensuring all exceptions to security policies are explicit and auditable.

- [use-structured-logging](../core/use-structured-logging.md): Security event logging requires structured, searchable audit trails that support compliance reporting and security incident investigation.

- [secure-by-design-principles](../../docs/bindings/categories/security/secure-by-design-principles.md): Authentication and authorization patterns provide the foundational security controls that enable secure-by-design architecture through explicit identity verification and access control.
