```markdown
## Chosen Approach
Implement the FileRewriter module as a class with injected Logger and a filesystem abstraction, using atomic write (write to temp, rename) and copy for backup, preserving original line endings.

## Rationale
- **Modularity + strict separation**: The core file rewriting logic is encapsulated in a class, and its dependency on filesystem operations is abstracted via an interface (`IFileSystemWriter`). This adheres to the Dependency Inversion Principle, making the module's core logic independent of the specific filesystem implementation (`NodeFileSystemWriter`). The content combination logic is a pure, private helper function.
- **Design for Testability**: By depending on the `IFileSystemWriter` interface, the `FileRewriter` class can be unit tested easily by providing a mock or stub implementation of the interface, avoiding complex mocking of the built-in `fs` module. This directly supports the "Design for Testability" tenet and the "Mocking Policy" (mocking external dependencies).
- **Coding Standards**: The approach leverages strong typing with interfaces and classes (`no any`). Error handling is explicit with `try...catch` and logged using the injected `Logger`. Immutability is supported by treating input objects (`StandardYamlMetadata`, `InspectedContent`) as immutable and the content combination being a pure function.
- **Simplicity**: While slightly more verbose than a single function, the class structure with DI simplifies the *management* of dependencies and separates concerns (filesystem vs. rewriting logic), leading to simpler, more focused individual components and tests. The core logic within the `rewriteFile` method remains straightforward: backup -> write temp -> rename -> cleanup.
- **Documentation Approach**: Interfaces and class methods are documented using TSDoc, clarifying their purpose, parameters, and return values.

## Build Steps
1.  Create `src/fileRewriter.ts`.
2.  Define the `IFileSystemWriter` interface in `src/fileRewriter.ts` with methods: `readFile(path: string, encoding: string): Promise<string>`, `writeFile(path: string, content: string, encoding: string): Promise<void>`, `copyFile(src: string, dest: string): Promise<void>`, `rename(oldPath: string, newPath: string): Promise<void>`, `unlink(path: string): Promise<void>`.
3.  Implement `NodeFileSystemWriter` class in `src/fileRewriter.ts` that implements `IFileSystemWriter` using `fs.promises`. Ensure correct handling of encoding (default to 'utf8').
4.  Define the `FileRewriter` class in `src/fileRewriter.ts`. Its constructor should accept a `logger: Logger` and `fsWriter: IFileSystemWriter` instance.
5.  Add a private helper method `combineContent(metadata: StandardYamlMetadata, content: string, lineBreakType: string): string` to the `FileRewriter` class. This method will serialize the `metadata` using `serializeToYaml` (from `yamlSerializer.ts`), prepend `---` and append `---` using the specified `lineBreakType`, and then append the original `content` using the same `lineBreakType`. Ensure a blank line separates the closing `---` from the content.
6.  Add the public asynchronous method `rewriteFile(filePath: string, newMetadata: StandardYamlMetadata, inspectedContent: InspectedContent, backupDir?: string): Promise<MigrationResult>` to the `FileRewriter` class.
7.  Inside `rewriteFile`:
    *   Log the start of the rewrite process using the injected `logger`.
    *   If `backupDir` is provided:
        *   Construct a backup file path (e.g., `path.join(backupDir, path.basename(filePath) + '.' + Date.now() + '.bak')`).
        *   Use `this.fsWriter.copyFile(filePath, backupPath)` within a `try...catch` block. Log success or error. If backup fails, log a warning but continue with the write.
    *   Call `this.combineContent(newMetadata, inspectedContent.content, inspectedContent.lineBreakType)` to get the new file content.
    *   Generate a temporary file path in the same directory as the target file (e.g., `filePath + '.tmp.' + Date.now() + Math.random().toString(36).substring(7)`).
    *   Use a `try...finally` block to ensure temp file cleanup:
        *   Inside `try`:
            *   Use `this.fsWriter.writeFile(tempPath, newContent, 'utf8')` to write the new content to the temp file. Handle errors (log, return failed `MigrationResult`).
            *   Use `this.fsWriter.rename(tempPath, filePath)` to atomically replace the original file. Handle errors (log, return failed `MigrationResult`).
        *   Inside `finally`:
            *   Attempt to `this.fsWriter.unlink(tempPath)` to clean up the temporary file. Log a warning if this fails, but do not affect the main operation's success status if the rename was successful.
    *   Return a successful `MigrationResult` including the backup path if created.
8.  Implement comprehensive error handling within `rewriteFile`, catching errors from all `fsWriter` operations, logging them with context (`filePath`, `backupPath`, `tempPath`, specific operation), and returning a failed `MigrationResult` object.
9.  Add unit tests for the `combineContent` helper (pure function tests).
10. Add unit tests for the `FileRewriter` class by mocking the `IFileSystemWriter` dependency. Test successful write, backup creation, and failure scenarios for each filesystem operation (`copyFile`, `writeFile`, `rename`, `unlink`).
11. Add integration tests for `NodeFileSystemWriter` in a dedicated test directory that cleans up after itself.
12. Ensure `Logger` and `StandardYamlMetadata`, `InspectedContent`, `MigrationResult` types are imported from their respective modules.
13. Add TSDoc comments for the interface, classes, and methods.
```
