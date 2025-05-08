# Contributing to Leyline

Thank you for your interest in contributing to Leyline! This document provides
guidelines for proposing changes to our tenets and bindings.

## Core Principles

Leyline maintains two types of documents:

1. **Tenets**: Immutable truths and principles that guide our development philosophy
1. **Bindings**: Enforceable rules derived from tenets, with specific implementation
   guidance

## Natural Language First Approach

Leyline adopts a "natural language first" approach to documentation. This means our
tenets and bindings are written to be:

1. **Accessible to humans** with different technical backgrounds
1. **Effective as context for large language models (LLMs)**
1. **Principle-focused** rather than implementation-focused

All new tenets and bindings should follow this approach. Please refer to our
[Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md) for detailed
writing guidelines and examples.

## Proposing Changes

### Process Overview

1. Fork the repository
1. Create a branch with a descriptive name
1. Make your changes following the guidelines below
1. Run validation tools locally
1. Submit a pull request with the appropriate label (`tenet` or `binding`)

### Validation

Before submitting your PR, please run the following validation tools locally:

```bash
# Validate front-matter format and required fields
ruby tools/validate_front_matter.rb

# Regenerate index files
ruby tools/reindex.rb

# If you have the tools installed, run formatting check
mdformat --check .
```

## Guidelines for Specific Contributions

### Proposing a New Tenet

**Requirements:**

- PR must have the "tenet" label
- Must represent a fundamental, enduring principle
- Must follow the natural language style guidance

**File Structure:**

- Create file in `tenets/` directory with a descriptive slug (e.g., `simplicity.md`)
- Use the [tenet template](docs/templates/tenet_template.md) as your starting point
- Follow front-matter format:
  ```yaml
  ---
  id: your-tenet-slug
  last_modified: "YYYY-MM-DD"
  ---
  ```
- Use the standard markdown structure:
  ```markdown
  # Tenet: Your Tenet Title

  [A concise 1-2 sentence principle statement that captures the essence of this tenet in plain, accessible language.]

  ## Core Belief

  [2-4 paragraphs explaining why this principle matters, using a conversational tone and relatable analogies.]

  ## Practical Guidelines

  1. **First Guideline**: [Explanation of how to apply the principle in practical terms]
  2. **Second Guideline**: [Another practical application of the principle]
  ...

  ## Warning Signs

  - **First Warning Sign**: [Description of behavior indicating the principle is being violated]
  ...

  ## Related Tenets

  - [Simplicity](docs/tenets/simplicity.md): [Explanation of how these tenets relate to each other]
  ...
  ```

### Proposing a New Binding

**Requirements:**

- PR must have the "binding" label
- Must be derived from an existing tenet
- Must be enforceable (through tools, reviews, etc.)
- Must follow the natural language style guidance

**File Structure:**

- Create file in `bindings/` directory with a descriptive slug (e.g., `ts-no-any.md`)

- Use the [binding template](docs/templates/binding_template.md) as your starting point

- Follow front-matter format:

  ```yaml
  ---
  id: your-binding-slug
  last_modified: "YYYY-MM-DD"
  derived_from: parent-tenet-id
  enforced_by: description of enforcement mechanism
  applies_to:
    - language or context
  ---
  ```

- Use the standard markdown structure:

  ````markdown
  # Binding: Your Binding Title

  [A concise 1-2 sentence statement of the rule in plain language.]

  ## Rationale

  [2-3 paragraphs explaining why this rule exists and how it connects to the parent tenet. Include analogies where appropriate to make abstract concepts more relatable.]

  ## Rule Definition

  [Clear, conversational explanation of the rule, its scope, and boundaries.]

  ## Practical Implementation

  [Actionable guidelines for implementing the rule in different contexts.]

  ## Examples

  ```language
  // ❌ BAD: Anti-pattern example
  code here

  // ✅ GOOD: Correct pattern
  code here
  ````

  ## Related Bindings

  - [Dependency Inversion](docs/bindings/dependency-inversion.md): \[Explanation of how
    these bindings work together or complement each other\] ...

  ```

  ```

### Editing Existing Documents

**For Tenets:**

- Changes should be clarifications, not fundamental alterations
- Update `last_modified` date
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)

**For Bindings:**

- Can evolve more freely as implementation practices change
- Update `last_modified` date
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)

## Writing Effective Natural Language Documentation

To create effective documentation that works well for both humans and LLMs, follow these
key principles:

1. **Principle-First Approach**: Start with the "why" before moving to the "how"
1. **Conversational Tone**: Use active voice and direct address
1. **Relatable Analogies**: Use analogies to explain complex concepts
1. **Clear Connections**: Establish explicit relationships between related concepts
1. **Narrative Structure**: Follow a problem → principle → solution → examples flow
1. **Balanced Detail**: Provide enough detail for understanding without overwhelming

For detailed guidance with examples, see the
[Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md).

## Release Process

- **Patch Releases** (typo fixes, clarifications): Quick review and merge
- **MINOR Releases** (new bindings): Standard review process
- **MAJOR Releases** (new/changed tenets, breaking binding changes): More thorough
  review

## Code of Conduct

All contributors are expected to adhere to our code of conduct, which emphasizes:

- Respectful, professional communication
- Evidence-based technical discussions
- Collaborative problem-solving

## Questions?

If you have questions about contributing, please open an issue with the "question"
label.
