---
id: database-testing-strategies
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: testability
enforced_by: test coverage tools & CI pipeline
---

# Binding: Design Database Code for Comprehensive Testing

All database interactions must be designed and structured to enable reliable,
isolated, and maintainable testing. Create clear boundaries between database
logic and business logic, manage test data systematically, and ensure database
tests are fast, predictable, and independent.

## Rationale

This binding directly implements our testability tenet by ensuring that database
code follows the same principles of testable design as any other component.
Database interactions are often the most complex and error-prone parts of
applications, making comprehensive testing absolutely critical for system
reliability. When database code is designed for testability from the beginning,
it naturally becomes more modular, maintainable, and robust.

Like testing electrical circuits, you need to test database components in isolation (unit testing), verify components work together (integration testing), and ensure performance under load. You wouldn't build complex circuits without testing each part independently, and you shouldn't build database-dependent code without clear testing strategies for each layer.

The challenge is that databases are stateful, shared resources that can create unpredictable test conditions. Poor database testing leads to flaky tests, slow test suites, and production bugs that only surface under specific data conditions. Systematic database testing strategies isolate tests from each other, provide consistent test data, and make database behavior predictable and verifiable.

## Rule Definition

Comprehensive database testing means systematically validating database interactions
at multiple levels while maintaining test isolation, speed, and reliability. This
requires explicit strategies for test data management, transaction boundaries,
and separation of database logic from business logic.

Key principles for testable database code:

- **Layer Separation**: Isolate database access code from business logic to enable independent testing
- **Test Data Management**: Systematic creation, cleanup, and isolation of test data
- **Transaction Isolation**: Each test runs in isolated transactions that don't affect other tests
- **Fast Feedback**: Database tests provide rapid feedback without requiring full database setup
- **Predictable State**: Tests produce consistent results regardless of execution order

Common patterns this binding requires:

- Repository pattern or data access layer with clear interfaces
- Test database fixtures with automated setup and teardown
- Transaction rollback strategies for test isolation
- In-memory database options for fast unit testing
- Comprehensive integration testing with real database

What this explicitly prohibits:

- Database logic mixed with business logic in untestable ways
- Tests that depend on specific database state or execution order
- Shared test data that creates unpredictable test results
- Database tests that require manual setup or cleanup
- Missing test coverage for critical database operations

## Practical Implementation

1. **Implement Repository Pattern with Testable Interfaces**: Create clear
   boundaries between database access and business logic through repository
   interfaces that can be easily mocked or replaced with test implementations.

   ```typescript
   // Database repository interface for testability
   interface UserRepository {
     findById(id: number): Promise<User | null>;
     create(userData: CreateUserData): Promise<User>;
     update(id: number, updates: Partial<User>): Promise<User>;
     delete(id: number): Promise<void>;
     findByEmail(email: string): Promise<User | null>;
   }

   // Production database implementation
   class DatabaseUserRepository implements UserRepository {
     constructor(private db: Database) {}

     async findById(id: number): Promise<User | null> {
       const result = await this.db.query(
         'SELECT * FROM users WHERE id = $1',
         [id]
       );
       return result.rows[0] ? this.mapToUser(result.rows[0]) : null;
     }

     async create(userData: CreateUserData): Promise<User> {
       const result = await this.db.query(
         'INSERT INTO users (email, name, created_at) VALUES ($1, $2, $3) RETURNING *',
         [userData.email, userData.name, new Date()]
       );
       return this.mapToUser(result.rows[0]);
     }

     private mapToUser(row: any): User {
       return {
         id: row.id,
         email: row.email,
         name: row.name,
         createdAt: row.created_at
       };
     }
   }

   // Business logic service with testable dependencies
   class UserService {
     constructor(private userRepo: UserRepository) {}

     async registerUser(email: string, name: string): Promise<User> {
       const existing = await this.userRepo.findByEmail(email);
       if (existing) {
         throw new Error('User already exists');
       }

       return this.userRepo.create({ email, name });
     }
   }
   ```

2. **Design Test Data Factories and Fixtures**: Create systematic approaches
   for generating and managing test data that ensure test isolation and
   predictable test conditions.

   ```typescript
   // Test data factory for consistent test scenarios
   class UserTestFactory {
     static createTestUser(overrides: Partial<CreateUserData> = {}): CreateUserData {
       return {
         email: `test-${Date.now()}@example.com`,
         name: 'Test User',
         ...overrides
       };
     }

     static async createUserInDb(
       repo: UserRepository,
       overrides: Partial<CreateUserData> = {}
     ): Promise<User> {
       const userData = this.createTestUser(overrides);
       return repo.create(userData);
     }
   }

   // Database fixture management for integration tests
   class DatabaseFixture {
     constructor(private db: Database) {}

     async setup(): Promise<void> {
       // Start transaction for test isolation
       await this.db.query('BEGIN');
     }

     async teardown(): Promise<void> {
       // Rollback transaction to clean up test data
       await this.db.query('ROLLBACK');
     }

     async createUser(overrides: Partial<CreateUserData> = {}): Promise<User> {
       const userData = UserTestFactory.createTestUser(overrides);
       const result = await this.db.query(
         'INSERT INTO users (email, name, created_at) VALUES ($1, $2, $3) RETURNING *',
         [userData.email, userData.name, new Date()]
       );
       return {
         id: result.rows[0].id,
         email: result.rows[0].email,
         name: result.rows[0].name,
         createdAt: result.rows[0].created_at
       };
     }
   }
   ```

3. **Implement Multi-Level Testing Strategy**: Create comprehensive test
   coverage through unit tests with mocks, integration tests with test
   databases, and performance tests with realistic data volumes.

   ```typescript
   // Unit tests with mocked repository
   describe('UserService', () => {
     let userService: UserService;
     let mockRepo: jest.Mocked<UserRepository>;

     beforeEach(() => {
       mockRepo = {
         findById: jest.fn(),
         create: jest.fn(),
         update: jest.fn(),
         delete: jest.fn(),
         findByEmail: jest.fn(),
       };
       userService = new UserService(mockRepo);
     });

     it('should register new user successfully', async () => {
       mockRepo.findByEmail.mockResolvedValue(null);
       mockRepo.create.mockResolvedValue({
         id: 1,
         email: 'test@example.com',
         name: 'Test User',
         createdAt: new Date()
       });

       const result = await userService.registerUser('test@example.com', 'Test User');

       expect(result.email).toBe('test@example.com');
       expect(mockRepo.findByEmail).toHaveBeenCalledWith('test@example.com');
       expect(mockRepo.create).toHaveBeenCalledWith({
         email: 'test@example.com',
         name: 'Test User'
       });
     });

     it('should throw error for duplicate email', async () => {
       mockRepo.findByEmail.mockResolvedValue({
         id: 1,
         email: 'test@example.com',
         name: 'Existing User',
         createdAt: new Date()
       });

       await expect(
         userService.registerUser('test@example.com', 'Test User')
       ).rejects.toThrow('User already exists');
     });
   });

   // Integration tests with real database
   describe('DatabaseUserRepository Integration', () => {
     let fixture: DatabaseFixture;
     let repository: DatabaseUserRepository;

     beforeEach(async () => {
       fixture = new DatabaseFixture(testDb);
       await fixture.setup();
       repository = new DatabaseUserRepository(testDb);
     });

     afterEach(async () => {
       await fixture.teardown();
     });

     it('should create and retrieve user', async () => {
       const userData = UserTestFactory.createTestUser();
       const created = await repository.create(userData);

       expect(created.id).toBeDefined();
       expect(created.email).toBe(userData.email);

       const retrieved = await repository.findById(created.id);
       expect(retrieved).toEqual(created);
     });

     it('should return null for non-existent user', async () => {
       const result = await repository.findById(99999);
       expect(result).toBeNull();
     });
   });
   ```

## Examples

```typescript
// ❌ BAD: Database logic mixed with business logic, untestable
class UserController {
  async registerUser(req: Request, res: Response) {
    // Direct database access in controller
    const existingUser = await db.query('SELECT * FROM users WHERE email = $1', [req.body.email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User exists' });
    }

    // Complex business logic mixed with database operations
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    const result = await db.query(
      'INSERT INTO users (email, password, name, created_at) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.body.email, hashedPassword, req.body.name, new Date()]
    );

    res.json(result.rows[0]);
  }
}
```

```typescript
// ✅ GOOD: Layered architecture with testable components
interface UserRepository {
  findByEmail(email: string): Promise<User | null>;
  create(userData: CreateUserData): Promise<User>;
}

class UserService {
  constructor(
    private userRepo: UserRepository,
    private passwordHash: PasswordHasher
  ) {}

  async registerUser(email: string, password: string, name: string): Promise<User> {
    const existing = await this.userRepo.findByEmail(email);
    if (existing) {
      throw new UserAlreadyExistsError('User with this email already exists');
    }

    const hashedPassword = await this.passwordHash.hash(password);
    return this.userRepo.create({
      email,
      password: hashedPassword,
      name
    });
  }
}

class UserController {
  constructor(private userService: UserService) {}

  async registerUser(req: Request, res: Response) {
    try {
      const user = await this.userService.registerUser(
        req.body.email,
        req.body.password,
        req.body.name
      );
      res.json(user);
    } catch (error) {
      if (error instanceof UserAlreadyExistsError) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
}
```

## Related Bindings

- [test-pyramid-implementation](../../core/test-pyramid-implementation.md): Database
  testing must follow the test pyramid pattern with more unit tests using mocks,
  fewer integration tests with real databases, and minimal end-to-end tests for
  critical user journeys.

- [test-data-management](../../core/test-data-management.md): Database testing
  requires systematic test data creation, cleanup, and isolation strategies to
  ensure tests are predictable and don't interfere with each other.

- [transaction-management-patterns](../../docs/bindings/categories/database/transaction-management-patterns.md): Database
  testing must understand and properly handle transaction boundaries to ensure
  test isolation and accurate testing of rollback scenarios.
