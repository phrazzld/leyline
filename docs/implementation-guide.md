# Leyline Implementation Guide

> **Audience**: This guide is for **contributors to Leyline itself** - authors creating new tenets and bindings. If you're looking to integrate Leyline into your project, see the [Pull-Based Integration Guide](integration/pull-model-guide.md).

## Overview

This guide explains how to contribute new tenets and bindings to Leyline, focusing on the directory structure and organizational patterns that support the pull-based content distribution model.

## Understanding the Pull-Based Architecture

Leyline uses a hierarchical directory structure that enables consumers to selectively sync only the content relevant to their projects. As a contributor, understanding this architecture is crucial for placing your content appropriately.

### How Directory Structure Supports Pull-Based Sync

The directory organization directly maps to consumer filtering capabilities:

```
docs/
├── tenets/                 # Always synced to all consumers (12 total)
│   ├── simplicity.md
│   ├── testability.md
│   ├── orthogonality.md
│   ├── dry-dont-repeat-yourself.md
│   ├── fix-broken-windows.md
│   └── adaptability-and-reversibility.md
└── bindings/
    ├── core/               # Always synced to all consumers
    │   ├── pure-functions.md
    │   ├── dependency-inversion.md
    │   ├── yagni-pattern-enforcement.md
    │   ├── fail-fast-validation.md
    │   └── property-based-testing.md
    └── categories/         # Selectively synced based on consumer choice
        ├── go/             # Only synced when consumers request 'go'
        ├── rust/           # Only synced when consumers request 'rust'
        ├── typescript/     # Only synced when consumers request 'typescript'
        ├── frontend/       # Only synced when consumers request 'frontend'
        └── backend/        # Only synced when consumers request 'backend'
```

When consumers use the `sync-leyline-content.yml` workflow, they specify categories in their configuration:

```yaml
with:
  categories: go,typescript,frontend  # Only these categories are synced
```

This architecture provides:
- **Consumer Control**: Teams only receive relevant content
- **Reduced Noise**: No irrelevant bindings in consumer repositories
- **Scalability**: Easy to add new categories without affecting existing consumers
- **Explicit Choice**: Consumers make intentional decisions about what to adopt

## Contributing Tenets

Tenets represent universal principles that apply to all development contexts.

### Placement
- **Location**: `docs/tenets/`
- **Scope**: Universal principles, technology-agnostic
- **Consumer Impact**: Always synced to all consumers

### Guidelines
- Focus on fundamental development philosophy
- Avoid technology-specific references
- Ensure broad applicability across languages and contexts
- Use clear, concise language that translates across cultures

### Example Structure
```markdown
---
title: "Principle Name"
description: "Brief description of the principle"
category: "tenet"
---

# Principle Name

## What
Clear definition of the principle...

## Why
Rationale and benefits...

## How
Practical application guidance...
```

## Contributing Bindings

Bindings are enforceable rules derived from tenets, with varying levels of specificity.

### Core Bindings

**Placement**: `docs/bindings/core/`
**Scope**: Universal rules applicable to all projects
**Consumer Impact**: Always synced to all consumers

Core bindings should:
- Apply regardless of programming language
- Focus on architectural and design principles
- Avoid technology-specific implementation details
- Provide broad guidance that teams can adapt

**Examples**:
- `pure-functions.md` - Functional programming principles
- `dependency-inversion.md` - Architectural patterns
- `yagni-pattern-enforcement.md` - YAGNI implementation patterns
- `fail-fast-validation.md` - Input validation and crash early patterns
- `system-boundaries.md` - Component isolation and orthogonality

### Category-Specific Bindings

**Placement**: `docs/bindings/categories/<category>/`
**Scope**: Rules specific to particular languages or contexts
**Consumer Impact**: Only synced when consumers request the category

#### Available Categories

| Category | Purpose | Consumer Usage |
|----------|---------|----------------|
| `go` | Go language-specific patterns | Go projects |
| `rust` | Rust language-specific patterns | Rust projects |
| `typescript` | TypeScript/JavaScript patterns | TypeScript/JS projects |
| `frontend` | Web/UI application patterns | Frontend applications |
| `backend` | Server-side patterns | Backend services |

#### Category Selection Guidelines

**Choose `core/` when**:
- Rule applies universally across all technologies
- Principle is language-agnostic
- Guidance doesn't require specific syntax

**Choose `categories/<category>/` when**:
- Rule uses language-specific syntax or features
- Guidance is tailored to specific technology constraints
- Implementation details are context-dependent

### Binding Structure

```markdown
---
title: "Binding Name"
description: "Brief description of the rule"
category: "binding"
difficulty: "beginner|intermediate|advanced"
tags: ["tag1", "tag2"]
---

# Binding Name

## Rule
Clear, enforceable statement...

## Rationale
Why this rule exists...

## Implementation
How to apply this rule...

## Examples
Code examples (if applicable)...

## Exceptions
When this rule might not apply...
```

## Pragmatic Programming Integration

Leyline's philosophy has been enhanced with insights from "The Pragmatic Programmer" and modern software engineering best practices. This integration strengthens the existing tenets while adding new principles that reflect decades of accumulated wisdom in software development.

### Enhanced Philosophy: From 8 to 12 Tenets

The original eight tenets have been expanded to twelve, incorporating four new foundational principles derived from pragmatic programming wisdom:

#### New Tenets from Pragmatic Programming

1. **[Orthogonality](../tenets/orthogonality.md)** - "Eliminate Effects Between Unrelated Things"
   - **Origin**: Pragmatic Programmer Tip #17
   - **Focus**: Component independence and isolation
   - **Key Bindings**: [system-boundaries](../bindings/core/system-boundaries.md), [component-isolation](../bindings/core/component-isolation.md)

2. **[DRY (Don't Repeat Yourself)](../tenets/dry-dont-repeat-yourself.md)** - Knowledge Representation Management
   - **Origin**: Pragmatic Programmer Tip #15
   - **Focus**: Single source of truth for all knowledge
   - **Key Bindings**: [extract-common-logic](../bindings/core/extract-common-logic.md), [normalized-data-design](../bindings/core/normalized-data-design.md)

3. **[Adaptability and Reversibility](../tenets/adaptability-and-reversibility.md)** - "There Are No Final Decisions"
   - **Origin**: Pragmatic Programmer Tip #18
   - **Focus**: Change management and flexible architecture
   - **Key Bindings**: [feature-flag-management](../bindings/core/feature-flag-management.md), [runtime-adaptability](../bindings/core/runtime-adaptability.md)

4. **[Fix Broken Windows](../tenets/fix-broken-windows.md)** - Quality Management
   - **Origin**: Pragmatic Programmer Tip #4
   - **Focus**: Preventing quality decay through immediate action
   - **Key Bindings**: [automated-quality-gates](../bindings/core/automated-quality-gates.md), [technical-debt-tracking](../bindings/core/technical-debt-tracking.md)

#### Enhanced Existing Tenets

Four existing tenets have been strengthened with additional pragmatic programming concepts:

- **[Simplicity](../tenets/simplicity.md)**: Enhanced with YAGNI principles, good-enough software, and tracer bullet development
- **[Explicit over Implicit](../tenets/explicit-over-implicit.md)**: Enhanced with plain text power and crash early patterns
- **[Maintainability](../tenets/maintainability.md)**: Enhanced with "gently exceed expectations" and knowledge portfolio investment
- **[Testability](../tenets/testability.md)**: Enhanced with ruthless testing and property-based testing approaches

### Enhanced Bindings from Pragmatic Principles

The pragmatic programming integration has produced new bindings that implement these enhanced concepts:

- **[yagni-pattern-enforcement](../bindings/core/yagni-pattern-enforcement.md)**: Implements YAGNI principles from enhanced simplicity
- **[fail-fast-validation](../bindings/core/fail-fast-validation.md)**: Implements crash early patterns from enhanced explicitness
- **[continuous-learning-investment](../bindings/core/continuous-learning-investment.md)**: Implements knowledge portfolio from enhanced maintainability
- **[property-based-testing](../bindings/core/property-based-testing.md)**: Implements property-based testing from enhanced testability

### Adoption Guidance for Pragmatic Integration

Teams adopting these enhanced principles should consider:

#### Incremental Adoption Strategy
1. **Start with Enhanced Existing Tenets**: Teams familiar with simplicity, explicitness, maintainability, and testability can immediately benefit from the pragmatic enhancements
2. **Add New Tenets Gradually**: Introduce orthogonality, DRY, adaptability, and broken windows concepts as architectural decisions arise
3. **Implement Supporting Bindings**: Use the new bindings to enforce the enhanced principles systematically

#### Priority Framework
- **High Priority**: Fix Broken Windows (immediate quality impact)
- **Medium Priority**: YAGNI and Fail-Fast patterns (development velocity impact)
- **Long-term**: Adaptability patterns and Learning Investment (strategic capability)

#### Integration with Existing Practices
- **Code Reviews**: Use enhanced bindings as review criteria
- **Architecture Decisions**: Apply orthogonality and adaptability principles
- **Technical Debt**: Use broken windows approach for quality management
- **Knowledge Management**: Apply DRY principles to documentation and processes

## File Naming and Organization

### Naming Conventions
- Use descriptive, hyphenated filenames: `no-any-types.md`
- Avoid language prefixes: Use `error-handling.md` not `go-error-handling.md`
- Keep names concise but clear
- Use present tense for rules: `use-explicit-types.md`

### Front Matter Requirements
- `title`: Human-readable title
- `description`: Brief summary for indexes
- `category`: "tenet" or "binding"
- `difficulty`: Helps consumers understand complexity
- `tags`: Enables better discovery and organization

### Directory Placement Decision Tree

```
Is this content applicable to ALL projects?
├─ Yes → docs/tenets/ (if philosophical principle)
│       └─ docs/bindings/core/ (if enforceable rule)
└─ No → Which specific context?
         ├─ Language-specific → docs/bindings/categories/<language>/
         ├─ Context-specific → docs/bindings/categories/<context>/
         └─ Multiple contexts → Choose primary, document others in content
```

## Supporting Pull-Based Consumption

### Cross-References
When creating content that relates to other tenets or bindings:
- Use relative paths: `[Related Tenet](../tenets/simplicity.md)`
- Consider that consumers may not have all categories
- Provide context for references to category-specific content

### Consumer Considerations
Remember that your content will be consumed by diverse teams:
- Provide clear, actionable guidance
- Include rationale for rules
- Consider different team sizes and experience levels
- Make content self-contained where possible

### Testing Your Contributions
Before submitting:
1. Ensure proper front matter format
2. Validate markdown syntax
3. Check that file placement aligns with category guidelines
4. Verify cross-references work correctly
5. Consider how content appears in different consumer contexts

## Integration with Workflow

The `sync-leyline-content.yml` workflow automatically:
- Syncs all tenets to consumers
- Syncs all core bindings to consumers
- Selectively syncs requested categories
- Generates updated indexes
- Handles cleanup of outdated content

As a contributor, you don't need to modify the workflow - proper file placement ensures correct distribution.

## Related Documentation

- **[Pull-Based Integration Guide](integration/pull-model-guide.md)**: How consumers integrate Leyline
- **[Migration Guide](migration-guide.md)**: How consumers migrate to new patterns
- **[Consumer Examples](../examples/consumer-workflows/)**: Working integration examples

---

**Questions?** Open an issue or discussion for guidance on content placement or contribution patterns.
