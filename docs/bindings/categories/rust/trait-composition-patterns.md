---
id: trait-composition-patterns
last_modified: '2025-06-02'
version: '0.1.0'
derived_from: orthogonality
enforced_by: 'Rust compiler, trait bounds, code review'
---
# Binding: Compose Behavior Through Trait Design and Implementation

Design systems using Rust's trait system to create modular, composable behaviors that combine without coupling. Use trait composition, associated types, and blanket implementations to build flexible abstractions that maintain orthogonal concerns.

## Rationale

This binding implements orthogonality by leveraging Rust's trait system to create independent, composable behaviors. Traits enable composition that is safer and more flexible than inheritance hierarchies, allowing behaviors to be mixed without creating tight coupling.

Rust traits work like standardized interfaces for modular components where each trait defines a specific capability. Traditional inheritance creates rigid hierarchies, but trait composition allows independent capability modification with zero-cost abstractions and compile-time guarantees.

## Rule Definition

Trait composition must establish these Rust patterns:
- **Single Responsibility Traits**: Design traits representing one cohesive behavior. Avoid monolithic traits combining unrelated functionality.
- **Composable Trait Bounds**: Use trait bounds to compose multiple traits, enabling complex behaviors through combinations.
- **Associated Types**: Create flexible trait definitions that adapt to different contexts while maintaining type safety.
- **Blanket Implementations**: Provide automatic trait implementations for types satisfying conditions.
- **Trait Objects**: Use for runtime polymorphism when needed, preferring static dispatch for performance.
- **Default Implementations**: Provide sensible defaults allowing implementations to focus on unique behavior.

**Design Patterns:** Capability traits (focused behaviors), marker traits (compile-time safety), extension traits (external type functionality), and associated type families (related types).
**Composition Strategies:** Multiple trait bounds for combination, trait object collections for heterogeneous types, and derive macros for automatic implementation.

## Practical Implementation

1. **Design Single-Responsibility Traits**: Create focused traits representing clear capabilities:

   ```rust
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

   // Capability trait for seeking
   trait Seekable {
       type Position;
       type Error;
       fn seek(&mut self, pos: Self::Position) -> Result<Self::Position, Self::Error>;
   }

   // Compose capabilities through trait bounds
   fn process_file<T>(mut file: T) -> Result<(), T::Error>
   where
       T: Readable<Item = Vec<u8>> + Writable<Item = Vec<u8>> + Seekable,
   {
       let data = file.read()?;
       file.seek(file.position())?;
       file.write(data)?;
       Ok(())
   }
   ```

2. **Use Associated Types for Flexible Abstractions**: Create traits that adapt to contexts:

   ```rust
   // Generic repository trait with associated types
   trait Repository {
       type Entity;
       type Id;
       type Error;

       fn find_by_id(&self, id: Self::Id) -> Result<Option<Self::Entity>, Self::Error>;
       fn save(&mut self, entity: Self::Entity) -> Result<Self::Entity, Self::Error>;
   }

   // Specific implementation
   struct UserRepository {
       db: DatabaseConnection,
   }

   impl Repository for UserRepository {
       type Entity = User;
       type Id = UserId;
       type Error = DatabaseError;

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
   }

   // Generic service working with any repository
   struct Service<R: Repository> {
       repo: R,
   }

   impl<R: Repository> Service<R> {
       fn get_entity(&self, id: R::Id) -> Result<Option<R::Entity>, R::Error> {
           self.repo.find_by_id(id)
       }
   }
   ```

3. **Implement Blanket Implementations**: Provide automatic trait coverage:

   ```rust
   // Base serialization trait
   trait Serialize {
       fn serialize(&self) -> Vec<u8>;
   }

   // JSON serialization trait
   trait JsonSerialize: Serialize {
       fn to_json(&self) -> String;
   }

   // Blanket implementation: any serializable type can do JSON
   impl<T: Serialize> JsonSerialize for T {
       fn to_json(&self) -> String {
           let bytes = self.serialize();
           format!("{{\"data\": \"{}\"}}", base64::encode(&bytes))
       }
   }

   // Extension trait for external types
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

   // Conditional implementation
   trait Summary {
       fn summarize(&self) -> String;
   }

   impl<T: std::fmt::Display + std::fmt::Debug> Summary for T {
       fn summarize(&self) -> String {
           format!("Display: {}, Debug: {:?}", self, self)
       }
   }
   ```

4. **Create Trait Object Collections**: Use dynamic dispatch for runtime polymorphism:

   ```rust
   // Event handling trait with object safety
   trait EventHandler: Send + Sync {
       fn handle_event(&mut self, event: &Event) -> Result<(), HandlerError>;
       fn event_types(&self) -> Vec<EventType>;
   }

   // Event dispatcher using trait objects
   struct EventDispatcher {
       handlers: Vec<Box<dyn EventHandler>>,
   }

   impl EventDispatcher {
       fn add_handler(&mut self, handler: Box<dyn EventHandler>) {
           self.handlers.push(handler);
       }

       fn dispatch(&mut self, event: Event) -> Result<(), Vec<HandlerError>> {
           let mut errors = Vec::new();
           for handler in &mut self.handlers {
               if handler.event_types().contains(&event.event_type) {
                   if let Err(error) = handler.handle_event(&event) {
                       errors.push(error);
                   }
               }
           }
           if errors.is_empty() { Ok(()) } else { Err(errors) }
       }
   }
   ```

5. **Use Derive Macros for Automatic Implementation**: Reduce boilerplate through derivation:

   ```rust
   // Standard derive traits for common functionality
   #[derive(Debug, Clone, PartialEq, Eq, Hash)]
   struct OrderId(String);

   #[derive(Debug, Clone, Serialize, Deserialize)]
   struct Order {
       id: OrderId,
       user_id: UserId,
       items: Vec<OrderItem>,
       total: Money,
   }
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
    // Too many unrelated responsibilities
}

// Problems: Mixed concerns, difficult to implement partially,
// changes affect all implementations, hard to test
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

trait Notifiable {
    type Error;
    fn send_notification(&self) -> Result<(), Self::Error>;
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

// Individual traits implemented and tested separately
impl Persistable for User {
    type Error = DatabaseError;
    fn save(&mut self) -> Result<(), Self::Error> { Ok(()) }
    fn delete(&mut self) -> Result<(), Self::Error> { Ok(()) }
}

impl Validatable for User {
    type Error = ValidationError;
    fn validate(&self) -> Result<(), Self::Error> {
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
        // Forced to use String for errors instead of io::Error
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
// ❌ BAD: Inheritance-style composition creating coupling
struct UserService {
    base: BaseService,  // Composition through struct embedding
    email_service: EmailService,
}

// Problems: Tight coupling, difficult substitution, hard to test
```

```rust
// ✅ GOOD: Trait-based composition with dependency injection
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
    D: Database + Send,
    L: Logger + Send,
    E: EmailService + Send,
{
    fn create_user(&mut self, user: User) -> Result<User, ServiceError> {
        self.logger.log("Creating user")?;
        let saved = self.db.save(user)?;
        self.email_service.send_welcome(saved.id)?;
        Ok(saved)
    }
}
```

## Related Bindings

- [component-isolation](../../core/component-isolation.md): Trait composition enables component isolation by creating behavior boundaries that prevent coupling, allowing independent development and testing.

- [ownership-patterns](./ownership-patterns.md): Rust's ownership system and trait composition work together to ensure memory safety while enabling flexible composition.

- [extract-common-logic](../../core/extract-common-logic.md): Trait composition provides Rust's primary mechanism for extracting and reusing common logic across types through blanket implementations and associated types.

- [orthogonality](../../tenets/orthogonality.md): This binding directly implements orthogonality through Rust's trait system, enabling independent behavior composition without coupling.
