## Chosen Approach
Manually add comprehensive TSDoc comments to all exported functions, classes, interfaces, and types, focusing on documenting intent and API contracts.

## Rationale
- **Simplicity (✔):** The manual approach is conceptually simple and avoids the complexity and potential pitfalls of integrating and relying on AI tools for nuanced documentation requirements.
- **Coding Standards (✔) & Documentation Approach (✔):** This approach provides maximum control over adhering to the project's specific standards, particularly the crucial principle of "Document Decisions, Not Mechanics: Explain the *Why*". Manual documentation ensures the rationale, intent, and explicit API contracts are accurately captured, which AI tools currently struggle with without extensive prompt engineering and review.
- **Maintainability:** High-quality, accurate documentation produced manually is more reliable and less likely to require frequent correction compared to potentially superficial AI-generated drafts.
- **Accuracy:** Direct human understanding of the codebase ensures the documentation precisely reflects the code's behavior, constraints, and intended usage, reducing the risk of subtle inaccuracies introduced by automated generation.

## Build Steps
1.  Review the TSDoc standard (https://tsdoc.org/) and the project's Documentation Approach philosophy, paying close attention to the "Document the Why" principle.
2.  Iterate through each specified module file (`src/types.ts`, `src/logger.ts`, `src/fileWalker.ts`, `src/metadataInspector.ts`, `src/legacyParser.ts`, `src/metadataConverter.ts`, `src/yamlSerializer.ts`, `src/fileRewriter.ts`, `src/backupManager.ts`, `src/cliHandler.ts`, `src/migrationEngine.ts`, `src/migrationOrchestrator.ts`, `src/nodeFileSystemAdapter.ts`).
3.  For each file, add a module-level TSDoc comment at the top explaining the file's overall purpose and how it fits into the migration tool's architecture.
4.  Within each file, identify all exported functions, classes, interfaces, and type aliases.
5.  Add a detailed TSDoc comment block (`/** ... */`) for each identified export.
6.  For functions and methods, include `@param` tags for all parameters, an `@returns` tag for the return value, and `@throws` tags for any potential errors or exceptions. Clearly describe the purpose, constraints, and role of each.
7.  For classes and interfaces, provide a clear description of their role in the system, their responsibilities, and the contract they define.
8.  For type aliases, explain what the type represents and its purpose.
9.  Throughout the documentation, prioritize explaining the *why* (rationale, intent, design choices) rather than just restating *what* the code does. Make API contracts explicit and immediately obvious. Include `@example` blocks where a usage example significantly clarifies the API.
10. Run `tsc --noEmit` to validate TSDoc syntax and ensure types are correctly referenced.
11. Run ESLint and Prettier to ensure adherence to coding standards and formatting, addressing any linting rules related to documentation.
12. Submit the changes for code review, requesting specific feedback on the quality, completeness, and adherence to the documentation philosophy.
