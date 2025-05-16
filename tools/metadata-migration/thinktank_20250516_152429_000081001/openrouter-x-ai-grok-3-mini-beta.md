## Chosen Approach
Implement a modular LegacyParser in TypeScript with separate detection and parsing logic, adhering to strict separation of concerns.

## Rationale
- **Simplicity:** This option uses straightforward functions for metadata detection and parsing, avoiding over-engineering by limiting to essential logic, while directly meeting requirements without unnecessary abstractions.
- **Modularity + strict separation:** Achieves the deepest green by isolating core parsing logic from infrastructure (e.g., file I/O detection), aligning with Dependency Inversion and Hexagonal Architecture guidelines.
- **Testability:** Ensures minimal mocking by designing pure functions for parsing, allowing unit tests to verify behavior in isolation without internal mocks, as per the testing strategy.
- **Coding standards:** Adheres strictly to TypeScript standards like `strict: true` and no `any`, with immutable data structures, outperforming other options that might introduce minor violations.
- **Documentation approach:** Prioritizes self-documenting code with TSDoc comments explaining rationale, over other options' potential for under-documented components.

## Build Steps
1. Create `src/legacyParser.ts` with exports for `detectFormat` (determines metadata type from content) and `parseMetadata` (converts raw metadata string to LegacyMetadata object).
2. Analyze legacy formats from fixtures (e.g., LegacyHr) by implementing `detectFormat` to check for patterns like YAML delimiters or HR markers, returning the appropriate MetadataFormat enum.
3. In `parseMetadata`, handle format-specific logic: for LegacyHr, split and map key-value pairs; for YAML, use a safe JSON.parse wrapper; validate required fields like `id` and throw typed errors if malformed.
4. Ensure modularity by separating concerns: use pure functions for parsing, inject dependencies via interfaces (e.g., for logging), and export only necessary types from the module.
5. Integrate testing: Write unit tests for `detectFormat` and `parseMetadata` using Jest, covering edge cases like empty files or unknown formats, with no internal mocking.
6. Add TSDoc comments to explain non-obvious choices, such as why specific format checks are ordered, and update `tsconfig.json` to enforce strict typing.
7. Review for risks: Address potential challenges like format variations by logging warnings and failing gracefully, ensuring the module handles malformed data per task requirements.
