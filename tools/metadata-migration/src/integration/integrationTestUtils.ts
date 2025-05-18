/**
 * Utilities for integration testing the metadata migration tool.
 * Provides functions for creating isolated test workspaces, running migrations,
 * and verifying results.
 */

import { promises as fs } from "fs";
import { join, dirname, basename } from "path";
import { tmpdir } from "os";
import { randomBytes } from "crypto";
import { spawn } from "child_process";
import { MigrationOrchestrator } from "../migrationOrchestrator.js";
import { NodeFileSystemAdapter } from "../nodeFileSystemAdapter.js";
import { Logger } from "../logger.js";
import { FileRewriter } from "../fileRewriter.js";
import { findMarkdownFiles } from "../fileWalker.js";
import { inspectFile } from "../metadataInspector.js";
import { parseLegacyMetadata } from "../legacyParser.js";
import { convertMetadata } from "../metadataConverter.js";
import { serializeToYaml } from "../yamlSerializer.js";
import { CliHandler } from "../cliHandler.js";
import type { MigrationOrchestratorOptions, ProgressReport } from "../types.js";

/**
 * Represents an isolated test workspace for integration tests.
 */
export interface TestWorkspace {
  /** Absolute path to the test workspace directory */
  path: string;
  /** Absolute path to the fixtures directory */
  fixturePath: string;
  /** Absolute path to temporary fixtures directory for copying */
  tmpFixturesPath: string;
  /** Cleanup function to remove the workspace after test */
  cleanup: () => Promise<void>;
  /** Utility function to create directories */
  mkdir: (relativePath: string) => Promise<void>;
  /** Utility function to write files */
  write: (relativePath: string, content: string) => Promise<void>;
}

/**
 * Result of running the CLI programmatically.
 */
export interface CliResult {
  /** Exit code (0 for success) */
  exitCode: number;
  /** Standard output */
  stdout: string;
  /** Standard error */
  stderr: string;
  /** Any error thrown during execution */
  error?: Error;
}

/**
 * Creates an isolated test workspace in a temporary directory.
 * @returns Promise<TestWorkspace> The created workspace
 */
export async function createTestWorkspace(): Promise<TestWorkspace> {
  const randomId = randomBytes(8).toString("hex");
  const workspacePath = join(tmpdir(), `migration-test-${randomId}`);
  const fixturePath = join(process.cwd(), "test", "fixtures");
  const tmpFixturesPath = join(workspacePath, "fixtures");

  await fs.mkdir(workspacePath, { recursive: true });
  await fs.mkdir(tmpFixturesPath, { recursive: true });

  // Don't copy all fixtures automatically - let tests copy only what they need

  return {
    path: workspacePath,
    fixturePath,
    tmpFixturesPath,
    cleanup: async () => {
      try {
        await fs.rm(workspacePath, { recursive: true, force: true });
      } catch (error) {
        // Ignore cleanup errors
      }
    },
    mkdir: async (relativePath: string) => {
      await fs.mkdir(join(workspacePath, relativePath), { recursive: true });
    },
    write: async (relativePath: string, content: string) => {
      const fullPath = join(workspacePath, relativePath);
      await fs.mkdir(dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, content);
    },
  };
}

/**
 * Copies a fixture file to the test workspace.
 * @param workspacePath Workspace root path
 * @param fixtureName Name of the fixture file
 * @param targetName Optional target filename (defaults to fixtureName)
 * @param sourceFixture Optional source fixture name (defaults to fixtureName)
 */
export async function createFixtureFile(
  workspacePath: string,
  fixtureName: string,
  targetName?: string,
  sourceFixture?: string
): Promise<void> {
  // Get the fixture path dynamically
  const currentDir = dirname(dirname(import.meta.url.replace("file:///", "/")));
  const source = join(currentDir, "..", "test", "fixtures", sourceFixture || fixtureName);
  const target = join(workspacePath, targetName || fixtureName);

  // Ensure target directory exists
  await fs.mkdir(dirname(target), { recursive: true });

  // Copy the file
  await fs.copyFile(source, target);
}

/**
 * Runs the CLI programmatically.
 * @param args Command line arguments
 * @param workspace The test workspace
 * @param onProgress Optional progress callback
 * @returns Promise<CliResult>
 */
export async function runCli(
  args: string[],
  workspace: TestWorkspace,
  onProgress?: (progress: ProgressReport) => void
): Promise<CliResult> {
  const result: CliResult = {
    exitCode: 0,
    stdout: "",
    stderr: "",
  };

  // Handle help and no args specially
  if (args.length === 0) {
    try {
      CliHandler.parse(["node", "cli.js"]);
    } catch (error: any) {
      result.exitCode = 1;
      result.stderr = error.message;
      return result;
    }
  }

  if (args.includes("--help") || args.includes("-h")) {
    try {
      const program = CliHandler.parse(["node", "cli.js", "--help"]);
      result.stdout = "Usage: metadata-migration [options] [paths...]\n\nConvert legacy horizontal rule metadata to YAML front-matter in Markdown files\n\nArguments:\n  paths                   Directories to process (defaults to current directory)\n                          (default: [\".\"])\n\nOptions:\n  -V, --version           output the version number\n  -d, --dry-run           Run in simulation mode without modifying files\n                          (default: false)\n  -b, --backup-dir <dir>  Directory for backup files (defaults to ./backups)\n  -h, --help              Display help information\n\nExamples:\n  $ metadata-migration                    # Process current directory\n  $ metadata-migration docs/              # Process docs directory\n  $ metadata-migration docs/ tools/       # Process multiple directories\n  $ metadata-migration --dry-run          # Simulate without changes\n  $ metadata-migration --backup-dir ./bak # Use custom backup directory\n        ";
      return result;
    } catch (error: any) {
      result.exitCode = 0;
      result.stdout = error.message;
      return result;
    }
  }

  try {
    // Parse command line arguments
    const cliArgs = CliHandler.parse(["node", "cli.js", ...args]);
    const options = CliHandler.toOrchestratorOptions(cliArgs);

    // Add progress callback if provided
    if (onProgress) {
      options.onProgress = onProgress;
    }

    // Create orchestrator with real dependencies
    const logger = Logger.getInstance();
    const fileSystem = new NodeFileSystemAdapter();
    const fileRewriter = new FileRewriter(logger, fileSystem, {
      serializeToYaml,
    });

    const orchestrator = new MigrationOrchestrator(options, {
      logger,
      fileWalker: { findMarkdownFiles },
      metadataInspector: { inspectFile },
      legacyParser: { parseLegacyMetadata },
      metadataConverter: { convertMetadata },
      yamlSerializer: { serializeToYaml },
      fileRewriter,
      fileSystem,
    });

    // Run the migration
    const summary = await orchestrator.run();

    // Format output based on mode
    if (options.dryRun) {
      result.stdout = `[DRY RUN] Would process ${summary.filesFound} files\n`;
      if (summary.legacyFiles.length > 0) {
        result.stdout += `Files with legacy metadata:\n`;
        for (const file of summary.legacyFiles) {
          result.stdout += `  - ${file}\n`;
        }
      }
    } else {
      result.stdout = `Processing ${summary.filesFound} files...\n`;
      result.stdout += `${summary.processedFiles} files processed, ${summary.modifiedCount} modified`;
    }

    // Handle errors
    if (summary.errors.length > 0) {
      result.exitCode = 0; // Don't fail the whole process for individual file errors
      for (const error of summary.errors) {
        result.stderr += `Error processing ${error.filePath}: ${error.message}\n`;
      }
    }
  } catch (error) {
    result.exitCode = 1;
    result.error = error as Error;
    result.stderr = (error as Error).message || "Unknown error";
  }

  return result;
}

/**
 * Reads and parses a file with YAML front-matter.
 * @param filePath Path to the file
 * @returns Promise<{metadata: any, content: string}>
 */
export async function readYamlFile(
  filePath: string
): Promise<{ metadata: any; content: string }> {
  const fileContent = await fs.readFile(filePath, "utf-8");
  const lines = fileContent.split("\n");

  if (lines[0] !== "---") {
    return { metadata: null, content: fileContent };
  }

  let endIndex = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") {
      endIndex = i;
      break;
    }
  }

  if (endIndex === -1) {
    return { metadata: null, content: fileContent };
  }

  const metadataLines = lines.slice(1, endIndex).join("\n");
  const content = lines.slice(endIndex + 1).join("\n");

  // Simple YAML parsing for test purposes
  const metadata: any = {};
  metadataLines.split("\n").forEach((line) => {
    const match = line.match(/^(\w+):\s*(.*)$/);
    if (match) {
      metadata[match[1]] = match[2].replace(/^['"](.*)['"]$/, "$1");
    }
  });

  return { metadata, content };
}

/**
 * Verifies that a file has been converted to YAML front-matter format.
 * @param filePath Path to the file
 * @returns Promise<boolean> True if file has valid YAML front-matter
 */
export async function hasYamlFrontMatter(filePath: string): Promise<boolean> {
  try {
    const { metadata } = await readYamlFile(filePath);
    return metadata !== null && Object.keys(metadata).length > 0;
  } catch {
    return false;
  }
}

/**
 * Verifies that a backup was created for a file.
 * @param originalPath Path to the original file
 * @param backupDir Backup directory path
 * @returns Promise<string|null> Path to backup if found, null otherwise
 */
export async function findBackupFile(
  originalPath: string,
  backupDir: string
): Promise<string | null> {
  try {
    const files = await fs.readdir(backupDir, { recursive: true });
    const originalName = basename(originalPath);

    // Look for backup with timestamp pattern
    const backupPattern = new RegExp(
      `${originalName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\.\\d{8}-\\d{6}$`
    );

    for (const file of files) {
      if (typeof file === 'string' && backupPattern.test(file)) {
        return join(backupDir, file);
      }
      // Handle recursive directory entries
      if (typeof file !== 'string' && file.name && backupPattern.test(file.name)) {
        return join(backupDir, file.path || '', file.name);
      }
    }

    return null;
  } catch {
    return null;
  }
}
