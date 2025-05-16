```
## Chosen Approach
Pure functional parser with strict field validation and robust error reporting for legacy metadata.

## Rationale
- Delivers maximum simplicity: stateless pure parsing, no class/OO, no mutation, no side effects.
- Achieves strict modularity: parser is a single function with helpers, no I/O, no coupling to logger or file system.
- Guarantees testability: deterministic, pure, no global state, no mocks needed.
- Fully aligns with coding standards: all types explicit, no `any`, strong error/edge-case handling.
- Documentation: TSDoc for function and types, rationale in top-level module comment only.

## Build Steps
1. Create `src/legacyParser.ts`.
2. Define strong types: `LegacyMetadata`, `LegacyParseError` (with code, message, and line/column position).
3. Implement `parseLegacyMetadata(raw: string): { metadata: LegacyMetadata; errors: LegacyParseError[] }`:
    - Tokenize input into lines, trim whitespace.
    - Parse key-value pairs (`key: value`) with robust splitting (handle multiline, special chars, whitespace).
    - Collect all fields into a canonical object; preserve unknown fields (dynamic keys).
    - Validate required fields (`id`, `lastModified`), validate date format (ISO 8601).
    - Detect malformed/missing fields, duplicate keys, blank lines in metadata block.
    - Return parsed object and array of errors (empty if parse is clean).
4. Thoroughly test:
    - All valid legacy fixture files (single/multiline, special chars, edge cases).
    - Malformed files: missing required, incomplete HR, duplicate keys, broken lines.
    - Assert full round-trip and error detection in `*.test.ts`.
5. Add TSDoc to all exports; document rationale/edge-case handling at module top.
```
