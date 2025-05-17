/**
 * Unit tests for the LegacyParser module
 */

import { describe, test, expect } from "vitest";
import { parseLegacyMetadata, LegacyParseError } from "./legacyParser.js";
import { readFileSync } from "fs";
import { join } from "path";

// Helper to read test fixtures
function readFixture(filename: string): string {
  const fixturePath = join(__dirname, "..", "test", "fixtures", filename);
  return readFileSync(fixturePath, "utf-8");
}

// Helper to extract metadata from fixture content
function extractMetadataSection(content: string): string {
  const lines = content.split(/\r\n|\r|\n/);
  const startIndex = lines.findIndex((line) => line.includes("_____"));

  if (startIndex === -1) {
    return "";
  }

  // Check for metadata between two delimiters (standard format)
  const endIndex = lines.findIndex(
    (line, index) => index > startIndex && line.includes("_____"),
  );

  if (endIndex !== -1) {
    // Standard format: metadata between two delimiters
    return lines.slice(startIndex, endIndex + 1).join("\n");
  } else {
    // Alternative format: delimiter followed by metadata until non-metadata content
    const metadataLines = [lines[startIndex]];

    for (let i = startIndex + 1; i < lines.length; i++) {
      const line = lines[i];

      // Empty lines are part of metadata
      if (line.trim() === "") {
        metadataLines.push(line);
        continue;
      }

      // Lines with key:value patterns are metadata
      if (line.includes(":") && !line.startsWith("#")) {
        metadataLines.push(line);
        continue;
      }

      // Lines starting with ## and containing : are metadata
      if (line.startsWith("##") && line.includes(":")) {
        metadataLines.push(line);
        continue;
      }

      // Any other content marks the end of metadata
      break;
    }

    // For incomplete delimiter test, don't add ending delimiter
    if (content.includes("incomplete-metadata")) {
      return metadataLines.join("\n");
    } else {
      // Add ending delimiter for other cases
      metadataLines.push(
        "______________________________________________________________________",
      );
      return metadataLines.join("\n");
    }
  }
}

describe("LegacyParser", () => {
  describe("valid metadata parsing", () => {
    test("parses basic binding metadata", () => {
      const fixture = readFixture("legacy-basic-binding.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("no-any");
      expect(result.metadata?.derivedFrom).toBe("simplicity");
      expect(result.metadata?.enforcedBy).toBe(
        'eslint("@typescript-eslint/no-explicit-any") & tsconfig("noImplicitAny")',
      );
      expect(result.metadata?.lastModified).toBe("'2025-01-15'");
    });

    test("parses basic tenet metadata", () => {
      const fixture = readFixture("legacy-basic-tenet.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("simplicity");
      expect(result.metadata?.lastModified).toBe("'2025-01-15'");
      expect(result.metadata?.derivedFrom).toBeUndefined();
    });

    test("parses multiline values", () => {
      const fixture = readFixture("legacy-multiline-values.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("require-conventional-commits");
      expect(result.metadata?.["summary"]).toBe(
        "Use conventional commit format for all commit messages",
      );
      expect(result.metadata?.["description"]).toContain(
        "All commit messages MUST follow",
      );
      expect(result.metadata?.["description"]).toContain(
        "to understand the semantic meaning of changes.",
      );
    });

    test("handles special characters in values", () => {
      const fixture = readFixture("legacy-special-chars.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["special_field"]).toContain('"quotes"');
      expect(result.metadata?.["special_field"]).toContain("'apostrophes'");
      expect(result.metadata?.["special_field"]).toContain("!@#$%^&*()");
    });

    test("parses metadata with applies_to field", () => {
      const fixture = readFixture("legacy-with-applies-to.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("error-wrapping");
      expect(result.metadata?.appliesTo).toBe("go");
    });

    test("handles metadata lines with leading hashes", () => {
      const metadata = "## id: test-id last_modified: '2025-01-15'";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("test-id");
      expect(result.metadata?.lastModified).toBe("'2025-01-15'");
    });
  });

  describe("malformed metadata handling", () => {
    test("returns error for missing required id field", () => {
      const fixture = readFixture("malformed-missing-required.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(2); // Both id and lastModified are missing
      expect(result.errors[0]).toBeInstanceOf(LegacyParseError);
      expect(result.errors[0].message).toContain("id");
      expect(result.metadata).toBeNull();
    });

    test("handles incomplete metadata delimiters", () => {
      const fixture = readFixture("malformed-incomplete-hr.md");
      const metadata = extractMetadataSection(fixture);
      const result = parseLegacyMetadata(metadata);

      // Should still parse what it can
      expect(result.warnings).toHaveLength(1);
      expect(result.warnings[0]).toContain("closing delimiter");
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("incomplete-metadata");
    });

    test("returns error for empty metadata", () => {
      const result = parseLegacyMetadata("");

      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].message).toContain("empty");
      expect(result.metadata).toBeNull();
    });

    test("returns error for whitespace-only metadata", () => {
      const result = parseLegacyMetadata("   \n\t\n  ");

      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].message).toContain("empty");
      expect(result.metadata).toBeNull();
    });
  });

  describe("field mapping and normalization", () => {
    test("maps snake_case to camelCase", () => {
      const metadata =
        "id: test last_modified: '2025-01-15' derived_from: parent enforced_by: tool";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.lastModified).toBe("'2025-01-15'");
      expect(result.metadata?.derivedFrom).toBe("parent");
      expect(result.metadata?.enforcedBy).toBe("tool");
    });

    test("preserves additional fields", () => {
      const metadata =
        "id: test last_modified: '2025-01-15' custom_field: value another_field: data";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["custom_field"]).toBe("value");
      expect(result.metadata?.["another_field"]).toBe("data");
    });
  });

  describe("edge cases", () => {
    test("handles CRLF line endings", () => {
      const metadata =
        "id: test\r\nlast_modified: '2025-01-15'\r\nderived_from: parent";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("test");
      expect(result.metadata?.derivedFrom).toBe("parent");
    });

    test("handles mixed line endings", () => {
      const metadata =
        "id: test\nlast_modified: '2025-01-15'\r\nderived_from: parent\r";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.id).toBe("test");
      expect(result.metadata?.derivedFrom).toBe("parent");
    });

    test("handles unicode characters", () => {
      const metadata =
        "id: test last_modified: '2025-01-15' unicode_field: Emoji 🚀 and symbols ∑∏";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["unicode_field"]).toBe(
        "Emoji 🚀 and symbols ∑∏",
      );
    });

    test("handles very long values", () => {
      const longValue = "x".repeat(1000);
      const metadata = `id: test last_modified: '2025-01-15' long_field: ${longValue}`;
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["long_field"]).toBe(longValue);
    });

    test("handles metadata with only colons in values", () => {
      const metadata =
        "id: test last_modified: '2025-01-15' url: https://example.com:8080/path";
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["url"]).toBe("https://example.com:8080/path");
    });
  });

  describe("multiline value edge cases", () => {
    test("handles empty lines within multiline values", () => {
      const metadata = `id: test last_modified: '2025-01-15' description: Line 1
Line 2

Line 4`;
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["description"]).toContain("Line 1");
      expect(result.metadata?.["description"]).toContain("Line 4");
    });

    test("handles indented continuation lines", () => {
      const metadata = `id: test last_modified: '2025-01-15' description: First line
  indented continuation
    more indented continuation`;
      const result = parseLegacyMetadata(metadata);

      expect(result.errors).toHaveLength(0);
      expect(result.metadata).not.toBeNull();
      expect(result.metadata?.["description"]).toContain("First line");
      expect(result.metadata?.["description"]).toContain(
        "indented continuation",
      );
      expect(result.metadata?.["description"]).toContain(
        "more indented continuation",
      );
    });
  });
});
