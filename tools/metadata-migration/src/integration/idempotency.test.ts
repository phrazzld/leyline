import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { readFile } from "fs/promises";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
} from "./integrationTestUtils";

describe("Integration Tests - Idempotency", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("running migration twice produces identical results", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // First run
    const result1 = await runCli([workspace.path], workspace);
    expect(result1.exitCode).toBe(0);
    const content1 = await readFile(filePath, "utf-8");

    // Second run
    const result2 = await runCli([workspace.path], workspace);
    expect(result2.exitCode).toBe(0);
    const content2 = await readFile(filePath, "utf-8");

    expect(content2).toBe(content1);
    expect(result2.stdout).toContain("0 files"); // No files should need processing
  });

  test("handles already-migrated YAML files", async () => {
    await createFixtureFile(workspace.path, "yaml-basic-binding.md");
    const filePath = join(workspace.path, "yaml-basic-binding.md");
    const originalContent = await readFile(filePath, "utf-8");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("0 files"); // Should skip YAML files

    const newContent = await readFile(filePath, "utf-8");
    expect(newContent).toBe(originalContent);
  });

  test("multiple runs on mixed formats", async () => {
    // Create files with different formats
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    await createFixtureFile(workspace.path, "yaml-basic-binding.md", "already-yaml.md");
    await createFixtureFile(workspace.path, "no-metadata-plain.md");

    // First run - should only convert legacy file
    const result1 = await runCli([workspace.path], workspace);
    expect(result1.exitCode).toBe(0);
    expect(result1.stdout).toContain("1 file"); // Only legacy file

    // Second run - should process 0 files
    const result2 = await runCli([workspace.path], workspace);
    expect(result2.exitCode).toBe(0);
    expect(result2.stdout).toContain("0 files");

    // Third run - still 0 files
    const result3 = await runCli([workspace.path], workspace);
    expect(result3.exitCode).toBe(0);
    expect(result3.stdout).toContain("0 files");

    // Verify all files remain unchanged after multiple runs
    const legacyContent1 = await readFile(join(workspace.path, "legacy-basic-binding.md"), "utf-8");
    const yamlContent1 = await readFile(join(workspace.path, "already-yaml.md"), "utf-8");
    const plainContent1 = await readFile(join(workspace.path, "no-metadata-plain.md"), "utf-8");

    // Fourth run for final verification
    await runCli([workspace.path], workspace);

    const legacyContent2 = await readFile(join(workspace.path, "legacy-basic-binding.md"), "utf-8");
    const yamlContent2 = await readFile(join(workspace.path, "already-yaml.md"), "utf-8");
    const plainContent2 = await readFile(join(workspace.path, "no-metadata-plain.md"), "utf-8");

    expect(legacyContent2).toBe(legacyContent1);
    expect(yamlContent2).toBe(yamlContent1);
    expect(plainContent2).toBe(plainContent1);
  });

  test("dry-run doesn't affect subsequent runs", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");
    const originalContent = await readFile(filePath, "utf-8");

    // Dry run first
    const dryResult = await runCli([workspace.path, "--dry-run"], workspace);
    expect(dryResult.exitCode).toBe(0);

    // Content should be unchanged
    const afterDryContent = await readFile(filePath, "utf-8");
    expect(afterDryContent).toBe(originalContent);

    // Real run should still process the file
    const realResult = await runCli([workspace.path], workspace);
    expect(realResult.exitCode).toBe(0);
    expect(realResult.stdout).toContain("1 file");

    // Verify conversion happened
    const convertedContent = await readFile(filePath, "utf-8");
    expect(convertedContent).not.toBe(originalContent);
    expect(convertedContent).toContain("---\n");
  });

  test("handles interrupted and resumed processing", async () => {
    // Create multiple files
    const fileNames = ["file1.md", "file2.md", "file3.md"];
    for (const fileName of fileNames) {
      await createFixtureFile(workspace.path, "legacy-basic-binding.md", fileName);
    }

    // First run - process all files
    const result1 = await runCli([workspace.path], workspace);
    expect(result1.exitCode).toBe(0);
    expect(result1.stdout).toContain("3 files");

    // "Corrupt" one file by adding legacy metadata back
    const file2Path = join(workspace.path, "file2.md");
    const legacyContent = await readFile(join(workspace.tmpFixturesPath, "legacy-basic-binding.md"), "utf-8");
    await workspace.write("file2.md", legacyContent);

    // Second run - should only process the "corrupted" file
    const result2 = await runCli([workspace.path], workspace);
    expect(result2.exitCode).toBe(0);
    expect(result2.stdout).toContain("1 file");

    // Third run - everything should be clean
    const result3 = await runCli([workspace.path], workspace);
    expect(result3.exitCode).toBe(0);
    expect(result3.stdout).toContain("0 files");
  });

  test("preserves file metadata through multiple runs", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // Get original file stats
    const { stat } = await import("fs/promises");
    const originalStats = await stat(filePath);
    const originalMode = originalStats.mode;

    // Run migration multiple times
    for (let i = 0; i < 3; i++) {
      await runCli([workspace.path], workspace);
    }

    // Check file mode is preserved (on systems that support it)
    const newStats = await stat(filePath);
    if (process.platform !== "win32") {
      expect(newStats.mode).toBe(originalMode);
    }
  });
});
