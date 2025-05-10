# Todo: Natural Language Rewrite of Tenets and Bindings

## Phase 1: Framework, Templates & Prototypes

- \[x\] **T001 · Feature · P1: create natural language tenet template**
  - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template
    Documents
  - **Action:**
    1. Create `docs/templates/tenet_template.md` adhering to the revised tenet structure
       (Front-Matter, Core Belief, Practical Guidelines, Warning Signs, Related Tenets).
  - **Done‑when:**
    1. Template file exists and matches the structure defined in PLAN.md.
    1. Template includes placeholders and explanatory comments for each section.
  - **Verification:**
    1. Manually inspect template against PLAN.md structure.
  - **Depends‑on:** none
- \[x\] **T002 · Feature · P1: create natural language binding template**
  - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template
    Documents
  - **Action:**
    1. Create `docs/templates/binding_template.md` adhering to the revised binding
       structure (Front-Matter, Rationale, Rule Definition, Practical Implementation,
       Examples, Related Bindings).
  - **Done‑when:**
    1. Template file exists and matches the structure defined in PLAN.md.
    1. Template includes placeholders and explanatory comments for each section.
  - **Verification:**
    1. Manually inspect template against PLAN.md structure.
  - **Depends‑on:** none
- \[x\] **T003 · Feature · P1: document style guide for natural language approach**
  - **Context:** PLAN.md > Phase 1: Framework and Templates > 1. Create Template
    Documents & Natural Language Guidelines
  - **Action:**
    1. Create `docs/STYLE_GUIDE_NATURAL_LANGUAGE.md` detailing conversational tone,
       principle-first approach, context/connections, and narrative structure.
    1. Include examples of preferred phrasing and anti-patterns.
  - **Done‑when:**
    1. Style guide exists and covers all guidelines from PLAN.md.
    1. Style guide is reviewed for clarity.
  - **Verification:**
    1. Peer review style guide against PLAN.md guidelines.
  - **Depends‑on:** none

\[... other completed tasks ...\]

## CI Fixes

- \[x\] **T056 · Chore · P0: Fix markdown-link-check installation in CI**

  - **Context:** CI failing due to incorrect package manager for markdown-link-check
  - **Action:**
    1. Update `.github/workflows/ci.yml` to install Node.js
    1. Change pip install to npm install for markdown-link-check
    1. Ensure the tool is properly executed in the workflow
  - **Done‑when:**
    1. CI workflow installs markdown-link-check using npm
    1. Lint-docs job passes successfully
  - **Verification:**
    1. CI run shows successful installation and execution
  - **Depends‑on:** none

- \[x\] **T057 · Chore · P0: Restructure project for proper documentation organization**

  - **Context:** Project structure should align with its purpose as a documentation
    project
  - **Action:**
    1. ✅ Move `/tenets/` directory to `/docs/tenets/`
    1. ✅ Move `/bindings/` directory to `/docs/bindings/`
    1. ✅ Copy CONTRIBUTING.md to docs or reference it properly
    1. ✅ Update mkdocs.yml to reference the new paths with detailed navigation
  - **Done‑when:**
    1. ✅ All tenets and bindings are contained within the docs directory
    1. ⏳ All internal links work correctly with the new structure (will be addressed in
       T058)
  - **Verification:**
    1. ✅ Run mkdocs build locally to verify structure works
    1. ⏳ Check that all cross-references work in the generated site (will be addressed
       in T058)
  - **Depends‑on:** none

- \[x\] **T058 · Chore · P0: Update all cross-references for new document paths**

  - **Context:** Moving files will break existing references between documents
  - **Action:**
    1. Update all references between tenets and bindings to use the new paths
    1. Fix any relative links in the index files
    1. Update links in any examples or documentation
  - **Done‑when:**
    1. All cross-references use the new path structure
    1. No broken links are present in the documentation
  - **Verification:**
    1. Run markdown-link-check or similar to find any broken links
    1. Manually review key documents for correct references
  - **Depends‑on:** \[T057\]

- \[x\] **T059 · Test · P0: Verify clean project build and documentation**

  - **Context:** Ensure restructured project works correctly
  - **Action:**
    1. Run all validation tools on the restructured project
    1. Ensure MkDocs builds successfully in strict mode
    1. Test documentation site navigation and links
  - **Done‑when:**
    1. All validation tools pass without errors
    1. MkDocs builds without warnings in strict mode
    1. Documentation site functions correctly
  - **Verification:**
    1. Run validation tools locally
    1. Run mkdocs build --strict and view the generated site
  - **Depends‑on:** \[T056, T057, T058\]

- \[x\] **T060 · Fix · P0: Fix broken links causing MkDocs build failure**

  - **Context:** CI deploy job fails in strict mode due to invalid links in index.md
  - **Action:**
    1. Fix relative links in index.md that use the ./docs/ prefix
    1. Update link to examples/github-workflows/language-specific-sync.yml
    1. Verify all links are using correct paths in the docs structure
  - **Done‑when:**
    1. All links in index.md correctly point to their targets
    1. MkDocs builds without warnings in strict mode
  - **Verification:**
    1. Run mkdocs build --strict locally to verify no warnings
    1. Run CI checks to verify successful build
  - **Depends‑on:** none

- \[x\] **T061 · Fix · P0: Apply consistent markdown formatting**

  - **Context:** CI lint-docs job fails due to inconsistent markdown formatting
  - **Action:**
    1. Install mdformat locally
    1. Run mdformat on all markdown files
    1. Commit the formatting changes
  - **Done‑when:**
    1. All markdown files pass the CI formatting check
  - **Verification:**
    1. Run local formatting check: mdformat --check .
    1. Run CI checks to verify successful lint-docs job
  - **Depends‑on:** none

- \[x\] **T062 · Chore · P1: Add markdown formatting pre-commit hook**

  - **Context:** Prevent future formatting inconsistencies
  - **Action:**
    1. Update the pre-commit configuration to include mdformat
    1. Add documentation about markdown formatting requirements
    1. Update CONTRIBUTING.md to mention formatting requirements
  - **Done‑when:**
    1. Pre-commit hook is configured to run mdformat
    1. Documentation is updated with formatting guidance
  - **Verification:**
    1. Make a change to a markdown file and verify pre-commit hook runs
    1. Verify updated documentation is clear about formatting requirements
  - **Depends‑on:** \[T061\]

## Phase 2: Tenet Rewrites

- \[x\] **T063 · Feature · P1: Rewrite simplicity tenet in natural language format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/simplicity.md` to use proper YAML front-matter format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T064 · Feature · P1: Rewrite modularity tenet in natural language format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/modularity.md` to use proper YAML front-matter format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T065 · Feature · P1: Rewrite testability tenet in natural language format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/testability.md` to use proper YAML front-matter format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T066 · Feature · P1: Rewrite explicit-over-implicit tenet in natural language
  format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/explicit-over-implicit.md` to use proper YAML front-matter
       format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T067 · Feature · P1: Rewrite document-decisions tenet in natural language
  format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/document-decisions.md` to ensure correct front-matter format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T068 · Feature · P1: Rewrite maintainability tenet in natural language
  format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/maintainability.md` to ensure correct front-matter format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T069 · Feature · P1: Rewrite no-secret-suppression tenet in natural language
  format**

  - **Context:** PLAN.md > Phase 2: Tenet Rewrites > 1. Rewrite Core Tenets
  - **Action:**
    1. Update `docs/tenets/no-secret-suppression.md` to ensure correct front-matter
       format
    1. Ensure content follows natural language style guide
    1. Validate content with validation tools
  - **Done‑when:**
    1. Tenet document passes validation
    1. Content follows natural language approach
    1. Tenet appears correctly in index
  - **Verification:**
    1. Run validation tools to verify format
    1. Review content against style guide
  - **Depends‑on:** \[T001, T003\]

- \[x\] **T070 · Chore · P1: Document and standardize front-matter format**

  - **Context:** Consistently format tenet and binding front-matter
  - **Action:**
    1. Document the standard format for metadata in tenets and bindings
    1. Update any non-conforming files to match the standard format
    1. Create TENET_FORMATTING.md to document the standard approach
  - **Done‑when:**
    1. Consistent front-matter format is documented
    1. All tenet files use the standardized format
    1. Documentation clearly explains the format and rationale
  - **Verification:**
    1. Check that documentation matches actual file formatting
    1. Verify files pass validation tools
  - **Depends‑on:** none

- \[x\] **T071 · Chore · P1: Fix validation for remaining tenets**

  - **Context:** Some tenet files are failing validation
  - **Action:**
    1. Run validation tools to identify all failing tenets
    1. Fix validation errors across all tenet files
    1. Ensure consistent front-matter format across all files
  - **Done‑when:**
    1. All tenet files pass validation tools
    1. Front-matter is consistently formatted
    1. Index files are correctly generated
  - **Verification:**
    1. Run validation tools on all tenet files
    1. Verify all files appear correctly in the index
  - **Depends‑on:** \[T070\]

## Front-Matter Standardization

- \[x\] **T072 · Fix · P0: Configure mdformat to preserve YAML front-matter**

  - **Context:** mdformat pre-commit hook converts YAML front-matter to horizontal rule
    format
  - **Action:**
    1. Update `.mdformat.toml` to properly configure front-matter preservation
    1. Test configuration with sample files to verify front-matter remains intact
    1. Document the configuration in code comments
  - **Done‑when:**
    1. mdformat no longer converts YAML front-matter to horizontal rule format
    1. Configuration file is properly documented
  - **Verification:**
    1. Run mdformat manually on a test file with YAML front-matter
    1. Verify front-matter remains in YAML format after formatting
  - **Depends‑on:** none

## CI Fixes (May 2025)

- \[x\] **T082 · Fix · P0: Apply mdformat to all markdown files**

  - **Context:** CI lint-docs job fails due to inconsistent markdown formatting across
    49 files
  - **Action:**
    1. Install mdformat locally with front-matter support:
       `pip install mdformat mdformat-frontmatter`
    1. Format all markdown files: `mdformat --wrap 88 .`
    1. Verify formatting has been applied correctly
  - **Done‑when:**
    1. All markdown files have consistent formatting
    1. mdformat runs without errors
  - **Verification:**
    1. Run `mdformat --check .` to confirm no formatting issues remain
  - **Depends‑on:** none

- \[x\] **T083 · Fix · P0: Update tenet_template.md with proper YAML front-matter
  comments**

  - **Context:** The template file has explanatory comments mixed into YAML which breaks
    validation
  - **Action:**
    1. Update the tenet_template.md file to place explanatory comments outside the YAML
       front-matter section
    1. Use proper YAML syntax for all front-matter fields
    1. Ensure the template demonstrates the correct format for others to follow
  - **Done‑when:**
    1. Template file has valid YAML front-matter
    1. Explanatory comments appear outside the YAML block
  - **Verification:**
    1. Run validation tool to verify the template passes front-matter validation
  - **Depends‑on:** none

- \[x\] **T084 · Fix · P0: Ensure tenets index file is properly formatted**

  - **Context:** The docs/tenets/00-index.md file appears to have formatting issues
  - **Action:**
    1. Check the format of docs/tenets/00-index.md
    1. Apply proper markdown formatting to the file
    1. Ensure any links in the index file are correctly formatted
  - **Done‑when:**
    1. Index file passes the formatting check
    1. All links in the index file work correctly
  - **Verification:**
    1. Run mdformat check on the index file
    1. Run markdown-link-check to verify links
  - **Depends‑on:** none

- \[x\] **T085 · Test · P0: Run full CI validation locally**

  - **Context:** Need to verify all fixes will pass the CI before pushing changes
  - **Action:**
    1. Run mdformat check on all files: `mdformat --check .`
    1. Run markdown link validation: `markdown-link-check -q -c ./.mlc-config '**/*.md'`
    1. Run mkdocs build to verify site generation: `mkdocs build --strict`
  - **Done‑when:**
    1. All validation tools pass without errors
    1. Site builds successfully without warnings
  - **Verification:**
    1. All tests run without errors
  - **Depends‑on:** \[T082, T083, T084\]

- \[x\] **T073 · Fix · P0: Update pre-commit configuration for front-matter support**

  - **Context:** pre-commit hooks need to be configured to respect YAML front-matter
  - **Action:**
    1. Update `.pre-commit-config.yaml` to ensure mdformat properly handles front-matter
    1. Add necessary dependencies for mdformat-frontmatter
    1. Test pre-commit hook with sample files
  - **Done‑when:**
    1. Pre-commit hooks run without converting YAML front-matter
    1. Configuration includes proper dependencies for front-matter support
  - **Verification:**
    1. Make changes to a file with YAML front-matter
    1. Run pre-commit hooks and verify format remains intact
  - **Depends‑on:** \[T072\]

- \[x\] **T074 · Fix · P1: Update validate_front_matter.rb to enforce YAML standard**

  - **Context:** Validation tool needs to consistently enforce YAML front-matter
  - **Action:**
    1. Review `validate_front_matter.rb` to ensure it properly enforces YAML format
    1. Update any code that might accept alternative formats
    1. Improve error messages to be clear about expected YAML format
  - **Done‑when:**
    1. Validation tool consistently requires YAML front-matter
    1. Error messages clearly indicate the expected format
  - **Verification:**
    1. Run validation tool on files with different formats
    1. Verify it correctly identifies non-YAML formats as errors
  - **Depends‑on:** none

- \[x\] **T075 · Chore · P1: Document standardized front-matter format**

  - **Context:** Consistent documentation needed for front-matter standards
  - **Action:**
    1. Update `TENET_FORMATTING.md` to clearly document YAML front-matter as the
       standard
    1. Include examples of correct format
    1. Add explanation of required metadata fields
    1. Include troubleshooting section for common issues
  - **Done‑when:**
    1. Documentation clearly establishes YAML front-matter as the standard
    1. Examples and requirements are comprehensive
  - **Verification:**
    1. Review documentation for clarity and completeness
    1. Ensure all required metadata fields are documented
  - **Depends‑on:** none

- \[x\] **T076 · Chore · P1: Update templates to use standardized YAML front-matter**

  - **Context:** Templates should use the standardized format for new content
  - **Action:**
    1. Update `docs/templates/tenet_template.md` to use YAML front-matter
    1. Update `docs/templates/binding_template.md` to use YAML front-matter
    1. Ensure all required fields are included in templates
  - **Done‑when:**
    1. Templates use standard YAML front-matter
    1. Templates include all required metadata fields
  - **Verification:**
    1. Verify templates pass validation tools
    1. Check that templates are properly documented
  - **Depends‑on:** \[T075\]

- \[x\] **T077 · Feature · P1: Update CONTRIBUTING.md with front-matter guidance**

  - **Context:** Contributors need clear guidance on front-matter standards
  - **Action:**
    1. Update `CONTRIBUTING.md` to reference the standardized front-matter format
    1. Add section on metadata requirements for new content
    1. Link to `TENET_FORMATTING.md` for detailed guidance
  - **Done‑when:**
    1. Contribution guidelines clearly reference YAML front-matter standard
    1. Guidelines provide sufficient guidance for contributors
  - **Verification:**
    1. Review updated guidelines for clarity
    1. Ensure all links are functional
  - **Depends‑on:** \[T075\]

- \[x\] **T078 · Feature · P2: Convert all tenet files to standardized format**

  - **Context:** All tenet files need to use the standardized YAML front-matter
  - **Action:**
    1. Identify all tenet files still using horizontal rule format
    1. Convert each file to use YAML front-matter
    1. Preserve all metadata during conversion
    1. Validate each file after conversion
  - **Done‑when:**
    1. All tenet files use YAML front-matter
    1. All files pass validation tools
  - **Verification:**
    1. Run validation tools on all tenet files
    1. Verify index generation works correctly
  - **Depends‑on:** \[T072, T073, T074, T075\]

- \[x\] **T079 · Feature · P2: Convert all binding files to standardized format**

  - **Context:** All binding files need to use the standardized YAML front-matter
  - **Action:**
    1. Identify all binding files still using horizontal rule format
    1. Convert each file to use YAML front-matter
    1. Preserve all metadata during conversion
    1. Validate each file after conversion
  - **Done‑when:**
    1. All binding files use YAML front-matter
    1. All files pass validation tools
  - **Verification:**
    1. Run validation tools on all binding files
    1. Verify index generation works correctly
  - **Depends‑on:** \[T072, T073, T074, T075\]

- \[x\] **T080 · Test · P1: Verify complete toolchain with standardized format**

  - **Context:** Final verification that all tools work with the standardized format
  - **Action:**
    1. Run validation tools on all tenets and bindings
    1. Generate indexes and verify correctness
    1. Run pre-commit hooks on sample changes to verify format preservation
    1. Run a complete build of the documentation site
  - **Done‑when:**
    1. All validation tools pass without errors
    1. Index generation works correctly
    1. Pre-commit hooks preserve YAML front-matter
    1. Documentation site builds correctly
  - **Verification:**
    1. Complete end-to-end testing of all toolchain components
    1. Verify no formatting issues are introduced during the process
  - **Depends‑on:** \[T078, T079\]

- \[x\] **T081 · Chore · P0: Remove duplicated top-level tenets and bindings
  directories**

  - **Context:** Task T057 moved tenets/ and bindings/ to docs/tenets/ and
    docs/bindings/, but the original directories still exist
  - **Action:**
    1. Verify that all content from top-level directories has been properly moved to
       docs/
    1. Check that all references have been updated to use the new paths
    1. Remove the top-level tenets/ and bindings/ directories
    1. Update any remaining references to the old paths
  - **Done‑when:**
    1. Top-level tenets/ and bindings/ directories no longer exist
    1. All references point to docs/tenets/ and docs/bindings/
    1. Documentation site builds correctly without errors
  - **Verification:**
    1. Run mkdocs build to verify no broken links
    1. Run markdown-link-check to find any lingering references to old paths
    1. Ensure no functionality is broken by the directory removal
  - **Depends‑on:** \[T057, T058\]
