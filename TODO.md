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

[... other completed tasks ...]

## CI Fixes

- [x] **T056 · Chore · P0: Fix markdown-link-check installation in CI**
    - **Context:** CI failing due to incorrect package manager for markdown-link-check
    - **Action:**
        1. Update `.github/workflows/ci.yml` to install Node.js
        2. Change pip install to npm install for markdown-link-check
        3. Ensure the tool is properly executed in the workflow
    - **Done‑when:**
        1. CI workflow installs markdown-link-check using npm
        2. Lint-docs job passes successfully
    - **Verification:**
        1. CI run shows successful installation and execution
    - **Depends‑on:** none

- [x] **T057 · Chore · P0: Restructure project for proper documentation organization**
    - **Context:** Project structure should align with its purpose as a documentation project
    - **Action:**
        1. ✅ Move `/tenets/` directory to `/docs/tenets/`
        2. ✅ Move `/bindings/` directory to `/docs/bindings/`
        3. ✅ Copy CONTRIBUTING.md to docs or reference it properly
        4. ✅ Update mkdocs.yml to reference the new paths with detailed navigation
    - **Done‑when:**
        1. ✅ All tenets and bindings are contained within the docs directory
        2. ⏳ All internal links work correctly with the new structure (will be addressed in T058)
    - **Verification:**
        1. ✅ Run mkdocs build locally to verify structure works
        2. ⏳ Check that all cross-references work in the generated site (will be addressed in T058)
    - **Depends‑on:** none

- [x] **T058 · Chore · P0: Update all cross-references for new document paths**
    - **Context:** Moving files will break existing references between documents
    - **Action:**
        1. Update all references between tenets and bindings to use the new paths
        2. Fix any relative links in the index files
        3. Update links in any examples or documentation
    - **Done‑when:**
        1. All cross-references use the new path structure
        2. No broken links are present in the documentation
    - **Verification:**
        1. Run markdown-link-check or similar to find any broken links
        2. Manually review key documents for correct references
    - **Depends‑on:** [T057]

- [x] **T059 · Test · P0: Verify clean project build and documentation**
    - **Context:** Ensure restructured project works correctly
    - **Action:**
        1. Run all validation tools on the restructured project
        2. Ensure MkDocs builds successfully in strict mode
        3. Test documentation site navigation and links
    - **Done‑when:**
        1. All validation tools pass without errors
        2. MkDocs builds without warnings in strict mode
        3. Documentation site functions correctly
    - **Verification:**
        1. Run validation tools locally
        2. Run mkdocs build --strict and view the generated site
    - **Depends‑on:** [T056, T057, T058]