## Chosen Approach
Implement a pure-function LegacyParser module that (1) parses legacy metadata strings into a typed LegacyMetadata object, (2) validates required fields, (3) maps to StandardYamlMetadata, and (4) renders standard YAML front-matter for integration in the migration pipeline.

## Rationale
- Simplicity: breaks the problem into four focused functions (parse, validate, convert, render) with clear inputs/outputs.
- Modularity: pure functions with no side effects, injectable in tests and in the CLI workflow.
- Testability: all logic lives in small functions that can be unit-tested against legacy fixtures without I/O or mocking.
- Coding standards: leverages strict TypeScript types, readonly data, and error classes for invalid metadata.
- Documentation: inline TSDoc on public functions explains *why* each step exists, with examples.

## Build Steps
1. Create `src/legacyParser.ts` exporting four pure functions:
   a. `parseLegacyMetadata(raw: string, format: MetadataFormat.LegacyHr | MetadataFormat.Unknown): LegacyMetadata` – split lines, handle multiline values, return typed map.
   b. `validateLegacyMetadata(meta: LegacyMetadata): void` – throw on missing `id` or `lastModified`.
   c. `convertToStandardYaml(meta: LegacyMetadata): StandardYamlMetadata` – rename keys (`lastModified`→`last_modified`, `derivedFrom`→`derived_from`, `enforcedBy`→`enforced_by`).
   d. `renderYamlFrontMatter(std: StandardYamlMetadata, lineBreak: string): string` – produce `"---\nkey: value\n...---\n"` string.
2. Write custom error classes (e.g., `InvalidMetadataError`) in the same module for validation failures.
3. In the migration workflow (e.g., `src/migrate.ts`), after `inspectFile` returns legacy content, call the parser functions in sequence; on success, splice in the YAML front matter and original content, preserving `lineBreakType`.
4. Unit-test each function in `test/legacyParser.spec.ts` against provided fixture metadata strings, including malformed and missing-field cases, verifying correct objects or thrown errors.
5. Add integration tests in `test/integration/migration.spec.ts` that run the full pipeline on fixture files, asserting file output matches expected YAML-prefixed content or error reporting for malformed metadata.
6. Ensure CI lint/format/type checks and coverage thresholds (95%+) are met; add TSDoc comments on public functions for maintenance and rationale.
