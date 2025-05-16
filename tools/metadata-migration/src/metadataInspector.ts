/**
 * MetadataInspector module for detecting metadata format and extracting content.
 * Analyzes Markdown files to determine metadata type and separate metadata from content.
 */

import { FileContext, InspectedContent, MetadataFormat } from "./types.js";
import { logger } from "./logger.js";

/**
 * Inspects a file to determine its metadata format and extract content sections.
 * @param file FileContext containing file path and content
 * @returns InspectedContent with detected format, metadata, and main content
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
 * @param content File content
 * @returns Line break type (\n, \r\n, or \r)
 */
function detectLineBreakType(content: string): string {
  if (content.includes("\r\n")) return "\r\n";
  if (content.includes("\r")) return "\r";
  return "\n";
}

/**
 * Extracts YAML front-matter from file lines.
 * @param lines Array of file lines
 * @param lineBreakType Detected line break type
 * @returns InspectedContent if YAML found, null otherwise
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
 * @param lines Array of file lines
 * @param lineBreakType Detected line break type
 * @returns InspectedContent if legacy format found, null otherwise
 */
function extractLegacyHrMetadata(
  lines: string[],
  lineBreakType: string,
): InspectedContent | null {
  // Look for the start of legacy metadata
  let startIndex = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith("#### ---")) {
      startIndex = i;
      break;
    }
  }

  if (startIndex === -1) return null;

  // Find the end of the metadata block
  let endIndex = startIndex;
  let inMetadata = true;

  for (let i = startIndex + 1; i < lines.length; i++) {
    const line = lines[i];
    const trimmedLine = line.trim();

    if (trimmedLine === "") {
      // Empty line might be part of metadata or signal its end
      // Continue checking next lines
      continue;
    }

    // Check if this line is metadata (contains colon)
    if (line.includes(":") && !line.startsWith("#")) {
      endIndex = i;
      inMetadata = true;
    } else {
      // Found non-metadata content
      if (inMetadata) {
        // We were in metadata, now we found content
        // Check if there were empty lines before this
        let checkIndex = i - 1;
        while (checkIndex > endIndex && lines[checkIndex].trim() === "") {
          checkIndex--;
        }
        endIndex = checkIndex;
        break;
      }
    }
  }

  // If we reached the end without finding content, metadata goes to the end
  if (
    endIndex === lines.length - 1 ||
    (endIndex < lines.length - 1 &&
      lines.slice(endIndex + 1).every((l) => l.trim() === ""))
  ) {
    endIndex = lines.length - 1;
  }

  const metadataLines = lines.slice(startIndex, endIndex + 1);
  const contentLines = lines.slice(endIndex + 1);

  // Ensure content doesn't start with empty line when it's not needed
  let contentStart = 0;
  while (
    contentStart < contentLines.length &&
    contentLines[contentStart] === ""
  ) {
    contentStart++;
  }

  // Keep one empty line if there was one between metadata and content
  if (contentStart > 0 && contentLines.length > 0) {
    contentStart = Math.max(0, contentStart - 1);
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
 * @param lines Array of file lines
 * @param lineBreakType Detected line break type
 * @returns InspectedContent if unknown format found, null otherwise
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
