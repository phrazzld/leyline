/**
 * Main entry point for the metadata migration tool.
 * Exports the migration orchestrator and related types.
 */

export { MigrationOrchestrator } from "./migrationOrchestrator.js";
export { NodeFileSystemAdapter } from "./nodeFileSystemAdapter.js";
export { CliHandler } from "./cliHandler.js";
export type {
  MigrationOrchestratorOptions,
  MigrationSummary,
  ProgressReport,
  FileProcessingResult,
} from "./types.js";
