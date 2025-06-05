# Todo

## Pre-commit & CI Validation
- [x] **T001 · Feature · P1: create pre-commit configuration file**
    - **Context:** PLAN.md § Phase 1.1 Create Pre-commit Configuration
    - **Action:**
        1. Create `.pre-commit-config.yaml` in the repository root.
        2. Populate the file with the specified `local` hook to execute `ruby tools/validate_front_matter.rb`.
        3. Ensure the hook is scoped to `^docs/(tenets|bindings)/.*\.md$` and `pass_filenames` is `false`.
    - **Done‑when:**
        1. The `.pre-commit-config.yaml` file exists with the exact configuration from the plan.
    - **Verification:**
        1. Run `pre-commit run --all-files` locally to confirm the hook executes without configuration errors.
    - **Depends‑on:** none

- [x] **T002 · Feature · P1: create github actions workflow for validation**
    - **Context:** PLAN.md § Phase 2.1 Create GitHub Actions Workflow
    - **Action:**
        1. Create `.github/workflows/validate.yml` with the specified workflow definition.
        2. Configure the workflow to trigger on push and pull requests to `master` and `main`.
        3. Add steps for code checkout, Ruby 3.0 setup, and executing the validation script.
    - **Done‑when:**
        1. The workflow file exists and passes GitHub's syntax validation.
        2. The "Validate Content" action runs on pull requests targeting `main` or `master`.
    - **Depends‑on:** none

- [x] **T003 · Chore · P1: configure branch protection to require validation**
    - **Context:** PLAN.md § Phase 2.2 Branch Protection Enhancement
    - **Action:**
        1. In GitHub repository settings, update branch protection rules for `main` and `master`.
        2. Add `validate` as a required status check before merging.
        3. Enable "Require status checks to be up to date before merging" and "Include administrators".
    - **Done‑when:**
        1. GitHub blocks pull requests from merging if the `validate` check has not passed.
    - **Verification:**
        1. Open a test PR and confirm the `validate` check is listed as a required check in the merge box.
    - **Depends‑on:** [T002]

- [x] **T004 · Docs · P2: update CONTRIBUTING.md with setup and troubleshooting**
    - **Context:** PLAN.md § Phase 1.2, 4.1, 4.2
    - **Action:**
        1. Add a "Pre-commit Hooks (Required)" section with installation and usage commands.
        2. Add a "Validation Troubleshooting" section detailing common Ruby, YAML, and CI errors with their solutions.
        3. Add clear Ruby 3.0+ installation instructions to mitigate the contributor dependency risk.
    - **Done‑when:**
        1. `CONTRIBUTING.md` contains comprehensive setup, usage, and troubleshooting guidance for the validation process.
    - **Verification:**
        1. A new contributor can successfully set up the pre-commit hook and resolve a simulated error using only the guide.
    - **Depends‑on:** [T001]

- [ ] **T005 · Docs · P2: update README.md with development validation info**
    - **Context:** PLAN.md § Phase 1.2 Update Repository Documentation
    - **Action:**
        1. Add or update a "Development Setup" section in `README.md`.
        2. Briefly explain the automated validation process and link to `CONTRIBUTING.md` for full setup instructions.
    - **Done‑when:**
        1. `README.md` clearly communicates the existence of the validation process to new developers.
    - **Depends‑on:** [T004]

- [ ] **T006 · Test · P1: test pre-commit hook with all error scenarios**
    - **Context:** PLAN.md § Phase 3.1 Layer 2 & 3.2 Error Scenario Testing
    - **Action:**
        1. Install the pre-commit hook locally.
        2. Attempt to commit files with each specified error: invalid YAML syntax, missing required fields, invalid field formats, duplicate IDs, and missing tenet references.
    - **Done‑when:**
        1. The pre-commit hook blocks every invalid commit attempt.
        2. The error messages printed to the console are clear and identify the specific validation failure.
        3. A commit with valid files is allowed to pass.
    - **Verification:**
        1. Create a file with invalid YAML (e.g., a missing `id` field).
        2. Run `git add .` and `git commit -m "test: invalid commit"`.
        3. Verify the commit is aborted and an error message is displayed.
    - **Depends‑on:** [T001]

- [ ] **T007 · Test · P1: test CI workflow with all error scenarios**
    - **Context:** PLAN.md § Phase 3.1 Layer 3 & 3.2 Error Scenario Testing
    - **Action:**
        1. Create a pull request with one or more files containing validation errors (e.g., duplicate ID, invalid date format).
        2. After confirming failure, push a fix to the same PR.
        3. Create a separate pull request with only valid changes.
    - **Done‑when:**
        1. The CI `validate` job fails on the PR with errors, displaying clear failure logs.
        2. The CI `validate` job passes after the fix is pushed.
        3. The CI `validate` job passes on the PR with only valid changes.
    - **Verification:**
        1. Check the "Checks" tab on the test pull requests to confirm the pass/fail status of the `Validate Content` workflow.
    - **Depends‑on:** [T002]

- [ ] **T008 · Test · P2: benchmark validation script performance**
    - **Context:** PLAN.md § Testing Strategy - Performance Testing
    - **Action:**
        1. Measure the execution time of the `ruby tools/validate_front_matter.rb` script on the entire repository.
    - **Done‑when:**
        1. The execution time is measured and confirmed to be under the 5-second target.
        2. If over target, a new issue is created to investigate optimization.
    - **Verification:**
        1. Run `time ruby tools/validate_front_matter.rb` and record the `real` time output.
    - **Depends‑on:** none

### Clarifications & Assumptions
- [x] **Issue:** Ruby Version Standardization
    - **Context:** Open Questions for Resolution #1
    - **Blocking?:** no
    - **Resolution:** Per the plan's recommendation, the standard is flexible `Ruby 3.0+`. The CI workflow is pinned to `3.0` for consistency.

- [x] **Issue:** Pre-commit Hook Installation Automation
    - **Context:** Open Questions for Resolution #2
    - **Blocking?:** no
    - **Resolution:** Per the plan's recommendation, installation remains manual. Task T004 provides the required documentation.

- [x] **Issue:** CI Workflow Trigger Optimization
    - **Context:** Open Questions for Resolution #3
    - **Blocking?:** no
    - **Resolution:** Per the plan's recommendation, the CI triggers on all pushes and PRs to `main`/`master` for comprehensive coverage.

- [x] **Issue:** Error Reporting Enhancement
    - **Context:** Open Questions for Resolution #4
    - **Blocking?:** no
    - **Resolution:** Per the plan's recommendation, human-readable output is sufficient. No structured (JSON) output will be implemented.

- [x] **Issue:** Validation Scope Expansion
    - **Context:** Open Questions for Resolution #5
    - **Blocking?:** no
    - **Resolution:** Per the plan's recommendation, the scope is limited to YAML front-matter only.
