---
derived_from: simplicity
enforced_by: linters & code review
id: immutable-by-default
last_modified: '2025-05-14'
version: '0.1.0'
---
# Binding: Treat All Data as Unchangeable by Default

Never modify data after it's created. When you need to update state, create entirely new
data structures instead of changing existing ones. Only allow direct mutation with
explicit justification, such as in critical performance hot paths with measured impact.

## Rationale

This binding directly implements our simplicity tenet by eliminating a major source of
complexity—unpredictable state changes that are difficult to trace and reason about.
When your code freely modifies existing data structures, you introduce a subtle form of
time-dependency that dramatically increases cognitive load. Each function becomes a
potential modifier of shared state, forcing developers to mentally track all possible
changes throughout the execution path.

Think of data like a recipe card in a box. When you want to make a variation of a
recipe, you don't erase and rewrite the original—you create a new card that preserves
the original while recording your changes. This ensures the original recipe remains
available for others (or your future self) and makes it clear exactly what changed
between versions. Similarly, immutable data structures provide an unambiguous history of
state changes that makes debugging, testing, and reasoning about your code dramatically
simpler.

The benefits of immutability compound over time. In complex systems, tracking mutable
state across multiple components becomes nearly impossible. Each additional point of
mutation multiplies the possible states your system can be in, creating an explosion in
complexity. By making immutability your default approach, you prevent this complexity
debt from accumulating in the first place. The slight increase in verbosity or
performance overhead is a small price to pay for the dramatic improvement in
predictability, debuggability, and long-term maintainability.

## Rule Definition

This binding establishes immutability as the default approach for all data in your
system:

- **Default to Immutability**: Consider all data immutable unless there's a compelling
  reason otherwise. This applies to:

  - Function parameters (never modify what was passed in)
  - Return values (return new objects, not modified versions of inputs)
  - Internal data structures (create new versions rather than modifying in place)
  - Shared state (manage through controlled replacement rather than direct mutation)

- **Scope of Application**: This rule applies to all types of data structures:

  - Objects/maps/dictionaries
  - Arrays/lists/collections
  - Sets and other specialized data structures
  - Domain entities and value objects
  - Configuration data

- **Permitted Exceptions**: Direct mutation is only allowed in specific circumstances:

  - Performance-critical code where immutability creates a measurable bottleneck
  - Initialization phase of objects before they become visible to other components
  - Private implementation details that maintain immutable public interfaces
  - Language-specific idioms where immutability would violate platform conventions

- **Exception Requirements**: When implementing exceptions, you must:

  - Document the specific reason for allowing mutation
  - Contain mutation to the smallest possible scope
  - Keep mutations private, never exposing mutable objects across boundaries
  - Verify with benchmarks that immutability would create a real performance issue

The rule doesn't prohibit all state changes—systems would be useless without them—but
requires that state changes happen through creation of new data structures rather than
modification of existing ones.

## Practical Implementation

**Language Features for Immutability:**
```typescript
// TypeScript/JavaScript
const user = { name: "Alice", email: "alice@example.com" };
interface User {
  readonly id: string;
  readonly name: string;
}
```

```rust
// Rust - default to immutable bindings
let user = User { name: "Alice", email: "alice@example.com" };
let mut builder = UserBuilder::new(); // Only when necessary
```

**Immutable Update Patterns:**
```typescript
// Update objects and arrays
const updatedUser = { ...user, name: "Bob" };
const newItems = [...items, newItem];
const filteredItems = items.filter(item => item.id !== itemToRemove.id);
```

**Recommended Libraries:**
- JavaScript/TypeScript: Immer.js, Immutable.js, Redux Toolkit
- Java: Immutables, Vavr
- General: Seek persistent data structures and immutable transformations

**Enforcement:**
- ESLint rules: `no-param-reassign`, `prefer-const`
- Compiler flags: `--strict` (TypeScript)
- Code reviews and tests for immutability violations

## Examples

**Object Updates:**
```typescript
// ❌ BAD: Mutating objects directly
function updateUserPreferences(user, preferences) {
  user.preferences = { ...user.preferences, ...preferences };
  return user; // Modifies original!
}

// ✅ GOOD: Creating new objects
function updateUserPreferences(user, preferences) {
  return {
    ...user,
    preferences: { ...user.preferences, ...preferences }
  }; // Returns new object
}
```

**Array Operations:**
```javascript
// ❌ BAD: Mutating arrays
function addItem(cart, item) {
  cart.items.push(item);
  cart.total += item.price;
  return cart;
}

// ✅ GOOD: Creating new arrays
function addItem(cart, item) {
  return {
    ...cart,
    items: [...cart.items, item],
    total: cart.total + item.price
  };
}
```

**Method Design:**
```go
// ❌ BAD: Modifying receiver
func (c *Counter) Increment() { c.Value++ }

// ✅ GOOD: Returning new instances
func (c Counter) Increment() Counter {
  return Counter{Value: c.Value + 1}
}
```

## Related Bindings

- [dependency-inversion](../../docs/bindings/core/dependency-inversion.md): Makes code more testable and maintainable
- [hex-domain-purity](../../docs/bindings/core/hex-domain-purity.md): Keeps business logic stable and predictable
- [no-internal-mocking](../../docs/bindings/core/no-internal-mocking.md): Immutable data makes testing easier
