---
id: dependency-injection-patterns
last_modified: '2025-06-03'
version: '0.1.0'
derived_from: orthogonality
enforced_by: 'Go interfaces, constructor functions, dependency injection frameworks, code review'
---

# Binding: Design Modular Systems Through Go's Interface-Based Dependency Injection

Use Go's interface system and constructor patterns to create loosely coupled, testable components that depend on abstractions rather than concrete implementations. Proper dependency injection enables component independence while maintaining clear boundaries and making testing straightforward.

## Rationale

This binding implements our orthogonality tenet by using Go's interface system to create truly independent components that can be developed, tested, and modified without affecting each other. Dependency injection allows you to compose functionality from independent parts while keeping those parts loosely coupled.

Like electrical components with standardized connectors, Go structs declare needed interfaces without caring about specific implementations. This flexibility enables swapping implementations, easy testing, and component reuse. Without dependency injection, components become hardwired together, making testing difficult and changes expensive.

## Rule Definition

Dependency injection patterns must establish these Go-specific practices:

- **Interface-Based Dependencies**: Define interfaces for all external dependencies and inject implementations through constructors. Components should depend on interfaces, not concrete types.
- **Constructor Injection**: Use constructor functions that accept dependencies as parameters, making all dependencies explicit and ensuring components are fully initialized when created.
- **Interface Segregation**: Design focused interfaces that represent single capabilities rather than large, monolithic interfaces. This allows components to depend only on the functionality they actually use.
- **Dependency Inversion**: High-level modules should not depend on low-level modules. Both should depend on abstractions (interfaces) that the high-level modules define.

Common patterns this binding requires:

- Small, focused interfaces with single responsibilities
- Constructor functions that accept all dependencies as parameters
- Dependency interfaces defined by consumers, not providers
- Clear separation between interface definitions and implementations
- Composition over inheritance through interface embedding

What this explicitly prohibits:

- Direct instantiation of dependencies within structs
- Large, monolithic interfaces with multiple responsibilities
- Circular dependencies between packages
- Global variables or singletons for managing dependencies
- Constructor functions that hide dependency requirements

## Practical Implementation

1. **Define Consumer-Driven Interfaces**: Create small, focused interfaces for each capability.

   ```go
   type UserRepository interface {
       Create(ctx context.Context, user *User) error
       GetByID(ctx context.Context, id string) (*User, error)
   }

   type NotificationSender interface {
       SendWelcomeEmail(ctx context.Context, user *User) error
   }

   type PasswordHasher interface {
       Hash(password string) (string, error)
   }

   type UserService struct {
       repo   UserRepository
       notify NotificationSender
       hasher PasswordHasher
   }

   func NewUserService(repo UserRepository, notify NotificationSender, hasher PasswordHasher) *UserService {
       return &UserService{repo: repo, notify: notify, hasher: hasher}
   }

   func (s *UserService) RegisterUser(ctx context.Context, email, password string) error {
       hashedPassword, err := s.hasher.Hash(password)
       if err != nil {
           return fmt.Errorf("password hashing failed: %w", err)
       }

       user := &User{ID: generateID(), Email: email, Password: hashedPassword}
       if err := s.repo.Create(ctx, user); err != nil {
           return fmt.Errorf("user creation failed: %w", err)
       }

       if err := s.notify.SendWelcomeEmail(ctx, user); err != nil {
           log.Printf("Failed to send welcome email: %v", err)
       }
       return nil
   }
   ```

2. **Implement Provider Structs**: Create concrete implementations.

   ```go
   type PostgresUserRepository struct {
       db *sql.DB
   }

   func NewPostgresUserRepository(db *sql.DB) *PostgresUserRepository {
       return &PostgresUserRepository{db: db}
   }

   func (r *PostgresUserRepository) Create(ctx context.Context, user *User) error {
       _, err := r.db.ExecContext(ctx,
           "INSERT INTO users (id, email, password) VALUES ($1, $2, $3)",
           user.ID, user.Email, user.Password)
       return err
   }

   type EmailNotificationSender struct {
       client EmailClient
   }

   func (e *EmailNotificationSender) SendWelcomeEmail(ctx context.Context, user *User) error {
       return e.client.SendEmail(ctx, EmailMessage{
           To: user.Email, Subject: "Welcome!", Body: "Welcome to our service!",
       })
   }
   ```

3. **Wire Dependencies**: Compose application by injecting dependencies through constructors.

   ```go
   func main() {
       db, _ := sql.Open("postgres", os.Getenv("DATABASE_URL"))
       defer db.Close()

       userRepo := NewPostgresUserRepository(db)
       emailSender := NewEmailNotificationSender(NewSMTPClient())
       passwordHasher := NewBcryptPasswordHasher(12)

       userService := NewUserService(userRepo, emailSender, passwordHasher)
       userHandler := NewUserHandler(userService)

       http.Handle("/users", userHandler)
       log.Fatal(http.ListenAndServe(":8080", nil))
   }
   ```

## Examples

```go
// ❌ BAD: Direct dependencies, untestable
type UserService struct {
    db     *sql.DB
    mailer *smtp.Client
}

func NewUserService() *UserService {
    db, _ := sql.Open("postgres", "production-db-url") // Hidden dependency
    mailer, _ := smtp.Dial("smtp.production.com:587")  // Hard to test
    return &UserService{db: db, mailer: mailer}
}

// ✅ GOOD: Interface-based dependencies, testable
type UserRepository interface {
    Create(ctx context.Context, user *User) error
}

type EmailSender interface {
    SendWelcome(ctx context.Context, email string) error
}

type UserService struct {
    repo   UserRepository
    sender EmailSender
}

func NewUserService(repo UserRepository, sender EmailSender) *UserService {
    return &UserService{repo: repo, sender: sender} // Dependencies explicit
}

// Easy to test with mocks
func TestUserService(t *testing.T) {
    service := NewUserService(&MockRepo{}, &MockSender{})
    err := service.CreateUser(context.Background(), "test@example.com")
    assert.NoError(t, err)
}
```

## Related Bindings

- [interface-design](../../docs/bindings/categories/go/interface-design.md): Dependency injection requires well-designed interfaces that follow the Interface Segregation Principle and represent single capabilities rather than large, monolithic contracts.

- [package-design](../../docs/bindings/categories/go/package-design.md): Effective dependency injection depends on proper package structure that avoids circular dependencies and places interface definitions in appropriate packages.

- [no-internal-mocking](../../core/no-internal-mocking.md): Dependency injection enables testing without internal mocking by making all external dependencies explicit and replaceable through interfaces.
