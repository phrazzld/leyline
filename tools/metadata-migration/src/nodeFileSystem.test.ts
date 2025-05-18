/**
 * Unit tests for NodeFileSystem module.
 * Tests the Node.js implementation of the IFileSystem interface.
 */

import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { NodeFileSystem } from "./nodeFileSystem.js";
import * as fs from "fs/promises";
import { IFileSystem } from "./fileRewriter.js";

// Mock fs/promises
vi.mock("fs/promises");

describe("NodeFileSystem", () => {
  let nodeFileSystem: NodeFileSystem;

  beforeEach(() => {
    vi.clearAllMocks();
    nodeFileSystem = new NodeFileSystem();
  });

  describe("readFile", () => {
    it("should read file content as UTF-8 string", async () => {
      const mockContent = "file content";
      vi.mocked(fs.readFile).mockResolvedValue(mockContent);

      const result = await nodeFileSystem.readFile("/test/file.txt");

      expect(result).toBe(mockContent);
      expect(fs.readFile).toHaveBeenCalledWith("/test/file.txt", "utf-8");
    });

    it("should propagate error when file cannot be read", async () => {
      const error = new Error("File not found");
      vi.mocked(fs.readFile).mockRejectedValue(error);

      await expect(nodeFileSystem.readFile("/test/missing.txt")).rejects.toThrow(
        "File not found"
      );
    });
  });

  describe("writeFile", () => {
    it("should write content to file as UTF-8", async () => {
      vi.mocked(fs.writeFile).mockResolvedValue();

      await nodeFileSystem.writeFile("/test/file.txt", "content");

      expect(fs.writeFile).toHaveBeenCalledWith(
        "/test/file.txt",
        "content",
        "utf-8"
      );
    });

    it("should propagate error when file cannot be written", async () => {
      const error = new Error("Permission denied");
      vi.mocked(fs.writeFile).mockRejectedValue(error);

      await expect(
        nodeFileSystem.writeFile("/test/file.txt", "content")
      ).rejects.toThrow("Permission denied");
    });
  });

  describe("copyFile", () => {
    it("should copy file from source to destination", async () => {
      vi.mocked(fs.copyFile).mockResolvedValue();

      await nodeFileSystem.copyFile("/test/source.txt", "/test/dest.txt");

      expect(fs.copyFile).toHaveBeenCalledWith(
        "/test/source.txt",
        "/test/dest.txt"
      );
    });

    it("should propagate error when file cannot be copied", async () => {
      const error = new Error("Source not found");
      vi.mocked(fs.copyFile).mockRejectedValue(error);

      await expect(
        nodeFileSystem.copyFile("/test/missing.txt", "/test/dest.txt")
      ).rejects.toThrow("Source not found");
    });
  });

  describe("renameFile", () => {
    it("should rename/move file", async () => {
      vi.mocked(fs.rename).mockResolvedValue();

      await nodeFileSystem.renameFile("/test/old.txt", "/test/new.txt");

      expect(fs.rename).toHaveBeenCalledWith("/test/old.txt", "/test/new.txt");
    });

    it("should propagate error when file cannot be renamed", async () => {
      const error = new Error("File in use");
      vi.mocked(fs.rename).mockRejectedValue(error);

      await expect(
        nodeFileSystem.renameFile("/test/locked.txt", "/test/new.txt")
      ).rejects.toThrow("File in use");
    });
  });

  describe("deleteFile", () => {
    it("should delete file", async () => {
      vi.mocked(fs.unlink).mockResolvedValue();

      await nodeFileSystem.deleteFile("/test/file.txt");

      expect(fs.unlink).toHaveBeenCalledWith("/test/file.txt");
    });

    it("should propagate error when file cannot be deleted", async () => {
      const error = new Error("File not found");
      vi.mocked(fs.unlink).mockRejectedValue(error);

      await expect(
        nodeFileSystem.deleteFile("/test/missing.txt")
      ).rejects.toThrow("File not found");
    });
  });

  describe("fileExists", () => {
    it("should return true when file exists", async () => {
      vi.mocked(fs.access).mockResolvedValue();

      const result = await nodeFileSystem.fileExists("/test/exists.txt");

      expect(result).toBe(true);
      expect(fs.access).toHaveBeenCalledWith("/test/exists.txt");
    });

    it("should return false when file does not exist", async () => {
      vi.mocked(fs.access).mockRejectedValue(new Error("Not found"));

      const result = await nodeFileSystem.fileExists("/test/missing.txt");

      expect(result).toBe(false);
    });
  });

  describe("ensureDirectoryExists", () => {
    it("should create directory recursively", async () => {
      vi.mocked(fs.mkdir).mockResolvedValue(undefined);

      await nodeFileSystem.ensureDirectoryExists("/test/nested/dir");

      expect(fs.mkdir).toHaveBeenCalledWith("/test/nested/dir", {
        recursive: true,
      });
    });

    it("should propagate error when directory cannot be created", async () => {
      const error = new Error("Permission denied");
      vi.mocked(fs.mkdir).mockRejectedValue(error);

      await expect(
        nodeFileSystem.ensureDirectoryExists("/test/protected")
      ).rejects.toThrow("Permission denied");
    });
  });

  describe("interface compliance", () => {
    it("should implement IFileSystem interface", () => {
      const interfaceTest: IFileSystem = nodeFileSystem;
      expect(interfaceTest).toBeDefined();
    });

    it("should have all required methods", () => {
      expect(nodeFileSystem.readFile).toBeDefined();
      expect(nodeFileSystem.writeFile).toBeDefined();
      expect(nodeFileSystem.copyFile).toBeDefined();
      expect(nodeFileSystem.renameFile).toBeDefined();
      expect(nodeFileSystem.deleteFile).toBeDefined();
      expect(nodeFileSystem.fileExists).toBeDefined();
      expect(nodeFileSystem.ensureDirectoryExists).toBeDefined();
    });
  });
});
