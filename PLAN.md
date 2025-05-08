# PLAN: Rewrite Tenets and Bindings with Natural Language First Approach

## Goal

Transform Leyline's tenets and bindings to prioritize natural language and readability,
optimizing them to serve as more effective context for large language models (LLMs)
while maintaining their philosophical integrity and utility.

## Background and Rationale

Current tenets and bindings are structured primarily for technical explicitness and
enforceability, with a focus on deterministic configurations and actions. While this
serves human developers well for specific implementation guidance, it creates
limitations when these documents are used as contextual information for LLMs.

When LLMs consume these documents as context, a more natural language approach that
emphasizes the principles, rationales, and patterns (the "why" and "what") rather than
just the technical implementation (the "how") will provide more effective guidance. This
rewrite aims to preserve the core philosophical content while making it more accessible
and interpretable by both humans and AI.

## Architecture and Approach

### Content Structure

1. **Maintain Front-Matter Metadata**

   - Continue using YAML front-matter for machine readability
   - Preserve all existing fields (`id`, `last_modified`, `derived_from`, `enforced_by`,
     `applies_to`)
   - Front-matter will remain deterministic and machine-parsable

1. **Revised Tenet Structure**

   ```markdown
   ---
   id: tenet-id
   last_modified: "YYYY-MM-DD"
   ---

   # Tenet: [Principle Name]

   [Concise principle statement in plain language that captures the essence]

   ## Core Belief

   [Natural language explanation of the underlying principle, focusing on the "why". Written in a conversational,
   accessible style that LLMs can effectively interpret and apply.]

   ## Practical Guidelines

   [Bulleted list of concrete ways this principle manifests in development practices. Each guideline should be
   actionable but focused on patterns rather than specific technical implementations.]

   ## Warning Signs

   [Bulleted list of indicators that this principle is being violated, written in natural language with examples.]

   ## Related Tenets

   [Links to related tenets with brief explanations of the relationships.]
   ```

1. **Revised Binding Structure**

   ```markdown
   ---
   id: binding-id
   last_modified: "YYYY-MM-DD"
   derived_from: parent-tenet-id
   enforced_by: [enforcement mechanism]
   applies_to: [languages/contexts]
   ---

   # Binding: [Rule Name]

   [Concise statement of the rule in plain language]

   ## Rationale

   [Natural language explanation of why this rule exists and the benefits it provides. Connect explicitly to the
   parent tenet. Focus on principles and patterns rather than specific technical implementations.]

   ## Rule Definition

   [Clear, conversational explanation of the rule. Use examples to illustrate concepts rather than just technical
   specifications. When technical specifics are needed, explain the "why" behind them.]

   ## Practical Implementation

   [Guidelines for implementing the rule in different contexts. May include language-specific approaches but
   focused on patterns and principles rather than just syntax.]

   ## Examples

   [Concrete examples that illustrate both good and bad implementations, with explanations of why each is
   good or bad from a principle perspective, not just technical correctness.]

   ## Related Bindings

   [Links to related bindings with brief explanations of the relationships.]
   ```

### Natural Language Guidelines

1. **Conversational Tone**

   - Use active voice and direct address
   - Avoid jargon where possible; when necessary, explain it
   - Write as if explaining to a developer who understands programming but not your
     specific conventions

1. **Principle-First Approach**

   - Start with the "why" before moving to the "what" and "how"
   - Emphasize patterns and principles over syntax and specifics
   - Use examples to illustrate concepts, not just to show syntax

1. **Context and Connections**

   - Explicitly connect bindings to their parent tenets
   - Establish clear relationships between related tenets and bindings
   - Provide sufficient context for each rule to be understood independently

1. **Narrative Structure**

   - Use narrative flow: problem → principle → solution → examples
   - Frame rules as solutions to common problems rather than isolated directives
   - Include rationales that tell the story of why the rule exists

## Implementation Plan

### Phase 1: Framework and Templates (Week 1)

1. **Create Template Documents**

   - Develop template for natural language tenet document
   - Develop template for natural language binding document
   - Document style guide for natural language approach

1. **Prototype Rewrites**

   - Rewrite one tenet (simplicity.md) as a prototype
   - Rewrite one binding (ts-no-any.md) as a prototype
   - Review and refine templates based on prototypes

1. **Update Validation Tools**

   - Review and update `tools/validate_front_matter.rb` if needed for new format
   - Test validation tools with prototype documents

### Phase 2: Tenet Rewrites (Week 2)

1. **Rewrite Core Tenets**

   - Rewrite all 8 tenets one by one:
     - simplicity.md
     - modularity.md
     - testability.md
     - maintainability.md
     - explicit-over-implicit.md
     - automation.md
     - document-decisions.md
     - no-secret-suppression.md

1. **Review and Validation**

   - Run validation tools on all rewritten tenets
   - Perform peer review of rewrites for clarity and philosophical alignment
   - Update tenet index with `tools/reindex.rb`

### Phase 3: Binding Rewrites (Weeks 3-4)

1. **Rewrite Language-Agnostic Bindings**

   - dependency-inversion.md
   - external-configuration.md
   - hex-domain-purity.md
   - immutable-by-default.md
   - no-internal-mocking.md
   - no-lint-suppression.md
   - require-conventional-commits.md
   - use-structured-logging.md

1. **Rewrite Language-Specific Bindings**

   - go-error-wrapping.md
   - ts-no-any.md

1. **Review and Validation**

   - Run validation tools on all rewritten bindings
   - Perform peer review of rewrites for clarity and philosophical alignment
   - Update binding index with `tools/reindex.rb`

### Phase 4: Documentation and Finalization (Week 5)

1. **Update Documentation**

   - Update `CONTRIBUTING.md` with new natural language standards
   - Create documentation for LLM integration approaches
   - Document examples of how tenets/bindings can be used in LLM prompts

1. **Audit for Completeness**

   - Review all source philosophy documents against tenets/bindings
   - Identify any gaps in coverage or clarity
   - Document needed additions for future work

1. **User Testing**

   - Test the usefulness of rewritten documents with LLMs
   - Gather feedback on clarity and effectiveness
   - Make final adjustments based on testing

## Testing Strategy

1. **Validation Testing**

   - Test all rewritten documents with `tools/validate_front_matter.rb`
   - Ensure all rewritten documents can be successfully indexed with `tools/reindex.rb`
   - Confirm all content meets the style guide requirements

1. **LLM Effectiveness Testing**

   - Test rewritten documents as context for popular LLMs (Claude, GPT-4, etc.)
   - Compare effectiveness of original vs. rewritten documents for various tasks
   - Document patterns that work particularly well for LLM context

1. **Human Readability Testing**

   - Have team members unfamiliar with specific tenets/bindings read the rewrites
   - Gather feedback on clarity, comprehension, and actionability
   - Use feedback to further refine natural language approach

## Risk Assessment and Mitigation

| Risk | Severity | Mitigation Strategy | |------|----------|---------------------| |
Loss of technical specificity during rewrite | High | Maintain separate "Technical
Implementation" sections where needed; peer review by domain experts | | Inconsistent
natural language style across documents | Medium | Develop and strictly follow a style
guide; use templates; regular review | | Breaking existing tooling with format changes |
Medium | Early validation testing; maintain all required metadata fields; update tools
as needed | | Drift from source philosophy during rewrites | High | Systematic audit
against source documents; explicit tracing to source principles | | Increased
maintenance burden for two writing styles | Low | Documentation of natural language
approach; templates; automation where possible |

## Success Criteria

1. **Completeness**

   - All 8 tenets rewritten in the natural language format
   - All 10 bindings rewritten in the natural language format
   - All required metadata preserved and validated

1. **Tooling Compatibility**

   - All validation tools run successfully on rewritten documents
   - All indexing tools run successfully on rewritten documents
   - No breaking changes to existing integrations

1. **Effectiveness**

   - Demonstrable improvement in LLM understanding and application of principles
   - Positive feedback from human readers on clarity and actionability
   - Maintained alignment with source philosophy documents

## Next Steps

1. Create initial templates and style guide
1. Begin prototype rewrites for review
1. Check out a branch for implementation
1. Proceed with phased implementation plan
