---
id: trait-composition-patterns
last_modified: '2025-06-02'
version: '0.1.0'
derived_from: orthogonality
enforced_by: 'Rust compiler, trait bounds, code review'
---
# Binding: Compose Behavior Through Trait Design and Implementation

Design systems using Rust's trait system to create modular, composable behaviors that can be combined and extended without coupling. Use trait composition, associated types, and blanket implementations to build flexible abstractions that maintain orthogonal concerns while enabling powerful code reuse.

## Rationale

This binding implements our orthogonality tenet by leveraging Rust's trait system to create truly independent, composable behaviors. Traits in Rust enable a form of composition that is both safer and more flexible than traditional inheritance hierarchies, allowing you to define behaviors that can be mixed and matched without creating tight coupling between components.

Think of Rust traits like standardized interfaces for modular electronic components. Each component (trait) defines a specific capability or behavior, and components can be combined in various configurations to create complex systems. Just as you can connect a GPS module, a camera, and a wireless transmitter to a microcontroller without any of these components knowing about the others, well-designed traits allow behaviors to be composed without creating dependencies between them. The microcontroller (your struct) gains all these capabilities without any of the individual components needing to be modified or even aware of each other's existence.

Traditional object-oriented inheritance creates rigid hierarchies where changes ripple through the entire chain, but trait composition allows you to add, remove, or modify capabilities independently. This flexibility becomes crucial as systems grow in complexity, enabling you to respond to changing requirements without restructuring foundational code. Rust's trait system, with its emphasis on zero-cost abstractions and compile-time guarantees, ensures that this flexibility doesn't come at the expense of performance or safety.

## Rule Definition

Trait composition must establish these Rust-specific patterns:

- **Single Responsibility Traits**: Design traits that represent one cohesive behavior or capability. Avoid large, monolithic traits that combine unrelated functionality.

- **Composable Trait Bounds**: Use trait bounds to compose multiple traits on types, enabling complex behaviors through simple trait combinations rather than inheritance hierarchies.

- **Associated Types for Flexibility**: Use associated types to create flexible trait definitions that can adapt to different contexts while maintaining type safety and performance.

- **Blanket Implementations**: Provide blanket implementations to automatically implement traits for types that satisfy certain conditions, reducing boilerplate and ensuring consistency.

- **Trait Objects for Dynamic Dispatch**: Use trait objects when runtime polymorphism is needed, while preferring static dispatch (generics with trait bounds) for performance-critical code.

- **Default Implementations**: Provide sensible default implementations for trait methods where possible, allowing implementations to focus only on the essential, unique behavior.

**Trait Design Patterns:**
- Capability traits (single, focused behaviors)
- Marker traits (compile-time type safety indicators)
- Extension traits (adding functionality to external types)
- Associated type families (related types that vary together)
- Conditional trait implementations (traits for types meeting criteria)

**Composition Strategies:**
- Multiple trait bounds for behavior combination
- Trait object collections for heterogeneous types
- Generic associated types for advanced abstractions
- Derive macros for automatic trait implementation
- Orphan rule compliance for external trait implementation

## Practical Implementation

1. **Design Single-Responsibility Traits**: Create focused traits that represent one clear capability:

   ```rust
   // ✅ GOOD: Single-responsibility traits with clear purposes

   // Capability trait for reading data
   trait Readable {
       type Item;
       type Error;

       fn read(&mut self) -> Result<Self::Item, Self::Error>;
   }

   // Capability trait for writing data
   trait Writable {
       type Item;
       type Error;

       fn write(&mut self, item: Self::Item) -> Result<(), Self::Error>;
   }

   // Capability trait for seeking within data
   trait Seekable {
       type Position;
       type Error;

       fn seek(&mut self, pos: Self::Position) -> Result<Self::Position, Self::Error>;
       fn position(&self) -> Self::Position;
   }

   // Capability trait for buffering operations
   trait Bufferable {
       fn flush(&mut self) -> Result<(), Self::Error>;
       fn buffer_size(&self) -> usize;
   }

   // Compose capabilities through trait bounds
   fn process_file<T>(mut file: T) -> Result<(), T::Error>
   where
       T: Readable<Item = Vec<u8>> + Writable<Item = Vec<u8>> + Seekable,
       T::Error: std::fmt::Debug,
   {
       // Can read, write, and seek because T implements all three traits
       let data = file.read()?;
       file.seek(file.position())?;
       file.write(data)?;
       Ok(())
   }
   ```

2. **Use Associated Types for Flexible Abstractions**: Create traits that adapt to different contexts:

   ```rust
   // ✅ GOOD: Associated types for flexible, context-aware traits

   // Generic repository trait with associated types
   trait Repository {
       type Entity;
       type Id;
       type Error;
       type Query;

       fn find_by_id(&self, id: Self::Id) -> Result<Option<Self::Entity>, Self::Error>;
       fn save(&mut self, entity: Self::Entity) -> Result<Self::Entity, Self::Error>;
       fn delete(&mut self, id: Self::Id) -> Result<bool, Self::Error>;
       fn query(&self, query: Self::Query) -> Result<Vec<Self::Entity>, Self::Error>;
   }

   // Specific implementation for users
   struct UserRepository {
       db: DatabaseConnection,
   }

   impl Repository for UserRepository {
       type Entity = User;
       type Id = UserId;
       type Error = DatabaseError;
       type Query = UserQuery;

       fn find_by_id(&self, id: Self::Id) -> Result<Option<Self::Entity>, Self::Error> {
           self.db.query_one("SELECT * FROM users WHERE id = ?", &[id.as_ref()])
       }

       fn save(&mut self, entity: Self::Entity) -> Result<Self::Entity, Self::Error> {
           if entity.id.is_empty() {
               self.create_user(entity)
           } else {
               self.update_user(entity)
           }
       }

       // ... other methods
   }

   // Generic service that works with any repository
   struct Service<R: Repository> {
       repo: R,
   }

   impl<R: Repository> Service<R> {
       fn new(repo: R) -> Self {
           Self { repo }
       }

       fn get_entity(&self, id: R::Id) -> Result<Option<R::Entity>, R::Error> {
           self.repo.find_by_id(id)
       }

       fn create_entity(&mut self, entity: R::Entity) -> Result<R::Entity, R::Error> {
           self.repo.save(entity)
       }
   }
   ```

3. **Implement Blanket Implementations for Automatic Trait Coverage**: Provide implementations for broad categories of types:

   ```rust
   // ✅ GOOD: Blanket implementations for automatic trait coverage

   // Base serialization trait
   trait Serialize {
       fn serialize(&self) -> Vec<u8>;
   }

   // Specific trait for JSON serialization
   trait JsonSerialize: Serialize {
       fn to_json(&self) -> String;
   }

   // Blanket implementation: any type that can serialize can do JSON
   impl<T: Serialize> JsonSerialize for T {
       fn to_json(&self) -> String {
           // Convert binary data to JSON representation
           let bytes = self.serialize();
           format!("{{\"data\": \"{}\"}}", base64::encode(&bytes))
       }
   }

   // Extension trait for adding functionality to external types
   trait StringExtensions {
       fn is_email(&self) -> bool;
       fn truncate_words(&self, max_words: usize) -> String;
   }

   // Implement for all string-like types
   impl<T: AsRef<str>> StringExtensions for T {
       fn is_email(&self) -> bool {
           let s = self.as_ref();
           s.contains('@') && s.contains('.')
       }

       fn truncate_words(&self, max_words: usize) -> String {
           let words: Vec<&str> = self.as_ref().split_whitespace().collect();
           if words.len() <= max_words {
               self.as_ref().to_string()
           } else {
               format!("{}...", words[..max_words].join(" "))
           }
       }
   }

   // Conditional implementation based on other traits
   trait Summary {
       fn summarize(&self) -> String;
   }

   // Auto-implement Summary for anything that can display and debug
   impl<T: std::fmt::Display + std::fmt::Debug> Summary for T {
       fn summarize(&self) -> String {
           format!("Display: {}, Debug: {:?}", self, self)
       }
   }
   ```

4. **Create Trait Object Collections for Heterogeneous Data**: Use dynamic dispatch for runtime polymorphism:

   ```rust
   // ✅ GOOD: Trait objects for heterogeneous collections

   // Event handling trait with object safety
   trait EventHandler: Send + Sync {
       fn handle_event(&mut self, event: &Event) -> Result<(), HandlerError>;
       fn event_types(&self) -> Vec<EventType>;
       fn handler_name(&self) -> &str;
   }

   // Specific event handlers
   struct UserEventHandler {
       user_service: Arc<Mutex<UserService>>,
   }

   impl EventHandler for UserEventHandler {
       fn handle_event(&mut self, event: &Event) -> Result<(), HandlerError> {
           match event.event_type {
               EventType::UserCreated => self.handle_user_created(event),
               EventType::UserDeleted => self.handle_user_deleted(event),
               _ => Ok(()),
           }
       }

       fn event_types(&self) -> Vec<EventType> {
           vec![EventType::UserCreated, EventType::UserDeleted]
       }

       fn handler_name(&self) -> &str {
           "UserEventHandler"
       }
   }

   struct NotificationHandler {
       email_service: Arc<dyn EmailService>,
   }

   impl EventHandler for NotificationHandler {
       fn handle_event(&mut self, event: &Event) -> Result<(), HandlerError> {
           match event.event_type {
               EventType::UserCreated => self.send_welcome_email(event),
               EventType::OrderCompleted => self.send_order_confirmation(event),
               _ => Ok(()),
           }
       }

       fn event_types(&self) -> Vec<EventType> {
           vec![EventType::UserCreated, EventType::OrderCompleted]
       }

       fn handler_name(&self) -> &str {
           "NotificationHandler"
       }
   }

   // Event dispatcher using trait objects
   struct EventDispatcher {
       handlers: Vec<Box<dyn EventHandler>>,
   }

   impl EventDispatcher {
       fn new() -> Self {
           Self {
               handlers: Vec::new(),
           }
       }

       fn add_handler(&mut self, handler: Box<dyn EventHandler>) {
           self.handlers.push(handler);
       }

       fn dispatch(&mut self, event: Event) -> Result<(), Vec<HandlerError>> {
           let mut errors = Vec::new();

           for handler in &mut self.handlers {
               if handler.event_types().contains(&event.event_type) {
                   if let Err(error) = handler.handle_event(&event) {
                       eprintln!("Handler {} failed: {}", handler.handler_name(), error);
                       errors.push(error);
                   }
               }
           }

           if errors.is_empty() {
               Ok(())
           } else {
               Err(errors)
           }
       }
   }
   ```

5. **Design Trait Families with Associated Types**: Create related traits that work together:

   ```rust
   // ✅ GOOD: Trait families with associated types for cohesive behavior

   // Parser trait family for different data formats
   trait Parser {
       type Input;
       type Output;
       type Error;

       fn parse(&self, input: Self::Input) -> Result<Self::Output, Self::Error>;
   }

   trait Validator<T> {
       type Error;

       fn validate(&self, value: &T) -> Result<(), Self::Error>;
   }

   trait Transformer<From, To> {
       type Error;

       fn transform(&self, from: From) -> Result<To, Self::Error>;
   }

   // Compose traits for complete data processing pipeline
   trait DataProcessor: Parser + Validator<Self::Output> + Transformer<Self::Output, Self::FinalOutput> {
       type FinalOutput;

       fn process(&self, input: Self::Input) -> Result<Self::FinalOutput, ProcessingError>
       where
           Self::Error: Into<ProcessingError>,
           <Self as Validator<Self::Output>>::Error: Into<ProcessingError>,
           <Self as Transformer<Self::Output, Self::FinalOutput>>::Error: Into<ProcessingError>,
       {
           let parsed = self.parse(input).map_err(Into::into)?;
           self.validate(&parsed).map_err(Into::into)?;
           self.transform(parsed).map_err(Into::into)
       }
   }

   // JSON processor implementation
   struct JsonProcessor;

   impl Parser for JsonProcessor {
       type Input = String;
       type Output = serde_json::Value;
       type Error = serde_json::Error;

       fn parse(&self, input: Self::Input) -> Result<Self::Output, Self::Error> {
           serde_json::from_str(&input)
       }
   }

   impl Validator<serde_json::Value> for JsonProcessor {
       type Error = ValidationError;

       fn validate(&self, value: &serde_json::Value) -> Result<(), Self::Error> {
           if value.is_object() {
               Ok(())
           } else {
               Err(ValidationError::new("Expected JSON object"))
           }
       }
   }

   impl Transformer<serde_json::Value, User> for JsonProcessor {
       type Error = serde_json::Error;

       fn transform(&self, from: serde_json::Value) -> Result<User, Self::Error> {
           serde_json::from_value(from)
       }
   }

   impl DataProcessor for JsonProcessor {
       type FinalOutput = User;
   }
   ```

6. **Use Derive Macros and Procedural Macros for Automatic Implementation**: Reduce boilerplate through automatic trait derivation:

   ```rust
   // ✅ GOOD: Derive macros for automatic trait implementation

   // Custom derive macro for automatic repository implementation
   #[derive(Repository)]
   #[repository(table = "users", id_field = "id")]
   struct User {
       id: UserId,
       email: String,
       name: String,
       created_at: DateTime<Utc>,
   }

   // The derive macro automatically generates:
   // impl Repository for User { ... }

   // Standard derive traits for common functionality
   #[derive(Debug, Clone, PartialEq, Eq, Hash)]
   struct OrderId(String);

   #[derive(Debug, Clone, Serialize, Deserialize)]
   struct Order {
       id: OrderId,
       user_id: UserId,
       items: Vec<OrderItem>,
       total: Money,
       status: OrderStatus,
   }

   // Custom trait with derive support
   trait Identifiable {
       type Id;
       fn id(&self) -> &Self::Id;
   }

   // Derive macro implementation (conceptual)
   #[derive(Identifiable)]
   #[identifiable(id_field = "id")]
   struct Product {
       id: ProductId,
       name: String,
       price: Money,
   }

   // Automatic implementation generated by derive macro:
   // impl Identifiable for Product {
   //     type Id = ProductId;
   //     fn id(&self) -> &Self::Id { &self.id }
   // }
   ```

## Examples

```rust
// ❌ BAD: Monolithic trait with mixed responsibilities
trait DatabaseEntity {
    fn save(&mut self) -> Result<(), DatabaseError>;
    fn delete(&mut self) -> Result<(), DatabaseError>;
    fn validate(&self) -> Result<(), ValidationError>;
    fn serialize(&self) -> Vec<u8>;
    fn send_notification(&self) -> Result<(), NotificationError>;
    fn log_audit(&self) -> Result<(), AuditError>;
    // Too many unrelated responsibilities in one trait
}

// Problems:
// - Mixed concerns (persistence, validation, serialization, notification, audit)
// - Difficult to implement partially
// - Changes to one concern affect all implementations
// - Hard to test individual behaviors
```

```rust
// ✅ GOOD: Separated traits with single responsibilities
trait Persistable {
    type Error;
    fn save(&mut self) -> Result<(), Self::Error>;
    fn delete(&mut self) -> Result<(), Self::Error>;
}

trait Validatable {
    type Error;
    fn validate(&self) -> Result<(), Self::Error>;
}

trait Serializable {
    fn serialize(&self) -> Vec<u8>;
}

trait Notifiable {
    type Error;
    fn send_notification(&self) -> Result<(), Self::Error>;
}

trait Auditable {
    type Error;
    fn log_audit(&self) -> Result<(), Self::Error>;
}

// Compose behaviors through trait bounds
fn process_entity<T>(mut entity: T) -> Result<(), ProcessingError>
where
    T: Persistable + Validatable + Notifiable,
    T::Error: Into<ProcessingError>,
    <T as Validatable>::Error: Into<ProcessingError>,
    <T as Notifiable>::Error: Into<ProcessingError>,
{
    entity.validate().map_err(Into::into)?;
    entity.save().map_err(Into::into)?;
    entity.send_notification().map_err(Into::into)?;
    Ok(())
}

// Individual traits can be implemented and tested separately
impl Persistable for User {
    type Error = DatabaseError;

    fn save(&mut self) -> Result<(), Self::Error> {
        // User-specific persistence logic
        Ok(())
    }

    fn delete(&mut self) -> Result<(), Self::Error> {
        // User-specific deletion logic
        Ok(())
    }
}

impl Validatable for User {
    type Error = ValidationError;

    fn validate(&self) -> Result<(), Self::Error> {
        // User-specific validation logic
        if self.email.contains('@') {
            Ok(())
        } else {
            Err(ValidationError::new("Invalid email"))
        }
    }
}
```

```rust
// ❌ BAD: Rigid trait without associated types
trait Logger {
    fn log(&self, message: String) -> Result<(), String>;
    // Fixed types make trait inflexible
}

struct FileLogger {
    path: PathBuf,
}

impl Logger for FileLogger {
    fn log(&self, message: String) -> Result<(), String> {
        // Forced to use String for errors, even though io::Error would be better
        std::fs::write(&self.path, message).map_err(|e| e.to_string())
    }
}
```

```rust
// ✅ GOOD: Flexible trait with associated types
trait Logger {
    type Error;
    type Message;

    fn log(&self, message: Self::Message) -> Result<(), Self::Error>;
}

struct FileLogger {
    path: PathBuf,
}

impl Logger for FileLogger {
    type Error = std::io::Error;
    type Message = String;

    fn log(&self, message: Self::Message) -> Result<(), Self::Error> {
        std::fs::write(&self.path, message)
    }
}

struct StructuredLogger {
    sender: Sender<LogEntry>,
}

impl Logger for StructuredLogger {
    type Error = SendError<LogEntry>;
    type Message = LogEntry;

    fn log(&self, message: Self::Message) -> Result<(), Self::Error> {
        self.sender.send(message)
    }
}

// Generic function works with any logger
fn log_user_action<L: Logger>(logger: &L, user_id: &str, action: &str) -> Result<(), L::Error>
where
    L::Message: From<String>,
{
    let message = format!("User {} performed {}", user_id, action);
    logger.log(message.into())
}
```

```rust
// ❌ BAD: Inheritance-style composition that creates coupling
struct BaseService {
    db: Database,
    logger: Logger,
}

struct UserService {
    base: BaseService,  // Composition through struct embedding
    email_service: EmailService,
}

impl UserService {
    fn create_user(&mut self, user: User) -> Result<User, ServiceError> {
        // Must access base services through self.base
        self.base.logger.log("Creating user");
        let saved = self.base.db.save(user)?;
        self.email_service.send_welcome(saved.id)?;
        Ok(saved)
    }
}

// Problems:
// - Tight coupling to BaseService structure
// - Difficult to substitute different implementations
// - Hard to test individual capabilities
```

```rust
// ✅ GOOD: Trait-based composition with dependency injection
trait Database {
    type Error;
    fn save<T: Serialize>(&mut self, entity: T) -> Result<T, Self::Error>;
}

trait Logger {
    type Error;
    fn log(&self, message: &str) -> Result<(), Self::Error>;
}

trait EmailService {
    type Error;
    fn send_welcome(&self, user_id: UserId) -> Result<(), Self::Error>;
}

struct UserService<D, L, E>
where
    D: Database,
    L: Logger,
    E: EmailService,
{
    db: D,
    logger: L,
    email_service: E,
}

impl<D, L, E> UserService<D, L, E>
where
    D: Database,
    L: Logger,
    E: EmailService,
    D::Error: Into<ServiceError>,
    L::Error: Into<ServiceError>,
    E::Error: Into<ServiceError>,
{
    fn new(db: D, logger: L, email_service: E) -> Self {
        Self { db, logger, email_service }
    }

    fn create_user(&mut self, user: User) -> Result<User, ServiceError> {
        self.logger.log("Creating user").map_err(Into::into)?;
        let saved = self.db.save(user).map_err(Into::into)?;
        self.email_service.send_welcome(saved.id).map_err(Into::into)?;
        Ok(saved)
    }
}

// Easy to test with different implementations
#[cfg(test)]
mod tests {
    use super::*;

    struct MockDatabase;
    impl Database for MockDatabase {
        type Error = ();
        fn save<T: Serialize>(&mut self, entity: T) -> Result<T, Self::Error> {
            Ok(entity)
        }
    }

    struct MockLogger;
    impl Logger for MockLogger {
        type Error = ();
        fn log(&self, _message: &str) -> Result<(), Self::Error> {
            Ok(())
        }
    }

    struct MockEmailService;
    impl EmailService for MockEmailService {
        type Error = ();
        fn send_welcome(&self, _user_id: UserId) -> Result<(), Self::Error> {
            Ok(())
        }
    }

    #[test]
    fn test_create_user() {
        let mut service = UserService::new(
            MockDatabase,
            MockLogger,
            MockEmailService,
        );

        let user = User::new("test@example.com");
        let result = service.create_user(user);
        assert!(result.is_ok());
    }
}
```

## Related Bindings

- [component-isolation.md](../../core/component-isolation.md): Trait composition directly enables component isolation by creating behavior boundaries that prevent coupling. Both bindings work together to ensure components can be developed, tested, and modified independently.

- [ownership-patterns.md](../../docs/bindings/categories/rust/ownership-patterns.md): Rust's ownership system and trait composition patterns work together to ensure memory safety while enabling flexible composition. Understanding ownership is crucial for designing traits that work efficiently with Rust's zero-cost abstractions.

- [extract-common-logic.md](../../core/extract-common-logic.md): Trait composition provides Rust's primary mechanism for extracting and reusing common logic across types. Blanket implementations and associated types enable powerful code reuse patterns that eliminate duplication while maintaining type safety.

- [orthogonality.md](../../tenets/orthogonality.md): This binding directly implements the orthogonality tenet through Rust's trait system, which enables composing independent behaviors without creating coupling between them. Traits provide compile-time guarantees that composed behaviors remain orthogonal.
