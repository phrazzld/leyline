/**
 * Node.js implementation of file system interfaces.
 * Provides real file system operations for the migration tool.
 */

import { readFile, writeFile, copyFile, rename, unlink, access, mkdir } from "fs/promises";
import { constants } from "fs";
import { dirname } from "path";
import { IFileSystemAdapter } from "./types.js";
import { IFileSystem } from "./fileRewriter.js";

/**
 * Node.js file system adapter implementing both IFileSystemAdapter and IFileSystem.
 */
export class NodeFileSystemAdapter implements IFileSystemAdapter, IFileSystem {
  /**
   * Read file content as string.
   * @param filePath Path to the file to read
   * @returns File content as string
   * @throws Error if file cannot be read
   */
  async readFile(filePath: string): Promise<string> {
    return await readFile(filePath, "utf-8");
  }

  /**
   * Write content to a file.
   * @param filePath Path to the file to write
   * @param content Content to write
   * @throws Error if file cannot be written
   */
  async writeFile(filePath: string, content: string): Promise<void> {
    await writeFile(filePath, content, "utf-8");
  }

  /**
   * Copy a file from source to destination.
   * @param sourcePath Source file path
   * @param destinationPath Destination file path
   * @throws Error if file cannot be copied
   */
  async copyFile(sourcePath: string, destinationPath: string): Promise<void> {
    await copyFile(sourcePath, destinationPath);
  }

  /**
   * Rename/move a file.
   * @param oldPath Current file path
   * @param newPath New file path
   * @throws Error if file cannot be renamed
   */
  async renameFile(oldPath: string, newPath: string): Promise<void> {
    await rename(oldPath, newPath);
  }

  /**
   * Delete a file.
   * @param filePath Path to the file to delete
   * @throws Error if file cannot be deleted
   */
  async deleteFile(filePath: string): Promise<void> {
    await unlink(filePath);
  }

  /**
   * Check if a file exists.
   * @param filePath Path to check
   * @returns True if file exists, false otherwise
   */
  async fileExists(filePath: string): Promise<boolean> {
    try {
      await access(filePath, constants.F_OK);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Ensure a directory exists, creating it if necessary.
   * @param dirPath Directory path to ensure exists
   * @throws Error if directory cannot be created
   */
  async ensureDirectoryExists(dirPath: string): Promise<void> {
    await mkdir(dirPath, { recursive: true });
  }
}
