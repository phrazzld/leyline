---
derived_from: simplicity
enforced_by: rust compiler & code review
id: ownership-patterns
last_modified: '2025-05-14'
version: '0.2.0'
---
# Binding: Embrace Rust's Ownership System, Don't Fight It

Design Rust code to work with the ownership system, not against it. Use ownership, borrowing, and lifetimes as core design elements that guide your APIs and data structures.

## Rationale

This binding implements our simplicity tenet by leveraging Rust's ownership system to prevent entire categories of bugs. Rust's ownership model moves complexity from runtime to compile time, creating naturally simpler, more robust software.

## Rule Definition

**Core Requirements:**
- **Ownership as API Design**: Structure APIs around ownership patterns - transfer ownership when taking responsibility, use shared references for read-only access, mutable references for temporary write access
- **Borrow Checking Compliance**: Never circumvent the borrow checker with complex schemes or unsafe code. If the borrow checker fights your design, rethink the design
- **Borrowing Over Copying**: Prefer borrowing over cloning/copying where possible, only clone when the clone will be modified independently
- **Lifetime Management**: Keep lifetime annotations simple, let Rust's lifetime elision rules work when possible
- **RAII Resource Management**: Use Rust's RAII pattern for all resource management with clear owners responsible for cleanup
- **Unsafe Usage Restrictions**: Minimize unsafe code, document with `// SAFETY:` comments, abstract behind safe interfaces

## Practical Implementation

**Ownership-Friendly API Design:**

```rust
// Consuming APIs - take ownership when storing or transforming values
fn process_message(message: Message) -> Result<Response, Error> {
    // Function takes ownership of message
}

// Non-consuming APIs - borrow when only reading
fn validate_message(message: &Message) -> bool {
    // Function only reads message
}

// Mutating APIs - use mutable borrows for modification
fn update_message(message: &mut Message, new_content: &str) {
    // Function temporarily modifies message in-place
}

// Factory pattern - return values instead of mutating
fn enrich_message(message: Message, metadata: &Metadata) -> Message {
    // Returns a new, enhanced Message
}
```

**Resource Management with Clear Ownership:**

```rust
struct Connection {
    socket: Socket,
}

impl Connection {
    fn new(socket: Socket, config: &ConnectionConfig) -> Self {
        Connection { socket }
    }

    fn send_data(&mut self, data: &[u8]) -> Result<usize, Error> {
        self.socket.write(data)
    }
}
```

**Borrowing Patterns for Shared Data:**

```rust
struct Parser<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input, position: 0 }
    }

    fn parse_identifier(&mut self) -> Option<&'a str> {
        let start = self.position;
        while self.position < self.input.len() &&
              self.input.as_bytes()[self.position].is_ascii_alphanumeric() {
            self.position += 1;
        }
        if start == self.position {
            None
        } else {
            Some(&self.input[start..self.position])
        }
    }
}
```

## Examples

```rust
// ❌ BAD: Fighting the borrow checker with excessive cloning
fn process_data(data: &mut Vec<String>, query: &str) -> Vec<String> {
    let results = data.iter()
        .filter(|item| item.contains(query))
        .cloned()  // Unnecessary clone
        .collect::<Vec<_>>();

    for item in &results {
        data.push(item.clone());  // Another clone
    }
    results
}

// ✅ GOOD: Working with the ownership system
fn process_data(data: &[String], query: &str) -> Vec<String> {
    data.iter()
        .filter(|item| item.contains(query))
        .cloned()
        .collect()
}
```

```rust
// ❌ BAD: Excessive use of Rc<RefCell<T>>
struct UserManager {
    users: Rc<RefCell<Vec<User>>>,
}

impl UserManager {
    fn add_user(&self, user: User) {
        self.users.borrow_mut().push(user);
    }
}

// ✅ GOOD: Clear ownership with appropriate borrowing
struct UserManager {
    users: Vec<User>,
}

impl UserManager {
    fn add_user(&mut self, user: User) {
        self.users.push(user);
    }

    fn get_user(&self, id: &str) -> Option<&User> {
        self.users.iter().find(|user| user.id == id)
    }
}
```

## Related Bindings

- [immutable-by-default](../../core/immutable-by-default.md): Rust's ownership system naturally encourages immutability through shared references
- [no-internal-mocking](../../core/no-internal-mocking.md): Rust's trait system combined with ownership makes abstractions easily testable
- [dependency-inversion](../../core/dependency-inversion.md): Dependency inversion pairs naturally with ownership to make relationships explicit
- [simplicity](../../tenets/simplicity.md): Rust's ownership system reduces accidental complexity by catching bugs at compile time
