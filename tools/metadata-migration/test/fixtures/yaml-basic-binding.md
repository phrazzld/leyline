---
id: pure-functions
derived_from: testability
enforced_by: code review & architecture guidelines
last_modified: '2025-01-15'
---

# Binding: Prefer Pure Functions Where Possible

Write pure functions that depend only on their inputs and produce consistent outputs
without side effects. Pure functions should make up the majority of your codebase,
with impure functions isolated at system boundaries.

## Rationale

This binding implements our testability tenet by creating functions that are trivially
easy to test. Pure functions are the gold standard of testability—they require no
setup, no mocks, and produce deterministic results.

Think of pure functions like mathematical equations. The function `f(x) = x * 2` always
returns the same output for the same input, regardless of when or where you calculate
it. This predictability makes pure functions incredibly reliable building blocks for
larger systems.

## Rule Definition

A pure function must satisfy two requirements:

1. **Deterministic**: Given the same inputs, it always returns the same output
2. **No Side Effects**: It doesn't modify any external state (files, databases,
   network, global variables, or even its input parameters)

## Examples

```typescript
// ❌ BAD: Impure function with side effects
function processUser(user: User): void {
  user.processedAt = new Date(); // Modifies input
  database.save(user); // External state change
  console.log(`Processed ${user.name}`); // I/O operation
}
```

```typescript
// ✅ GOOD: Pure function
function processUser(user: User): ProcessedUser {
  return {
    ...user,
    processedAt: new Date().toISOString()
  };
}
```
