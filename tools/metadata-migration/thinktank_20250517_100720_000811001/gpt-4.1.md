```
## Chosen Approach
Functional, strongly typed FileRewriter module with pure content construction and explicit, atomic file operations, backup support, and structured error handling/logging.

## Rationale
- Maximizes simplicity by strictly separating pure content construction from I/O, minimizing side effects and complexity.
- Enforces modularity and testability: pure functions (content construction, path resolution) are independently testable; all filesystem interactions are explicit and injectable.
- Uses strong typing and explicit interfaces for all operations; prohibits `any`.
- Comprehensive error handling with structured logging via the provided Logger.
- Adheres to immutability and explicitness: no mutation of inputs, explicit backup directory, and line ending preservation.
- Aligns with documentation approach: self-documenting, pure core logic, and clear error contracts.

## Build Steps
1. **Define Interfaces**:
   - `FileRewriterOptions`:
     - `backupDir?: string` (optional, default to same dir as file)
     - `logger: Logger`
   - `FileRewriterResult`:
     - `filePath: string`
     - `backupPath?: string`
     - `success: boolean`
     - `error?: string`
   - Export a `FileRewriter` class exposing a single `rewriteFile` method.

2. **Pure Content Construction**:
   - Implement a pure function:
     ```ts
     function buildYamlFrontMatterContent(
       metadata: StandardYamlMetadata,
       documentContent: string,
       lineBreak: string
     ): string
     ```
     - Uses `YamlSerializer` to produce front-matter (`---\n...YAML...\n---\n`) and concatenates with document content, preserving line endings.

3. **Path Resolution (Pure)**:
   - Implement a function to resolve the backup path, supporting a configurable backup directory (default: alongside file):
     ```ts
     function computeBackupPath(originalPath: string, backupDir?: string): string
     ```

4. **Atomic File Writing**:
   - In `FileRewriter.rewriteFile`:
     - Use `fs.promises` for async operations.
     - Write new content to a temp file in the same directory (`.${filename}.tmp`).
     - Use `fs.promises.rename` to atomically replace the original file with the temp file.
     - Before overwrite, copy the original file to the computed backup path.

5. **Backup Creation**:
   - Copy the original file to the backup path (create backupDir if needed).
   - Ensure backup creation is atomic and does not overwrite existing backups (use timestamp or unique suffix if necessary).

6. **Error Handling & Logging**:
   - All filesystem errors are caught and logged using the provided `Logger`, with structured context (file, operation, error).
   - Return a strongly typed `FileRewriterResult` with details of failure or success.
   - Never throw uncaught errors; propagate as error results.

7. **Line Ending Preservation**:
   - Use the detected line ending type from `InspectedContent.lineBreakType` and apply it throughout the constructed file content.

8. **Testing Approach**:
   - Unit-test all pure functions (content construction, backup path computation) with a variety of edge cases.
   - Integration-test `rewriteFile` using temp directories and mock filesystem where possible, verifying atomicity, backup correctness, and error handling.
   - Mock only true FS boundaries, never internal logic.

```
