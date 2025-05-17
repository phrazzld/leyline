/**
 * MigrationOrchestrator module for coordinating the metadata migration workflow.
 * Orchestrates the sequential processing of files through the migration pipeline.
 */

import {
  MigrationOrchestratorOptions,
  MigrationSummary,
  FileProcessingResult,
  IFileSystemAdapter,
  MetadataFormat,
  InspectedContent,
} from "./types.js";
import { Logger } from "./logger.js";
import { FileRewriter } from "./fileRewriter.js";
import { findMarkdownFiles } from "./fileWalker.js";
import { inspectFile } from "./metadataInspector.js";
import { parseLegacyMetadata } from "./legacyParser.js";
import { convertMetadata } from "./metadataConverter.js";
import { serializeToYaml } from "./yamlSerializer.js";

/**
 * Orchestrates the metadata migration workflow.
 * Coordinates all modules to process files sequentially.
 */
export class MigrationOrchestrator {
  private readonly options: MigrationOrchestratorOptions;
  private readonly logger: Logger;
  private readonly fileWalker: { findMarkdownFiles: typeof findMarkdownFiles };
  private readonly metadataInspector: { inspectFile: typeof inspectFile };
  private readonly legacyParser: {
    parseLegacyMetadata: typeof parseLegacyMetadata;
  };
  private readonly metadataConverter: {
    convertMetadata: typeof convertMetadata;
  };
  private readonly yamlSerializer: { serializeToYaml: typeof serializeToYaml };
  private readonly fileRewriter: FileRewriter;
  private readonly fileSystem: IFileSystemAdapter;

  /**
   * Creates a new MigrationOrchestrator instance.
   * @param options Configuration options for the migration
   * @param dependencies All required module dependencies
   */
  constructor(
    options: MigrationOrchestratorOptions,
    dependencies: {
      logger: Logger;
      fileWalker: { findMarkdownFiles: typeof findMarkdownFiles };
      metadataInspector: { inspectFile: typeof inspectFile };
      legacyParser: { parseLegacyMetadata: typeof parseLegacyMetadata };
      metadataConverter: { convertMetadata: typeof convertMetadata };
      yamlSerializer: { serializeToYaml: typeof serializeToYaml };
      fileRewriter: FileRewriter;
      fileSystem: IFileSystemAdapter;
    },
  ) {
    this.options = options;
    this.logger = dependencies.logger;
    this.fileWalker = dependencies.fileWalker;
    this.metadataInspector = dependencies.metadataInspector;
    this.legacyParser = dependencies.legacyParser;
    this.metadataConverter = dependencies.metadataConverter;
    this.yamlSerializer = dependencies.yamlSerializer;
    this.fileRewriter = dependencies.fileRewriter;
    this.fileSystem = dependencies.fileSystem;
  }

  /**
   * Runs the migration process on all configured paths.
   * @returns Migration summary with statistics and errors
   */
  async run(): Promise<MigrationSummary> {
    // Initialize summary
    const summary: MigrationSummary = {
      totalFiles: 0,
      processedFiles: 0,
      succeededCount: 0,
      failedCount: 0,
      alreadyYamlCount: 0,
      noMetadataCount: 0,
      unknownFormatCount: 0,
      modifiedCount: 0,
      backupsCreated: 0,
      errors: [],
    };

    this.logger.info("Starting metadata migration", {
      paths: this.options.paths,
      dryRun: this.options.dryRun,
      backupDir: this.options.backupDir,
    });

    // Find all markdown files
    let files: string[] = [];
    try {
      files = await this.fileWalker.findMarkdownFiles(this.options.paths);
      summary.totalFiles = files.length;
      this.logger.info(`Found ${files.length} markdown files to process`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error("Failed to find markdown files", {
        error: errorMessage,
      });
      summary.errors.push({
        filePath: "",
        message: `Failed to find files: ${errorMessage}`,
      });
      return summary;
    }

    // Process files sequentially
    for (let i = 0; i < files.length; i++) {
      const filePath = files[i];

      // Report progress (before processing)
      if (this.options.onProgress) {
        this.options.onProgress({
          totalFiles: files.length,
          processedFiles: i,
          currentFilePath: filePath,
          status: "processing",
        });
      }

      // Process single file
      const result = await this._processSingleFile(filePath);
      summary.processedFiles++;

      // Update summary based on result
      if (result.success) {
        summary.succeededCount++;
      } else {
        summary.failedCount++;
        summary.errors.push({
          filePath: result.filePath,
          message: result.error || "Unknown error",
        });
      }

      if (result.modified) {
        summary.modifiedCount++;
      }

      if (result.backupPath) {
        summary.backupsCreated++;
      }

      // Update format counts
      switch (result.originalFormat) {
        case MetadataFormat.Yaml:
          summary.alreadyYamlCount++;
          break;
        case MetadataFormat.None:
          summary.noMetadataCount++;
          break;
        case MetadataFormat.Unknown:
          summary.unknownFormatCount++;
          break;
      }

      // Report progress (after processing)
      if (this.options.onProgress) {
        this.options.onProgress({
          totalFiles: files.length,
          processedFiles: i + 1,
          currentFilePath: filePath,
          status: result.success ? "completed" : "failed",
        });
      }
    }

    this.logger.info("Migration completed", { summary });
    return summary;
  }

  /**
   * Processes a single file through the migration pipeline.
   * @param filePath Path to the file to process
   * @returns Processing result with success status and details
   */
  private async _processSingleFile(
    filePath: string,
  ): Promise<FileProcessingResult> {
    const result: FileProcessingResult = {
      filePath,
      success: false,
      modified: false,
      originalFormat: MetadataFormat.None,
    };

    try {
      // Read file
      let content: string;
      try {
        content = await this.fileSystem.readFile(filePath);
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        this.logger.error(`Failed to read file: ${filePath}`, {
          error: errorMessage,
        });
        result.error = `Failed to read file: ${errorMessage}`;
        return result;
      }

      // Inspect metadata
      const inspected = this.metadataInspector.inspectFile({
        path: filePath,
        content,
        exists: true,
      });
      result.originalFormat = inspected.format;

      // Process based on format
      switch (inspected.format) {
        case MetadataFormat.LegacyHr:
          return await this._processLegacyFile(
            filePath,
            content,
            inspected,
            result,
          );

        case MetadataFormat.Yaml:
          this.logger.info(`File already in YAML format: ${filePath}`);
          result.success = true;
          result.modified = false;
          return result;

        case MetadataFormat.None:
          this.logger.info(`No metadata found in file: ${filePath}`);
          result.success = true;
          result.modified = false;
          return result;

        case MetadataFormat.Unknown:
          this.logger.warn(`Unknown metadata format in file: ${filePath}`);
          result.success = false;
          result.error = "Unknown metadata format";
          result.modified = false;
          return result;

        default:
          // Should never happen, but TypeScript exhaustiveness check
          const _exhaustive: never = inspected.format;
          throw new Error(`Unhandled metadata format: ${_exhaustive}`);
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(`Unexpected error processing file: ${filePath}`, {
        error: errorMessage,
      });
      result.error = `Unexpected error: ${errorMessage}`;
      return result;
    }
  }

  /**
   * Processes a file with legacy metadata format.
   * @param filePath Path to the file
   * @param content File content
   * @param inspected Inspection result
   * @param result Processing result object to update
   * @returns Updated processing result
   */
  private async _processLegacyFile(
    filePath: string,
    _content: string,
    inspected: InspectedContent,
    result: FileProcessingResult,
  ): Promise<FileProcessingResult> {
    // Parse legacy metadata
    const parseOutput = this.legacyParser.parseLegacyMetadata(
      inspected.metadata,
    );
    if (!parseOutput.metadata || parseOutput.errors.length > 0) {
      const errorMessage = parseOutput.errors.map((e) => e.message).join("; ");
      this.logger.error(`Failed to parse legacy metadata: ${filePath}`, {
        errors: parseOutput.errors,
      });
      result.error = `Failed to parse legacy metadata: ${errorMessage}`;
      return result;
    }

    // Convert metadata
    const filename = filePath.split("/").pop() || filePath;
    const convertOutput = this.metadataConverter.convertMetadata(
      parseOutput.metadata,
      { filename },
    );
    if (!convertOutput.success || !convertOutput.data) {
      const errorMessage =
        "errors" in convertOutput
          ? convertOutput.errors.map((e: any) => e.message).join("; ")
          : "Unknown conversion error";
      this.logger.error(`Failed to convert metadata: ${filePath}`, {
        errors: "errors" in convertOutput ? convertOutput.errors : [],
      });
      result.error = `Failed to convert metadata: ${errorMessage}`;
      return result;
    }

    // Serialize to YAML (unused but needed for validation)
    this.yamlSerializer.serializeToYaml(convertOutput.data);

    // Mark as modified
    result.modified = true;

    // Handle dry-run vs actual write
    if (this.options.dryRun) {
      this.logger.info(`[DRY RUN] Would rewrite: ${filePath}`, {
        filePath,
        format: inspected.format,
      });
      result.success = true;
    } else {
      // Rewrite file
      const rewriteResult = await this.fileRewriter.rewriteFile(
        filePath,
        convertOutput.data,
        inspected,
        { backupDirectory: this.options.backupDir },
      );

      result.success = rewriteResult.success;
      result.backupPath = rewriteResult.backupPath;

      if (!rewriteResult.success) {
        result.error = rewriteResult.error?.message || "Failed to rewrite file";
        this.logger.error(`Failed to rewrite file: ${filePath}`, {
          error: rewriteResult.error,
        });
      }
    }

    return result;
  }
}
