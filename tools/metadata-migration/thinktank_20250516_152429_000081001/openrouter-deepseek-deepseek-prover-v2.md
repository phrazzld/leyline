## Chosen Approach
Implement the `LegacyParser` module with a focus on simplicity, modularity, and testability, adhering to strict coding standards and comprehensive documentation.

## Rationale
- **Simplicity**: The approach uses straightforward parsing logic and avoids unnecessary complexity by focusing on the core requirements of parsing legacy metadata formats.
- **Modularity**: The parser is designed as a standalone module with clear interfaces, making it easy to integrate and test independently.
- **Testability**: The parser is designed to be easily testable with unit tests, ensuring that it correctly handles various legacy metadata formats and malformed data.
- **Coding Standards**: The implementation follows TypeScript best practices, including strict typing, immutability, and error handling, ensuring high code quality.
- **Documentation Approach**: The code is well-documented with clear explanations of the parsing logic and error handling, making it easy to understand and maintain.

## Build Steps
1. **Create `src/legacyParser.ts`**:
   - Implement the `LegacyParser` class with methods to parse raw metadata into a `LegacyMetadata` object.
   - Include error handling for malformed data and validation of required fields.
   - Ensure the parser can handle variations in legacy metadata formats.

2. **Analyze Existing Legacy Formats**:
   - Review the provided test fixtures to understand the variations in legacy metadata formats.
   - Identify common patterns and edge cases to ensure the parser can handle all expected variations.

3. **Implement Parsing Logic**:
   - Use regular expressions and string manipulation to extract metadata fields from the raw metadata string.
   - Validate the presence of required fields (`id` and `lastModified`) and handle missing or malformed data appropriately.
   - Ensure the parser can handle special characters and multiline values in metadata fields.

4. **Handle Malformed Data**:
   - Implement robust error handling to detect and report malformed metadata, such as missing required fields or incomplete metadata blocks.
   - Provide clear error messages to help users identify and fix issues in their metadata.

5. **Write Unit Tests**:
   - Create unit tests for the `LegacyParser` to ensure it correctly parses valid legacy metadata and handles malformed data gracefully.
   - Use the provided test fixtures to cover various edge cases and ensure comprehensive test coverage.

6. **Integrate with the Rest of the System**:
   - Ensure the `LegacyParser` can be easily integrated with other modules, such as the `MetadataInspector` and `MigrationEngine`.
   - Verify that the parsed `LegacyMetadata` objects are correctly transformed into `StandardYamlMetadata` objects during the migration process.

7. **Document the Module**:
   - Provide clear documentation for the `LegacyParser` module, including usage examples and explanations of the parsing logic.
   - Ensure that all public methods and interfaces are well-documented to facilitate easy integration and maintenance.
