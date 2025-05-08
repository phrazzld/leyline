# Integrating Tenets and Bindings with Large Language Models

This guide outlines strategies for effectively using Leyline's tenets and bindings as context for Large Language Models (LLMs) to enhance code quality, maintain consistency with development standards, and automate aspects of code review.

## Introduction

Leyline's tenets and bindings have been rewritten with a "natural language first" approach specifically designed to:

1. **Make principles more accessible to humans** of different technical backgrounds
2. **Serve as effective context for Large Language Models (LLMs)**
3. **Focus on principles and patterns** rather than implementation details

This document explains how to leverage these documents with LLMs to improve your development workflows, code quality, and adherence to principles.

## Why Natural Language Documentation Works Better with LLMs

Traditional technical documentation often focuses on low-level implementation details using terse, technical language. This presents challenges for LLMs for several reasons:

1. **Context Limitations**: LLMs have finite context windows, so documentation that's concise yet comprehensive has advantages
2. **Principle Understanding**: LLMs understand principles better than highly technical specifics
3. **Reasoning Capabilities**: LLMs reason more effectively with natural language explanations than with prescriptive rules

Our natural language approach addresses these limitations by:

- **Using conversational language** that models can interpret more accurately
- **Including relatable analogies** that help models grasp abstract concepts
- **Focusing on the "why"** behind rules, which models can apply to novel situations
- **Providing explicit connections** between related concepts, which models can leverage for reasoning

## General Strategies for Using Tenets and Bindings as LLM Context

### 1. Selective Context Inclusion

Rather than including all tenets and bindings in every prompt, select the most relevant ones for your specific task:

- **For architectural decisions**: Include high-level tenets like simplicity, modularity, and maintainability
- **For language-specific implementation**: Include relevant bindings (e.g., ts-no-any for TypeScript projects)
- **For specific concerns**: Include targeted tenets/bindings (e.g., automation for CI/CD tasks)

### 2. Context Ordering

The order of context matters for LLMs. Structure your prompts for maximum effectiveness:

1. Begin with the most relevant tenet(s) to establish core principles
2. Follow with specific bindings that implement those principles
3. Place the most directly relevant content earlier in the prompt

### 3. Explicit References

When asking the LLM to apply principles or rules, explicitly reference the relevant documents:

```
Apply the principles from the "Simplicity Above All" tenet and the "Immutable by Default" binding to refactor this code...
```

### 4. Staged Processing

For complex tasks, use a multi-stage approach:

1. First prompt: Ask the LLM to analyze which tenets/bindings are relevant to the task
2. Second prompt: Include only those relevant documents as context and perform the task

## Prompt Engineering Techniques

### Template for Code Review

```
I'll provide you with code that needs review according to our development principles.
First, I'll share relevant tenets and bindings, then the code to review.

TENET: [Paste tenet content here]

BINDING: [Paste binding content here]

CODE TO REVIEW:
```code
[Your code here]
```

Please review this code based on the provided tenets and bindings.
For each issue:
1. Identify the specific principle or rule that's violated
2. Explain why it's problematic
3. Suggest a concrete improvement
```

### Template for Code Generation

```
I need you to help me implement [feature/component description].
Our codebase follows these principles and rules:

TENET: [Paste tenet content here]

BINDING: [Paste binding content here]

ADDITIONAL CONTEXT:
- [Any project-specific context or constraints]

Please generate code that implements this feature while following our principles.
Explain your design choices and how they align with the provided tenets and bindings.
```

### Template for Refactoring

```
I have code that needs refactoring to better align with our development principles.

TENET: [Paste tenet content here]

BINDING: [Paste binding content here]

CURRENT CODE:
```code
[Your code here]
```

Please refactor this code to better follow our principles. Explain:
1. What aspects of the current code violate our principles
2. How your refactoring addresses these issues
3. Any trade-offs you considered
```

## Best Practices

### 1. Provide Sufficient Context

Always include:
- The relevant tenets and bindings
- Project-specific context that might override general principles
- Constraints or requirements that must be met

### 2. Be Specific in Your Requests

Clearly state what you want the LLM to do:
- "Evaluate if this code follows the immutability binding"
- "Suggest changes to make this code more modular"
- "Explain how this code could be simplified following our simplicity tenet"

### 3. Use Multi-turn Conversations

Build context over multiple interactions:
1. Start with general guidance and principles
2. Refine based on the LLM's responses
3. Ask for specific applications of principles to your code

### 4. Address Limitations

Be aware of LLM limitations:
- Models may not understand complex, project-specific abstractions without explanation
- Programming languages evolve, and models may not be aware of the latest features
- Models may need guidance on prioritizing when different principles conflict

## Managing Context Length

Most LLMs have context length limitations. To manage this:

1. **Summarize tenets and bindings** when appropriate, focusing on the core principles
2. **Use selective inclusion** rather than providing all documentation
3. **Create shortened versions** of the most frequently used tenets and bindings
4. **Split complex tasks** into smaller sub-tasks with focused context

### Example: Shortened Version of a Tenet

```
TENET (Simplicity): Prefer the simplest design that solves the problem.
Complexity causes defects and cognitive overload. Use YAGNI (You Aren't
Gonna Need It) rigorously, minimize moving parts, and value readability
over cleverness. Warning signs include over-engineering, premature
abstraction, and designing for imagined future requirements.
```

## Integration Approaches

### 1. Direct Inclusion in Prompts

The simplest approach is to directly copy relevant tenets and bindings into your prompts. This works well for:
- One-off coding tasks
- Code reviews of specific files or functions
- Explaining principles to team members

### 2. Retrieval-Augmented Generation (RAG)

For more sophisticated applications, implement a RAG system:
1. Convert all tenets and bindings to embeddings
2. Store in a vector database
3. When a query comes in, find the most relevant documents
4. Include only those documents in the context

### 3. Custom Agents and Tools

Build custom tools that can:
- Automatically retrieve relevant tenets and bindings based on the task
- Enforce compliance with key principles
- Guide developers through the application of principles

### 4. IDE Integration

Consider integrating with development environments:
- VS Code extensions that can insert relevant tenets/bindings
- Git hooks that check for compliance with principles
- CI/CD integrations that enforce bindings

## Provider-Specific Guidance

### OpenAI (GPT-4, etc.)

- **Context Window**: Efficiently use the 8K-32K token context window
- **Function Calling**: Define functions that retrieve relevant tenets/bindings
- **System Instructions**: Use system instructions to establish consistent application of principles

### Anthropic (Claude)

- **Longer Context**: Take advantage of Claude's larger context window for more comprehensive inclusion
- **Xml Tags**: Structure your prompts with XML tags for clear organization
- **Conversational Style**: Claude works well with the conversational style of the rewritten documents

### Open Source Models

- **More Explicit Guidance**: May need more explicit instructions to apply principles correctly
- **Repetition**: Consider restating key principles in different ways for reinforcement
- **Concrete Examples**: Include more examples of principles in action

## Limitations and Considerations

1. **Model Knowledge Cutoffs**: LLMs may not be aware of the latest technological developments
2. **Inconsistent Application**: Models may apply principles inconsistently without careful prompting
3. **Over-reliance**: Use LLMs as assistants rather than replacements for human judgment
4. **Context Collapse**: Very large contexts may cause models to lose focus on specific principles
5. **Prioritization**: Models may struggle to prioritize when principles conflict

## Concrete Examples

Below are practical examples of how to use tenets and bindings effectively with LLMs for different use cases. These examples include actual content from Leyline documents with complete prompts you can adapt for your needs.

### Example 1: Code Review Against Simplicity Tenet

This example shows how to review code for compliance with the Simplicity tenet.

```
I'll provide you with code that needs review according to our development principles.
First, I'll share our Simplicity tenet, then the code to review.

TENET: # Tenet: Simplicity Above All

Prefer the simplest design that solves the problem completely. Complexity is the root cause of most software defects, maintenance challenges, and cognitive overload. Rigorously seek solutions with the fewest moving parts.

## Core Belief

Simplicity is a fundamental requirement for building high-quality, maintainable software, not just a nice-to-have goal. When you write simple code, you're making an investment in the future health of your project. Simple code is easier to understand when you return to it months later, easier to debug when something goes wrong, and easier to extend when requirements change.

## Warning Signs

- **Over-engineering solutions** by creating elaborate frameworks or systems for simple problems. If you're building infrastructure that far exceeds current requirements, you're likely introducing unnecessary complexity.
- **Designing for imagined future requirements** rather than actual needs. Focus on solving today's real problems, not tomorrow's hypothetical ones.
- **Premature abstraction** before seeing multiple concrete use cases. Wait until you see the same pattern at least three times before abstracting.
- **Implementing overly clever or obscure code** that requires significant mental effort to understand.
- **Deep nesting (> 2-3 levels)** of conditionals, loops, or functions, creating code that requires keeping multiple contexts in mind simultaneously.

CODE TO REVIEW:
```typescript
class DataProcessor {
  private cache = new Map<string, any>();
  private processors: Map<string, (data: any) => any> = new Map();
  private static instance: DataProcessor;

  private constructor() {
    // Initialize with default processors
    this.processors.set("uppercase", (data: string) => data.toUpperCase());
    this.processors.set("lowercase", (data: string) => data.toLowerCase());
    this.processors.set("reverse", (data: string) => data.split("").reverse().join(""));
  }

  public static getInstance(): DataProcessor {
    if (!DataProcessor.instance) {
      DataProcessor.instance = new DataProcessor();
    }
    return DataProcessor.instance;
  }

  public registerProcessor(name: string, processor: (data: any) => any): void {
    this.processors.set(name, processor);
  }

  public process(data: any, operations: string[]): any {
    const cacheKey = JSON.stringify({ data, operations });

    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    let result = data;

    for (const op of operations) {
      const processor = this.processors.get(op);
      if (processor) {
        result = processor(result);
      }
    }

    this.cache.set(cacheKey, result);
    return result;
  }

  public clearCache(): void {
    this.cache.clear();
  }
}

// Usage
const processor = DataProcessor.getInstance();
processor.registerProcessor("double", (data: string) => data + data);
const result = processor.process("hello", ["uppercase", "double"]);
console.log(result); // HELLOHELLO
```

Please review this code based on the Simplicity tenet. For each issue:
1. Identify the specific principle or rule that's violated
2. Explain why it's problematic
3. Suggest a concrete improvement
```

### Example 2: Error Handling Guidance with Go Error Wrapping Binding

This example shows how to request guidance on implementing proper error handling in Go.

```
I'm implementing a Go service that interacts with a database and external API.
Please help me design proper error handling based on our binding document below.

BINDING: # Binding: Add Context to Errors as They Travel Upward

When errors cross package boundaries in Go, wrap them with contextual information using `fmt.Errorf("context: %w", err)` or custom error types. Never return raw errors from exported functions.

## Rationale

Think of error wrapping like a travel journal for an error's journey through your codebase. When a raw error travels across your application without being wrapped, it's like a mysterious visitor with no record of where they've been or what they were trying to do. By wrapping the error at each significant boundary—adding an entry to its travel journal—you create a clear path of breadcrumbs showing exactly where it originated and what operations failed along the way.

## Rule Definition

Error wrapping means adding contextual information to an error as it travels up the call stack, while preserving the original error for type checking and root cause analysis. At minimum, this context should include:

1. The operation that was attempted (e.g., "fetching user profile")
2. Any relevant identifiers (e.g., user IDs, record numbers)
3. Additional information that would help with debugging

## Practical Implementation

### When to Wrap Errors

Always wrap errors when:
- Returning an error from an exported function
- Crossing major component boundaries
- Adding significant context would help with debugging

Generally avoid wrapping when:
- The error is already wrapped with the same context
- The function is internal to a package and doesn't add meaningful context
- Creating sentinel errors meant to be checked by type/value (these should be returned directly)

I need to implement a function that:
1. Fetches user data from a database
2. Calls an external API to get additional user information
3. Combines and returns the results

Please provide a code example showing proper error handling according to our binding, including:
- Appropriate error wrapping at package boundaries
- Custom error types if beneficial
- Examples of checking for specific error types
```

### Example 3: Refactoring TypeScript Code to Remove 'any' Types

This example demonstrates using the ts-no-any binding to guide refactoring.

```
I need to refactor this TypeScript code to remove all uses of 'any' according to our binding.

BINDING: # Binding: Make Types Explicit, Never Use `any`

Never use the `any` type in TypeScript code. Instead, always create proper type definitions that accurately describe your data structures and API contracts. The `any` type defeats TypeScript's safety mechanisms and undermines the compiler's ability to catch errors.

## Rationale

Think of TypeScript's type system like a detailed map for your code. When you mark something as `any`, it's like drawing a blank area on that map labeled "here be dragons." While explorers once used this phrase to mark unknown territories, modern software doesn't have room for such uncertainty. Each `any` type creates a blind spot where TypeScript can't provide guidance, intellisense help, or error checking.

## Alternative Approaches

1. **Use `unknown` instead of `any` for values of uncertain type**
2. **Create proper interfaces for structured data**
3. **Use union types for values that could be one of several types**
4. **Use generics for flexible, type-safe functions**
5. **For third-party libraries without types, use declaration files or minimally-scoped type assertions**

CODE TO REFACTOR:
```typescript
function processApiResponse(response: any): any {
  const results = response.data || [];
  return results.map((item: any) => {
    return {
      id: item.id,
      name: item.name,
      value: item.count * 2,
      metadata: item.meta
    };
  });
}

async function fetchAndProcess(url: string): Promise<any> {
  try {
    const response = await fetch(url);
    const data = await response.json();
    return processApiResponse(data);
  } catch (error: any) {
    console.error("Error fetching data:", error.message);
    return [];
  }
}

function handleData(callback: (data: any) => any): void {
  const data = { foo: "bar" };
  const result = callback(data);
  console.log(result);
}
```

Please refactor this code to remove all 'any' types, following our binding principles. For each change:
1. Explain what type you're using instead of 'any'
2. Why that type is appropriate
3. How it improves type safety
```

### Example 4: Architecture Evaluation with Explicit-over-Implicit Tenet

This example shows how to evaluate an architecture design against the Explicit-over-Implicit tenet.

```
I'm designing an architecture for a new service and want to ensure it follows our Explicit-over-Implicit tenet. Please evaluate my approach and suggest improvements.

TENET: # Tenet: Explicit is Better than Implicit

Make code behavior obvious by clearly expressing dependencies, data flow, control flow, contracts, and side effects. Favor code that states its intentions directly over "magical" solutions, even when explicitness requires more code or initial effort.

## Core Belief

Software development is fundamentally about managing complexity, and explicitness is one of our most powerful tools for doing so. When code is explicit, its behavior, assumptions, and dependencies are visible on the surface rather than hidden beneath layers of abstraction or convention.

## Practical Guidelines

1. **Make Dependencies Explicit**: Express dependencies directly rather than accessing them through global state, ambient context, or hidden singletons.

2. **Reveal Control Flow**: Structure code so the path of execution is clear and obvious.

3. **Signal Side Effects**: Make it obvious when a function or method does more than compute a return value.

4. **Express Contracts Clearly**: Define the expectations and guarantees of each component explicitly.

5. **Choose Clarity Over Convenience**: Prioritize code that clearly communicates its intent over code that saves a few keystrokes.

## Warning Signs

- **"Magic" behavior** that happens automatically without clear indication in the code
- **Global state or hidden singletons** that components access implicitly
- **Undocumented assumptions about execution context** or environment
- **Complex inheritance hierarchies or mixins** that make behavior difficult to trace

MY ARCHITECTURE PROPOSAL:

I'm designing a service that processes financial transactions with these components:

1. HTTP API Layer: Express.js controllers that accept requests
2. Service Layer: Contains business logic using a service locator pattern
3. Data Access Layer: Repositories for database operations
4. Shared Utilities: Global logger, config, and error handlers

Key aspects:
- Services discover dependencies through a central registry
- Configuration loaded from environment variables at startup
- Authentication middleware automatically attaches user info to request objects
- Database connection managed by a singleton pool
- Aspect-oriented programming for cross-cutting concerns like logging

Please evaluate this architecture against our Explicit-over-Implicit tenet and suggest improvements to make it more explicit.
```

### Example 5: Combining Multiple Bindings for Code Generation

This example demonstrates combining multiple bindings to guide code generation.

```
Please help me generate code for a new Go function based on several of our bindings.

BINDING 1: # Binding: Add Context to Errors as They Travel Upward

When errors cross package boundaries in Go, wrap them with contextual information using `fmt.Errorf("context: %w", err)` or custom error types. Never return raw errors from exported functions.

BINDING 2: # Binding: Immutable by Default

Design data structures to be immutable by default. Modification operations should return new copies rather than mutating existing data. Only permit mutation when there's a clear performance need and the scope of mutation is tightly controlled.

BINDING 3: # Binding: Use Structured Logging

Always use structured logging (with key-value pairs) instead of string interpolation or string concatenation in log messages. Every log statement must include appropriate context and correlation IDs to enable trace aggregation.

TASK:
I need to implement a function that processes a batch of customer records, validates them, and returns an error report. The function should:

1. Accept a slice of customer records
2. Validate each record against business rules
3. Return a report containing invalid records and errors
4. Follow all the bindings above

Please generate the function with appropriate:
- Error handling with proper context
- Immutable data processing
- Structured logging
- Well-defined types
- Documentation comments
```

## Future Directions

As LLM technology evolves, consider:

1. **Fine-tuning models** specifically on your tenets and bindings
2. **Creating embeddings** that better represent your principles
3. **Building custom agents** that specialize in applying your specific principles
4. **Automating compliance checks** based on LLM evaluation

---

By following these strategies, you can effectively leverage Leyline's natural language tenets and bindings with LLMs to improve code quality, maintain consistency with development standards, and streamline development workflows.
