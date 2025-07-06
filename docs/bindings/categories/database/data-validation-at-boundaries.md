---
id: data-validation-at-boundaries
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: modularity
enforced_by: input validation frameworks & code review
---

# Binding: Validate Data Explicitly at Database Boundaries

All data crossing database boundaries must be explicitly validated by the responsible module before persistence and after retrieval. Each module owns its validation logic completely, without depending on other modules or database constraints for data integrity.

## Rationale

This binding implements our modularity tenet by ensuring each module takes complete responsibility for data validity at database boundaries. Like customs at international borders, each module must validate what enters and leaves its territory.

Database constraints provide backup protection but aren't sufficient for proper validation. They provide cryptic errors, limited logic, and can't handle complex business rules. Explicit code-level validation provides clear error messages, comprehensive business logic, and maintainable validation that evolves with requirements.

## Rule Definition

**Required Components:**
- **Input Validation**: Validate type safety, business rules, and constraints before persistence
- **Output Validation**: Validate retrieved data meets current business rules and isn't corrupted
- **Business Rule Enforcement**: Implement complex rules too sophisticated for database constraints
- **Clear Error Messages**: Provide actionable feedback for validation failures
- **Fail-Fast Principle**: Reject invalid data as early as possible

**Prohibited Practices:**
- Relying solely on database constraints for validation
- Allowing invalid data to reach database operations
- Scattering validation logic across modules
- Generic error messages without actionable guidance
- Bypassing validation for "trusted" sources

## Practical Implementation

**1. Schema-Based Input Validation**

Create explicit validation schemas defining data types, constraints, and business rules:

```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email('Must be valid email').max(255),
  password: z.string().min(8).regex(/[A-Za-z\d]/),
  name: z.string().min(1).max(100),
  age: z.number().int().min(13).max(120)
});

class UserRepository {
  async create(userData: unknown): Promise<User> {
    // Validate input at boundary
    const validated = CreateUserSchema.parse(userData);

    // Check business rules
    if (await this.emailExists(validated.email)) {
      throw new ValidationError('Email already registered');
    }

    // Transform for database
    const dbData = {
      email: validated.email.toLowerCase(),
      passwordHash: hashPassword(validated.password),
      name: validated.name.trim(),
      age: validated.age
    };

    const result = await this.db.query(/* INSERT query */, Object.values(dbData));
    return this.validateOutput(result.rows[0]);
  }
}
```

**2. Structured Error Handling**

Provide actionable validation feedback:

```typescript
interface ValidationErrorDetail {
  field: string;
  message: string;
  value?: any;
}

class ValidationError extends Error {
  constructor(message: string, public details: ValidationErrorDetail[]) {
    super(message);
  }

  toResponse() {
    return {
      error: 'validation_failed',
      message: this.message,
      details: this.details
    };
  }
}
```

**3. Output Validation**

Validate data retrieved from database:

```typescript
const DatabaseUserSchema = z.object({
  id: z.number().positive(),
  email: z.string().email(),
  name: z.string().min(1),
  created_at: z.date()
});

private validateOutput(dbRow: any): User {
  try {
    const validated = DatabaseUserSchema.parse(dbRow);
    return this.transformToDomain(validated);
  } catch (error) {
    this.logger.error('Data integrity error', { userId: dbRow.id });
    throw new Error(`Corrupted data for user ${dbRow.id}`);
  }
}
```

## Examples

```typescript
// ❌ BAD: No validation, relies on database constraints
class UserRepository {
  async create(userData: any): Promise<User> {
    // Direct database insert without validation
    const result = await this.db.query(
      'INSERT INTO users (email, password, name) VALUES ($1, $2, $3) RETURNING *',
      [userData.email, userData.password, userData.name]
    );
    return result.rows[0]; // Assumes database data is valid
  }
}
```

```typescript
// ✅ GOOD: Comprehensive validation at boundaries
const CreateUserSchema = z.object({
  email: z.string().email('Must be valid email'),
  password: z.string().min(8, 'Password too short'),
  name: z.string().min(1, 'Name required').max(100, 'Name too long')
});

class UserRepository {
  async create(userData: unknown): Promise<User> {
    // Validate input with clear error messages
    const validated = CreateUserSchema.parse(userData);

    // Business rule validation
    if (await this.emailExists(validated.email)) {
      throw new ValidationError('Email already registered');
    }

    // Transform and persist
    const dbData = {
      email: validated.email.toLowerCase(),
      passwordHash: await hashPassword(validated.password),
      name: validated.name.trim()
    };

    const result = await this.db.query(/* INSERT */, Object.values(dbData));
    return this.validateOutput(result.rows[0]); // Validate output
  }
}
```

## Related Bindings

- [input-validation-standards](../../categories/security/input-validation-standards.md): Database boundary validation must coordinate with general input validation to ensure consistent validation approaches across all system entry points.

- [audit-logging-implementation](../../docs/bindings/categories/database/audit-logging-implementation.md): Data validation failures should be logged for security monitoring and compliance, especially when validation failures might indicate malicious input attempts.

- [transaction-management-patterns](../../docs/bindings/categories/database/transaction-management-patterns.md): Validation failures should properly handle transaction rollback to ensure data consistency when validation occurs within database transactions.
