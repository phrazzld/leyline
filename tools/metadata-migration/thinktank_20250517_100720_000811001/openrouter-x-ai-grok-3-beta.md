## Chosen Approach
Implement a modular FileRewriter with atomic writes, backup support, and structured error handling in TypeScript.

## Rationale
- **Simplicity**: This approach prioritizes clear, focused functions for content construction and file operations, reducing complexity as per the core philosophy's "Simplicity First" principle.
- **Modularity**: By separating concerns (content rewriting, atomic writes, backups) into distinct methods with explicit interfaces, it adheres to "Strict Separation of Concerns" and enhances maintainability.
- **Testability**: The design avoids internal mocking, using dependency injection for filesystem operations, aligning with "Design for Testability" and minimizing test complexity.
- **Coding Standards**: It enforces TypeScript strictness, immutability by default, and structured logging, fully complying with language-specific standards from DEVELOPMENT_PHILOSOPHY_APPENDIX_TYPESCRIPT.md.
- **Documentation Approach**: Clear TSDoc comments and self-documenting code align with the "Document Decisions, Not Mechanics" principle, ensuring maintainability.

## Build Steps
1. **Create src/fileRewriter.ts**: Define the `FileRewriter` class with methods for content construction, atomic writes, and backups, using explicit interfaces for dependencies (filesystem, logger).
2. **Implement Content Construction**: Add a pure function `constructNewContent` to combine YAML front-matter (from `YamlSerializer`) with original content, preserving line endings.
3. **Implement Atomic Writes**: Create a method `writeFileAtomically` to write to a temporary file and rename it to the target path using Node.js `fs` module, ensuring data safety.
4. **Add Backup Functionality**: Implement `createBackup` to copy the original file to a configurable backup directory with a timestamped filename before overwriting.
5. **Define Error Handling**: Use custom error types (e.g., `FileWriteError`, `BackupError`) for filesystem operations, with structured logging of errors via the `Logger` class.
6. **Inject Dependencies**: Use constructor injection for `Logger` and filesystem operations (mockable in tests), adhering to dependency inversion principles.
7. **Preserve Line Endings**: Detect and maintain original line endings (CRLF/LF) in content construction to ensure consistency.
8. **Add Configuration**: Support a configurable backup directory via an options interface, externalizing configuration as per architectural guidelines.
