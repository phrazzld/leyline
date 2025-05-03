---
id: binding-id  # Unique identifier for this binding (kebab-case)
last_modified: "YYYY-MM-DD"  # ISO format date of last modification
derived_from: parent-tenet-id  # ID of the parent tenet this binding implements
enforced_by: [enforcement mechanism]  # Tool, rule, or process that enforces this binding
applies_to:  # Languages or contexts where this binding applies
  - language/context
---

# Binding: [Rule Name]

[A concise 1-2 sentence statement of the rule in plain language. Focus on clarity and directness without technical jargon if possible. This statement should clearly communicate what the rule requires or prohibits.]

## Rationale

[Write a 2-3 paragraph natural language explanation of why this rule exists and the benefits it provides. This section should:

1. Connect explicitly to the parent tenet, explaining how this binding serves the tenet's principle
2. Focus on the problems this rule solves and the value it delivers
3. Explain the reasoning in terms of patterns and principles rather than just technical details

Use a conversational tone that helps the reader understand not just what the rule is, but why it matters and how it contributes to the overall quality of the codebase.]

## Rule Definition

[Provide a clear, conversational explanation of the rule itself. Rather than just listing technical specifications, explain concepts with examples and analogies where appropriate. When technical specifics are needed, explain the "why" behind them.

This section should define the scope and boundaries of the rule, clarifying what is included and excluded. It should make the rule unambiguous while still keeping the focus on principles rather than syntax alone.]

## Practical Implementation

[Offer actionable guidelines for implementing the rule in different contexts. This may include:

1. Language-specific approaches, but focused on patterns rather than just syntax
2. Common scenarios developers will encounter and how to handle them
3. Strategies for migrating existing code to comply with the rule
4. Tooling, configuration, or automation that can help enforce the rule

Focus on providing practical, principle-based guidance that helps developers apply the rule effectively in their daily work.]

## Examples

[Provide concrete examples that illustrate both good and bad implementations. For each example:

1. Show the problematic code or pattern first, labeling it clearly as an anti-pattern
2. Show the improved approach that follows the binding
3. Explain why each example is good or bad from a principle perspective, not just technical correctness
4. Where possible, demonstrate the real-world benefits or consequences of following or violating the rule

Code examples should be clear, focused, and representative of real-world scenarios developers are likely to encounter.]

```language
// ❌ BAD: Brief description of what's wrong
// Anti-pattern example

// ✅ GOOD: Brief description of what's right
// Positive example that follows the binding
```

## Related Bindings

[List links to related bindings with brief explanations of the relationships. Explain how this binding connects to, complements, or is distinguished from other bindings. This helps create a network of understanding across the binding system.]

- [binding-name.md](./binding-filename.md): [Brief explanation of relationship]
- [binding-name.md](./binding-filename.md): [Brief explanation of how these rules interact]