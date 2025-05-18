______________________________________________________________________

id: no-any derived_from: simplicity enforced_by: eslint("@typescript-eslint/no-explicit-any") & tsconfig("noImplicitAny") last_modified: '2025-01-15'

______________________________________________________________________

# Binding: Make Types Explicit, Never Use `any`

Never use the `any` type in TypeScript code. Instead, always create proper type
definitions that accurately describe your data structures and API contracts. The `any`
type defeats TypeScript's safety mechanisms and undermines the compiler's ability to
catch errors.

## Rationale

This binding implements our explicit-over-implicit tenet by requiring you to clearly
express types rather than hiding them behind an escape hatch.

Think of TypeScript's type system like a detailed map for your code. When you mark
something as `any`, it's like drawing a blank area on that map labeled "here be
dragons."

## Rule Definition

The `any` type in TypeScript is an escape hatch that effectively opts out of type
checking. When you use `any`, you're telling the compiler to trust you blindly,
regardless of what operations you perform.
