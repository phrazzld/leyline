import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join, basename } from "path";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
  hasYamlFrontMatter,
  readYamlFile,
} from "./integrationTestUtils.js";
import { promises as fs } from "fs";

describe("Metadata Migration - Success Cases", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  describe("Basic Conversions", () => {
    test.each([
      ["no-any.md", { expectedId: "no-any" }],
      ["simplicity.md", { expectedId: "simplicity" }],
    ])("converts %s correctly", async (fixtureName, expectations) => {
      await createFixtureFile(workspace.path, fixtureName);
      const filePath = join(workspace.path, fixtureName);

      const result = await runCli([workspace.path], workspace);

      expect(result.exitCode).toBe(0);
      expect(await hasYamlFrontMatter(filePath)).toBe(true);

      const { metadata } = await readYamlFile(filePath);
      if ("expectedId" in expectations) {
        expect(metadata.id).toBe(expectations.expectedId);
      }
    });
  });

  describe("YAML Files", () => {
    test("leaves existing YAML files unchanged", async () => {
      await createFixtureFile(workspace.path, "yaml-basic-binding.md");
      const filePath = join(workspace.path, "yaml-basic-binding.md");

      const result = await runCli([workspace.path], workspace);

      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain("0 modified");

      // File should remain unchanged
      expect(await hasYamlFrontMatter(filePath)).toBe(true);
    });
  });

  describe("Multiple File Processing", () => {
    test("processes multiple files in a directory", async () => {
      await createFixtureFile(workspace.path, "no-any.md");
      await createFixtureFile(workspace.path, "simplicity.md");
      await createFixtureFile(workspace.path, "no-metadata-plain.md");

      const result = await runCli([workspace.path], workspace);

      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain("3 files processed");
      expect(result.stdout).toContain("2 modified"); // Only legacy files

      // Verify legacy files were converted
      const file1 = join(workspace.path, "no-any.md");
      const file2 = join(workspace.path, "simplicity.md");
      const file3 = join(workspace.path, "no-metadata-plain.md");

      expect(await hasYamlFrontMatter(file1)).toBe(true);
      expect(await hasYamlFrontMatter(file2)).toBe(true);
      expect(await hasYamlFrontMatter(file3)).toBe(false); // No metadata
    });
  });

  describe("Custom Backup Directory", () => {
    test("creates backups in specified directory", async () => {
      await createFixtureFile(workspace.path, "no-any.md");
      const customBackupDir = join(workspace.path, "my-backups");

      const result = await runCli([
        workspace.path,
        "--backup-dir",
        customBackupDir,
      ], workspace);

      expect(result.exitCode).toBe(0);

      // Check if backup was created
      const files = await fs.readdir(customBackupDir);
      expect(files.length).toBeGreaterThan(0);

      // Find the backup file
      const backupFile = files.find(f => f.startsWith("no-any.md."));
      expect(backupFile).toBeDefined();
      expect(backupFile).toMatch(/no-any\.md\.\d{8}-\d{6}$/);
    });
  });

  describe("Progress Callback", () => {
    test("reports progress correctly", async () => {
      await createFixtureFile(workspace.path, "no-any.md");
      await createFixtureFile(workspace.path, "simplicity.md");

      const progressReports: Array<{ completed: number; total: number }> = [];

      const result = await runCli([workspace.path], workspace, (progress) => {
        progressReports.push({
          completed: progress.processedFiles,
          total: progress.totalFiles,
        });
      });

      expect(result.exitCode).toBe(0);
      expect(progressReports.length).toBeGreaterThan(0);
      expect(progressReports[progressReports.length - 1]).toEqual({
        completed: 2,
        total: 2,
      });
    });
  });

  describe("Edge Cases", () => {
    test("handles empty files", async () => {
      const emptyFile = join(workspace.path, "empty.md");
      await workspace.write("empty.md", "");

      const result = await runCli([workspace.path], workspace);

      expect(result.exitCode).toBe(0);
      const content = await fs.readFile(emptyFile, "utf-8");
      expect(content).toBe(""); // No change to empty files
    });
  });

  describe("Mixed Formats", () => {
    test("handles directory with mixed metadata formats", async () => {
      await createFixtureFile(workspace.path, "yaml-basic-binding.md");
      await createFixtureFile(workspace.path, "no-any.md");
      await createFixtureFile(workspace.path, "no-metadata-plain.md");

      const result = await runCli([workspace.path], workspace);

      expect(result.exitCode).toBe(0);
      expect(result.stdout).toContain("1 modified"); // Only legacy file

      // YAML file should remain unchanged
      const yamlFile = join(workspace.path, "yaml-basic-binding.md");
      expect(await hasYamlFrontMatter(yamlFile)).toBe(true);

      // Legacy file should be converted
      const legacyFile = join(workspace.path, "no-any.md");
      expect(await hasYamlFrontMatter(legacyFile)).toBe(true);

      // Plain file should remain unchanged
      const plainFile = join(workspace.path, "no-metadata-plain.md");
      const plainContent = await fs.readFile(plainFile, "utf-8");
      expect(plainContent).not.toContain("---");
    });
  });
});
