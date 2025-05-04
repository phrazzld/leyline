---
id: ts-no-any
last_modified: "2025-05-04"
derived_from: simplicity
enforced_by: eslint("@typescript-eslint/no-explicit-any") & tsconfig("noImplicitAny")
applies_to:
  - typescript
---

# Binding: No `any` in TypeScript

Never use the `any` type in TypeScript code. It defeats TypeScript's type safety system, undermines the compiler's ability to catch errors, and introduces unnecessary complexity and uncertainty into your codebase.

## Rationale

This binding directly implements our simplicity tenet by eliminating a major source of accidental complexity in TypeScript codebases. When you use `any`, you're essentially creating a "type hole" that undermines TypeScript's primary benefit: static type checking. This introduces uncertainty and cognitive overhead for every developer who interacts with that code.

Think of TypeScript's type system as a safety net that catches errors before they reach production. When you use `any`, you're cutting holes in that safety net. These holes not only allow errors to slip through where `any` is used, but they can spread throughout your codebase as untyped values propagate, creating a cascade of uncertainty. What seems like a quick convenience in the moment becomes a significant maintenance burden over time.

The complexity cost of `any` isn't just about potential bugs. It's also about the mental overhead required to work with the code. Without proper types, developers must constantly keep implementation details in their head rather than relying on the compiler to verify correctness. This contradicts our simplicity principle by making code harder to reason about, maintain, and extend.

## Rule Definition

The `any` type in TypeScript is essentially an escape hatch from the type system. When you declare a variable, parameter, or return type as `any`, you're telling the TypeScript compiler to stop checking types for that piece of code. This means:

- The compiler won't validate operations on that value
- Properties and methods can be accessed without verification
- The value can be assigned to any other type without warning
- Type errors involving that value won't be caught until runtime (if ever)

This binding prohibits using `any` in all its forms, including:

- Explicit declarations (`let x: any`)
- Implicit use through disabled configuration (`noImplicitAny: false`)
- Type assertions to `any` (`as any`)
- Generic instantiations with `any` (`Map<string, any>`)

Consider `any` as a last resort that should trigger an immediate refactoring. In the rare case where you genuinely cannot type something (such as when interfacing with untyped third-party code), contain the `any` to the smallest possible scope and document clearly why it's necessary.

## Practical Implementation

To effectively implement this binding in your TypeScript projects:

1. **Configure your tooling** to prevent `any` from being introduced:
   - Enable the TypeScript compiler option `"noImplicitAny": true` in your `tsconfig.json`
   - Add the ESLint rule `"@typescript-eslint/no-explicit-any": "error"` to your linting configuration

2. **Prefer `unknown` for top-type needs**. When you need a type that can hold any value but want to maintain type safety, use `unknown` instead of `any`. Unlike `any`, `unknown` requires type checking before you can perform operations on it:
   ```typescript
   // With unknown, you must verify the type before using it
   function processInput(input: unknown): string {
     if (typeof input === 'string') {
       return input.toUpperCase(); // Type-safe because we've verified it's a string
     }
     return String(input);
   }
   ```

3. **Use union types for values that could be one of several specific types**:
   ```typescript
   // Union types are more precise than 'any'
   function formatValue(value: string | number | boolean): string {
     return String(value);
   }
   ```

4. **Leverage generics for flexible, type-safe functions and interfaces**:
   ```typescript
   // Generics preserve type information
   function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
     return obj[key];
   }
   ```

5. **Create proper interfaces** for structured data. When working with objects, define interfaces that accurately describe their structure:
   ```typescript
   interface User {
     id: string;
     name: string;
     email?: string;
   }
   
   function processUser(user: User): void {
     // TypeScript ensures we're using valid properties
   }
   ```

6. **For existing code with `any`**, incrementally refactor using the strategies above. Start with the most critical paths and areas with the most reuse, as these will give the biggest return on investment.

## Examples

```typescript
// ❌ BAD: Using 'any' creates type holes
function processData(data: any): any {
  return data.value * 2; // No type checking! This could easily crash
}

const result = processData("not an object"); // Runtime error: Cannot read property 'value' of undefined
const total: number = result + 10; // TypeScript won't catch that 'result' might not be a number
```

```typescript
// ✅ GOOD: Using proper types ensures correctness
interface DataWithValue {
  value: number;
}

function processData(data: DataWithValue): number {
  return data.value * 2; // Type safe!
}

// TypeScript would catch this error during compilation
// const result = processData("not an object"); // Error: Argument of type 'string' is not assignable to parameter of type 'DataWithValue'

const validData = { value: 5 };
const result = processData(validData); // Works as expected
const total: number = result + 10; // Type safe
```

```typescript
// ❌ BAD: Using 'any' for API responses
async function fetchUserData(): Promise<any> {
  const response = await fetch('/api/user');
  return response.json();
}

// Later in code:
const user = await fetchUserData();
console.log(user.nmae); // Typo won't be caught by TypeScript
```

```typescript
// ✅ GOOD: Using interfaces for API responses
interface User {
  id: string;
  name: string;
  email: string;
}

async function fetchUserData(): Promise<User> {
  const response = await fetch('/api/user');
  return response.json() as User;
}

// Later in code:
const user = await fetchUserData();
console.log(user.nmae); // TypeScript error: Property 'nmae' does not exist on type 'User'. Did you mean 'name'?
```

```typescript
// ❌ BAD: Using 'any' for uncertain function parameters
function handleEvent(event: any) {
  // We have no idea what this event is
  event.stopPropagation();
  console.log(event.target.value);
}
```

```typescript
// ✅ GOOD: Using 'unknown' with type guards for uncertain parameters
function handleEvent(event: unknown) {
  // We need to check what kind of event this is
  if (isMouseEvent(event)) {
    event.stopPropagation();
    console.log('Mouse position:', event.clientX, event.clientY);
  } else if (isKeyboardEvent(event)) {
    event.stopPropagation();
    console.log('Key pressed:', event.key);
  }
}

// Type guard functions
function isMouseEvent(event: unknown): event is MouseEvent {
  return event instanceof MouseEvent;
}

function isKeyboardEvent(event: unknown): event is KeyboardEvent {
  return event instanceof KeyboardEvent;
}
```

## Related Bindings

- [immutable-by-default](/bindings/immutable-by-default.md): Works together with this binding to reduce complexity by making data flow more predictable; both bindings eliminate common sources of runtime errors.

- [hex-domain-purity](/bindings/hex-domain-purity.md): Complements this binding by ensuring domain logic remains pure and well-typed, further enhancing code safety and simplicity.

- [no-lint-suppression](/bindings/no-lint-suppression.md): Reinforces this binding by preventing teams from bypassing type checking rules with lint suppressions or similar mechanisms.