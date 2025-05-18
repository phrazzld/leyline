/**
 * Validation script for testing the metadata migration tool in dry-run mode.
 *
 * This script executes the migration tool on actual repository files and analyzes
 * the structured logs to verify expected behavior without making any modifications.
 *
 * @remarks
 * This validation is critical for ensuring the migration tool behaves correctly
 * on real data before performing actual migrations.
 */

import { spawn } from "child_process";
import { Logger } from "./logger.js";
import { MetadataFormat } from "./types.js";

interface LogEntry {
  level: string;
  msg: string;
  [key: string]: any;
}

interface ValidationResult {
  success: boolean;
  totalFiles: number;
  yamlFiles: number;
  legacyFiles: number;
  noMetadataFiles: number;
  unknownFiles: number;
  errors: string[];
  warnings: string[];
}

/**
 * Executes the migration tool in dry-run mode and captures output.
 *
 * @param paths - Array of paths to process
 * @returns Promise resolving to captured log output
 */
async function executeDryRun(paths: string[]): Promise<string> {
  const logger = Logger.getInstance();
  logger.info("Executing migration tool in dry-run mode", { paths });

  return new Promise((resolve, reject) => {
    const args = [...paths, "--dry-run", "--verbose"];
    const child = spawn("node", ["./dist/cli.js", ...args], {
      cwd: process.cwd(),
      env: process.env,
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    child.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    child.on("close", (code) => {
      if (code !== 0) {
        logger.error("Migration tool exited with non-zero code", { code, stderr });
        reject(new Error(`Migration tool exited with code ${code}`));
      } else {
        resolve(stdout + stderr);
      }
    });

    child.on("error", (error) => {
      logger.error("Failed to spawn migration tool", { error: error.message });
      reject(error);
    });
  });
}

/**
 * Parses structured log output into log entries.
 *
 * @param output - Raw log output
 * @returns Array of parsed log entries
 */
function parseLogOutput(output: string): LogEntry[] {
  const logger = Logger.getInstance();
  const entries: LogEntry[] = [];
  const lines = output.split("\n").filter(line => line.trim());

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      entries.push(entry);
    } catch (error) {
      // Skip non-JSON lines
      logger.debug("Skipping non-JSON line", { line });
    }
  }

  return entries;
}

/**
 * Analyzes log entries to validate migration behavior.
 *
 * @param entries - Array of log entries
 * @returns Validation result
 */
function analyzeLogEntries(entries: LogEntry[]): ValidationResult {
  const result: ValidationResult = {
    success: true,
    totalFiles: 0,
    yamlFiles: 0,
    legacyFiles: 0,
    noMetadataFiles: 0,
    unknownFiles: 0,
    errors: [],
    warnings: [],
  };

  // Find summary log entry
  const summaryEntry = entries.find(e =>
    e.msg === "Migration completed" &&
    e.summary
  );

  if (summaryEntry && summaryEntry.summary) {
    const summary = summaryEntry.summary;
    result.totalFiles = summary.totalFiles;
    result.yamlFiles = summary.alreadyYamlCount;
    result.legacyFiles = summary.processedFiles - summary.alreadyYamlCount - summary.noMetadataCount - summary.unknownFormatCount;
    result.noMetadataFiles = summary.noMetadataCount;
    result.unknownFiles = summary.unknownFormatCount;

    // Check for errors
    if (summary.errors && summary.errors.length > 0) {
      result.success = false;
      summary.errors.forEach((error: any) => {
        result.errors.push(`${error.filePath}: ${error.message}`);
      });
    }
  }

  // Analyze individual file processing logs
  const fileProcessingLogs = entries.filter(e =>
    e.msg?.includes("File already in YAML format") ||
    e.msg?.includes("No metadata found in file") ||
    e.msg?.includes("[DRY RUN] Would rewrite") ||
    e.msg?.includes("Unknown metadata format")
  );

  // Look for warnings and errors
  const errorLogs = entries.filter(e => e.level === "ERROR");
  const warningLogs = entries.filter(e => e.level === "WARN");

  errorLogs.forEach(e => {
    if (!result.errors.includes(e.msg)) {
      result.errors.push(e.msg);
    }
  });

  warningLogs.forEach(e => {
    if (!result.warnings.includes(e.msg)) {
      result.warnings.push(e.msg);
    }
  });

  // Validate dry-run behavior
  const dryRunLogs = entries.filter(e => e.msg?.includes("[DRY RUN]"));
  if (dryRunLogs.length === 0 && result.legacyFiles > 0) {
    result.success = false;
    result.errors.push("No dry-run logs found despite legacy files being processed");
  }

  return result;
}

/**
 * Main validation function.
 *
 * @param paths - Paths to validate
 * @returns Promise resolving to validation result
 */
export async function validateDryRun(paths: string[]): Promise<ValidationResult> {
  const logger = Logger.getInstance();

  try {
    logger.info("Starting dry-run validation", { paths });

    // Execute migration in dry-run mode
    const output = await executeDryRun(paths);

    // Parse structured logs
    const logEntries = parseLogOutput(output);
    logger.info(`Parsed ${logEntries.length} log entries`);

    // Analyze logs
    const result = analyzeLogEntries(logEntries);

    // Log results
    logger.info("Validation completed", { result });

    if (result.success) {
      logger.info("✅ Dry-run validation PASSED", {
        totalFiles: result.totalFiles,
        yamlFiles: result.yamlFiles,
        legacyFiles: result.legacyFiles,
        noMetadataFiles: result.noMetadataFiles,
        unknownFiles: result.unknownFiles,
      });
    } else {
      logger.error("❌ Dry-run validation FAILED", {
        errors: result.errors,
        warnings: result.warnings,
      });
    }

    return result;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    logger.error("Validation failed with error", { error: errorMessage });

    return {
      success: false,
      totalFiles: 0,
      yamlFiles: 0,
      legacyFiles: 0,
      noMetadataFiles: 0,
      unknownFiles: 0,
      errors: [errorMessage],
      warnings: [],
    };
  }
}

// If run directly, execute validation
if (import.meta.url === `file://${process.argv[1]}`) {
  const paths = process.argv.slice(2);

  if (paths.length === 0) {
    console.error("Usage: node validate-dry-run.js <path1> [path2] ...");
    process.exit(1);
  }

  validateDryRun(paths)
    .then(result => {
      process.exit(result.success ? 0 : 1);
    })
    .catch(error => {
      console.error("Unexpected error:", error);
      process.exit(1);
    });
}
