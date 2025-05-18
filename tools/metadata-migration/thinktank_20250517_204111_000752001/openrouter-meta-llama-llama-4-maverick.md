## Chosen Approach
Implement comprehensive integration tests for the metadata migration tool using a real file system and test fixtures.

## Rationale
- Ensures end-to-end workflow testing with real file system operations
- Uses actual test fixtures to verify behavior across various scenarios
- Tests multiple configuration combinations (dry-run, backup directory)
- Verifies CLI integration through programmatic testing
- Validates file outputs against expected results
- Covers both success cases and error scenarios
- Ensures idempotency by testing repeated executions

## Build Steps
1. Create a test suite using a suitable testing framework (e.g., Jest or Vitest for TypeScript)
2. Set up test fixtures in a temporary directory for each test case
3. Implement tests for various scenarios:
   - Successful migration of legacy metadata to YAML front-matter
   - Handling of files already in YAML format
   - Files with no metadata
   - Files with malformed or unknown metadata formats
   - Dry-run mode verification
   - Backup creation and handling
   - Progress reporting callback testing
   - Error handling and edge cases
4. Verify file system outputs match expected results
5. Test idempotency by running migrations multiple times on the same files
6. Clean up test fixtures after each test to maintain isolation
7. Integrate these tests into the CI pipeline with appropriate coverage thresholds.
