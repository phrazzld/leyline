---
derived_from: simplicity
enforced_by: Code review, Clippy static analysis
id: error-handling
last_modified: '2025-05-14'
version: '0.2.0'
---
# Binding: Rust Error Handling

Handle errors explicitly in Rust using the type system. Return `Result` for all
operations that can fail, use custom error types to convey precise error information,
and leverage the `?` operator for concise propagation.

## Rationale

This binding implements simplicity and explicit-over-implicit tenets by making errors a first-class concern in the type system. Rust's `Result<T, E>` makes failure explicit in function signatures, unlike exceptions that can propagate invisibly. This eliminates bugs related to unhandled exceptions and ensures every potential failure point is explicitly addressed.

## Rule Definition

**Required Patterns:**
- **Use `Result<T, E>` for all fallible operations**: Return `Result` for any function that can fail in expected ways
- **Never use `panic!` for expected failures**: Reserve `panic!` for unrecoverable programming errors only
- **Create domain-specific error types**: Define custom error types that precisely represent domain failures
- **Use the `?` operator for error propagation**: Leverage `?` for concise error propagation
- **Provide context with wrapped errors**: Add context when propagating errors from lower-level components

**Exceptions:** Application `main()` functions, test code, prototyping code

## Practical Implementation

**1. Create Custom Error Types:**

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UserServiceError {
    #[error("user not found with id {0}")]
    UserNotFound(String),
    #[error("database error: {0}")]
    DatabaseError(#[from] DatabaseError),
    #[error("validation error: {0}")]
    ValidationError(String),
}
```

**2. Design Function Signatures with `Result`:**

```rust
pub fn get_user(id: &str) -> Result<User, UserServiceError> {
    // Implementation...
}
```

**3. Use the `?` Operator:**

```rust
pub fn process_user_data(id: &str) -> Result<ProcessedData, UserServiceError> {
    let user = get_user(id)?;
    let settings = get_user_settings(id)?;
    let processed = transform_data(user, settings)?;
    Ok(processed)
}
```

**4. Add Context When Propagating Errors:**

```rust
// Binary crates using anyhow
use anyhow::{Context, Result};

fn load_config(path: &Path) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    parse_config(&content)
        .with_context(|| format!("failed to parse config from {}", path.display()))
}
```

**5. Handle Different Error Cases Explicitly:**

```rust
match get_user(user_id) {
    Ok(user) => { /* Happy path */ },
    Err(UserServiceError::UserNotFound(_)) => { /* Handle missing user */ },
    Err(UserServiceError::ValidationError(msg)) => { /* Handle validation */ },
    Err(e) => { log::error!("Unexpected error: {}", e); }
}
```

## Examples

```rust
// ❌ BAD: Using unwrap/expect for normal error handling
fn get_config() -> Config {
    let file = std::fs::File::open("config.json").expect("Failed to open config file");
    serde_json::from_reader(std::io::BufReader::new(file)).expect("Failed to parse config")
}

// ✅ GOOD: Using Result to make errors explicit
fn get_config() -> Result<Config, ConfigError> {
    let file = std::fs::File::open("config.json")
        .map_err(|e| ConfigError::IoError { source: e, file: "config.json" })?;
    let config = serde_json::from_reader(std::io::BufReader::new(file))
        .map_err(|e| ConfigError::ParseError { source: e, file: "config.json" })?;
    Ok(config)
}
```

```rust
// ❌ BAD: Using strings as errors loses type information
fn process_data(data: &str) -> Result<ProcessedData, String> {
    if data.is_empty() {
        return Err("Data cannot be empty".to_string());
    }
    // Processing...
    Ok(ProcessedData::new(data))
}

// ✅ GOOD: Using typed errors with proper context
#[derive(Error, Debug)]
enum ProcessingError {
    #[error("empty input data")]
    EmptyData,
    #[error("parsing error: {0}")]
    ParseError(#[from] ParseError),
}

fn process_data(data: &str) -> Result<ProcessedData, ProcessingError> {
    if data.is_empty() {
        return Err(ProcessingError::EmptyData);
    }
    let parsed = parse_input(data)?;
    Ok(ProcessedData::new(parsed))
}
```

## Related Bindings

- [go-error-wrapping](../go/error-wrapping.md): Similar emphasis on explicit error handling and context propagation
- [ownership-patterns](ownership-patterns.md): Complements error handling by defining resource management patterns
- [dependency-inversion](../../core/dependency-inversion.md): Creates cleanly separated components with well-defined error boundaries
- [immutable-by-default](../../core/immutable-by-default.md): Reduces state management complexity for clearer error reasoning
