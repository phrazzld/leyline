---
id: input-validation-standards
last_modified: '2025-06-11'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: static analysis tools (semgrep, codeql, bandit) + security code review + test coverage requirements
---

# Binding: Implement Comprehensive Security Input Validation and Sanitization

Validate and sanitize all external input at system boundaries using explicit security-focused validation rules that prevent injection attacks, data corruption, and privilege escalation. Treat all external data as untrusted and potentially malicious.

## Rationale

This binding implements our explicit-over-implicit tenet by applying security-focused validation at every trust boundary. Like an immune system with multiple layers of defense, security input validation creates explicit protection against common attack vectors while making security assumptions visible and testable.

Input validation failures are among the most exploited vulnerabilities—from SQL injection to XSS to remote code execution. These attacks succeed when applications trust external data without proper validation. Explicit, security-focused validation at every boundary eliminates entire categories of vulnerabilities.

## Rule Definition

Security input validation requires comprehensive protection across all external data sources:

**Validation Scope:**
- **All External Input**: HTTP requests, file uploads, API calls, environment variables, configuration files
- **Trust Boundaries**: Validation at every point where data crosses from untrusted to trusted zones
- **Output Validation**: Data leaving the system must be sanitized for destination context

**Security Categories:**
- **Injection Prevention**: SQL injection, XSS, command injection, path traversal using parameterized queries and encoding
- **Data Integrity**: Type safety, format validation, size limits, character set validation
- **Authentication/Authorization**: Identity verification, permission checking, rate limiting, origin validation

## Practical Implementation

1. **Multi-Layer Security Validation**: Create validation layers that focus on different threat categories:

   ```typescript
   interface SecurityValidator {
     validateSQLSafety(input: string): ValidationResult;
     validateXSSSafety(input: string): ValidationResult;
     validateFileUpload(file: File): ValidationResult;
     validateAuthentication(token: string): ValidationResult;
   }

   class InputSecurityValidator implements SecurityValidator {
     validateSQLSafety(input: string): ValidationResult {
       // Check for SQL injection patterns: quotes, semicolons, SQL keywords
       const dangerousPatterns = /['"`;]|(union|select|insert|update|delete|drop)\s/i;
       if (dangerousPatterns.test(input)) {
         return ValidationResult.failure("Potentially malicious SQL patterns detected");
       }
       return ValidationResult.success();
     }

     validateXSSSafety(input: string): ValidationResult {
       // Check for XSS patterns: script tags, event handlers, javascript: URLs
       const xssPatterns = /<script|on\w+\s*=|javascript:/i;
       if (xssPatterns.test(input)) {
         return ValidationResult.failure("Potentially malicious script content detected");
       }
       return ValidationResult.success();
     }

     validateFileUpload(file: File): ValidationResult {
       const allowedTypes = ['image/jpeg', 'image/png', 'text/plain', 'application/pdf'];
       const maxSize = 10 * 1024 * 1024; // 10MB

       if (!allowedTypes.includes(file.type)) {
         return ValidationResult.failure("File type not allowed");
       }
       if (file.size > maxSize) {
         return ValidationResult.failure("File size exceeds limit");
       }
       return ValidationResult.success();
     }
   }
   ```

2. **Parameterized Queries and Output Encoding**: Use safe database APIs and proper encoding:

   ```python
   # Prevent SQL injection with parameterized queries
   def get_user_by_id(user_id: int) -> User:
       # ❌ VULNERABLE: String interpolation
       # query = f"SELECT * FROM users WHERE id = {user_id}"

       # ✅ SECURE: Parameterized query
       query = "SELECT * FROM users WHERE id = ?"
       return db.execute(query, [user_id])

   # Prevent XSS with output encoding
   def render_user_bio(bio: str) -> str:
       # ❌ VULNERABLE: Raw output
       # return f"<p>{bio}</p>"

       # ✅ SECURE: HTML encoding
       import html
       return f"<p>{html.escape(bio)}</p>"
   ```

3. **Rate Limiting and Authentication**: Implement protection against abuse and unauthorized access:

   ```typescript
   class SecurityMiddleware {
     private rateLimiter = new Map<string, number[]>();

     async validateRequest(req: Request): Promise<ValidationResult> {
       // Rate limiting by IP
       const clientIP = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
       if (!this.checkRateLimit(clientIP)) {
         return ValidationResult.failure("Rate limit exceeded");
       }

       // Authentication validation
       const authToken = req.headers['authorization'];
       if (!this.validateAuthToken(authToken)) {
         return ValidationResult.failure("Invalid authentication");
       }

       return ValidationResult.success();
     }

     private checkRateLimit(identifier: string): boolean {
       const now = Date.now();
       const windowMs = 60000; // 1 minute
       const maxRequests = 100;

       const requests = this.rateLimiter.get(identifier) || [];
       const validRequests = requests.filter(timestamp => now - timestamp < windowMs);

       if (validRequests.length >= maxRequests) {
         return false;
       }

       validRequests.push(now);
       this.rateLimiter.set(identifier, validRequests);
       return true;
     }
   }
   ```

## Examples

```typescript
// ❌ BAD: No input validation, vulnerable to injection attacks
app.post('/users', (req, res) => {
  const { username, email, bio } = req.body;

  // SQL injection vulnerability
  const query = `INSERT INTO users (username, email, bio) VALUES ('${username}', '${email}', '${bio}')`;
  db.query(query);

  // XSS vulnerability when displaying bio
  res.json({ message: `User ${username} registered!` });
});
```

```typescript
// ✅ GOOD: Comprehensive security validation
app.post('/users', async (req, res) => {
  try {
    // 1. Validate all input
    const validationResult = await securityValidator.validateUserInput(req.body);
    if (!validationResult.isValid) {
      return res.status(400).json({ error: validationResult.errors });
    }

    // 2. Use parameterized queries
    const { username, email, bio } = validationResult.sanitizedData;
    const user = await db.query(
      'INSERT INTO users (username, email, bio) VALUES (?, ?, ?) RETURNING id',
      [username, email, bio]
    );

    // 3. Safe response (no XSS risk)
    res.json({
      message: 'User registered successfully',
      userId: user.id
    });

  } catch (error) {
    auditLogger.logSecurityEvent('user_registration_failed', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});
```

## Related Bindings

- [fail-fast-validation](../../core/fail-fast-validation.md): Input validation standards build upon fail-fast validation principles by adding security-specific validation rules and threat detection.

- [secure-by-design-principles](../../docs/bindings/categories/security/secure-by-design-principles.md): Input validation is a foundational component of secure-by-design architecture, providing the first line of defense against external threats.
