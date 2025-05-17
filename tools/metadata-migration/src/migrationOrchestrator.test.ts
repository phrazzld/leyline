/**
 * Unit tests for the MigrationOrchestrator module.
 * Tests the orchestration of the metadata migration workflow.
 */

import { describe, it, expect, vi, beforeEach, Mock } from "vitest";
import { MigrationOrchestrator } from "./migrationOrchestrator.js";
import {
  MigrationOrchestratorOptions,
  MigrationSummary,
  FileProcessingResult,
  IFileSystemAdapter,
  ProgressReport,
} from "./types.js";
import { MetadataFormat } from "./types.js";
import { Logger } from "./logger.js";
import { FileRewriter } from "./fileRewriter.js";
import { findMarkdownFiles } from "./fileWalker.js";
import { inspectFile } from "./metadataInspector.js";
import { parseLegacyMetadata } from "./legacyParser.js";
import { convertMetadata } from "./metadataConverter.js";
import { serializeToYaml } from "./yamlSerializer.js";

// Mock all dependencies
vi.mock("./logger.js");
vi.mock("./fileRewriter.js");
vi.mock("./fileWalker.js");
vi.mock("./metadataInspector.js");
vi.mock("./legacyParser.js");
vi.mock("./metadataConverter.js");
vi.mock("./yamlSerializer.js");

describe("MigrationOrchestrator", () => {
  let orchestrator: MigrationOrchestrator;
  let mockLogger: Logger;
  let mockFileRewriter: FileRewriter;
  let mockFileSystem: IFileSystemAdapter;
  let mockOnProgress: Mock;
  let options: MigrationOrchestratorOptions;

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();

    // Create mock instances
    mockLogger = new Logger();
    mockFileRewriter = new FileRewriter(mockLogger, {} as any, {
      serializeToYaml,
    });
    mockFileSystem = {
      readFile: vi.fn(),
    };
    mockOnProgress = vi.fn();

    // Default options
    options = {
      paths: ["/test/docs"],
      dryRun: false,
      backupDir: "/test/backups",
      onProgress: mockOnProgress,
    };

    // Create orchestrator instance
    orchestrator = new MigrationOrchestrator(options, {
      logger: mockLogger,
      fileWalker: { findMarkdownFiles },
      metadataInspector: { inspectFile },
      legacyParser: { parseLegacyMetadata },
      metadataConverter: { convertMetadata },
      yamlSerializer: { serializeToYaml },
      fileRewriter: mockFileRewriter,
      fileSystem: mockFileSystem,
    });
  });

  describe("constructor", () => {
    it("should initialize with required dependencies", () => {
      expect(orchestrator).toBeDefined();
      expect(orchestrator).toBeInstanceOf(MigrationOrchestrator);
    });
  });

  describe("run()", () => {
    it("should process legacy format files successfully", async () => {
      // Setup mocks
      const mockFiles = ["/test/file1.md"];
      vi.mocked(findMarkdownFiles).mockResolvedValue(mockFiles);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("file content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.LegacyHr,
        metadata: "id: test\nlast_modified: 2025-01-15",
        content: "# Document\nContent here",
        lineBreakType: "\n",
      });
      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: { id: "test", lastModified: "2025-01-15" },
        errors: [],
        warnings: [],
      });
      vi.mocked(convertMetadata).mockReturnValue({
        success: true,
        data: { id: "test", last_modified: "2025-01-15" },
      });
      vi.mocked(serializeToYaml).mockReturnValue(
        "id: test\nlast_modified: '2025-01-15'\n",
      );
      vi.mocked(mockFileRewriter.rewriteFile).mockResolvedValue({
        success: true,
        filePath: "/test/file1.md",
        backupPath: "/test/backups/file1.md.bak",
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary).toEqual({
        totalFiles: 1,
        processedFiles: 1,
        succeededCount: 1,
        failedCount: 0,
        modifiedCount: 1,
        alreadyYamlCount: 0,
        noMetadataCount: 0,
        unknownFormatCount: 0,
        backupsCreated: 1,
        errors: [],
      });

      // Verify interactions
      expect(findMarkdownFiles).toHaveBeenCalledWith(["/test/docs"]);
      expect(mockFileSystem.readFile).toHaveBeenCalledWith("/test/file1.md");
      expect(mockFileRewriter.rewriteFile).toHaveBeenCalled();
      expect(mockOnProgress).toHaveBeenCalledWith({
        totalFiles: 1,
        processedFiles: 0,
        currentFilePath: "/test/file1.md",
        status: "processing",
      });
      expect(mockOnProgress).toHaveBeenCalledWith({
        totalFiles: 1,
        processedFiles: 1,
        currentFilePath: "/test/file1.md",
        status: "completed",
      });
    });

    it("should skip YAML format files", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("file content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.Yaml,
        metadata: "---\nid: test\n---",
        content: "# Document",
        lineBreakType: "\n",
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.alreadyYamlCount).toBe(1);
      expect(summary.modifiedCount).toBe(0);
      expect(mockFileRewriter.rewriteFile).not.toHaveBeenCalled();
    });

    it("should handle files with no metadata", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("# Just content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.None,
        metadata: "",
        content: "# Just content",
        lineBreakType: "\n",
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.noMetadataCount).toBe(1);
      expect(summary.modifiedCount).toBe(0);
    });

    it("should handle unknown format files", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("strange: format");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.Unknown,
        metadata: "strange: format",
        content: "",
        lineBreakType: "\n",
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.unknownFormatCount).toBe(1);
      expect(summary.failedCount).toBe(1);
      expect(summary.errors).toHaveLength(1);
      expect(summary.errors[0]).toEqual({
        filePath: "/test/file1.md",
        message: "Unknown metadata format",
      });
    });

    it("should handle file read errors", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockRejectedValue(
        new Error("File not found"),
      );

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.failedCount).toBe(1);
      expect(summary.errors).toHaveLength(1);
      expect(summary.errors[0].message).toContain("File not found");
    });

    it("should handle parsing errors", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.LegacyHr,
        metadata: "invalid metadata",
        content: "content",
        lineBreakType: "\n",
      });
      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: null,
        errors: [
          { message: "Invalid metadata", field: "id", lineNumber: 1 } as any,
        ],
        warnings: [],
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.failedCount).toBe(1);
      expect(summary.errors[0].message).toContain("Invalid metadata");
    });

    it("should handle conversion errors", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.LegacyHr,
        metadata: "id: test",
        content: "content",
        lineBreakType: "\n",
      });
      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: { id: "test" } as any,
        errors: [],
        warnings: [],
      });
      vi.mocked(convertMetadata).mockReturnValue({
        success: false,
        errors: [{ fieldPath: "lastModified", message: "Required" }],
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.failedCount).toBe(1);
      expect(summary.errors[0].message).toContain("Required");
    });

    it("should handle file rewrite errors", async () => {
      // Setup all mocks for successful processing up to rewrite
      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.LegacyHr,
        metadata: "id: test\nlast_modified: 2025-01-15",
        content: "content",
        lineBreakType: "\n",
      });
      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: { id: "test", lastModified: "2025-01-15" },
        errors: [],
        warnings: [],
      });
      vi.mocked(convertMetadata).mockReturnValue({
        success: true,
        data: { id: "test", last_modified: "2025-01-15" },
      });
      vi.mocked(serializeToYaml).mockReturnValue("id: test\n");
      vi.mocked(mockFileRewriter.rewriteFile).mockResolvedValue({
        success: false,
        filePath: "/test/file1.md",
        error: {
          message: "Write failed",
          path: "/test/file1.md",
        } as any,
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.failedCount).toBe(1);
      expect(summary.errors[0].message).toContain("Write failed");
    });

    it("should respect dry-run mode", async () => {
      // Setup mocks
      options.dryRun = true;
      orchestrator = new MigrationOrchestrator(options, {
        logger: mockLogger,
        fileWalker: { findMarkdownFiles },
        metadataInspector: { inspectFile },
        legacyParser: { parseLegacyMetadata },
        metadataConverter: { convertMetadata },
        yamlSerializer: { serializeToYaml },
        fileRewriter: mockFileRewriter,
        fileSystem: mockFileSystem,
      });

      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.LegacyHr,
        metadata: "id: test\nlast_modified: 2025-01-15",
        content: "content",
        lineBreakType: "\n",
      });
      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: { id: "test", lastModified: "2025-01-15" },
        errors: [],
        warnings: [],
      });
      vi.mocked(convertMetadata).mockReturnValue({
        success: true,
        data: { id: "test", last_modified: "2025-01-15" },
      });
      vi.mocked(serializeToYaml).mockReturnValue("id: test\n");

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.modifiedCount).toBe(1);
      expect(summary.succeededCount).toBe(1);
      expect(mockFileRewriter.rewriteFile).not.toHaveBeenCalled();
      expect(mockLogger.info).toHaveBeenCalledWith(
        expect.stringContaining("[DRY RUN]"),
        expect.any(Object),
      );
    });

    it("should process multiple files sequentially", async () => {
      // Setup mocks
      const mockFiles = ["/test/file1.md", "/test/file2.md", "/test/file3.md"];
      vi.mocked(findMarkdownFiles).mockResolvedValue(mockFiles);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile)
        .mockReturnValueOnce({
          format: MetadataFormat.LegacyHr,
          metadata: "id: test1",
          content: "content1",
          lineBreakType: "\n",
        })
        .mockReturnValueOnce({
          format: MetadataFormat.Yaml,
          metadata: "---\nid: test2\n---",
          content: "content2",
          lineBreakType: "\n",
        })
        .mockReturnValueOnce({
          format: MetadataFormat.None,
          metadata: "",
          content: "content3",
          lineBreakType: "\n",
        });

      vi.mocked(parseLegacyMetadata).mockReturnValue({
        metadata: { id: "test1", lastModified: "2025-01-15" },
        errors: [],
        warnings: [],
      });
      vi.mocked(convertMetadata).mockReturnValue({
        success: true,
        data: { id: "test1", last_modified: "2025-01-15" },
      });
      vi.mocked(serializeToYaml).mockReturnValue("id: test1\n");
      vi.mocked(mockFileRewriter.rewriteFile).mockResolvedValue({
        success: true,
        filePath: "/test/file1.md",
      });

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.totalFiles).toBe(3);
      expect(summary.processedFiles).toBe(3);
      expect(summary.modifiedCount).toBe(1);
      expect(summary.alreadyYamlCount).toBe(1);
      expect(summary.noMetadataCount).toBe(1);

      // Verify progress callbacks were called for each file
      expect(mockOnProgress).toHaveBeenCalledTimes(6); // 2 calls per file
    });

    it("should handle errors in file discovery", async () => {
      // Setup mocks
      vi.mocked(findMarkdownFiles).mockRejectedValue(
        new Error("Directory not found"),
      );

      // Execute
      const summary = await orchestrator.run();

      // Verify results
      expect(summary.totalFiles).toBe(0);
      expect(summary.processedFiles).toBe(0);
      expect(summary.errors).toHaveLength(1);
      expect(summary.errors[0].filePath).toBe("");
      expect(summary.errors[0].message).toContain("Directory not found");
    });

    it("should not call progress callback if not provided", async () => {
      // Create orchestrator without progress callback
      options.onProgress = undefined;
      orchestrator = new MigrationOrchestrator(options, {
        logger: mockLogger,
        fileWalker: { findMarkdownFiles },
        metadataInspector: { inspectFile },
        legacyParser: { parseLegacyMetadata },
        metadataConverter: { convertMetadata },
        yamlSerializer: { serializeToYaml },
        fileRewriter: mockFileRewriter,
        fileSystem: mockFileSystem,
      });

      vi.mocked(findMarkdownFiles).mockResolvedValue(["/test/file1.md"]);
      vi.mocked(mockFileSystem.readFile).mockResolvedValue("content");
      vi.mocked(inspectFile).mockReturnValue({
        format: MetadataFormat.None,
        metadata: "",
        content: "content",
        lineBreakType: "\n",
      });

      // Execute
      await orchestrator.run();

      // Verify progress callback was never called
      expect(mockOnProgress).not.toHaveBeenCalled();
    });
  });
});
