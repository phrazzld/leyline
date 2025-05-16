```
## Chosen Approach
Implement a line-by-line parser with state tracking to handle multiline values and map legacy snake_case keys to the target camelCase `LegacyMetadata` structure.

## Rationale
- **Simplicity First:** This approach offers the most straightforward implementation strategy for the identified legacy format, which involves simple key-value pairs potentially spanning multiple lines. It avoids the added complexity and dependencies of formal parsing libraries or the brittleness of complex regular expressions, aligning with the principle of favoring the simplest solution.
- **Modularity + strict separation:** The parser logic is contained within a single, dedicated `LegacyParser` module (`src/legacyParser.ts`), providing a clear separation of concerns for handling this specific legacy format.
- **Testability:** The parsing function takes a raw string and returns a structured object or throws a defined error, making it highly testable. Diverse test cases can be written to cover valid inputs, edge cases like multiline values, and various malformed data scenarios, ensuring reliable behavior.
- **Coding Standards:** The implementation will use standard TypeScript features, control flow, and explicit error handling via custom error classes, adhering to the project's coding standards and promoting readability.
- **Documentation Approach:** While the parsing logic is procedural, it is relatively easy to understand and can be documented with clear inline comments and TSDoc for the public function signature.

## Build Steps
1.  Create the file `src/legacyParser.ts`.
2.  Import necessary types, including `LegacyMetadata` from `../types.js`, and the `logger` from `../logger.js`.
3.  Define custom error classes, such as `LegacyParsingError` for structural parsing issues and `LegacyValidationError` for missing required metadata fields.
4.  Implement the main function `parseLegacyMetadata(rawMetadata: string): LegacyMetadata`, which accepts the raw string block extracted by the `MetadataInspector`.
5.  Inside `parseLegacyMetadata`, split the `rawMetadata` string into individual lines.
6.  Iterate through the lines, maintaining state to identify key-value pairs. Implement logic to:
    *   Skip or handle initial non-data lines (e.g., `#### ---`, blank lines, comment lines like `## ` if they appear in the raw block).
    *   Detect lines starting with `key: ` as the beginning of a new key-value pair.
    *   Append subsequent lines that do not start with `key: ` to the value of the current key, preserving indentation/newlines for multiline values.
7.  After parsing all lines, process the collected key-value pairs.
8.  Map the known snake_case keys found in the legacy data (e.g., `last_modified`, `derived_from`, `enforced_by`, `applies_to`) to their corresponding camelCase names in the `LegacyMetadata` interface (`lastModified`, `derivedFrom`, etc.). Assign values to the resulting `LegacyMetadata` object. Include any unknown keys as additional properties.
9.  Validate that the required fields (`id` and `lastModified`) are present and non-empty in the final `LegacyMetadata` object. If not, throw a `LegacyValidationError`.
10. Implement error handling within the parsing loop to catch malformed patterns (e.g., lines that are not key-value pairs and do not belong to a preceding multiline value) and throw a `LegacyParsingError`. Log these parsing errors using the imported `logger`.
11. Write comprehensive unit tests in `src/legacyParser.test.ts` covering:
    *   Valid single-line metadata.
    *   Valid metadata with multiline values.
    *   Metadata with extra, unknown fields.
    *   Metadata with missing required fields (`id`, `last_modified`).
    *   Malformed inputs (e.g., no colon, unexpected lines, incomplete blocks).
    *   Inputs with leading/trailing whitespace and various line break types.
```
