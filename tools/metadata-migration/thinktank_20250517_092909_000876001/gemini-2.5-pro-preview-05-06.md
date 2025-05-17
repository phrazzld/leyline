## Chosen Approach
Implement the MetadataConverter module as a primary orchestration function that composes several smaller, pure helper functions for distinct stages: mapping legacy structure, normalizing field values, and validating the result against the standard metadata definition. This approach ensures high modularity, testability, and maintainability.

## Rationale
- **Simplicity:** This approach enhances simplicity by decomposing the complex transformation into manageable, focused pure functions. Each function has a clear, single responsibility, making it easier to understand, develop, and debug than a monolithic alternative. (Ref: Core Principle 1: Simplicity First)
- **Modularity + strict separation:** The design strictly separates concerns: `mapLegacyToStandardShape` handles structural mapping, `normalizeFieldValues` handles data formatting, and `validateStandardStructureAndValues` handles validation. This aligns perfectly with "Modularity is Mandatory" and "Strict Separation of Concerns."
- **Testability (minimal mocking):** Each helper function is pure (output depends only on input, no side effects) and can be unit-tested thoroughly in isolation without any mocking. The main `convertMetadata` function is tested by verifying the orchestration of these well-tested units. (Ref: Core Principle 3: Design for Testability; Testing Strategy: Mocking Policy)
- **Coding Standards:** The use of pure functions, immutable data patterns (inputs are not mutated, new objects are returned), and strong typing (via TypeScript, with no `any`) naturally adheres to the project's "Coding Standards" and the "TypeScript Appendix."
- **Documentation Approach:** Each function (main orchestrator and helpers) will have clear TSDoc comments explaining its specific purpose, parameters, return values, and any special case handling, fulfilling the "Document Decisions, Not Mechanics" principle.

## Build Steps
1.  **Setup and Type Definitions:**
    *   Create `src/metadataConverter.ts`.
    *   Ensure `LegacyMetadata` and `StandardYamlMetadata` types are imported or defined (as per dependencies T004, T005, T006, T009).
    *   Define helper types within `src/metadataConverter.ts` or a shared types file:
        ```typescript
        export interface ValidationError {
            field: string; // Path to the field, e.g., "title", "keywords[0]"
            message: string;
        }

        export type ConversionResult =
            | { success: true; data: StandardYamlMetadata }
            | { success: false; errors: ValidationError[] };
        ```

2.  **Implement `mapLegacyToStandardShape` Function:**
    *   Signature: `function mapLegacyToStandardShape(legacy: LegacyMetadata): Partial<StandardYamlMetadata>`
    *   Responsibility:
        *   Perform direct field-to-field mapping from `LegacyMetadata` to a `Partial<StandardYamlMetadata>` object.
        *   Handle structural transformations (e.g., splitting a legacy string field into a standard array field, combining multiple legacy fields into one standard field).
        *   Address special cases related to mapping logic, such as conditional mapping or providing default values for standard fields if corresponding legacy fields are absent but the mapping logic dictates a default at this stage.
    *   Ensure the function is pure and returns a new object.

3.  **Implement `normalizeFieldValues` Function:**
    *   Signature: `function normalizeFieldValues(data: Partial<StandardYamlMetadata>): Partial<StandardYamlMetadata>`
    *   Responsibility:
        *   Take the `Partial<StandardYamlMetadata>` from the mapping step.
        *
