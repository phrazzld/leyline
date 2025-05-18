```
## Chosen Approach
Full end-to-end integration tests using real file system operations and fixtures, executed in isolated temporary directories, testing the CLI programmatically with all core options/scenarios.

## Rationale
- Simplicity: Tests run the actual CLI (or orchestrator) using real files, minimal internal setup, no internal mocks, no overengineering—aligns with development philosophy's "Simplicity First."
- Modularity/Testability: Each test is self-contained, sets up its own temp workspace using real fixture copies, invokes the CLI handler programmatically (or via child_process when needed), and verifies both outputs and file system effects. No internal module mocking, strict separation and true integration coverage.
- Coverage: Supports all required scenarios—success, error, all option combinations, backup verification, dry-run, CLI argument parsing, progress callbacks, and idempotency—using real data and outputs.
- Coding Standards: Clear, maintainable test structure (describe/it or test/table-driven), explicit assertions, no magic or test pollution.
- Documentation: Tests act as executable documentation for the entire workflow and key edge cases.

## Build Steps
1. **Test Workspace Setup**: For each test (or test suite), create a fresh temporary directory, recursively copy the relevant fixture files from `test/fixtures/` into the temp workspace using real file system operations.
2. **Test CLI Programmatically**:
   - For core tests, import the CLI handler (or orchestrator) directly and run with simulated arguments, capturing results and file system changes.
   - For full CLI path testing, spawn the CLI as a child process with the desired arguments, capturing stdout/stderr and exit codes.
3. **Option Combinations**: For each major scenario, test with various CLI arguments:
   - Default run (modifies in place, backup default)
   - `--dry-run` (no file modifications)
   - `--backup-dir` (custom backup location)
   - Multiple paths
   - Error cases (malformed, unknown, missing files)
   - Idempotency (run twice: first modifies, second produces no changes)
4. **Assertions**:
   - Verify file modifications and backup files exist as expected (using `fs.readFile`, `fs.existsSync`, etc.).
   - For dry-run, assert no file changes or backups.
   - Compare migrated file contents to expected outputs (either via golden files or inline expectations).
   - Check that backup files are created and contain the original content.
   - Assert CLI/program output, exit code, and logs/messages (stdout/stderr).
   - For error/edge cases, assert error detection, error messages, and no unwanted file changes.
   - For progress callback (when orchestrator used directly), provide a mock function and assert the sequence of progress calls.
5. **Isolation/Cleanup**: After each test, clean up the temp workspace to prevent cross-test contamination.
6. **Test Structure**: Organize tests in `test/integration/` (not unit), grouped by scenario. Use clear, descriptive names and comments for each test, ensuring maintainability and easy extensibility.
7. **CI Integration**: Ensure tests run in CI without special permissions, relying only on local filesystem. Enforce test coverage and failure on regressions.
```
