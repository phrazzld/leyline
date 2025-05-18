## Chosen Approach
Automate TSDoc stub generation for all public exports via a custom `ts-morph` script, then manually enrich each stub following comprehensive TSDoc guidelines, with enforcement via `eslint-plugin-tsdoc`.

## Rationale
- **Simplicity:** The `ts-morph` script handles the repetitive boilerplate of creating initial TSDoc blocks, allowing developers to focus on high-quality content. The overall workflow (script -> manual enrichment -> lint) is straightforward.
- **Modularity + strict separation:** The script processes modules individually, and documentation remains co-located with the code, respecting modular design. The script itself is a distinct, modular tool.
- **Testability:** `eslint-plugin-tsdoc` provides automated validation of TSDoc syntax and presence. The quality of the enriched content is verified through peer review. This approach does not negatively impact code testability.
- **Coding Standards:** Directly enforces TSDoc standards via linting. The script provides a consistent baseline, and manual enrichment ensures adherence to the project's documentation philosophy, including documenting the "Why."
- **Documentation approach:** This hybrid method ensures comprehensive coverage (no export missed) by automating stub creation, freeing human effort for the critical aspects: rationale, explicit API contracts, examples, and overall clarity.

## Build Steps
1.  **Setup TSDoc Tooling:**
    *   Install `ts-morph` as a dev dependency: `npm install ts-morph --save-dev` (or equivalent for yarn/pnpm).
    *   Install and configure `eslint-plugin-tsdoc`: `npm install eslint-plugin-tsdoc --save-dev`. Update your ESLint configuration (e.g., `.eslintrc.js`) to include `plugin:tsdoc/recommended` and customize rules as needed (e.g., to error on TSDoc syntax issues or specific missing tags).

2.  **Develop TSDoc Stub Generation Script:**
    *   Create a new script (e.g., `scripts/generate-tsdoc-stubs.ts`) using `ts-morph`.
    *   This script will:
        *   Iterate through all specified `.ts` files in the `src/` directory (e.g., `src/types.ts`, `src/logger.ts`, etc.).
        *   Identify all exported functions, classes, interfaces, and type aliases.
        *   For any identified export that currently lacks a TSDoc comment block, the script will insert a basic TSDoc stub (e.g., `/** @remarks TODO: Document this entity */`).
        *   (Optional Enhancement): For functions/methods, the script could attempt to pre-fill `@param` tags based on function parameters and an `@returns` tag if a return type is explicit. Keep this logic simple to avoid overcomplicating the script.
    *   Add an npm script to `package.json` to execute this, e.g., `"docs:stubs": "ts-node ./scripts/generate-tsdoc-stubs.ts"`.

3.  **Initial Stub Generation:**
    *   Run the newly created stub generation script once (e.g., `npm run docs:stubs`) to populate initial TSDoc comment blocks for all undocumented public exports.
    *   Commit these generated stubs to version control.

4.  **Systematic Manual Enrichment:**
    *   Iterate through each module listed in the task requirements.
    *   **Module-Level Documentation:** For each file, add or enhance a module-level TSDoc comment at the top. This comment should explain the module's overall purpose, its primary responsibilities, and how it fits into the metadata migration tool's architecture.
    *   **Export-Level Documentation:** For each exported entity (class, function, interface, type alias) within the module:
        *   Locate the TSDoc stub (or existing comment) and enrich it comprehensively.
        *   Focus on documenting the "Why" (rationale, intent, design choices) rather than just restating what the code does.
        *   Make API contracts explicit and immediately obvious. Document all parameters (`@param {type} name - description`), return values (`@returns {type} - description`), and potential exceptions (`@throws {ErrorType} - when it's thrown`).
        *   Provide clear descriptions for classes (responsibilities, usage) and interfaces (the contract it defines).
        *   Explain what type aliases represent and their purpose.
        *   Include concise and helpful `@example` blocks where they significantly clarify usage, especially for complex APIs or non-obvious behavior.

5.  **Linting and Validation:**
    *   Regularly run your ESLint command (e.g., `npm run lint` or `eslint . --ext .ts`) throughout the documentation process. This will help catch TSDoc syntax errors and ensure adherence to configured rules.
    *   Ensure that the TSDoc linting rules are configured to fail the build in your CI (Continuous Integration) pipeline if violations are found.

6.  **Review and Refine:**
    *   Conduct thorough peer reviews of all added/updated TSDoc comments. Reviewers should focus on:
        *   Adherence to TSDoc standards (https://tsdoc.org/) and project-specific documentation guidelines.
        *   Clarity, accuracy, and completeness of the information.
        *   Effective communication of the "Why" and the explicitness of API contracts.
        *   Correctness and helpfulness of examples.
    *   Iterate on the documentation based on feedback until all public exports meet the required quality and comprehensiveness.

7.  **(Optional but Recommended) Generate and Review HTML Documentation:**
    *   Consider integrating a tool like TypeDoc (`npm install typedoc --save-dev`) to generate HTML documentation from your TSDoc comments.
    *   Add an npm script (e.g., `"docs:generate": "typedoc"`) to generate the documentation.
    *   Reviewing the generated HTML output can help identify how comments are rendered and spot areas needing improvement in clarity or structure.
