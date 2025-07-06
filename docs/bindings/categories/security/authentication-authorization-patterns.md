---
id: authentication-authorization-patterns
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: authentication audit tools + access control testing + security code review + compliance checks
---

# Binding: Implement Explicit Authentication and Authorization Patterns

Establish clear, explicit identity verification and access control mechanisms that make authentication and authorization decisions visible, auditable, and enforceable.

## Rationale

This binding implements explicit-over-implicit by requiring that all authentication and authorization decisions be visible, documented, and intentional rather than hidden behind implicit assumptions. It prevents bypass of security controls without proper justification.

## Rule Definition

**Authentication Requirements:**
- Multi-factor authentication with explicit trust levels
- Secure session management with timeouts and lifecycle controls
- Strong credential policies with proper hashing and rotation
- Explicit authentication context and verification state

**Authorization Requirements:**
- Role-based access control with clear hierarchies
- Attribute-based decisions using user and resource context
- Least privilege principle with explicit elevation
- Comprehensive logging and audit trails

## Practical Implementation

**1. Authentication Context:**

```typescript
interface AuthenticationContext {
  userId: string;
  sessionId: string;
  trustLevel: TrustLevel;
  expiresAt: Date;
}

enum TrustLevel {
  ANONYMOUS = 0,
  AUTHENTICATED = 1,
  VERIFIED = 2
}

class AuthenticationService {
  async authenticate(credentials: LoginCredentials): Promise<AuthenticationResult> {
    try {
      const user = await this.validateCredentials(credentials);
      const authContext = await this.createAuthenticationContext(user);

      await this.auditLogger.logAuthenticationSuccess({ userId: user.id });

      return {
        status: 'SUCCESS',
        authenticationContext: authContext,
        sessionToken: await this.createSessionToken(authContext)
      };
    } catch (error) {
      await this.auditLogger.logAuthenticationFailure({ username: credentials.username });
      throw new AuthenticationError('Authentication failed');
    }
  }
}
```

**2. Role-Based Access Control:**

```typescript
interface Permission {
  id: string;
  resource: string;
  action: string;
}

interface Role {
  id: string;
  name: string;
  permissions: Permission[];
}

class AuthorizationService {
  async authorize(
    authContext: AuthenticationContext,
    resource: string,
    action: string
  ): Promise<AuthorizationResult> {
    const userRoles = await this.getUserRoles(authContext.userId);
    const effectivePermissions = await this.resolvePermissions(userRoles);

    const matchingPermission = this.findMatchingPermission(
      effectivePermissions,
      resource,
      action
    );

    if (!matchingPermission) {
      await this.auditLogger.logAuthorizationDenied({ userId: authContext.userId, resource, action });
      return { granted: false, reason: 'Insufficient permissions' };
    }

    await this.auditLogger.logAuthorizationGranted({ userId: authContext.userId, resource, action });

    return { granted: true, permission: matchingPermission };
  }
}
```

**3. Security Middleware:**

```typescript
class SecurityMiddleware {
  authenticate() {
    return async (req: Request, res: Response, next: NextFunction) => {
      const token = this.extractToken(req);
      if (!token) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const authContext = await this.authService.validateSession(token);
      if (!authContext) {
        return res.status(401).json({ error: 'Invalid session' });
      }

      req.authContext = authContext;
      next();
    };
  }

  authorize(resource: string, action: string) {
    return async (req: Request, res: Response, next: NextFunction) => {
      const authResult = await this.authzService.authorize(
        req.authContext,
        resource,
        action
      );

      if (!authResult.granted) {
        return res.status(403).json({ error: 'Access denied' });
      }

      next();
    };
  }
}

// Usage: app.get('/admin/users', security.authenticate(), security.authorize('users', 'read'), handler);
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
async function createPost(req: AuthenticatedRequest, res: Response) {
  const authResult = await authzService.authorize(
    req.authContext,
    'posts',
    'create'
  );

  if (!authResult.granted) {
    return res.status(403).json({
      error: 'Access denied',
      reason: authResult.reason
    });
  }

  const post = await postService.create(req.body, {
    createdBy: req.authContext.userId
  });

  res.json(post);
}
```

## Related Bindings

- [explicit-over-implicit](../../tenets/explicit-over-implicit.md): Makes all security decisions visible, documented, and intentional
- [no-secret-suppression](../../tenets/no-secret-suppression.md): Prevents bypass of security controls without proper justification
- [use-structured-logging](../../core/use-structured-logging.md): Requires structured audit trails for compliance and investigation
- [secure-by-design-principles](secure-by-design-principles.md): Provides foundational security controls for secure-by-design architecture
