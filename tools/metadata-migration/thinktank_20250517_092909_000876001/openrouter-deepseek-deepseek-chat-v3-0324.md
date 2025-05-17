```
## Chosen Approach
Implement MetadataConverter as a pure function module with strict type safety and validation, using dependency injection for external services.

## Rationale
- **Simplicity:** Pure functions for transformation logic maintain simplicity and testability
- **Modularity:** Single responsibility - only handles metadata conversion without side effects
- **Testability:** Input/output testing with no mocking needed for core logic
- **Coding Standards:** Strict TypeScript with no `any`, immutability via `readonly`
- **Documentation:** TSDoc for public API with examples of transformations

## Build Steps
1. Create `src/metadataConverter.ts` with:
   - Input/Output types (LegacyMetadata, StandardYamlMetadata)
   - Core conversion functions (pure, immutable)
   - Validation utilities (schema-based)
2. Implement main `convertMetadata` function:
   - Accepts LegacyMetadata and optional config
   - Returns Result<StandardYamlMetadata, Error[]>
   - Uses composition of smaller transform functions
3. Add validation layer:
   - Zod schemas for both input and output
   - Collects all validation errors
4. Create comprehensive test suite:
   - Happy path tests for all metadata variants
   - Error cases for invalid inputs
   - Property-based testing for edge cases
5. Document public API with examples:
   - Conversion examples in TSDoc
   - Error handling patterns
   - Common use cases
