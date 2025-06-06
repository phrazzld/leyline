# Contributing to Leyline

Thank you for your interest in contributing to Leyline! This document provides
guidelines for proposing changes to our tenets and bindings.

> **Note**: This guide is for contributors to Leyline itself. If you're looking to integrate Leyline into your project, see the [Pull-Based Integration Guide](docs/integration/pull-model-guide.md).

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

### Front-Matter Standards

All tenet and binding documents **MUST** use YAML front-matter format for metadata. This
format is standardized across the project and is required for our toolchain to function
properly.

### Key Front-Matter Requirements

1. **Format**: Use YAML front-matter enclosed by triple dashes (`---`)
1. **Required Fields**:
   - For tenets: `id` and `last_modified`
   - For bindings: `id`, `last_modified`, `derived_from`, and `enforced_by`
1. **All dates** must be in ISO format (YYYY-MM-DD) and enclosed in quotes (e.g.,
   `'2025-05-09'`)

**Note**: The `applies_to` field has been deprecated. Binding applicability is now determined by its location in the directory structure:
- `/docs/bindings/core/` - Core bindings that apply to all projects
- `/docs/bindings/categories/<category>/` - Category-specific bindings

This directory-based organization supports Leyline's pull-based distribution model, allowing consumers to selectively sync only the categories relevant to their projects.

For detailed guidance on front-matter requirements, including examples, format
conversion, and troubleshooting, refer to [TENET_FORMATTING.md](TENET_FORMATTING.md).

## Development Setup

### Pre-commit Hooks (Mandatory)

To ensure quality and consistency, you must install pre-commit hooks that automatically validate your changes:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks in your local repository
pre-commit install

# Test hooks manually (optional)
pre-commit run --all-files
```

The pre-commit hooks will automatically:
- Validate YAML front-matter format and required fields
- Check index consistency with strict validation
- Fix trailing whitespace and ensure proper file endings
- Validate YAML syntax

### Manual Validation

You can also run validation tools manually before submitting your PR:

```bash
# Validate front-matter format and required fields
ruby tools/validate_front_matter.rb

# Regenerate index files
ruby tools/reindex.rb
```

### Markdown Guidelines

All markdown files in this repository should follow consistent style guidelines:

1. **Write clear, readable markdown** - Focus on content over strict formatting
2. **Use proper heading hierarchy** - Structure documents logically
3. **Maintain appropriate whitespace** - Use blank lines to separate content sections
4. **Be consistent with lists and indentation** - Follow standard markdown conventions

The pre-commit hooks will handle basic formatting like trailing whitespace and line endings.

## Guidelines for Specific Contributions

### Proposing a New Tenet

**Requirements:**

- PR must have the "tenet" label
- Must represent a fundamental, enduring principle
- Must follow the natural language style guidance

**File Structure:**

- Create file in `docs/tenets/` directory with a descriptive slug (e.g.,
  `simplicity.md`)
- Use the [tenet template](docs/templates/tenet_template.md) as your starting point
- Follow YAML front-matter format as specified in
  [TENET_FORMATTING.md](TENET_FORMATTING.md):
  ```yaml
  ---
  # Unique identifier for this tenet (must match filename without .md)
  id: your-tenet-slug
  # Date of last modification in ISO format with single quotes
  last_modified: '2025-05-09'
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

- Place the file in the appropriate directory based on its applicability:
  - `docs/bindings/core/` for bindings that apply to all projects
  - `docs/bindings/categories/<category>/` for category-specific bindings
    - Valid categories: `go`, `rust`, `typescript`, `cli`, `frontend`, `backend`

- Use a descriptive filename without category prefixes (e.g., `no-any.md` rather than `ts-no-any.md`)

- Use the [binding template](docs/templates/binding_template.md) as your starting point

- Follow YAML front-matter format as specified in
  [TENET_FORMATTING.md](TENET_FORMATTING.md):

  ```yaml
  ---
  # Unique identifier for this binding (must match filename without .md)
  id: your-binding-slug
  # Date of last modification in ISO format with single quotes
  last_modified: '2025-05-09'
  # ID of the parent tenet this binding implements
  derived_from: parent-tenet-id
  # Tool, rule, or process that enforces this binding
  enforced_by: description of enforcement mechanism
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

### Cross-Cutting Bindings Strategy

Some bindings may be applicable across multiple categories. When deciding where to place such bindings, follow these guidelines (see the [Implementation Guide](docs/implementation-guide.md) for detailed placement guidance):

1. **Core Bindings**:
   - Place a binding in `docs/bindings/core/` if:
     - It applies to virtually all projects regardless of language or context
     - It represents a fundamental principle that transcends specific languages or environments
     - It can be described in language-agnostic terms

2. **Category Bindings**:
   - Place a binding in `docs/bindings/categories/<category>/` if:
     - It applies primarily to a specific programming language or context
     - It uses language-specific syntax or features
     - It addresses concerns specific to a particular category

3. **Cross-Cutting Decision Process**:
   - Identify the primary category where the binding is most relevant
   - Place the binding in that primary category directory
   - In the binding document, clearly explain its applicability to other categories
   - Reference the binding from relevant documentation in other categories

### Editing Existing Documents

**For Tenets:**

- Changes should be clarifications, not fundamental alterations
- Update `last_modified` date to today's date in ISO format with single quotes (e.g.,
  `'2025-05-09'`)
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)
- Ensure the document uses YAML front-matter format for metadata as described in [TENET_FORMATTING.md](TENET_FORMATTING.md)

**For Bindings:**

- Can evolve more freely as implementation practices change
- Update `last_modified` date to today's date in ISO format with single quotes
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)
- Verify that all required front-matter fields are present and formatted correctly
- Ensure the document uses YAML front-matter format for metadata

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

Each release must maintain consistent front-matter standards in YAML format as described in [TENET_FORMATTING.md](TENET_FORMATTING.md).

When new content is released, consumers using the pull-based model can update at their own pace by adjusting the `leyline_ref` in their sync workflow. See the [Versioning Guide](docs/integration/versioning-guide.md) for consumer versioning best practices.

## Code of Conduct

All contributors are expected to adhere to our code of conduct, which emphasizes:

- Respectful, professional communication
- Evidence-based technical discussions
- Collaborative problem-solving

## Questions?

If you have questions about contributing, please open an issue with the "question"
label.
