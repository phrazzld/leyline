# T017 Task Document

## Task ID: T017

## Title: Implement integration tests

## Original Ticket Text:
- **T017 · Test · P1: Implement integration tests**
    - **Context:** Testing Strategy - Integration Tests
    - **Action:**
        1. Create tests for end-to-end workflow
        2. Test with various fixture combinations
    - **Done‑when:**
        1. Integration tests verify the complete workflow
    - **Depends‑on:** [T013, T015, T016]

## Implementation Approach Analysis Prompt:
You are an AI assistant helping implement integration tests for a metadata migration tool. The project has:

1. A complete pipeline of modules that work together:
   - FileWalker: Finds markdown files
   - MetadataInspector: Detects metadata format
   - LegacyParser: Parses legacy metadata
   - MetadataConverter: Converts to standard format
   - YamlSerializer: Generates YAML front-matter
   - FileRewriter: Writes updated files
   - MigrationOrchestrator: Coordinates the workflow
   - CliHandler: Processes command-line arguments

2. Test fixtures in `test/fixtures/` directory including:
   - Valid legacy formats
   - Files with YAML front-matter
   - Files with no metadata
   - Files with malformed metadata
   - Edge cases

3. Testing principles:
   - NO internal mocking (don't mock internal modules)
   - Test real integrations
   - Use actual file system operations where possible
   - Test the complete end-to-end workflow
   - Cover success cases and error scenarios

Please design integration tests that:
1. Test the complete migration workflow from start to finish
2. Use real test fixtures to verify actual behavior
3. Test various combinations of options (dry-run, backup, etc.)
4. Ensure the CLI can be tested programmatically
5. Verify file outputs match expected results
6. Test error handling and edge cases
7. Ensure idempotency (running twice doesn't change results)

Consider:
- How to test file system operations in isolation
- How to verify backup creation
- How to test CLI integration
- How to test progress reporting callbacks
- How to structure tests for readability and maintainability
