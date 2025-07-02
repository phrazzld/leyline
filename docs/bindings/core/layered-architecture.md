---
id: layered-architecture
last_modified: '2025-06-15'
version: '0.1.0'
derived_from: orthogonality
enforced_by: 'Build system dependencies, architectural linting, code review'
---

# Binding: Implement Layered Architecture with Dependency Flow Control

Organize code into distinct horizontal layers with well-defined responsibilities, where higher-level layers depend on lower-level layers but never vice versa. This creates a clear hierarchy that separates concerns and enables flexible, testable, and maintainable systems.

## Rationale

This binding implements our orthogonality tenet by creating structured separation between different levels of abstraction and responsibility. Layered architecture prevents high-level policy from becoming entangled with low-level implementation details, enabling each layer to evolve independently as long as the interfaces between layers remain stable.

Without layered organization, code becomes a tangled web where business logic depends on database schemas, user interface code contains business rules, and infrastructure concerns are scattered throughout the application. Layered architecture solves these problems by enforcing a discipline where dependencies flow in only one direction, creating stability and flexibility.

## Rule Definition

**MUST** implement these four distinct layers:

**Presentation Layer**: Handles user interface concerns, input/output formatting, and user interaction workflows. Translates between external interfaces and application use cases.

**Application Layer**: Orchestrates business workflows and use cases. Coordinates between domain services and handles application-specific logic like transaction boundaries and security enforcement.

**Domain Layer**: Contains core business logic, entities, and domain services. Encapsulates the essential complexity of the business problem and must be independent of external concerns.

**Infrastructure Layer**: Handles external concerns like databases, file systems, network communication, and third-party integrations. Implements interfaces defined by higher layers.

**MUST** enforce dependency rules:
- Presentation may depend on Application and Domain
- Application may depend on Domain only
- Domain depends on nothing else in the application
- Infrastructure may depend on Domain and Application (to implement their interfaces)
- Dependencies never flow upward or sideways between peer layers

**MUST** ensure each layer has a single, well-defined responsibility with cohesive internals and loose coupling to other layers.

**SHOULD** communicate between layers through explicit interfaces only.

## Practical Implementation

**Start Simple**: Begin with clear separation of concerns before introducing complex patterns.

**Interface-Driven Design**: Define interfaces in higher layers that lower layers implement.

**Dependency Injection**: Use dependency injection to connect layers without creating tight coupling.

**Test Boundaries**: Each layer should be testable in isolation from others.

**Avoid Cross-Layer Calls**: Never skip layers or create backdoor dependencies.

## Implementation Examples

**❌ Tangled Architecture:**
```typescript
class UserService {
  async registerUser(userData: any) {
    if (!userData.email?.includes('@')) throw new Error('Invalid email');
    const user = await db.query('INSERT INTO users...', userData);
    await sendEmail(user.email, 'Welcome!');
    return { message: 'User created successfully' };
  }
}
```

**✅ Layered Architecture:**
```typescript
// Domain Layer - Pure business logic
interface User { id: string; email: string; username: string; }
interface UserRepository { save(user: User): Promise<User>; }

class UserDomainService {
  validateUser(email: string): void {
    if (!email.includes('@')) throw new Error('Invalid email');
  }
  createUser(email: string, username: string): User {
    this.validateUser(email);
    return { id: crypto.randomUUID(), email, username };
  }
}

// Application Layer - Orchestrates workflows
class UserApplicationService {
  constructor(private userRepo: UserRepository, private userDomain: UserDomainService) {}

  async registerUser(email: string, username: string): Promise<string> {
    const user = this.userDomain.createUser(email, username);
    await this.userRepo.save(user);
    return user.id;
  }
}

// Infrastructure Layer - External concerns
class DatabaseUserRepository implements UserRepository {
  async save(user: User): Promise<User> {
    await this.db.query('INSERT INTO users...', [user.id, user.email]);
    return user;
  }
}

// Presentation Layer - HTTP concerns
class UserController {
  constructor(private userService: UserApplicationService) {}

  async register(req: Request, res: Response): Promise<void> {
    const { email, username } = req.body;
    const userId = await this.userService.registerUser(email, username);
    res.status(201).json({ userId });
  }
}
```

## Layer Testing Strategy

**Domain Layer:** Pure unit tests with no mocks
**Application Layer:** Mock external dependencies
**Infrastructure Layer:** Integration tests with real external systems
**Presentation Layer:** Test HTTP request/response handling

```typescript
// Domain - Pure unit tests
test('validates email format', () => {
  const userDomain = new UserDomainService();
  expect(() => userDomain.validateUser('invalid')).toThrow('Invalid email');
});

// Application - Mock dependencies
test('registers new user', async () => {
  const mockRepo = { save: jest.fn() };
  const service = new UserApplicationService(mockRepo, mockDomain);
  await service.registerUser('test@example.com', 'user');
  expect(mockRepo.save).toHaveBeenCalled();
});
```

## Common Anti-Patterns

❌ **Layer Skipping:** Presentation calling Infrastructure directly
❌ **Circular Dependencies:** Lower layers depending on higher layers
❌ **Anemic Domain:** Domain with only data, no business logic
❌ **Fat Controllers:** Business logic in Presentation layer
❌ **Leaky Abstractions:** Infrastructure concerns in Domain

## When to Use

**Good Fit:** Complex business logic, high testability needs, multiple integrations
**Poor Fit:** Simple CRUD apps, high-performance systems, small applications

**Evolution:** Start minimal, measure impact, refactor boundaries as needed

## Related Bindings

- [dependency-inversion](../../docs/bindings/core/dependency-inversion.md): Dependency management for layer isolation
- [interface-contracts](../../docs/bindings/core/interface-contracts.md): Clean layer boundaries
- [component-isolation](../../docs/bindings/core/component-isolation.md): Component separation principles
