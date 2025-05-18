/**
 * MetadataConverter module for transforming legacy metadata to standard YAML format.
 *
 * This module handles the transformation of parsed legacy metadata into the standardized
 * YAML front-matter format. It provides validation, normalization, and field mapping
 * functionality to ensure data integrity during the conversion process.
 *
 * @remarks
 * The converter is designed to be strict about data validation to ensure that converted
 * metadata meets all requirements of the standard format. Key responsibilities include:
 * - Validating required fields (id, last_modified)
 * - Ensuring proper date formatting (ISO 8601)
 * - Verifying ID matches filename
 * - Mapping field names appropriately
 * - Logging deprecated fields for awareness
 *
 * The converter returns detailed validation errors when conversion fails, enabling
 * proper error handling and user feedback.
 */

import { LegacyMetadata, StandardYamlMetadata } from "./types.js";
import { logger } from "./logger.js";

/**
 * Represents a validation error with field path and message.
 *
 * @remarks
 * Validation errors provide structured information about what went wrong
 * during conversion, including the specific field path where the error
 * occurred and a human-readable error message.
 */
export interface ValidationError {
  /** The field path where the error occurred */
  fieldPath: string;
  /** Human-readable error message */
  message: string;
}

/**
 * Options for the conversion process.
 *
 * @remarks
 * Conversion options allow customization of the validation process,
 * such as providing the filename to validate against the metadata ID.
 */
export interface ConversionOptions {
  /**
   * Filename to validate ID against (optional)
   * @remarks Should be the basename without path (e.g., "example.md")
   */
  filename?: string;
}

/**
 * Result of the metadata conversion process.
 *
 * @remarks
 * Uses a discriminated union to provide type-safe success/failure results.
 * On success, contains the converted StandardYamlMetadata. On failure,
 * contains an array of validation errors explaining what went wrong.
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
 *
 * @remarks
 * This is the main entry point for metadata conversion. The function:
 * 1. Validates the input is a valid object
 * 2. Checks all required fields are present
 * 3. Validates field formats (dates, IDs)
 * 4. Maps fields to the standard format
 * 5. Returns the converted metadata or validation errors
 *
 * The conversion process is strict to ensure data integrity. Any validation
 * errors will cause the conversion to fail, returning a detailed error report.
 *
 * @example
 * ```typescript
 * const result = convertMetadata(legacyMetadata, {
 *   filename: 'example.md'
 * });
 *
 * if (result.success) {
 *   console.log(result.data.id); // Normalized ID
 * } else {
 *   console.error(result.errors);
 * }
 * ```
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
 * Validates that required fields are present and non-empty.
 *
 * @param legacy - Legacy metadata to validate
 * @returns Array of validation errors for missing required fields
 *
 * @remarks
 * Checks for the presence of 'id' and 'lastModified' fields, which are
 * mandatory in both legacy and standard formats. Empty strings are
 * considered missing values.
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
 * Validates date format (ISO 8601: YYYY-MM-DD).
 *
 * @param date - Date string to validate
 * @returns ValidationError if format is invalid, null otherwise
 *
 * @remarks
 * Accepts dates in ISO 8601 format. The function handles:
 * - Dates with or without quotes
 * - Dates with time components (extracts date part only)
 * - Basic format validation using regex
 *
 * Note: This doesn't validate if the date is actually valid
 * (e.g., 2024-13-45 would pass the format check).
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
 * Validates that the metadata ID matches the filename.
 *
 * @param id - Metadata ID to validate
 * @param filename - Filename to match against
 * @returns ValidationError if ID doesn't match, null otherwise
 *
 * @remarks
 * The ID should match the filename without the .md extension.
 * Both values are normalized (lowercase, special chars to hyphens)
 * before comparison to allow for minor formatting differences.
 *
 * @example
 * ```typescript
 * // Valid match
 * validateIdMatchesFilename('api-design', 'api-design.md'); // null
 *
 * // Invalid match
 * validateIdMatchesFilename('api-design', 'api_design.md'); // ValidationError
 * ```
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
 * Logs warnings for deprecated fields.
 *
 * @param legacy - Legacy metadata to check for deprecated fields
 *
 * @remarks
 * Currently checks for the 'appliesTo' field, which is deprecated
 * and will not be included in the converted metadata. This provides
 * visibility into data that will be lost during conversion.
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
 * Normalizes date string by removing quotes and extracting date part.
 *
 * @param dateString - Date string to normalize
 * @returns Normalized date string
 *
 * @remarks
 * Handles various date string formats:
 * - Quoted dates: "'2024-03-15'" → "2024-03-15"
 * - DateTime strings: "2024-03-15T10:30:00" → "2024-03-15"
 * - Already normalized: "2024-03-15" → "2024-03-15"
 */
function normalizeDate(dateString: string): string {
  // Remove quotes if present
  let normalized = dateString.replace(/^['"]|['"]$/g, "");

  // Extract date part if time component is present
  normalized = normalized.split("T")[0];

  return normalized;
}

/**
 * Normalizes identifier by removing .md extension and normalizing format.
 *
 * @param id - Identifier to normalize
 * @returns Normalized identifier
 *
 * @remarks
 * Normalization process:
 * 1. Removes .md extension if present
 * 2. Converts to lowercase
 * 3. Replaces special characters with hyphens
 *
 * This ensures consistent ID formatting across the system.
 *
 * @example
 * ```typescript
 * normalizeIdentifier("API_Design.md");  // "api-design"
 * normalizeIdentifier("api design");     // "api-design"
 * normalizeIdentifier("API-DESIGN");     // "api-design"
 * ```
 */
function normalizeIdentifier(id: string): string {
  // Remove .md extension if present
  let normalized = id.replace(/\.md$/, "");

  // Convert to lowercase and replace each special character with a hyphen
  normalized = normalized.toLowerCase().replace(/[^a-z0-9-]/g, "-");

  return normalized;
}

/**
 * Maps core required fields from legacy to standard format.
 *
 * @param legacy - Legacy metadata containing core fields
 * @returns Object with mapped core fields
 *
 * @remarks
 * Maps the required fields with appropriate transformations:
 * - id: Normalized to lowercase with special chars as hyphens
 * - lastModified → last_modified: Date normalized to ISO format
 *
 * These fields are always present due to prior validation.
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
 * Maps optional fields from legacy to standard format.
 *
 * @param legacy - Legacy metadata containing optional fields
 * @returns Object with mapped optional fields
 *
 * @remarks
 * Maps optional fields with snake_case naming:
 * - derivedFrom → derived_from
 * - enforcedBy → enforced_by
 *
 * Note that:
 * - appliesTo is deprecated and not mapped
 * - Unknown fields are not preserved in the standard format
 * - Only fields defined in StandardYamlMetadata are included
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
