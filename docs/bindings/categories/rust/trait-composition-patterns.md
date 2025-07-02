---
id: trait-composition-patterns
last_modified: '2025-06-02'
version: '0.1.0'
derived_from: orthogonality
enforced_by: 'Rust compiler, trait bounds, code review'
---
# Binding: Compose Behavior Through Trait Design and Implementation

Design systems using Rust's trait system to create modular, composable behaviors that combine without coupling. Use trait composition, associated types, and blanket implementations to build flexible abstractions.

## Rationale

This binding implements orthogonality by leveraging Rust's trait system to create independent, composable behaviors. Traits enable safer, more flexible composition than inheritance hierarchies, allowing behaviors to be mixed without tight coupling.

Rust traits work like standardized interfaces where each trait defines a specific capability. Trait composition allows independent capability modification with zero-cost abstractions and compile-time guarantees.

## Rule Definition

**Required Patterns:**
- **Single Responsibility Traits**: Design traits representing one cohesive behavior
- **Composable Trait Bounds**: Use trait bounds to compose multiple traits
- **Associated Types**: Create flexible trait definitions adapting to contexts
- **Blanket Implementations**: Provide automatic trait implementations for types satisfying conditions
- **Trait Objects**: Use for runtime polymorphism when needed
- **Default Implementations**: Provide sensible defaults for implementations

**Prohibited Practices:**
- Monolithic traits combining unrelated functionality
- Rigid inheritance-style composition patterns
- Overuse of trait objects when static dispatch suffices

## Practical Implementation

**1. Single-Responsibility Traits**

Create focused traits with associated types:

```rust
trait Readable {
    type Item;
    type Error;
    fn read(&mut self) -> Result<Self::Item, Self::Error>;
}

trait Writable {
    type Item;
    type Error;
    fn write(&mut self, item: Self::Item) -> Result<(), Self::Error>;
}

// Compose capabilities through trait bounds
fn process_file<T>(mut file: T) -> Result<(), T::Error>
where
    T: Readable<Item = Vec<u8>> + Writable<Item = Vec<u8>>,
{
    let data = file.read()?;
    file.write(data)?;
    Ok(())
}
```

**2. Repository Pattern with Associated Types**

```rust
trait Repository {
    type Entity;
    type Id;
    type Error;

    fn find_by_id(&self, id: Self::Id) -> Result<Option<Self::Entity>, Self::Error>;
    fn save(&mut self, entity: Self::Entity) -> Result<Self::Entity, Self::Error>;
}

impl Repository for UserRepository {
    type Entity = User;
    type Id = UserId;
    type Error = DatabaseError;

    fn find_by_id(&self, id: Self::Id) -> Result<Option<Self::Entity>, Self::Error> {
        self.db.query_one("SELECT * FROM users WHERE id = ?", &[id.as_ref()])
    }
}
```

**3. Blanket Implementations**

```rust
trait Serialize {
    fn serialize(&self) -> Vec<u8>;
}

trait JsonSerialize: Serialize {
    fn to_json(&self) -> String;
}

// Any serializable type can do JSON
impl<T: Serialize> JsonSerialize for T {
    fn to_json(&self) -> String {
        let bytes = self.serialize();
        format!("{{\"data\": \"{}\"}}", base64::encode(&bytes))
    }
}
```

**4. Trait Objects for Runtime Polymorphism**

```rust
trait EventHandler: Send + Sync {
    fn handle_event(&mut self, event: &Event) -> Result<(), HandlerError>;
}

struct EventDispatcher {
    handlers: Vec<Box<dyn EventHandler>>,
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
    // Too many unrelated responsibilities
}
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

// Compose behaviors through trait bounds
fn process_entity<T>(mut entity: T) -> Result<(), ProcessingError>
where
    T: Persistable + Validatable,
    T::Error: Into<ProcessingError>,
    <T as Validatable>::Error: Into<ProcessingError>,
{
    entity.validate().map_err(Into::into)?;
    entity.save().map_err(Into::into)?;
    Ok(())
}
```

```rust
// ❌ BAD: Rigid trait without associated types
trait Logger {
    fn log(&self, message: String) -> Result<(), String>;
    // Fixed types make trait inflexible
}
```

```rust
// ✅ GOOD: Flexible trait with associated types
trait Logger {
    type Error;
    type Message;
    fn log(&self, message: Self::Message) -> Result<(), Self::Error>;
}

impl Logger for FileLogger {
    type Error = std::io::Error;
    type Message = String;

    fn log(&self, message: Self::Message) -> Result<(), Self::Error> {
        std::fs::write(&self.path, message)
    }
}

// Generic function works with any logger
fn log_user_action<L: Logger>(logger: &L, user_id: &str) -> Result<(), L::Error>
where
    L::Message: From<String>,
{
    logger.log(format!("User {}", user_id).into())
}
```

## Related Bindings

- [orthogonality](../../tenets/orthogonality.md): This binding directly implements orthogonality through Rust's trait system
- [component-isolation](../../core/component-isolation.md): Trait composition enables component isolation by creating behavior boundaries
- [ownership-patterns](ownership-patterns.md): Rust's ownership system and trait composition work together for memory safety
- [error-handling](error-handling.md): Associated types in traits provide flexible error handling patterns
