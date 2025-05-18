/**
 * Tests for the MetadataInspector module
 */

import { describe, it, expect, beforeEach, vi } from "vitest";
import { inspectFile } from "./metadataInspector.js";
import { FileContext, MetadataFormat } from "./types.js";

// Mock the logger
vi.mock("./logger.js", () => ({
  logger: {
    info: vi.fn(),
    debug: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

describe("MetadataInspector", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("inspectFile", () => {
    describe("empty file handling", () => {
      it("should handle empty file", () => {
        const file: FileContext = {
          path: "/test/empty.md",
          content: "",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.None,
          metadata: "",
          content: "",
          lineBreakType: "\n",
        });
      });

      it("should handle file with only whitespace", () => {
        const file: FileContext = {
          path: "/test/whitespace.md",
          content: "   \n  \n ",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.None,
          metadata: "",
          content: "   \n  \n ",
          lineBreakType: "\n",
        });
      });
    });

    describe("line break detection", () => {
      it("should detect Windows line breaks (CRLF)", () => {
        const file: FileContext = {
          path: "/test/windows.md",
          content: "# Title\r\n\r\nContent here\r\n",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.lineBreakType).toBe("\r\n");
      });

      it("should detect Unix line breaks (LF)", () => {
        const file: FileContext = {
          path: "/test/unix.md",
          content: "# Title\n\nContent here\n",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.lineBreakType).toBe("\n");
      });

      it("should detect old Mac line breaks (CR)", () => {
        const file: FileContext = {
          path: "/test/mac.md",
          content: "# Title\r\rContent here\r",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.lineBreakType).toBe("\r");
      });
    });

    describe("YAML front-matter detection", () => {
      it("should detect valid YAML front-matter", () => {
        const file: FileContext = {
          path: "/test/yaml.md",
          content:
            "---\nid: test-id\nlast_modified: '2024-01-01'\n---\n\n# Content\n\nThis is the content.",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.Yaml,
          metadata: "id: test-id\nlast_modified: '2024-01-01'",
          content: "\n# Content\n\nThis is the content.",
          lineBreakType: "\n",
        });
      });

      it("should handle empty YAML front-matter", () => {
        const file: FileContext = {
          path: "/test/empty-yaml.md",
          content: "---\n---\n\n# Content",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.Yaml,
          metadata: "",
          content: "\n# Content",
          lineBreakType: "\n",
        });
      });

      it("should handle malformed YAML (no closing delimiter)", () => {
        const file: FileContext = {
          path: "/test/malformed-yaml.md",
          content: "---\nid: test-id\nlast_modified: '2024-01-01'\n\n# Content",
          exists: true,
        };

        const result = inspectFile(file);

        // Should not detect as YAML if closing delimiter is missing
        expect(result.format).not.toBe(MetadataFormat.Yaml);
      });

      it("should handle file starting with --- but not YAML", () => {
        const file: FileContext = {
          path: "/test/not-yaml.md",
          content: "--- This is not YAML\n\nJust regular content",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).toBe(MetadataFormat.None);
      });
    });

    describe("legacy HR metadata detection", () => {
      it("should detect legacy HR metadata with underscores", () => {
        const file: FileContext = {
          path: "/test/legacy.md",
          content:
            "______________________________________________________________________\n\nid: test-id\nlastModified: 2024-01-01\nappliesTo: frontend\n\n______________________________________________________________________\n\n# Content\n\nThis is the content.",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.LegacyHr,
          metadata: "\nid: test-id\nlastModified: 2024-01-01\nappliesTo: frontend\n",
          content: "# Content\n\nThis is the content.",
          lineBreakType: "\n",
        });
      });

      it("should handle legacy metadata without empty lines", () => {
        const file: FileContext = {
          path: "/test/legacy-compact.md",
          content:
            "______________________________________________________________________\nid: test-id\nlastModified: 2024-01-01\n______________________________________________________________________\n\n# Content",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.LegacyHr,
          metadata: "id: test-id\nlastModified: 2024-01-01",
          content: "# Content",
          lineBreakType: "\n",
        });
      });

      it("should handle legacy metadata with empty lines", () => {
        const file: FileContext = {
          path: "/test/legacy-empty.md",
          content:
            "______________________________________________________________________\n\nid: test-id\n\nlastModified: 2024-01-01\n\n______________________________________________________________________\n\n# Content",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.LegacyHr,
          metadata: "\nid: test-id\n\nlastModified: 2024-01-01\n",
          content: "# Content",
          lineBreakType: "\n",
        });
      });

      it("should require closing underscores", () => {
        const file: FileContext = {
          path: "/test/legacy-unclosed.md",
          content:
            "______________________________________________________________________\n\nid: test-id\nlastModified: 2024-01-01\n\n# Content",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).not.toBe(MetadataFormat.LegacyHr);
      });
    });

    describe("unknown format detection", () => {
      it("should detect unknown metadata format", () => {
        const file: FileContext = {
          path: "/test/unknown.md",
          content:
            "id: test-id\ndate: 2024-01-01\nauthor: John Doe\n\n# Title\n\nContent here",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.Unknown,
          metadata: "id: test-id\ndate: 2024-01-01\nauthor: John Doe",
          content: "\n# Title\n\nContent here",
          lineBreakType: "\n",
        });
      });

      it("should not detect unknown format if no key-value pairs", () => {
        const file: FileContext = {
          path: "/test/not-unknown.md",
          content: "Just some text\nMore text\n\n# Title",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).toBe(MetadataFormat.None);
      });

      it("should not detect unknown format for regular markdown", () => {
        const file: FileContext = {
          path: "/test/regular.md",
          content:
            "# Title\n\nThis is a paragraph with a colon: it's normal text.",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).toBe(MetadataFormat.None);
      });
    });

    describe("no metadata detection", () => {
      it("should detect no metadata in regular markdown file", () => {
        const file: FileContext = {
          path: "/test/no-metadata.md",
          content:
            "# Title\n\nThis is just content.\n\n## Section\n\nMore content.",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result).toEqual({
          format: MetadataFormat.None,
          metadata: "",
          content:
            "# Title\n\nThis is just content.\n\n## Section\n\nMore content.",
          lineBreakType: "\n",
        });
      });
    });

    describe("edge cases", () => {
      it("should handle file with only dashes", () => {
        const file: FileContext = {
          path: "/test/dashes.md",
          content: "---",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).toBe(MetadataFormat.None);
      });

      it("should handle file with HR but not metadata", () => {
        const file: FileContext = {
          path: "/test/hr.md",
          content: "# Title\n\n---\n\nContent after HR",
          exists: true,
        };

        const result = inspectFile(file);

        expect(result.format).toBe(MetadataFormat.None);
      });

      it("should handle mixed line endings", () => {
        const file: FileContext = {
          path: "/test/mixed.md",
          content: "---\r\nid: test\n---\r\n\nContent",
          exists: true,
        };

        const result = inspectFile(file);

        // Should detect first line ending type encountered
        expect(result.lineBreakType).toBe("\r\n");
      });
    });
  });
});
