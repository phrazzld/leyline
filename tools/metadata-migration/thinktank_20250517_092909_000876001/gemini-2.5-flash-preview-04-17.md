## Chosen Approach
Implement the MetadataConverter as a pipeline of pure, focused transformation and validation functions orchestrated by a main conversion function.

## Rationale
- This approach prioritizes **Simplicity** by breaking down complex transformation logic into small, understandable steps.
- It strongly adheres to **Modularity** and strict separation by making each function responsible for one specific aspect (validation, normalization, mapping specific fields), fostering high cohesion and low coupling.
- It excels in **Testability** by maximizing the use of pure functions, which are trivial to test in isolation without any mocking, directly aligning with the philosophy's emphasis on easy, reliable automated verification and the strict anti-internal mocking policy.
- It naturally encourages adherence to **Coding Standards** by promoting small function sizes, clear input/output types, and immutability through functional transformation patterns.
- The **Documentation Approach** benefits from well-defined functions with clear TSDoc, making the code largely self-documenting, while the overall pipeline structure provides clear insight into the transformation flow.

## Build Steps
1.  Define or confirm availability of `LegacyMetadata` and `StandardYamlMetadata` TypeScript interfaces based on dependent tasks (T004, T005, T006, T009).
2.  Create the file `src/metadataConverter.ts`.
3.  Implement small, pure TypeScript functions for specific validation checks (e.g., `validateRequiredFields(legacy: LegacyMetadata): string[] | null`), returning errors or validated data.
4.  Implement small, pure TypeScript functions for data normalization (e.g., `normalizeString(input: string | undefined): string`, `parseDate(input: string | undefined): Date | null`).
5.  Implement small, pure TypeScript functions for mapping specific fields or groups of fields from `LegacyMetadata` to `StandardYamlMetadata` structure, utilizing the normalization functions.
6.  Implement functions or logic to handle identified "special cases" within the transformation pipeline, potentially as dedicated mapping functions or conditional logic within broader mapping steps.
7.  Create the main exported function, `convertLegacyToStandard(legacy: LegacyMetadata): StandardYamlMetadata`, which orchestrates the call sequence of validation, normalization, and mapping functions. Ensure this function handles errors from validation appropriately (e.g., throwing a specific error type).
8.  Write comprehensive unit tests (`src/metadataConverter.test.ts`) for each individual pure helper function, covering various inputs, edge cases, and expected outputs.
9.  Write integration tests for the main `convertLegacyToStandard` function, providing realistic `LegacyMetadata` samples to verify the end-to-end transformation pipeline, including happy paths, validation failure scenarios, and special cases.
10. Ensure all tests pass and meet defined code coverage thresholds.
11. Add TSDoc comments to the exported `convertLegacyToStandard` function, describing its purpose, parameters, return value, and potential errors thrown. Add internal comments explaining the *why* behind non-obvious transformation logic or special case handling.
