```
## Chosen Approach
Implement a pure functional LegacyParser module in TypeScript, focused on robustly parsing raw legacy metadata strings into a typed `LegacyMetadata` object, with comprehensive error handling and clear validation logic.

## Rationale
- **Simplicity:** Adopts a stateless, pure functional approach for parsing, minimizing internal complexity and side effects, making the logic straightforward and easier to reason about.
- **Modularity + strict separation:** The parser will be a self-contained module with a clear input (raw string) and output (`LegacyMetadata` or errors), having no external dependencies beyond type definitions and potentially a logger interface, ensuring strict separation of concerns.
- **Testability (minimal mocking):** Pure functions are inherently easy to test; given an input, they produce a predictable output, requiring no mocking of dependencies or internal state. Test cases can directly verify parsing outcomes for various inputs.
- **Coding Standards:** The implementation will strictly adhere to TypeScript best practices, including `strict: true`, explicit typing (no `any`), use of `readonly` for input/output structures where appropriate, and consistent error handling patterns.
- **Documentation Approach:** Public functions and types will be documented using TSDoc. Rationale for complex parsing decisions or handling of specific legacy quirks will be included in comments within the implementation, prioritizing self-documenting code.

## Build Steps
1.  **Create `src/legacyParser.ts` and Define Core Types:**
    *   Initialize the `src/legacyParser.ts` file.
    *   Import necessary existing types (e.g., from `types.ts` as per T004, T005, T006).
    *   Define the `LegacyMetadata` interface if not already fully defined, ensuring it accurately represents the structure of parsed legacy data.
    *   Define custom error types (e.g., `LegacyParseError`, `MissingRequiredFieldError`) extending `Error` to provide structured error information (e.g., field name, line number, message).

2.  **Analyze Existing Legacy Formats:**
    *   Thoroughly review provided fixtures and examples of legacy metadata formats (e.g., `legacy-basic-tenet.md`, `legacy-multiline-values.md`, `malformed-incomplete-hr.md`).
    *   Identify key characteristics: delimiters (e.g., `#### ---`), key-value pair syntax, multiline value conventions, special character handling, and common variations or malformations.

3.  **Implement the Core Parsing Function:**
    *   Design a primary pure function, e.g., `parseLegacyMetadata(rawMetadataString: string): { metadata: LegacyMetadata | null; errors: LegacyParseError[] }`.
    *   **Input Processing:**
        *   Normalize line endings and trim whitespace from the input string.
        *   Split the input into lines.
    *   **Metadata Extraction:**
        *   Iterate through lines to identify and extract key-value pairs.
        *   Implement logic to correctly handle multiline values (e.g., lines indented or not starting with a new key are part of the previous key's value).
        *   Handle potential escape sequences or special characters within values if defined by the legacy format.
    *   Populate an intermediate raw data structure (e.g., `Record<string, string>`).

4.  **Transform to `LegacyMetadata` and Validate:**
    *   Convert the intermediate raw data structure into the strongly-typed `LegacyMetadata` object.
    *   Map legacy field names to `LegacyMetadata` property names if they differ (e.g., `last_modified` to `lastModified`).
    *   **Validation:**
        *   Check for the presence and non-emptiness of required fields (e.g., `id`, `lastModified`). Accumulate `MissingRequiredFieldError` if checks fail.
        *   Validate the format of specific fields if necessary (e.g., date formats). Accumulate `LegacyParseError` for format violations.
        *   Handle unknown fields: decide whether to include them in `LegacyMetadata` (e.g., in an `additionalProperties` field) or to log/report them as errors/warnings.

5.  **Error Reporting and Return Value:**
    *   The parsing function should return an object containing the parsed `LegacyMetadata` (or `null` if critical errors prevent object creation) and an array of any `LegacyParseError` instances encountered during parsing or validation.
    *   If malformed data is encountered that prevents further sensible parsing, the function should stop and return the errors found up to that point.
    *   Utilize the existing `Logger` (from T008) to log warnings or errors encountered during parsing, especially for recoverable issues or malformations that are handled gracefully.

6.  **Develop Comprehensive Unit Tests:**
    *   Create a co-located test file, e.g., `src/legacyParser.test.ts`.
    *   Write unit tests covering:
        *   Successful parsing of various valid legacy formats (using fixtures).
        *   Correct handling of multiline values.
        *   Parsing of metadata with all optional fields present and absent.
        *   Graceful handling of malformed data:
            *   Missing required fields.
            *   Incorrectly formatted values (e.g., dates).
            *   Incomplete or broken metadata blocks.
            *   Unexpected characters or syntax.
        *   Edge cases: empty input string, metadata block with no content, etc.
    *   Assert both the structure/content of the `LegacyMetadata` object and the accuracy of reported errors. Aim for high test coverage (e.g., >85%).

7.  **Documentation:**
    *   Add TSDoc comments to the main `parseLegacyMetadata` function, exported types (including custom errors), explaining their purpose, parameters, return values, and any thrown exceptions (though pure functions prefer returning errors).
    *   Include inline comments for complex logic or specific decisions made to handle legacy format quirks.
```
