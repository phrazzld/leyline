```
## Chosen Approach
Implement integration tests using a testing framework, temporary directories for file system interaction, and direct calls to the orchestrator and CLI entry points with real dependencies.

## Rationale
- **Simplicity:** Using standard testing framework features, temporary directories, and direct function calls (instead of process spawning) keeps the test setup relatively simple and focused on the logic rather than complex environment management.
- **Modularity + strict separation:** The tests naturally follow the module structure by testing the `MigrationOrchestrator` which coordinates the other modules. The test setup clearly separates test data (fixtures in temp dir) from the code under test. Adhering to the "NO internal mocking" principle forces tests to interact with the real components, ensuring actual integration paths are verified. The `IFileSystem` interface is used by `FileRewriter`, but the test will provide the *real* `NodeFileSystem` implementation, testing the actual file operations against a controlled temporary environment.
- **Testability (minimal mocking):** This approach minimizes mocking strictly to external interfaces like the Logger or optional progress callbacks, and potentially process I/O for CLI tests, fully adhering to the philosophy's mandate against internal mocking. The core application logic and module interactions are tested with real instances.
- **Coding Standards:** Uses standard TypeScript testing patterns (Jest/Vitest, `describe`/`it`, assertions) and leverages the existing dependency injection pattern in `MigrationOrchestrator`.
- **Documentation Approach:** The tests serve as executable documentation for how the various modules integrate and how the tool behaves with different inputs and fixtures.

## Build Steps
1.  Set up the chosen testing framework (Jest or Vitest) if not already configured, ensuring TypeScript support.
2.  Install a library for managing temporary directories and file operations within tests (e.g., `tempy` for path generation, `fs-extra` for copying/cleanup).
3.  Create a dedicated test suite file for Orchestrator integration tests (e.g., `test/integration/orchestrator.test.ts`).
4.  Implement test setup/teardown logic within the Orchestrator test suite to:
    *   Create a unique temporary directory before each test or test suite.
    *   Copy relevant fixture files from `test/fixtures/` into the temporary directory for each specific test case.
    *   Clean up and remove the temporary directory after each test or test suite.
5.  Within the Orchestrator test suite, write tests to cover various scenarios:
    *   Basic success cases for legacy files, verifying the output file content matches expected YAML format and the original body content is preserved.
    *   Cases for files that are already in YAML format or have no metadata, verifying no changes are made and the summary reflects these counts.
    *   Cases for malformed or unknown metadata formats, verifying appropriate errors are reported in the summary and files are not modified (or handled gracefully).
    *   Tests for the `--dry-run` option, asserting that the orchestrator runs without writing any files and the summary reflects the simulated changes.
    *   Tests for the `--backup-dir` option, asserting that backup files are created in the specified directory and contain the original file content.
    *   Tests for error scenarios (e.g., file read failures, invalid paths), asserting that errors are caught and reported in the summary.
    *   Tests for idempotency by running the migration twice on the same initial set of files in the temporary directory and asserting the result is unchanged after the first successful run.
    *   (Optional) Use mock functions for the Logger and the `onProgress` callback provided to the Orchestrator options to assert logging behavior and progress reporting.
6.  Create a separate test suite file for CLI integration tests (e.g., `test/integration/cli.test.ts`).
7.  Implement test setup/teardown logic for the CLI test suite, similar to the Orchestrator tests (temporary directory, fixture copying).
8.  Within the CLI test suite, write tests that programmatically invoke the CLI entry point (`src/cli.ts`'s `main` function):
    *   Mock `process.argv` to simulate different command-line arguments (`paths`, `--dry-run`, `--backup-dir`).
    *   Mock `process.exit` and capture its call with the expected exit code (0 for success, non-zero for failure).
    *   Mock `console.log`, `process.stdout`, and `process.stderr` to capture the output (logs, summary) and assert against expected messages.
    *   After invoking the CLI's `main` function, read files from the temporary directory and assert their state (modified content, backup files) matches the expected output based on the simulated command-line options.
9.  Ensure the CI pipeline is configured to run these integration tests, potentially using a different command or tag if they are slower than unit tests.
```
