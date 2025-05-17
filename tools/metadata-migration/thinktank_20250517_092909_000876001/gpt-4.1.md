```
## Chosen Approach
Implement MetadataConverter as a pure, typed, functional transformer module in `src/metadataConverter.ts` with strict validation and normalization logic, explicit type contracts, and exhaustive test coverage.

## Rationale
- Maximizes simplicity and modularity: a single-purpose, stateless function with explicit input/output types, no side effects, and no infrastructure coupling.
- Highest testability: pure function, no internal mocking or hidden dependencies, enabling exhaustive unit and integration tests.
- Strict coding standards: leverages TypeScript strictest typing, immutability, and clear error handling; all code and types are self-documenting.
- Documentation focuses on API contracts (types/interfaces) and rationale for non-obvious transformation/validation rules.

## Build Steps
1. Define precise `LegacyMetadata` and `StandardYamlMetadata` TypeScript interfaces/types in `src/metadataConverter.ts`, describing all required and optional fields.
2. Implement a pure function `convertLegacyToStandardMetadata(input: LegacyMetadata): StandardYamlMetadata`:
    - Validate presence and correctness of all required fields (throwing custom typed errors for missing/invalid fields).
    - Normalize formats (dates, enumerations, casing, etc.) as per StandardYamlMetadata requirements.
    - Handle all specified "special cases" as explicit branches with rationale in code comments.
    - Ensure output object is deeply immutable (`readonly`).
3. Export only the types and converter function in the module; no infrastructure or I/O.
4. Write exhaustive Jest/Vitest unit tests in `src/metadataConverter.test.ts`, covering:
    - Happy path transformations
    - All validation errors (missing/invalid fields)
    - Edge cases and all documented special cases
    - Format normalization correctness
5. Document the module with:
    - TSDoc comments on all public types/functions, including `@throws` for possible errors
    - Brief rationale on transformation design and any non-obvious decisions
6. Ensure strict type-checking, linting, and full code/test coverage in CI.
```
