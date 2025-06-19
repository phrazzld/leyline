# CI Simplification TODO
*Streamline CI pipeline to serve documentation repository purpose*

## Problem Statement
Current CI pipeline applies production software engineering standards to a knowledge management repository, creating massive friction for documentation work and blocking valuable contributions over nitpicky issues that don't affect core repository value.

## Philosophy
CI should **enable** documentation work, not **hinder** it. Focus on essential quality gates that serve the repository's purpose while removing overengineered validation that creates friction without proportional value.

---

## Essential CI Validation (Keep)
> **Philosophy**: Validate what enables automation and basic quality

- [x] **E001 · Keep · P0: maintain YAML front-matter validation**
    - **Context:** YAML front-matter enables automation, indexing, and content management
    - **Current state:** Working correctly and serves clear purpose
    - **Action:** Keep `ruby tools/validate_front_matter.rb` in CI pipeline
    - **Rationale:** Essential for repository automation and content organization
    - **Done-when:** YAML validation remains in CI with no changes

- [x] **E002 · Keep · P0: maintain basic markdown syntax validation**
    - **Context:** Ensures documentation renders correctly across platforms
    - **Current state:** Handled by pre-commit hooks (check yaml, end-of-file-fixer)
    - **Action:** Keep existing pre-commit hook validation for basic syntax
    - **Rationale:** Prevents broken documentation rendering
    - **Done-when:** Pre-commit hooks remain active for basic syntax checks

- [x] **E003 · Keep · P1: maintain index consistency validation**
    - **Context:** Ensures generated indexes stay synchronized with content
    - **Current state:** Working correctly via `ruby tools/reindex.rb --strict`
    - **Action:** Keep index consistency check in CI pipeline
    - **Rationale:** Prevents navigation breakage in generated documentation
    - **Done-when:** Index validation remains in CI with no changes

---

## Overengineered Validation (Remove/Simplify)
> **Philosophy**: Remove friction that doesn't serve repository purpose

- [ ] **R001 · Remove · P0: eliminate blocking cross-reference validation**
    - **Context:** Currently blocks ALL PRs due to hundreds of pre-existing broken links
    - **Problem:** New work cannot proceed due to old, unrelated documentation debt
    - **Current behavior:** `ruby tools/validate_cross_references.rb` fails CI if ANY link is broken
    - **Action:** Remove cross-reference validation from CI pipeline entirely
    - **Rationale:** Link validation should be advisory, not blocking; broken links don't prevent knowledge transfer
    - **Alternative:** Convert to optional/advisory check in local tools only
    - **Done-when:** Cross-reference validation removed from CI, still available locally

- [ ] **R002 · Remove · P0: eliminate production-grade TypeScript binding validation**
    - **Context:** Extracts code snippets from docs and runs full TypeScript compilation
    - **Problem:** Documentation examples should teach concepts, not be production-ready
    - **Current behavior:** `ruby tools/validate_typescript_bindings.rb` treats educational examples like production code
    - **Action:** Remove TypeScript binding validation from CI pipeline entirely
    - **Rationale:** Educational examples prioritize clarity over compilation perfection
    - **Alternative:** Keep tool available for authors who want to test examples locally
    - **Done-when:** TypeScript binding validation removed from CI, still available locally

- [ ] **R003 · Remove · P0: eliminate security scanning of documentation examples**
    - **Context:** Enterprise-grade secret detection on educational examples
    - **Problem:** Educational "bad examples" need realistic patterns to be effective
    - **Current behavior:** Gitleaks scanning fails on examples that demonstrate what NOT to do
    - **Action:** Remove gitleaks security scanning from CI pipeline entirely
    - **Rationale:** Documentation repo doesn't contain actual secrets, only educational content
    - **Alternative:** Keep .gitleaksignore for local development but remove from CI
    - **Done-when:** Security scanning removed from CI pipeline

- [ ] **R004 · Remove · P1: eliminate dependency security auditing of example projects**
    - **Context:** Running `pnpm audit` on example/demo projects in documentation repo
    - **Problem:** Example projects are for education, not production deployment
    - **Current behavior:** CI fails if example projects have dependency vulnerabilities
    - **Action:** Remove pnpm audit checks from CI pipeline
    - **Rationale:** Educational examples don't need production-grade security auditing
    - **Alternative:** Document that examples are for learning, not production use
    - **Done-when:** Dependency auditing removed from CI for example projects

---

## CI Pipeline Simplification
> **Philosophy**: Fast feedback on essential quality gates only

- [ ] **S001 · Simplify · P0: update run_ci_checks.rb to essential-only mode**
    - **Context:** Current script runs all validation types, creating 60+ second feedback loops
    - **Problem:** Slow feedback discourages frequent validation during development
    - **Action:**
        1. Create `run_ci_checks.rb --essential` mode that runs only E001-E003
        2. Move R001-R004 validations to `--full` mode (local development only)
        3. Update CI to use `--essential` mode
    - **Expected time:** Essential mode should complete in <10 seconds
    - **Done-when:** CI uses essential-only validation, fast feedback loop established

- [ ] **S002 · Simplify · P0: update CI workflow to use essential validation only**
    - **Context:** Current CI workflow calls comprehensive validation
    - **Problem:** Long CI times block development velocity
    - **Action:**
        1. Update `.github/workflows/` to call `run_ci_checks.rb --essential`
        2. Remove individual validation steps that are now covered by essential mode
        3. Ensure CI completes in <2 minutes total
    - **Verification:** Create test PR to confirm fast CI execution
    - **Done-when:** CI workflow updated and verified to run essential checks only

- [ ] **S003 · Simplify · P1: update CLAUDE.md to reflect simplified CI**
    - **Context:** Current documentation promotes comprehensive local validation
    - **Problem:** Developers are encouraged to run slow, overengineered validation
    - **Action:**
        1. Update "CI Failure Prevention" section to recommend `--essential` for daily use
        2. Document `--full` mode as optional for authors who want comprehensive validation
        3. Update pre-push recommendations to use fast essential mode
    - **Focus:** Encourage frequent validation through fast feedback
    - **Done-when:** CLAUDE.md updated with simplified workflow recommendations

---

## Developer Experience Improvements
> **Philosophy**: Remove friction, enable flow

- [ ] **D001 · Improve · P1: create documentation authoring workflow guide**
    - **Context:** Simplified CI enables focus on documentation quality over technical perfection
    - **Action:**
        1. Create `docs/AUTHORING_WORKFLOW.md` focused on content creation
        2. Document when to use essential vs full validation
        3. Provide guidance on writing effective examples (clear over compilable)
        4. Include patterns for educational "bad examples" that won't trigger false positives
    - **Focus:** Enable authors to focus on knowledge transfer, not technical compliance
    - **Done-when:** Authoring guide created emphasizing content over technical perfection

- [ ] **D002 · Improve · P1: simplify pre-commit hooks to essential checks only**
    - **Context:** Current pre-commit hooks may include overengineered validation
    - **Action:**
        1. Audit `.pre-commit-config.yaml` for overengineered checks
        2. Keep only: trailing whitespace, end-of-file, YAML syntax, large files
        3. Remove any validation that duplicates removed CI checks
    - **Goal:** Fast pre-commit feedback that doesn't block commits
    - **Done-when:** Pre-commit hooks run in <5 seconds with essential checks only

- [ ] **D003 · Improve · P2: add advisory validation for interested authors**
    - **Context:** Some authors may want comprehensive validation for their work
    - **Action:**
        1. Create `run_advisory_checks.rb` script with all removed validations
        2. Document as optional tool for authors who want comprehensive feedback
        3. Ensure it's completely separate from required CI workflow
    - **Principle:** Available but not required, never blocks development
    - **Done-when:** Advisory validation available but not enforced

---

## Communication and Migration
> **Philosophy**: Clear communication about simplified approach

- [ ] **C001 · Communicate · P0: update CI failure prevention documentation**
    - **Context:** Current `docs/CI_FAILURE_PREVENTION.md` promotes overengineered approach
    - **Problem:** Documentation encourages practices we're moving away from
    - **Action:**
        1. Rewrite guide to focus on essential validation only
        2. Remove detailed troubleshooting for removed validation types
        3. Emphasize speed and developer flow over comprehensive checking
    - **Message:** CI should enable, not hinder documentation work
    - **Done-when:** Prevention guide updated to reflect simplified philosophy

- [ ] **C002 · Communicate · P1: create migration guide for existing contributors**
    - **Context:** Contributors may be accustomed to comprehensive validation
    - **Action:**
        1. Document what's changing and why (focus shift from software engineering to knowledge management)
        2. Explain when to use different validation levels
        3. Address concerns about "lowering standards" by clarifying appropriate standards for docs
    - **Key message:** Different repositories have different quality requirements
    - **Done-when:** Migration guide clarifies new approach and rationale

- [ ] **C003 · Communicate · P2: update repository README to reflect documentation focus**
    - **Context:** Repository may present itself as software project rather than knowledge repository
    - **Action:**
        1. Review README.md for overemphasis on technical sophistication
        2. Emphasize knowledge sharing and documentation quality over technical perfection
        3. Set appropriate expectations for contribution standards
    - **Goal:** Attract contributors interested in knowledge work, not just technical validation
    - **Done-when:** README reflects documentation repository purpose clearly

---

## Validation and Rollback Planning
> **Philosophy**: Measure impact, be ready to adjust

- [ ] **V001 · Validate · P0: measure CI performance improvement**
    - **Context:** Changes should demonstrably improve developer experience
    - **Action:**
        1. Baseline current CI execution time across recent PRs
        2. Measure new CI time after simplification
        3. Target: <2 minutes total CI time, <10 seconds essential validation
    - **Success criteria:** >75% reduction in CI execution time
    - **Done-when:** Performance improvement documented and verified

- [ ] **V002 · Validate · P1: monitor documentation quality after simplification**
    - **Context:** Ensure simplification doesn't degrade actual documentation quality
    - **Action:**
        1. Establish baseline metrics: broken internal links, YAML errors, basic syntax issues
        2. Monitor same metrics for 2 weeks after simplification
        3. Watch for any quality degradation in new content
    - **Acceptance criteria:** No increase in essential quality issues (YAML, syntax, basic structure)
    - **Done-when:** Quality monitoring shows no degradation in essential areas

- [ ] **V003 · Validate · P2: create rollback plan if simplification proves problematic**
    - **Context:** Major CI changes should be reversible if they cause unforeseen issues
    - **Action:**
        1. Document exact changes made for easy reversal
        2. Keep comprehensive validation tools available but unused
        3. Define criteria for rolling back (quality degradation, contributor concerns)
    - **Rollback triggers:** Significant increase in basic quality issues, major contributor objections
    - **Done-when:** Clear rollback procedure documented and tested

---

## Success Criteria

**Primary Goals:**
- CI execution time reduced from >60 seconds to <2 minutes
- Essential quality gates maintained (YAML, basic syntax, index consistency)
- Developer experience improved through fast feedback loops
- Documentation work no longer blocked by overengineered validation

**Quality Assurance:**
- No degradation in essential documentation quality
- Continued ability to validate comprehensively when desired (optional)
- Clear communication about appropriate standards for documentation repositories

**Philosophy Achievement:**
- CI enables rather than hinders documentation work
- Validation effort proportional to repository value and purpose
- Fast feedback encourages frequent validation and quality improvement
