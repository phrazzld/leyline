# Plan: Reorganize Leyline Documentation Structure

## Chosen Approach (One‑liner)

Restructure Leyline bindings into an explicit, directory-based organization (core, category-specific), remove the `applies_to` front-matter field from bindings, and update workflows for explicit category selection via a single input, thereby simplifying filtering and maintenance.

## Architecture Blueprint

-   **Modules / Packages**
    -   `docs/tenets/`: Contains tenet markdown files. Structure remains unchanged.
    -   `docs/bindings/core/`: Contains core bindings applicable to all projects. These are always synced.
    -   `docs/bindings/categories/<category>/`: Contains category-specific bindings (e.g., `docs/bindings/categories/go/`, `docs/bindings/categories/rust/`, `docs/bindings/categories/typescript/`, `docs/bindings/categories/cli/`, `docs/bindings/categories/frontend/`).
    -   `tools/reindex.rb`: Script responsible for generating `docs/bindings/00-index.md`.
    -   `tools/validate_front_matter.rb`: Script responsible for validating document front matter (will no longer check `applies_to` for bindings).
    -   `.github/workflows/vendor.yml`: Reusable GitHub Actions workflow for consumers to sync documentation.
    -   `.github/workflows/ci.yml`: Main Leyline repository CI workflow.

-   **Public Interfaces / Contracts**
    -   **Binding File Front Matter:**
        ```yaml
        ---
        id: unique-binding-id # (matches filename without .md)
        last_modified: 'YYYY-MM-DD'
        derived_from: tenet-id # ID of the tenet this binding is derived from
        enforced_by: # Description of how this binding is enforced (e.g., linter, code review, convention)
        # 'applies_to' field is REMOVED from bindings. Directory location is the sole source of truth.
        ---
        ```
    -   **Tenet File Front Matter:** (Remains unchanged)
        ```yaml
        ---
        id: unique-tenet-id # (matches filename without .md)
        last_modified: 'YYYY-MM-DD'
        ---
        ```
    -   **`.github/workflows/vendor.yml` Inputs:**
        ```yaml
        inputs:
          ref:
            description: 'Git ref (tag/branch) of Leyline to use.'
            required: true
          categories:
            description: 'Comma-separated list of categories to sync bindings for (e.g., "go,rust,typescript,cli,frontend"). Leave empty for core bindings only.'
            required: false
            default: ''
        ```
        *Rationale*: Explicit input aligns with "Simplicity" and "Separation". Empty default means only `core/` bindings (and `tenets/`) are synced, providing a minimal base.

-   **Data Flow Diagram** (Mermaid)

    ```mermaid
    graph TD
        A[Leyline Repository: New Structure] -->|docs/*| B(Consuming Repo: Call vendor.yml);
        B -- Inputs: ref, categories --> C{vendor.yml Workflow Logic};
        C -->|Always| D[Checkout Leyline Repo @ ref];
        D -->|Always| E[Copy docs/tenets/* to Consumer];
        D -->|Always| F[Copy docs/bindings/core/* to Consumer];
        C -- For each category in 'categories' input --> G{Check if docs/bindings/categories/<category>/ exists};
        G -- Exists --> H[Copy docs/bindings/categories/<category>/* to Consumer];
        I[Consumer Repo: Cleanup old binding structure];
        E & F & H --> I;
        I --> J[Consumer Repo: Run reindex.rb];
        J --> K[Consumer Repo: docs/bindings/00-index.md updated];
        K --> L[Consumer Repo: Commit & Create/Update PR];
    ```

-   **Error & Edge‑Case Strategy**
    -   **Workflow `vendor.yml`:**
        -   If a specified category directory (from `categories` input) does not exist in the Leyline repo: Log a warning, skip that category, and continue.
        -   Invalid input format for `categories` (e.g., unexpected characters): Fail workflow with a clear error.
    -   **`reindex.rb`:**
        -   If a binding file is found directly under `docs/bindings/` (not in `core/` or `categories/*`): Log an error and skip the file, as it's misplaced.
        -   Gracefully handle empty category directories.
    -   **`validate_front_matter.rb`:**
        -   Will no longer validate `applies_to` for bindings.
        -   Continues to validate other required fields (id, last_modified, derived_from, enforced_by).
    -   **Cross-cutting bindings (applicable to multiple categories):**
        -   The primary mechanism is `docs/bindings/core/` for truly universal bindings.
        -   If a binding is specific to, e.g., "Rust for CLI development":
            1.  **Preferred:** Generalize the principle to fit `core/`.
            2.  Place in the primary category (e.g., `docs/bindings/categories/rust/`) and ensure the content makes its applicability clear, possibly with CLI examples.
            3.  Or place in `docs/bindings/categories/cli/` and ensure content makes its applicability clear, possibly with Rust examples.
        -   Avoid creating nested subdirectories like `categories/rust/cli/` to maintain simplicity. This forces clearer categorization or generalization. Duplication or symlinking of binding files is discouraged.

## Detailed Build Steps

1.  **Preparation & Communication:**
    1.  Create a new feature branch (e.g., `feature/doc-directory-restructure`).
    2.  Announce the upcoming breaking change and migration path to consumers via appropriate channels (e.g., README update, changelog, direct communication if feasible).

2.  **Directory Creation:**
    1.  In `docs/bindings/`, create the following base directories:
        -   `core/`
        -   `categories/`
    2.  Within `docs/bindings/categories/`, create initial category directories based on existing content (e.g., `go/`, `rust/`, `typescript/`, `cli/`, `frontend/`, `backend/`).

3.  **Move and Rename Bindings:**
    1.  For each existing binding `.md` file in `docs/bindings/`:
        -   Determine its primary category (core or specific category) based on its current `applies_to` field and content.
        -   Move the file to the corresponding new directory.
        -   Rename the file to remove any category prefix (e.g., `ts-no-any.md` becomes `docs/bindings/categories/typescript/no-any.md`). The `id` in the front matter must match this new filename.
    2.  Review bindings that applied to multiple specific categories. Apply the cross-cutting binding strategy (generalize to `core/` or place in the primary specific category).

4.  **Update Binding Front Matter:**
    1.  For all binding files in their new locations (`docs/bindings/**/*.md`):
        -   Remove the `applies_to` field entirely.
        -   Ensure the `id` field matches the new filename (without `.md` and path).
        -   Verify `last_modified`, `derived_from`, and `enforced_by` fields are present and correct.

5.  **Update Tooling - `reindex.rb`:**
    1.  Modify `tools/reindex.rb` to scan recursively within `docs/bindings/core/` and `docs/bindings/categories/*/`.
    2.  Ensure the generated `docs/bindings/00-index.md` includes clear sections for "Core" and each category.
    3.  Update links in the index to reflect the new relative paths (e.g., `[Binding Name](./categories/go/error-wrapping.md)`).

6.  **Update Tooling - `validate_front_matter.rb`:**
    1.  Modify `tools/validate_front_matter.rb` to:
        -   Stop expecting or validating the `applies_to` field in binding documents.
        -   Correctly locate and process binding files in their new nested subdirectories.
        -   Continue validating `id` (matching filename), `last_modified`, `derived_from`, and `enforced_by`.

7.  **Update Workflow - `.github/workflows/vendor.yml`:**
    1.  Add new `input`: `categories` (string, comma-separated, default `''`).
    2.  Modify workflow logic:
        -   Always sync `docs/tenets/`.
        -   Always sync `docs/bindings/core/`.
        -   Parse `inputs.categories`. For each specified category, if `docs/bindings/categories/<category>/` exists, sync its contents. Log a warning if a requested category directory doesn't exist.
        -   Implement a cleanup step in the consumer repository to remove any files/directories from the *previous* flat `docs/bindings/` structure before copying new files. This prevents stale files.
        -   Ensure the `reindex.rb` script is run in the consumer repository *after* all files are synced.
        -   Update the PR message generated by the workflow to list the categories of bindings that were synced.

8.  **Update Leyline CI - `.github/workflows/ci.yml`:**
    1.  Ensure `tools/validate_front_matter.rb --strict` is run.
    2.  Ensure `tools/reindex.rb` is run and that `docs/bindings/00-index.md` is up-to-date (fail CI if it needs changes and isn't committed).

9.  **Update Documentation:**
    1.  `README.md` / `docs/index.md`: Explain the new directory structure and how to use the updated `vendor.yml` with the `categories` input.
    2.  `CONTRIBUTING.md`: Guide contributors on where to place new bindings (based on directory structure) and the updated front matter requirements (no `applies_to`).
    3.  `docs/migration-guide.md`: Provide clear, step-by-step instructions for existing consumers to update their `vendor.yml` workflow call.
    4.  `docs/binding-metadata.md` (or `TENET_FORMATTING.md`): Reflect removal of `applies_to` and new directory-based categorization.
    5.  `mkdocs.yml`: Update the `nav` section to correctly point to all bindings in their new locations.
    6.  Review and update any other internal or external documentation referencing the old structure or `applies_to`.

10. **Testing:**
    1.  Manually run `tools/reindex.rb` and `tools/validate_front_matter.rb` locally.
    2.  Perform integration testing of the `vendor.yml` workflow using a test consumer repository, covering various combinations of `categories` inputs (including empty input). Verify correct file syncing, cleanup of old files, and index regeneration.

11. **Merge, Release, and Communicate:**
    1.  Merge the feature branch into the main branch.
    2.  Tag a new release (this is a breaking change for consumers, so likely a minor or major version bump, e.g., `vX.Y.0`).
    3.  Re-communicate the change, pointing to the new release and migration guide.

## Testing Strategy

-   **Unit Tests:**
    -   For `tools/reindex.rb`: Test index generation logic with mock directory structures representing various scenarios (core, different categories, empty dirs, files with correct/incorrect front matter for ID matching).
    -   For `tools/validate_front_matter.rb`: Test validation logic for binding and tenet front matter, especially the absence of `applies_to` in bindings and presence of other required fields.
    -   *Mocking*: Use temporary fixture directories and files for filesystem interactions.
-   **Integration Tests:**
    -   The primary integration test is the `vendor.yml` workflow.
    -   Create a dedicated test GitHub repository that calls the `vendor.yml` from the Leyline feature branch (or main branch after merge).
    -   Trigger this workflow with various `categories` inputs:
        -   No categories (syncs `tenets/`, `bindings/core/`).
        -   Specific categories (e.g., `"go,typescript"`).
        -   Multiple categories from different domains (e.g., `"go,frontend"`).
        -   Inputs requesting non-existent category directories.
    -   Verify:
        -   Correct set of files are synced to the test consumer repo.
        -   Old files/directories from the previous flat structure are removed.
        -   `docs/bindings/00-index.md` in the consumer repo is correctly regenerated.
        -   The PR created in the consumer repo is accurate.
-   **End-to-End (E2E) Tests:**
    -   A real consumer repository updating to the new Leyline version and successfully syncing documentation will serve as an E2E validation.
-   **Coverage Targets:**
    -   Tooling scripts (`reindex.rb`, `validate_front_matter.rb`): Aim for high unit test coverage (e.g., >80%) on critical logic.
-   **Edge Cases for Testing:**
    -   Empty `categories` input to `vendor.yml`.
    -   Filenames with special characters (though Markdown typically avoids this).
    -   Very large number of binding files.

## Risk Matrix

| Risk                                                                 | Severity | Mitigation                                                                                                                                                              |
| :------------------------------------------------------------------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Consumers' `vendor.yml` workflows break due to input/path changes.   | Critical | Comprehensive `docs/migration-guide.md`; clear versioning (new release for this breaking change); proactive communication.                                                |
| Flawed `vendor.yml` logic leads to incorrect file syncing or deletion. | High     | Thorough integration testing with a dedicated test consumer repository covering various input scenarios; careful code review of workflow changes.                         |
| `reindex.rb` fails to correctly index the new nested structure.        | High     | Robust unit tests for `reindex.rb` covering new paths and structure; manual verification of generated index on the feature branch; CI check for index consistency.       |
| Bindings miscategorized during manual file moving process.             | Medium   | Clear placement guidelines; careful, methodical execution of file moves; peer review of the PR containing file moves.                                                   |
| `mkdocs.yml` navigation breaks or becomes incorrect.                   | Medium   | Meticulous manual update of all binding paths in `mkdocs.yml`; local `mkdocs serve` and thorough site click-through before merging.                                       |
| Confusion for contributors on where to place new bindings.           | Medium   | Clear, concise documentation in `CONTRIBUTING.md` explaining the new directory structure and decision process for placement.                                                |
| Cross-cutting bindings are difficult to represent or discover.       | Medium   | Emphasize `core/` for universal principles. For specifics, guide towards placing in primary category and clarifying scope in content. This is a trade-off for simplicity. |

## Open Questions

-   **Strict validation of `categories` input values in `vendor.yml`?**
    -   *Decision*: For now, the workflow will attempt to use any string provided (e.g., `docs/bindings/categories/mycustom/`). If the directory doesn't exist in Leyline, it will warn and skip. This offers flexibility. Stricter validation against a predefined list could be added later if abuse or common typos become an issue.
-   **Handling of newly created category directories in Leyline:**
    -   *Clarification*: Consumers will only receive content for categories they explicitly request *and* that exist in the version of Leyline they are syncing. Adding a new category dir in Leyline doesn't automatically push it to consumers unless they update their workflow inputs.
