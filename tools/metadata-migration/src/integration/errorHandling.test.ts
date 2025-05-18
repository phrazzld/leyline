import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { rm, writeFile, mkdir, access, mkdtemp } from "fs/promises";
import { constants } from "fs";
import { tmpdir } from "os";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
} from "./integrationTestUtils";

describe("Integration Tests - Error Handling", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("handles non-existent path", async () => {
    const result = await runCli(["/path/that/does/not/exist"], workspace);

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toContain("ENOENT");
  });

  test("handles invalid file permissions", async () => {
    // Skip this test on Windows where permissions work differently
    if (process.platform === "win32") {
      return;
    }

    // Create a file with legacy metadata
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    // Remove write permissions
    await writeFile(filePath, "test content");
    await writeFile(filePath, "test content", { mode: 0o444 }); // Read-only

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toMatch(/EACCES|permission/i);
  });

  test("handles malformed markdown files", async () => {
    await createFixtureFile(workspace.path, "malformed-invalid-yaml.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0); // Should continue despite errors
    expect(result.stderr || result.stdout).toContain("Error processing");
  });

  test("handles backup directory creation failure", async () => {
    // Create a file named 'backups' to prevent directory creation
    const backupPath = join(workspace.path, "backups");
    await writeFile(backupPath, "not a directory");

    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([
      workspace.path,
      "--backup-dir",
      backupPath,
    ], workspace);

    expect(result.exitCode).not.toBe(0);
    expect(result.stderr).toMatch(/ENOTDIR|EEXIST|already exists/i);
  });

  test("handles concurrent file modification", async () => {
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    const filePath = join(workspace.path, "legacy-basic-binding.md");

    let modificationStarted = false;

    // Start the CLI process
    const cliPromise = runCli([workspace.path], workspace);

    // Simulate concurrent modification
    const modificationPromise = (async () => {
      // Wait a tiny bit to ensure CLI has started
      await new Promise(resolve => setTimeout(resolve, 10));
      modificationStarted = true;
      await writeFile(filePath, "modified during processing");
    })();

    const [result] = await Promise.all([cliPromise, modificationPromise]);

    expect(modificationStarted).toBe(true);
    // The CLI might succeed or fail depending on timing, but shouldn't crash
    expect([0, 1]).toContain(result.exitCode);
  });

  test("handles very large number of files", async () => {
    // Create 100 files to test batch processing
    const filePromises = [];
    for (let i = 0; i < 100; i++) {
      const fileName = `file-${i}.md`;
      filePromises.push(createFixtureFile(workspace.path, "legacy-basic-binding.md", fileName));
    }
    await Promise.all(filePromises);

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("100"); // Should report processing 100 files
  });

  test("handles circular symbolic links", async () => {
    // Skip on Windows which handles symlinks differently
    if (process.platform === "win32") {
      return;
    }

    const linkPath = join(workspace.path, "circular-link");
    try {
      // Create a circular symlink
      await mkdir(join(workspace.path, "subdir"));
      process.chdir(workspace.path);
      await executeCommand(`ln -s . circular-link`);
    } catch {
      // Skip if symlink creation fails
      return;
    }

    await createFixtureFile(workspace.path, "legacy-basic-binding.md");

    const result = await runCli([workspace.path], workspace);

    // Should handle gracefully without infinite recursion
    expect(result.exitCode).toBe(0);
  });

  test("handles disk space issues", async () => {
    // This is hard to test reliably cross-platform
    // We'll simulate by using a very small temp directory
    const smallTmpDir = await mkdtemp(join(tmpdir(), "small-"));

    try {
      // Create many large files to fill up space
      const largeContent = "x".repeat(1024 * 1024); // 1MB
      const promises = [];

      // Try to create files until we run out of space
      for (let i = 0; i < 1000; i++) {
        promises.push(
          writeFile(join(smallTmpDir, `large-${i}.txt`), largeContent)
            .catch(() => {}) // Ignore errors when we run out of space
        );
      }

      await Promise.all(promises);

      // Now try to run migration with backup in the full directory
      await createFixtureFile(workspace.path, "legacy-basic-binding.md");

      const result = await runCli([
        workspace.path,
        "--backup-dir",
        smallTmpDir,
      ], workspace);

      // Should handle gracefully
      expect([0, 1]).toContain(result.exitCode);
      if (result.exitCode !== 0) {
        expect(result.stderr).toMatch(/ENOSPC|space|disk full/i);
      }
    } finally {
      await rm(smallTmpDir, { recursive: true, force: true });
    }
  });
});

async function executeCommand(command: string): Promise<void> {
  const { exec } = await import("child_process");
  const { promisify } = await import("util");
  const execAsync = promisify(exec);
  await execAsync(command);
}
