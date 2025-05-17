/**
 * FileRewriter module for constructing new file content with YAML front-matter
 * and performing atomic file writes with optional backup functionality.
 */

import path from "path";
import { StandardYamlMetadata, InspectedContent } from "./types.js";
import { Logger } from "./logger.js";
import { serializeToYaml } from "./yamlSerializer.js";

/**
 * Interface for filesystem operations to enable testing and abstraction
 */
export interface IFileSystem {
  readFile(filePath: string): Promise<string>;
  writeFile(filePath: string, content: string): Promise<void>;
  copyFile(sourcePath: string, destinationPath: string): Promise<void>;
  renameFile(oldPath: string, newPath: string): Promise<void>;
  deleteFile(filePath: string): Promise<void>;
  fileExists(filePath: string): Promise<boolean>;
  ensureDirectoryExists(dirPath: string): Promise<void>;
}

/**
 * Options for file rewriting operations
 */
export interface FileRewriteOptions {
  /** Directory to store backups. If undefined, create backup in same directory */
  backupDirectory?: string;
}

/**
 * Custom error class for file rewrite operations
 */
export class FileRewriteError extends Error {
  public readonly operation?: string;
  public readonly path?: string;
  public readonly originalError?: Error;

  constructor(
    message: string,
    details?: {
      operation?: string;
      path?: string;
      originalError?: Error;
    },
  ) {
    super(message);
    this.name = "FileRewriteError";
    this.operation = details?.operation;
    this.path = details?.path;
    this.originalError = details?.originalError;

    // Preserve original error stack if available
    if (details?.originalError?.stack) {
      this.stack = details.originalError.stack;
    }
  }
}

/**
 * Result of a file rewrite operation
 */
export interface FileRewriteResult {
  /** Whether the operation succeeded */
  success: boolean;
  /** Path of the file that was processed */
  filePath: string;
  /** Path where backup was created, if applicable */
  backupPath?: string;
  /** Error details if operation failed */
  error?: FileRewriteError;
}

/**
 * Module for rewriting files with new YAML front-matter
 */
export class FileRewriter {
  private readonly logger: Logger;
  private readonly fs: IFileSystem;
  private readonly yamlSerializer: typeof serializeToYaml;

  constructor(
    logger: Logger,
    fsAdapter: IFileSystem,
    yamlSerializer: { serializeToYaml: typeof serializeToYaml },
  ) {
    this.logger = logger;
    this.fs = fsAdapter;
    this.yamlSerializer = yamlSerializer.serializeToYaml;
  }

  /**
   * Construct new file content with YAML front-matter
   * @param yamlContent Serialized YAML content
   * @param originalBodyContent Original document content
   * @param lineBreakType Type of line breaks to use
   * @returns Complete file content with front-matter
   */
  static constructNewFileContent(
    yamlContent: string,
    originalBodyContent: string,
    lineBreakType: string,
  ): string {
    const EOL = lineBreakType;
    const trimmedYaml = yamlContent.trim();
    return `---${EOL}${trimmedYaml}${EOL}---${EOL}${originalBodyContent}`;
  }

  /**
   * Compute backup file path
   * @param originalFilePath Path to the original file
   * @param backupDirectory Optional backup directory
   * @returns Path for the backup file
   */
  static computeBackupPath(
    originalFilePath: string,
    backupDirectory?: string,
  ): string {
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const fileName = path.basename(originalFilePath);
    const backupFileName = `${fileName}.${timestamp}.bak`;

    if (backupDirectory) {
      return path.join(backupDirectory, backupFileName);
    }

    // Same directory as original file
    const dir = path.dirname(originalFilePath);
    return path.join(dir, backupFileName);
  }

  /**
   * Rewrite a file with new YAML front-matter metadata
   * @param filePath Path to the file to rewrite
   * @param newMetadata New metadata to apply
   * @param inspectedContent Inspected content from the original file
   * @param options Rewrite options including backup configuration
   * @returns Result of the rewrite operation
   */
  async rewriteFile(
    filePath: string,
    newMetadata: StandardYamlMetadata,
    inspectedContent: InspectedContent,
    options?: FileRewriteOptions,
  ): Promise<FileRewriteResult> {
    this.logger.info(`Starting rewrite for file: ${filePath}`, { filePath });
    let backupPath: string | undefined;

    try {
      // 1. Create backup if configured
      if (options?.backupDirectory) {
        backupPath = FileRewriter.computeBackupPath(
          filePath,
          options.backupDirectory,
        );
        try {
          await this.fs.ensureDirectoryExists(path.dirname(backupPath));
          await this.fs.copyFile(filePath, backupPath);
          this.logger.info(`Created backup for ${filePath} at ${backupPath}`, {
            filePath,
            backupPath,
          });
        } catch (backupError) {
          const err = new FileRewriteError(
            `Backup creation failed for ${filePath}`,
            {
              operation: "backup",
              path: backupPath,
              originalError: backupError as Error,
            },
          );
          this.logger.error(err.message, {
            error: err,
            filePath,
            backupPath,
          });
          // Continue with write despite backup failure
          backupPath = undefined;
        }
      }

      // 2. Construct new file content
      const yamlContent = this.yamlSerializer(newMetadata);
      const newFileContent = FileRewriter.constructNewFileContent(
        yamlContent,
        inspectedContent.content,
        inspectedContent.lineBreakType,
      );

      // 3. Atomic write (write to temp file, then rename)
      const tempFilePath = path.join(
        path.dirname(filePath),
        `.${path.basename(filePath)}.tmp-rewrite-${Date.now()}`,
      );
      let tempFileWritten = false;

      try {
        await this.fs.writeFile(tempFilePath, newFileContent);
        tempFileWritten = true;
        await this.fs.renameFile(tempFilePath, filePath);
        this.logger.info(`Successfully rewrote file: ${filePath}`, {
          filePath,
        });
        return { success: true, filePath, backupPath };
      } catch (writeError) {
        // Clean up temp file if it was created
        if (tempFileWritten) {
          try {
            const exists = await this.fs.fileExists(tempFilePath);
            if (exists) {
              await this.fs.deleteFile(tempFilePath);
              this.logger.info(`Cleaned up temporary file: ${tempFilePath}`, {
                tempFilePath,
              });
            }
          } catch (cleanupError) {
            this.logger.warn(
              `Failed to clean up temporary file: ${tempFilePath}`,
              {
                error: cleanupError,
                tempFilePath,
              },
            );
          }
        }

        const err = new FileRewriteError(
          `Atomic write failed for ${filePath}`,
          {
            operation: "atomicWrite",
            path: filePath,
            originalError: writeError as Error,
          },
        );
        this.logger.error(err.message, { error: err, filePath });
        return { success: false, filePath, backupPath, error: err };
      }
    } catch (e) {
      // Catch-all for unexpected errors
      const err = new FileRewriteError(
        `Unexpected error during rewrite of ${filePath}`,
        {
          originalError: e as Error,
          path: filePath,
        },
      );
      this.logger.error(err.message, { error: err, filePath });
      return { success: false, filePath, backupPath, error: err };
    }
  }
}
