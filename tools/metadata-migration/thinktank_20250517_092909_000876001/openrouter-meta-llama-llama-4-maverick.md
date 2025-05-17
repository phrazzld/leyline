## Chosen Approach
Implement MetadataConverter module using a transform function that maps LegacyMetadata to StandardYamlMetadata.

## Rationale
- The implementation will follow the simplicity principle by using a straightforward transform function.
- Modularity is maintained by keeping the MetadataConverter module separate and focused on its responsibility.
- Testability is ensured by designing the transform function to be easily testable with various LegacyMetadata inputs.
- Coding standards will be adhered to by using strict TypeScript typing and following the project's linting rules.
- Documentation will focus on explaining the rationale behind the transformation logic and any non-obvious decisions.

## Build Steps
1. Create `src/metadataConverter.ts` with the necessary imports and type definitions for LegacyMetadata and StandardYamlMetadata.
2. Implement the `transformLegacyMetadata` function that takes LegacyMetadata as input and returns StandardYamlMetadata.
3. Within the `transformLegacyMetadata` function, validate required fields and normalize formats as necessary.
4. Handle special cases and edge conditions as identified in the LegacyMetadata specification.
5. Write comprehensive unit tests for the `transformLegacyMetadata` function to ensure correctness and handle various input scenarios.
6. Integrate the MetadataConverter module into the relevant parts of the application, ensuring it is properly used and tested in the larger context.
