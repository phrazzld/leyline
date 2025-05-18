/**
 * MetadataInspector module for detecting metadata format and extracting content.
 *
 * This module analyzes Markdown files to determine their metadata format (YAML front-matter,
 * legacy horizontal rule, none, or unknown) and separates metadata from main content.
 * It's a critical component that enables the migration tool to understand what type of
 * transformation is needed for each file.
 *
 * @remarks
 * The inspection process is designed to be robust and handle various edge cases:
 * - Empty or whitespace-only files
 * - Different line break types (LF, CRLF, CR)
 * - Malformed metadata sections
 * - Unknown metadata formats for future extensibility
 *
 * The module preserves the original file structure, including line breaks and spacing,
 * to ensure minimal changes to files during migration.
 */

import { FileContext, InspectedContent, MetadataFormat } from "./types.js";
import { logger } from "./logger.js";

/**
 * Inspects a file to determine its metadata format and extract content sections.
 *
 * @param file - FileContext containing file path and content
 * @returns InspectedContent with detected format, metadata, and main content
 *
 * @remarks
 * This function serves as the main entry point for file inspection. It:
 * 1. Handles edge cases like empty files
 * 2. Detects the line break type used in the file
 * 3. Checks for each known metadata format in order
 * 4. Returns structured information about the file's format and content
 *
 * The inspection order is important: YAML front-matter is checked first,
 * then legacy HR format, then unknown formats.
 *
 * @example
 * ```typescript
 * const result = inspectFile({
 *   path: '/path/to/file.md',
 *   content: '---\nid: example\n---\n# Title',
 *   exists: true
 * });
 * console.log(result.format); // MetadataFormat.Yaml
 * ```
 */
export function inspectFile(file: FileContext): InspectedContent {
  logger.debug("Inspecting file for metadata format", { path: file.path });

  // Handle empty files
  if (!file.content || file.content.trim() === "") {
    logger.info("File is empty or contains only whitespace", {
      path: file.path,
    });
    return {
      format: MetadataFormat.None,
      metadata: "",
      content: file.content,
      lineBreakType: "\n",
    };
  }

  // Detect line break type
  const lineBreakType = detectLineBreakType(file.content);
  const lines = file.content.split(/\r\n|\r|\n/);

  // Check for YAML front-matter
  if (lines[0] === "---") {
    const yamlResult = extractYamlFrontMatter(lines, lineBreakType);
    if (yamlResult) {
      logger.info("YAML front-matter detected", { path: file.path });
      return yamlResult;
    }
  }

  // Check for legacy HR metadata
  const legacyResult = extractLegacyHrMetadata(lines, lineBreakType);
  if (legacyResult) {
    logger.info("Legacy HR metadata detected", { path: file.path });
    return legacyResult;
  }

  // Check for other metadata patterns (unknown format)
  const unknownResult = detectUnknownFormat(lines, lineBreakType);
  if (unknownResult) {
    logger.warn("Unknown metadata format detected", { path: file.path });
    return unknownResult;
  }

  // No metadata found
  logger.info("No metadata detected", { path: file.path });
  return {
    format: MetadataFormat.None,
    metadata: "",
    content: file.content,
    lineBreakType,
  };
}

/**
 * Detects the line break type used in the content.
 *
 * @param content - File content to analyze
 * @returns Line break type (LF, CRLF, or CR)
 *
 * @remarks
 * This function checks for line break types in a specific order:
 * 1. CRLF (Windows)
 * 2. CR (old Mac)
 * 3. LF (Unix/Linux/modern Mac) as default
 *
 * The detection order matters because CRLF contains CR, so we must
 * check for CRLF first to avoid false positives.
 */
function detectLineBreakType(content: string): string {
  if (content.includes("\r\n")) return "\r\n";
  if (content.includes("\r")) return "\r";
  return "\n";
}

/**
 * Extracts YAML front-matter from file lines.
 *
 * @param lines - Array of file lines
 * @param lineBreakType - Detected line break type
 * @returns InspectedContent if YAML found, null otherwise
 *
 * @remarks
 * YAML front-matter must:
 * - Start with "---" on the first line
 * - End with "---" on a subsequent line
 * - Contain valid YAML between the delimiters
 *
 * This function is strict about the format to avoid false positives
 * with horizontal rules or other content that might use dashes.
 */
function extractYamlFrontMatter(
  lines: string[],
  lineBreakType: string,
): InspectedContent | null {
  if (lines[0] !== "---") return null;

  // Find closing delimiter
  let closingIndex = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") {
      closingIndex = i;
      break;
    }
  }

  if (closingIndex === -1) {
    // Opening delimiter but no closing - could be malformed YAML
    return null;
  }

  // Extract metadata and content
  const metadataLines = lines.slice(1, closingIndex);
  const contentLines = lines.slice(closingIndex + 1);

  return {
    format: MetadataFormat.Yaml,
    metadata: metadataLines.join(lineBreakType),
    content: contentLines.join(lineBreakType),
    lineBreakType,
  };
}

/**
 * Extracts legacy horizontal rule metadata from file lines.
 *
 * @param lines - Array of file lines
 * @param lineBreakType - Detected line break type
 * @returns InspectedContent if legacy format found, null otherwise
 *
 * @remarks
 * Legacy HR metadata format consists of:
 * - Three or more underscores on a line by themselves (opening)
 * - Metadata in key: value format
 * - Three or more underscores on a line by themselves (closing)
 *
 * This function is flexible about the exact number of underscores
 * to accommodate variations in the legacy format.
 *
 * @example
 * ```
 * # Document Title
 *
 * Content here...
 *
 * ___
 * **ID:** example
 * **Last-Modified:** 2024-03-15
 * ___
 * ```
 */
function extractLegacyHrMetadata(
  lines: string[],
  lineBreakType: string,
): InspectedContent | null {
  // Look for the start of legacy metadata with underscore pattern
  let startIndex = -1;
  const underscorePattern = /^_{3,}$/;

  for (let i = 0; i < lines.length; i++) {
    if (underscorePattern.test(lines[i])) {
      startIndex = i;
      break;
    }
  }

  if (startIndex === -1) return null;

  // Find the closing underscore pattern
  let endIndex = -1;
  for (let i = startIndex + 1; i < lines.length; i++) {
    if (underscorePattern.test(lines[i])) {
      endIndex = i;
      break;
    }
  }

  if (endIndex === -1) return null;

  // Extract metadata between the two underscore lines
  const metadataLines = lines.slice(startIndex + 1, endIndex);
  const contentLines = lines.slice(endIndex + 1);

  // Skip empty lines at the start of content
  let contentStart = 0;
  while (
    contentStart < contentLines.length &&
    contentLines[contentStart].trim() === ""
  ) {
    contentStart++;
  }

  return {
    format: MetadataFormat.LegacyHr,
    metadata: metadataLines.join(lineBreakType),
    content: contentLines.slice(contentStart).join(lineBreakType),
    lineBreakType,
  };
}

/**
 * Detects unknown metadata formats.
 *
 * @param lines - Array of file lines
 * @param lineBreakType - Detected line break type
 * @returns InspectedContent if unknown format found, null otherwise
 *
 * @remarks
 * This function attempts to identify metadata patterns that don't match
 * the known formats (YAML front-matter or legacy HR). It looks for:
 * - Key: value patterns at the start of the file
 * - A blank line or non-metadata content indicating the end of metadata
 *
 * This provides extensibility for future metadata formats without
 * requiring changes to the core inspection logic.
 *
 * @example
 * Files with formats like:
 * ```
 * Title: Example Document
 * Author: John Doe
 * Date: 2024-03-15
 *
 * Document content starts here...
 * ```
 */
function detectUnknownFormat(
  lines: string[],
  lineBreakType: string,
): InspectedContent | null {
  // Check for potential metadata patterns that don't match known formats
  // For example: files starting with metadata-like patterns but not standard formats

  // Check if first few lines look like metadata (key: value patterns)
  let potentialMetadataEnd = -1;
  for (let i = 0; i < Math.min(10, lines.length); i++) {
    const line = lines[i].trim();
    if (line === "") {
      // Empty line might signal end of metadata
      if (i > 0) {
        potentialMetadataEnd = i;
        break;
      }
    } else if (!line.includes(":") && !line.startsWith("#") && i > 0) {
      // Non-metadata-like content
      potentialMetadataEnd = i;
      break;
    }
  }

  // Only consider it unknown metadata if we found key-value pairs in the first line
  if (potentialMetadataEnd > 0 && lines[0].includes(":")) {
    const metadataLines = lines.slice(0, potentialMetadataEnd);
    const contentLines = lines.slice(potentialMetadataEnd);

    return {
      format: MetadataFormat.Unknown,
      metadata: metadataLines.join(lineBreakType),
      content: contentLines.join(lineBreakType),
      lineBreakType,
    };
  }

  return null;
}
