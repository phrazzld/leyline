/**
 * FileWalker module for recursively finding Markdown files within directories.
 * Uses the glob package for efficient pattern matching.
 */

import { glob } from "glob";
import { stat } from "fs/promises";
import { resolve } from "path";
import { logger } from "./logger.js";

/**
 * Recursively find all Markdown files in the specified directories.
 * @param directories Array of directory paths to search
 * @returns Promise resolving to array of absolute file paths
 * @throws Error if a provided path is not a valid directory
 */
export async function findMarkdownFiles(
  directories: string[],
): Promise<string[]> {
  logger.info("Starting markdown file search", {
    directories,
    count: directories.length,
  });

  const allFiles: string[] = [];

  for (const directory of directories) {
    const absolutePath = resolve(directory);
    logger.debug(`Processing directory: ${absolutePath}`);

    // Verify the path exists and is a directory
    try {
      const stats = await stat(absolutePath);
      if (!stats.isDirectory()) {
        throw new Error(`Path is not a directory: ${absolutePath}`);
      }
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        throw new Error(`Directory does not exist: ${absolutePath}`);
      }
      throw error;
    }

    // Use glob to find all markdown files recursively
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
  }

  // Remove duplicates (in case of overlapping directory paths)
  const uniqueFiles = Array.from(new Set(allFiles));

  logger.info("Markdown file search completed", {
    totalFiles: uniqueFiles.length,
    directories: directories.length,
  });

  return uniqueFiles;
}
