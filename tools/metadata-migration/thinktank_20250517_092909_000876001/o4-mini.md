## Chosen Approach
Implement a pure‐function MetadataConverter module that validates, normalizes, and transforms LegacyMetadata into StandardYamlMetadata in three clear steps.

## Rationale
- Keeps core logic simple and explicit: separate `validate`, `normalize`, and `transform` functions avoid overengineering.
- High modularity: each responsibility lives in its own function, enabling independent maintenance and clear interfaces.
- Testability guaranteed: pure functions with no side effects facilitate fast, isolated unit tests for each step and edge case.
- Adheres to TypeScript standards: strict typing, no `any`, explicit error classes, and TSDoc comments for public APIs.
- Documentation via code and TSDoc explains the *why*, minimizing external docs while surface types describe the *what*.

## Build Steps
1. Define TypeScript interfaces in `src/types.ts`:
   - `LegacyMetadata` with optional and required fields
   - `StandardYamlMetadata` with normalized, mandatory fields
2. Create custom error classes in `src/errors.ts`:
   - `MissingFieldError` for absent required properties
   - `ValidationError` for format violations
3. In `src/metadataConverter.ts`, implement `validateLegacyMetadata(legacy: LegacyMetadata): void`:
   - Check presence and primitive types of required fields
   - Throw `MissingFieldError` or `ValidationError` with context
4. Implement `normalizeLegacyMetadata(legacy: LegacyMetadata): NormalizedMetadata`:
   - Parse dates to ISO strings, trim strings, split comma lists, enforce lowercase IDs
   - Return a new immutably updated object
5. Implement `transformMetadata(legacy: LegacyMetadata): StandardYamlMetadata`:
   - Call `validateLegacyMetadata`, then `normalizeLegacyMetadata`
   - Map normalized fields into the `StandardYamlMetadata` shape
6. Add TSDoc comments for all exported types and functions, explaining purpose and usage, including `@throws` tags.
7. Write unit tests in `tests/metadataConverter.test.ts`:
   - Test missing fields, invalid formats, correct normalization, and full transformation
   - Cover edge cases (empty arrays, nulls, unexpected extra fields)
8. Configure CI to run `tsc --noEmit`, `eslint --max-warnings=0`, and Jest with coverage thresholds on the new module.
