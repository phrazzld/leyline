/**
 * Tests for the NodeFileSystemAdapter module
 */

import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { NodeFileSystemAdapter } from "./nodeFileSystemAdapter.js";
import * as fsPromises from "fs/promises";
import { constants } from "fs";

// Mock the fs/promises module
vi.mock("fs/promises");

describe("NodeFileSystemAdapter", () => {
  let adapter: NodeFileSystemAdapter;

  beforeEach(() => {
    adapter = new NodeFileSystemAdapter();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe("readFile", () => {
    it("should read file content as string", async () => {
      const mockContent = "file content";
      vi.mocked(fsPromises.readFile).mockResolvedValue(mockContent);

      const result = await adapter.readFile("/test/file.txt");

      expect(result).toBe(mockContent);
      expect(fsPromises.readFile).toHaveBeenCalledWith("/test/file.txt", "utf-8");
    });

    it("should throw error if file cannot be read", async () => {
      const error = new Error("ENOENT: no such file");
      vi.mocked(fsPromises.readFile).mockRejectedValue(error);

      await expect(adapter.readFile("/test/nonexistent.txt")).rejects.toThrow("ENOENT");
    });
  });

  describe("writeFile", () => {
    it("should write content to file", async () => {
      vi.mocked(fsPromises.writeFile).mockResolvedValue();

      await adapter.writeFile("/test/file.txt", "content");

      expect(fsPromises.writeFile).toHaveBeenCalledWith("/test/file.txt", "content", "utf-8");
    });

    it("should throw error if file cannot be written", async () => {
      const error = new Error("EACCES: permission denied");
      vi.mocked(fsPromises.writeFile).mockRejectedValue(error);

      await expect(adapter.writeFile("/test/file.txt", "content")).rejects.toThrow("EACCES");
    });
  });

  describe("copyFile", () => {
    it("should copy file from source to destination", async () => {
      vi.mocked(fsPromises.copyFile).mockResolvedValue();

      await adapter.copyFile("/test/source.txt", "/test/dest.txt");

      expect(fsPromises.copyFile).toHaveBeenCalledWith("/test/source.txt", "/test/dest.txt");
    });

    it("should throw error if file cannot be copied", async () => {
      const error = new Error("ENOENT: no such file");
      vi.mocked(fsPromises.copyFile).mockRejectedValue(error);

      await expect(adapter.copyFile("/test/source.txt", "/test/dest.txt")).rejects.toThrow("ENOENT");
    });
  });

  describe("renameFile", () => {
    it("should rename file", async () => {
      vi.mocked(fsPromises.rename).mockResolvedValue();

      await adapter.renameFile("/test/old.txt", "/test/new.txt");

      expect(fsPromises.rename).toHaveBeenCalledWith("/test/old.txt", "/test/new.txt");
    });

    it("should throw error if file cannot be renamed", async () => {
      const error = new Error("ENOENT: no such file");
      vi.mocked(fsPromises.rename).mockRejectedValue(error);

      await expect(adapter.renameFile("/test/old.txt", "/test/new.txt")).rejects.toThrow("ENOENT");
    });
  });

  describe("deleteFile", () => {
    it("should delete file", async () => {
      vi.mocked(fsPromises.unlink).mockResolvedValue();

      await adapter.deleteFile("/test/file.txt");

      expect(fsPromises.unlink).toHaveBeenCalledWith("/test/file.txt");
    });

    it("should throw error if file cannot be deleted", async () => {
      const error = new Error("ENOENT: no such file");
      vi.mocked(fsPromises.unlink).mockRejectedValue(error);

      await expect(adapter.deleteFile("/test/file.txt")).rejects.toThrow("ENOENT");
    });
  });

  describe("fileExists", () => {
    it("should return true if file exists", async () => {
      vi.mocked(fsPromises.access).mockResolvedValue();

      const result = await adapter.fileExists("/test/file.txt");

      expect(result).toBe(true);
      expect(fsPromises.access).toHaveBeenCalledWith("/test/file.txt", constants.F_OK);
    });

    it("should return false if file does not exist", async () => {
      const error = new Error("ENOENT: no such file");
      vi.mocked(fsPromises.access).mockRejectedValue(error);

      const result = await adapter.fileExists("/test/file.txt");

      expect(result).toBe(false);
    });
  });

  describe("ensureDirectoryExists", () => {
    it("should create directory with recursive option", async () => {
      vi.mocked(fsPromises.mkdir).mockResolvedValue(undefined);

      await adapter.ensureDirectoryExists("/test/nested/dir");

      expect(fsPromises.mkdir).toHaveBeenCalledWith("/test/nested/dir", { recursive: true });
    });

    it("should throw error if directory cannot be created", async () => {
      const error = new Error("EACCES: permission denied");
      vi.mocked(fsPromises.mkdir).mockRejectedValue(error);

      await expect(adapter.ensureDirectoryExists("/test/dir")).rejects.toThrow("EACCES");
    });
  });
});
