/**
 * Structured JSON logger for the metadata migration script.
 * Provides different log levels and outputs JSON-formatted log entries.
 */

/**
 * Enum representing available log levels
 */
export enum LogLevel {
  DEBUG = "DEBUG",
  INFO = "INFO",
  WARN = "WARN",
  ERROR = "ERROR",
}

/**
 * Interface for structured log entries
 */
export interface LogEntry {
  /** ISO timestamp of when the log was created */
  timestamp: string;
  /** Log level */
  level: LogLevel;
  /** Log message */
  message: string;
  /** Optional metadata to include with the log */
  metadata?: Record<string, unknown>;
}

/**
 * Logger class providing structured JSON logging functionality
 */
export class Logger {
  private static instance: Logger;

  /**
   * Private constructor to enforce singleton pattern
   */
  private constructor() {}

  /**
   * Get the singleton logger instance
   */
  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  /**
   * Create a structured log entry
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
   * Output log entry to console
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
   * Log a debug message
   */
  debug(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.DEBUG, message, metadata);
    this.log(entry);
  }

  /**
   * Log an info message
   */
  info(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.INFO, message, metadata);
    this.log(entry);
  }

  /**
   * Log a warning message
   */
  warn(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.WARN, message, metadata);
    this.log(entry);
  }

  /**
   * Log an error message
   */
  error(message: string, metadata?: Record<string, unknown>): void {
    const entry = this.createLogEntry(LogLevel.ERROR, message, metadata);
    this.log(entry);
  }
}

/**
 * Export a singleton instance for convenience
 */
export const logger = Logger.getInstance();
