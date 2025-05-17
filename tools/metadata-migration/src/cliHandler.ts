import { Command } from "commander";
import { MigrationOrchestratorOptions } from "./types.js";

/**
 * Parsed CLI arguments for the metadata migration tool.
 */
export interface CliArguments {
  paths: string[];
  dryRun: boolean;
  backupDir?: string;
}

/**
 * Handles command-line interface parsing for the metadata migration tool.
 */
export class CliHandler {
  /**
   * Parses command-line arguments and returns structured options.
   * @param argv - Command-line arguments (typically process.argv)
   * @returns Parsed and validated CLI arguments
   */
  public static parse(argv: string[]): CliArguments {
    const program = new Command();

    program
      .name("metadata-migration")
      .description(
        "Convert legacy horizontal rule metadata to YAML front-matter in Markdown files",
      )
      .version("1.0.0")
      .argument(
        "[paths...]",
        "Directories to process (defaults to current directory)",
        ["."],
      )
      .option(
        "-d, --dry-run",
        "Run in simulation mode without modifying files",
        false,
      )
      .option(
        "-b, --backup-dir <dir>",
        "Directory for backup files (defaults to ./backups)",
      )
      .helpOption("-h, --help", "Display help information")
      .addHelpText(
        "after",
        `
Examples:
  $ metadata-migration                    # Process current directory
  $ metadata-migration docs/              # Process docs directory
  $ metadata-migration docs/ tools/       # Process multiple directories
  $ metadata-migration --dry-run          # Simulate without changes
  $ metadata-migration --backup-dir ./bak # Use custom backup directory
        `,
      );

    const options = program.parse(argv);
    const paths = program.args.length > 0 ? program.args : ["."];
    const parsedOptions = options.opts();

    return {
      paths,
      dryRun: parsedOptions.dryRun || false,
      backupDir: parsedOptions.backupDir,
    };
  }

  /**
   * Converts CLI arguments to MigrationOrchestratorOptions.
   * @param args - Parsed CLI arguments
   * @returns Options suitable for MigrationOrchestrator
   */
  public static toOrchestratorOptions(
    args: CliArguments,
  ): MigrationOrchestratorOptions {
    return {
      paths: args.paths,
      dryRun: args.dryRun,
      backupDir: args.backupDir,
    };
  }
}
