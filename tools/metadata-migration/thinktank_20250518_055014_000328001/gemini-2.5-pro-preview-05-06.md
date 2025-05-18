## Chosen Approach
A systematic, module-by-module documentation process using TSDoc, enforced by linting, focusing on explaining the "why," making API contracts explicit, and covering all exported members and module-level purposes.

## Rationale
- **Simplicity:** The task is broken down into manageable units (per module), making a large documentation effort less daunting and easier to track.
- **Modularity + strict separation:** Processing modules individually, starting with foundational ones like `src/types.ts`, respects dependencies and aligns with modular design principles. Each module's documentation is a self-contained unit of work.
- **Coding standards:** Directly implements the project's coding standards by mandating TSDoc, focusing on the "Why" as per `DEVELOPMENT_PHILOSOPHY.md`, and using linters for enforcement.
- **Documentation approach:** This approach comprehensively addresses all specified requirements: adherence to TSDoc standards, documenting rationale, explicating API contracts, including examples, and thoroughly documenting all code constructs (modules, classes, interfaces, functions, types, parameters, return values, exceptions).
- **Maintainability:** Produces high-quality, consistent documentation that is invaluable for long-term maintenance and onboarding, directly supporting the "Maintainability Over Premature Optimization" principle by prioritizing human understanding.

## Build Steps
1.  **Configure TSDoc Linting:**
    *   Install `eslint-plugin-tsdoc`: `npm install eslint-plugin-tsdoc --save-dev` (or yarn/pnpm equivalent).
    *   Update ESLint configuration (`.eslintrc.js` or similar) to include the plugin and enable its recommended rules:
        ```json
        {
          "plugins": ["tsdoc"],
          "rules": {
            "tsdoc/syntax": "warn" // or "error" for stricter enforcement
          }
        }
        ```
    *   Create a `tsdoc.json` file in the project root if custom tag definitions or advanced validation is needed (refer to TSDoc documentation for schema). For this task, the default TSDoc tags should suffice.

2.  **Document Core Types (`src/types.ts`):**
    *   Begin with `src/types.ts` as these definitions are fundamental to other modules.
    *   For each exported `interface`, `enum`, and `type` alias:
        *   Add a TSDoc comment block directly above the declaration.
        *   **Summary:** Clearly explain its purpose, what kind of data it represents, and its role in the system (the "Why").
        *   **Interfaces:** Detail the contract it defines. For each property and method, add a description.
            *   Example for `FileContext`: `/** Represents a file being processed, encapsulating its path and content. Crucial for passing file information through the migration pipeline. */`
        *   **Enums:** Explain what the set of enumerated values represents. Document each enum member if its meaning isn't immediately obvious.
            *   Example for `MetadataFormat`: `/** Defines the recognized metadata formats within Markdown files, guiding the inspection and parsing logic. */`
        *   **Type Aliases:** Explain the structure and purpose of the alias, especially for complex union or intersection types.

3.  **Iterate and Document Each Module Systematically:**
    Process the following modules one by one. For modules whose code was not provided in the context (marked with *), apply the same documentation steps based on their inferred responsibilities or once their code is available:
    *   `src/logger.ts`
    *   `src/fileWalker.ts`
    *   `src/metadataInspector.ts`
    *   `src/legacyParser.ts`*
    *   `src/metadataConverter.ts`*
    *   `src/yamlSerializer.ts`*
    *   `src/fileRewriter.ts`
    *   `src/backupManager.ts`*
    *   `src/cliHandler.ts`
    *   `src/migrationEngine.ts`*
    *   `src/migrationOrchestrator.ts`
    *   `src/nodeFileSystemAdapter.ts`* (likely implements `IFileSystem` from `fileRewriter.ts`)

    For each module:
    *   **Module-Level Documentation:**
        *   Add a TSDoc comment block at the very top of the file (e.g., `/** @module metadataInspector */` followed by a descriptive summary).
        *   Explain the module's overall purpose, its primary responsibilities, and how it fits into the metadata migration tool's architecture.
        *   Example for `src/fileWalker.ts`: `/** @module fileWalker \n * Responsible for discovering Markdown files within specified directory paths. \n * It uses glob patterns for efficient recursive searching and provides a list of absolute file paths \n * to the MigrationOrchestrator. */`
    *   **Exported Members Documentation:** Review, enhance, or add TSDoc comments for all exported classes, functions, interfaces, and type aliases.
        *   **Classes:**
            *   **Summary:** Describe the class's role, responsibilities, and primary use cases.
            *   **Constructor:** Document with `@param` tags for each parameter, explaining its purpose and type.
            *   **Public Methods:** Provide a summary, document each parameter with `@param` (name, type, description, and the "why" if not obvious), describe the return value with `@returns` (type and what it represents), and list potential exceptions with `@throws` (type of error and conditions for throwing). Include `@example` tags for non-trivial usage patterns.
            *   **Public Properties:** Document their purpose and type.
        *   **Interfaces (if not in `types.ts`):**
            *   **Summary:** Explain the contract the interface defines and its intended use.
            *   Document each property and method signature with a clear description.
        *   **Functions:**
            *   **Summary:** Explain what the function does, its inputs, and its outputs. Focus on the "why" it exists.
            *   Use `@param` for each parameter (name, type, description).
            *   Use `@returns` for the return value (type, description).
            *   Use `@throws` for any exceptions the function might throw (type, conditions).
            *   Provide `@example` tags for functions with complex parameters or usage.
        *   **Type Aliases (if not in `types.ts`):**
            *   **Summary:** Explain what the type represents and its intended use.
    *   **Adherence to Principles:**
        *   **"Why" vs. "How":** Ensure comments explain the rationale, intent, and design decisions, not just mechanically restate what the code does.
        *   **API Contracts:** Make API contracts explicit and immediately obvious for all public exports.
        *   **TSDoc Standard Tags:** Consistently use standard TSDoc tags (`@param`, `@returns`, `@throws`, `@example`, `@remarks`, `@default`, `@see`, `@deprecated` if applicable).

4.  **Review and Refine Documentation:**
    *   After the initial pass on all modules, conduct a comprehensive review of all TSDoc comments.
    *   Check for clarity, accuracy, completeness, and consistency in style and detail.
    *   Ensure examples are correct and helpful.
    *   Verify that all public APIs are adequately documented from the perspective of both a maintainer and a potential user of the API.
    *   Run the TSDoc linter (`eslint . --ext .ts`) and fix all reported issues.

5.  **Generate HTML Documentation (Recommended):**
    *   Install TypeDoc: `npm install typedoc --save-dev`.
    *   Add a script to `package.json` to generate documentation, e.g., `"doc": "typedoc src/index.ts"`. (Adjust entry point as needed).
    *   Generate the documentation and review the HTML output. This helps identify how comments are rendered and if any information is missing or unclear.

6.  **Integrate TSDoc Linting into CI:**
    *   Add a step to the CI pipeline (e.g., GitHub Actions workflow) to run the TSDoc linter (`eslint . --ext .ts --quiet` or similar, failing the build on errors). This ensures ongoing documentation quality and adherence to standards.
    *   Example CI step: `npm run lint:tsdoc` (assuming a script `lint:tsdoc` is configured in `package.json` to run the linter).
