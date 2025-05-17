## Chosen Approach
Implement the FileRewriter module with atomic writes and backup functionality.

## Rationale
- The implementation will follow the simplicity principle by focusing on a single responsibility: safely writing new file content while preserving original line endings and creating backups.
- It will adhere to modularity by separating concerns into different functions for content construction, atomic writing, and backup creation.
- The module will be designed for testability by using pure functions where possible and minimizing side effects.
- Strong typing will be maintained throughout the implementation using existing types from `types.ts`.
- Comprehensive error handling will be implemented to gracefully handle filesystem errors.

## Build Steps
1. Create `src/fileRewriter.ts` with the necessary imports from `types.ts`, `yamlSerializer.ts`, and `logger.ts`.
2. Implement the `constructNewFileContent` function to combine YAML front-matter with original document content, preserving original line endings.
3. Develop the `writeFileAtomically` function to perform atomic file writes using a temporary file and rename operation.
4. Create the `createBackup` function to backup original files before overwriting, supporting a configurable backup directory.
5. Implement the main `rewriteFile` function to orchestrate content construction, backup creation, and atomic writing.
6. Handle filesystem errors gracefully in all file operations.
7. Add comprehensive tests for all functions, focusing on different content types, error scenarios, and edge cases.
