```
## Chosen Approach
Manual, fully hands-on TSDoc documentation pass for all exported entities, with module-level context and rationale, following project and TSDoc standards.

## Rationale
- Maximizes Simplicity: Directly augments source files with rich, intentional doc comments—no extra layers, generators, or meta files.
- Highest Modularity: Keeps documentation tightly coupled to the actual code, ensuring interfaces and contracts are explicit and visible at source.
- Best for Testability: By making contracts, parameters, return types, and exceptions explicit, both maintainers and users (including test writers) immediately understand expected behaviors and edge cases.
- Strict Coding Standards: Aligns with both the core and TypeScript-specific documentation and code clarity mandates; ensures “why” is covered, not just “how.”
- Documentation Approach: Produces self-explanatory, TSDoc-compliant, rationale-rich doc comments that serve as single source of truth for both maintainers and API consumers.

## Build Steps
1. For each module (`src/types.ts`, `src/logger.ts`, `src/fileWalker.ts`, `src/metadataInspector.ts`, `src/legacyParser.ts`, `src/metadataConverter.ts`, `src/yamlSerializer.ts`, `src/fileRewriter.ts`, `src/backupManager.ts`, `src/cliHandler.ts`, `src/migrationEngine.ts`, `src/migrationOrchestrator.ts`, `src/nodeFileSystemAdapter.ts`):
    1. Add a **module-level TSDoc comment** at the top explaining its role, context, and how it fits into the migration system (“why”, not just “what”).
    2. For EVERY exported function, class, interface, and type:
        - Write a TSDoc comment block explaining:
            - What the export is for and why it exists (intent/rationale).
            - Explicit API contract: what it expects, what it returns, and what it promises.
            - All parameters (`@param`), return values (`@returns`), and exceptions (`@throws`), including rationale for exceptions.
            - Guidance on usage, edge cases, and side effects.
            - Add `@example` where non-obvious or helpful.
        - For interfaces and types, describe the contract in terms of both structure and system-level intent.
        - For classes, explain responsibilities and usage patterns, not just methods.
    3. Ensure all doc comments are TSDoc-compliant, using standard tags.
2. Review/iterate to ensure comments focus on rationale and intent, not just descriptions of mechanics.
3. Confirm that documentation is comprehensive, immediately visible, and accurate for all public APIs—serving both as guidance for users and maintainers.
```
