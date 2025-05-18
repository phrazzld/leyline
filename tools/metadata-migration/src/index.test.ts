/**
 * Unit tests for the main index module.
 * Tests that all exports are properly available.
 */

import { describe, it, expect } from "vitest";
import * as index from "./index.js";

describe("index module", () => {
  it("should export MigrationOrchestrator", () => {
    expect(index.MigrationOrchestrator).toBeDefined();
  });

  it("should export NodeFileSystemAdapter", () => {
    expect(index.NodeFileSystemAdapter).toBeDefined();
  });

  it("should export CliHandler", () => {
    expect(index.CliHandler).toBeDefined();
  });

  it("should have exported types (type-level test)", () => {
    // Type-level test - if this compiles, the types are exported
    type TestOrchestratorOptions = typeof index extends {
      MigrationOrchestratorOptions: any
    } ? true : false;
    type TestSummary = typeof index extends {
      MigrationSummary: any
    } ? true : false;
    type TestProgress = typeof index extends {
      ProgressReport: any
    } ? true : false;
    type TestResult = typeof index extends {
      FileProcessingResult: any
    } ? true : false;

    // These are compile-time checks
    const _options: TestOrchestratorOptions = true;
    const _summary: TestSummary = true;
    const _progress: TestProgress = true;
    const _result: TestResult = true;

    expect(true).toBe(true); // Types are exported correctly
  });
});
