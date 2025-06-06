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

- [x] **T005 · Docs · P2: update README.md with development validation info**
    - **Context:** PLAN.md § Phase 1.2 Update Repository Documentation
    - **Action:**
        1. Add or update a "Development Setup" section in `README.md`.
        2. Briefly explain the automated validation process and link to `CONTRIBUTING.md` for full setup instructions.
    - **Done‑when:**
        1. `README.md` clearly communicates the existence of the validation process to new developers.
    - **Depends‑on:** [T004]

- [x] **T006 · Test · P1: test pre-commit hook with all error scenarios**
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
    - **Results:**
        ✅ Invalid YAML syntax: Successfully blocked
        ✅ Missing required fields: Successfully blocked
        ✅ Invalid field formats: Successfully blocked
        ⚠️  Duplicate IDs: Configuration gap discovered - Ruby script detects duplicates but pre-commit hook passes single files individually
        ✅ Missing tenet references: Successfully blocked
        ✅ Valid file acceptance: Successfully passes with automatic formatting fixes
    - **Depends‑on:** [T001]

- [x] **T007 · Test · P1: test CI workflow with all error scenarios**
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
    - **Results:**
        ✅ PR #31 created with validation errors (invalid YAML, duplicate IDs, missing fields)
        ✅ CI validate job failed with clear error messages identifying specific issues
        ✅ Fixed errors and pushed to same PR → CI validate job passed
        ✅ Cleaned up test files → CI validate job continued to pass
        ✅ Confirmed validation workflow correctly blocks invalid content and allows valid content
    - **Depends‑on:** [T002]

- [x] **T008 · Test · P2: benchmark validation script performance**
    - **Context:** PLAN.md § Testing Strategy - Performance Testing
    - **Action:**
        1. Measure the execution time of the `ruby tools/validate_front_matter.rb` script on the entire repository.
    - **Done‑when:**
        1. The execution time is measured and confirmed to be under the 5-second target.
        2. If over target, a new issue is created to investigate optimization.
    - **Verification:**
        1. Run `time ruby tools/validate_front_matter.rb` and record the `real` time output.
    - **Results:**
        ✅ Execution time: 0.397 seconds (real time)
        ✅ Target: Under 5 seconds → **PASSED** (10x faster than target)
        ✅ Performance is excellent - no optimization needed
        ✅ Script validates 12 tenets + 35 bindings in under 0.4 seconds
    - **Depends‑on:** none

### Code Review Remediation

- [x] **T009 · Fix · P1: remove manual edits to auto-generated index files**
    - **Context:** Code review identified critical functional issue
    - **Action:**
        1. Remove test artifacts that were manually added to auto-generated index files
        2. Regenerate clean index files using `ruby tools/reindex.rb`
        3. Commit only script-generated results
    - **Done‑when:**
        1. All test-related entries removed from `docs/bindings/00-index.md` and `docs/tenets/00-index.md`
        2. Index files contain only legitimate content entries
        3. Files maintain "automatically generated" integrity
    - **Results:**
        ✅ Test artifacts automatically removed by pre-commit automation
        ✅ Index files now contain only legitimate content entries
        ✅ "Automatically generated" integrity maintained
    - **Depends‑on:** none

- [x] **T010 · Fix · P1: correct pre-commit hook documentation**
    - **Context:** Philosophy violation - hooks documented as "recommended" vs "mandatory"
    - **Action:**
        1. Change "(Recommended)" to "(Mandatory)" in CONTRIBUTING.md for pre-commit hooks
        2. Align documentation with stated development philosophy
    - **Done‑when:**
        1. CONTRIBUTING.md reflects mandatory nature of pre-commit hooks
        2. Documentation aligns with `DEVELOPMENT_PHILOSOPHY.md` requirements
    - **Results:**
        ✅ Changed "Pre-commit Hooks (Recommended)" to "(Mandatory)" in CONTRIBUTING.md
        ✅ Updated language from "we recommend" to "you must" install hooks
        ✅ Documentation now aligns with DEVELOPMENT_PHILOSOPHY.md requirements
    - **Depends‑on:** none

### Future Enhancements (Convert to GitHub Issues)

- [x] **T011 · Enhancement · P2: harden CI dependency management**
    - **Context:** CI workflows should explicitly manage Ruby dependencies
    - **Action:** Create GitHub issue to investigate and implement explicit dependency management
    - **Done‑when:** GitHub issue created with detailed specification
    - **Results:** ✅ GitHub issue #33 created
    - **Depends‑on:** none

- [x] **T012 · Enhancement · P2: improve pre-commit duplicate ID detection**
    - **Context:** Current pre-commit hook validates files individually, missing cross-file duplicates
    - **Action:** Create GitHub issue to enhance pre-commit hook for comprehensive duplicate detection
    - **Done‑when:** GitHub issue created with technical approach outlined
    - **Results:** ✅ GitHub issue #34 created
    - **Depends‑on:** none

- [x] **T013 · Process · P3: define TODO.md lifecycle management**
    - **Context:** Establish process for archiving/retiring TODO.md to prevent documentation drift
    - **Action:** Create GitHub issue for TODO.md lifecycle planning
    - **Done‑when:** GitHub issue created with lifecycle process proposal
    - **Results:** ✅ GitHub issue #35 created
    - **Depends‑on:** none

- [x] **T014 · Enhancement · P3: enhance CI error reporting specificity**
    - **Context:** Make validation failure messages more explicit and actionable
    - **Action:** Create GitHub issue for improved error reporting in CI workflows
    - **Done‑when:** GitHub issue created with specific improvements identified
    - **Results:** ✅ GitHub issue #36 created
    - **Depends‑on:** none

- [x] **T015 · Docs · P3: standardize Ruby version documentation**
    - **Context:** Document expected Ruby version range for contributors
    - **Action:** Create GitHub issue for Ruby version standardization documentation
    - **Done‑when:** GitHub issue created with version compatibility requirements
    - **Results:** ✅ GitHub issue #37 created
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
