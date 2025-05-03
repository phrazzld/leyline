# Contributing to Leyline

Thank you for your interest in contributing to Leyline! This document provides guidelines for proposing changes to our tenets and bindings.

## Core Principles

Leyline maintains two types of documents:

1. **Tenets**: Immutable truths and principles that guide our development philosophy
2. **Bindings**: Enforceable rules derived from tenets, with specific implementation guidance

## Proposing Changes

### Process Overview

1. Fork the repository
2. Create a branch with a descriptive name
3. Make your changes following the guidelines below
4. Run validation tools locally
5. Submit a pull request with the appropriate label (`tenet` or `binding`)

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

**File Structure:**
- Create file in `tenets/` directory with a descriptive slug (e.g., `simplicity.md`)
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

  A concise description of the principle (≤ 150 chars).

  ## Core Belief

  Detailed explanation of the underlying belief.

  ## Practical Guidelines

  1. **First Guideline**: Explanation
  2. **Second Guideline**: Explanation
  ...

  ## Warning Signs

  - Signs that this principle is being violated
  ...

  ## Related Tenets

  - [Other Tenet](/tenets/other-tenet.md): Brief connection
  ...
  ```

### Proposing a New Binding

**Requirements:**
- PR must have the "binding" label
- Must be derived from an existing tenet
- Must be enforceable (through tools, reviews, etc.)

**File Structure:**
- Create file in `bindings/` directory with a descriptive slug (e.g., `ts-no-any.md`)
- Follow front-matter format:
  ```yaml
  ---
  id: your-binding-slug
  last_modified: "YYYY-MM-DD"
  derived_from: parent-tenet-id
  enforced_by: description of enforcement mechanism
  ---
  ```
- Use the standard markdown structure:
  ```markdown
  # Binding: Your Binding Title

  A concise description of the rule (≤ 150 chars).

  ## Rationale

  Detailed explanation of why this rule matters.

  ## Enforcement

  This binding is enforced by:

  1. Mechanism one
  2. Mechanism two
  ...

  ## Guidelines

  Specific implementation guidance.

  ## Examples

  ```language
  // ❌ BAD: Anti-pattern example
  code here

  // ✅ GOOD: Correct pattern
  code here
  ```

  ## Related Bindings

  - [Other Binding](/bindings/other-binding.md): Brief connection
  ...
  ```

### Editing Existing Documents

**For Tenets:**
- Changes should be clarifications, not fundamental alterations
- Update `last_modified` date

**For Bindings:**
- Can evolve more freely as implementation practices change
- Update `last_modified` date

## Release Process

- **Patch Releases** (typo fixes, clarifications): Quick review and merge
- **MINOR Releases** (new bindings): Standard review process
- **MAJOR Releases** (new/changed tenets, breaking binding changes): More thorough review

## Code of Conduct

All contributors are expected to adhere to our code of conduct, which emphasizes:
- Respectful, professional communication
- Evidence-based technical discussions
- Collaborative problem-solving

## Questions?

If you have questions about contributing, please open an issue with the "question" label.