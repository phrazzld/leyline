# Todo

## Project Setup & Communication
- [x] **T001 · Chore · P2: Create feature branch for documentation restructure**
    - **Context:** Detailed Build Steps - 1. Preparation & Communication - 1.1
    - **Action:**
        1. Create a new Git branch named `feature/doc-directory-restructure` from the main branch.
    - **Done‑when:**
        1. The branch `feature/doc-directory-restructure` exists in the repository.
    - **Verification:**
        1. `git branch` shows the new branch locally.
        2. Branch is pushed to remote.
    - **Depends‑on:** none

- [x] **T002 · Chore · P1: Announce upcoming breaking change and migration path**
    - **Context:** Detailed Build Steps - 1. Preparation & Communication - 1.2
    - **Note:** This task is skipped since the project isn't actively used by consumers yet.
    - **Depends‑on:** [T001]

## Directory Structure & Content Migration
- [x] **T003 · Feature · P0: Create base directories `docs/bindings/core/` and `docs/bindings/categories/`**
    - **Context:** Detailed Build Steps - 2. Directory Creation - 2.1
    - **Action:**
        1. Create the directory `docs/bindings/core/`.
        2. Create the directory `docs/bindings/categories/`.
    - **Done‑when:**
        1. Both `docs/bindings/core/` and `docs/bindings/categories/` directories exist.
    - **Verification:**
        1. `ls docs/bindings/` shows `core/` and `categories/`.
    - **Depends‑on:** [T001]

- [x] **T004 · Feature · P0: Create initial category subdirectories in `docs/bindings/categories/`**
    - **Context:** Detailed Build Steps - 2. Directory Creation - 2.2
    - **Action:**
        1. Create `docs/bindings/categories/go/`.
        2. Create `docs/bindings/categories/rust/`.
        3. Create `docs/bindings/categories/typescript/`.
        4. Create `docs/bindings/categories/cli/`.
        5. Create `docs/bindings/categories/frontend/`.
        6. Create `docs/bindings/categories/backend/`.
    - **Done‑when:**
        1. All specified initial category directories exist under `docs/bindings/categories/`.
    - **Verification:**
        1. `ls docs/bindings/categories/` shows all created subdirectories.
    - **Depends‑on:** [T003]

- [x] **T005 · Refactor · P0: Move and rename binding files to new directory structure**
    - **Context:** Detailed Build Steps - 3. Move and Rename Bindings
    - **Action:**
        1. For each binding `.md` file in `docs/bindings/`, determine its primary category (core or specific) and move it to the corresponding new directory (`core/` or `categories/<category>/`).
        2. Rename the file to remove any category prefix (e.g., `ts-no-any.md` becomes `no-any.md`).
        3. Apply the cross-cutting binding strategy for bindings that applied to multiple categories (generalize to `core/` or place in primary specific category, clarifying content).
    - **Done‑when:**
        1. All binding files are moved from the root of `docs/bindings/` to their respective new subdirectories.
        2. All moved binding files are renamed according to the new convention.
    - **Verification:**
        1. No binding `.md` files remain directly under `docs/bindings/`.
        2. Spot-check a sample of files in `core/` and `categories/*/` for correct placement and naming.
    - **Depends‑on:** [T004]

- [x] **T006 · Refactor · P0: Update binding front matter: remove `applies_to`, update `id`, verify required fields**
    - **Context:** Detailed Build Steps - 4. Update Binding Front Matter; Architecture Blueprint - Public Interfaces / Contracts - Binding File Front Matter
    - **Action:**
        1. For all binding files in their new locations, remove the `applies_to` field entirely from the front matter.
        2. Ensure the `id` field in the front matter matches the new filename (without `.md` and path).
        3. Verify `last_modified`, `derived_from`, and `enforced_by` fields are present and correct.
    - **Done‑when:**
        1. No binding file front matter contains the `applies_to` field.
        2. All binding file front matters have an `id` field matching their filename.
        3. All binding files have `last_modified`, `derived_from`, and `enforced_by` fields.
    - **Verification:**
        1. Run `tools/validate_front_matter.rb` (once updated by T009) and confirm it passes for all bindings regarding these changes.
        2. Manually inspect a sample of binding front matters.
    - **Depends‑on:** [T005]

## Tooling: `reindex.rb`
- [x] **T007 · Feature · P0: Modify `reindex.rb` to scan new structure, group index, and update links**
    - **Context:** Detailed Build Steps - 5. Update Tooling - `reindex.rb` - 5.1, 5.2, 5.3
    - **Action:**
        1. Modify `tools/reindex.rb` to scan recursively within `docs/bindings/core/` and `docs/bindings/categories/*/`.
        2. Ensure the generated `docs/bindings/00-index.md` includes clear sections for "Core" and each category.
        3. Update links in the generated index to reflect the new relative paths (e.g., `[Binding Name](./categories/go/error-wrapping.md)`).
    - **Done‑when:**
        1. `reindex.rb` generates `docs/bindings/00-index.md` with "Core" and per-category sections.
        2. All links in the generated index point to the correct new file locations.
    - **Verification:**
        1. Run `tools/reindex.rb` locally.
        2. Inspect the generated `docs/bindings/00-index.md` for correct structure, sections, and functional links.
    - **Depends‑on:** [T006]

- [x] **T008 · Feature · P1: Enhance `reindex.rb` to log error and skip misplaced files in `docs/bindings/` root**
    - **Context:** Detailed Build Steps - Error & Edge‑Case Strategy - `reindex.rb`
    - **Action:**
        1. Add logic to `tools/reindex.rb` to detect if a binding file is found directly under `docs/bindings/` (not in `core/` or `categories/*`).
        2. If a misplaced file is found, log an error message specifying the file and skip processing it for the index.
    - **Done‑when:**
        1. `reindex.rb` logs an error and skips any binding file found directly under `docs/bindings/`.
    - **Verification:**
        1. Temporarily place a test binding file in `docs/bindings/`.
        2. Run `tools/reindex.rb` and verify an error is logged and the file is not in `00-index.md`.
    - **Depends‑on:** [T007]

- [ ] **T009 · Feature · P1: Ensure `reindex.rb` gracefully handles empty category directories**
    - **Context:** Detailed Build Steps - Error & Edge‑Case Strategy - `reindex.rb`
    - **Action:**
        1. Modify `tools/reindex.rb` to correctly handle cases where a category directory (e.g., `docs/bindings/categories/new-empty-category/`) exists but contains no binding files.
        2. Ensure the script does not fail and the generated index correctly reflects the empty category (e.g., by omitting the section or noting it's empty).
    - **Done‑when:**
        1. `reindex.rb` completes successfully when encountering empty category directories.
        2. The generated `00-index.md` handles empty categories as expected (e.g., section exists but is empty, or section is omitted).
    - **Verification:**
        1. Create an empty category directory (e.g., `docs/bindings/categories/test-empty/`).
        2. Run `tools/reindex.rb` and verify it completes without error and the index is correctly formatted.
    - **Depends‑on:** [T007]

## Tooling: `validate_front_matter.rb`
- [ ] **T010 · Feature · P0: Modify `validate_front_matter.rb` to remove `applies_to` validation and support new structure**
    - **Context:** Detailed Build Steps - 6. Update Tooling - `validate_front_matter.rb`
    - **Action:**
        1. Modify `tools/validate_front_matter.rb` to stop expecting or validating the `applies_to` field in binding documents.
        2. Update the script to correctly locate and process binding files in their new nested subdirectories (`docs/bindings/core/` and `docs/bindings/categories/*/`).
        3. Ensure it continues to validate `id` (matching filename), `last_modified`, `derived_from`, and `enforced_by`.
    - **Done‑when:**
        1. `validate_front_matter.rb` no longer flags missing `applies_to` in bindings as an error.
        2. The script correctly finds and validates all bindings in the new structure.
        3. Other required fields are still validated correctly.
    - **Verification:**
        1. Run `tools/validate_front_matter.rb` on the restructured bindings.
        2. Confirm it passes for correctly formatted files and fails appropriately for files with issues in other required fields.
    - **Depends‑on:** [T006]

## Workflow: `.github/workflows/vendor.yml`
- [ ] **T011 · Feature · P0: Add `categories` input to `.github/workflows/vendor.yml`**
    - **Context:** Detailed Build Steps - 7. Update Workflow - `.github/workflows/vendor.yml` - 7.1; Architecture Blueprint - Public Interfaces / Contracts - `.github/workflows/vendor.yml` Inputs
    - **Action:**
        1. Add the new `categories` input to `.github/workflows/vendor.yml` with `description: 'Comma-separated list of categories...'`, `required: false`, and `default: ''`.
    - **Done‑when:**
        1. The `.github/workflows/vendor.yml` file includes the `categories` input definition.
    - **Depends‑on:** [T001]

- [ ] **T012 · Feature · P0: Update `vendor.yml` to sync `tenets/`, `core/`, and specified `categories`**
    - **Context:** Detailed Build Steps - 7. Update Workflow - `.github/workflows/vendor.yml` - 7.2 (sync logic)
    - **Action:**
        1. Modify `vendor.yml` workflow logic to always sync `docs/tenets/`.
        2. Modify `vendor.yml` to always sync `docs/bindings/core/`.
        3. Parse the `inputs.categories` string (comma-separated list). For each specified category, if `docs/bindings/categories/<category>/` exists in the Leyline repo, sync its contents to the consumer.
    - **Done‑when:**
        1. `vendor.yml` syncs `docs/tenets/` and `docs/bindings/core/` unconditionally.
        2. `vendor.yml` syncs category-specific bindings from `docs/bindings/categories/<category>/` based on the `categories` input.
    - **Depends‑on:** [T011, T006]

- [ ] **T013 · Feature · P1: Implement warning in `vendor.yml` for non-existent requested category directories**
    - **Context:** Detailed Build Steps - Error & Edge‑Case Strategy - Workflow `vendor.yml`
    - **Action:**
        1. In `vendor.yml`, if a category specified in the `categories` input does not correspond to an existing directory in `docs/bindings/categories/` in the Leyline repo, log a warning.
        2. Ensure the workflow skips that category and continues processing other valid categories.
    - **Done‑when:**
        1. `vendor.yml` logs a warning and continues when a requested category directory does not exist.
    - **Depends‑on:** [T012]

- [ ] **T014 · Feature · P1: Implement failure in `vendor.yml` for invalid `categories` input format**
    - **Context:** Detailed Build Steps - Error & Edge‑Case Strategy - Workflow `vendor.yml`
    - **Action:**
        1. Add validation to `vendor.yml` to check if the `categories` input string contains unexpected characters (e.g., not alphanumeric, comma, or hyphen).
        2. If the format is invalid, fail the workflow with a clear error message.
    - **Done‑when:**
        1. `vendor.yml` fails with a clear error message if the `categories` input has an invalid format.
    - **Depends‑on:** [T012]

- [ ] **T015 · Feature · P0: Implement cleanup step in `vendor.yml` to remove old flat binding structure in consumer repo**
    - **Context:** Detailed Build Steps - 7. Update Workflow - `.github/workflows/vendor.yml` - 7.2 (cleanup step)
    - **Action:**
        1. Add a step to `vendor.yml` that, when run in the consumer repository, removes any files/directories from the *previous* flat `docs/bindings/` structure before copying new files.
    - **Done‑when:**
        1. The `vendor.yml` workflow effectively cleans up the old binding structure in the consumer repository.
    - **Verification:**
        1. As part of integration testing, ensure that after a sync, no stale files from a previous flat structure remain in `docs/bindings/` in the test consumer repo.
    - **Depends‑on:** [T012]

- [ ] **T016 · Feature · P0: Ensure `vendor.yml` runs `reindex.rb` in consumer repo post-sync**
    - **Context:** Detailed Build Steps - 7. Update Workflow - `.github/workflows/vendor.yml` - 7.2 (reindex step)
    - **Action:**
        1. Add a step to `vendor.yml` to execute `tools/reindex.rb` (from the synced Leyline content) in the consumer repository *after* all files are synced and old files are cleaned up.
    - **Done‑when:**
        1. `vendor.yml` successfully runs `reindex.rb` in the consumer repository, updating `docs/bindings/00-index.md`.
    - **Verification:**
        1. As part of integration testing, verify that `docs/bindings/00-index.md` in the test consumer repo is correctly regenerated.
    - **Depends‑on:** [T015, T007]

- [ ] **T017 · Feature · P2: Update PR message in `vendor.yml` to list synced categories**
    - **Context:** Detailed Build Steps - 7. Update Workflow - `.github/workflows/vendor.yml` - 7.2 (PR message step)
    - **Action:**
        1. Modify the part of `vendor.yml` that generates a Pull Request in the consumer repository.
        2. Update the PR message to list the categories of bindings that were synced (e.g., "Synced core bindings and categories: go, rust.").
    - **Done‑when:**
        1. PRs created by `vendor.yml` in the consumer repository include a list of the categories synced.
    - **Verification:**
        1. As part of integration testing, inspect the PR message generated in the test consumer repo.
    - **Depends‑on:** [T012]

## CI: `.github/workflows/ci.yml`
- [ ] **T018 · Feature · P1: Update `.github/workflows/ci.yml` to run `tools/validate_front_matter.rb --strict`**
    - **Context:** Detailed Build Steps - 8. Update Leyline CI - `.github/workflows/ci.yml` - 8.1
    - **Action:**
        1. Ensure the `.github/workflows/ci.yml` workflow executes `tools/validate_front_matter.rb --strict`.
    - **Done‑when:**
        1. The Leyline CI pipeline runs `tools/validate_front_matter.rb --strict` on relevant code changes.
    - **Verification:**
        1. CI build logs show the execution of the script with the `--strict` flag.
    - **Depends‑on:** [T010]

- [ ] **T019 · Feature · P1: Update `.github/workflows/ci.yml` to run `tools/reindex.rb` and check `00-index.md` consistency**
    - **Context:** Detailed Build Steps - 8. Update Leyline CI - `.github/workflows/ci.yml` - 8.2
    - **Action:**
        1. Ensure the `.github/workflows/ci.yml` workflow executes `tools/reindex.rb`.
        2. Add a step to check if `docs/bindings/00-index.md` has uncommitted changes after running `reindex.rb`; if so, fail the CI build.
    - **Done‑when:**
        1. The Leyline CI pipeline runs `tools/reindex.rb` and fails if `docs/bindings/00-index.md` is not up-to-date.
    - **Verification:**
        1. Intentionally make `00-index.md` outdated, push, and verify CI fails.
        2. Commit the correct `00-index.md`, push, and verify CI passes.
    - **Depends‑on:** [T007]

## Documentation Updates
- [ ] **T020 · Docs · P1: Update `README.md` / `docs/index.md` for new structure and `vendor.yml` usage**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.1
    - **Action:**
        1. In `README.md` and/or `docs/index.md`, explain the new `docs/bindings/core/` and `docs/bindings/categories/` directory structure.
        2. Document how to use the updated `vendor.yml` workflow with the new `categories` input.
    - **Done‑when:**
        1. `README.md` and/or `docs/index.md` accurately describe the new structure and `vendor.yml` usage.
    - **Verification:**
        1. Review the updated documentation for clarity and correctness.
    - **Depends‑on:** [T005, T011]

- [ ] **T021 · Docs · P1: Update `CONTRIBUTING.md` for new binding placement, front matter, and cross-cutting strategy**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.2
    - **Action:**
        1. Update `CONTRIBUTING.md` to guide contributors on where to place new bindings (in `core/` or `categories/<category>/`).
        2. Document the updated front matter requirements (no `applies_to`, `id` matches filename).
        3. Explain the strategy for handling cross-cutting bindings.
    - **Done‑when:**
        1. `CONTRIBUTING.md` provides clear and accurate guidance for contributors.
    - **Verification:**
        1. Review `CONTRIBUTING.md` to ensure the new guidelines are easy to understand and follow.
    - **Depends‑on:** [T005, T006]

- [ ] **T022 · Docs · P0: Create `docs/migration-guide.md` for consumer workflow updates**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.3
    - **Action:**
        1. Create a new file `docs/migration-guide.md`.
        2. Document step-by-step instructions for existing consumers to update their workflows:
           - How to update `vendor.yml` workflow call with the new `categories` input
           - What happens with the cleanup step and reindexing
           - How to select the appropriate categories for their needs
    - **Done‑when:**
        1. `docs/migration-guide.md` exists with clear migration instructions.
    - **Verification:**
        1. Review the migration guide for clarity, completeness, and correctness.
    - **Depends‑on:** [T012]

- [ ] **T023 · Docs · P1: Update `docs/binding-metadata.md` or `TENET_FORMATTING.md` for binding categorization**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.4
    - **Action:**
        1. Update relevant documentation to reflect the removal of `applies_to` field.
        2. Document the new directory-based categorization approach.
        3. Update any examples or schemas to match the new front matter structure.
    - **Done‑when:**
        1. Documentation accurately reflects the new approach to binding categorization.
    - **Verification:**
        1. Review the updated documentation for clarity and correctness.
    - **Depends‑on:** [T006]

- [ ] **T024 · Docs · P1: Update `mkdocs.yml` navigation section**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.5
    - **Action:**
        1. Update the `nav` section in `mkdocs.yml` to correctly point to all bindings in their new locations.
    - **Done‑when:**
        1. `mkdocs.yml` navigation reflects the new directory structure.
    - **Verification:**
        1. Run `mkdocs serve` locally and verify all navigation links work correctly.
    - **Depends‑on:** [T005]

- [ ] **T025 · Docs · P2: Review and update other documentation references**
    - **Context:** Detailed Build Steps - 9. Update Documentation - 9.6
    - **Action:**
        1. Search for references to the old structure or `applies_to` across the codebase.
        2. Update any found references to match the new approach.
    - **Done‑when:**
        1. No references to the old structure or `applies_to` remain in documentation.
    - **Verification:**
        1. Search for keywords like "applies_to" and review results.
    - **Depends‑on:** [T023]

## Testing
- [ ] **T026 · Test · P1: Add unit tests for updated `reindex.rb`**
    - **Context:** Testing Strategy - Unit Tests for `reindex.rb`
    - **Action:**
        1. Create unit tests for `reindex.rb` covering:
           - Scanning nested directory structure
           - Generating sections for core and categories
           - Handling empty categories
           - Link generation logic
    - **Done‑when:**
        1. Unit tests cover critical logic in `reindex.rb` with >80% coverage.
    - **Verification:**
        1. Run tests and verify they pass.
    - **Depends‑on:** [T007, T008, T009]

- [ ] **T027 · Test · P1: Add unit tests for updated `validate_front_matter.rb`**
    - **Context:** Testing Strategy - Unit Tests for `validate_front_matter.rb`
    - **Action:**
        1. Create unit tests for `validate_front_matter.rb` covering:
           - No longer validating `applies_to`
           - Validating correct `id`, `last_modified`, `derived_from`, `enforced_by`
           - Finding bindings in nested directories
    - **Done‑when:**
        1. Unit tests cover critical logic in `validate_front_matter.rb` with >80% coverage.
    - **Verification:**
        1. Run tests and verify they pass.
    - **Depends‑on:** [T010]

- [ ] **T028 · Test · P0: Perform integration testing with test consumer repository**
    - **Context:** Testing Strategy - Integration Tests
    - **Action:**
        1. Set up a dedicated test GitHub repository that calls `vendor.yml` from the feature branch.
        2. Test with various inputs:
           - No `categories` (should sync only `tenets/` and `core/`)
           - Specific categories (e.g., `"go,typescript"`)
           - Multiple categories (e.g., `"go,frontend"`)
           - Non-existent categories
    - **Done‑when:**
        1. The workflow correctly syncs files based on inputs, cleans up old files, regenerates the index, and creates a PR with appropriate message.
    - **Verification:**
        1. Verify the correct files are present in the consumer repo.
        2. Verify no stale files remain.
        3. Verify the index is correctly generated.
    - **Depends‑on:** [T016]

- [ ] **T029 · Test · P2: Perform end-to-end test with real consumer**
    - **Context:** Testing Strategy - End-to-End (E2E) Tests
    - **Action:**
        1. After release, assist a real consumer repository in updating to the new Leyline version.
        2. Support them through the migration process.
    - **Done‑when:**
        1. A real consumer successfully migrates to the new structure and their documentation is correctly synced.
    - **Verification:**
        1. Work with the consumer to verify successful migration.
    - **Depends‑on:** [T031]

## Release & Communication
- [ ] **T030 · Chore · P1: Merge feature branch to main**
    - **Context:** Detailed Build Steps - 11. Merge, Release, and Communicate - 11.1
    - **Action:**
        1. Create PR from `feature/doc-directory-restructure` to `main`.
        2. Ensure all checks pass and PR is reviewed.
        3. Merge to `main`.
    - **Done‑when:**
        1. Branch is merged to `main`.
    - **Verification:**
        1. Verify the commit is present in `main`.
    - **Depends‑on:** [T020, T021, T022, T023, T024, T025, T028]

- [ ] **T031 · Chore · P0: Tag new release with breaking change**
    - **Context:** Detailed Build Steps - 11. Merge, Release, and Communicate - 11.2
    - **Action:**
        1. Tag a new release with an appropriate version bump (likely minor or major).
        2. Include release notes detailing the breaking change and migration path.
    - **Done‑when:**
        1. New release tag exists on the repository.
    - **Verification:**
        1. Verify the tag exists and release notes are correct.
    - **Depends‑on:** [T030]

- [ ] **T032 · Chore · P1: Communicate release and migration guide to consumers**
    - **Context:** Detailed Build Steps - 11. Merge, Release, and Communicate - 11.3
    - **Action:**
        1. Re-communicate the release to consumers, pointing to the new version and migration guide.
    - **Done‑when:**
        1. Communication is sent to consumers.
    - **Verification:**
        1. Verify consumers have received the communication.
    - **Depends‑on:** [T031]

## Open Questions
- [ ] **Issue: Strict validation of categories input values**
    - **Context:** Open Questions - Strict validation of `categories` input values in `vendor.yml`
    - **Description:** Determine whether to implement strict validation of `categories` input values against a predefined list now or defer to later.
    - **Decision:** Current decision is to attempt to use any string provided in `categories`. If the directory doesn't exist, log a warning and skip.
    - **Blocking?:** No

- [ ] **Issue: Process for handling newly created category directories**
    - **Context:** Open Questions - Handling of newly created category directories in Leyline
    - **Description:** Define the process for how consumers will be informed about and receive content from newly added category directories in Leyline.
    - **Decision:** Consumers will only receive content for categories they explicitly request and that exist in their synced version of Leyline.
    - **Blocking?:** No
