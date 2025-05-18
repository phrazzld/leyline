/**
 * Integration tests for dry-run mode.
 * Verifies that dry-run doesn't modify files but reports what would be changed.
 */

import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { promises as fs } from "fs";
import {
  TestWorkspace,
  createTestWorkspace,
  copyFixture,
  runCli,
  hasYamlFrontMatter,
  findBackupFile,
} from "./integrationTestUtils.js";

describe("Metadata Migration - Dry Run Mode", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("doesn't modify files in dry-run mode", async () => {
    await copyFixture("legacy-basic-binding.md", workspace);
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // Read original content
    const originalContent = await fs.readFile(filePath, "utf-8");

    // Run in dry-run mode
    const result = await runCli([workspace.path, "--dry-run"], workspace);

    expect(result.exitCode).toBe(0);

    // Verify file wasn't modified
    const currentContent = await fs.readFile(filePath, "utf-8");
    expect(currentContent).toBe(originalContent);

    // Verify no YAML front-matter was added
    const hasYaml = await hasYamlFrontMatter(filePath);
    expect(hasYaml).toBe(false);
  });

  test("doesn't create backups in dry-run mode", async () => {
    await copyFixture("legacy-basic-binding.md", workspace);
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // Run in dry-run mode
    const result = await runCli([workspace.path, "--dry-run"], workspace);

    expect(result.exitCode).toBe(0);

    // Verify no backup was created
    const backupPath = await findBackupFile(filePath, join(workspace.path, "backups"));
    expect(backupPath).toBeNull();

    // Check backup directory doesn't exist
    const backupDirExists = await fs.access(join(workspace.path, "backups"))
      .then(() => true)
      .catch(() => false);
    expect(backupDirExists).toBe(false);
  });

  test("reports what would be changed", async () => {
    // Copy multiple fixtures with different formats
    await copyFixture("legacy-basic-binding.md", workspace);
    await copyFixture("yaml-basic-binding.md", workspace);
    await copyFixture("no-metadata-plain.md", workspace);

    // Run in dry-run mode
    const result = await runCli([workspace.path, "--dry-run"], workspace);

    expect(result.exitCode).toBe(0);

    // Should report that it would process files but not actually modify them
    expect(result.stdout).toContain("files processed");

    // All files should remain unchanged
    const legacyHasYaml = await hasYamlFrontMatter(
      join(workspace.path, "legacy-basic-binding.md")
    );
    expect(legacyHasYaml).toBe(false);
  });

  test("handles errors without modifying files", async () => {
    await copyFixture("malformed-invalid-yaml.md", workspace);

    // Run in dry-run mode on malformed file
    const result = await runCli([workspace.path, "--dry-run"], workspace);

    // Should still report the error
    expect(result.exitCode).toBe(1);
    expect(result.stderr).toContain("Error");

    // But shouldn't create any backups
    const backupPath = await findBackupFile(
      join(workspace.path, "malformed-invalid-yaml.md"),
      join(workspace.path, "backups")
    );
    expect(backupPath).toBeNull();
  });

  test("dry-run with custom backup directory", async () => {
    await copyFixture("legacy-basic-binding.md", workspace);
    const customBackupDir = join(workspace.path, "custom-backups");

    // Run in dry-run mode with custom backup directory
    const result = await runCli(
      [workspace.path, "--dry-run", "--backup-dir", customBackupDir],
      workspace
    );

    expect(result.exitCode).toBe(0);

    // Custom backup directory shouldn't be created
    const dirExists = await fs.access(customBackupDir)
      .then(() => true)
      .catch(() => false);
    expect(dirExists).toBe(false);
  });

  describe("Multiple Files", () => {
    test("processes multiple files without modification", async () => {
      const fixtures = [
        "legacy-basic-binding.md",
        "legacy-basic-tenet.md",
        "legacy-multiline-values.md",
      ];

      // Copy fixtures and store original content
      const originalContents = new Map<string, string>();

      for (const fixture of fixtures) {
        await copyFixture(fixture, workspace);
        const filePath = join(workspace.path, fixture);
        const content = await fs.readFile(filePath, "utf-8");
        originalContents.set(fixture, content);
      }

      // Run in dry-run mode
      const result = await runCli([workspace.path, "--dry-run"], workspace);

      expect(result.exitCode).toBe(0);

      // Verify all files remain unchanged
      for (const fixture of fixtures) {
        const filePath = join(workspace.path, fixture);
        const currentContent = await fs.readFile(filePath, "utf-8");
        expect(currentContent).toBe(originalContents.get(fixture));
      }
    });
  });

  describe("Progress Reporting", () => {
    test("reports progress in dry-run mode", async () => {
      await copyFixture("legacy-basic-binding.md", workspace);

      const progressReports: any[] = [];
      const onProgress = (progress: any) => {
        progressReports.push({ ...progress });
      };

      // Run in dry-run mode with progress callback
      const result = await runCli(
        [workspace.path, "--dry-run"],
        workspace,
        onProgress
      );

      expect(result.exitCode).toBe(0);
      expect(progressReports.length).toBeGreaterThan(0);

      // Progress should be reported even in dry-run
      const lastReport = progressReports[progressReports.length - 1];
      expect(lastReport.processedFiles).toBe(1);
    });
  });
});
