# Todo

## Python Bindings - Phase 1: Update Existing Bindings
- [x] **T001 · Refactor · P1: promote uv in dependency-management.md**
    - **Context:** PLAN.md > Phase 1 > 1.1 Enhance `dependency-management.md`
    - **Action:**
        1. Reorder tool recommendations to position `uv` as the primary tool.
        2. Move `Poetry` and `pip-tools` to an "Alternative Approaches" section to maintain backward compatibility as per risk mitigation.
    - **Done-when:**
        1. The document structure clearly prioritizes `uv` over other tools.
    - **Depends-on:** none

- [x] **T002 · Feature · P2: add uv workflow and ci examples to dependency-management.md**
    - **Context:** PLAN.md > Phase 1 > 1.1 & Detailed Implementation Steps > Step 1
    - **Action:**
        1. Add a new section with `uv` installation, configuration, and workflow examples (`init`, `add`, `run`).
        2. Include a CI example snippet demonstrating `uv.lock` validation.
    - **Done-when:**
        1. The document contains clear, copy-pasteable examples for `uv` usage and CI validation.
    - **Verification:**
        1. Execute the `uv` workflow commands in a test project to ensure they work as documented.
    - **Depends-on:** [T001]

- [ ] **T003 · Feature · P2: add poetry-to-uv migration guide to dependency-management.md**
    - **Context:** PLAN.md > Phase 1 > 1.1 & Detailed Implementation Steps > Step 1
    - **Action:**
        1. Add a new section titled "Migration from Poetry to uv".
        2. Provide clear, step-by-step instructions for converting a `pyproject.toml` from Poetry to `uv`.
    - **Done-when:**
        1. A developer can follow the guide to migrate a simple Poetry-based project to `uv`.
    - **Depends-on:** [T001]

- [ ] **T004 · Refactor · P1: expand type-hinting.md scope to all functions**
    - **Context:** PLAN.md > Phase 1 > 1.2 Expand `type-hinting.md`
    - **Action:**
        1. Update the core rule in `type-hinting.md` from "public APIs" to "all functions".
        2. Add specific guidance on typing private/internal functions, with clearly documented exceptions (e.g., simple lambdas).
    - **Done-when:**
        1. The document mandates type hints for all functions, with clearly defined and justified exceptions.
    - **Depends-on:** none

- [ ] **T005 · Feature · P2: add advanced patterns and strict mypy config to type-hinting.md**
    - **Context:** PLAN.md > Phase 1 > 1.2 Expand `type-hinting.md`
    - **Action:**
        1. Add a section with examples for advanced typing patterns like `Protocol`, `TypedDict`, and `Generics`.
        2. Add a complete, strict `mypy` configuration example for `pyproject.toml`.
        3. Include a subsection on strategies for incrementally adopting strict typing in a large codebase.
    - **Done-when:**
        1. The document contains examples for advanced types and a reference strict `mypy` configuration.
    - **Verification:**
        1. The provided `mypy` config runs successfully on a sample file.
    - **Depends-on:** [T004]

## Python Bindings - Phase 2: Create New Bindings
- [ ] **T006 · Feature · P1: create modern-python-toolchain.md binding**
    - **Context:** PLAN.md > Phase 2 > 2.1 New Binding: `modern-python-toolchain.md`
    - **Action:**
        1. Create a new file `modern-python-toolchain.md` with correct YAML front-matter.
        2. Populate it with the rationale for the modern toolchain (uv, ruff, mypy, pytest), a complete `pyproject.toml` example, and CI/CD integration patterns.
    - **Done-when:**
        1. The new binding exists and serves as a central reference for the modern Python stack.
    - **Depends-on:** none

- [ ] **T007 · Feature · P1: create ruff-code-quality.md binding**
    - **Context:** PLAN.md > Phase 2 > 2.2 New Binding: `ruff-code-quality.md`
    - **Action:**
        1. Create a new file `ruff-code-quality.md` with correct YAML front-matter.
        2. Document the rule selection philosophy and provide a comprehensive `ruff` configuration for `pyproject.toml` that replaces Black, isort, and flake8.
        3. Include examples for integrating `ruff` into CI pipelines and pre-commit hooks.
    - **Done-when:**
        1. The new binding provides a complete, copy-pasteable `ruff` configuration and integration examples.
    - **Depends-on:** none

- [ ] **T008 · Feature · P1: create pyproject-toml-configuration.md binding**
    - **Context:** PLAN.md > Phase 2 > 2.3 New Binding: `pyproject-toml-configuration.md`
    - **Action:**
        1. Create a new file `pyproject-toml-configuration.md` with correct YAML front-matter.
        2. Mandate the use of `pyproject.toml` as the single source for configuration, explicitly forbidding legacy files.
        3. Provide both minimal and comprehensive `pyproject.toml` templates and migration guidance.
    - **Done-when:**
        1. The new binding establishes the `pyproject.toml`-only standard with templates and migration guides.
    - **Depends-on:** none

- [ ] **T009 · Feature · P2: add ide integration guides to modern-python-toolchain.md**
    - **Context:** PLAN.md > Risk Assessment > Medium-Risk Areas > IDE integration challenges
    - **Action:**
        1. Add a section to `modern-python-toolchain.md` with setup instructions for VS Code and PyCharm.
        2. Include common troubleshooting steps for toolchain/IDE integration.
    - **Done-when:**
        1. The binding contains actionable setup guides for popular IDEs.
    - **Verification:**
        1. Test the configuration steps in a clean instance of VS Code and PyCharm.
    - **Depends-on:** [T006]

- [ ] **T010 · Chore · P2: pin tool versions in all new and updated examples**
    - **Context:** PLAN.md > Risk Assessment > Medium-Risk Areas > Tool version compatibility issues
    - **Action:**
        1. Review all `pyproject.toml` and CI examples in the new/updated bindings.
        2. Pin specific, tested versions for all tools (`uv`, `ruff`, `mypy`, `pytest`).
    - **Done-when:**
        1. All code and configuration examples specify exact tool versions.
    - **Depends-on:** [T002, T005, T006, T007, T008]

## Python Bindings - Phase 3: Integration and Validation
- [ ] **T011 · Chore · P1: update all cross-references and indexes**
    - **Context:** PLAN.md > Phase 3 > 3.1 Cross-Reference Updates
    - **Action:**
        1. Review all existing Python bindings and update internal links to reference the new and updated documents.
        2. Ensure the Python category index file is updated to reflect the new structure.
    - **Done-when:**
        1. All links between Python-related documents are accurate and there are no dead links.
    - **Depends-on:** [T003, T005, T006, T007, T008]

- [ ] **T012 · Test · P1: run all documentation validation scripts**
    - **Context:** PLAN.md > Phase 3 > 3.2 Tool Validation
    - **Action:**
        1. Run `ruby tools/validate_front_matter.rb` on all modified and new files.
        2. Run `ruby tools/reindex.rb --strict` to regenerate indexes.
        3. Run `ruby tools/fix_cross_references.rb` to verify and fix links.
    - **Done-when:**
        1. All validation and indexing scripts complete successfully without errors.
    - **Verification:**
        1. CI build containing these changes passes all documentation-related checks.
    - **Depends-on:** [T011]

- [ ] **T013 · Test · P1: create sample project to validate new bindings**
    - **Context:** PLAN.md > Testing Strategy > Test Cases
    - **Action:**
        1. Create a new, minimal Python project from scratch in a test repository.
        2. Configure the project's `pyproject.toml` using the new templates and guidance.
        3. Validate the entire toolchain: `uv` for install, `ruff` for quality, `mypy` for types, and `pytest` for tests.
    - **Done-when:**
        1. The sample project is fully configured and all toolchain commands (`uv run`, `ruff check`, `mypy --strict`) execute successfully.
    - **Verification:**
        1. Intentionally introduce a lint error and a type error to confirm `ruff` and `mypy` fail the build as expected.
    - **Depends-on:** [T010, T012]

- [ ] **T014 · Test · P2: test and refine poetry-to-uv migration guide**
    - **Context:** PLAN.md > Testing Strategy > Test Cases
    - **Action:**
        1. Create a separate, simple Poetry-based project.
        2. Follow the migration guide created in T003 to convert the project to `uv`.
        3. Refine the documentation based on any ambiguities or issues found.
    - **Done-when:**
        1. The project is successfully migrated using only the documented steps.
        2. The project's dependencies can be installed and tests can be run using `uv` post-migration.
    - **Depends-on:** [T003, T013]

## Clarifications & Assumptions
- [ ] **Issue:** Confirm the exact file path and naming convention for the new binding documents within the repository structure.
    - **Context:** PLAN.md > Phase 2
    - **Blocking?:** no
- [ ] **Issue:** The plan assumes the `ruby tools/*.rb` scripts are up-to-date and functioning correctly.
    - **Context:** PLAN.md > Phase 3
    - **Blocking?:** no
- [ ] **Issue:** Confirm if existing `testing-patterns.md` or `error-handling.md` require minor updates for toolchain consistency (e.g., command examples).
    - **Context:** PLAN.md only lists `dependency-management.md` and `type-hinting.md` for explicit updates.
    - **Blocking?:** no
