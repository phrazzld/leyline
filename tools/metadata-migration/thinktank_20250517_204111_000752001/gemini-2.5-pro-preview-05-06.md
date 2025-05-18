## Chosen Approach
Implement a hybrid integration testing strategy: comprehensive tests for `MigrationOrchestrator` focusing on core logic and file operations, complemented by focused tests for `CliHandler` (argument parsing) and the `main` CLI entry point (wiring and high-level E2E).

## Rationale
- **Modularity + Strict Separation:** This approach tests distinct parts of the application (CLI parsing, core orchestration, main wiring) with appropriate focus, aligning with the principle of modularity and separation of concerns.
- **Testability (Minimal Mocking):** It provides the best test coverage for all aspects: CLI arguments, options propagation, core migration logic, file system interactions (using a real temporary FS), progress reporting, error handling, and idempotency, with minimal and appropriate mocking (e.g., `process.argv`, `process.exit`, `onProgress` callbacks).
- **Simplicity:** While composed of multiple test suites, each suite is focused and simple to understand and maintain. The overall complexity is managed through clear separation.
- **Documentation Approach:** The combined tests serve as comprehensive documentation for both CLI usage and the internal workings of the migration pipeline.
- **Coding Standards:** Facilitates clean, well-organized, and maintainable test code by separating test concerns.

## Build Steps

1.  **Test Environment Setup:**
    *   Choose a test framework (e.g., Jest).
    *   Configure the framework for TypeScript.
    *   Implement utility functions for:
        *   Managing temporary directories (creation before tests, cleanup after).
        *   Copying fixture files from `test/fixtures/` into temporary directories.
        *   Reading file content and checking file/directory existence for assertions.

2.  **`MigrationOrchestrator` Integration Tests:**
    *   Create a test suite for `MigrationOrchestrator`.
    *   For each test scenario:
        *   Set up a temporary directory with necessary fixture files.
        *   Instantiate `MigrationOrchestrator` with:
            *   Real module implementations (e.g., `FileWalker`, `MetadataInspector`, `LegacyParser`, `MetadataConverter`, `YamlSerializer`).
            *   A real `FileRewriter` instance using a `NodeFileSystem` adapter pointed at the temporary directory.
            *   A real `Logger` instance (or a test-specific one if fine-grained log assertion is needed for orchestrator behavior).
            *   Test-specific `MigrationOrchestratorOptions` (e.g., `paths` pointing to the temp directory, `dryRun`, `backupDir`).
            *   A mock `onProgress` callback (`jest.fn()`).
        *   Execute `orchestrator.run()`.
        *   **Assert:**
            *   The content of modified files against expected output.
            *   The existence and content of backup files (if applicable).
            *   No changes in `dryRun` mode.
            *   The `MigrationSummary` returned by `run()` (counts of processed, succeeded, failed, modified files, errors).
            *   The mock `onProgress` callback was called with expected arguments and frequency.
    *   **Test Cases:**
        *   **Success Cases:** For each valid fixture type (e.g., `legacy-basic-tenet.md`, `legacy-basic-binding.md`):
            *   Verify correct conversion to YAML front-matter.
            *   Test with `dryRun: false` (files modified).
            *   Test with `dryRun: true` (files not modified, summary reflects simulation).
            *   Test with `backupDir` specified (backups created in custom location).
            *   Test without `backupDir` (backups created in default location relative to file, or as per `FileRewriter.computeBackupPath` logic if no backupDir means same dir).
        *   **No-Op Cases:**
            *   Files already in YAML format (e.g., `yaml-basic-tenet.md`): Verify no changes, correct summary counts.
            *   Files with no metadata (e.g., `no-metadata-plain.md`): Verify no changes, correct summary counts.
        *   **Error Handling & Edge Cases:**
            *   Malformed metadata (e.g., `malformed-incomplete-hr.md`, `malformed-missing-required.md`): Verify errors are reported in summary, files are not incorrectly modified.
            *   Files with unknown metadata format: Verify correct summary counts.
            *   Empty files, files with special characters, different line endings (e.g., `edge-*.md`).
            *   Non-existent input paths (test `FileWalker` integration).
        *   **Idempotency:** For scenarios involving file modifications, run the migration twice. Assert that the second run:
            *   Does not change files further.
            *   Reports correct summary (e.g., `modifiedCount: 0`, `alreadyYamlCount` reflects files converted in the first run).

3.  **`CliHandler` Unit/Integration Tests:**
    *   Create a test suite for `CliHandler`.
    *   Test `CliHandler.parse(argv)`:
        *   Provide various mocked `argv` arrays (simulating different command-line inputs).
        *   Assert the returned `CliArguments` object matches expected values for `paths`, `dryRun`, `backupDir`.
        *   Cover cases: no arguments (defaults), specific paths, `--dry-run`, `-d`, `--backup-dir <dir>`, `-b <dir>`, help flags.
    *   Test `CliHandler.toOrchestratorOptions(args)`:
        *   Provide various `CliArguments` objects.
        *   Assert the returned `MigrationOrchestratorOptions` are correctly mapped.

4.  **CLI `main` Entry Point Integration Tests:**
    *   Create a test suite for `cli.ts`'s `main` function. These tests are high-level checks for wiring.
    *   For a few representative scenarios (e.g., successful run, dry-run with output, error due to bad fixture):
        *   Set up a temporary directory with a simple fixture.
        *   Mock `process.argv` with appropriate arguments.
        *   Mock `process.exit` (`jest.spyOn(process, 'exit').mockImplementation(jest.fn() as any);`) to prevent test termination and assert exit codes.
        *   Spy on `Logger` methods (e.g., `jest.spyOn(Logger.prototype, 'info')` or `jest.spyOn(Logger.getInstance(), 'info')`) to capture key log outputs. (Note: `Logger.getInstance()` might need adjustment for testability if it's a rigid singleton, or spy on its prototype methods).
        *   Call the exported `main()` function from `cli.ts`.
        *   **Assert:**
            *   `process.exit` was called with the expected code (0 for success, 1 for error).
            *   Key log messages indicating start, completion, or specific errors.
            *   Basic file system changes (e.g., one file modified if not dry-run, or one backup created), relying on `MigrationOrchestrator` tests for detailed content verification.
    *   Restore mocks after each test.

5.  **Test Execution and CI Integration:**
    *   Configure `package.json` scripts to run all tests.
    *   Integrate test execution (including coverage checks as per `DEVELOPMENT_PHILOSOPHY.md`) into the CI pipeline. Ensure builds fail if tests fail or coverage drops.
    *   Ensure tests clean up temporary directories even on failure (e.g., using `afterEach` or `afterAll` hooks with `try...finally`).
