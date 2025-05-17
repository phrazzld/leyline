/**
 * MetadataConverter module for transforming legacy metadata to standard YAML format.
 * Provides validation, normalization, and field mapping functionality.
 */

import { LegacyMetadata, StandardYamlMetadata } from "./types.js";
import { logger } from "./logger.js";

/**
 * Represents a validation error with field path and message
 */
export interface ValidationError {
  /** The field path where the error occurred */
  fieldPath: string;
  /** Human-readable error message */
  message: string;
}

/**
 * Options for the conversion process
 */
export interface ConversionOptions {
  /** Filename to validate ID against (optional) */
  filename?: string;
}

/**
 * Result of the metadata conversion process
 */
export type ConversionResult =
  | { success: true; data: StandardYamlMetadata }
  | { success: false; errors: ValidationError[] };

/**
 * Converts legacy metadata to standard YAML metadata format.
 * Performs validation, normalization, and field mapping.
 *
 * @param legacy - The legacy metadata to convert
 * @param options - Optional conversion options
 * @returns ConversionResult with either converted data or validation errors
 */
export function convertMetadata(
  legacy: LegacyMetadata,
  options: ConversionOptions = {},
): ConversionResult {
  logger.debug("Starting metadata conversion", { id: legacy?.id });

  // Validate input
  if (!legacy || typeof legacy !== "object") {
    return {
      success: false,
      errors: [
        { fieldPath: "", message: "Invalid input: metadata object required" },
      ],
    };
  }

  // Collect all validation errors
  const errors: ValidationError[] = [];

  // Validate required fields
  errors.push(...validateRequiredFields(legacy));

  // Validate field formats
  if (legacy.lastModified) {
    const dateError = validateDateFormat(legacy.lastModified);
    if (dateError) errors.push(dateError);
  }

  // Validate ID matches filename if provided
  if (options.filename && legacy.id) {
    const filenameError = validateIdMatchesFilename(
      legacy.id,
      options.filename,
    );
    if (filenameError) errors.push(filenameError);
  }

  // Log deprecated fields
  logDeprecatedFields(legacy);

  // Return early if validation fails
  if (errors.length > 0) {
    logger.warn("Metadata conversion failed", { errorCount: errors.length });
    return { success: false, errors };
  }

  try {
    // Map fields to standard format
    const coreFields = mapCoreFields(legacy);
    const optionalFields = mapOptionalFields(legacy);

    // Combine into final metadata
    const standardMetadata: StandardYamlMetadata = {
      ...coreFields,
      ...optionalFields,
    } as StandardYamlMetadata;

    logger.info("Metadata conversion successful", { id: standardMetadata.id });
    return { success: true, data: standardMetadata };
  } catch (error) {
    logger.error("Unexpected error during conversion", {
      error: error instanceof Error ? error.message : String(error),
    });
    errors.push({
      fieldPath: "",
      message:
        error instanceof Error ? error.message : "Unknown error occurred",
    });
    return { success: false, errors };
  }
}

/**
 * Validates that required fields are present and non-empty
 */
function validateRequiredFields(legacy: LegacyMetadata): ValidationError[] {
  const errors: ValidationError[] = [];

  if (!legacy.id) {
    errors.push({ fieldPath: "id", message: "Required field missing" });
  }

  if (!legacy.lastModified) {
    errors.push({
      fieldPath: "lastModified",
      message: "Required field missing",
    });
  }

  return errors;
}

/**
 * Validates date format (ISO 8601: YYYY-MM-DD)
 */
function validateDateFormat(date: string): ValidationError | null {
  // Extract date part if time component is present
  const datePart = date.split("T")[0];

  // Remove quotes if present
  const unquoted = datePart.replace(/^['"]|['"]$/g, "");

  // Check ISO 8601 date format
  const isoDatePattern = /^\d{4}-\d{2}-\d{2}$/;
  if (!isoDatePattern.test(unquoted)) {
    return {
      fieldPath: "lastModified",
      message: "Date must be in ISO 8601 format (YYYY-MM-DD)",
    };
  }

  return null;
}

/**
 * Validates that the metadata ID matches the filename
 */
function validateIdMatchesFilename(
  id: string,
  filename: string,
): ValidationError | null {
  const expectedId = filename.replace(/\.md$/, "");
  const normalizedId = normalizeIdentifier(id);
  const normalizedExpected = normalizeIdentifier(expectedId);

  if (normalizedId !== normalizedExpected) {
    return {
      fieldPath: "id",
      message: `ID "${id}" does not match filename "${expectedId}"`,
    };
  }

  return null;
}

/**
 * Logs warnings for deprecated fields
 */
function logDeprecatedFields(legacy: LegacyMetadata): void {
  if (legacy.appliesTo) {
    logger.warn('Deprecated field "appliesTo" found in metadata', {
      id: legacy.id,
      appliesTo: legacy.appliesTo,
    });
  }
}

/**
 * Normalizes date string by removing quotes and extracting date part
 */
function normalizeDate(dateString: string): string {
  // Remove quotes if present
  let normalized = dateString.replace(/^['"]|['"]$/g, "");

  // Extract date part if time component is present
  normalized = normalized.split("T")[0];

  return normalized;
}

/**
 * Normalizes identifier by removing .md extension and normalizing format
 */
function normalizeIdentifier(id: string): string {
  // Remove .md extension if present
  let normalized = id.replace(/\.md$/, "");

  // Convert to lowercase and replace each special character with a hyphen
  normalized = normalized.toLowerCase().replace(/[^a-z0-9-]/g, "-");

  return normalized;
}

/**
 * Maps core required fields from legacy to standard format
 */
function mapCoreFields(
  legacy: LegacyMetadata,
): Pick<StandardYamlMetadata, "id" | "last_modified"> {
  return {
    id: normalizeIdentifier(legacy.id),
    last_modified: normalizeDate(legacy.lastModified),
  };
}

/**
 * Maps optional fields from legacy to standard format
 */
function mapOptionalFields(
  legacy: LegacyMetadata,
): Partial<StandardYamlMetadata> {
  const fields: Partial<StandardYamlMetadata> = {};

  if (legacy.derivedFrom) {
    fields.derived_from = legacy.derivedFrom;
  }

  if (legacy.enforcedBy) {
    fields.enforced_by = legacy.enforcedBy;
  }

  // Note: appliesTo is deprecated and not mapped to standard format
  // Additional unknown fields are not preserved in StandardYamlMetadata

  return fields;
}
