# Natural Language Style Guide for Tenets and Bindings

## Introduction and Purpose

This style guide defines the approach for writing tenets and bindings with a "natural language first" mindset. The goal is to optimize these documents to serve as effective context for large language models (LLMs) while maintaining their philosophical integrity and utility for human readers.

While our previous approach prioritized technical explicitness and enforceability, this updated approach emphasizes principles, rationales, and patterns (the "why" and "what") alongside technical implementation details (the "how"). This makes our documents more accessible and interpretable by both humans and AI systems.

Use this guide when:
- Creating new tenets or bindings
- Rewriting existing tenets or bindings 
- Reviewing tenet or binding content for quality and alignment

## Tone and Voice

### Conversational Tone

Use a conversational, accessible tone that feels like a knowledgeable colleague explaining important principles:

- **Use active voice** to create direct, engaging content
  - ✅ "Start with the 'why' before explaining implementation details."
  - ❌ "Implementation details should be explained after the 'why' is presented."

- **Address the reader directly** when providing guidance
  - ✅ "When you encounter circular dependencies, refactor to break the cycle."
  - ❌ "Circular dependencies should be refactored to break the cycle."

- **Avoid excessive formality** that creates distance
  - ✅ "This approach prevents bugs and makes your code easier to test."
  - ❌ "The aforementioned methodology facilitates the reduction of defects and enhances testability."

- **Limit jargon**, and when necessary, explain it
  - ✅ "Practice 'YAGNI' (You Aren't Gonna Need It) by avoiding speculative abstractions."
  - ❌ "Adhere to YAGNI principles to minimize superfluous abstraction layers."

### Relatable Language

Connect principles to human experience and understanding:

- **Use analogies** to explain complex concepts
  - ✅ "Think of immutability like a recipe card: you can make many cookies from one recipe without changing the original instructions."
  - ❌ "Immutability ensures data is not modified after creation."

- **Tell micro-stories** when explaining patterns
  - ✅ "When a developer encounters this code later, they'll immediately understand what it does without having to decode clever tricks."
  - ❌ "Readability is prioritized over cleverness."

- **Use real-world consequences** to illustrate importance
  - ✅ "Without explicit error handling, bugs can silently propagate through the system, only becoming visible in unexpected places far from their source."
  - ❌ "Proper error handling is required."

## Structure and Organization

### Principle-First Approach

Always lead with the "why" before moving to the "what" and "how":

- **Start with underlying principles** before implementation details
  - ✅ "We isolate domain logic to protect it from infrastructure concerns, ensuring our core business rules remain pure and testable. This is implemented through a hexagonal architecture pattern."
  - ❌ "Implement hexagonal architecture pattern. This separates domain and infrastructure."

- **Emphasize patterns over syntax** 
  - ✅ "Ensure functions have a single responsibility and clear purpose. For example, separate data validation from business processing."
  - ❌ "Functions should call validateInput() before calling processData()."

- **Use examples to illustrate concepts**, not just to show syntax
  - ✅ "Consider a user service that depends directly on a database client. This creates tight coupling that makes testing difficult. Instead, define an interface that the database client implements, allowing you to substitute a test double during testing."
  - ❌ "Use interfaces to enable mocking of dependencies. Example: `interface DBClient { query(): Result }`"

### Context and Connections

Explicitly connect ideas and establish relationships:

- **Connect bindings to parent tenets** clearly
  - ✅ "This binding implements our simplicity tenet by eliminating accidental complexity that comes from mixing concerns."
  - ❌ "This binding enforces separation of concerns."

- **Establish relationships** between related concepts
  - ✅ "While our modularity tenet focuses on component boundaries, this explicitness tenet addresses how those components should communicate."
  - ❌ "This tenet is related to modularity."

- **Provide sufficient context** for independent understanding
  - ✅ "In strongly typed languages like TypeScript, using 'any' effectively opts out of the type system. This defeats the purpose of using TypeScript and eliminates the safety net that static typing provides."
  - ❌ "Don't use 'any' in TypeScript."

### Narrative Structure

Organize content to tell a coherent story:

- **Follow a problem → principle → solution → examples flow**
  - 1. Describe the problem or challenge
  - 2. Explain the principle that addresses it
  - 3. Present the solution approach
  - 4. Illustrate with concrete examples

- **Frame rules as solutions** to common problems
  - ✅ "Developers often struggle with understanding code that relies on implicit behaviors. By making dependencies explicit, we create code that clearly communicates its needs and assumptions."
  - ❌ "Dependencies must be explicit."

- **Include rationales that tell the story** of why the rule exists
  - ✅ "This rule emerged from our experience with subtle bugs caused by mutation. When data can change unexpectedly, it becomes difficult to reason about program state."
  - ❌ "Mutation causes bugs."

## Language Patterns

### Preferred Patterns

These patterns make content more accessible for both humans and LLMs:

- **Define terms before using them**
  - ✅ "Pure functions—those which always produce the same output for a given input and have no side effects—are easier to test and reason about."
  - ❌ "Use pure functions for better testability."

- **Use consistent terminology** throughout the document
  - ✅ Consistently use "component" rather than alternating between "component," "module," and "unit"
  - ❌ "Components should be small. Modules should have clear boundaries. Units should be testable."

- **Balance abstract principles with concrete examples**
  - ✅ "Prefer composition over inheritance. For example, instead of creating a complex inheritance hierarchy for different report types, compose reports from reusable formatting and data components."
  - ❌ "Always choose composition over inheritance as it's more flexible."

- **Use parallel structure** for similar concepts
  - ✅ "Testing validates that your code works. Linting ensures your code follows conventions. Typing verifies your code is type-safe."
  - ❌ "Testing is important for validation. Your code should follow linting rules. Type safety is ensured by typing."

### Anti-Patterns to Avoid

Patterns that reduce clarity and effectiveness:

- **Unexplained acronyms or project-specific terminology**
  - ✅ "The Single Responsibility Principle (SRP) states that a class should have only one reason to change."
  - ❌ "Follow SRP to reduce coupling."

- **Technical details without principles**
  - ✅ "We use ESLint with strict configuration to catch potential issues early. This implements our principle of catching problems at their source rather than in production."
  - ❌ "Set 'strict: true' in your ESLint config."

- **Excessive focus on tooling over principles**
  - ✅ "The principle of automated verification means we never rely on manual checks for quality. We implement this through continuous integration pipelines that run tests, linters, and security scans."
  - ❌ "Set up GitHub Actions to run on every PR."

- **Vague or absolute language** without nuance
  - ✅ "In most cases, mutable state increases complexity and should be isolated. There are rare exceptions, such as performance-critical code sections, where controlled mutation may be acceptable."
  - ❌ "Never use mutable state."

## Examples

### Example: Tenet Explanation (Good)

```markdown
## Core Belief

Simplicity is a fundamental requirement for building high-quality, maintainable software, not just a nice-to-have goal. When you write simple code, you're making an investment in the future health of your project. Simple code is easier to understand when you return to it months later, easier to debug when something goes wrong, and easier to extend when requirements change.

Complexity, on the other hand, is the primary source of bugs, development friction, and long-term maintenance costs. Each additional layer of complexity creates exponential growth in the mental overhead needed to work with the code. What seems manageable today becomes a burden tomorrow as the codebase grows.
```

### Example: Tenet Explanation (Bad)

```markdown
## Core Belief

Simplicity is a key tenet. Complex code has more bugs and is harder to maintain. Simple code should be prioritized. Unnecessary complexity should be avoided at all costs. KISS principle should be followed.
```

### Example: Binding Rule Definition (Good)

```markdown
## Rule Definition

TypeScript's 'any' type effectively tells the compiler to stop checking types for a particular variable or return value. While this might seem convenient in the short term, it creates a "type hole" that undermines TypeScript's primary benefit: static type checking.

When you use 'any', you're essentially opting out of the type system for that piece of code. This isn't just a minor stylistic concern—it breaks the contract between different parts of your application and eliminates the safety net that type checking provides. Type errors that could have been caught at compile time now become runtime errors, often in production.

Consider 'any' as a last resort, used only in very specific circumstances where you truly cannot type something, such as when interfacing with untyped third-party code you don't control. Even then, try to contain the 'any' type to the smallest possible scope.
```

### Example: Binding Rule Definition (Bad)

```markdown
## Rule Definition

The 'any' type is not allowed in TypeScript. Use more specific types. The 'any' type defeats type checking. ESLint should be configured to prohibit 'any'.
```

### Example: Practical Implementation (Good)

```markdown
## Practical Implementation

To implement dependency inversion effectively in your codebase:

1. Identify high-level components that depend on low-level implementation details. For example, a UserService that directly imports and uses a specific database client.

2. Define interfaces that abstract the capabilities you need from those low-level components. Focus on what you need, not how it's implemented. For instance, create a `DataStore` interface with methods like `findById`, `save`, etc.

3. Make your high-level components depend on these interfaces rather than concrete implementations. Have your UserService take a `DataStore` as a parameter rather than creating a specific database client.

4. Provide concrete implementations of these interfaces in composition roots or factory methods, where you assemble your application.

5. For existing code, use the "Strangler Fig" pattern: incrementally refactor by introducing interfaces alongside existing code, then gradually switch over.
```

### Example: Practical Implementation (Bad)

```markdown
## Practical Implementation

Use interfaces. Don't depend directly on implementations. Inject dependencies. Create factories for object creation. Use DI containers if available.
```

## Checklist for Review

When reviewing or writing tenets and bindings, check if the document:

- [ ] Uses active voice and conversational tone
- [ ] Addresses the reader directly when providing guidance
- [ ] Explains the "why" before the "what" and "how"
- [ ] Connects explicitly to parent tenets (for bindings)
- [ ] Establishes clear relationships with other tenets/bindings
- [ ] Follows a narrative structure (problem → principle → solution → examples)
- [ ] Defines terms before using them
- [ ] Uses consistent terminology throughout
- [ ] Balances abstract principles with concrete examples
- [ ] Avoids unexplained acronyms or project-specific terminology
- [ ] Includes rationales that tell the story of why the rule exists
- [ ] Provides sufficient context for independent understanding
- [ ] Uses examples to illustrate concepts, not just syntax

## Further Reading

- The Leyline DEVELOPMENT_PHILOSOPHY.md (in source directory)
- Tenet Template: [templates/tenet_template.md](templates/tenet_template.md)
- Binding Template: [templates/binding_template.md](templates/binding_template.md)