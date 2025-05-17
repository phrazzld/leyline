/**
 * Node.js filesystem adapter implementing the IFileSystem interface
 */

import fs from "fs/promises";
import { IFileSystem } from "./fileRewriter.js";

/**
 * Implementation of IFileSystem using Node.js fs/promises module
 */
export class NodeFileSystem implements IFileSystem {
  /**
   * Read file content as UTF-8 string
   * @param filePath Path to the file
   * @returns File content
   */
  async readFile(filePath: string): Promise<string> {
    return fs.readFile(filePath, "utf-8");
  }

  /**
   * Write content to file as UTF-8
   * @param filePath Path to the file
   * @param content Content to write
   */
  async writeFile(filePath: string, content: string): Promise<void> {
    await fs.writeFile(filePath, content, "utf-8");
  }

  /**
   * Copy file from source to destination
   * @param sourcePath Source file path
   * @param destinationPath Destination file path
   */
  async copyFile(sourcePath: string, destinationPath: string): Promise<void> {
    await fs.copyFile(sourcePath, destinationPath);
  }

  /**
   * Rename/move file
   * @param oldPath Current file path
   * @param newPath New file path
   */
  async renameFile(oldPath: string, newPath: string): Promise<void> {
    await fs.rename(oldPath, newPath);
  }

  /**
   * Delete file
   * @param filePath Path to the file to delete
   */
  async deleteFile(filePath: string): Promise<void> {
    await fs.unlink(filePath);
  }

  /**
   * Check if file exists
   * @param filePath Path to check
   * @returns True if file exists
   */
  async fileExists(filePath: string): Promise<boolean> {
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Ensure directory exists, creating it recursively if needed
   * @param dirPath Directory path
   */
  async ensureDirectoryExists(dirPath: string): Promise<void> {
    await fs.mkdir(dirPath, { recursive: true });
  }
}
