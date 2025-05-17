## Chosen Approach
A class-based `FileRewriter` module leveraging dependency injection for filesystem operations (via an `IFileSystem` interface), logging, and YAML serialization. It utilizes pure static helper functions for content construction and backup path determination, ensuring atomic writes, configurable backups, and preservation of original line endings.

## Rationale
- **Modularity + Strict Separation**: The `FileRewriter`'s core logic is decoupled from direct filesystem interactions via the `IFileSystem` interface, adhering to the Dependency Inversion Principle. Pure static helper functions for content construction and path calculation further enhance separation of concerns.
- **Testability (Minimal Mocking)**: The `FileRewriter` class can be unit-tested effectively by injecting mock implementations of `IFileSystem`, `Logger`, and `YamlSerializer`, isolating its logic from external dependencies. Pure helper functions are inherently easy to test.
- **Simplicity**: While dependency injection introduces some initial setup, it simplifies the internal logic of the `FileRewriter` class and its tests. The use of pure functions for specific tasks contributes to overall simplicity and predictability.
- **Coding Standards**: The approach enforces strong typing (no `any` usage), promotes immutability for input data, implements explicit and comprehensive error handling (using a custom `FileRewriteError` and returning a `FileRewriteResult`), and integrates structured logging.
- **Explicit over Implicit**: All dependencies are explicitly injected. File operations, backup behavior, and error reporting are clearly defined.

## Build Steps

1.  **Define Core Interfaces and Types** (`src/fileRewriterTypes.ts` or within `src/fileRewriter.ts`):

    ```typescript
    import { StandardYamlMetadata, InspectedContent } from "./types"; // Assuming from project structure
    import { Logger } from "./logger"; // Assuming from project structure
    import { YamlSerializer } from "./yamlSerializer"; // Assuming from project structure

    export interface IFileSystem {
      readFile(filePath: string): Promise<string>;
      writeFile(filePath: string, content: string): Promise<void>;
      copyFile(sourcePath: string, destinationPath: string): Promise<void>;
      renameFile(oldPath: string, newPath: string): Promise<void>;
      deleteFile(filePath: string): Promise<void>;
      fileExists(filePath: string): Promise<boolean>;
      ensureDirectoryExists(dirPath: string): Promise<void>; // Creates directory recursively if not exists
    }

    export interface FileRewriteOptions {
      backupDirectory?: string; // If undefined, no backup is created.
    }

    export class FileRewriteError extends Error {
      public readonly operation?: string;
      public readonly path?: string;
      public readonly originalError?: Error;

      constructor(message: string, details?: { operation?: string; path?: string; originalError?: Error }) {
        super(message);
        this.name = 'FileRewriteError';
        this.operation = details?.operation;
        this.path = details?.path;
        this.originalError = details?.originalError;
        if (details?.originalError?.stack) {
          this.stack = details.originalError.stack;
        }
      }
    }

    export interface FileRewriteResult {
      success: boolean;
      filePath: string;
      backupPath?: string; // Path where backup was made, if applicable
      error?: FileRewriteError; // Present if success is false
    }
    ```

2.  **Implement `NodeFileSystem` Adapter** (`src/nodeFileSystem.ts`):

    ```typescript
    import fs from 'fs/promises';
    import path from 'path';
    import { IFileSystem } from './fileRewriterTypes'; // Or wherever IFileSystem is defined

    export class NodeFileSystem implements IFileSystem {
      async readFile(filePath: string): Promise<string> {
        return fs.readFile(filePath, 'utf-8');
      }

      async writeFile(filePath: string, content: string): Promise<void> {
        await fs.writeFile(filePath, content, 'utf-8');
      }

      async copyFile(sourcePath: string, destinationPath: string): Promise<void> {
        await fs.copyFile(sourcePath, destinationPath);
      }

      async renameFile(oldPath: string, newPath: string): Promise<void> {
        await fs.rename(oldPath, newPath);
      }

      async deleteFile(filePath: string): Promise<void> {
        await fs.unlink(filePath);
      }

      async fileExists(filePath: string): Promise<boolean> {
        try {
          await fs.access(filePath);
          return true;
        } catch {
          return false;
        }
      }

      async ensureDirectoryExists(dirPath: string): Promise<void> {
        await fs.mkdir(dirPath, { recursive: true });
      }
    }
    ```

3.  **Create `FileRewriter` Class** (`src/fileRewriter.ts`):

    ```typescript
    import path from 'path'; // Node.js path module
    import { StandardYamlMetadata, InspectedContent } from "./types";
    import { Logger } from "./logger";
    import { YamlSerializer } from "./yamlSerializer";
    import {
      IFileSystem,
      FileRewriteOptions,
      FileRewriteResult,
      FileRewriteError,
    } from "./fileRewriterTypes"; // Or appropriate path

    export class FileRewriter {
      private readonly logger: Logger;
      private readonly fs: IFileSystem;
      private readonly yamlSerializer: YamlSerializer;

      constructor(logger: Logger, fsAdapter: IFileSystem, yamlSerializer: YamlSerializer) {
        this.logger = logger;
        this.fs = fsAdapter;
        this.yamlSerializer = yamlSerializer;
      }

      private static constructNewFileContent(
        metadata: StandardYamlMetadata,
        originalBodyContent: string,
        lineBreakType: 'CRLF' | 'LF',
        yamlSerializer: YamlSerializer
      ): string {
        const yamlContent = yamlSerializer.serialize(metadata); // Assumes this returns YAML string block
        const EOL = lineBreakType === 'CRLF' ? '\r\n' : '\n';
        // Ensure yamlContent doesn't have leading/trailing --- or newlines if serializer is simple
        const trimmedYamlContent = yamlContent.trim();
        return `---${EOL}${trimmedYamlContent}${EOL}---${EOL}${originalBodyContent}`;
      }

      private static computeBackupPath(
        originalFilePath: string,
        backupDirectory?: string
      ): string | undefined {
        if (!backupDirectory) {
          return undefined;
        }
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const fileName = path.basename(originalFilePath);
        return path.join(backupDirectory, `${fileName}.${timestamp}.bak`);
      }

      public async rewriteFile(
        filePath: string,
        newMetadata: StandardYamlMetadata,
        inspectedContent: InspectedContent,
        options?: FileRewriteOptions
      ): Promise<FileRewriteResult> {
        this.logger.info(`Starting rewrite for file: ${filePath}`);
        let backupPath: string | undefined;

        try {
          // 1. Create backup if configured
          if (options?.backupDirectory) {
            backupPath = FileRewriter.computeBackupPath(filePath, options.backupDirectory);
            if (backupPath) {
              try {
                await this.fs.ensureDirectoryExists(path.dirname(backupPath));
                await this.fs.copyFile(filePath, backupPath);
                this.logger.info(`Created backup for ${filePath} at ${backupPath}`);
              } catch (backupError) {
                const err = new FileRewriteError(`Backup creation failed for ${filePath}`, {
                  operation: 'backup',
                  path: backupPath,
                  originalError: backupError as Error,
                });
                this.logger.error(err.message, { error: err });
                // Decide if this is fatal. For now, log and continue.
                // To make it fatal: return { success: false, filePath, error: err, backupPath: undefined };
              }
            }
          }

          // 2. Construct new file content
          const newFileContent = FileRewriter.constructNewFileContent(
            newMetadata,
            inspectedContent.content,
            inspectedContent.lineBreakType,
            this.yamlSerializer
          );

          // 3. Atomic write (write to temp file, then rename)
          const tempFilePath = path.join(path.dirname(filePath), `.${path.basename(filePath)}.tmp-rewrite-${Date.now()}`);
          let tempFileWritten = false;

          try {
            await this.fs.writeFile(tempFilePath, newFileContent);
            tempFileWritten = true;
            await this.fs.renameFile(tempFilePath, filePath);
            this.logger.info(`Successfully rewrote file: ${filePath}`);
            return { success: true, filePath, backupPath };
          } catch (writeError) {
            if (tempFileWritten && await this.fs.fileExists(tempFilePath)) {
              try {
                await this.fs.deleteFile(tempFilePath);
                this.logger.info(`Cleaned up temporary file: ${tempFilePath}`);
              } catch (cleanupError) {
                this.logger.warn(`Failed to clean up temporary file: ${tempFilePath}`, { error: cleanupError });
              }
            }
            const err = new FileRewriteError(`Atomic write failed for ${filePath}`, {
              operation: 'atomicWrite',
              path: filePath,
              originalError: writeError as Error,
            });
            this.logger.error(err.message, { error: err });
            return { success: false, filePath, backupPath, error: err };
          }
        } catch (e) {
          // Catch-all for unexpected errors before atomic write section
          const err = new FileRewriteError(`Unexpected error during rewrite of ${filePath}`, {
            originalError: e as Error,
            path: filePath,
          });
          this.logger.error(err.message, { error: err });
          return { success: false, filePath, backupPath, error: err };
        }
      }
    }
    ```

4.  **Error Handling Strategy**:
    *   All filesystem operations performed via `IFileSystem` are wrapped in `try...catch` blocks.
    *   Specific errors are wrapped in the custom `FileRewriteError`, providing context like the operation name (`backup`, `atomicWrite`), file path, and the original error.
    *   Structured logging (using the injected `Logger`) is used for all significant operations, successes, and errors.
    *   The `rewriteFile` method returns a `FileRewriteResult` object, indicating success or failure, and includes the error object and backup path if applicable.

5.  **Testing Approach**:
    *   **Unit Tests**:
        *   Test `FileRewriter.constructNewFileContent` (static pure function) with various metadata, content, and line ending combinations.
        *   Test `FileRewriter.computeBackupPath`
