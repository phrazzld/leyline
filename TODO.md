# Todo: Metadata Format Elimination

## Prerequisite Verification & Backup
- [x] **T001 · Chore · P0: Verify migration completion and create backup**
    - **Context:** Prerequisite validation before removing legacy format support
    - **Action:**
        1. Confirm that `tools/metadata-migration/` has been successfully executed across all files
        2. Create a full backup of `docs/tenets/` and `docs/bindings/` directories
        3. Run `grep -rL '^---' docs/tenets/ docs/bindings/` to identify any files without YAML front-matter
        4. Manually spot-check ~12 diverse files to verify YAML format compliance
    - **Done‑when:**
        1. Backup is successfully created and verified
        2. No files without YAML front-matter are detected
    - **Verification:**
        1. Backup integrity checked by restoring a sample file
        2. `grep` command returns no file paths (no legacy files)
    - **Depends‑on:** none
    - **Notes:**
        - ⚠️ **MIGRATION INCOMPLETE** - All tenet files (9 files) still use legacy format
        - See detailed findings in `metadata-format-elimination-verification.md`
        - Additional migration step required before proceeding with T002

## Additional Task (Required)
- [x] **T001a · Chore · P0: Complete metadata migration for tenet files**
    - **Context:** Address incomplete migration discovered in T001
    - **Action:**
        1. Create a script or manually convert all tenet files from legacy horizontal rule format to YAML front-matter
        2. Preserve all existing metadata values during conversion
        3. Verify conversion success for all tenet files
    - **Done‑when:**
        1. All tenet files use YAML front-matter
        2. `grep -rL '^---' docs/tenets/ docs/bindings/` only returns index files
    - **Verification:**
        1. Manual inspection of converted files
        2. Running validation tool confirms success
    - **Depends‑on:** none

## Ruby Tool Refactoring

### Validate Front Matter Tool
- [x] **T002 · Refactor · P0: Remove legacy format logic from validate_front_matter.rb**
    - **Context:** Core tool refactoring for YAML-only validation
    - **Action:**
        1. Delete all code handling detection, parsing, or validation of legacy horizontal rule format
        2. Enforce that only YAML front-matter delimited by `---` is accepted
        3. Remove or repurpose the `--strict` flag if its primary purpose was YAML-only enforcement
    - **Done‑when:**
        1. All legacy format parsing code is completely removed
        2. Script enforces YAML-only validation
        3. `--strict` flag is removed or repurposed
    - **Verification:**
        1. Code review confirms removal of legacy parsing logic
        2. Running script against legacy format file produces explicit failure
    - **Depends‑on:** [T001, T001a]

- [x] **T003 · Refactor · P1: Implement strict YAML validation in validate_front_matter.rb**
    - **Context:** Ensure robust validation for YAML-only format
    - **Action:**
        1. Implement validation for required YAML keys (e.g., `id`, `last_modified`, `derived_from` for bindings)
        2. Validate correct data types/formats for known keys
        3. Use `YAML.safe_load` for secure YAML parsing
        4. Update error messages to be clear about YAML errors (malformed, missing keys, invalid values)
    - **Done‑when:**
        1. Script correctly validates compliant YAML structure and required fields
        2. Script fails appropriately for malformed YAML, missing front-matter, or missing required keys
        3. Safe YAML loading is implemented
    - **Verification:**
        1. Test with files: valid YAML, malformed YAML, missing front-matter, missing required keys
    - **Depends‑on:** [T002]

- [x] **T004 · Test · P1: Update tests for validate_front_matter.rb**
    - **Context:** Ensure test coverage for YAML-only functionality
    - **Action:**
        1. Remove unit tests specifically designed for legacy format validation
        2. Write unit tests for YAML parsing, required key validation, and error reporting
        3. Add tests explicitly verifying that detection of legacy format remnants causes failure
    - **Done‑when:**
        1. No unit tests for legacy format handling remain
        2. Test suite covers YAML validation and error paths
        3. Test coverage for refactored code meets target (>90%)
    - **Verification:**
        1. All tests pass and coverage targets are met
    - **Depends‑on:** [T003]

### Reindex Tool
- [x] **T005 · Refactor · P0: Remove legacy format parsing from reindex.rb**
    - **Context:** Core tool refactoring for YAML-only indexing
    - **Action:**
        1. Remove all code paths related to parsing metadata from the legacy horizontal rule format
        2. Modify script to exclusively use YAML parser (`YAML.safe_load`) for metadata extraction
        3. Simplify metadata extraction logic now that only one format is supported
    - **Done‑when:**
        1. Legacy metadata parsing logic is completely removed
        2. Script exclusively uses YAML parsing
        3. Metadata extraction logic is simplified
    - **Verification:**
        1. Code review confirms removal of legacy parsing logic
    - **Depends‑on:** [T001, T001a]

- [x] **T006 · Refactor · P1: Implement error handling in reindex.rb**
    - **Context:** Ensure robust handling of invalid files
    - **Action:**
        1. Implement behavior to fail loudly if a file cannot be parsed as valid YAML or lacks expected metadata
        2. Use `YAML.safe_load` for secure YAML parsing
        3. Add clear error messages indicating problematic files and issues
    - **Done‑when:**
        1. Script fails loudly on YAML parsing errors or missing required metadata
        2. Error messages clearly indicate the problematic file and nature of error
    - **Verification:**
        1. Test with valid YAML files, malformed YAML files, and files missing required metadata
    - **Depends‑on:** [T005]

- [x] **T007 · Test · P1: Update tests for reindex.rb**
    - **Context:** Ensure test coverage for YAML-only functionality
    - **Action:**
        1. Remove unit tests specifically designed for legacy format parsing
        2. Write unit tests for correct data extraction from YAML front-matter
        3. Add tests for handling of files with missing/malformed YAML
    - **Done‑when:**
        1. No unit tests for legacy format handling remain
        2. Test suite covers YAML parsing and error paths
        3. Test coverage for refactored code meets target (>90%)
    - **Verification:**
        1. All tests pass and coverage targets are met
    - **Depends‑on:** [T006]

### Cross-References Tool
- [x] **T008 · Chore · P2: Analyze fix_cross_references.rb for metadata parsing**
    - **Context:** Determine if additional refactoring is needed
    - **Action:**
        1. Investigate if `tools/fix_cross_references.rb` parses or relies on tenet/binding metadata structure
        2. Document findings regarding its metadata usage
    - **Done‑when:**
        1. Analysis is complete with clear determination if script uses metadata and how
    - **Depends‑on:** none

- [x] **T009 · Refactor · P2: Refactor fix_cross_references.rb for YAML-only (if applicable)**
    - **Context:** Conditional refactoring based on analysis
    - **Action:**
        1. If T008 found metadata usage, remove any legacy format parsing logic
        2. Update to rely exclusively on YAML front-matter
        3. Use `YAML.safe_load` for secure YAML parsing
    - **Done‑when:**
        1. If applicable, script is refactored to use YAML-only
        2. Legacy parsing logic is removed
    - **Verification:**
        1. If refactored, test with YAML-only files and verify correct operation
    - **Depends‑on:** [T008]

### Other Tooling
- [x] **T010 · Chore · P1: Search codebase for other legacy metadata parsing**
    - **Context:** Ensure comprehensive elimination of legacy format
    - **Action:**
        1. Perform comprehensive search (e.g., `git grep`, `rg`) for keywords like `horizontal_rule`, `____`, or patterns used for legacy parsing
        2. Document any identified scripts or code sections that handle tenet/binding metadata outside already refactored tools
    - **Done‑when:**
        1. Codebase search is completed
        2. Findings are documented with list of any other identified tooling
    - **Depends‑on:** [T001]

- [ ] **T011 · Refactor · P2: Refactor identified tooling for YAML-only**
    - **Context:** Conditional refactoring based on search
    - **Action:**
        1. For each tool identified in T010 that uses metadata:
           - Remove legacy format parsing logic
           - Update to support YAML-only metadata access
           - Use `YAML.safe_load` for secure YAML parsing
    - **Done‑when:**
        1. All identified tooling is refactored to use YAML-only
        2. Legacy parsing is removed from these tools
    - **Verification:**
        1. Test each refactored tool with YAML-only files and verify correct operation
    - **Depends‑on:** [T010]

## CI/CD and Pre-commit Integration
- [ ] **T012 · Chore · P0: Update CI workflows for YAML-only validation**
    - **Context:** Ensure automated builds enforce new standard
    - **Action:**
        1. Update relevant CI workflow files (`.github/workflows/`)
        2. Ensure CI jobs execute the refactored `validate_front_matter.rb` and `reindex.rb`
        3. Configure CI steps to fail the build if `validate_front_matter.rb` reports any errors
        4. Remove any CI steps or configurations related to legacy format
    - **Done‑when:**
        1. CI workflows are updated to run refactored tools
        2. CI builds fail on validation errors (including legacy format detection)
        3. Legacy-related CI configuration is removed
    - **Verification:**
        1. Test commit/PR with valid, invalid, and legacy format files to verify expected CI behavior
    - **Depends‑on:** [T003, T006]

- [ ] **T013 · Chore · P0: Update pre-commit hooks for YAML-only validation**
    - **Context:** Ensure local validation enforces new standard
    - **Action:**
        1. Update the `.pre-commit-config.yaml` file
        2. Ensure the pre-commit hook executes the refactored `validate_front_matter.rb`
        3. Verify hooks block commits with invalid YAML or legacy format
    - **Done‑when:**
        1. Pre-commit hook configuration is updated
        2. Hook blocks commits on validation errors
    - **Verification:**
        1. Attempt to commit files with legacy metadata, malformed YAML, and valid YAML
    - **Depends‑on:** [T003]

## Documentation Updates
- [ ] **T014 · Chore · P1: Update core documentation (TENET_FORMATTING, CONTRIBUTING)**
    - **Context:** Ensure documentation reflects YAML-only standard
    - **Action:**
        1. Rewrite `docs/TENET_FORMATTING.md`:
           - Remove all references to the horizontal rule format
           - State clearly that YAML front-matter is the sole and mandatory format
           - Provide clear examples of the required YAML structure and fields
           - Update or remove "Converting" sections
        2. Update `docs/CONTRIBUTING.md`:
           - Update front-matter standards to reflect YAML-only
           - Ensure validation instructions reflect updated tool behavior
    - **Done‑when:**
        1. Both documents are updated to reflect YAML-only standard
        2. All references to legacy format are removed
    - **Depends‑on:** [T003, T006]

- [ ] **T015 · Chore · P2: Update ancillary documentation (READMEs, CLAUDE.md, etc.)**
    - **Context:** Ensure consistent documentation across repository
    - **Action:**
        1. Review `README.md`, `CLAUDE.md`, any tool READMEs, and other relevant documentation
        2. Remove all references to dual formats or legacy format
        3. Ensure consistency regarding the YAML-only standard
    - **Done‑when:**
        1. All documentation is consistent with YAML-only standard
        2. No references to legacy format remain
    - **Depends‑on:** [T014]

## Repository Cleanup
- [ ] **T016 · Chore · P2: Repository cleanup (remove legacy fixtures/scripts)**
    - **Context:** Remove obsolete artifacts
    - **Action:**
        1. Identify and remove test fixtures, sample files, or utility scripts specific to legacy format
        2. Determine appropriate handling for `tools/metadata-migration/`:
           - Archive it (move to a separate branch or archive directory)
           - Delete it if no longer needed
           - Mark as deprecated/historical with clear documentation
    - **Done‑when:**
        1. Legacy test fixtures and utility scripts are removed
        2. Migration script is appropriately handled
    - **Verification:**
        1. Confirm no references to legacy format remain in repository
    - **Depends‑on:** [T004, T007, T009, T011]

## Communication
- [ ] **T017 · Chore · P1: Communicate change to contributors**
    - **Context:** Ensure awareness of breaking change
    - **Action:**
        1. Draft announcement about YAML-only metadata standard
        2. Highlight breaking nature for any manual processes or custom tooling
        3. Post announcement in relevant contributor channels
        4. Update `CHANGELOG.md`
    - **Done‑when:**
        1. Announcement is drafted and sent
        2. `CHANGELOG.md` is updated
    - **Depends‑on:** [T014, T015, T016]

## Issues Requiring Clarification
- [ ] **Issue:** Are there any external or undocumented consumers of tenet/binding files that might break?
    - **Context:** Risk assessment for breaking change
    - **Blocking?:** Yes - Potential significant impact if unknown consumers exist

- [ ] **Issue:** What are the precise required fields for YAML front-matter in tenets vs. bindings?
    - **Context:** Required for validation implementation
    - **Blocking?:** Yes - Required for T003 implementation

- [ ] **Issue:** Should reindex.rb halt entirely on a YAML parse error or continue after reporting?
    - **Context:** Error handling behavior
    - **Blocking?:** No - Can proceed with conservative approach (halt) and refine later
