/**
 * Core TypeScript interfaces for the metadata migration script.
 * These types define the structure of data throughout the migration process.
 */

/**
 * Enum representing the different metadata formats that can be encountered
 * in markdown files during the migration process.
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
 * Encapsulates both the file's location and its content.
 */
export interface FileContext {
  /** Absolute path to the file */
  path: string;
  /** Raw content of the file */
  content: string;
  /** Whether the file exists on the filesystem */
  exists: boolean;
}

/**
 * Result of inspecting a file's content to determine its metadata format
 * and separate metadata from main content.
 */
export interface InspectedContent {
  /** The detected metadata format */
  format: MetadataFormat;
  /** Raw metadata content (if present) */
  metadata: string;
  /** Main content without metadata */
  content: string;
  /** Type of line breaks used in the file (\n, \r\n, or \r) */
  lineBreakType: string;
}

/**
 * Structure representing the legacy horizontal rule metadata format.
 * This is the source format that needs to be converted to YAML.
 */
export interface LegacyMetadata {
  /** Unique identifier for the document (required) */
  id: string;
  /** Date of last modification in ISO format (required) */
  lastModified: string;
  /** ID of parent tenet for bindings (optional) */
  derivedFrom?: string;
  /** Enforcement mechanism for bindings (optional) */
  enforcedBy?: string;
  /** Applicability context (deprecated field) */
  appliesTo?: string;
  /** Any additional fields that might exist in legacy format */
  [key: string]: string | undefined;
}

/**
 * Standard YAML front-matter format that all documents should use.
 * This is the target format for the migration.
 */
export interface StandardYamlMetadata {
  /** Unique identifier for the document (must match filename without .md) */
  id: string;
  /** Date of last modification in ISO format with single quotes */
  last_modified: string;
  /** ID of parent tenet for bindings */
  derived_from?: string;
  /** Tool, rule, or process that enforces this binding */
  enforced_by?: string;
}

/**
 * Options for configuring the migration process.
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
 */
export interface MigrationSummary {
  /** Total number of files processed */
  totalFiles: number;
  /** Number of successful migrations */
  successCount: number;
  /** Number of failed migrations */
  failureCount: number;
  /** Number of files that were already in YAML format */
  alreadyYamlCount: number;
  /** Number of files with no metadata */
  noMetadataCount: number;
  /** Number of files that were modified */
  modifiedCount: number;
  /** Number of backups created */
  backupsCreated: number;
  /** List of errors encountered */
  errors: Array<{ filePath: string; error: string }>;
}
