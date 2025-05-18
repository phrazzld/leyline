import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { readFile, readdir, stat } from "fs/promises";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
} from "./integrationTestUtils";

describe("Integration Tests - Backup Verification", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("creates backups with timestamps", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Check backup directory exists
    const backupPath = join(workspace.path, "backups");
    const backupStat = await stat(backupPath);
    expect(backupStat.isDirectory()).toBe(true);

    // Check for timestamped backup file
    const backupFiles = await readdir(backupPath);
    expect(backupFiles.length).toBeGreaterThan(0);

    // Verify backup filename format
    const backupFile = backupFiles[0];
    expect(backupFile).toMatch(/^legacy-basic-binding\.md\.\d{8}-\d{6}$/);
  });

  test("backup content matches original", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");
    const originalContent = await readFile(filePath, "utf-8");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Find the backup file
    const backupPath = join(workspace.path, "backups");
    const backupFiles = await readdir(backupPath);
    const backupFilePath = join(backupPath, backupFiles[0]);

    // Compare contents
    const backupContent = await readFile(backupFilePath, "utf-8");
    expect(backupContent).toBe(originalContent);
  });

  test("uses custom backup directory", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const customBackupDir = join(workspace.path, "custom-backups");

    const result = await runCli([
      workspace.path,
      "--backup-dir",
      customBackupDir,
    ], workspace);

    expect(result.exitCode).toBe(0);

    // Check custom backup directory
    const backupStat = await stat(customBackupDir);
    expect(backupStat.isDirectory()).toBe(true);

    const backupFiles = await readdir(customBackupDir);
    expect(backupFiles.length).toBeGreaterThan(0);
  });

  test("handles existing backup files", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    // Create an existing backup
    const backupPath = join(workspace.path, "backups");
    await workspace.mkdir(backupPath);
    const existingBackup = "legacy-basic-binding.md.12345678-123456";
    await workspace.write(join("backups", existingBackup), "old backup content");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Should create a new backup with different timestamp
    const backupFiles = await readdir(backupPath);
    expect(backupFiles.length).toBe(2);
    expect(backupFiles).toContain(existingBackup);

    // New backup should have different timestamp
    const newBackup = backupFiles.find(f => f !== existingBackup);
    expect(newBackup).toBeDefined();
    expect(newBackup).not.toBe(existingBackup);
  });

  test("preserves directory structure in backups", async () => {
    // Create nested structure
    const nestedPath = join(workspace.path, "docs", "guides");
    await workspace.mkdir(nestedPath);
    await createFixtureFile(nestedPath, "legacy-basic-binding.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Check backup preserves directory structure
    const backupPath = join(workspace.path, "backups", "docs", "guides");
    const backupStat = await stat(backupPath);
    expect(backupStat.isDirectory()).toBe(true);

    const backupFiles = await readdir(backupPath);
    expect(backupFiles.length).toBe(1);
    expect(backupFiles[0]).toMatch(/^legacy-basic-binding\.md\.\d{8}-\d{6}$/);
  });

  test("no backups in dry-run mode", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([workspace.path, "--dry-run"], workspace);

    expect(result.exitCode).toBe(0);

    // Check no backup directory was created
    try {
      await stat(join(workspace.path, "backups"));
      expect.fail("Backup directory should not exist in dry-run mode");
    } catch (error: any) {
      expect(error.code).toBe("ENOENT");
    }
  });

  test("backup creation doesn't affect idempotency", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    // First run
    const result1 = await runCli([workspace.path], workspace);
    expect(result1.exitCode).toBe(0);

    const backupPath = join(workspace.path, "backups");
    const backupFiles1 = await readdir(backupPath);
    expect(backupFiles1.length).toBe(1);

    // Second run (no files to process)
    const result2 = await runCli([workspace.path], workspace);
    expect(result2.exitCode).toBe(0);
    expect(result2.stdout).toContain("0 files");

    // No new backups should be created
    const backupFiles2 = await readdir(backupPath);
    expect(backupFiles2.length).toBe(1);
    expect(backupFiles2).toEqual(backupFiles1);
  });

  test("handles backup creation errors gracefully", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    // Create a file with the backup directory name to prevent directory creation
    const backupPath = join(workspace.path, "backups");
    await workspace.write("backups", "not a directory");

    const result = await runCli([workspace.path], workspace);

    // Should fail due to backup creation error
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toMatch(/backup/i);
  });

  test("verifies backup integrity", async () => {
    await createFixtureFile(workspace.path, "legacy-special-chars.md");
    const filePath = join(workspace.path, "legacy-special-chars.md");
    const originalContent = await readFile(filePath, "utf-8");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Find backup and verify special characters are preserved
    const backupPath = join(workspace.path, "backups");
    const backupFiles = await readdir(backupPath);
    const backupFilePath = join(backupPath, backupFiles[0]);
    const backupContent = await readFile(backupFilePath, "utf-8");

    expect(backupContent).toBe(originalContent);
    expect(backupContent).toContain("Special chars: @#$%^&*()");

    // Verify the migrated file has proper escaping
    const migratedContent = await readFile(filePath, "utf-8");
    expect(migratedContent).toContain("Special chars: @#$%^&*()");
  });
});
