import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { readFile } from "fs/promises";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
} from "./integrationTestUtils";

describe("Integration Tests - CLI Integration", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("shows help when no arguments provided", async () => {
    const result = await runCli([], workspace);

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("Usage:");
  });

  test("shows help with --help flag", async () => {
    const result = await runCli(["--help"], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("Usage:");
    expect(result.stdout).toContain("Options:");
  });

  test("processes single file", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([filePath], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("1 file processed");

    const content = await readFile(filePath, "utf-8");
    expect(content).toContain("---\n");
  });

  test("processes multiple files", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    await createFixtureFile(workspace.path, "legacy-basic-tenet.md");

    const result = await runCli([
      join(workspace.path, "legacy-basic-binding.md"),
      join(workspace.path, "legacy-basic-tenet.md"),
    ], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("2 files processed");
  });

  test("processes directory recursively", async () => {
    // Create nested structure
    const subPath = join(workspace.path, "sub");
    await workspace.mkdir(subPath);

    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    await createFixtureFile(subPath, "legacy-basic-tenet.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("2 files processed");
  });

  test("dry-run mode output", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([workspace.path, "--dry-run"], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("[DRY RUN]");
    expect(result.stdout).toContain("Would process");
    expect(result.stdout).toContain("legacy-basic-binding.md");
  });

  test("progress reporting", async () => {
    // Create multiple files to see progress
    for (let i = 0; i < 5; i++) {
      await createFixtureFile(workspace.path, "legacy-basic-binding.md", `file${i}.md`);
    }

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("Processing");
    expect(result.stdout).toContain("5 files processed");
  });

  test("error reporting", async () => {
    // Create a malformed file
    await createFixtureFile(workspace.path, "malformed-invalid-yaml.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0); // Continues despite errors
    expect(result.stderr || result.stdout).toContain("Error");
    expect(result.stderr || result.stdout).toContain("malformed-invalid-yaml.md");
  });

  test("combines multiple path arguments", async () => {
    // Create files in different directories
    const dir1 = join(workspace.path, "dir1");
    const dir2 = join(workspace.path, "dir2");
    await workspace.mkdir(dir1);
    await workspace.mkdir(dir2);

    await createFixtureFile(dir1, "legacy-basic-binding.md");
    await createFixtureFile(dir2, "legacy-basic-tenet.md");
    await createFixtureFile(workspace.path, "legacy-multiline-values.md");

    const result = await runCli([dir1, dir2, join(workspace.path, "legacy-multiline-values.md")], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("3 files processed");
  });

  test("handles mix of files and directories", async () => {
    const subDir = join(workspace.path, "subdir");
    await workspace.mkdir(subDir);

    await createFixtureFile(workspace.path, "file1.md", undefined, "legacy-basic-binding.md");
    await createFixtureFile(subDir, "file2.md", undefined, "legacy-basic-tenet.md");
    await createFixtureFile(workspace.path, "file3.md", undefined, "legacy-multiline-values.md");

    const result = await runCli([
      join(workspace.path, "file1.md"),
      subDir,
      join(workspace.path, "file3.md"),
    ], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("3 files processed");
  });

  test("respects .gitignore patterns", async () => {
    // Create .gitignore
    await workspace.write(".gitignore", "node_modules/\n*.log\n");

    // Create files
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const nodeModulesPath = join(workspace.path, "node_modules");
    await workspace.mkdir(nodeModulesPath);
    await createFixtureFile(nodeModulesPath, "legacy-basic-tenet.md");
    await createFixtureFile(workspace.path, "legacy-multiline-values.md", "test.log");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("1 file processed"); // Only the root file
  });

  test("handles permission errors gracefully", async () => {
    if (process.platform === "win32") {
      // Skip on Windows where permissions work differently
      return;
    }

    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // Remove write permissions
    const { chmod } = await import("fs/promises");
    await chmod(filePath, 0o444);

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toMatch(/permission|EACCES/i);
  });

  test("handles very long paths", async () => {
    // Create deeply nested structure
    let currentPath = workspace.path;
    for (let i = 0; i < 10; i++) {
      currentPath = join(currentPath, `very_long_directory_name_${i}`);
      await workspace.mkdir(currentPath);
    }

    await createFixtureFile(currentPath, "legacy-basic-binding.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("1 file processed");
  });
});
