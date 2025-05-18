/**
 * FileWalker module for recursively finding Markdown files within directories.
 *
 * This module provides functionality to discover all Markdown files in specified
 * paths, whether they are individual files or directories. It uses the `glob`
 * package for efficient pattern matching when scanning directories.
 *
 * @remarks
 * The FileWalker is the first step in the migration pipeline, identifying all
 * files that need to be processed. It supports both file and directory inputs,
 * making it flexible for various use cases (single file migration, directory
 * migration, or multiple mixed paths).
 */

import { glob } from "glob";
import { stat } from "fs/promises";
import { resolve } from "path";
import { logger } from "./logger.js";

/**
 * Recursively find all Markdown files in the specified paths.
 *
 * @param paths - Array of file or directory paths to search
 * @returns Promise resolving to array of absolute file paths
 * @throws Error if a provided path does not exist or is invalid
 *
 * @remarks
 * This function handles both individual files and directories:
 * - Individual files are validated to ensure they exist and have a .md extension
 * - Directories are recursively scanned for all .md files
 * - Duplicate paths are automatically removed from the results
 * - All returned paths are absolute paths for consistent processing
 *
 * @example
 * ```typescript
 * // Find all markdown files in specific directories
 * const files = await findMarkdownFiles(['docs/', 'README.md']);
 * console.log(`Found ${files.length} markdown files`);
 *
 * // Process a single file
 * const singleFile = await findMarkdownFiles(['docs/example.md']);
 * ```
 */
export async function findMarkdownFiles(paths: string[]): Promise<string[]> {
  logger.info("Starting markdown file search", {
    paths,
    count: paths.length,
  });

  const allFiles: string[] = [];

  for (const path of paths) {
    const absolutePath = resolve(path);
    logger.debug(`Processing path: ${absolutePath}`);

    // Verify the path exists
    try {
      const stats = await stat(absolutePath);

      if (stats.isFile()) {
        // If it's a file, add it directly if it's a markdown file
        if (absolutePath.endsWith('.md')) {
          logger.debug(`Adding markdown file: ${absolutePath}`);
          allFiles.push(absolutePath);
        } else {
          logger.debug(`Skipping non-markdown file: ${absolutePath}`);
        }
      } else if (stats.isDirectory()) {
        // If it's a directory, use glob to find all markdown files recursively
        try {
          const pattern = `${absolutePath}/**/*.md`;
          const files = await glob(pattern, {
            nodir: true,
            absolute: true,
          });

          logger.debug(`Found ${files.length} markdown files in ${absolutePath}`, {
            directory: absolutePath,
            fileCount: files.length,
          });

          allFiles.push(...files);
        } catch (error) {
          logger.error(`Error searching for markdown files in ${absolutePath}`, {
            directory: absolutePath,
            error: (error as Error).message,
          });
          throw error;
        }
      } else {
        throw new Error(`Path is neither a file nor directory: ${absolutePath}`);
      }
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        throw new Error(`Path does not exist: ${absolutePath}`);
      }
      throw error;
    }
  }

  // Remove duplicates (in case of overlapping paths)
  const uniqueFiles = Array.from(new Set(allFiles));

  logger.info("Markdown file search completed", {
    totalFiles: uniqueFiles.length,
    paths: paths.length,
  });

  return uniqueFiles;
}
