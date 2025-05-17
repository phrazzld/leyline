#!/usr/bin/env node
/**
 * Command-line interface entry point for the metadata migration tool.
 */

import { CliHandler } from "./cliHandler.js";
import { MigrationOrchestrator } from "./migrationOrchestrator.js";
import { NodeFileSystem } from "./nodeFileSystem.js";
import { Logger } from "./logger.js";
import { FileRewriter } from "./fileRewriter.js";
import { findMarkdownFiles } from "./fileWalker.js";
import { inspectFile } from "./metadataInspector.js";
import { parseLegacyMetadata } from "./legacyParser.js";
import { convertMetadata } from "./metadataConverter.js";
import { serializeToYaml } from "./yamlSerializer.js";

const logger = Logger.getInstance();

async function main(): Promise<void> {
  try {
    // Parse command-line arguments
    const cliArgs = CliHandler.parse(process.argv);
    const options = CliHandler.toOrchestratorOptions(cliArgs);

    // Initialize file system adapter and dependencies
    const fileSystem = new NodeFileSystem();
    const fileRewriter = new FileRewriter(logger, fileSystem, {
      serializeToYaml,
    });

    // Create orchestrator with all dependencies
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
    logger.info("Starting metadata migration", { options });
    const summary = await orchestrator.run();

    // Report results
    logger.info("Migration completed", { summary });

    if (summary.errors.length > 0) {
      process.exit(1);
    }
  } catch (error) {
    logger.error("Fatal error during migration", { error });
    process.exit(1);
  }
}

// Run the CLI if this file is executed directly
if (require.main === module) {
  main();
}
