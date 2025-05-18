/**
 * Standalone script to run dry-run validation on the actual repository.
 *
 * @remarks
 * This script executes the validation against real Leyline docs directories
 * and provides a comprehensive report of the migration tool's behavior.
 */

import { validateDryRun } from "./validate-dry-run.js";
import { Logger } from "./logger.js";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

/**
 * Checks git status to ensure no uncommitted changes exist.
 *
 * @param paths - Paths to check
 * @returns True if working directory is clean
 */
function checkGitStatus(paths: string[]): boolean {
  const logger = Logger.getInstance();

  try {
    // Get git status for specific paths
    const gitStatus = execSync(`git status --porcelain ${paths.join(" ")}`, {
      encoding: "utf-8",
      cwd: process.cwd()
    });

    if (gitStatus.trim()) {
      logger.warn("Uncommitted changes detected", {
        changes: gitStatus.trim().split("\n")
      });
      return false;
    }

    return true;
  } catch (error) {
    logger.error("Failed to check git status", {
      error: error instanceof Error ? error.message : String(error)
    });
    return false;
  }
}

/**
 * Creates checksums of all files in specified paths.
 *
 * @param paths - Paths to checksum
 * @returns Map of file paths to checksums
 */
function createChecksums(paths: string[]): Map<string, string> {
  const logger = Logger.getInstance();
  const checksums = new Map<string, string>();

  try {
    const fileList = execSync(`find ${paths.join(" ")} -name "*.md" -type f`, {
      encoding: "utf-8",
      cwd: process.cwd()
    }).trim().split("\n");

    for (const file of fileList) {
      if (file) {
        const checksum = execSync(`shasum -a 256 "${file}"`, {
          encoding: "utf-8",
          cwd: process.cwd()
        }).split(" ")[0];

        checksums.set(file, checksum);
      }
    }

    logger.info(`Created checksums for ${checksums.size} files`);
  } catch (error) {
    logger.error("Failed to create checksums", {
      error: error instanceof Error ? error.message : String(error)
    });
  }

  return checksums;
}

/**
 * Verifies that checksums haven't changed.
 *
 * @param before - Checksums before operation
 * @param after - Checksums after operation
 * @returns Array of changed files
 */
function verifyChecksums(
  before: Map<string, string>,
  after: Map<string, string>
): string[] {
  const changed: string[] = [];

  for (const [file, checksum] of before) {
    if (after.get(file) !== checksum) {
      changed.push(file);
    }
  }

  for (const file of after.keys()) {
    if (!before.has(file)) {
      changed.push(file);
    }
  }

  return changed;
}

/**
 * Main validation runner.
 */
async function main() {
  const logger = Logger.getInstance();
  const targetPaths = ["../../docs/tenets", "../../docs/bindings"];

  logger.info("=== Starting Dry-Run Validation ===");
  logger.info("Target paths:", { paths: targetPaths });

  // Resolve absolute paths
  const absolutePaths = targetPaths.map(p =>
    path.resolve(process.cwd(), p)
  );

  // Verify paths exist
  for (const targetPath of absolutePaths) {
    if (!fs.existsSync(targetPath)) {
      logger.error(`Path does not exist: ${targetPath}`);
      process.exit(1);
    }
  }

  // Check git status
  logger.info("Checking git status...");
  if (!checkGitStatus(absolutePaths)) {
    logger.error("Working directory is not clean. Please commit or stash changes.");
    process.exit(1);
  }

  // Create checksums before dry-run
  logger.info("Creating file checksums...");
  const checksumsBefore = createChecksums(absolutePaths);

  // Run validation
  logger.info("Executing dry-run validation...");
  const result = await validateDryRun(absolutePaths);

  // Create checksums after dry-run
  logger.info("Verifying file integrity...");
  const checksumsAfter = createChecksums(absolutePaths);

  // Verify no files changed
  const changedFiles = verifyChecksums(checksumsBefore, checksumsAfter);
  if (changedFiles.length > 0) {
    logger.error("FILES WERE MODIFIED DURING DRY-RUN!", {
      changedFiles
    });
    result.success = false;
    result.errors.push(`${changedFiles.length} files were modified during dry-run`);
  }

  // Print final report
  logger.info("=== Validation Report ===");
  logger.info("Status:", { success: result.success ? "PASSED ✅" : "FAILED ❌" });
  logger.info("File Statistics:", {
    total: result.totalFiles,
    yaml: result.yamlFiles,
    legacy: result.legacyFiles,
    noMetadata: result.noMetadataFiles,
    unknown: result.unknownFiles
  });

  if (result.warnings.length > 0) {
    logger.warn("Warnings:", { warnings: result.warnings });
  }

  if (result.errors.length > 0) {
    logger.error("Errors:", { errors: result.errors });
  }

  // Check backup directory
  const backupDirs = absolutePaths.map(p => path.join(p, ".metadata-backup"));
  const createdBackups = backupDirs.filter(d => fs.existsSync(d));
  if (createdBackups.length > 0) {
    logger.error("Backup directories were created during dry-run!", {
      backupDirs: createdBackups
    });
    result.success = false;
  }

  // Final summary
  logger.info("=== Summary ===");
  if (result.success) {
    logger.info("✅ Dry-run validation completed successfully!");
    logger.info("The migration tool correctly processed all files without modifications.");
  } else {
    logger.error("❌ Dry-run validation failed!");
    logger.error("Please review the errors above before proceeding with actual migration.");
  }

  process.exit(result.success ? 0 : 1);
}

// Run validation
main().catch(error => {
  console.error("Unexpected error:", error);
  process.exit(1);
});
