# Todo

## Terminology & Documentation Philosophy
- [x] **T001 · Chore · P1: define and document "Warden System" vs. "Pull-Based Sync" terminology**
    - **Context:** Detailed Build Steps #1, Risk Matrix (Ambiguity remains in documentation)
    - **Action:**
        1. Document that "Warden System" is Leyline's *philosophy* of standardized principles.
        2. Document that "Pull-Based Sync" via `sync-leyline-content.yml` is the *consumer-initiated implementation*.
        3. Ensure definitions emphasize consumer-initiated pull and no Leyline push.
    - **Done‑when:**
        1. Terminology definitions are finalized and recorded for team use.
        2. All subsequent documentation tasks can refer to these definitions.
    - **Depends‑on:** none

## Reusable Workflow: `leyline/.github/workflows/sync-leyline-content.yml`
- [x] **T002 · Refactor · P1: review existing `vendor.yml` and rename to `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2, Architecture Blueprint - `leyline/.github/workflows/sync-leyline-content.yml`
    - **Action:**
        1. Locate and analyze any existing `vendor.yml` or similar workflow for reusable logic.
        2. Rename the relevant workflow file to `sync-leyline-content.yml` in `leyline/.github/workflows/`.
        3. Establish the basic `on: workflow_call:` structure.
    - **Done‑when:**
        1. `leyline/.github/workflows/sync-leyline-content.yml` exists with the basic structure.
        2. Old workflow (if any) is renamed or its contents considered for migration.
    - **Depends‑on:** none

- [x] **T003 · Feature · P1: implement required inputs (`token`, `leyline_ref`) for `sync-leyline-content.yml`**
    - **Context:** Public Interfaces / Contracts - `sync-leyline-content.yml` Inputs
    - **Action:**
        1. Define `token: { required: true, type: string }` and `leyline_ref: { required: true, type: string }` in the workflow's `inputs` section.
        2. Add initial validation or usage of these inputs (e.g., passing `token` to checkout actions, using `leyline_ref` for Leyline checkout).
    - **Done‑when:**
        1. Workflow correctly parses `token` and `leyline_ref` inputs.
        2. Workflow fails if these required inputs are not provided by the caller.
    - **Depends‑on:** [T002]

- [x] **T004 · Feature · P1: implement optional general inputs (`categories`, `target_path`, `create_pr`) for `sync-leyline-content.yml`**
    - **Context:** Public Interfaces / Contracts - `sync-leyline-content.yml` Inputs
    - **Action:**
        1. Define `categories: { required: false, type: string, default: '' }`, `target_path: { required: false, type: string, default: 'docs/leyline' }`, and `create_pr: { required: false, type: boolean, default: true }` in workflow inputs.
        2. Ensure default values are applied correctly when inputs are omitted.
    - **Done‑when:**
        1. Workflow correctly parses optional inputs and applies defaults.
    - **Depends‑on:** [T002]

- [x] **T005 · Feature · P1: implement optional PR-specific inputs (`commit_message`, `pr_title`, `pr_branch_name`) for `sync-leyline-content.yml`**
    - **Context:** Public Interfaces / Contracts - `sync-leyline-content.yml` Inputs
    - **Action:**
        1. Define `commit_message` (default: `docs: Sync Leyline content from @${{ inputs.leyline_ref }}`), `pr_title` (default: `Sync Leyline Content @${{ inputs.leyline_ref }}`), and `pr_branch_name` (default: `leyline-sync/${{ inputs.leyline_ref }}`) as optional string inputs.
        2. Ensure default values correctly use the `inputs.leyline_ref` context.
    - **Done‑when:**
        1. Workflow correctly parses PR-specific inputs and applies dynamic defaults.
    - **Depends‑on:** [T003]

- [x] **T006 · Feature · P1: implement Leyline content checkout logic in `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2
    - **Action:**
        1. Use `actions/checkout@vX` to check out the Leyline repository.
        2. Configure the checkout action to use the `inputs.leyline_ref` to fetch the specified version of Leyline content into a temporary path.
    - **Done‑when:**
        1. The specified Leyline version's content is checked out successfully.
    - **Depends‑on:** [T003]

- [x] **T007 · Feature · P1: implement file copying for `tenets`, `core` bindings, and specified `categories` in `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2, Architecture Blueprint - `sync-leyline-content.yml`
    - **Action:**
        1. Copy all content from the checked-out Leyline `tenets/` directory to `inputs.target_path`.
        2. Copy content from `bindings/core/` to `inputs.target_path`.
        3. If `inputs.categories` is provided, parse the comma-separated list and copy content from each `bindings/categories/<category_name>/` to `inputs.target_path`.
    - **Done‑when:**
        1. `tenets`, `core` bindings, and specified `categories` are copied to the consumer repository's workspace at `inputs.target_path`.
    - **Depends‑on:** [T004, T006]

- [x] **T008 · Feature · P2: implement efficient file copying with stale file removal in `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2 (efficient file copying)
    - **Action:**
        1. Implement file copying (e.g., using `rsync --delete` or equivalent `cp` and `rm` logic) to ensure files/directories in `inputs.target_path` that are no longer in the source Leyline content (for the synced set) are removed.
    - **Done‑when:**
        1. Stale files in `inputs.target_path` are removed upon sync.
        2. File copying is efficient.
    - **Verification:**
        1. Sync version A of Leyline. Then sync version B (where a file from A is removed). Verify the removed file is no longer in `target_path`.
    - **Depends‑on:** [T007]

- [x] **T009 · Feature · P1: implement Pull Request creation logic in `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2, Public Interfaces / Contracts - Outputs
    - **Action:**
        1. Integrate `peter-evans/create-pull-request@vX` action.
        2. Configure it using `inputs.token`, `inputs.commit_message`, `inputs.pr_title`, `inputs.pr_branch_name`.
        3. Ensure this step is skipped if `inputs.create_pr` is `false`.
    - **Done‑when:**
        1. A PR is created in the consumer repository if `inputs.create_pr` is true and changes exist.
        2. No PR is created if `inputs.create_pr` is false.
    - **Depends‑on:** [T003, T005, T008]

- [x] **T010 · Feature · P1: implement outputs (`pr_url`, `commit_sha`) for `sync-leyline-content.yml`**
    - **Context:** Public Interfaces / Contracts - `sync-leyline-content.yml` Outputs
    - **Action:**
        1. Define `pr_url: { type: string }` and `commit_sha: { type: string }` in the workflow's `outputs` section.
        2. Capture and set these outputs from the `create-pull-request` action's results if a PR/commit is made.
    - **Done‑when:**
        1. Workflow outputs `pr_url` and `commit_sha` are correctly populated when a PR is created.
    - **Depends‑on:** [T009]

- [x] **T011 · Feature · P1: implement error handling for invalid `leyline_ref` in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - Invalid `leyline_ref`
    - **Action:**
        1. After the Leyline content checkout step (T006), check if it was successful.
        2. If checkout fails (e.g., due to an invalid ref), fail the workflow with a clear error message (e.g., "Error: Invalid `leyline_ref` provided: ${{ inputs.leyline_ref }}").
    - **Done‑when:**
        1. Workflow fails with a descriptive error message if `leyline_ref` is invalid.
    - **Verification:**
        1. Test with a non-existent tag/branch for `leyline_ref`.
    - **Depends‑on:** [T006]

- [x] **T012 · Feature · P2: implement handling for non-existent `categories` in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - Non-existent `categories`
    - **Action:**
        1. When processing `inputs.categories`, if a specified category directory does not exist in the checked-out Leyline content, issue a warning (e.g., `::warning::Category '<category_name>' not found in Leyline ref '${{ inputs.leyline_ref }}'. Skipping.`).
        2. Proceed to sync `tenets`, `core` bindings, and any other valid requested categories.
    - **Done‑when:**
        1. Workflow logs a warning for each non-existent category and continues.
    - **Verification:**
        1. Test with a mix of valid and invalid category names.
    - **Depends‑on:** [T007]

- [x] **T013 · Feature · P2: implement `target_path` creation if non-existent in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - `target_path` non-existent
    - **Action:**
        1. Before copying files, check if `inputs.target_path` exists in the consumer repository's workspace.
        2. If not, create the directory path (e.g., using `mkdir -p`).
    - **Done‑when:**
        1. `inputs.target_path` is created if it does not exist.
    - **Verification:**
        1. Test by syncing to a `target_path` that does not initially exist.
    - **Depends‑on:** [T007]

- [x] **T014 · Feature · P1: implement "no changes detected" handling in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - No changes detected
    - **Action:**
        1. After file copying (T008) and before attempting to commit, check if any actual file changes occurred in `inputs.target_path`.
        2. If no changes, log "No changes to sync." and skip commit and PR creation steps.
    - **Done‑when:**
        1. Workflow completes successfully without creating a commit/PR if no content changes.
    - **Verification:**
        1. Run sync twice with the same `leyline_ref`. The second run should report no changes.
    - **Depends‑on:** [T008, T009]

- [ ] **T015 · Feature · P2: implement error handling for `token` permission issues in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - Permission errors
    - **Action:**
        1. Ensure that failures in steps requiring special permissions (checkout, PR creation) provide clear error messages suggesting a token permission issue.
        2. Explicitly catch common errors from `create-pull-request` action related to permissions.
    - **Done‑when:**
        1. Workflow fails with a clear message indicating likely permission issues if token lacks necessary scopes.
    - **Verification:**
        1. Test with a token that has insufficient permissions (e.g., read-only).
    - **Depends‑on:** [T009]

- [ ] **T016 · Feature · P2: implement error handling for PR branch conflicts in `sync-leyline-content.yml`**
    - **Context:** Error & Edge‑Case Strategy - Merge conflicts if `pr_branch_name` already exists
    - **Action:**
        1. Configure `peter-evans/create-pull-request` to handle existing branches.
        2. If PR creation fails due to a conflicting existing branch with diverged history, ensure the error message is clear, prompting manual intervention.
    - **Done‑when:**
        1. PR creation step fails clearly if the target branch exists and has diverged.
    - **Verification:**
        1. Manually create a branch with the default `pr_branch_name`, add a conflicting commit, then run the sync.
    - **Depends‑on:** [T009]

- [ ] **T017 · Chore · P2: add comprehensive logging throughout `sync-leyline-content.yml`**
    - **Context:** Detailed Build Steps #2
    - **Action:**
        1. Add `echo` statements or use workflow logging commands (e.g., `::debug::`, `::info::`) at key stages: start, inputs received, Leyline checkout, files being copied, categories processed, changes detected/not detected, PR creation attempt.
    - **Done‑when:**
        1. Workflow execution logs are informative and aid in traceability/debugging.
    - **Depends‑on:** [T002, T003, T004, T005, T006, T007, T008, T009, T010, T011, T012, T013, T014, T015, T016]

## Core Documentation (`README.md`, `docs/index.md`)
- [ ] **T018 · Chore · P1: update `README.md` and `docs/index.md` with pull-based model information**
    - **Context:** Detailed Build Steps #3
    - **Action:**
        1. Clearly explain the pull-based model as the sole standard integration pattern in `README.md` and `docs/index.md`.
        2. Reframe the "Warden System" conceptually per T001.
        3. Provide a high-level overview of `sync-leyline-content.yml` usage and link prominently to new integration guides (T020, T021).
    - **Done‑when:**
        1. `README.md` and `docs/index.md` are updated to reflect the pull-based model and link to new guides.
    - **Verification:**
        1. Review rendered `README.md` and `docs/index.md` for clarity and correct links.
    - **Depends‑on:** [T001]

## New Integration Guides (`docs/integration/`)
- [ ] **T019 · Chore · P1: create `docs/integration/` directory**
    - **Context:** Architecture Blueprint - `leyline/docs/integration/`
    - **Action:**
        1. Create the new directory `leyline/docs/integration/`.
    - **Done‑when:**
        1. The `leyline/docs/integration/` directory exists in the repository structure.
    - **Depends‑on:** none

- [ ] **T020 · Feature · P1: create `pull-model-guide.md` for consumer integration**
    - **Context:** Detailed Build Steps #4, Architecture Blueprint - `pull-model-guide.md`
    - **Action:**
        1. Create `docs/integration/pull-model-guide.md`.
        2. Write comprehensive step-by-step instructions for integrating using `sync-leyline-content.yml`, detailing all inputs/outputs, CI/CD triggers, and troubleshooting common issues (permissions, invalid inputs, version conflicts).
        3. Explicitly state "Warden System" is a philosophy, not a push mechanism, and sync is consumer-initiated.
    - **Done‑when:**
        1. `pull-model-guide.md` is complete, accurate, and clear for consumers.
    - **Verification:**
        1. Review guide against workflow features (T003-T016) and error strategies.
    - **Depends‑on:** [T001, T017, T019]

- [ ] **T021 · Feature · P1: create `versioning-guide.md` for Leyline versioning**
    - **Context:** Detailed Build Steps #4, Architecture Blueprint - `versioning-guide.md`
    - **Action:**
        1. Create `docs/integration/versioning-guide.md`.
        2. Explain Leyline's release/versioning strategy (e.g., SemVer for tags).
        3. Provide explicit recommendations for consumers on `leyline_ref` (pinning to tags, strongly warning against floating refs like `main`, using Dependabot/Renovate).
    - **Done‑when:**
        1. `versioning-guide.md` clearly explains versioning and best practices for `leyline_ref`.
    - **Verification:**
        1. Review guide for clarity on version pinning and warnings.
    - **Depends‑on:** [T019]

## Consumer Workflow Examples (`examples/consumer-workflows/`)
- [ ] **T022 · Chore · P1: create `examples/consumer-workflows/` directory**
    - **Context:** Architecture Blueprint - `leyline/examples/consumer-workflows/`
    - **Action:**
        1. Create the new directory `leyline/examples/consumer-workflows/`.
    - **Done‑when:**
        1. The `leyline/examples/consumer-workflows/` directory exists.
    - **Depends‑on:** none

- [ ] **T023 · Feature · P1: create `sync-leyline-example.yml` consumer workflow example**
    - **Context:** Detailed Build Steps #5, Architecture Blueprint - `sync-leyline-example.yml`
    - **Action:**
        1. Create `examples/consumer-workflows/sync-leyline-example.yml`.
        2. Provide a minimal, heavily commented, copy-paste ready example calling `leyline/.github/workflows/sync-leyline-content.yml@vX.Y.Z` (use a placeholder like `@v1` or `@main` initially, to be updated upon workflow tagging).
        3. Include commented-out examples for `categories` and other common configurations.
    - **Done‑when:**
        1. `sync-leyline-example.yml` is a clear, functional example for consumers.
    - **Verification:**
        1. Manually inspect the example for clarity and correctness.
    - **Depends‑on:** [T017, T022]

- [ ] **T024 · Chore · P2: update or deprecate existing consumer workflow examples**
    - **Context:** Detailed Build Steps #5
    - **Action:**
        1. Review any existing consumer workflow examples.
        2. Update them to use the standardized `sync-leyline-content.yml` or clearly deprecate them, pointing to the new standard example (T023).
    - **Done‑when:**
        1. All consumer examples are aligned with the new standard or deprecated.
    - **Depends‑on:** [T023]

## Existing Supporting Documentation Updates
- [ ] **T025 · Chore · P2: update `docs/migration-guide.md`**
    - **Context:** Detailed Build Steps #6
    - **Action:**
        1. Update `docs/migration-guide.md` with instructions for migrating from any legacy sync methods to `sync-leyline-content.yml`.
    - **Done‑when:**
        1. Migration guide provides clear steps for users of old methods.
    - **Depends‑on:** [T017, T020]

- [ ] **T026 · Chore · P2: update `docs/implementation-guide.md` for Leyline authors**
    - **Context:** Detailed Build Steps #6
    - **Action:**
        1. Ensure `docs/implementation-guide.md` is clearly focused on *authors contributing new tenets/bindings to Leyline itself*.
        2. Clarify how the directory structure (`core/`, `categories/`) supports the pull mechanism.
    - **Done‑when:**
        1. `docs/implementation-guide.md` has a clear audience and explains directory structure relevance.
    - **Depends‑on:** [T001]

- [ ] **T027 · Chore · P2: update `CONTRIBUTING.md` for consistency**
    - **Context:** Detailed Build Steps #6
    - **Action:**
        1. Review `CONTRIBUTING.md` and verify its consistency with the pull-based model and updated terminology.
    - **Done‑when:**
        1. `CONTRIBUTING.md` is consistent with the new standard.
    - **Depends‑on:** [T001]

- [ ] **T028 · Chore · P3: review and update all other documentation (e.g., `CLAUDE.md`)**
    - **Context:** Detailed Build Steps #6
    - **Action:**
        1. Review all other miscellaneous documentation files for outdated references to push mechanisms or the "Warden System" as an active agent.
        2. Update these references accordingly.
    - **Done‑when:**
        1. All miscellaneous documentation is consistent with the new standard.
    - **Depends‑on:** [T001]

## Testing and Validation
- [ ] **T029 · Test · P1: set up test consumer repository for `sync-leyline-content.yml` integration testing**
    - **Context:** Testing Strategy - Reusable Workflow Integration Testing
    - **Action:**
        1. Create a dedicated private test consumer repository.
        2. This repository will contain a workflow that calls `leyline/.github/workflows/sync-leyline-content.yml` (pointing to the development branch of Leyline during testing).
    - **Done‑when:**
        1. Test consumer repository is created and configured with a calling workflow.
    - **Depends‑on:** [T017]

- [ ] **T030 · Test · P0: test `sync-leyline-content.yml` - default inputs scenario**
    - **Context:** Testing Strategy - Test scenarios
    - **Action:**
        1. Trigger the test workflow in the consumer repo (T029) using default inputs for `sync-leyline-content.yml`.
    - **Done‑when:**
        1. Correct files (`tenets`, `core` bindings) are synced to the default `target_path`. PR is created with default messages/branch. Outputs are populated.
    - **Verification:**
        1. Inspect consumer repo files, PR, workflow logs, and outputs.
    - **Depends‑on:** [T029]

- [ ] **T031 · Test · P0: test `sync-leyline-content.yml` - specific `categories`, custom `target_path`, `create_pr: false` scenarios**
    - **Context:** Testing Strategy - Test scenarios
    - **Action:**
        1. Trigger test workflow with specific `categories` (valid and non-existent mix).
        2. Trigger test workflow with a custom `target_path`.
        3. Trigger test workflow with `create_pr: false`.
    - **Done‑when:**
        1. Correct files synced, warnings for non-existent categories logged, custom path used, PR skipped as expected.
    - **Verification:**
        1. Inspect consumer repo files, PRs (or lack thereof), workflow logs.
    - **Depends‑on:** [T029]

- [ ] **T032 · Test · P0: test `sync-leyline-content.yml` - error/edge case scenarios (invalid ref, no changes, permissions)**
    - **Context:** Testing Strategy - Test scenarios
    - **Action:**
        1. Trigger test workflow with an invalid `leyline_ref`.
        2. Trigger test workflow when no content changes are expected (run twice).
        3. Trigger test workflow with a token lacking sufficient permissions.
    - **Done‑when:**
        1. Workflow fails/completes as expected for each error/edge case, with clear logs/messages.
    - **Verification:**
        1. Inspect workflow logs and consumer repo state.
    - **Depends‑on:** [T029]

- [ ] **T033 · Test · P0: test `sync-leyline-content.yml` - content changes (add, modify, remove) scenario**
    - **Context:** Testing Strategy - Test scenarios
    - **Action:**
        1. In a test branch of Leyline, add, modify, and remove some tenet/binding files.
        2. Trigger the test workflow in the consumer repo, pointing `leyline_ref` to this test branch.
    - **Done‑when:**
        1. Consumer repository's `target_path` correctly reflects all additions, modifications, and removals.
    - **Verification:**
        1. Inspect the created PR diff or commit diff in the consumer repo.
    - **Depends‑on:** [T029]

- [ ] **T034 · Chore · P1: refine `sync-leyline-content.yml` based on integration test results**
    - **Context:** Implementation Timeline - Week 2: Testing & Refinement
    - **Action:**
        1. Address any bugs, inconsistencies, or areas for improvement in `sync-leyline-content.yml` identified during T030-T033.
    - **Done‑when:**
        1. All identified issues from integration testing are resolved in the workflow.
    - **Depends‑on:** [T030, T031, T032, T033]

- [ ] **T035 · Test · P0: manually review all updated and new documentation**
    - **Context:** Testing Strategy - Documentation Review, Implementation Timeline - Week 2
    - **Action:**
        1. Conduct a rigorous manual review of all new and updated documentation (T018, T020, T021, T025, T026, T027, T028) by at least two team members.
        2. Focus on clarity, accuracy, consistency of terminology (per T001), and completeness.
    - **Done‑when:**
        1. All documentation has been reviewed and approved. Feedback is incorporated.
    - **Depends‑on:** [T001, T018, T020, T021, T025, T026, T027, T028]

## Finalization & Communication (Post-Implementation)
- [ ] **T036 · Chore · P1: tag stable version of `sync-leyline-content.yml` workflow**
    - **Context:** Implementation Timeline - Week 3: Finalization & Release
    - **Action:**
        1. After successful testing (T034) and documentation review (T035), create a stable version tag (e.g., `v1.0.0`) for the commit containing the finalized `sync-leyline-content.yml`.
        2. Update `sync-leyline-example.yml` (T023) and documentation (T020, T021) to reference this stable tag.
    - **Done‑when:**
        1. A stable version tag is created for the workflow.
        2. Examples and guides reference this tag.
    - **Verification:**
        1. Check tag in repo. Verify example and docs use `@vX.Y.Z`.
    - **Depends‑on:** [T023, T034, T035]

- [ ] **T037 · Chore · P1: announce standardized pull-based model and new documentation**
    - **Context:** Detailed Build Steps #8, Communication Plan
    - **Action:**
        1. Announce the standardized pull-based model through appropriate channels (e.g., project README update, release notes).
        2. Clearly direct users to the new documentation (T020, T021) and examples (T023).
        3. Highlight benefits: clarity, consumer control, version-pinning.
    - **Done‑when:**
        1. Announcement is published through designated channels.
    - **Depends‑on:** [T018, T020, T021, T023, T036]

- [ ] **T038 · Chore · P1: open a pull request for pull-based distribution model implementation linking to issue #9**
    - **Context:** Implementation completion
    - **Action:**
        1. Create a PR for the implementation of the pull-based distribution model.
        2. Link the PR to GitHub issue #9.
        3. Include a summary of changes and their benefits.
    - **Done‑when:**
        1. PR is created and linked to issue #9.
    - **Depends‑on:** [T035, T036]

### Clarifications & Assumptions
- [ ] **Issue:** Confirm location and content of any existing `vendor.yml` or similar workflow to be refined/renamed.
    - **Context:** Detailed Build Steps #2
    - **Blocking?:** no (can proceed with new creation if none found, but good to check)
- [ ] **Issue:** Identify specific "other documentation (`CLAUDE.md`, etc.)" needing review in T028.
    - **Context:** Detailed Build Steps #6
    - **Blocking?:** no (can be a general sweep, but specific list helps scope)
- [ ] **Issue:** Confirm Leyline's release and versioning strategy (e.g., SemVer for tags) for T021 if not already formally defined.
    - **Context:** Detailed Build Steps #4 (`versioning-guide.md`)
    - **Blocking?:** no (guide can propose one if undefined, but best to align)
