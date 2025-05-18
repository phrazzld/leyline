/**
 * Tests for the dry-run validation script.
 *
 * @remarks
 * These tests validate the validation script's ability to analyze
 * migration tool output and detect expected behaviors.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { validateDryRun } from "./validate-dry-run.js";
import { Logger } from "./logger.js";
import * as childProcess from "child_process";

// Mock child_process
vi.mock("child_process");

describe("validateDryRun", () => {
  let mockSpawn: any;
  let mockChild: any;

  beforeEach(() => {
    vi.clearAllMocks();

    // Mock child process
    mockChild = {
      stdout: { on: vi.fn() },
      stderr: { on: vi.fn() },
      on: vi.fn(),
    };

    mockSpawn = vi.fn().mockReturnValue(mockChild);
    (childProcess.spawn as any) = mockSpawn;
  });

  describe("successful dry-run", () => {
    it("should validate successful dry-run with all format types", async () => {
      // Mock successful execution with structured logs
      const mockOutput = [
        JSON.stringify({ level: "INFO", msg: "Starting metadata migration", dryRun: true }),
        JSON.stringify({ level: "INFO", msg: "Found 5 markdown files to process" }),
        JSON.stringify({ level: "INFO", msg: "File already in YAML format: docs/tenets/example.md" }),
        JSON.stringify({ level: "INFO", msg: "No metadata found in file: docs/bindings/no-meta.md" }),
        JSON.stringify({ level: "INFO", msg: "[DRY RUN] Would rewrite: docs/tenets/legacy.md", format: "legacy-hr" }),
        JSON.stringify({ level: "WARN", msg: "Unknown metadata format in file: docs/tenets/unknown.md" }),
        JSON.stringify({
          level: "INFO",
          msg: "Migration completed",
          summary: {
            totalFiles: 5,
            processedFiles: 5,
            succeededCount: 5,
            failedCount: 0,
            alreadyYamlCount: 1,
            noMetadataCount: 1,
            unknownFormatCount: 1,
            modifiedCount: 1,
            backupsCreated: 0,
            errors: []
          }
        }),
      ].join("\n");

      // Setup mock behavior
      mockChild.stdout.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          setTimeout(() => callback(Buffer.from(mockOutput)), 0);
        }
      });

      mockChild.stderr.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          // No stderr output in successful run
        }
      });

      mockChild.on.mockImplementation((event: string, callback: Function) => {
        if (event === "close") {
          setTimeout(() => callback(0), 10);
        }
      });

      const result = await validateDryRun(["docs/tenets", "docs/bindings"]);

      expect(result.success).toBe(true);
      expect(result.totalFiles).toBe(5);
      expect(result.yamlFiles).toBe(1);
      expect(result.legacyFiles).toBe(2); // 5 - 1 - 1 - 1 = 2
      expect(result.noMetadataFiles).toBe(1);
      expect(result.unknownFiles).toBe(1);
      expect(result.errors).toHaveLength(0);
      expect(result.warnings).toHaveLength(1); // One unknown format warning
    });
  });

  describe("failed dry-run", () => {
    it("should detect errors in log output", async () => {
      const mockOutput = [
        JSON.stringify({ level: "INFO", msg: "Starting metadata migration", dryRun: true }),
        JSON.stringify({ level: "ERROR", msg: "Failed to parse legacy metadata: invalid-file.md" }),
        JSON.stringify({
          level: "INFO",
          msg: "Migration completed",
          summary: {
            totalFiles: 1,
            processedFiles: 1,
            succeededCount: 0,
            failedCount: 1,
            alreadyYamlCount: 0,
            noMetadataCount: 0,
            unknownFormatCount: 0,
            modifiedCount: 0,
            backupsCreated: 0,
            errors: [{ filePath: "invalid-file.md", message: "Failed to parse legacy metadata" }]
          }
        }),
      ].join("\n");

      // Setup mock behavior
      mockChild.stdout.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          setTimeout(() => callback(Buffer.from(mockOutput)), 0);
        }
      });

      mockChild.on.mockImplementation((event: string, callback: Function) => {
        if (event === "close") {
          setTimeout(() => callback(0), 10);
        }
      });

      const result = await validateDryRun(["docs/tenets"]);

      expect(result.success).toBe(false);
      expect(result.errors).toHaveLength(3); // One from summary, one from ERROR log, one from missing dry-run
      expect(result.errors[0]).toContain("invalid-file.md");
    });

    it("should handle migration tool failure", async () => {
      // Mock tool exit with error code
      mockChild.stderr.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          setTimeout(() => callback(Buffer.from("Command failed")), 0);
        }
      });

      mockChild.on.mockImplementation((event: string, callback: Function) => {
        if (event === "close") {
          setTimeout(() => callback(1), 10);
        }
      });

      const result = await validateDryRun(["docs/tenets"]);

      expect(result.success).toBe(false);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0]).toContain("Migration tool exited with code 1");
    });
  });

  describe("edge cases", () => {
    it("should handle missing summary", async () => {
      const mockOutput = [
        JSON.stringify({ level: "INFO", msg: "Starting metadata migration", dryRun: true }),
        JSON.stringify({ level: "INFO", msg: "Processing files..." }),
        // No summary log entry
      ].join("\n");

      // Setup mock behavior
      mockChild.stdout.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          setTimeout(() => callback(Buffer.from(mockOutput)), 0);
        }
      });

      mockChild.on.mockImplementation((event: string, callback: Function) => {
        if (event === "close") {
          setTimeout(() => callback(0), 10);
        }
      });

      const result = await validateDryRun(["docs/tenets"]);

      expect(result.success).toBe(true);
      expect(result.totalFiles).toBe(0);
    });

    it("should handle mixed JSON and non-JSON output", async () => {
      const mockOutput = [
        "Non-JSON startup message",
        JSON.stringify({ level: "INFO", msg: "Starting metadata migration", dryRun: true }),
        "Another non-JSON line",
        JSON.stringify({
          level: "INFO",
          msg: "Migration completed",
          summary: {
            totalFiles: 1,
            processedFiles: 1,
            succeededCount: 1,
            failedCount: 0,
            alreadyYamlCount: 1,
            noMetadataCount: 0,
            unknownFormatCount: 0,
            modifiedCount: 0,
            backupsCreated: 0,
            errors: []
          }
        }),
      ].join("\n");

      // Setup mock behavior
      mockChild.stdout.on.mockImplementation((event: string, callback: Function) => {
        if (event === "data") {
          setTimeout(() => callback(Buffer.from(mockOutput)), 0);
        }
      });

      mockChild.on.mockImplementation((event: string, callback: Function) => {
        if (event === "close") {
          setTimeout(() => callback(0), 10);
        }
      });

      const result = await validateDryRun(["docs/tenets"]);

      expect(result.success).toBe(true);
      expect(result.totalFiles).toBe(1);
    });
  });
});
