/**
 * Unit tests for the FileRewriter module
 */

import { describe, test, expect, vi, beforeEach } from "vitest";
import { FileRewriter, FileRewriteError } from "./fileRewriter.js";
import {
  StandardYamlMetadata,
  InspectedContent,
  MetadataFormat,
} from "./types.js";
import { Logger } from "./logger.js";

// Mock dependencies
const mockLogger: Logger = {
  debug: vi.fn(),
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn(),
} as any;

const mockFileSystem = {
  readFile: vi.fn(),
  writeFile: vi.fn(),
  copyFile: vi.fn(),
  renameFile: vi.fn(),
  deleteFile: vi.fn(),
  fileExists: vi.fn(),
  ensureDirectoryExists: vi.fn(),
};

const mockYamlSerializer = {
  serializeToYaml: vi.fn(),
};

describe("FileRewriter", () => {
  let fileRewriter: FileRewriter;

  beforeEach(() => {
    vi.clearAllMocks();
    fileRewriter = new FileRewriter(
      mockLogger,
      mockFileSystem,
      mockYamlSerializer,
    );
  });

  describe("rewriteFile", () => {
    const testMetadata: StandardYamlMetadata = {
      id: "test-binding",
      last_modified: "2025-01-17",
    };

    const testContent: InspectedContent = {
      format: MetadataFormat.LegacyHr,
      metadata: "id: test-binding\nlastModified: 2025-01-17",
      content: "# Test Document\n\nThis is the content.",
      lineBreakType: "\n",
    };

    test("successfully rewrites file with no backup", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      mockFileSystem.renameFile.mockResolvedValue(undefined);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
      );

      expect(result.success).toBe(true);
      expect(result.filePath).toBe("/test/file.md");
      expect(result.backupPath).toBeUndefined();
      expect(result.error).toBeUndefined();

      // Verify temp file was created and renamed
      expect(mockFileSystem.writeFile).toHaveBeenCalledWith(
        expect.stringMatching(/^\/test\/\.file\.md\.tmp-rewrite-\d+$/),
        '---\nid: test-binding\nlast_modified: "2025-01-17"\n---\n# Test Document\n\nThis is the content.',
      );
      expect(mockFileSystem.renameFile).toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        "Successfully rewrote file: /test/file.md",
        expect.any(Object),
      );
    });

    test("successfully rewrites file with backup", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      mockFileSystem.ensureDirectoryExists.mockResolvedValue(undefined);
      mockFileSystem.copyFile.mockResolvedValue(undefined);
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      mockFileSystem.renameFile.mockResolvedValue(undefined);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
        { backupDirectory: "/backups" },
      );

      expect(result.success).toBe(true);
      expect(result.filePath).toBe("/test/file.md");
      expect(result.backupPath).toMatch(
        /^\/backups\/file\.md\.\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.bak$/,
      );
      expect(result.error).toBeUndefined();

      // Verify backup was created
      expect(mockFileSystem.ensureDirectoryExists).toHaveBeenCalledWith(
        "/backups",
      );
      expect(mockFileSystem.copyFile).toHaveBeenCalledWith(
        "/test/file.md",
        expect.stringMatching(
          /^\/backups\/file\.md\.\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.bak$/,
        ),
      );
    });

    test("preserves CRLF line endings", async () => {
      const crlfContent: InspectedContent = {
        ...testContent,
        content: "# Test Document\r\n\r\nThis is the content.",
        lineBreakType: "\r\n",
      };

      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      mockFileSystem.renameFile.mockResolvedValue(undefined);

      await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        crlfContent,
      );

      expect(mockFileSystem.writeFile).toHaveBeenCalledWith(
        expect.any(String),
        '---\r\nid: test-binding\nlast_modified: "2025-01-17"\r\n---\r\n# Test Document\r\n\r\nThis is the content.',
      );
    });

    test("handles write failure with cleanup", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      const writeError = new Error("Write failed");
      mockFileSystem.writeFile.mockRejectedValue(writeError);
      mockFileSystem.fileExists.mockResolvedValue(false);
      mockFileSystem.deleteFile.mockResolvedValue(undefined);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
      );

      expect(result.success).toBe(false);
      expect(result.error).toBeInstanceOf(FileRewriteError);
      expect(result.error?.message).toContain("Atomic write failed");
      expect(result.error?.operation).toBe("atomicWrite");
      expect(result.error?.originalError).toBe(writeError);

      // File wasn't written, so no cleanup should happen
      expect(mockFileSystem.deleteFile).not.toHaveBeenCalled();
    });

    test("handles rename failure with cleanup", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      const renameError = new Error("Rename failed");
      mockFileSystem.renameFile.mockRejectedValue(renameError);
      mockFileSystem.fileExists.mockResolvedValue(true);
      mockFileSystem.deleteFile.mockResolvedValue(undefined);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
      );

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain("Atomic write failed");
      expect(result.error?.originalError).toBe(renameError);

      // Verify cleanup attempt
      expect(mockFileSystem.deleteFile).toHaveBeenCalled();
    });

    test("handles backup failure but continues with write", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      const backupError = new Error("Backup failed");
      mockFileSystem.ensureDirectoryExists.mockResolvedValue(undefined);
      mockFileSystem.copyFile.mockRejectedValue(backupError);
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      mockFileSystem.renameFile.mockResolvedValue(undefined);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
        { backupDirectory: "/backups" },
      );

      // Should succeed despite backup failure
      expect(result.success).toBe(true);
      expect(result.filePath).toBe("/test/file.md");
      expect(result.backupPath).toBeUndefined();

      // Verify backup error was logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        expect.stringContaining("Backup creation failed"),
        expect.any(Object),
      );
    });

    test("handles cleanup failure gracefully", async () => {
      mockYamlSerializer.serializeToYaml.mockReturnValue(
        'id: test-binding\nlast_modified: "2025-01-17"',
      );
      mockFileSystem.writeFile.mockResolvedValue(undefined);
      const renameError = new Error("Rename failed");
      mockFileSystem.renameFile.mockRejectedValue(renameError);
      mockFileSystem.fileExists.mockResolvedValue(true);
      const cleanupError = new Error("Cleanup failed");
      mockFileSystem.deleteFile.mockRejectedValue(cleanupError);

      const result = await fileRewriter.rewriteFile(
        "/test/file.md",
        testMetadata,
        testContent,
      );

      expect(result.success).toBe(false);
      expect(result.error?.message).toContain("Atomic write failed");

      // Verify cleanup failure was logged as warning
      expect(mockLogger.warn).toHaveBeenCalledWith(
        expect.stringContaining("Failed to clean up temporary file"),
        expect.any(Object),
      );
    });
  });

  describe("constructNewFileContent", () => {
    test("constructs content with LF line endings", () => {
      const metadata: StandardYamlMetadata = {
        id: "test",
        last_modified: "2025-01-17",
      };
      const yamlContent = 'id: test\nlast_modified: "2025-01-17"';
      const originalContent = "# Document\n\nContent here.";

      const result = FileRewriter.constructNewFileContent(
        yamlContent,
        originalContent,
        "\n",
      );

      expect(result).toBe(
        '---\nid: test\nlast_modified: "2025-01-17"\n---\n# Document\n\nContent here.',
      );
    });

    test("constructs content with CRLF line endings", () => {
      const yamlContent = 'id: test\nlast_modified: "2025-01-17"';
      const originalContent = "# Document\r\n\r\nContent here.";

      const result = FileRewriter.constructNewFileContent(
        yamlContent,
        originalContent,
        "\r\n",
      );

      expect(result).toBe(
        '---\r\nid: test\nlast_modified: "2025-01-17"\r\n---\r\n# Document\r\n\r\nContent here.',
      );
    });
  });

  describe("computeBackupPath", () => {
    test("generates backup path with directory", () => {
      const now = new Date("2025-01-17T10:30:00.000Z");
      vi.setSystemTime(now);

      const result = FileRewriter.computeBackupPath(
        "/path/to/file.md",
        "/backups",
      );

      expect(result).toBe("/backups/file.md.2025-01-17T10-30-00-000Z.bak");
    });

    test("generates backup path in same directory when no backup dir specified", () => {
      const now = new Date("2025-01-17T10:30:00.000Z");
      vi.setSystemTime(now);

      const result = FileRewriter.computeBackupPath("/path/to/file.md");

      expect(result).toBe("/path/to/file.md.2025-01-17T10-30-00-000Z.bak");
    });

    test("handles paths with various separators", () => {
      const now = new Date("2025-01-17T10:30:00.000Z");
      vi.setSystemTime(now);

      const result = FileRewriter.computeBackupPath(
        "C:\\Users\\test\\file.md",
        "D:\\backups",
      );

      // Path module should normalize separators based on platform
      expect(result).toMatch(/file\.md\.2025-01-17T10-30-00-000Z\.bak$/);
    });
  });
});
