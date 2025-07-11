---
derived_from: testability
enforced_by: code review & linting
id: interface-design
last_modified: '2025-05-14'
version: '0.2.0'
---
# Binding: Design Small, Focused Interfaces in Consumer Packages

In Go, define interfaces where they are used (consumer packages), not where they are implemented. Keep interfaces small and focused, preferably with only 1-3 methods, and design them based on the specific behaviors required by the consuming code rather than an implementation's capabilities.

## Rationale

Small, consumer-defined interfaces enable testability by creating natural seams for substituting implementations without complex mocking. They act as adapters specifying only needed behavior, rather than forcing implementations to conform to large contracts.

When requirements change, small interfaces affect only immediate areas while keeping the rest stable. "The bigger the interface, the weaker the abstraction"—larger interfaces create rigid, brittle connections.

## Rule Definition

**Requirements:**

- **Consumer Ownership**: Define interfaces in consuming packages, not implementation packages
- **Small & Focused**: 1-3 methods maximum; compose larger interfaces from smaller ones
- **Behavior Names**: Use `-er` suffix (Reader, Writer, Validator); describe behavior, not implementation
- **Implicit Implementation**: Use compile-time checks; return concrete types, accept interfaces
- **Avoid Empty Interface**: Minimize `interface{}`/`any`; prefer generics for type-safe polymorphism

## Practical Implementation

1. **Point of Use**: Place interfaces in consuming packages
2. **Compliance**: Use compile-time checks: `var _ Interface = (*ConcreteType)(nil)`
3. **Composable**: Break complex behaviors into small, composable interfaces
4. **Accept/Return**: Accept interfaces, return concrete types
5. **Type Safety**: Use generics instead of `interface{}` when possible

## Examples

```go
// ✅ GOOD: Small, focused interfaces per use case
type UserAuthenticator interface { // Package: internal/auth
    FindByEmail(email string) (*User, error)
    UpdatePassword(id string, password string) error
}

type UserManager interface { // Package: internal/user/admin
    FindByID(id string) (*User, error)
    Create(user *User) error
}

type RoleBasedUserFinder interface { // Package: internal/rbac
    FindByRole(role string) ([]*User, error)
}
```

```go
// ✅ GOOD: Interface defined in consumer package
package notification

// EmailSender defines the contract for sending emails.
// This is defined here because the notification package consumes this behavior.
type EmailSender interface {
    SendEmail(to string, subject string, body string) error
}

// Service sends notifications through various channels.
type Service struct {
    emailSender EmailSender
}

// NewService creates a notification service with the given dependencies.
func NewService(emailSender EmailSender) *Service {
    return &Service{
        emailSender: emailSender,
    }
}

// Send delivers a notification via email.
func (s *Service) Send(to string, message string) error {
    return s.emailSender.SendEmail(to, "New Notification", message)
}
```

```go
// package: internal/email
type Service struct { smtpServer, username, password string }

func NewService(server, user, pass string) *Service {
    return &Service{server, user, pass}
}

func (s *Service) SendEmail(to, subject, body string) error {
    // SMTP implementation...
    return nil
}
```

```go
// Testing with simple mock
package notification

var _ EmailSender = (*email.Service)(nil) // Compile-time check

type mockEmailSender struct {
    sentEmails []struct{ to, subject, body string }
}

func (m *mockEmailSender) SendEmail(to, subject, body string) error {
    m.sentEmails = append(m.sentEmails, struct{to, subject, body string}{to, subject, body})
    return nil
}

func TestNotificationService(t *testing.T) {
    mock := &mockEmailSender{}
    service := NewService(mock)

    err := service.Send("user@example.com", "Hello!")

    if err != nil || len(mock.sentEmails) != 1 || mock.sentEmails[0].to != "user@example.com" {
        t.Errorf("Test failed: err=%v, emails=%d", err, len(mock.sentEmails))
    }
}
```

```go
// ✅ GOOD: Small, focused interfaces that compose
// Reader abstracts reading operations.
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Writer abstracts writing operations.
type Writer interface {
    Write(p []byte) (n int, err error)
}

// Closer abstracts resource cleanup.
type Closer interface {
    Close() error
}

// ReadWriter combines reading and writing operations.
type ReadWriter interface {
    Reader
    Writer
}

// ReadWriteCloser adds resource cleanup to ReadWriter.
type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}
```

```go
// ✅ GOOD: Accept interfaces, return concrete types
type Database interface {
    Query(query string, args ...interface{}) (Rows, error)
    Exec(query string, args ...interface{}) (Result, error)
}

type Rows interface { Scan(dest ...interface{}) error; Next() bool; Close() error }

type UserRepository struct { db Database }

func NewUserRepository(db Database) *UserRepository { return &UserRepository{db} }
```

```go
// ✅ GOOD: Using generics for type safety
type Cache[T any] struct { items map[string]T }

func NewCache[T any]() *Cache[T] { return &Cache[T]{items: make(map[string]T)} }
func (c *Cache[T]) Set(key string, value T) { c.items[key] = value }
func (c *Cache[T]) Get(key string) (T, bool) { return c.items[key] }

// Type-safe usage
userCache := NewCache[*User]()
userCache.Set("user", &User{Name: "Alice"})
user, _ := userCache.Get("user") // No type assertion needed
```

```go
// ❌ BAD: Large "header interface" with many methods
type UserRepository interface {
    FindByID(id string) (*User, error)
    FindByEmail(email string) (*User, error)
    FindAll() ([]*User, error)
    Create(user *User) error
    Update(user *User) error
    // ... 10+ more methods
}

// ❌ BAD: Interface in implementation package
package database
type Repository interface { Find(id string) (interface{}, error) }
```

## Related Bindings

- [dependency-inversion](../../docs/bindings/core/dependency-inversion.md): Consumer-defined interfaces implement dependency inversion
- [go-package-design](../../docs/bindings/categories/go/package-design.md): Interface design defines package boundaries
- [testability](../../docs/tenets/testability.md): Small interfaces enable simple test implementations
- [hex-domain-purity](../../docs/bindings/core/hex-domain-purity.md): Interfaces provide hexagonal architecture adapters
