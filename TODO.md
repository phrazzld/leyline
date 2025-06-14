# Todo

## Binding Category Refactor
- [x] **T001 · Refactor · P1: create new binding category directories**
    - **Context:** PLAN.md › Phase 1: Category Creation and Migration, Step 1
    - **Action:**
        1. Run the command `mkdir -p docs/bindings/categories/{api,cli,browser-extensions,react,web}` to create all required directories.
    - **Done‑when:**
        1. The five new category directories (`api`, `cli`, `browser-extensions`, `react`, `web`) exist under `docs/bindings/categories/`.
    - **Depends‑on:** none

- [x] **T002 · Refactor · P2: move state-management.md to react category**
    - **Context:** PLAN.md › Existing Bindings to Recategorize › `state-management.md`
    - **Action:**
        1. Use `git mv` to move the file from `docs/bindings/categories/frontend/state-management.md` to `docs/bindings/categories/react/`.
    - **Done‑when:**
        1. The file `state-management.md` is present in the `docs/bindings/categories/react/` directory.
        2. The file's git history is preserved.
    - **Depends‑on:** [T001]

- [ ] **T003 · Refactor · P2: move web-accessibility.md to web category**
    - **Context:** PLAN.md › Existing Bindings to Recategorize › `web-accessibility.md`
    - **Action:**
        1. Use `git mv` to move the file from `docs/bindings/categories/frontend/web-accessibility.md` to `docs/bindings/categories/web/`.
    - **Done‑when:**
        1. The file `web-accessibility.md` is present in the `docs/bindings/categories/web/` directory.
        2. The file's git history is preserved.
    - **Depends‑on:** [T001]

- [ ] **T004 · Chore · P3: remove empty frontend category directory**
    - **Context:** PLAN.md › Remove empty category
    - **Action:**
        1. Delete the `docs/bindings/categories/frontend/` directory.
    - **Done‑when:**
        1. The `docs/bindings/categories/frontend/` directory is no longer present in the project.
    - **Depends‑on:** [T002, T003]

## New Bindings
- [ ] **T005 · Feature · P2: create binding for pnpm usage in node.js projects**
    - **Context:** PLAN.md › New Bindings to Create › TypeScript Category
    - **Action:**
        1. Create the file `docs/bindings/categories/typescript/use-pnpm-for-nodejs.md`.
        2. Populate the file with the specified YAML front-matter and content sections (Rule, Rationale, Enforcement, etc.) as per the plan.
    - **Done‑when:**
        1. The new binding document is created and complete.
        2. The binding's content clearly connects to the `automation` and `development-environment-consistency` tenets.
    - **Depends‑on:** none

- [ ] **T006 · Feature · P2: create binding for rest-first api design**
    - **Context:** PLAN.md › New Bindings to Create › API Category
    - **Action:**
        1. Create the file `docs/bindings/categories/api/rest-first-api-design.md`.
        2. Populate the file with the specified YAML front-matter and content sections as per the plan.
    - **Done‑when:**
        1. The new binding document is created and complete.
        2. The binding's content clearly connects to the `simplicity` and `explicit-over-implicit` tenets.
    - **Depends‑on:** [T001]

- [ ] **T007 · Feature · P2: create binding for cli developer experience**
    - **Context:** PLAN.md › New Bindings to Create › CLI Category
    - **Action:**
        1. Create the file `docs/bindings/categories/cli/cli-developer-experience.md`.
        2. Populate the file with the specified YAML front-matter and content sections as per the plan.
    - **Done‑when:**
        1. The new binding document is created and complete.
        2. The binding's content clearly connects to the `empathize-with-your-user` and `simplicity` tenets.
    - **Depends‑on:** [T001]

- [ ] **T008 · Feature · P2: create binding for browser extension security patterns**
    - **Context:** PLAN.md › New Bindings to Create › Browser Extensions Category
    - **Action:**
        1. Create the file `docs/bindings/categories/browser-extensions/browser-extension-security-patterns.md`.
        2. Populate the file with the specified YAML front-matter and content sections as per the plan.
    - **Done‑when:**
        1. The new binding document is created and complete.
        2. The binding's content clearly connects to the `secure-by-design-principles` and `no-secret-suppression` tenets.
    - **Depends‑on:** [T001]

## Validation & Integration
- [ ] **T009 · Test · P1: validate all changes and regenerate indexes**
    - **Context:** PLAN.md › Phase 3: Validation and Integration
    - **Action:**
        1. Run the structure validation script: `ruby tools/validate_front_matter.rb`.
        2. Run the index generation script: `ruby tools/reindex.rb`.
    - **Done‑when:**
        1. The validation script passes with no errors for all new and moved bindings.
        2. The re-indexing script completes successfully.
        3. All new and moved bindings appear correctly in any generated index files under their new categories.
    - **Verification:**
        1. Manually inspect the output of `reindex.rb` to confirm the new categories are processed.
        2. Manually check any generated index or manifest file to confirm `state-management.md` and `web-accessibility.md` are listed with their new paths.
        3. Confirm `use-pnpm-for-nodejs.md`, `rest-first-api-design.md`, `cli-developer-experience.md`, and `browser-extension-security-patterns.md` are present in the index.
    - **Depends‑on:** [T004, T005, T006, T007, T008]
