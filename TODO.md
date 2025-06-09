# TODO: Semantic Versioning and Release Automation

## Critical Setup (Blocking - Must Complete First)

- [x] **T001 · Setup · P0: Create initial VERSION file and establish versioning policy**
    - **Context:** Starting version < 1.0.0, establish 0.1.0 as current
    - **Action:**
        1. Create `VERSION` file containing `0.1.0`
        2. Document versioning policy in `CONTRIBUTING.md`:
           - Pre-1.0: breaking changes increment minor (0.1.0 → 0.2.0)
           - Post-1.0: standard semver (breaking = major, features = minor, fixes = patch)
        3. Add note that 1.0.0 will mark stable API commitment
    - **Commands:**
        ```bash
        echo "0.1.0" > VERSION
        # Document policy in CONTRIBUTING.md
        ```
    - **Done-when:**
        1. `VERSION` file exists with `0.1.0`
        2. Versioning policy documented in `CONTRIBUTING.md`
    - **Depends-on:** none

- [x] **T002 · Setup · P0: Define breaking change detection rules**
    - **Context:** Required for automated version bump logic
    - **Action:**
        1. Document breaking change policy:
           - Removed/renamed tenet or binding files
           - Changes to YAML front-matter schema
           - Directory restructuring (moving categories)
           - Changes to binding metadata structure
        2. Create `tools/breaking_change_rules.yml` config file
        3. Add examples in `docs/DEVELOPMENT_PHILOSOPHY.md`
    - **Commands:**
        ```bash
        # Create breaking change config
        cat > tools/breaking_change_rules.yml << 'EOF'
        breaking_patterns:
          - "^docs/tenets/.+\.md$" # Deleted tenet files
          - "^docs/bindings/.+\.md$" # Deleted binding files
          - "^docs/bindings/categories/.+/.+\.md$" # Moved category files
        schema_changes:
          - "tools/validate_front_matter.rb" # Schema validation changes
        EOF
        ```
    - **Done-when:**
        1. Breaking change policy documented with examples
        2. `tools/breaking_change_rules.yml` exists
        3. Rules cover all identified breaking change scenarios
    - **Depends-on:** none

## Phase 1: Version Calculation Foundation

- [x] **T003 · Feature · P0: Build version calculation script (`tools/calculate_version.rb`)**
    - **Context:** Core engine for semantic version determination
    - **Action:**
        1. Create Ruby script that parses `git log --oneline` since last tag
        2. Analyze conventional commit prefixes: `feat:`, `fix:`, `BREAKING CHANGE:`
        3. Detect breaking changes using rules from T002
        4. Calculate next version (patch/minor for pre-1.0, full semver post-1.0)
        5. Output JSON: `{current_version, next_version, bump_type, commits, breaking_changes}`
    - **Commands:**
        ```bash
        # Create script skeleton
        cat > tools/calculate_version.rb << 'EOF'
        #!/usr/bin/env ruby
        require 'json'
        require 'yaml'
        # Implementation will parse git history and apply semantic versioning rules
        EOF
        chmod +x tools/calculate_version.rb
        ```
    - **Done-when:**
        1. Script runs: `ruby tools/calculate_version.rb` outputs valid JSON
        2. Correctly handles: no commits, no tags, mixed commit types
        3. Breaking change detection works with test commits
        4. Version bumps follow pre-1.0 rules (0.1.0 → 0.2.0 for breaking)
    - **Verification:**
        ```bash
        # Test with current repo
        ruby tools/calculate_version.rb
        # Should output JSON with current version 0.1.0
        ```
    - **Depends-on:** [T001, T002]

- [x] **T004 · Feature · P1: Add changelog generation to version calculator**
    - **Context:** Generate release notes from commit history
    - **Action:**
        1. Extend `tools/calculate_version.rb` to parse commit messages
        2. Categorize commits: Features (`feat:`), Fixes (`fix:`), Breaking (`BREAKING CHANGE:`)
        3. Generate markdown sections with commit links
        4. Add to JSON output: `changelog_markdown` field
    - **Commands:**
        ```bash
        # Test changelog generation
        ruby tools/calculate_version.rb --include-changelog
        ```
    - **Done-when:**
        1. JSON output includes `changelog_markdown` field
        2. Generated markdown has proper sections and GitHub commit links
        3. Breaking changes section highlights impact
    - **Verification:**
        ```bash
        # Generate changelog and inspect markdown
        ruby tools/calculate_version.rb | jq -r '.changelog_markdown'
        ```
    - **Depends-on:** [T003]

- [x] **T005 · Refactor · P1: Extend existing Ruby tools for version validation**
    - **Context:** Integrate version checking with current infrastructure
    - **Action:**
        1. Modify `tools/validate_front_matter.rb`:
           - Add `version` field validation to YAML schema
           - Ensure all docs have consistent version field
           - Fail if version doesn't match `VERSION` file
        2. Update `tools/reindex.rb`:
           - Include version metadata in generated indexes
           - Add version field to document metadata
    - **Commands:**
        ```bash
        # Test validation
        ruby tools/validate_front_matter.rb
        # Test reindexing
        ruby tools/reindex.rb
        ```
    - **Done-when:**
        1. `validate_front_matter.rb` checks version consistency
        2. `reindex.rb` includes version in output
        3. Version mismatches cause validation failures
    - **Verification:**
        ```bash
        # Test by temporarily changing a doc version
        # Validation should fail
        ruby tools/validate_front_matter.rb
        ```
    - **Depends-on:** [T003]

- [x] **T006 · Feature · P1: Create release preparation script (`tools/prepare_release.rb`)**
    - **Context:** Orchestrate all release preparation steps
    - **Action:**
        1. Create script that calls `calculate_version.rb` to get next version
        2. Update `VERSION` file with calculated version
        3. Run full validation suite: `validate_front_matter.rb`, `reindex.rb`
        4. Generate `CHANGELOG.md` entry from changelog markdown
        5. Exit with non-zero code if any step fails
    - **Commands:**
        ```bash
        cat > tools/prepare_release.rb << 'EOF'
        #!/usr/bin/env ruby
        # Orchestrates release preparation:
        # 1. Calculate next version
        # 2. Update VERSION file
        # 3. Run validations
        # 4. Update CHANGELOG.md
        EOF
        chmod +x tools/prepare_release.rb
        ```
    - **Done-when:**
        1. Script runs end-to-end: `ruby tools/prepare_release.rb`
        2. Updates `VERSION` file with next version
        3. Adds new entry to `CHANGELOG.md`
        4. Fails gracefully with clear error messages
    - **Verification:**
        ```bash
        # Run preparation in dry-run mode
        ruby tools/prepare_release.rb --dry-run
        ```
    - **Depends-on:** [T003, T004, T005]

## Phase 2: Release Automation Workflow

- [x] **T007 · Feature · P0: Create GitHub Actions release workflow**
    - **Context:** Fully automated release on merge to master
    - **Action:**
        1. Create `.github/workflows/release.yml`:
           - Trigger: push to master branch
           - Jobs: validate → prepare → tag → release → update-docs
           - Use `ruby tools/prepare_release.rb` for preparation
           - Create Git tag with calculated version
           - Create GitHub release with changelog
           - Commit updated docs back to master with `[skip ci]`
        2. Configure GitHub token permissions: `contents: write`, `actions: read`
    - **Commands:**
        ```bash
        mkdir -p .github/workflows
        cat > .github/workflows/release.yml << 'EOF'
        name: Release
        on:
          push:
            branches: [master]
        permissions:
          contents: write
          actions: read
        jobs:
          release:
            runs-on: ubuntu-latest
            steps:
              - uses: actions/checkout@v4
              - name: Setup Ruby
                uses: ruby/setup-ruby@v1
                with:
                  ruby-version: '3.1'
              - name: Prepare Release
                run: ruby tools/prepare_release.rb
              # Additional steps for tagging and GitHub release
        EOF
        ```
    - **Done-when:**
        1. Workflow file exists and is valid YAML
        2. Triggers on push to master
        3. Complete release cycle: prep → tag → release → commit
        4. Generated releases appear in GitHub with changelog
    - **Verification:**
        ```bash
        # Validate workflow YAML
        yamllint .github/workflows/release.yml
        # Test with a dummy commit to master
        ```
    - **Depends-on:** [T006]

- [x] **T008 · Feature · P1: Add release gates and validation**
    - **Context:** Prevent bad releases with comprehensive checks
    - **Action:**
        1. Add to release workflow:
           - Require existing CI checks to pass
           - Run `tools/validate_front_matter.rb` and `tools/reindex.rb`
           - Verify no breaking changes without appropriate version bump
           - Check for security vulnerabilities in scripts
        2. Configure branch protection rules requiring status checks
    - **Commands:**
        ```bash
        # Add validation job to workflow
        # Configure branch protection via GitHub settings or API
        ```
    - **Done-when:**
        1. Release fails if any CI check fails
        2. Breaking change detection blocks inappropriate version bumps
        3. All existing validation tools pass before release
        4. Branch protection enforces checks
    - **Verification:**
        ```bash
        # Intentionally break validation and confirm release blocks
        # Add invalid YAML to a doc and push
        ```
    - **Depends-on:** [T007]

## Phase 3: Consumer Support

- [x] **T009 · Feature · P2: Create consumer integration examples**
    - **Context:** Help consumers adopt and integrate effectively
    - **Action:**
        1. Create `examples/consumer-git-submodule/` with:
           - Sample repository using Leyline as Git submodule
           - GitHub Actions workflow showing integration
           - Documentation with version pinning examples
        2. Create `examples/consumer-direct-copy/` with:
           - Script to copy specific tenets/bindings
           - Version compatibility checking
        3. Add `examples/README.md` explaining integration patterns
    - **Commands:**
        ```bash
        mkdir -p examples/consumer-git-submodule
        mkdir -p examples/consumer-direct-copy
        # Create sample configurations and workflows
        ```
    - **Done-when:**
        1. Examples demonstrate common integration patterns
        2. Include working GitHub Actions workflows
        3. Show version pinning and update strategies
        4. Documentation explains when to use each pattern
    - **Verification:**
        ```bash
        # Test example workflows in isolation
        cd examples/consumer-git-submodule && .github/workflows/test.yml
        ```
    - **Depends-on:** [T007]

- [x] **T010 · Feature · P2: Create migration guide system**
    - **Context:** Support consumers through version upgrades
    - **Action:**
        1. Create `tools/generate_migration_guide.rb`:
           - Detect breaking changes between versions
           - Generate upgrade instructions with before/after examples
           - Create version compatibility matrix
        2. Integrate with `prepare_release.rb` to auto-generate guides
        3. Store guides in `docs/migration/v0.X-to-v0.Y.md`
    - **Commands:**
        ```bash
        mkdir -p docs/migration
        cat > tools/generate_migration_guide.rb << 'EOF'
        #!/usr/bin/env ruby
        # Generates migration guides for version upgrades
        EOF
        chmod +x tools/generate_migration_guide.rb
        ```
    - **Done-when:**
        1. Migration guides generated for breaking changes
        2. Include specific file changes and impact analysis
        3. Guides linked in GitHub release notes
        4. Version compatibility matrix updated automatically
    - **Verification:**
        ```bash
        # Test migration guide generation
        ruby tools/generate_migration_guide.rb --from=0.1.0 --to=0.2.0
        ```
    - **Depends-on:** [T006]

## Phase 4: Rollback and Safety

- [x] **T011 · Feature · P1: Create rollback automation**
    - **Context:** Safety net for failed releases
    - **Action:**
        1. Create `tools/rollback_release.rb`:
           - Delete Git tag and GitHub release
           - Revert `VERSION` file and `CHANGELOG.md`
           - Create rollback notification issue
        2. Add post-release validation to workflow:
           - Test consumer examples still work
           - Validate generated releases
           - Auto-trigger rollback on failures
    - **Commands:**
        ```bash
        cat > tools/rollback_release.rb << 'EOF'
        #!/usr/bin/env ruby
        require 'octokit'
        # Rolls back a failed release by version tag
        EOF
        chmod +x tools/rollback_release.rb
        ```
    - **Done-when:**
        1. Script can rollback any version: `ruby tools/rollback_release.rb v0.2.0`
        2. Post-release validation detects problems
        3. Auto-rollback triggers on validation failure
        4. Rollback notifications inform consumers
    - **Verification:**
        ```bash
        # Test rollback in development
        ruby tools/rollback_release.rb --dry-run v0.1.1
        ```
    - **Depends-on:** [T007]

## Phase 5: Testing and Hardening

- [x] **T012 · Test · P1: Create comprehensive test suite**
    - **Context:** Ensure system reliability and regression prevention
    - **Action:**
        1. Create `tools/test_calculate_version.rb`:
           - Unit tests for version calculation logic
           - Test fixtures with various commit scenarios
           - Edge cases: no tags, malformed commits, large histories
        2. Create `tools/test_release_workflow.rb`:
           - Integration tests for end-to-end release process
           - Mock GitHub API for testing
        3. Add to CI: `tools/run_all_tests.rb`
    - **Commands:**
        ```bash
        cat > tools/test_calculate_version.rb << 'EOF'
        #!/usr/bin/env ruby
        require 'test/unit'
        # Comprehensive tests for version calculation
        EOF
        chmod +x tools/test_calculate_version.rb
        ```
    - **Done-when:**
        1. All tests pass: `ruby tools/run_all_tests.rb`
        2. Test coverage > 90% for critical components
        3. Tests run in CI before any release
        4. Performance benchmarks for large repositories
    - **Verification:**
        ```bash
        # Run test suite
        ruby tools/run_all_tests.rb
        # Check coverage
        ruby tools/test_coverage_report.rb
        ```
    - **Depends-on:** [T003, T006, T007]

- [x] **T013 · Security · P1: Harden security and access controls**
    - **Context:** Protect release process from compromise
    - **Action:**
        1. Configure GitHub repository settings:
           - Branch protection rules for master
           - Require reviews for workflow changes
           - Restrict GitHub token permissions to minimum needed
        2. Add input validation to all Ruby scripts:
           - Sanitize commit messages in changelog generation
           - Validate version strings and Git references
           - Prevent injection attacks in shell commands
        3. Scan all scripts for security issues
    - **Commands:**
        ```bash
        # Configure branch protection
        gh api repos/:owner/:repo/branches/master/protection --method PUT --input protection.json
        # Add security scanning
        bundle audit
        ```
    - **Done-when:**
        1. Branch protection prevents direct pushes to master
        2. Workflow changes require review and approval
        3. All shell commands use proper escaping
        4. Security scanning passes in CI
    - **Verification:**
        ```bash
        # Test malicious commit messages
        # Verify they don't break changelog generation
        # Attempt direct push to master (should fail)
        ```
    - **Depends-on:** [T007]

## CI Fix Tasks (Critical - Blocking PR Merge)

- [x] **CI-001 · Fix · P0: Create automated migration script for adding version field**
    - **Context:** All tenets and bindings need version field in YAML front-matter
    - **Action:**
        1. Create `tools/add_version_to_metadata.rb` migration script
        2. Script should:
           - Read VERSION file to get current version
           - Find all .md files in docs/tenets/ and docs/bindings/
           - Parse YAML front-matter
           - Add `version: '0.1.0'` if missing
           - Preserve all other fields and formatting
        3. Handle edge cases: malformed YAML, existing version fields
    - **Commands:**
        ```bash
        ruby tools/add_version_to_metadata.rb --dry-run
        ruby tools/add_version_to_metadata.rb
        ```
    - **Done-when:**
        1. Migration script created and tested
        2. Handles all edge cases gracefully
        3. Dry-run mode shows what will be changed
    - **Depends-on:** none

- [x] **CI-002 · Fix · P0: Test migration script on single file**
    - **Context:** Verify script works correctly before bulk changes
    - **Action:**
        1. Backup a single tenet file
        2. Run migration on that file only
        3. Verify YAML is valid and content unchanged
        4. Check version field is correctly added
    - **Commands:**
        ```bash
        cp docs/tenets/simplicity.md docs/tenets/simplicity.md.bak
        ruby tools/add_version_to_metadata.rb -f docs/tenets/simplicity.md
        diff -u docs/tenets/simplicity.md.bak docs/tenets/simplicity.md
        ```
    - **Done-when:**
        1. Single file migration successful
        2. Only version field added, no other changes
        3. YAML remains valid
    - **Depends-on:** [CI-001]

- [x] **CI-003 · Fix · P0: Run migration on all tenet documents**
    - **Context:** Add version field to all 13 tenet files
    - **Action:**
        1. Run migration script on docs/tenets/
        2. Validate all files with validate_front_matter.rb
        3. Review git diff to ensure only version added
    - **Commands:**
        ```bash
        ruby tools/add_version_to_metadata.rb --path docs/tenets/
        ruby tools/validate_front_matter.rb -d docs/tenets/
        git diff docs/tenets/
        ```
    - **Done-when:**
        1. All 13 tenets have version field
        2. Validation passes for all tenets
        3. No content changes except version field
    - **Depends-on:** [CI-002]

- [x] **CI-004 · Fix · P0: Run migration on all binding documents**
    - **Context:** Add version field to all binding files
    - **Action:**
        1. Run migration script on docs/bindings/
        2. Validate all files with validate_front_matter.rb
        3. Review changes for correctness
    - **Commands:**
        ```bash
        ruby tools/add_version_to_metadata.rb --path docs/bindings/
        ruby tools/validate_front_matter.rb -d docs/bindings/
        git diff docs/bindings/
        ```
    - **Done-when:**
        1. All bindings have version field
        2. Validation passes for all bindings
        3. No unintended changes
    - **Depends-on:** [CI-002]

- [x] **CI-005 · Fix · P1: Update document templates with version field**
    - **Context:** Prevent future documents from missing version
    - **Action:**
        1. Update docs/templates/tenet_template.md
        2. Update docs/templates/binding_template.md
        3. Add version field with placeholder
    - **Commands:**
        ```bash
        # Edit templates to include:
        # version: '<CURRENT_VERSION>'
        ```
    - **Done-when:**
        1. Both templates include version field
        2. Clear instructions for version value
    - **Depends-on:** none

- [x] **CI-006 · Fix · P1: Document version field requirement**
    - **Context:** Ensure contributors know about this requirement
    - **Action:**
        1. Update CONTRIBUTING.md with version field requirement
        2. Update docs/TENET_FORMATTING.md if it exists
        3. Add example showing required fields
    - **Done-when:**
        1. Requirement clearly documented
        2. Examples show version field
        3. Explanation of why it's needed
    - **Depends-on:** none

- [ ] **CI-007 · Verify · P0: Run full local validation before push**
    - **Context:** Ensure all CI checks will pass
    - **Action:**
        1. Run full validation suite locally
        2. Run any pre-commit hooks
        3. Verify no errors or warnings
    - **Commands:**
        ```bash
        ruby tools/validate_front_matter.rb -v
        ruby tools/reindex.rb --strict
        pre-commit run --all-files
        ```
    - **Done-when:**
        1. All validation passes locally
        2. No errors or warnings
        3. Ready to commit and push
    - **Depends-on:** [CI-003, CI-004]

## Implementation Commands

### Quick Start
```bash
# 1. Create initial version
echo "0.1.0" > VERSION

# 2. Build version calculator
ruby tools/calculate_version.rb

# 3. Prepare first release
ruby tools/prepare_release.rb --dry-run

# 4. Test release workflow
git add . && git commit -m "feat: add semantic versioning system"
git push origin master
```

### Testing Commands
```bash
# Run all tests
ruby tools/run_all_tests.rb

# Test version calculation
ruby tools/test_calculate_version.rb

# Test release preparation
ruby tools/prepare_release.rb --dry-run

# Validate workflow
yamllint .github/workflows/release.yml
```

### Rollback Commands
```bash
# Emergency rollback
ruby tools/rollback_release.rb v0.2.0

# Check release status
ruby tools/check_release_health.rb

# Manual recovery
ruby tools/manual_recovery.rb --guide
```

## Critical Path Dependencies

**Blocking Path:** T001 → T002 → T003 → T006 → T007 → T008
**Parallel Development:** T004, T005 can run concurrent with T003
**Safety Features:** T011, T013 can start after T007
**Consumer Support:** T009, T010 can develop in parallel after T006

## Success Criteria

- [ ] **Automated releases work:** Push to master → release appears in < 5 minutes
- [ ] **Version calculation accurate:** Handles all commit patterns correctly
- [ ] **Consumer examples functional:** All examples in `examples/` work independently
- [ ] **Rollback tested:** Can safely revert any release
- [ ] **Security hardened:** No credentials in code, input validation complete
- [ ] **Tests comprehensive:** > 90% coverage, CI integration complete

## Key Decisions Made

✅ **Initial Version:** 0.1.0 (pre-stability, allows rapid iteration)
✅ **Breaking Changes:** File removal/rename, YAML schema changes, directory restructuring
✅ **Release Trigger:** Every merge to master (rapid feedback)
✅ **Consumer Notification:** GitHub releases + migration guides + working examples
✅ **Pre-1.0 Versioning:** Breaking changes increment minor version (0.1.0 → 0.2.0)
✅ **Post-1.0 Versioning:** Standard semver (breaking = major, features = minor, fixes = patch)

This TODO list is now completely actionable with concrete file paths, commands, and measurable completion criteria.
