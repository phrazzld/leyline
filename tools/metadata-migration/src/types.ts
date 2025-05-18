/**
 * Core type definitions for the metadata migration tool.
 *
 * This module defines the fundamental types used throughout the migration process:
 * - Metadata format detection and classification
 * - File context and processing results
 * - Legacy and standard metadata structures
 * - Migration options and orchestration configuration
 *
 * The type system is designed to be explicit and self-documenting, providing
 * clear contracts for all components in the migration pipeline.
 *
 * @remarks
 * These types serve as the foundation for type safety across the application,
 * ensuring that data flows correctly through the transformation pipeline from
 * legacy horizontal rule format to standard YAML front-matter.
 */

/**
 * Enum representing the different metadata formats that can be encountered
 * in markdown files during the migration process.
 *
 * @remarks
 * The migration tool uses this enum to classify files and determine appropriate
 * processing strategies. Files with `LegacyHr` format will be converted to `Yaml`.
 */
export enum MetadataFormat {
  /** YAML front-matter format (standard target format) */
  Yaml = "yaml",
  /** Legacy horizontal rule format (deprecated source format) */
  LegacyHr = "legacy-hr",
  /** No metadata present in the file */
  None = "none",
  /** Metadata present but in an unrecognized format */
  Unknown = "unknown",
}

/**
 * Represents a file being processed during the metadata migration.
 * Encapsulates both the file's location and its content for efficient processing.
 *
 * @remarks
 * This interface provides a unified view of a file's state, allowing components
 * to access both content and metadata without repeated file system operations.
 */
export interface FileContext {
  /** Absolute path to the file */
  path: string;
  /** Raw content of the file as read from disk */
  content: string;
  /** Whether the file exists on the filesystem */
  exists: boolean;
}

/**
 * Result of inspecting a file's content to determine its metadata format
 * and separate metadata from main content.
 *
 * @remarks
 * The inspection process is crucial for identifying which files need migration
 * and preserving the original content structure during transformation.
 */
export interface InspectedContent {
  /** The detected metadata format */
  format: MetadataFormat;
  /** Raw metadata content (if present) */
  metadata: string;
  /** Main content without metadata */
  content: string;
  /** Type of line breaks used in the file (LF, CRLF, or CR) */
  lineBreakType: string;
}

/**
 * Structure representing the legacy horizontal rule metadata format.
 * This is the source format that needs to be converted to YAML.
 *
 * @remarks
 * Legacy metadata appears at the bottom of files after three underscores.
 * Required fields are `id` and `lastModified`, but files may contain
 * additional fields that vary by document type (tenet vs binding).
 *
 * @example
 * ```
 * # Document Title
 *
 * Content...
 *
 * ___
 * **ID:** example-id
 * **Last-Modified:** 2024-03-15
 * **Derived-From:** parent-tenet
 * ```
 */
export interface LegacyMetadata {
  /**
   * Unique identifier for the document (required)
   * @remarks Must match the filename without .md extension
   */
  id: string;
  /**
   * Date of last modification in ISO format (required)
   * @remarks Expected format: YYYY-MM-DD
   */
  lastModified: string;
  /**
   * ID of parent tenet for bindings (optional)
   * @remarks Only present in binding documents
   */
  derivedFrom?: string;
  /**
   * Enforcement mechanism for bindings (optional)
   * @remarks Describes how the binding is enforced (e.g., "linting", "ci")
   */
  enforcedBy?: string;
  /**
   * Applicability context (deprecated field)
   * @remarks This field is deprecated and will be ignored during migration
   */
  appliesTo?: string;
  /**
   * Index signature for additional fields that might exist in legacy format
   * @remarks Allows for extensibility while maintaining type safety
   */
  [key: string]: string | undefined;
}

/**
 * Standard YAML front-matter format that all documents should use.
 * This is the target format for the migration.
 *
 * @remarks
 * The standard format uses snake_case field names and requires
 * single quotes around date values for YAML compliance.
 *
 * @example
 * ```yaml
 * ---
 * id: example-id
 * last_modified: '2024-03-15'
 * derived_from: parent-tenet
 * ---
 * ```
 */
export interface StandardYamlMetadata {
  /**
   * Unique identifier for the document
   * @remarks Must match filename without .md extension
   */
  id: string;
  /**
   * Date of last modification in ISO format with single quotes
   * @remarks Format: 'YYYY-MM-DD' (quotes included in value)
   */
  last_modified: string;
  /**
   * ID of parent tenet for bindings
   * @remarks Optional field, only present in binding documents
   */
  derived_from?: string;
  /**
   * Tool, rule, or process that enforces this binding
   * @remarks Describes how the binding is enforced programmatically
   */
  enforced_by?: string;
}

/**
 * Options for configuring the migration process.
 * Used by the CLI and orchestration layer to control behavior.
 *
 * @remarks
 * These options allow fine-grained control over the migration process,
 * including safety features like dry-run mode and backup management.
 */
export interface MigrationOptions {
  /** Target paths to process (directories or files) */
  paths: string[];
  /** Whether to run in dry-run mode (no file modifications) */
  dryRun: boolean;
  /** Directory to store backups of modified files */
  backupDir?: string;
  /** Verbosity level for logging */
  verbose: boolean;
}

/**
 * Result of a single file migration operation.
 * Provides detailed information about the outcome of processing each file.
 *
 * @remarks
 * This structure allows for comprehensive reporting and error tracking
 * throughout the migration process.
 */
export interface MigrationResult {
  /** Path of the processed file */
  filePath: string;
  /** Whether the migration was successful */
  success: boolean;
  /** Format before migration */
  originalFormat: MetadataFormat;
  /** Whether the file was actually modified */
  modified: boolean;
  /** Error message if migration failed */
  error?: string;
  /** Path to backup file if created */
  backupPath?: string;
}

/**
 * Summary statistics for the entire migration process.
 * Aggregates results across all processed files for reporting.
 *
 * @remarks
 * This summary provides a comprehensive overview of the migration
 * operation, useful for logging and user feedback.
 */
export interface MigrationSummary {
  /** Total number of files processed */
  totalFiles: number;
  /** Number of files actually processed (attempted) */
  processedFiles: number;
  /** Number of successful migrations */
  succeededCount: number;
  /** Number of failed migrations */
  failedCount: number;
  /** Number of files that were already in YAML format */
  alreadyYamlCount: number;
  /** Number of files with no metadata */
  noMetadataCount: number;
  /** Number of files with unknown metadata format */
  unknownFormatCount: number;
  /** Number of files that were modified */
  modifiedCount: number;
  /** Number of backups created */
  backupsCreated: number;
  /** List of errors encountered */
  errors: Array<{ filePath: string; message: string }>;
}

/**
 * Options for configuring the migration orchestrator.
 * Extended configuration for the main orchestration engine.
 *
 * @remarks
 * Includes optional callbacks for progress reporting, enabling
 * integration with UI or other monitoring systems.
 */
export interface MigrationOrchestratorOptions {
  /** Target paths to process (directories or files) */
  paths: string[];
  /** Whether to run in dry-run mode (no file modifications) */
  dryRun: boolean;
  /** Directory to store backups of modified files */
  backupDir?: string;
  /**
   * Optional progress callback for UI integration
   * @param progress - Current progress information
   */
  onProgress?: (progress: ProgressReport) => void;
}

/**
 * Progress report for tracking migration progress.
 * Used for real-time monitoring of long-running operations.
 *
 * @remarks
 * Enables responsive UI updates and progress bars in CLI tools.
 */
export interface ProgressReport {
  /** Total number of files to process */
  totalFiles: number;
  /** Number of files processed so far */
  processedFiles: number;
  /** Path of the current file being processed */
  currentFilePath: string;
  /** Status of current file processing */
  status: "processing" | "completed" | "failed";
}

/**
 * Result of processing a single file.
 * Similar to MigrationResult but used internally by the orchestrator.
 *
 * @remarks
 * This structure is used for internal communication between
 * orchestration components.
 */
export interface FileProcessingResult {
  /** Path of the processed file */
  filePath: string;
  /** Whether the processing was successful */
  success: boolean;
  /** Whether the file was actually modified */
  modified: boolean;
  /** Format before migration */
  originalFormat: MetadataFormat;
  /** Path to backup file if created */
  backupPath?: string;
  /** Error message if processing failed */
  error?: string;
}

/**
 * Abstraction for file system operations.
 * Allows for dependency injection and testing.
 *
 * @remarks
 * This interface enables unit testing by allowing mock implementations
 * and supports future extensions like virtual file systems.
 */
export interface IFileSystemAdapter {
  /**
   * Read file content as string
   * @param filePath - Path to the file to read
   * @returns Promise resolving to file content
   * @throws Error if file cannot be read
   */
  readFile(filePath: string): Promise<string>;
}

/**
 * Full file system interface for components requiring write access.
 * Extends the basic adapter with write and manipulation operations.
 *
 * @remarks
 * This interface is implemented by NodeFileSystemAdapter for production use
 * and can be mocked for testing.
 */
export interface IFileSystem extends IFileSystemAdapter {
  /**
   * Write content to a file
   * @param filePath - Path to the file to write
   * @param content - Content to write
   * @throws Error if file cannot be written
   */
  writeFile(filePath: string, content: string): Promise<void>;

  /**
   * Copy a file from source to destination
   * @param source - Source file path
   * @param destination - Destination file path
   * @throws Error if copy operation fails
   */
  copyFile(source: string, destination: string): Promise<void>;

  /**
   * Rename or move a file
   * @param oldPath - Current file path
   * @param newPath - New file path
   * @throws Error if rename operation fails
   */
  renameFile(oldPath: string, newPath: string): Promise<void>;

  /**
   * Delete a file
   * @param filePath - Path to the file to delete
   * @throws Error if delete operation fails
   */
  deleteFile(filePath: string): Promise<void>;

  /**
   * Check if a file exists
   * @param filePath - Path to check
   * @returns Promise resolving to true if file exists
   */
  fileExists(filePath: string): Promise<boolean>;

  /**
   * Ensure a directory exists, creating it if necessary
   * @param dirPath - Path to the directory
   * @throws Error if directory cannot be created
   */
  ensureDirectoryExists(dirPath: string): Promise<void>;
}
