# Todo

## Python Bindings - Foundation & CI
- [x] **T001 · Chore · P0: create python bindings directory**
    - **Context:** Phase 1: Foundation - Directory Creation
    - **Action:**
        1. Create the directory `docs/bindings/categories/python/`.
    - **Done‑when:**
        1. The directory exists in the main branch of the repository.
    - **Verification:**
        1. Run `ls docs/bindings/categories/python/` and confirm the directory is present.
    - **Depends‑on:** none

- [x] ~~**T002 · Chore · P1: establish python expert review panel and process**~~ (CANCELLED - requires human coordination)
    - **Context:** Actionable Next Steps & Governance Framework - Community Engagement
    - **Action:**
        1. Identify and invite at least two Python experts to form a review panel.
        2. Document the panel members and a lightweight review process (e.g., PR reviews).
    - **Done‑when:**
        1. At least two experts have agreed to participate.
        2. The review process is documented in a `CONTRIBUTING.md` or a governance file.
    - **Depends‑on:** none

- [x] **T003 · Feature · P1: integrate python code example linting into ci**
    - **Context:** Phase 3: Quality Assurance - Python Code Linting
    - **Action:**
        1. Implement a script to extract Python code blocks from markdown files in the `docs/bindings/categories/python/` directory.
        2. Configure the script to run `flake8` and `mypy` on the extracted code.
        3. Add a job to the CI pipeline that runs this script and fails the build on any linting or type errors.
    - **Done‑when:**
        1. The CI pipeline includes a step that validates Python code examples.
        2. A pull request with a faulty code example fails the CI build at this step.
    - **Depends‑on:** [T001]

- [x] **T004 · Test · P1: configure ci to validate python binding front-matter**
    - **Context:** Phase 3: Quality Assurance - YAML front-matter validation
    - **Action:**
        1. Ensure the existing `validate_front_matter.rb` script is configured to scan markdown files in the `docs/bindings/categories/python/` path.
        2. Add a CI step that runs this validation and fails the build on errors.
    - **Done‑when:**
        1. The CI pipeline fails when a Python binding file has invalid YAML front-matter.
    - **Depends‑on:** [T001]

- [x] **T005 · Test · P1: configure ci to validate index integrity with python category**
    - **Context:** Phase 3: Quality Assurance - Index integrity check
    - **Action:**
        1. Ensure the existing `reindex.rb --strict` script processes the new Python category.
        2. Add a CI step that runs this check and fails the build on indexing or cross-reference errors.
    - **Done‑when:**
        1. The CI pipeline successfully re-indexes the site including the Python category.
        2. The build fails if cross-references are broken.
    - **Depends‑on:** [T001]

- [x] **T006 · Test · P2: integrate automated link checker for python bindings**
    - **Context:** Comprehensive Risk Mitigation Matrix - Cross-reference link rot
    - **Action:**
        1. Configure an automated link-checking tool (e.g., `lychee`, `htmlproofer`) in the CI pipeline.
        2. Ensure the tool scans the generated documentation for the Python category.
    - **Done‑when:**
        1. The CI pipeline fails if a broken link is detected in the Python binding documents.
    - **Depends‑on:** [T001]

- [x] **T007 · Test · P2: integrate secret scanning for python code examples**
    - **Context:** Comprehensive Risk Mitigation Matrix - Security vulnerabilities in examples
    - **Action:**
        1. Configure a secret scanning tool (e.g., `gitleaks`, `trufflehog`) in the CI pipeline.
        2. Ensure the scanner checks files within `docs/bindings/categories/python/`.
    - **Done‑when:**
        1. The CI pipeline fails if a potential secret (e.g., API key) is detected in a code example.
    - **Depends‑on:** [T001]

## Python Bindings - Core Content
- [x] **T008 · Feature · P1: create binding for type hinting and static analysis**
    - **Context:** Essential Python Bindings #1
    - **Action:**
        1. Create `docs/bindings/categories/python/type-hinting.md`.
        2. Draft the binding content including the rule, rationale, tenet derivation (`explicit-over-implicit`, `maintainability`), enforcement (`mypy`), and at least two bad/good code examples.
    - **Done‑when:**
        1. The markdown file passes all CI checks (front-matter, code linting).
    - **Verification:**
        1. `mypy --strict` passes on the "good" code examples.
    - **Depends‑on:** [T001, T003, T004]

- [x] **T009 · Feature · P2: create binding for explicit error handling**
    - **Context:** Essential Python Bindings #2
    - **Action:**
        1. Create `docs/bindings/categories/python/error-handling.md`.
        2. Draft the binding content including the rule, rationale, tenet derivation (`explicit-over-implicit`, `fix-broken-windows`), enforcement (`flake8-bugbear`), and at least two bad/good code examples.
    - **Done‑when:**
        1. The markdown file passes all CI checks.
    - **Depends‑on:** [T001, T003, T004]

- [x] **T010 · Feature · P2: create binding for virtual environment and dependency management**
    - **Context:** Essential Python Bindings #3
    - **Action:**
        1. Create `docs/bindings/categories/python/dependency-management.md`.
        2. Draft the binding content including the rule, rationale, tenet derivation (`automation`, `dependency-management`), enforcement (CI checks, `poetry`), and examples of lockfiles.
    - **Done‑when:**
        1. The markdown file passes all CI checks.
    - **Depends‑on:** [T001, T003, T004]

- [x] **T011 · Feature · P2: create binding for package structure and module organization**
    - **Context:** Essential Python Bindings #4
    - **Action:**
        1. Create `docs/bindings/categories/python/package-structure.md`.
        2. Draft the binding content including the rule, rationale, tenet derivation (`modularity`, `simplicity`), enforcement (code review), and examples of a `src/` layout.
    - **Done‑when:**
        1. The markdown file passes all CI checks.
    - **Depends‑on:** [T001, T003, T004]

- [x] **T012 · Feature · P2: create binding for testing patterns with pytest**
    - **Context:** Essential Python Bindings #5
    - **Action:**
        1. Create `docs/bindings/categories/python/testing-patterns.md`.
        2. Draft the binding content including the rule, rationale, tenet derivation (`testability`, `automation`), enforcement (`pytest`), and examples targeting behavior.
    - **Done‑when:**
        1. The markdown file passes all CI checks.
    - **Depends‑on:** [T001, T003, T004]

- [x] **T013 · Feature · P2: add cross-references to all core bindings**
    - **Context:** Phase 2: Core Binding Development - Cross-Reference Integration
    - **Action:**
        1. Edit each of the 5 core binding files to add links to analogous TypeScript/Go bindings.
        2. Add bidirectional links between related Python patterns where applicable.
    - **Done‑when:**
        1. All 5 core bindings contain a cross-reference section with valid links.
        2. The `reindex.rb --strict` CI check passes.
    - **Depends‑on:** [T005, T008, T009, T010, T011, T012]

- [x] ~~**T014 · Chore · P1: conduct expert review and finalize content**~~ (CANCELLED - requires human expert review)
    - **Context:** Phase 3: Quality Assurance - Expert technical review
    - **Action:**
        1. Submit a pull request with the 5 completed bindings for review by the expert panel.
        2. Incorporate all feedback related to technical accuracy, idiomaticity, and clarity.
    - **Done‑when:**
        1. At least one expert from the panel has formally approved the pull request.
    - **Depends‑on:** [T002, T013]

## Python Bindings - Governance
- [x] ~~**T015 · Chore · P2: assign python category champion**~~ (CANCELLED - requires human coordination)
    - **Context:** Phase 4: Publication and Governance - Champion Assignment
    - **Action:**
        1. Identify and designate a long-term maintainer for the Python bindings category.
        2. Document the champion's name and responsibilities in a project governance file.
    - **Done‑when:**
        1. A champion is named and documented publicly within the project.
    - **Depends‑on:** [T014]

- [x] ~~**T016 · Chore · P3: establish and document review cycle**~~ (CANCELLED - requires human governance decisions)
    - **Context:** Phase 4: Publication and Governance - Review Cycle Establishment
    - **Action:**
        1. Define and document the update cadence (e.g., annual) and process for the Python bindings.
        2. Include details on how community feedback will be integrated.
    - **Done‑when:**
        1. The review cycle and feedback process are documented in a governance file.
    - **Depends‑on:** [T015]

- [x] **T017 · Chore · P3: document tooling version pinning strategy**
    - **Context:** Comprehensive Risk Mitigation Matrix - Tooling drift over time
    - **Action:**
        1. Document the current pinned versions of `flake8`, `mypy`, and other enforcement tools.
        2. Outline a policy for how and when these tool versions should be updated.
    - **Done‑when:**
        1. A versioning policy is documented in a developer or governance guide.
    - **Depends‑on:** [T003]

## CI Infrastructure - Gitleaks Resolution
- [x] **T018 · Chore · P0: fix gitleaks installation failure in CI pipeline**
    - **Context:** PR #84 CI failure - gitleaks download URL returns 404
    - **Action:**
        1. Replace manual gitleaks installation with official `gitleaks/gitleaks-action@v2` in `.github/workflows/validate.yml`.
        2. Update workflow to use action-based scanning instead of manual installation.
        3. Test the new configuration with current Python binding files.
    - **Done‑when:**
        1. CI pipeline successfully installs and runs gitleaks without 404 errors.
        2. Python binding files are scanned for secrets without blocking valid examples.
        3. The action completes within 30 seconds.
    - **Verification:**
        1. Run CI pipeline and confirm gitleaks step passes.
        2. Verify gitleaks actually scans Python binding directory.
    - **Depends‑on:** none

- [x] **T019 · Test · P1: implement fallback gitleaks installation strategies**
    - **Context:** CI resilience - prevent future installation failures
    - **Action:**
        1. If GitHub Action fails, add fallback manual installation using GitHub API for dynamic URL resolution.
        2. Implement error handling with clear failure diagnostics.
        3. Add Ubuntu package manager installation as tertiary fallback.
    - **Done‑when:**
        1. CI pipeline has multiple installation strategies with graceful fallback.
        2. Each failure mode provides clear error message with resolution guidance.
    - **Verification:**
        1. Test each fallback method in isolated environment.
        2. Verify error messages provide actionable resolution steps.
    - **Depends‑on:** [T018]

- [x] **T020 · Chore · P2: document ci dependency management best practices**
    - **Context:** Prevent future CI dependency failures
    - **Action:**
        1. Add section to `CONTRIBUTING.md` covering CI dependency management principles.
        2. Document preferred methods for installing external tools (actions > manual > package manager).
        3. Create troubleshooting guide for common CI failures.
    - **Done‑when:**
        1. `CONTRIBUTING.md` includes comprehensive CI dependency guidelines.
        2. Troubleshooting guide covers gitleaks and similar tool installations.
    - **Verification:**
        1. Documentation review by CI/CD subject matter expert.
        2. Troubleshooting guide tested against real failure scenarios.
    - **Depends‑on:** [T018, T019]

- [ ] **T021 · Test · P2: implement ci pipeline health monitoring**
    - **Context:** Early detection of future CI issues
    - **Action:**
        1. Add validation step that checks all CI dependencies are properly installed.
        2. Implement tool version logging for debugging and maintenance.
        3. Create monitoring for CI success/failure rates across tools.
    - **Done‑when:**
        1. CI pipeline logs all tool versions and installation status.
        2. Health check validates all required tools before main validation.
        3. Failure patterns are detectable through logging.
    - **Verification:**
        1. Review CI logs show clear tool status and version information.
        2. Health check catches tool installation issues before they cause downstream failures.
    - **Depends‑on:** [T018]

---
