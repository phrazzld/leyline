/**
 * Node.js implementation of the IFileSystemAdapter interface.
 * Provides real file system operations for the MigrationOrchestrator.
 */

import { readFile } from "fs/promises";
import { IFileSystemAdapter } from "./types.js";

/**
 * Node.js file system adapter implementing IFileSystemAdapter.
 */
export class NodeFileSystemAdapter implements IFileSystemAdapter {
  /**
   * Read file content as string.
   * @param filePath Path to the file to read
   * @returns File content as string
   * @throws Error if file cannot be read
   */
  async readFile(filePath: string): Promise<string> {
    return await readFile(filePath, "utf-8");
  }
}
