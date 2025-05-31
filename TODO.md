# Todo

## CI Resolution: Fix MkDocs Infrastructure Removal Failures

### Workflow Cleanup
- [x] **T001 · Chore · P1: identify orphaned MkDocs workflow**
    - **Context:** CI Failure Resolution > Phase 1: Workflow Cleanup - critical blocker
    - **Action:**
        1. Search all files in `.github/workflows/` for MkDocs references: `grep -r "mkdocs" .github/workflows/`
        2. Search for "build-site" job definitions: `grep -r "build-site" .github/workflows/`
        3. Identify which workflow file contains `pip install mkdocs mkdocs-material` and `mkdocs build` commands
    - **Done‑when:**
        1. Specific workflow file causing build-site job failure identified
        2. File path and problematic sections documented
    - **Verification:**
        1. Review workflow file contents to confirm MkDocs build steps
        2. Cross-reference with CI failure logs to confirm match
    - **Depends‑on:** none

- [x] **T002 · Chore · P1: remove or update orphaned MkDocs workflow**
    - **Context:** CI Failure Resolution > Phase 1: Workflow Cleanup - eliminate CI blocker
    - **Action:**
        1. Evaluate if entire workflow should be removed or just MkDocs steps updated
        2. If workflow only contains MkDocs functionality: delete the file entirely
        3. If workflow contains other functionality: remove only MkDocs-related steps
        4. Ensure no other workflows reference the removed/updated workflow
    - **Done‑when:**
        1. No GitHub workflows contain MkDocs build commands
        2. build-site job no longer triggered by CI
    - **Verification:**
        1. Search all workflows for remaining MkDocs references: `grep -r "mkdocs" .github/workflows/`
        2. Verify search returns no results in workflow files
    - **Depends‑on:** [T001]

### Cross-Reference Resolution
- [x] **T003 · Fix · P2: resolve internal cross-reference links**
    - **Context:** CI Failure Resolution > Phase 2: Link Resolution - documentation quality
    - **Action:**
        1. Run cross-reference fixing tool: `ruby tools/fix_cross_references.rb`
        2. Review any files modified by the tool
        3. Manually check high-priority broken links identified in CI logs
        4. Fix any remaining broken internal references not resolved by tool
    - **Done‑when:**
        1. Cross-reference tool completes without errors
        2. Manual verification of critical internal links successful
        3. Significant reduction in Status: 400 link check errors
    - **Verification:**
        1. Run link checker locally if available
        2. Manually verify key cross-references resolve correctly
        3. Test binding-to-tenet and tenet-to-binding links
    - **Depends‑on:** [T002]

- [ ] **T004 · Fix · P3: update dead external links**
    - **Context:** CI Failure Resolution > Phase 2: Link Resolution - external reference cleanup
    - **Action:**
        1. Address GitHub discussions link returning 404: `https://github.com/phrazzld/leyline/discussions`
        2. Verify if discussions are disabled for the repository
        3. Either enable discussions or remove/update references to discussions
        4. Check for other dead external links in documentation
    - **Done‑when:**
        1. GitHub discussions link either works or is removed/updated
        2. No obvious dead external links remain in core documentation
    - **Verification:**
        1. Test discussions link functionality
        2. Review external link status in CI link checker results
    - **Depends‑on:** [T003]

### Final Validation
- [ ] **T005 · Test · P1: validate complete CI resolution**
    - **Context:** CI Failure Resolution > Phase 3: Validation - ensure complete fix
    - **Action:**
        1. Run all local validation tools: `ruby tools/validate_front_matter.rb`
        2. Run reindexing: `ruby tools/reindex.rb --strict`
        3. Commit all changes with conventional commit message
        4. Push changes and monitor CI status
        5. Verify all CI checks pass (4/4)
    - **Done‑when:**
        1. All local validation tools pass without errors
        2. CI shows all checks passing (build-site and lint-docs)
        3. PR ready for merge
    - **Verification:**
        1. Check CI status: `gh pr checks`
        2. Confirm no failing jobs
        3. Review CI logs for any remaining warnings
    - **Depends‑on:** [T004]

### Cleanup
- [ ] **T006 · Chore · P3: remove temporary CI analysis files**
    - **Context:** CI Failure Resolution > Cleanup - maintain repository cleanliness
    - **Action:**
        1. Delete `CI-FAILURE-SUMMARY.md`
        2. Delete `CI-RESOLUTION-PLAN.md`
        3. Update this TODO.md to mark all tasks complete
    - **Done‑when:**
        1. Temporary analysis files removed
        2. Repository clean of temporary CI resolution artifacts
    - **Verification:**
        1. Confirm files no longer exist in repository
        2. Check git status shows clean working directory
    - **Depends‑on:** [T005]

## Success Criteria

✅ **CI Resolution:**
- All GitHub Actions checks pass (4/4)
- No MkDocs references in CI workflows
- Internal cross-references resolve correctly
- Documentation system fully functional

✅ **Quality Assurance:**
- All validation tools pass locally
- Link checker shows minimal warnings
- Repository maintains LLM-first documentation approach
- No broken critical documentation paths
