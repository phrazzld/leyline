---
# Unique identifier for this binding (must be kebab-case, matching the filename without .md)
id: binding-id

# Date of last modification in ISO format (YYYY-MM-DD) with single quotes
last_modified: '2025-05-09'

# Version of the repository when this binding was last modified
# This should match the current VERSION file. Update when making changes.
version: '0.2.0'

# ID of the parent tenet this binding implements (must be an existing tenet ID)
derived_from: tenet-id

# Tool, rule, or process that enforces this binding
enforced_by: '[enforcement mechanism]'
---

# Binding: \[Rule Name\]

\[A concise 1-2 sentence statement of the rule in plain language. Focus on clarity and
directness without technical jargon if possible. This statement should clearly
communicate what the rule requires or prohibits.\]

## Rationale

\[Write a 2-3 paragraph natural language explanation of why this rule exists and the
benefits it provides. This section should:

1. Connect explicitly to the parent tenet, explaining how this binding serves the
   tenet's principle (e.g., "This binding directly implements our simplicity tenet by
   eliminating a major source of accidental complexity...")
1. Focus on the problems this rule solves and the value it delivers
1. Explain the reasoning in terms of patterns and principles rather than just technical
   details

Consider using analogies to make abstract concepts more relatable (e.g., "Think of
TypeScript's type system as a safety net that catches errors before they reach
production..."). Analogies help readers connect technical concepts to familiar
experiences.

Use a conversational tone that helps the reader understand not just what the rule is,
but why it matters and how it contributes to the overall quality of the codebase.
Address the consequences of not following this rule in terms of maintenance burden,
cognitive overhead, or other real costs.\]

## Rule Definition

\[Provide a clear, conversational explanation of the rule itself. Rather than just
listing technical specifications, explain concepts with examples and analogies where
appropriate. When technical specifics are needed, explain the "why" behind them.

Consider using bullet points to clearly outline different aspects of the rule, which
forms it takes, or what specifically is prohibited or required. For example:

- What the rule applies to
- What is explicitly prohibited
- Common forms of violation to watch for

This section should define the scope and boundaries of the rule, clarifying what is
included and excluded. It should make the rule unambiguous while still keeping the focus
on principles rather than syntax alone.

Include guidance on exceptions if they exist, and how to handle edge cases where the
rule might reasonably be bent. Explain when exceptions might be appropriate and how to
minimize their impact (e.g., "In the rare case where you genuinely cannot follow this
rule, contain the exception to the smallest possible scope and document clearly why it's
necessary.").\]

## Practical Implementation

\[Offer actionable guidelines for implementing the rule in different contexts. Structure
this as a numbered list with bold headings for each implementation strategy. This may
include:\]

1. **\[Implementation Strategy\]**: \[Explanation of how to implement this aspect of the
   rule. Be specific about tooling, configuration, or patterns to use. Include code
   snippets where appropriate to illustrate the approach.\]

1. **\[Implementation Strategy\]**: \[Explanation of another approach, potentially for a
   different scenario or context. Focus on patterns rather than just syntax, but provide
   enough technical detail to be actionable.\]

1. **\[Alternative Approach\]**: \[Explanation of alternatives to common anti-patterns.
   Show how to accomplish the same goal while following the rule. Include code examples
   where helpful.\]

1. **\[Migration Strategy\]**: \[Guidance on how to migrate existing non-compliant code.
   Suggest incremental approaches that prioritize high-impact areas first.\]

1. **\[Tooling and Enforcement\]**: \[Information about how to configure tools, linters,
   or processes to enforce this rule automatically where possible.\]

\[Focus on providing practical, principle-based guidance that helps developers apply the
rule effectively in their daily work. Include enough detail to be immediately useful
without requiring further research.\]

## Examples

\[Provide 2-3 pairs of concrete examples that illustrate both good and bad
implementations. For each example:

1. Show the problematic code or pattern first, labeling it clearly as an anti-pattern
1. Show the improved approach that follows the binding
1. Explain why each example is good or bad from a principle perspective, not just
   technical correctness
1. Where possible, demonstrate the real-world benefits or consequences of following or
   violating the rule

Choose examples that represent different scenarios or aspects of the rule. Start with
simpler examples and progress to more complex ones. Code examples should be clear,
focused, and representative of real-world scenarios developers are likely to
encounter.\]

```language
// ❌ BAD: Brief description of what's wrong
// Anti-pattern example

// ✅ GOOD: Brief description of what's right
// Positive example that follows the binding
```

```language
// ❌ BAD: Brief description of another common issue
// Another anti-pattern example that shows a different aspect of the rule

// ✅ GOOD: Brief description of the proper approach
// Positive example showing how to address this issue correctly
```

```language
// ❌ BAD: Brief description of a more subtle or complex violation
// More complex anti-pattern example

// ✅ GOOD: Brief description of the comprehensive solution
// More complex positive example that demonstrates best practices
```

## Related Bindings

\[List links to related bindings with brief explanations of the relationships. Explain
how this binding connects to, complements, or is distinguished from other bindings.
Focus on how they work together functionally to achieve broader goals.\]

- [binding-name.md](binding-filename.md): \[Explanation of relationship that focuses on
  how these bindings work together or complement each other. Explain how following both
  leads to better outcomes.\]

- [binding-name.md](binding-filename.md): \[Explanation of how these rules interact
  functionally, including any potential tensions and how to balance them effectively.\]
