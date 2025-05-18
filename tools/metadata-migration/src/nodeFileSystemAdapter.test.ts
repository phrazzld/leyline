/**
 * Unit tests for NodeFileSystemAdapter module.
 * Tests the IFileSystemAdapter implementation.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { NodeFileSystemAdapter } from "./nodeFileSystemAdapter.js";
import { readFile } from "fs/promises";
import { IFileSystemAdapter } from "./types.js";

// Mock fs/promises
vi.mock("fs/promises");

describe("NodeFileSystemAdapter", () => {
  let adapter: NodeFileSystemAdapter;

  beforeEach(() => {
    vi.clearAllMocks();
    adapter = new NodeFileSystemAdapter();
  });

  describe("readFile", () => {
    it("should read file content as UTF-8 string", async () => {
      const mockContent = "file content with unicode: 文字化け";
      vi.mocked(readFile).mockResolvedValue(mockContent);

      const result = await adapter.readFile("/test/file.txt");

      expect(result).toBe(mockContent);
      expect(readFile).toHaveBeenCalledWith("/test/file.txt", "utf-8");
    });

    it("should propagate error when file cannot be read", async () => {
      const error = new Error("ENOENT: no such file or directory");
      vi.mocked(readFile).mockRejectedValue(error);

      await expect(adapter.readFile("/test/missing.txt")).rejects.toThrow(
        "ENOENT: no such file or directory"
      );
    });

    it("should handle empty files", async () => {
      vi.mocked(readFile).mockResolvedValue("");

      const result = await adapter.readFile("/test/empty.txt");

      expect(result).toBe("");
    });

    it("should handle large files", async () => {
      const largeContent = "x".repeat(10000);
      vi.mocked(readFile).mockResolvedValue(largeContent);

      const result = await adapter.readFile("/test/large.txt");

      expect(result).toBe(largeContent);
    });
  });

  describe("interface compliance", () => {
    it("should implement IFileSystemAdapter interface", () => {
      const interfaceTest: IFileSystemAdapter = adapter;
      expect(interfaceTest).toBeDefined();
    });

    it("should have readFile method with correct signature", () => {
      expect(adapter.readFile).toBeDefined();
      expect(typeof adapter.readFile).toBe("function");
    });
  });

  describe("error scenarios", () => {
    it("should handle permission denied errors", async () => {
      const error = new Error("EACCES: permission denied");
      vi.mocked(readFile).mockRejectedValue(error);

      await expect(adapter.readFile("/test/protected.txt")).rejects.toThrow(
        "EACCES: permission denied"
      );
    });

    it("should handle file system errors", async () => {
      const error = new Error("EIO: i/o error");
      vi.mocked(readFile).mockRejectedValue(error);

      await expect(adapter.readFile("/test/corrupted.txt")).rejects.toThrow(
        "EIO: i/o error"
      );
    });
  });
});
