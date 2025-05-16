## Chosen Approach
Implement the LegacyParser module in TypeScript with a focus on robust parsing of legacy HR metadata into a structured LegacyMetadata object, emphasizing simplicity, modularity, and testability.

## Rationale
- **Simplicity**: The chosen approach prioritizes straightforward logic for parsing legacy HR metadata, avoiding over-engineering by focusing on essential parsing rules and error handling, aligning with the core philosophy of "Simplicity First."
- **Modularity**: By isolating parsing logic within a dedicated `LegacyParser` module, it ensures strict separation of concerns, adhering to "Modularity is Mandatory" and allowing independent evolution or replacement.
- **Testability**: The design avoids internal mocking by using pure functions and clear interfaces, supporting "Design for Testability" with easy unit testing of parsing outcomes.
- **Coding Standards**: Adherence to TypeScript strict typing (`strict: true`) and structured logging (JSON output via existing `Logger`) ensures compliance with mandatory standards in the appendices.
- **Documentation Approach**: Focus on self-documenting code with TSDoc comments for public APIs, supplemented by rationale comments for complex logic, aligns with "Document Decisions, Not Mechanics."

## Build Steps
1. **Create src/legacyParser.ts**: Initialize the file with necessary imports from existing modules (`types.ts`, `logger.ts`) and define the `LegacyParser` namespace or class to encapsulate parsing functionality.
2. **Analyze Legacy Formats**: Review provided fixtures (e.g., `legacy-basic-tenet.md`, `legacy-multiline-values.md`) to identify patterns (e.g., HR delimiters, key-value pairs, multiline values, special characters) and edge cases (e.g., malformed metadata in `malformed-incomplete-hr.md`).
3. **Define Parsing Logic**: Implement a `parseLegacyMetadata` function to extract metadata between HR delimiters (`#### ---` or similar), split into key-value pairs, handle multiline values by concatenating lines until a new key or end, and validate required fields (`id`, `last_modified`).
4. **Map to LegacyMetadata**: Transform parsed raw data into a typed `LegacyMetadata` object, ensuring type safety with explicit casting or validation, and log warnings for missing required fields or malformed data using the existing `Logger`.
5. **Handle Errors Gracefully**: Add error handling to return a default or partial `LegacyMetadata` object for malformed input, logging detailed errors (JSON format) for debugging without crashing, aligning with "Consistent Error Handling."
6. **Write Unit Tests**: Create co-located test files (`legacyParser.test.ts`) using Jest or Vitest, covering happy paths (basic metadata), edge cases (multiline, special chars), and failures (missing fields, malformed delimiters), ensuring 85%+ coverage per CI standards.
7. **Document Public API**: Use TSDoc comments to document the `parseLegacyMetadata` function, explaining inputs, outputs, and error behavior, focusing on *why* certain parsing rules are applied (e.g., handling legacy quirks).
8. **Integrate with Existing Code**: Ensure compatibility with `metadataInspector.ts` by accepting `InspectedContent` metadata string as input, and output `LegacyMetadata` for further processing in the migration tool.
