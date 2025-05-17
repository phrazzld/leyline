/**
 * Unit tests for the YamlSerializer module
 */

import { describe, test, expect } from "vitest";
import { serializeToYaml } from "./yamlSerializer.js";
import { StandardYamlMetadata } from "./types.js";
import yaml from "js-yaml";

describe("YamlSerializer", () => {
  describe("serializeToYaml", () => {
    test("serializes minimal metadata", () => {
      const metadata: StandardYamlMetadata = {
        id: "test-binding",
        last_modified: "2025-01-17",
      };

      const result = serializeToYaml(metadata);

      // Verify it's valid YAML
      const parsed = yaml.load(result) as StandardYamlMetadata;
      expect(parsed).toEqual(metadata);

      // Check basic formatting
      expect(result).toContain("id: test-binding");
      expect(result).toContain('last_modified: "2025-01-17"');
    });

    test("serializes complete metadata with all fields", () => {
      const metadata: StandardYamlMetadata = {
        id: "no-any",
        last_modified: "2025-01-17",
        derived_from: "simplicity",
        enforced_by: 'eslint("@typescript-eslint/no-explicit-any")',
      };

      const result = serializeToYaml(metadata);

      // Verify it's valid YAML
      const parsed = yaml.load(result) as StandardYamlMetadata;
      expect(parsed).toEqual(metadata);

      // Check all fields are present
      expect(result).toContain("id: no-any");
      expect(result).toContain('last_modified: "2025-01-17"');
      expect(result).toContain("derived_from: simplicity");
      // The actual serialized format may differ due to quote handling
      expect(result).toContain("enforced_by:");
      expect(result).toContain("eslint");
      expect(result).toContain("@typescript-eslint/no-explicit-any");
    });

    test("preserves field ordering", () => {
      const metadata: StandardYamlMetadata = {
        id: "test",
        last_modified: "2025-01-17",
        derived_from: "parent",
        enforced_by: "tool",
      };

      const result = serializeToYaml(metadata);

      // Check field order
      const lines = result.split("\n").filter((line) => line.trim());
      expect(lines[0]).toContain("id:");
      expect(lines[1]).toContain("last_modified:");
      expect(lines[2]).toContain("derived_from:");
      expect(lines[3]).toContain("enforced_by:");
    });

    test("handles special characters in values", () => {
      const metadata: StandardYamlMetadata = {
        id: "test-with-special-chars",
        last_modified: "2025-01-17",
        enforced_by: 'tool("config with \\"quotes\\" and \\n newlines")',
      };

      const result = serializeToYaml(metadata);

      // Parse to verify it can be read back correctly
      const parsed = yaml.load(result) as StandardYamlMetadata;
      expect(parsed.enforced_by).toBe(
        'tool("config with \\"quotes\\" and \\n newlines")',
      );
    });

    test("properly quotes dates", () => {
      const metadata: StandardYamlMetadata = {
        id: "test",
        last_modified: "2025-01-17",
      };

      const result = serializeToYaml(metadata);

      // Dates should be quoted to prevent YAML from interpreting them
      expect(result).toMatch(/last_modified: "2025-01-17"/);
    });

    test("handles empty strings", () => {
      const metadata: StandardYamlMetadata = {
        id: "",
        last_modified: "",
      };

      const result = serializeToYaml(metadata);

      // Empty strings should be quoted
      expect(result).toContain('id: ""');
      expect(result).toContain('last_modified: ""');
    });

    test("handles IDs with dots and dashes", () => {
      const metadata: StandardYamlMetadata = {
        id: "test.binding-with-dots",
        last_modified: "2025-01-17",
      };

      const result = serializeToYaml(metadata);

      // Should be properly serialized
      expect(result).toContain("id: test.binding-with-dots");
    });

    test("produces consistent output", () => {
      const metadata: StandardYamlMetadata = {
        id: "test",
        last_modified: "2025-01-17",
        derived_from: "parent",
        enforced_by: "tool",
      };

      // Multiple calls should produce identical output
      const result1 = serializeToYaml(metadata);
      const result2 = serializeToYaml(metadata);

      expect(result1).toBe(result2);
    });

    test("handles multiline text properly", () => {
      const metadata: StandardYamlMetadata = {
        id: "test",
        last_modified: "2025-01-17",
        enforced_by: "Multi-line\ntext with\nnewlines",
      };

      const result = serializeToYaml(metadata);

      // Should properly escape or format multiline text
      const parsed = yaml.load(result) as StandardYamlMetadata;
      expect(parsed.enforced_by).toBe("Multi-line\ntext with\nnewlines");
    });

    test("serializes metadata with only required fields", () => {
      const metadata: StandardYamlMetadata = {
        id: "minimal",
        last_modified: "2025-01-17",
      } as StandardYamlMetadata;

      const result = serializeToYaml(metadata);

      // Should only contain required fields
      expect(result).toContain("id:");
      expect(result).toContain("last_modified:");
      expect(result).not.toContain("derived_from:");
      expect(result).not.toContain("enforced_by:");
    });
  });
});
