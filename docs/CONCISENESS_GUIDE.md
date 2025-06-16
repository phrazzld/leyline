# Conciseness Guide for Leyline Documentation

This guide establishes writing principles to ensure leyline documents are tight, punchy, terse, concise, and direct. Following these guidelines prevents the accumulation of verbose content that obscures core principles.

## Target Lengths

**Tenets**: Maximum 150 lines
- Core philosophy documents that establish principles
- Focus on the "why" behind beliefs
- Single, clear metaphor or example

**Bindings**: Maximum 400 lines
- Implementation guidance derived from tenets
- Focus on actionable rules and patterns
- One comprehensive example demonstrating the pattern

## The One Example Rule

**Show the pattern once, clearly, rather than multiple times in different languages.**

❌ **Verbose Approach**: Show the same concept in JavaScript, Python, Java, Go, and Rust
❎ **Better**: Show the concept in JavaScript with notes about language-agnostic principles
✅ **Best**: Show one comprehensive example that demonstrates the pattern clearly

Choose the most appropriate language for your audience:
- **TypeScript/JavaScript**: For web, CLI, and general development patterns
- **Python**: For data processing, scripting, and backend patterns
- **Go**: For systems programming and concurrency patterns
- **Rust**: For memory safety and performance-critical patterns

## Document Structure Template

### For Tenets (150 lines max)
```
# Tenet: [Name]

[One-sentence summary of the core principle]

## Core Belief
[2-3 paragraphs explaining the philosophy and why it matters]

## Practical Guidelines
[3-5 actionable guidelines with clear action verbs]

## Warning Signs
[5-8 specific indicators organized in logical groups]

## Related Tenets
[Cross-references with brief explanations of relationships]
```

### For Bindings (400 lines max)
```
# Binding: [Name]

[One-sentence summary connecting to parent tenet]

## Implementation Rules
[3-5 specific, actionable rules]

## Example Implementation
[One comprehensive example with good/bad contrast]

## Integration Requirements
[Specific requirements for adoption]

## Related Bindings
[Cross-references with relationship explanations]
```

## Writing Principles

### Lead with Value
Start every document with the core value proposition. Answer "why should I care?" in the first paragraph.

### Use Active Voice
- ✅ "Create explicit interfaces"
- ❌ "Explicit interfaces should be created"

### Choose Precise Verbs
- ✅ "Eliminate", "Prevent", "Establish", "Implement"
- ❌ "Handle", "Deal with", "Work with", "Manage"

### Cut Redundant Explanations
If you've explained a concept once clearly, don't re-explain it. Use cross-references instead.

### Focus on Outcomes
Describe what the reader will achieve, not just what they should do.

## Common Verbosity Patterns to Avoid

### Tool-Specific Configuration Details
❌ **Verbose**: Include complete webpack.config.js, package.json, and CI configuration
✅ **Concise**: Show the essential pattern with a note about implementation details

### Multi-Language Example Repetition
❌ **Verbose**: Show factory pattern in JavaScript, Python, Java, and Go
✅ **Concise**: Show one clear factory pattern example with language-agnostic principles

### Repetitive Bullet Point Lists
❌ **Verbose**: 6 sections each with 8-10 bullet points covering similar concepts
✅ **Concise**: 3 focused sections with the essential points

### Over-Explanation of Concepts
❌ **Verbose**: Explain the same principle from multiple angles across several paragraphs
✅ **Concise**: One clear explanation with a concrete example

## Quality Gates

Before submitting any tenet or binding:

1. **Length Check**: Run `ruby tools/check_document_length.rb` to verify compliance
2. **One Example Audit**: Confirm you're showing each pattern once, not multiple times
3. **Value Density**: Every paragraph should advance understanding of the core principle
4. **Action Clarity**: Guidelines should contain specific, actionable verbs

## Examples of Effective Conciseness

### Good Tenet Example (64 lines)
The `maintainability.md` tenet demonstrates effective conciseness:
- Clear one-sentence opening that captures the essence
- Core belief section that explains "why" without repetition
- Practical guidelines with specific action verbs
- Warning signs organized into logical categories
- Related tenets with brief relationship explanations

### Good Binding Example (202 lines)
The `test-pyramid-implementation.md` binding shows effective pattern demonstration:
- Single comprehensive TypeScript example showing 70/20/10 distribution
- Clear good/bad contrast within one example
- Language-agnostic principles explained alongside specific code
- No repetitive multi-language implementations

## Enforcement

This guide is enforced through:
- Pre-commit hooks that block oversized documents
- GitHub Actions that validate document length on all PRs
- PR template checklist requiring conciseness review
- Regular audit of existing documents for compliance

## Continuous Improvement

This guide evolves based on community feedback and document quality outcomes. When adding new patterns or examples, prioritize proven approaches over theoretical guidelines.
