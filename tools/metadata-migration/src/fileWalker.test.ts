/**
 * Tests for the FileWalker module
 */

import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { findMarkdownFiles } from "./fileWalker.js";
import { stat } from "fs/promises";
import { glob } from "glob";

// Mock the modules
vi.mock("fs/promises");
vi.mock("glob");
vi.mock("./logger.js", () => ({
  logger: {
    info: vi.fn(),
    debug: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

describe("FileWalker", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe("findMarkdownFiles", () => {
    it("should find markdown files in a single directory", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const mockGlob = glob as unknown as ReturnType<typeof vi.fn>;

      mockStat.mockResolvedValue({ isDirectory: () => true });
      mockGlob.mockResolvedValue([
        "/test/dir/file1.md",
        "/test/dir/subdir/file2.md",
      ]);

      const result = await findMarkdownFiles(["/test/dir"]);

      expect(result).toEqual([
        "/test/dir/file1.md",
        "/test/dir/subdir/file2.md",
      ]);
      expect(mockStat).toHaveBeenCalledWith(
        expect.stringContaining("/test/dir"),
      );
      expect(mockGlob).toHaveBeenCalledWith(
        expect.stringContaining("/**/*.md"),
        expect.objectContaining({
          nodir: true,
          absolute: true,
        }),
      );
    });

    it("should find markdown files in multiple directories", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const mockGlob = glob as unknown as ReturnType<typeof vi.fn>;

      mockStat.mockResolvedValue({ isDirectory: () => true });
      mockGlob
        .mockResolvedValueOnce(["/test/dir1/file1.md"])
        .mockResolvedValueOnce(["/test/dir2/file2.md"]);

      const result = await findMarkdownFiles(["/test/dir1", "/test/dir2"]);

      expect(result).toEqual(["/test/dir1/file1.md", "/test/dir2/file2.md"]);
      expect(mockStat).toHaveBeenCalledTimes(2);
      expect(mockGlob).toHaveBeenCalledTimes(2);
    });

    it("should remove duplicate files", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const mockGlob = glob as unknown as ReturnType<typeof vi.fn>;

      mockStat.mockResolvedValue({ isDirectory: () => true });
      mockGlob
        .mockResolvedValueOnce(["/test/dir/file1.md", "/test/dir/file2.md"])
        .mockResolvedValueOnce(["/test/dir/file2.md", "/test/dir/file3.md"]);

      const result = await findMarkdownFiles(["/test/dir", "/test/dir"]);

      expect(result).toEqual([
        "/test/dir/file1.md",
        "/test/dir/file2.md",
        "/test/dir/file3.md",
      ]);
    });

    it("should throw error if directory does not exist", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const error = new Error("ENOENT") as NodeJS.ErrnoException;
      error.code = "ENOENT";
      mockStat.mockRejectedValue(error);

      await expect(findMarkdownFiles(["/nonexistent"])).rejects.toThrow(
        "Directory does not exist: /nonexistent",
      );
    });

    it("should throw error if path is not a directory", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      mockStat.mockResolvedValue({ isDirectory: () => false });

      await expect(findMarkdownFiles(["/test/file.txt"])).rejects.toThrow(
        "Path is not a directory: /test/file.txt",
      );
    });

    it("should throw error if glob operation fails", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const mockGlob = glob as unknown as ReturnType<typeof vi.fn>;

      mockStat.mockResolvedValue({ isDirectory: () => true });
      mockGlob.mockRejectedValue(new Error("Glob error"));

      await expect(findMarkdownFiles(["/test/dir"])).rejects.toThrow(
        "Glob error",
      );
    });

    it("should handle empty directory", async () => {
      const mockStat = stat as unknown as ReturnType<typeof vi.fn>;
      const mockGlob = glob as unknown as ReturnType<typeof vi.fn>;

      mockStat.mockResolvedValue({ isDirectory: () => true });
      mockGlob.mockResolvedValue([]);

      const result = await findMarkdownFiles(["/empty/dir"]);

      expect(result).toEqual([]);
    });
  });
});
