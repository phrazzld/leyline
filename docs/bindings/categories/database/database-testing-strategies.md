---
id: database-testing-strategies
last_modified: '2025-01-12'
version: '0.2.0'
derived_from: testability
enforced_by: test coverage tools & CI pipeline
---

# Binding: Design Database Code for Comprehensive Testing

All database interactions must be designed and structured to enable reliable,
isolated, and maintainable testing. Create clear boundaries between database
logic and business logic, manage test data systematically, and ensure database
tests are fast, predictable, and independent.

## Rationale

Database interactions are complex and error-prone, requiring systematic testing at multiple levels. Poor database testing creates flaky tests and production bugs. Proper separation of database logic from business logic enables isolated unit testing, while systematic test data management ensures predictable, fast tests.

## Rule Definition

**Core Requirements:**
- **Layer Separation**: Isolate database access code from business logic via repository interfaces
- **Test Data Management**: Systematic creation, cleanup, and isolation using fixtures
- **Transaction Isolation**: Each test runs in isolated transactions with automatic rollback
- **Fast Feedback**: Unit tests with mocks, integration tests with test databases
- **Predictable State**: Tests produce consistent results regardless of execution order

**Required Patterns:**
- Repository pattern with clear interfaces for mocking
- Test fixtures with automated setup/teardown
- Transaction rollback for test isolation
- Multi-level testing (unit with mocks, integration with real DB)

**Prohibited Patterns:**
- Database logic mixed with business logic
- Tests depending on specific database state or execution order
- Shared test data creating unpredictable results
- Manual setup/cleanup requirements

## Practical Implementation

**Repository Pattern with Testable Interfaces:**
```typescript
interface UserRepository {
  findById(id: number): Promise<User | null>;
  create(userData: CreateUserData): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
}

class DatabaseUserRepository implements UserRepository {
  constructor(private db: Database) {}

  async findById(id: number): Promise<User | null> {
    const result = await this.db.query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0] ? this.mapToUser(result.rows[0]) : null;
  }

  async create(userData: CreateUserData): Promise<User> {
    const result = await this.db.query(
      'INSERT INTO users (email, name) VALUES ($1, $2) RETURNING *',
      [userData.email, userData.name]
    );
    return this.mapToUser(result.rows[0]);
  }

  private mapToUser(row: any): User {
    return { id: row.id, email: row.email, name: row.name };
  }
}

class UserService {
  constructor(private userRepo: UserRepository) {}

  async registerUser(email: string, name: string): Promise<User> {
    const existing = await this.userRepo.findByEmail(email);
    if (existing) throw new Error('User already exists');
    return this.userRepo.create({ email, name });
  }
}
```

**Test Data Factories and Fixtures:**
```typescript
class UserTestFactory {
  static createTestUser(overrides = {}): CreateUserData {
    return { email: `test-${Date.now()}@example.com`, name: 'Test User', ...overrides };
  }
}

class DatabaseFixture {
  constructor(private db: Database) {}

  async setup(): Promise<void> { await this.db.query('BEGIN'); }
  async teardown(): Promise<void> { await this.db.query('ROLLBACK'); }
}
```

**Multi-Level Testing Strategy:**
```typescript
// Unit test with mocks
describe('UserService', () => {
  let userService: UserService;
  let mockRepo: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepo = { findById: jest.fn(), create: jest.fn(), findByEmail: jest.fn() };
    userService = new UserService(mockRepo);
  });

  it('should register new user', async () => {
    mockRepo.findByEmail.mockResolvedValue(null);
    mockRepo.create.mockResolvedValue({ id: 1, email: 'test@example.com', name: 'Test' });

    const result = await userService.registerUser('test@example.com', 'Test');
    expect(result.email).toBe('test@example.com');
  });
});

// Integration test with real database
describe('DatabaseUserRepository', () => {
  let fixture: DatabaseFixture;
  let repository: DatabaseUserRepository;

  beforeEach(async () => {
    fixture = new DatabaseFixture(testDb);
    await fixture.setup();
    repository = new DatabaseUserRepository(testDb);
  });

  afterEach(async () => { await fixture.teardown(); });

  it('should create and retrieve user', async () => {
    const userData = UserTestFactory.createTestUser();
    const created = await repository.create(userData);
    const retrieved = await repository.findById(created.id);
    expect(retrieved).toEqual(created);
  });
});
```

## Examples

```typescript
// ❌ BAD: Database logic mixed with business logic, untestable
class UserController {
  async registerUser(req: Request, res: Response) {
    const existingUser = await db.query('SELECT * FROM users WHERE email = $1', [req.body.email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'User exists' });
    }
    const result = await db.query('INSERT INTO users (email, name) VALUES ($1, $2) RETURNING *',
      [req.body.email, req.body.name]);
    res.json(result.rows[0]);
  }
}

// ✅ GOOD: Layered architecture with testable components
class UserService {
  constructor(private userRepo: UserRepository) {}

  async registerUser(email: string, name: string): Promise<User> {
    const existing = await this.userRepo.findByEmail(email);
    if (existing) throw new UserAlreadyExistsError('User already exists');
    return this.userRepo.create({ email, name });
  }
}

class UserController {
  constructor(private userService: UserService) {}

  async registerUser(req: Request, res: Response) {
    try {
      const user = await this.userService.registerUser(req.body.email, req.body.name);
      res.json(user);
    } catch (error) {
      res.status(error instanceof UserAlreadyExistsError ? 400 : 500)
         .json({ error: error.message });
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
