```
## Chosen Approach
Implement a robust LegacyParser module that handles legacy metadata formats with strict validation and graceful error handling.

## Rationale
- Aligns with core philosophy of simplicity by focusing on parsing only known legacy formats
- Follows modularity principle by separating parsing logic from validation and transformation
- Enables testability through pure parsing functions with clear input/output contracts
- Handles malformed data explicitly as required by the task
- Maintains strict type safety throughout the parsing process

## Build Steps
1. Create src/legacyParser.ts with core parsing functions:
   - parseLegacyMetadata(rawText): LegacyMetadata
   - validateLegacyMetadata(parsed): boolean
   - normalizeLegacyMetadata(parsed): StandardYamlMetadata

2. Implement format detection:
   - Identify HR-delimited blocks
   - Handle key-value pairs with special character escaping
   - Support multiline values

3. Add validation:
   - Required fields (id, last_modified)
   - Field format validation (dates, IDs)
   - Unknown field detection

4. Implement error handling:
   - Structured error types for different failure modes
   - Recovery attempts for common malformations
   - Detailed error messages with context

5. Write comprehensive tests:
   - Happy path for all legacy format variations
   - Malformed input scenarios
   - Edge cases (empty values, special chars)
   - Round-trip parsing/normalization checks
```
