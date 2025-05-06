# Philosophy to Tenets & Bindings Audit Template

## Purpose

This template provides a structured approach for auditing source philosophy documents to ensure complete coverage in tenets and bindings. It helps identify gaps where important principles or rules from the source documents haven't been properly represented in the Leyline system.

## Instructions

1. Create a new audit file for each source document you're analyzing
1. Work through the document section by section, identifying key principles and rules
1. Map each identified item to existing tenets and bindings, or mark as a gap
1. Use the resulting gap analysis to create new tenets and bindings

## Audit File Format

```markdown
# Audit: [Source Document Name]

**Source Path**: [Path to source document]
**Audit Date**: YYYY-MM-DD
**Auditor**: [Name/ID]

## Section: [Section Name/Number]

### Key Principle 1: [Brief description]

**Source Text**:
> [Quote the relevant text from the source document]

**Coverage**:
- [ ] Fully covered
- [ ] Partially covered
- [ ] Not covered

**Mapped To**:
- Tenet: [tenet-id or "NONE"]
- Bindings: [binding-id, binding-id, or "NONE"]

**Gap Analysis**:
[Description of what aspects are missing or incomplete in current coverage]

**Recommendation**:
- [ ] Create new tenet
- [ ] Create new binding(s)
- [ ] Update existing tenet/binding
- [ ] No action needed

### Key Principle 2: [Brief description]

[... repeat for each principle ...]

## Summary

**Total Principles Identified**: [Number]
**Fully Covered**: [Number]
**Partially Covered**: [Number]
**Not Covered**: [Number]

**New Tenets Needed**:
1. [Proposed tenet title]
2. [...]

**New Bindings Needed**:
1. [Proposed binding title]
2. [...]
```

## Example

```markdown
# Audit: DEVELOPMENT_PHILOSOPHY.md

**Source Path**: /Users/phaedrus/Development/codex/docs/DEVELOPMENT_PHILOSOPHY.md
**Audit Date**: 2025-05-03
**Auditor**: Claude

## Section: Core Principles

### Key Principle 1: Simplicity First

**Source Text**:
> Always seek the simplest possible solution that correctly meets the requirements. Actively resist and eliminate unnecessary complexity.

**Coverage**:
- [x] Fully covered

**Mapped To**:
- Tenet: simplicity
- Bindings: ts-no-any, hex-domain-purity

**Gap Analysis**:
The core principle is well-covered in the simplicity tenet, but some specific guidelines on how to identify and eliminate complexity are missing.

**Recommendation**:
- [ ] Create new binding: "avoid-premature-abstraction"

### Key Principle 2: Explicit over Implicit

**Source Text**:
> Make dependencies, data flow, control flow, contracts, and side effects clear and obvious. Avoid hidden conventions, global state, or complex implicit mechanisms.

**Coverage**:
- [x] Fully covered

**Mapped To**:
- Tenet: explicit-over-implicit
- Bindings: NONE

**Gap Analysis**:
The principle is covered at the tenet level, but no specific bindings enforce this principle.

**Recommendation**:
- [x] Create new binding: "explicit-dependency-injection"
- [x] Create new binding: "no-globals"
```

## Recommended Workflow

1. **Preparation**:

   - Clone this template for each source document
   - Gather all source philosophy documents
   - List all existing tenets and bindings for reference

1. **Systematic Analysis**:

   - Work through each document section by section
   - Be thorough and precise in identifying both explicit and implicit principles
   - Quote actual text to maintain fidelity to the source

1. **Gap Identification**:

   - Be honest about coverage gaps
   - Consider not just presence but quality of coverage
   - Look for areas where the principles might be diluted or modified

1. **Follow-up**:

   - Prioritize gap remediation
   - Create missing tenets and bindings
   - Track completion
