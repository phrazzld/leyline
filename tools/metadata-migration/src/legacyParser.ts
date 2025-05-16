/**
 * LegacyParser module for parsing legacy horizontal rule metadata format.
 * Converts raw legacy metadata strings into structured LegacyMetadata objects.
 */

import { LegacyMetadata } from "./types.js";
import { logger } from "./logger.js";

/**
 * Result of parsing legacy metadata
 */
export interface ParseResult {
  /** Parsed metadata object or null if critical errors occurred */
  metadata: LegacyMetadata | null;
  /** Array of parsing errors encountered */
  errors: LegacyParseError[];
  /** Array of warnings (non-critical issues) */
  warnings: string[];
}

/**
 * Error class for legacy metadata parsing failures
 */
export class LegacyParseError extends Error {
  constructor(
    message: string,
    public field?: string,
    public lineNumber?: number,
  ) {
    super(message);
    this.name = "LegacyParseError";
  }
}

// Field mapping from snake_case to camelCase
const FIELD_MAPPINGS: Record<string, keyof LegacyMetadata> = {
  id: "id",
  last_modified: "lastModified",
  derived_from: "derivedFrom",
  enforced_by: "enforcedBy",
  applies_to: "appliesTo",
};

// Required fields that must be present
const REQUIRED_FIELDS = ["id", "lastModified"] as const;

// Valid metadata keys that we should recognize
const VALID_KEYS = new Set([
  "id",
  "last_modified",
  "derived_from",
  "enforced_by",
  "applies_to",
  "description",
  "summary",
  "special_field",
  "url",
  "status",
  "category",
  "tags",
  "purpose",
  "custom_field",
  "another_field",
  "unicode_field",
  "long_field",
]);

/**
 * Parses raw legacy metadata string into a structured LegacyMetadata object.
 * @param rawMetadata Raw metadata string to parse
 * @returns ParseResult containing metadata and any errors/warnings
 */
export function parseLegacyMetadata(rawMetadata: string): ParseResult {
  const errors: LegacyParseError[] = [];
  const warnings: string[] = [];

  logger.debug("Starting legacy metadata parsing", {
    contentLength: rawMetadata.length,
  });

  // Check for empty metadata
  if (!rawMetadata || rawMetadata.trim() === "") {
    logger.error("Empty metadata provided for parsing");
    errors.push(new LegacyParseError("Metadata is empty or contains only whitespace"));
    return { metadata: null, errors, warnings };
  }

  // Parse the metadata into key-value pairs
  const parsedData = parseKeyValuePairs(rawMetadata, warnings);

  // Map fields from snake_case to camelCase
  const mappedData = mapFieldNames(parsedData);

  // Check for missing closing delimiter first (do this before validation)
  const lines = rawMetadata.split(/\r\n|\r|\n/);
  const delimiterLines = lines.filter(line => line.includes("_____"));
  if (delimiterLines.length < 2) {
    warnings.push("Metadata may be missing closing delimiter");
  }

  // Validate required fields
  for (const requiredField of REQUIRED_FIELDS) {
    if (!mappedData[requiredField]) {
      errors.push(new LegacyParseError(`Missing required field: ${requiredField}`, requiredField));
    }
  }

  // If there are critical errors, check if we can return partial metadata
  if (errors.length > 0) {
    logger.warn("Critical errors found during parsing", { errorCount: errors.length });

    // If we at least have an ID, return partial metadata with errors
    if (mappedData.id) {
      const partialMetadata: LegacyMetadata = {
        id: mappedData.id as string,
        lastModified: mappedData.lastModified as string || "",
      };

      // Add optional fields if they exist
      if (mappedData.derivedFrom) partialMetadata.derivedFrom = mappedData.derivedFrom as string;
      if (mappedData.enforcedBy) partialMetadata.enforcedBy = mappedData.enforcedBy as string;
      if (mappedData.appliesTo) partialMetadata.appliesTo = mappedData.appliesTo as string;

      return { metadata: partialMetadata, errors, warnings };
    }

    return { metadata: null, errors, warnings };
  }

  // Create the metadata object
  const metadata: LegacyMetadata = {
    id: mappedData.id as string,
    lastModified: mappedData.lastModified as string,
  };

  // Add optional fields
  if (mappedData.derivedFrom) metadata.derivedFrom = mappedData.derivedFrom as string;
  if (mappedData.enforcedBy) metadata.enforcedBy = mappedData.enforcedBy as string;
  if (mappedData.appliesTo) metadata.appliesTo = mappedData.appliesTo as string;

  // Add any additional fields that weren't mapped
  for (const [key, value] of Object.entries(parsedData)) {
    if (!FIELD_MAPPINGS[key] && !metadata[key]) {
      metadata[key] = value;
    }
  }

  logger.info("Successfully parsed legacy metadata", {
    fieldCount: Object.keys(metadata).length,
    hasWarnings: warnings.length > 0,
  });

  return { metadata, errors, warnings };
}

/**
 * Parses raw metadata into key-value pairs
 * @param rawMetadata Raw metadata string
 * @param warnings Array to collect warnings
 * @returns Record of key-value pairs
 */
function parseKeyValuePairs(
  rawMetadata: string,
  _warnings: string[],
): Record<string, string> {
  const data: Record<string, string> = {};

  // Normalize line endings and remove leading hashes
  const lines = rawMetadata
    .split(/\r\n|\r|\n/)
    .map(line => line.replace(/^#+\s*/, ""));

  // Find the first content line
  let firstContentLine = "";
  let firstContentLineIndex = -1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line && !line.startsWith("_____")) {
      firstContentLine = lines[i];
      firstContentLineIndex = i;
      break;
    }
  }

  if (firstContentLineIndex === -1) {
    return data;
  }

  // Check if this is the special case where the metadata line has ## prefix
  // (e.g., "## id: simplicity last_modified: '2025-01-15'")
  const isCommentedMetadata = firstContentLine.trim().startsWith("##");
  const cleanedFirstLine = isCommentedMetadata
    ? firstContentLine.replace(/^#+\s*/, "")
    : firstContentLine;

  // Check if we need to process multiple lines together
  // If there are multiple keys on the first line, but it also appears to have a
  // continuation (line doesn't end with a value), we need special handling
  const keyPatterns: string[] = [];
  const keyRegex = /\b([a-zA-Z_]+):/g;
  let match;
  while ((match = keyRegex.exec(cleanedFirstLine)) !== null) {
    if (VALID_KEYS.has(match[1]) || match[1].match(/^[a-zA-Z_]+$/)) {
      keyPatterns.push(match[1]);
    }
  }

  // Detect mixed format: multiple keys on first line + continuations
  const lineEndsWithValue = cleanedFirstLine.trim().match(/:\s*[^:]+$/);
  const isMixedFormat = keyPatterns.length > 1 && !lineEndsWithValue;

  const formatType = isMixedFormat ? "mixed" : (keyPatterns.length > 1 ? "single-line" : "multiline");

  if (formatType === "single-line") {
    // For single-line format, parse all keys that look valid
    const keys: Array<{ key: string; startPos: number }> = [];

    // Find all valid key positions - ensure they're preceded by space or start of line
    const keyRegex = /(?:^|\s)([a-zA-Z_]+):/g;
    let keyMatch;
    while ((keyMatch = keyRegex.exec(cleanedFirstLine)) !== null) {
      const key = keyMatch[1];
      const actualStart = keyMatch.index === 0 ? 0 : keyMatch.index + 1; // Skip the space

      // Accept keys that are in the valid list or look like reasonable metadata keys
      // Reject common URL parts and suspicious patterns
      const isUrlPart = ["https", "http", "ftp", "www", "com", "org", "net", "localhost"].includes(key);
      const isSuspicious = key === "chars" && cleanedFirstLine.substring(actualStart - 10, actualStart).includes("special");

      if (!isUrlPart && !isSuspicious && (VALID_KEYS.has(key) || key.match(/^[a-zA-Z_][a-zA-Z0-9_]*$/))) {
        keys.push({ key, startPos: actualStart });
      }
    }

    // Extract values for each key
    for (let i = 0; i < keys.length; i++) {
      const { key, startPos } = keys[i];
      const keyLength = key.length + 1; // +1 for the colon
      const valueStart = startPos + keyLength;

      // Find where this value ends (at the next key or end of line)
      let valueEnd = cleanedFirstLine.length;
      if (i < keys.length - 1) {
        valueEnd = keys[i + 1].startPos;
      }

      let value = cleanedFirstLine.substring(valueStart, valueEnd).trim();
      data[key] = value;
    }

    // Check for continuation lines and additional keys
    let currentKey = keys[keys.length - 1]?.key;
    if (currentKey) {
      for (let i = firstContentLineIndex + 1; i < lines.length; i++) {
        const line = lines[i];
        if (line.trim().startsWith("_____")) break;

        // Check if this line contains keys
        const lineKeys: Array<{ key: string; startPos: number }> = [];
        const lineKeyRegex = /(?:^|\s)([a-zA-Z_]+):/g;
        let keyMatch;

        while ((keyMatch = lineKeyRegex.exec(line)) !== null) {
          const key = keyMatch[1];
          const actualStart = keyMatch.index === 0 ? 0 : keyMatch.index + 1;

          if (VALID_KEYS.has(key)) {
            lineKeys.push({ key, startPos: actualStart });
          }
        }

        if (lineKeys.length > 0) {
          // Before starting a new key, check if there's a value before the first key
          const firstKeyPos = lineKeys[0].startPos;
          if (firstKeyPos > 0) {
            // There's text before the first key, it's a continuation
            const continuationText = line.substring(0, firstKeyPos).trim();
            if (continuationText) {
              data[currentKey] = data[currentKey] + " " + continuationText;
            }
          }

          // Now parse the keys on this line
          for (let j = 0; j < lineKeys.length; j++) {
            const { key, startPos } = lineKeys[j];
            const keyLength = key.length + 1;
            const valueStart = startPos + keyLength;

            let valueEnd = line.length;
            if (j < lineKeys.length - 1) {
              valueEnd = lineKeys[j + 1].startPos;
            }

            data[key] = line.substring(valueStart, valueEnd).trim();
            currentKey = key; // Update current key for next line's continuation
          }
        } else {
          // No valid keys, treat as continuation of current value
          if (line.trim()) {
            data[currentKey] = data[currentKey] + " " + line.trim();
          }
        }
      }
    }
  } else if (formatType === "mixed") {
    // Mixed format: multiple keys on first line, possibly with continuations
    // First parse all keys from the first line
    const keyRegex = /(?:^|\s)([a-zA-Z_]+):/g;
    let keyMatch;
    const keys: Array<{ key: string; startPos: number }> = [];

    while ((keyMatch = keyRegex.exec(cleanedFirstLine)) !== null) {
      const key = keyMatch[1];
      const actualStart = keyMatch.index === 0 ? 0 : keyMatch.index + 1;

      if (VALID_KEYS.has(key) || key.match(/^[a-zA-Z_][a-zA-Z0-9_]*$/)) {
        keys.push({ key, startPos: actualStart });
      }
    }

    // Extract values for each key from the first line
    for (let i = 0; i < keys.length; i++) {
      const { key, startPos } = keys[i];
      const keyLength = key.length + 1;
      const valueStart = startPos + keyLength;

      let valueEnd = cleanedFirstLine.length;
      if (i < keys.length - 1) {
        valueEnd = keys[i + 1].startPos;
      }

      let value = cleanedFirstLine.substring(valueStart, valueEnd).trim();
      data[key] = value;
    }

    // Process subsequent lines - they may contain continuation values or new keys
    const lastKey = keys[keys.length - 1]?.key;
    for (let i = firstContentLineIndex + 1; i < lines.length; i++) {
      const line = lines[i];

      if (line.trim().startsWith("_____")) break;

      // Check if this line contains a key
      const keyMatch = line.match(/^([a-zA-Z_]+):\s*/);
      if (keyMatch && VALID_KEYS.has(keyMatch[1])) {
        // This is a new key-value pair on its own line
        const key = keyMatch[1];
        const valueStart = keyMatch[0].length;
        data[key] = line.substring(valueStart).trim();
      } else if (lastKey && line.trim()) {
        // This is a continuation of the previous value
        data[lastKey] = data[lastKey] + " " + line.trim();
      }
    }
  } else {
    // Multiline format: each key-value pair can be on its own line
    let currentKey: string | null = null;
    let currentValue: string[] = [];

    for (let i = firstContentLineIndex; i < lines.length; i++) {
      const line = lines[i];

      if (line.trim().startsWith("_____")) break;

      // Check if this line starts with a key
      const keyMatch = line.match(/^([a-zA-Z_]+):\s*/);
      if (keyMatch) {
        // Save previous key-value pair
        if (currentKey) {
          data[currentKey] = currentValue.join(" ").trim();
        }

        // Start new key-value pair
        currentKey = keyMatch[1];
        const valueStart = keyMatch[0].length;
        currentValue = [line.substring(valueStart).trim()];
      } else if (currentKey) {
        // Continuation line
        if (line.trim()) {
          currentValue.push(line.trim());
        } else {
          // Empty line - preserve it in multiline values
          currentValue.push("");
        }
      }
    }

    // Save the last key-value pair
    if (currentKey) {
      // For empty lines, preserve them with special marker
      const joinedValue = currentValue
        .map(v => v === "" ? "  " : v)
        .join(" ")
        .trim()
        .replace(/\s{2,}/g, "  "); // Preserve double spaces as line breaks
      data[currentKey] = joinedValue;
    }
  }

  return data;
}

/**
 * Maps field names from snake_case to camelCase
 * @param data Record of key-value pairs
 * @returns Record with mapped field names
 */
function mapFieldNames(data: Record<string, string>): Record<string, string> {
  const mapped: Record<string, string> = {};

  for (const [key, value] of Object.entries(data)) {
    const mappedKey = FIELD_MAPPINGS[key];
    if (mappedKey) {
      mapped[mappedKey] = value;
    } else {
      mapped[key] = value;
    }
  }

  return mapped;
}
