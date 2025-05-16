## Chosen Approach
Implement a LegacyParser module in TypeScript that can parse legacy metadata formats and convert them into the standard YAML front-matter format.

## Rationale
- The task requires analyzing existing legacy formats to understand variations, which implies that the solution must be flexible and adaptable to different input formats.
- The LegacyParser module needs to be implemented in TypeScript, adhering to the project's coding standards and guidelines outlined in the DEVELOPMENT_PHILOSOPHY.md and its appendices.
- The parser should be able to handle malformed data, indicating that robust error handling is necessary.
- The output of the parser should be a LegacyMetadata object, which will then be converted into the standard YAML front-matter format.

## Build Steps
1. Create a new TypeScript module `legacyParser.ts` in the `src` directory.
2. Define the `LegacyMetadata` interface in `types.ts` to represent the structure of the legacy metadata.
3. Implement the `LegacyParser` class in `legacyParser.ts`, which will contain methods for parsing different legacy metadata formats.
4. Use regular expressions or string manipulation to extract metadata from the input files.
5. Handle different line break types (`\n`, `\r\n`, `\r`) and be robust against minor formatting variations.
6. Implement error handling to detect and report malformed metadata.
7. Write unit tests for the `LegacyParser` class to ensure it correctly handles various input scenarios, including valid and malformed data.
8. Integrate the `LegacyParser` into the metadata migration pipeline.
