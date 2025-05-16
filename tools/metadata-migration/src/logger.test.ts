import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { Logger, LogLevel, logger } from "./logger";

describe("Logger", () => {
  let consoleLogSpy: any;
  let consoleDebugSpy: any;
  let consoleWarnSpy: any;
  let consoleErrorSpy: any;
  let dateNowSpy: any;

  const mockTimestamp = "2025-05-16T12:00:00.000Z";
  const mockDate = new Date(mockTimestamp);

  beforeEach(() => {
    // Mock console methods
    consoleLogSpy = vi.spyOn(console, "log").mockImplementation(() => {});
    consoleDebugSpy = vi.spyOn(console, "debug").mockImplementation(() => {});
    consoleWarnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
    consoleErrorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    // Mock Date to have consistent timestamps
    dateNowSpy = vi
      .spyOn(Date.prototype, "toISOString")
      .mockReturnValue(mockTimestamp);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("singleton pattern", () => {
    it("should return the same instance", () => {
      const instance1 = Logger.getInstance();
      const instance2 = Logger.getInstance();
      expect(instance1).toBe(instance2);
    });

    it("should export a singleton instance", () => {
      expect(logger).toBe(Logger.getInstance());
    });
  });

  describe("log methods", () => {
    it("should log debug messages with correct format", () => {
      logger.debug("Debug message");

      expect(consoleDebugSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleDebugSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.DEBUG,
        message: "Debug message",
      });
    });

    it("should log info messages with correct format", () => {
      logger.info("Info message");

      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.INFO,
        message: "Info message",
      });
    });

    it("should log warning messages with correct format", () => {
      logger.warn("Warning message");

      expect(consoleWarnSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleWarnSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.WARN,
        message: "Warning message",
      });
    });

    it("should log error messages with correct format", () => {
      logger.error("Error message");

      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleErrorSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.ERROR,
        message: "Error message",
      });
    });
  });

  describe("metadata handling", () => {
    it("should include metadata when provided", () => {
      const metadata = { userId: "123", operation: "migration" };
      logger.info("Operation started", metadata);

      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.INFO,
        message: "Operation started",
        metadata: metadata,
      });
    });

    it("should not include metadata field when metadata is empty", () => {
      logger.info("Simple message", {});

      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.INFO,
        message: "Simple message",
      });
    });

    it("should not include metadata field when metadata is undefined", () => {
      logger.info("Simple message");

      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);

      expect(loggedData).toEqual({
        timestamp: mockTimestamp,
        level: LogLevel.INFO,
        message: "Simple message",
      });
    });
  });

  describe("JSON formatting", () => {
    it("should output valid JSON strings", () => {
      logger.info("Test message", {
        number: 42,
        boolean: true,
        nested: { value: "test" },
      });

      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      const loggedString = consoleLogSpy.mock.calls[0][0];

      // Should not throw when parsing
      expect(() => JSON.parse(loggedString)).not.toThrow();

      const parsed = JSON.parse(loggedString);
      expect(parsed.metadata).toEqual({
        number: 42,
        boolean: true,
        nested: { value: "test" },
      });
    });
  });
});
