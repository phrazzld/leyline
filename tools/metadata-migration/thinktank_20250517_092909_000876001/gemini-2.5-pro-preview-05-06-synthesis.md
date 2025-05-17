## Chosen Approach
Implement the `MetadataConverter` module as a functional pipeline composed of pure, focused helper functions for validation, normalization, and transformation, orchestrated by a main conversion function that returns a typed result indicating success or failure with detailed errors.

## Rationale
- **Simplicity:** This approach excels by breaking down the complex transformation into small, easily understandable pure functions, each with a single responsibility. This manages essential complexity effectively, aligning with "Simplicity First."
- **Modularity + strict separation:** Helper functions for validation, specific normalizations (e.g., date formatting, string-to-array), and field mapping are distinct and self-contained. This directly supports "Modularity is Mandatory" and "Strict Separation of Concerns," allowing independent development, testing, and maintenance.
- **Testability (minimal mocking):** Pure helper functions are highly testable in isolation, requiring no mocks for their internal logic. The main orchestrator function's logic is tested by verifying its composition of these well-tested units, adhering to "Design for Testability" and minimizing mocking.
- **Coding Standards:** The use of pure functions, immutable data patterns (inputs are not mutated; new objects/values are returned), and strong TypeScript typing (e.g., `noImplicitAny`, `strictNullChecks`) naturally meets "Coding Standards" and "Maximize Language Strictness."
- **Documentation Approach:** Each pure function, along with the main orchestrator, will have clear TSDoc comments defining its API contract (parameters, return value, errors). This makes the code largely self-documenting for "what" it does, with comments focusing on the "why" for non-obvious logic, fitting "Document Decisions, Not Mechanics."

## Build Steps
1.  **Setup & Type Definitions:**
    *   Create `src/metadataConverter.ts`.
    *   Define or import `LegacyMetadata` and `StandardYamlMetadata` TypeScript interfaces (as per dependencies T004, T005, T006, T009).
    *   Define helper types: `ValidationError { fieldPath: string; message: string; }` and a discriminated union for the result: `ConversionResult = { success: true; data: StandardYamlMetadata; } | { success: false; errors: ValidationError[]; }`.
2.  **Implement Pure Helper Functions:**
    *   Develop focused, pure TypeScript functions for distinct stages:
        *   **Validation:** Functions like `validateLegacyInput(legacy: LegacyMetadata): ValidationError[]` to check for required fields and basic structural integrity of the input.
        *   **Normalization:** Small functions like `normalizeDate(dateString?: string): string | undefined`, `normalizeStringToArray(text?: string): string[]`, `sanitizeString(text?: string): string | undefined` for consistent data formatting.
        *   **Mapping & Special Cases:** Functions responsible for mapping specific parts of `LegacyMetadata` to `StandardYamlMetadata`, incorporating normalization logic and explicitly handling any documented "special cases."
3.  **Implement Main `convertMetadata` Orchestrator Function:**
    *   Create the primary exported function: `export function convertMetadata(legacy: LegacyMetadata): ConversionResult`.
    *   This function will:
        *   Invoke initial validation helpers.
        *   Sequentially call mapping and normalization helpers to build the `StandardYamlMetadata` object.
        *   Aggregate any errors encountered during validation, normalization, or mapping.
        *   If errors are present, return `{ success: false, errors: collectedErrors }`.
        *   If successful, return `{ success: true, data: resultingStandardMetadata }`.
4.  **Develop Comprehensive Tests:**
    *   Create `src/metadataConverter.test.ts`.
    *   Write unit tests for each individual validation, normalization, and mapping helper function, covering various inputs, edge cases, and expected outputs/errors.
    *   Write integration tests for the main `convertMetadata` function, using diverse `LegacyMetadata` samples to verify:
        *   Correct end-to-end transformation for valid inputs.
        *   Accurate error reporting (correct `ValidationError` objects) for invalid inputs or transformation failures.
        *   Proper handling of all specified "special cases."
5.  **Documentation & Standards Adherence:**
    *   Add TSDoc comments to all exported types and functions, clearly describing their purpose, parameters, return values (including the structure of `ConversionResult`), and any specific error conditions.
    *   Ensure the entire implementation adheres to project coding standards (linting, formatting), TypeScript strictness settings, and promotes immutability.
    *   Integrate with CI pipeline for automated type checking, linting, testing, and code coverage analysis.
