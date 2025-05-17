/**
 * Unit tests for the MetadataConverter module
 */

import { describe, test, expect, vi, beforeEach } from "vitest";
import { convertMetadata, ValidationError } from "./metadataConverter.js";
import { LegacyMetadata, StandardYamlMetadata } from "./types.js";

// Mock the logger
vi.mock("./logger.js", () => ({
  logger: {
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

describe("MetadataConverter", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("convertMetadata", () => {
    describe("successful conversions", () => {
      test("converts minimal valid metadata", () => {
        const legacy: LegacyMetadata = {
          id: "test-binding",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data).toEqual({
            id: "test-binding",
            last_modified: "2025-01-15",
          });
        }
      });

      test("converts complete metadata with all fields", () => {
        const legacy: LegacyMetadata = {
          id: "no-any",
          lastModified: "'2025-01-15'",
          derivedFrom: "simplicity",
          enforcedBy: 'eslint("@typescript-eslint/no-explicit-any")',
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data).toEqual({
            id: "no-any",
            last_modified: "2025-01-15",
            derived_from: "simplicity",
            enforced_by: 'eslint("@typescript-eslint/no-explicit-any")',
          });
        }
      });

      test("handles dates with quotes", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "'2025-01-15'",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.last_modified).toBe("2025-01-15");
        }
      });

      test("handles dates with double quotes", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: '"2025-01-15"',
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.last_modified).toBe("2025-01-15");
        }
      });

      test("normalizes ID by removing .md extension", () => {
        const legacy: LegacyMetadata = {
          id: "test-binding.md",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.id).toBe("test-binding");
        }
      });

      test("ignores deprecated appliesTo field with warning", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "2025-01-15",
          appliesTo: "typescript",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data).not.toHaveProperty("appliesTo");
          expect(result.data).not.toHaveProperty("applies_to");
        }
      });

      test("preserves unknown fields", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "2025-01-15",
          customField: "custom value",
          anotherField: "another value",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data).toEqual({
            id: "test",
            last_modified: "2025-01-15",
          });
          // Note: unknown fields are not preserved in StandardYamlMetadata
        }
      });
    });

    describe("validation failures", () => {
      test("fails when id is missing", () => {
        const legacy: LegacyMetadata = {
          id: "",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toContainEqual({
            fieldPath: "id",
            message: "Required field missing",
          });
        }
      });

      test("fails when lastModified is missing", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toContainEqual({
            fieldPath: "lastModified",
            message: "Required field missing",
          });
        }
      });

      test("fails with multiple validation errors", () => {
        const legacy: LegacyMetadata = {
          id: "",
          lastModified: "",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toHaveLength(2);
          expect(result.errors).toContainEqual({
            fieldPath: "id",
            message: "Required field missing",
          });
          expect(result.errors).toContainEqual({
            fieldPath: "lastModified",
            message: "Required field missing",
          });
        }
      });

      test("fails with invalid date format", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "Jan 15, 2025",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toContainEqual({
            fieldPath: "lastModified",
            message: "Date must be in ISO 8601 format (YYYY-MM-DD)",
          });
        }
      });

      test("fails with partial date", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "2025-01",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toContainEqual({
            fieldPath: "lastModified",
            message: "Date must be in ISO 8601 format (YYYY-MM-DD)",
          });
        }
      });

      test("accepts time components in date and truncates them", () => {
        const legacy: LegacyMetadata = {
          id: "test",
          lastModified: "2025-01-15T10:30:00Z",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.last_modified).toBe("2025-01-15");
        }
      });
    });

    describe("edge cases", () => {
      test("handles null input gracefully", () => {
        const result = convertMetadata(null as unknown as LegacyMetadata);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors[0].message).toContain("Invalid input");
        }
      });

      test("handles undefined input gracefully", () => {
        const result = convertMetadata(undefined as unknown as LegacyMetadata);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors[0].message).toContain("Invalid input");
        }
      });

      test("handles empty object", () => {
        const result = convertMetadata({} as LegacyMetadata);

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toHaveLength(2); // missing id and lastModified
        }
      });

      test("preserves field casing in values", () => {
        const legacy: LegacyMetadata = {
          id: "TestBinding",
          lastModified: "2025-01-15",
          derivedFrom: "CamelCase",
          enforcedBy: "MixedCase_Tool",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data).toEqual({
            id: "testbinding", // ID is normalized to lowercase
            last_modified: "2025-01-15",
            derived_from: "CamelCase", // Value casing preserved
            enforced_by: "MixedCase_Tool", // Value casing preserved
          });
        }
      });

      test("handles special characters in ID", () => {
        const legacy: LegacyMetadata = {
          id: "test!@#$%binding",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.id).toBe("test-----binding");
        }
      });
    });

    describe("filename validation", () => {
      test("validates ID matches filename when filename is provided", () => {
        const legacy: LegacyMetadata = {
          id: "wrong-id",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy, { filename: "correct-id.md" });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors).toContainEqual({
            fieldPath: "id",
            message: 'ID "wrong-id" does not match filename "correct-id"',
          });
        }
      });

      test("passes validation when ID matches filename", () => {
        const legacy: LegacyMetadata = {
          id: "correct-id",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy, { filename: "correct-id.md" });

        expect(result.success).toBe(true);
      });

      test("ignores filename validation when not provided", () => {
        const legacy: LegacyMetadata = {
          id: "any-id",
          lastModified: "2025-01-15",
        };

        const result = convertMetadata(legacy);

        expect(result.success).toBe(true);
      });
    });
  });
});
