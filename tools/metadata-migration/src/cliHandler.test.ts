import { describe, it, expect } from "vitest";
import { CliHandler } from "./cliHandler.js";

describe("CliHandler", () => {
  describe("parse", () => {
    it("should parse default arguments", () => {
      const args = CliHandler.parse(["node", "script.js"]);
      expect(args).toEqual({
        paths: ["."],
        dryRun: false,
        backupDir: undefined,
      });
    });

    it("should parse single path argument", () => {
      const args = CliHandler.parse(["node", "script.js", "docs/"]);
      expect(args).toEqual({
        paths: ["docs/"],
        dryRun: false,
        backupDir: undefined,
      });
    });

    it("should parse multiple path arguments", () => {
      const args = CliHandler.parse(["node", "script.js", "docs/", "tools/"]);
      expect(args).toEqual({
        paths: ["docs/", "tools/"],
        dryRun: false,
        backupDir: undefined,
      });
    });

    it("should parse dry-run flag", () => {
      const args = CliHandler.parse(["node", "script.js", "--dry-run"]);
      expect(args).toEqual({
        paths: ["."],
        dryRun: true,
        backupDir: undefined,
      });
    });

    it("should parse backup-dir option", () => {
      const args = CliHandler.parse([
        "node",
        "script.js",
        "--backup-dir",
        "./custom-backup",
      ]);
      expect(args).toEqual({
        paths: ["."],
        dryRun: false,
        backupDir: "./custom-backup",
      });
    });

    it("should parse combined options", () => {
      const args = CliHandler.parse([
        "node",
        "script.js",
        "docs/",
        "--dry-run",
        "--backup-dir",
        "./backup",
      ]);
      expect(args).toEqual({
        paths: ["docs/"],
        dryRun: true,
        backupDir: "./backup",
      });
    });

    it("should parse short options", () => {
      const args = CliHandler.parse([
        "node",
        "script.js",
        "-d",
        "-b",
        "./backup",
      ]);
      expect(args).toEqual({
        paths: ["."],
        dryRun: true,
        backupDir: "./backup",
      });
    });
  });

  describe("toOrchestratorOptions", () => {
    it("should convert CLI arguments to orchestrator options", () => {
      const cliArgs = {
        paths: ["docs/", "tools/"],
        dryRun: true,
        backupDir: "./custom-backup",
      };

      const options = CliHandler.toOrchestratorOptions(cliArgs);
      expect(options).toEqual({
        paths: ["docs/", "tools/"],
        dryRun: true,
        backupDir: "./custom-backup",
      });
    });

    it("should handle minimal arguments", () => {
      const cliArgs = {
        paths: ["."],
        dryRun: false,
      };

      const options = CliHandler.toOrchestratorOptions(cliArgs);
      expect(options).toEqual({
        paths: ["."],
        dryRun: false,
        backupDir: undefined,
      });
    });
  });
});
