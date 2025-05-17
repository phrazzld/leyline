```
## Chosen Approach
Functional composition with pure transformation pipelines, strict validation layers, and atomic normalization utilities.

## Rationale
- **Simplicity:** Atomic functions with single responsibilities avoid OOP ceremony while maintaining clear data flow
- **Modularity:** Separation of transform/validate/normalize enables independent testing and future extension
- **Testability:** Pure functions require zero mocking - input/output verification suffices
- **Coding Standards:** Immutable patterns and strict typing align with philosophy mandates
- **Docs Approach:** JSDoc + type signatures provide machine-checked API documentation

## Build Steps
1. Create `src/metadataConverter.ts` with:
   - Type guards for legacy field detection
   - Validation chain using Zod schemas
   - Normalization utilities (dates/strings/formats)
   - Pipeline function composing transforms
2. Implement recursive field mapping:
   - Handle nested structures via depth-first traversal
   - Convert snake_case to camelCase using regex patterns
   - Apply conditional formatting based on detected types
3. Add validation middleware:
   - Required field checks with contextual errors
   - Type consistency verification post-conversion
   - Custom error classes for special case handling
4. Create `src/metadataConverter.test.ts` with:
   - Golden master tests for core transformation
   - Property-based testing for edge cases
   - Schema validation failure test matrix
5. Integrate with CI pipeline:
   - Type checking as quality gate
   - 100% branch coverage requirement
   - Benchmark performance metrics
```
