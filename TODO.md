# Todo: Natural Language Rewrite of Tenets and Bindings

## Phase 1: Framework, Templates & Prototypes
- [x] **T001 · Feature · P1: create natural language tenet template**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template Documents
    - **Action:**
        1. Create `docs/templates/tenet_template.md` adhering to the revised tenet structure (Front-Matter, Core Belief, Practical Guidelines, Warning Signs, Related Tenets).
    - **Done‑when:**
        1. Template file exists and matches the structure defined in PLAN.md.
        2. Template includes placeholders and explanatory comments for each section.
    - **Verification:**
        1. Manually inspect template against PLAN.md structure.
    - **Depends‑on:** none
- [x] **T002 · Feature · P1: create natural language binding template**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template Documents
    - **Action:**
        1. Create `docs/templates/binding_template.md` adhering to the revised binding structure (Front-Matter, Rationale, Rule Definition, Practical Implementation, Examples, Related Bindings).
    - **Done‑when:**
        1. Template file exists and matches the structure defined in PLAN.md.
        2. Template includes placeholders and explanatory comments for each section.
    - **Verification:**
        1. Manually inspect template against PLAN.md structure.
    - **Depends‑on:** none
- [x] **T003 · Feature · P1: document style guide for natural language approach**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template Documents & Natural Language Guidelines
    - **Action:**
        1. Create `docs/STYLE_GUIDE_NATURAL_LANGUAGE.md` detailing conversational tone, principle-first approach, context/connections, and narrative structure.
        2. Include examples of preferred phrasing and anti-patterns.
    - **Done‑when:**
        1. Style guide exists and covers all guidelines from PLAN.md.
        2. Style guide is reviewed for clarity.
    - **Verification:**
        1. Peer review style guide against PLAN.md guidelines.
    - **Depends‑on:** none
- [x] **T004 · Chore · P1: review and update front-matter validation tool**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 3. Update Validation Tools & Risk Assessment (Breaking tooling)
    - **Action:**
        1. Review `tools/validate_front_matter.rb` for compatibility with new template front-matter.
        2. Update script if necessary to handle new/changed fields or structure.
        3. Add/update tests for the validation script.
    - **Done‑when:**
        1. `tools/validate_front_matter.rb` correctly validates front-matter based on T001 and T002.
        2. Tests pass for both valid and invalid front-matter scenarios.
    - **Verification:**
        1. Run script against template files and confirm correct validation/errors.
    - **Depends‑on:** [T001, T002]
- [x] **T005 · Chore · P1: review and update index generation tool**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 3. Update Validation Tools & Risk Assessment (Breaking tooling)
    - **Action:**
        1. Review `tools/reindex.rb` for compatibility with new file structure and front-matter.
        2. Update script if necessary to correctly parse and index new documents.
        3. Add/update tests for the indexing script.
    - **Done‑when:**
        1. `tools/reindex.rb` correctly generates indexes based on T001 and T002.
        2. Tests pass for index generation scenarios.
    - **Verification:**
        1. Run script against sample files and confirm correct index output.
    - **Depends‑on:** [T001, T002]
- [x] **T006 · Feature · P1: rewrite tenet 'simplicity.md' as prototype**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 2. Prototype Rewrites
    - **Action:**
        1. Rewrite content of `tenets/simplicity.md` using the tenet template (T001) and style guide (T003).
        2. Ensure original metadata is preserved in the front-matter.
    - **Done‑when:**
        1. Rewritten prototype `simplicity.md` exists.
        2. Content follows the new template and style guide.
        3. Front-matter passes validation with updated tool (T004).
    - **Verification:**
        1. Run `tools/validate_front_matter.rb` on the rewritten file.
        2. Peer review prototype for clarity and adherence to guidelines.
    - **Depends‑on:** [T001, T003, T004]
- [x] **T007 · Feature · P1: rewrite binding 'ts-no-any.md' as prototype**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 2. Prototype Rewrites
    - **Action:**
        1. Rewrite content of `bindings/ts-no-any.md` using the binding template (T002) and style guide (T003).
        2. Ensure original metadata is preserved in the front-matter.
    - **Done‑when:**
        1. Rewritten prototype `ts-no-any.md` exists.
        2. Content follows the new template and style guide.
        3. Front-matter passes validation with updated tool (T004).
    - **Verification:**
        1. Run `tools/validate_front_matter.rb` on the rewritten file.
        2. Peer review prototype for clarity and adherence to guidelines.
    - **Depends‑on:** [T002, T003, T004]
- [x] **T008 · Chore · P1: review and refine templates based on prototypes**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 2. Prototype Rewrites
    - **Action:**
        1. Review prototype tenet (T006) and binding (T007) against templates (T001, T002).
        2. Identify and implement improvements to the templates based on practical application.
    - **Done‑when:**
        1. Templates (`tenet_template.md`, `binding_template.md`) are updated based on prototype feedback.
        2. Templates finalized for Phase 2/3 rewrites.
    - **Verification:**
        1. Re-validate prototype documents against refined templates.
    - **Depends‑on:** [T006, T007]
- [x] **T009 · Test · P1: test validation and index tools with prototype documents**
    - **Context:** PLAN.md > Phase 1: Framework and Templates > 3. Update Validation Tools
    - **Action:**
        1. Run updated `tools/validate_front_matter.rb` (T004) against prototypes (T006, T007).
        2. Run updated `tools/reindex.rb` (T005) against prototypes (T006, T007).
        3. Ensure scripts pass and produce correct output.
    - **Done‑when:**
        1. `tools/validate_front_matter.rb` successfully validates prototypes.
        2. `tools/reindex.rb` successfully indexes prototypes.
        3. Tooling confirmed working correctly with new format documents.
    - **Depends‑on:** [T004, T005, T006, T007, T008]

## Phase 2: Tenet Rewrites
- [x] **T010 · Feature · P2: rewrite tenet 'simplicity.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/simplicity.md`.
    - **Done‑when:**
        1. `tenets/simplicity.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T011 · Feature · P2: rewrite tenet 'modularity.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/modularity.md`.
    - **Done‑when:**
        1. `tenets/modularity.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T012 · Feature · P2: rewrite tenet 'testability.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/testability.md`.
    - **Done‑when:**
        1. `tenets/testability.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T013 · Feature · P2: rewrite tenet 'maintainability.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/maintainability.md`.
    - **Done‑when:**
        1. `tenets/maintainability.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T014 · Feature · P2: rewrite tenet 'explicit-over-implicit.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/explicit-over-implicit.md`.
    - **Done‑when:**
        1. `tenets/explicit-over-implicit.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T015 · Feature · P2: rewrite tenet 'automation.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/automation.md`.
    - **Done‑when:**
        1. `tenets/automation.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T016 · Feature · P2: rewrite tenet 'document-decisions.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/document-decisions.md`.
    - **Done‑when:**
        1. `tenets/document-decisions.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T017 · Feature · P2: rewrite tenet 'no-secret-suppression.md'**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
    - **Action:**
        1. Apply finalized tenet template (T008) and style guide (T003) to rewrite `tenets/no-secret-suppression.md`.
    - **Done‑when:**
        1. `tenets/no-secret-suppression.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T018 · Test · P2: run validation tools on all rewritten tenets**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 2. Review and Validation
    - **Action:**
        1. Execute `tools/validate_front_matter.rb` against all rewritten tenet files (T010-T017).
        2. Fix any validation errors found.
    - **Done‑when:**
        1. Validation script passes successfully for all rewritten tenets.
    - **Verification:**
        1. Check validation logs for success.
    - **Depends‑on:** [T009, T010, T011, T012, T013, T014, T015, T017]
- [x] **T019 · Chore · P2: perform peer review of rewritten tenets**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 2. Review and Validation
    - **Action:**
        1. Conduct peer reviews for each rewritten tenet (T010-T017).
        2. Focus on clarity, style guide adherence, and philosophical alignment.
        3. Incorporate feedback into the documents.
    - **Done‑when:**
        1. All rewritten tenets (T010-T017) have been peer-reviewed and feedback incorporated.
    - **Verification:**
        1. Review comments addressed or documented.
    - **Depends‑on:** [T010, T011, T012, T013, T014, T015, T016, T017]
- [x] **T020 · Chore · P2: update tenet index**
    - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 2. Review and Validation
    - **Action:**
        1. Run the `tools/reindex.rb` script (T005) to update the tenet index file.
        2. Verify the index is updated correctly based on the rewritten tenets.
    - **Done‑when:**
        1. Tenet index file is successfully regenerated and committed.
        2. Index accurately reflects the rewritten tenets (T010-T017).
    - **Verification:**
        1. Manually check index file contents.
    - **Depends‑on:** [T005, T018, T019]

## Phase 3: Binding Rewrites
- [x] **T021 · Feature · P2: rewrite binding 'dependency-inversion.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/dependency-inversion.md`.
    - **Done‑when:**
        1. `bindings/dependency-inversion.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T022 · Feature · P2: rewrite binding 'external-configuration.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/external-configuration.md`.
    - **Done‑when:**
        1. `bindings/external-configuration.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T023 · Feature · P2: rewrite binding 'hex-domain-purity.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/hex-domain-purity.md`.
    - **Done‑when:**
        1. `bindings/hex-domain-purity.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T024 · Feature · P2: rewrite binding 'immutable-by-default.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/immutable-by-default.md`.
    - **Done‑when:**
        1. `bindings/immutable-by-default.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T025 · Feature · P2: rewrite binding 'no-internal-mocking.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/no-internal-mocking.md`.
    - **Done‑when:**
        1. `bindings/no-internal-mocking.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T026 · Feature · P2: rewrite binding 'no-lint-suppression.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/no-lint-suppression.md`.
    - **Done‑when:**
        1. `bindings/no-lint-suppression.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T027 · Feature · P2: rewrite binding 'require-conventional-commits.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/require-conventional-commits.md`.
    - **Done‑when:**
        1. `bindings/require-conventional-commits.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T028 · Feature · P2: rewrite binding 'use-structured-logging.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 1. Rewrite Language-Agnostic Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/use-structured-logging.md`.
    - **Done‑when:**
        1. `bindings/use-structured-logging.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T029 · Feature · P2: rewrite binding 'go-error-wrapping.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 2. Rewrite Language-Specific Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/go-error-wrapping.md`.
    - **Done‑when:**
        1. `bindings/go-error-wrapping.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T030 · Feature · P2: rewrite binding 'ts-no-any.md'**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 2. Rewrite Language-Specific Bindings
    - **Action:**
        1. Apply finalized binding template (T008) and style guide (T003) to rewrite `bindings/ts-no-any.md`.
    - **Done‑when:**
        1. `bindings/ts-no-any.md` is rewritten in the final new format.
        2. Front-matter is valid per T004.
    - **Depends‑on:** [T003, T008, T004]
- [x] **T031 · Test · P2: run validation tools on all rewritten bindings**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 3. Review and Validation
    - **Action:**
        1. Execute `tools/validate_front_matter.rb` against all rewritten binding files (T021-T030).
        2. Fix any validation errors found.
    - **Done‑when:**
        1. Validation script passes successfully for all rewritten bindings.
    - **Verification:**
        1. Check validation logs for success.
    - **Depends‑on:** [T009, T021, T022, T023, T024, T025, T026, T027, T028, T029, T030]
- [x] **T032 · Chore · P2: perform peer review of rewritten bindings**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 3. Review and Validation
    - **Action:**
        1. Conduct peer reviews for each rewritten binding (T021-T030).
        2. Focus on clarity, style guide adherence, philosophical alignment, and correct linking.
        3. Incorporate feedback into the documents.
    - **Done‑when:**
        1. All rewritten bindings (T021-T030) have been peer-reviewed and feedback incorporated.
    - **Verification:**
        1. Review comments addressed or documented.
    - **Depends‑on:** [T021, T022, T023, T024, T025, T026, T027, T028, T029, T030]
- [x] **T033 · Chore · P2: update binding index**
    - **Context:** PLAN.md > Phase 3: Binding Rewrites > 3. Review and Validation
    - **Action:**
        1. Run the `tools/reindex.rb` script (T005) to update the binding index file.
        2. Verify the index is updated correctly based on the rewritten bindings.
    - **Done‑when:**
        1. Binding index file is successfully regenerated and committed.
        2. Index accurately reflects the rewritten bindings (T021-T030).
    - **Verification:**
        1. Manually check index file contents.
    - **Depends‑on:** [T005, T031, T032]

## Phase 4: Documentation and Finalization
- [x] **T034 · Chore · P2: update CONTRIBUTING.md with new standards**
    - **Context:** PLAN.md > Phase 4: Documentation and Finalization > 1. Update Documentation
    - **Action:**
        1. Edit `CONTRIBUTING.md` to reflect new natural language standards, referencing style guide (T003) and templates (T008).
    - **Done‑when:**
        1. `CONTRIBUTING.md` accurately describes the process for writing/updating tenets and bindings in the new format.
    - **Verification:**
        1. Review contributing guide for accuracy and clarity.
    - **Depends‑on:** [T003, T008, T020, T033]
- [x] **T035 · Feature · P2: create documentation for LLM integration approaches**
    - **Context:** PLAN.md > Phase 4: Documentation and Finalization > 1. Update Documentation
    - **Action:**
        1. Create `docs/LLM_INTEGRATION.md` outlining strategies for using rewritten documents as LLM context.
        2. Include best practices and potential prompt engineering techniques.
    - **Done‑when:**
        1. `docs/LLM_INTEGRATION.md` exists and provides clear guidance.
    - **Verification:**
        1. Peer review documentation for usefulness.
    - **Depends‑on:** [T020, T033]
- [x] **T036 · Feature · P2: document examples of tenet/binding usage in LLM prompts**
    - **Context:** PLAN.md > Phase 4: Documentation and Finalization > 1. Update Documentation
    - **Action:**
        1. Add concrete examples of prompts using rewritten documents to `docs/LLM_INTEGRATION.md` (T035).
    - **Done‑when:**
        1. Documentation includes practical, runnable examples for LLM integration.
    - **Verification:**
        1. Test example prompts with an LLM to ensure they work as intended.
    - **Depends‑on:** [T035]
- [x] **T037 · Chore · P2: audit source philosophy documents for coverage**
    - **Context:** PLAN.md > Phase 4: Documentation and Finalization > 2. Audit for Completeness
    - **Action:**
        1. Systematically compare rewritten tenets and bindings against original source philosophy documents.
        2. Identify any gaps in coverage or clarity.
    - **Done‑when:**
        1. Comprehensive audit document exists detailing coverage analysis.
    - **Verification:**
        1. Peer review audit for completeness.
    - **Depends‑on:** [T020, T033]
- [x] **T038 · Chore · P2: document needed additions for future work**
    - **Context:** PLAN.md > Phase 4: Documentation and Finalization > 2. Audit for Completeness
    - **Action:**
        1. Document any gaps identified in T037 as future work items.
        2. Create issues/tickets for missing tenets or bindings.
    - **Done‑when:**
        1. Future work document exists with clear action items.
        2. Issues are created for significant gaps.
    - **Verification:**
        1. Review document for clarity and actionability.
    - **Depends‑on:** [T037]

## Future Binding Work (Based on Audit)

### Core Bindings

- [x] **T041 · Feature · P3: create binding 'api-design.md'**
    - **Context:** Audit Gap > Core Philosophy Gaps > API Design
    - **Action:**
        1. Create new binding `bindings/api-design.md` using the binding template (T002) and style guide (T003).
        2. Cover best practices for defining clear, explicit, robust contracts for all APIs.
    - **Done‑when:**
        1. Binding exists and covers interface design for internal module interfaces, external REST/gRPC/GraphQL APIs, and CLIs.
        2. Front-matter is valid and derives from `explicit-over-implicit` tenet.
    - **Depends‑on:** [T037]

- [x] **T042 · Feature · P3: create binding 'pure-functions.md'**
    - **Context:** Audit Gap > Core Philosophy Gaps > Pure Functions
    - **Action:**
        1. Create new binding `bindings/pure-functions.md` using the binding template (T002) and style guide (T003).
        2. Focus on implementation of core logic as pure functions that isolate side effects.
    - **Done‑when:**
        1. Binding exists with clear definition of pure functions, their benefits, and practical implementation patterns.
        2. Front-matter is valid and derives from `simplicity` and `testability` tenets.
    - **Depends‑on:** [T037]

- [x] **T043 · Feature · P3: create binding 'dependency-management.md'**
    - **Context:** Audit Gap > Core Philosophy Gaps > Dependency Management
    - **Action:**
        1. Create new binding `bindings/dependency-management.md` using the binding template (T002) and style guide (T003).
        2. Cover practices for minimizing third-party dependencies and keeping them updated.
    - **Done‑when:**
        1. Binding exists with guidance on dependency evaluation, security auditing, and maintenance.
        2. Front-matter is valid and derives from `simplicity` and `automation` tenets.
    - **Depends‑on:** [T037]

- [x] **T044 · Feature · P3: create binding 'code-size.md'**
    - **Context:** Audit Gap > Core Philosophy Gaps > Length Guidelines
    - **Action:**
        1. Create new binding `bindings/code-size.md` using the binding template (T002) and style guide (T003).
        2. Provide clear guidelines on function, method, and file size limits.
    - **Done‑when:**
        1. Binding exists with specific, measurable criteria for appropriate code size and refactoring signals.
        2. Front-matter is valid and derives from `simplicity` and `modularity` tenets.
    - **Depends‑on:** [T037]

- [x] **T045 · Feature · P3: enhance binding 'use-structured-logging.md' for observability**
    - **Context:** Audit Gap > Core Philosophy Gaps > Design for Observability
    - **Action:**
        1. Expand existing binding `bindings/use-structured-logging.md` to include metrics and tracing.
        2. Add comprehensive guidance on the three pillars of observability.
    - **Done‑when:**
        1. Enhanced binding covers structured logging, metrics collection, and distributed tracing.
        2. Front-matter remains valid.
    - **Depends‑on:** [T037]

### Language-Specific Bindings

- [x] **T046 · Feature · P3: create binding 'go-package-design.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Go-Specific Practices
    - **Action:**
        1. Create new binding `bindings/go-package-design.md` using the binding template (T002) and style guide (T003).
        2. Focus on Go-specific package organization, naming, and structure.
    - **Done‑when:**
        1. Binding exists with clear guidance on Go package design aligned with the Go appendix.
        2. Front-matter is valid and applies to Go.
    - **Depends‑on:** [T037]

- [x] **T047 · Feature · P3: create binding 'go-interface-design.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Go-Specific Practices
    - **Action:**
        1. Create new binding `bindings/go-interface-design.md` using the binding template (T002) and style guide (T003).
        2. Cover Go-specific interface design principles (small interfaces, consumer-defined, etc.).
    - **Done‑when:**
        1. Binding exists with practical guidance on Go interface design patterns.
        2. Front-matter is valid and applies to Go.
    - **Depends‑on:** [T037]

- [x] **T048 · Feature · P3: create binding 'go-concurrency-patterns.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Go-Specific Practices
    - **Action:**
        1. Create new binding `bindings/go-concurrency-patterns.md` using the binding template (T002) and style guide (T003).
        2. Detail Go-specific concurrency best practices (goroutines, channels, context).
    - **Done‑when:**
        1. Binding exists with guidelines for safe, effective concurrency in Go.
        2. Front-matter is valid and applies to Go.
    - **Depends‑on:** [T037]

- [x] **T049 · Feature · P3: create binding 'ts-module-organization.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > TypeScript-Specific Practices
    - **Action:**
        1. Create new binding `bindings/ts-module-organization.md` using the binding template (T002) and style guide (T003).
        2. Focus on TypeScript-specific module, import/export, and project organization.
    - **Done‑when:**
        1. Binding exists with guidance on TypeScript module structure aligned with the TypeScript appendix.
        2. Front-matter is valid and applies to TypeScript.
    - **Depends‑on:** [T037]

- [ ] **T050 · Feature · P3: create binding 'ts-async-patterns.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > TypeScript-Specific Practices
    - **Action:**
        1. Create new binding `bindings/ts-async-patterns.md` using the binding template (T002) and style guide (T003).
        2. Cover TypeScript-specific async/await patterns and error handling.
    - **Done‑when:**
        1. Binding exists with best practices for working with asynchronous code in TypeScript.
        2. Front-matter is valid and applies to TypeScript.
    - **Depends‑on:** [T037]

- [ ] **T051 · Feature · P3: create binding 'rust-ownership-patterns.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Rust-Specific Practices
    - **Action:**
        1. Create new binding `bindings/rust-ownership-patterns.md` using the binding template (T002) and style guide (T003).
        2. Focus on Rust-specific ownership, borrowing, and lifetime patterns.
    - **Done‑when:**
        1. Binding exists with practical guidance on effective ownership management in Rust.
        2. Front-matter is valid and applies to Rust.
    - **Depends‑on:** [T037]

- [ ] **T052 · Feature · P3: create binding 'rust-error-handling.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Rust-Specific Practices
    - **Action:**
        1. Create new binding `bindings/rust-error-handling.md` using the binding template (T002) and style guide (T003).
        2. Detail Rust-specific error handling patterns and types.
    - **Done‑when:**
        1. Binding exists with guidance on Result, Option, error types, and propagation in Rust.
        2. Front-matter is valid and applies to Rust.
    - **Depends‑on:** [T037]

### Frontend-Specific Bindings

- [ ] **T053 · Feature · P3: create binding 'component-architecture.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Frontend Practices
    - **Action:**
        1. Create new binding `bindings/component-architecture.md` using the binding template (T002) and style guide (T003).
        2. Focus on Atomic Design principles for component organization.
    - **Done‑when:**
        1. Binding exists with clear component architectural principles aligned with the Frontend appendix.
        2. Front-matter is valid and applies to frontend technologies.
    - **Depends‑on:** [T037]

- [ ] **T054 · Feature · P3: create binding 'frontend-state-management.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Frontend Practices
    - **Action:**
        1. Create new binding `bindings/frontend-state-management.md` using the binding template (T002) and style guide (T003).
        2. Cover state management approaches and best practices.
    - **Done‑when:**
        1. Binding exists with practical guidance on different state management approaches and when to use each.
        2. Front-matter is valid and applies to frontend technologies.
    - **Depends‑on:** [T037]

- [ ] **T055 · Feature · P3: create binding 'web-accessibility.md'**
    - **Context:** Audit Gap > Language-Specific Gaps > Frontend Practices
    - **Action:**
        1. Create new binding `bindings/web-accessibility.md` using the binding template (T002) and style guide (T003).
        2. Detail accessibility (a11y) requirements and implementation.
    - **Done‑when:**
        1. Binding exists with concrete requirements for meeting WCAG standards and implementation patterns.
        2. Front-matter is valid and applies to frontend technologies.
    - **Depends‑on:** [T037]
