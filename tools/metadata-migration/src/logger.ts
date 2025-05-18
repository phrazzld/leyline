/**
 * Structured JSON logger for the metadata migration tool.
 *
 * This module provides a singleton logger that outputs structured JSON logs,
 * making it easy to parse and analyze logs in production environments.
 * The logger supports multiple log levels and optional metadata attachments.
 *
 * @remarks
 * The logger follows a singleton pattern to ensure consistent logging
 * throughout the application. All log entries are formatted as JSON
 * for easy parsing by log aggregation systems.
 *
 * @example
 * ```typescript
 * import { logger } from './logger';
 *
 * logger.info('Processing file', {
 *   filePath: '/path/to/file.md',
 *   format: 'legacy-hr'
 * });
 * ```
 */

/**
 * Enum representing available log levels.
 *
 * @remarks
 * Log levels are ordered by severity, with DEBUG being the least severe
 * and ERROR being the most severe. This ordering allows for log filtering
 * based on minimum severity thresholds.
 */
export enum LogLevel {
  /** Debug-level logging for detailed troubleshooting */
  DEBUG = "DEBUG",
  /** Informational messages about normal operations */
  INFO = "INFO",
  /** Warning messages for potentially problematic situations */
  WARN = "WARN",
  /** Error messages for failures and exceptions */
  ERROR = "ERROR",
}

/**
 * Interface for structured log entries.
 *
 * @remarks
 * Each log entry contains essential information like timestamp and level,
 * along with the message and optional metadata. The structured format
 * ensures consistency and enables efficient log parsing.
 */
export interface LogEntry {
  /** ISO timestamp of when the log was created */
  timestamp: string;
  /** Log level indicating severity */
  level: LogLevel;
  /** Primary log message */
  message: string;
  /** Optional metadata to provide additional context */
  metadata?: Record<string, unknown>;
}

/**
 * Logger class providing structured JSON logging functionality.
 *
 * @remarks
 * Implements the singleton pattern to ensure a single logger instance
 * is used throughout the application. This provides consistent logging
 * behavior and prevents multiple logger instances from interfering
 * with each other.
 */
export class Logger {
  private static instance: Logger;

  /**
   * Private constructor to enforce singleton pattern.
   *
   * @remarks
   * The private constructor prevents direct instantiation of the Logger class.
   * Use `Logger.getInstance()` to get the singleton instance.
   */
  private constructor() {}

  /**
   * Get the singleton logger instance.
   *
   * @returns The singleton Logger instance
   *
   * @example
   * ```typescript
   * const logger = Logger.getInstance();
   * logger.info('Application started');
   * ```
   */
  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  /**
   * Create a structured log entry.
   *
   * @param level - The severity level of the log entry
   * @param message - The primary log message
   * @param metadata - Optional metadata to attach to the log entry
   * @returns A structured LogEntry object
   *
   * @remarks
   * This method ensures consistent log entry structure across all log levels.
   * Empty metadata objects are excluded to keep logs clean.
   */
  private createLogEntry(
    level: LogLevel,
    message: string,
    metadata?: Record<string, unknown>,
  ): LogEntry {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
    };

    if (metadata && Object.keys(metadata).length > 0) {
      entry.metadata = metadata;
    }

    return entry;
  }

  /**
   * Output log entry to console.
   *
   * @param entry - The log entry to output
   *
   * @remarks
   * Routes log entries to appropriate console methods based on severity.
   * All entries are serialized to JSON before output.
   */
  private log(entry: LogEntry): void {
    const output = JSON.stringify(entry);

    switch (entry.level) {
      case LogLevel.ERROR:
        console.error(output);
        break;
      case LogLevel.WARN:
        console.warn(output);
        break;
      case LogLevel.DEBUG:
        console.debug(output);
        break;
      case LogLevel.INFO:
      default:
        console.log(output);
        break;
    }
  }

  /**
   * Log a debug message.
   *
   * @param message - The debug message to log
   * @param metadata - Optional metadata providing additional context
   *
   * @remarks
   * Debug logs are typically used for detailed troubleshooting
   * and are often filtered out in production environments.
   *
   * @example
   * ```typescript
   * logger.debug('Parsing metadata', {
   *   lineCount: 42,
   *   format: 'legacy-hr'
   * });
   * ```
   */
  debug(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.DEBUG, message, metadata);
    this.log(entry);
  }

  /**
   * Log an info message.
   *
   * @param message - The informational message to log
   * @param metadata - Optional metadata providing additional context
   *
   * @remarks
   * Info logs represent normal operational messages that confirm
   * the application is working as expected.
   *
   * @example
   * ```typescript
   * logger.info('Migration completed', {
   *   filesProcessed: 10,
   *   duration: '2.5s'
   * });
   * ```
   */
  info(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.INFO, message, metadata);
    this.log(entry);
  }

  /**
   * Log a warning message.
   *
   * @param message - The warning message to log
   * @param metadata - Optional metadata providing additional context
   *
   * @remarks
   * Warning logs indicate potentially problematic situations that
   * don't prevent the application from functioning but may require attention.
   *
   * @example
   * ```typescript
   * logger.warn('Deprecated field detected', {
   *   field: 'appliesTo',
   *   file: 'example.md'
   * });
   * ```
   */
  warn(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.WARN, message, metadata);
    this.log(entry);
  }

  /**
   * Log an error message.
   *
   * @param message - The error message to log
   * @param metadata - Optional metadata providing additional context
   *
   * @remarks
   * Error logs indicate failures that prevent normal operation.
   * These should include enough context to diagnose the issue.
   *
   * @example
   * ```typescript
   * logger.error('Failed to parse metadata', {
   *   file: 'broken.md',
   *   error: error.message,
   *   line: 42
   * });
   * ```
   */
  error(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.ERROR, message, metadata);
    this.log(entry);
  }
}

/**
 * Export a singleton instance for convenience.
 *
 * @remarks
 * This export provides a ready-to-use logger instance,
 * eliminating the need to call getInstance() in every module.
 *
 * @example
 * ```typescript
 * import { logger } from './logger';
 * logger.info('Application started');
 * ```
 */
export const logger = Logger.getInstance();
