# Todo

## MkDocs Infrastructure Removal

### Pre-Implementation Validation
- [x] **T001 · Test · P1: document current state and run baseline validation**
    - **Context:** Testing Strategy > Pre-Implementation - establish baseline before changes
    - **Action:**
        1. Document current state with `git status` and file listings
        2. Execute `ruby tools/validate_front_matter.rb` to establish baseline
        3. Execute `ruby tools/reindex.rb --strict` to generate baseline index
    - **Done‑when:**
        1. Current state documented for rollback reference
        2. All baseline validation tools pass without errors
        3. Baseline index generated successfully
    - **Verification:**
        1. Review validation output for any pre-existing issues
        2. Confirm baseline artifacts exist
    - **Depends‑on:** none

### Infrastructure File Removal
- [x] **T002 · Chore · P2: remove mkdocs.yml configuration file**
    - **Context:** Implementation Steps > Phase 1: File Removal
    - **Action:**
        1. Delete `/mkdocs.yml` from repository root
    - **Done‑when:**
        1. File no longer exists in repository
    - **Verification:**
        1. Confirm deletion with `git status`
        2. Verify file absence with `ls mkdocs.yml`
    - **Depends‑on:** [T001]

- [x] **T003 · Chore · P2: remove GitHub Pages deployment workflow**
    - **Context:** Implementation Steps > Phase 1: File Removal
    - **Action:**
        1. Delete `/.github/workflows/gh-pages.yml`
    - **Done‑when:**
        1. Workflow file no longer exists
        2. Automated GitHub Pages deployment disabled
    - **Verification:**
        1. Confirm deletion with `git status`
        2. Check GitHub Actions UI shows workflow removed
    - **Depends‑on:** [T001]

- [x] **T004 · Chore · P2: remove MkDocs setup documentation**
    - **Context:** Implementation Steps > Phase 1: File Removal
    - **Action:**
        1. Delete `/docs/gh-pages-setup.md`
    - **Done‑when:**
        1. Documentation file no longer exists
    - **Verification:**
        1. Confirm deletion with `git status`
        2. Verify file absence in docs directory
    - **Depends‑on:** [T001]

### Content Updates for LLM-First Approach
- [x] **T005 · Refactor · P1: update README.md for LLM-first approach**
    - **Context:** Implementation Steps > Phase 2: Content Updates - critical messaging update
    - **Action:**
        1. Remove all references to GitHub Pages site
        2. Add clear messaging about LLM-first documentation approach
        3. Emphasize GitHub repository browsing sufficiency
        4. Update documentation section to remove site references
    - **Done‑when:**
        1. README contains no GitHub Pages or MkDocs references
        2. README explicitly describes LLM-first approach and GitHub browsing sufficiency
    - **Verification:**
        1. Search README for `mkdocs`, `github.pages`, or site URLs
        2. Review for clear LLM-first messaging
    - **Depends‑on:** [T002, T003, T004]

- [x] **T006 · Refactor · P2: update TENET_FORMATTING.md references**
    - **Context:** Implementation Steps > Phase 2: Content Updates
    - **Action:**
        1. Remove MkDocs Meta-Data references from `/TENET_FORMATTING.md`
        2. Remove MkDocs Meta-Data references from `/docs/TENET_FORMATTING.md`
        3. Preserve Jekyll front-matter references as still relevant
    - **Done‑when:**
        1. Both files contain no MkDocs references
        2. Jekyll references remain intact for front-matter context
    - **Verification:**
        1. Search both files for "MkDocs" and confirm absence
        2. Verify Jekyll references are preserved
    - **Depends‑on:** [T005]

- [ ] **T007 · Refactor · P2: update automate-changelog.md binding**
    - **Context:** Implementation Steps > Phase 2: Content Updates
    - **Action:**
        1. Remove MkDocs-specific example from GitHub workflow section
        2. Replace with generic documentation build example
        3. Maintain the binding principle while removing MkDocs specificity
    - **Done‑when:**
        1. File contains generic documentation build example
        2. No MkDocs-specific language remains
    - **Verification:**
        1. Search file for "mkdocs" and confirm absence
        2. Review updated example for correctness and principle maintenance
    - **Depends‑on:** [T006]

### Comprehensive Validation
- [ ] **T008 · Test · P1: verify complete MkDocs removal**
    - **Context:** Implementation Steps > Phase 3: Validation - critical completeness check
    - **Action:**
        1. Execute `rg -i "mkdocs|github.pages"` across entire repository
        2. Review search results for any unintended references
        3. Address any remaining references not covered by previous tasks
    - **Done‑when:**
        1. Search returns zero relevant results in content files
        2. Any found references are intentional (e.g., in this TODO file)
    - **Verification:**
        1. Review search output carefully for false positives
        2. Confirm no content files contain unintended references
    - **Depends‑on:** [T007]

- [ ] **T009 · Test · P1: validate system integrity post-removal**
    - **Context:** Implementation Steps > Phase 3: Validation - ensure core functionality intact
    - **Action:**
        1. Execute `ruby tools/validate_front_matter.rb`
        2. Execute `ruby tools/reindex.rb --strict`
        3. Execute `ruby tools/fix_cross_references.rb` if needed
    - **Done‑when:**
        1. All validation tools pass without errors
        2. Reindexing completes successfully
        3. No broken cross-references remain
    - **Verification:**
        1. Check all command outputs for success messages
        2. Manually verify key documentation accessibility on GitHub
    - **Depends‑on:** [T008]

### Final Integration
- [ ] **T010 · Chore · P1: create conventional commit**
    - **Context:** Implementation Checklist - proper version control integration
    - **Action:**
        1. Stage all changes related to MkDocs infrastructure removal
        2. Create conventional commit with format: `chore: remove mkdocs infrastructure`
        3. Include descriptive body explaining LLM-first approach alignment
    - **Done‑when:**
        1. Single commit contains all changes with proper conventional message
        2. Commit body explains motivation and scope of changes
    - **Verification:**
        1. Run `git log -1` to verify commit message format
        2. Confirm all changes are included in commit
    - **Depends‑on:** [T009]

## Clarifications & Assumptions

### Non-Blocking Decisions
- [ ] **Issue: Virtual environment cleanup approach**
    - **Context:** Open Questions & Decisions > venv cleanup
    - **Decision:** Leave venv as-is to avoid affecting other dependencies
    - **Blocking?:** no

- [ ] **Issue: External GitHub Pages link handling**
    - **Context:** Open Questions & Decisions > Link replacement strategy
    - **Decision:** Update README to clarify repository browsing; external links will naturally break but content remains accessible
    - **Blocking?:** no

- [ ] **Issue: MkDocs configuration preservation**
    - **Context:** Open Questions & Decisions > Archive approach
    - **Decision:** Git history provides sufficient preservation; follows simplicity principle
    - **Blocking?:** no

## Success Criteria

✅ **Technical Completion:**
- All MkDocs infrastructure files removed
- Content updated for LLM-first approach
- All validation tools pass
- No broken internal references

✅ **Philosophy Alignment:**
- Simplicity: Reduced maintenance complexity
- Modularity: Decoupled documentation generation
- Testability: Validated via existing tool suite
- LLM-First: Clear messaging for primary consumers
