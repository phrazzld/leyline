```
## Chosen Approach
Implement integration tests for the metadata migration tool using real file system operations and test fixtures to verify end-to-end workflow with a focus on real integrations and comprehensive coverage.

## Rationale
- This approach prioritizes **simplicity** by using a straightforward testing strategy that leverages existing fixtures and real file system operations, avoiding complex mocking or setup.
- It ensures **modularity** and **strict separation** by testing the complete pipeline through public interfaces without internal mocking, aligning with the philosophy of testing real integrations.
- It maximizes **testability** by focusing on end-to-end workflow verification across various scenarios (success, error, edge cases) and fixture combinations, adhering to the no-mocking policy for internal collaborators.
- It complies with **coding standards** by structuring tests for readability and maintainability using TypeScript and Jest, consistent with the project's guidelines.
- It supports a robust **documentation approach** by embedding test cases as executable documentation within the test suite, ensuring clarity on expected behavior.

## Build Steps
1. **Set Up Test Environment**: Create a dedicated `test/integration/` directory to house integration tests, ensuring separation from unit tests, and configure Jest to run these tests with appropriate timeouts for file operations.
2. **Utilize Test Fixtures**: Leverage the existing `test/fixtures/` directory to test various file scenarios (legacy formats, YAML, no metadata, malformed, edge cases) by copying fixtures to a temporary test directory for each test run.
3. **Implement End-to-End Workflow Tests**: Write integration tests in `test/integration/workflow.test.ts` to verify the complete migration pipeline (FileWalker to FileRewriter) by running `MigrationOrchestrator` on temporary fixture copies, covering success paths and error scenarios.
4. **Test CLI Integration**: Develop tests in `test/integration/cli.test.ts` to programmatically invoke `CliHandler` with various argument combinations (paths, dry-run, backup options), validating parsed options and orchestrator behavior without mocking.
5. **Verify File System Operations**: Ensure tests perform real file system operations in isolated temporary directories (using `tmp` or similar library) to validate file reading, writing, and backup creation, checking output against expected results.
6. **Cover Options and Edge Cases**: Design test cases for different orchestrator options (dry-run, backup-dir) and edge cases (malformed metadata, Unicode, line endings), updating summary statistics and error logs accordingly.
7. **Test Idempotency**: Add tests to confirm that running the migration tool multiple times on the same files produces consistent results, ensuring no unintended modifications after the initial run.
8. **Add Progress Reporting Tests**: Implement tests to verify `onProgress` callbacks in `MigrationOrchestratorOptions`, capturing progress updates during processing to ensure accurate reporting for UI integration.
```
