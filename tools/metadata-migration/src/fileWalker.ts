/**
 * FileWalker module for recursively finding Markdown files within directories.
 * Uses the glob package for efficient pattern matching.
 */

import { glob } from "glob";
import { stat } from "fs/promises";
import { resolve } from "path";
import { logger } from "./logger.js";

/**
 * Recursively find all Markdown files in the specified paths.
 * @param paths Array of file or directory paths to search
 * @returns Promise resolving to array of absolute file paths
 * @throws Error if a provided path does not exist
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
