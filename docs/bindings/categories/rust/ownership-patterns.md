---
derived_from: simplicity
enforced_by: rust compiler & code review
id: ownership-patterns
last_modified: '2025-05-14'
version: '0.1.0'
---
# Binding: Embrace Rust's Ownership System, Don't Fight It

Design Rust code to work with the ownership system, not against it. Use ownership, borrowing, and lifetimes as core design elements that guide your APIs and data structures. Embrace the constraints of the ownership model to create safer, more maintainable code without resorting to excessive cloning, unsafe code, or overly complex lifetime annotations.

## Rationale

This binding implements our simplicity tenet by leveraging Rust's ownership system to prevent entire categories of bugs that would otherwise add tremendous complexity to your codebase. Rust's ownership model moves complexity from runtime (where it causes subtle, hard-to-fix bugs) to compile time (where it can be systematically addressed). When developers design code to work with ownership constraints rather than against them, they create naturally simpler, more robust software where the ownership system prevents runtime battles over memory access and modification.

## Rule Definition

**Core Requirements:**

- **Ownership as API Design**: Structure APIs around ownership patterns, using ownership transfer when functions take responsibility for values, shared references for read-only access, mutable references for temporary write access, and returning new values rather than mutating inputs when possible

- **Borrow Checking Compliance**: Never try to circumvent the borrow checker with complex schemes, unsafe code, or excessive interior mutability. If the borrow checker fights your design, rethink the design to use ownership patterns that naturally satisfy the compiler

- **Borrowing Over Copying**: Prefer borrowing over cloning/copying where possible, only cloning data when the clone will be modified independently, using references when only inspecting data

- **Lifetime Management**: Keep lifetime annotations as simple as possible, letting Rust's lifetime elision rules work when possible, using explicit lifetimes only when necessary to express constraints

- **RAII Resource Management**: Use Rust's RAII pattern for all resource management where every resource has a clear owner responsible for cleanup using the Drop trait

- **Unsafe Usage Restrictions**: Unsafe code must be strictly minimized, thoroughly documented with `// SAFETY:` comments, abstracted behind safe interfaces, and carefully reviewed

## Practical Implementation

**Ownership-Friendly API Design:**

Structure function signatures to clearly communicate ownership intent:

```rust
// Consuming APIs - take ownership when storing or transforming values
fn process_message(message: Message) -> Result<Response, Error> {
    // Function takes ownership of message, can store it or transform it freely
}

// Non-consuming APIs - borrow when only reading
fn validate_message(message: &Message) -> bool {
    // Function only reads message, doesn't affect its ownership
}

// Mutating APIs - use mutable borrows for modification
fn update_message(message: &mut Message, new_content: &str) {
    // Function temporarily modifies message in-place
}

// Factory pattern - return values instead of mutating
fn enrich_message(message: Message, metadata: &Metadata) -> Message {
    // Returns a new, enhanced Message rather than mutating the input
}
```

**Resource Management with Clear Ownership:**

```rust
// Connection clearly owns the socket and is responsible for cleanup
struct Connection {
    socket: Socket,
}

impl Connection {
    // Constructor takes ownership of the socket
    fn new(socket: Socket, config: &ConnectionConfig) -> Self {
        Connection { socket }
    }

    // Methods use &self or &mut self to operate on the owned socket
    fn send_data(&mut self, data: &[u8]) -> Result<usize, Error> {
        self.socket.write(data)
    }
}

// When Connection is dropped, socket is automatically cleaned up
```

**Borrowing Patterns for Shared Data:**

```rust
// Parser borrows the input text and returns slices of that same text
struct Parser<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input, position: 0 }
    }

    // Return type shares the same lifetime as the input
    fn parse_identifier(&mut self) -> Option<&'a str> {
        let start = self.position;

        // Find the end of the identifier
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

**Comprehensive Ownership Pattern Implementation:**

```rust
// ❌ BAD: Fighting the borrow checker with excessive cloning
fn process_data(data: &mut Vec<String>, query: &str) -> Vec<String> {
    let results = data.iter()
        .filter(|item| item.contains(query))
        .cloned()  // Unnecessary clone of each matching item
        .collect::<Vec<_>>();

    for item in &results {
        data.push(item.clone());  // Another clone to add back to data
    }

    results  // Return cloned results
}

// ✅ GOOD: Working with the ownership system
fn process_data(data: &[String], query: &str) -> Vec<String> {
    // First collect matching items
    data.iter()
        .filter(|item| item.contains(query))
        .cloned()
        .collect()
}
```

**Smart Pointer Usage When Truly Needed:**

```rust
use std::rc::Rc;
use std::cell::RefCell;

// ❌ BAD: Excessive use of Rc<RefCell<T>> for simple operations
struct UserManager {
    users: Rc<RefCell<Vec<User>>>,
}

impl UserManager {
    fn add_user(&self, user: User) {
        self.users.borrow_mut().push(user);
    }

    fn get_user(&self, id: &str) -> Option<User> {
        self.users.borrow()
            .iter()
            .find(|user| user.id == id)
            .cloned()
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

**Builder Pattern with Ownership Transfer:**

```rust
struct ServerConfig {
    address: String,
    port: u16,
    max_connections: usize,
    timeout_seconds: u64,
    tls_enabled: bool,
}

// Builder owns the partially constructed config
struct ServerConfigBuilder {
    config: ServerConfig,
}

impl ServerConfigBuilder {
    fn new() -> Self {
        ServerConfigBuilder {
            config: ServerConfig {
                address: String::from("127.0.0.1"),
                port: 8080,
                max_connections: 100,
                timeout_seconds: 30,
                tls_enabled: false,
            },
        }
    }

    // Each method takes and returns ownership of the builder
    fn address(mut self, address: impl Into<String>) -> Self {
        self.config.address = address.into();
        self
    }

    fn port(mut self, port: u16) -> Self {
        self.config.port = port;
        self
    }

    // Finalize by transferring ownership of the config
    fn build(self) -> ServerConfig {
        self.config
    }
}
```

**Complete Resource Management Example:**

```rust
// Define a resource that requires cleanup
struct FileProcessor {
    file: std::fs::File,
    buffer: Vec<u8>,
}

impl FileProcessor {
    // Constructor takes ownership of the file
    fn new(file: std::fs::File) -> Self {
        FileProcessor {
            file,
            buffer: Vec::with_capacity(4096),
        }
    }

    // Process takes &mut self - temporary mutable access
    fn process(&mut self) -> Result<usize, std::io::Error> {
        use std::io::Read;
        self.buffer.clear();
        let bytes_read = self.file.read_to_end(&mut self.buffer)?;
        Ok(bytes_read)
    }

    // Extract results without taking ownership of the processor
    fn results(&self) -> &[u8] {
        &self.buffer
    }

    // Optional: explicit cleanup method if needed beyond Drop
    fn cleanup(self) -> std::fs::File {
        // Return ownership of the file for potential reuse
        self.file
    }
}

// The Drop trait ensures cleanup happens automatically
impl Drop for FileProcessor {
    fn drop(&mut self) {
        println!("FileProcessor being cleaned up");
    }
}

// Usage example showing clear ownership flow
fn process_file(path: &str) -> Result<Vec<u8>, std::io::Error> {
    // Open takes &str (borrowed) and returns owned File
    let file = std::fs::File::open(path)?;

    // Create processor by transferring ownership of file
    let mut processor = FileProcessor::new(file);

    // Process borrows processor mutably
    processor.process()?;

    // Get results without taking ownership
    let results = processor.results().to_vec();

    // Processor is dropped here, automatically cleaning up resources
    Ok(results)
}
```

## Related Bindings

- [immutable-by-default](../../core/immutable-by-default.md): Rust's ownership system naturally encourages immutability through shared references, creating the same benefits as explicit immutability patterns
- [no-internal-mocking](../../core/no-internal-mocking.md): Rust's trait system combined with ownership makes it natural to define abstractions that can be easily tested without complex mocking
- [dependency-inversion](../../core/dependency-inversion.md): Dependency inversion in Rust is often implemented through traits, which pair naturally with the ownership system to make relationships more explicit
- [simplicity](../../tenets/simplicity.md): Rust's ownership system reduces accidental complexity by catching entire classes of bugs at compile time rather than creating hidden runtime complexity
