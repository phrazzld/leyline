---
id: data-validation-at-boundaries
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: modularity
enforced_by: input validation frameworks & code review
---

# Binding: Validate Data Explicitly at Database Boundaries

All data crossing database boundaries must be explicitly validated by the
responsible module before persistence operations and after retrieval operations.
Each module must own its validation logic completely, without depending on
other modules or database constraints to ensure data integrity.

## Rationale

This binding directly implements our modularity tenet by ensuring that each
module takes complete responsibility for the validity of data at its database
boundaries. Just as good modules have clear, well-defined interfaces with
explicit contracts, database operations must have explicit validation that
makes data requirements visible and enforceable at the code level.

Like customs at international borders, each module is responsible for checking what enters and leaves its territory, regardless of what other modules might have done. You can't rely on previous modules to have properly validated data—you must validate everything that crosses your database boundary according to your own standards and requirements. This creates clear, defensible boundaries that prevent invalid data from corrupting your system.

Database constraints provide important backup protection, but they're not sufficient for proper boundary validation. They typically provide cryptic error messages, limited validation logic, and can't handle complex business rules. Explicit validation at the code level provides clear error messages, comprehensive business logic validation, and maintainable, testable validation rules that evolve with your requirements.

## Rule Definition

Data validation at boundaries means implementing comprehensive, explicit validation logic that ensures data integrity before it enters the database and after it's retrieved. This requires validation layers that understand business rules, provide clear error messages, and maintain data consistency across all operations.

Key principles for boundary validation:

- **Input Validation**: All data entering the database must be validated for type safety, business rules, and constraints before persistence
- **Output Validation**: Data retrieved from the database should be validated to ensure it meets current business rules and hasn't been corrupted
- **Business Rule Enforcement**: Validation logic implements business rules that may be too complex for database constraints
- **Clear Error Messages**: Validation failures provide actionable error messages that help users correct their input
- **Fail-Fast Principle**: Invalid data is rejected as early as possible in the processing pipeline

Common patterns this binding requires:

- Input validation schemas with type checking and business rule validation
- Validation layers that run before database operations
- Structured error responses that identify specific validation failures
- Data sanitization and normalization before persistence
- Validation of retrieved data against current business rules

What this explicitly prohibits:

- Relying solely on database constraints for data validation
- Allowing invalid data to reach database operations
- Validation logic scattered across multiple modules or layers
- Generic error messages that don't help users correct problems
- Bypassing validation for "trusted" data sources

## Practical Implementation

1. **Implement Schema-Based Input Validation**: Create explicit validation
   schemas that define data types, constraints, and business rules for all
   data entering the database.

   ```typescript
   // User registration data validation schema
   import { z } from 'zod';

   const CreateUserSchema = z.object({
     email: z.string()
       .email('Must be a valid email address')
       .max(255, 'Email must be less than 255 characters'),

     password: z.string()
       .min(8, 'Password must be at least 8 characters')
       .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
       .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
       .regex(/[0-9]/, 'Password must contain at least one number'),

     name: z.string()
       .min(1, 'Name is required')
       .max(100, 'Name must be less than 100 characters')
       .regex(/^[a-zA-Z\s'-]+$/, 'Name can only contain letters, spaces, hyphens, and apostrophes'),

     age: z.number()
       .int('Age must be a whole number')
       .min(13, 'Must be at least 13 years old')
       .max(120, 'Age must be realistic'),

     terms_accepted: z.boolean()
       .refine(val => val === true, 'Must accept terms and conditions')
   });

   type CreateUserData = z.infer<typeof CreateUserSchema>;

   // Repository with validation boundary
   class UserRepository {
     async create(userData: unknown): Promise<User> {
       // Validate input data at boundary
       const validatedData = this.validateCreateUserData(userData);

       // Additional business rule validation
       await this.validateBusinessRules(validatedData);

       // Transform data for persistence
       const dbData = this.transformForDatabase(validatedData);

       // Persist to database
       const result = await this.db.query(
         'INSERT INTO users (email, password_hash, name, age, created_at) VALUES ($1, $2, $3, $4, $5) RETURNING *',
         [dbData.email, dbData.passwordHash, dbData.name, dbData.age, new Date()]
       );

       // Validate output data from database
       return this.validateAndTransformUser(result.rows[0]);
     }

     private validateCreateUserData(data: unknown): CreateUserData {
       try {
         return CreateUserSchema.parse(data);
       } catch (error) {
         if (error instanceof z.ZodError) {
           throw new ValidationError('Invalid user data', error.errors.map(err => ({
             field: err.path.join('.'),
             message: err.message,
             value: err.input
           })));
         }
         throw error;
       }
     }

     private async validateBusinessRules(data: CreateUserData): Promise<void> {
       // Check for duplicate email
       const existingUser = await this.findByEmail(data.email);
       if (existingUser) {
         throw new ValidationError('Business rule violation', [{
           field: 'email',
           message: 'Email address is already registered',
           value: data.email
         }]);
       }

       // Additional business rules
       if (data.age < 18 && !await this.hasParentalConsent(data.email)) {
         throw new ValidationError('Business rule violation', [{
           field: 'age',
           message: 'Users under 18 require parental consent',
           value: data.age
         }]);
       }
     }

     private transformForDatabase(data: CreateUserData): DatabaseUser {
       return {
         email: data.email.toLowerCase(), // Normalize email
         passwordHash: hashPassword(data.password), // Hash password
         name: data.name.trim(), // Sanitize name
         age: data.age
       };
     }
   }
   ```

2. **Create Structured Validation Error Handling**: Implement comprehensive
   error handling that provides actionable feedback for validation failures.

   ```typescript
   // Structured validation error types
   interface ValidationErrorDetail {
     field: string;
     message: string;
     value?: any;
     code?: string;
   }

   class ValidationError extends Error {
     constructor(
       message: string,
       public details: ValidationErrorDetail[]
     ) {
       super(message);
       this.name = 'ValidationError';
     }

     toResponse() {
       return {
         error: 'validation_failed',
         message: this.message,
         details: this.details
       };
     }
   }

   // Service layer with comprehensive validation
   class UserService {
     constructor(private userRepo: UserRepository) {}

     async registerUser(requestData: unknown): Promise<User> {
       try {
         return await this.userRepo.create(requestData);
       } catch (error) {
         if (error instanceof ValidationError) {
           // Log validation failure for monitoring
           this.logger.warn('User registration validation failed', {
             details: error.details,
             timestamp: new Date().toISOString()
           });
           throw error; // Re-throw for API layer
         }

         // Handle unexpected errors
         this.logger.error('Unexpected error during user registration', error);
         throw new Error('Registration failed due to system error');
       }
     }
   }

   // API layer with validation error responses
   class UserController {
     async register(req: Request, res: Response) {
       try {
         const user = await this.userService.registerUser(req.body);
         res.status(201).json({
           success: true,
           user: {
             id: user.id,
             email: user.email,
             name: user.name
           }
         });
       } catch (error) {
         if (error instanceof ValidationError) {
           res.status(400).json(error.toResponse());
         } else {
           res.status(500).json({
             error: 'internal_server_error',
             message: 'An unexpected error occurred'
           });
         }
       }
     }
   }
   ```

3. **Implement Output Validation and Data Integrity Checks**: Validate data
   retrieved from the database to ensure it meets current business rules and
   hasn't been corrupted.

   ```typescript
   // Database result validation schema
   const DatabaseUserSchema = z.object({
     id: z.number().int().positive(),
     email: z.string().email(),
     password_hash: z.string().min(1),
     name: z.string().min(1),
     age: z.number().int().min(13).max(120),
     created_at: z.date(),
     updated_at: z.date().optional()
   });

   class UserRepository {
     async findById(id: number): Promise<User | null> {
       const result = await this.db.query(
         'SELECT * FROM users WHERE id = $1',
         [id]
       );

       if (result.rows.length === 0) {
         return null;
       }

       // Validate database result
       return this.validateAndTransformUser(result.rows[0]);
     }

     private validateAndTransformUser(dbRow: any): User {
       try {
         // Validate database result against schema
         const validatedData = DatabaseUserSchema.parse({
           ...dbRow,
           created_at: new Date(dbRow.created_at),
           updated_at: dbRow.updated_at ? new Date(dbRow.updated_at) : undefined
         });

         // Transform to domain model
         return {
           id: validatedData.id,
           email: validatedData.email,
           name: validatedData.name,
           age: validatedData.age,
           createdAt: validatedData.created_at,
           updatedAt: validatedData.updated_at
         };
       } catch (error) {
         if (error instanceof z.ZodError) {
           // Log data corruption issue
           this.logger.error('Database data validation failed', {
             userId: dbRow.id,
             errors: error.errors,
             rawData: dbRow
           });

           throw new Error(`Data integrity error for user ${dbRow.id}`);
         }
         throw error;
       }
     }

     async updateUser(id: number, updates: Partial<CreateUserData>): Promise<User> {
       // Validate input updates
       const validatedUpdates = this.validateUserUpdates(updates);

       // Fetch current user for validation
       const currentUser = await this.findById(id);
       if (!currentUser) {
         throw new Error('User not found');
       }

       // Validate business rules for updates
       await this.validateUpdateBusinessRules(currentUser, validatedUpdates);

       // Perform update
       const result = await this.db.query(
         'UPDATE users SET email = $2, name = $3, age = $4, updated_at = $5 WHERE id = $1 RETURNING *',
         [id, validatedUpdates.email, validatedUpdates.name, validatedUpdates.age, new Date()]
       );

       return this.validateAndTransformUser(result.rows[0]);
     }
   }
   ```

## Examples

```typescript
// ❌ BAD: No validation, relies on database constraints
class UserRepository {
  async create(userData: any): Promise<User> {
    // No input validation - data goes directly to database
    const result = await this.db.query(
      'INSERT INTO users (email, password, name) VALUES ($1, $2, $3) RETURNING *',
      [userData.email, userData.password, userData.name]
    );

    // No output validation - assumes database data is valid
    return result.rows[0];
  }
}
```

```typescript
// ✅ GOOD: Comprehensive validation at boundaries
const CreateUserSchema = z.object({
  email: z.string().email('Must be a valid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required').max(100, 'Name too long')
});

class UserRepository {
  async create(userData: unknown): Promise<User> {
    // Validate input data with clear error messages
    const validatedData = CreateUserSchema.parse(userData);

    // Additional business rule validation
    const existingUser = await this.findByEmail(validatedData.email);
    if (existingUser) {
      throw new ValidationError('Email already registered');
    }

    // Transform and sanitize for database
    const dbData = {
      email: validatedData.email.toLowerCase(),
      passwordHash: await hashPassword(validatedData.password),
      name: validatedData.name.trim()
    };

    const result = await this.db.query(
      'INSERT INTO users (email, password_hash, name, created_at) VALUES ($1, $2, $3, $4) RETURNING *',
      [dbData.email, dbData.passwordHash, dbData.name, new Date()]
    );

    // Validate output data from database
    return this.validateAndTransformUser(result.rows[0]);
  }
}
```

## Related Bindings

- [input-validation-standards](../../categories/security/input-validation-standards.md): Database boundary validation must coordinate with general input validation to ensure consistent validation approaches across all system entry points.

- [audit-logging-implementation](./audit-logging-implementation.md): Data validation failures should be logged for security monitoring and compliance, especially when validation failures might indicate malicious input attempts.

- [transaction-management-patterns](./transaction-management-patterns.md): Validation failures should properly handle transaction rollback to ensure data consistency when validation occurs within database transactions.
