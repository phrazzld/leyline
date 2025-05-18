## Chosen Approach
Use Jest-driven end-to-end tests that copy real fixtures into isolated temp directories, invoke the CLI via child_process (and the orchestrator directly), and verify file outputs, backups, progress callbacks, error handling, and idempotency against expected results.

## Rationale
- Tests exercise the full pipeline with real FS I/O and CLI, satisfying “no internal mocking” and covering true integrations.
- Using temporary directories and fixture copies isolates side effects, ensuring repeatable, independent tests.
- Parametrized Jest suites simplify coverage of success, error, and edge‐case fixtures, keeping tests modular and maintainable.
- Programmatic CLI invocation (execa) plus direct orchestrator calls enable coverage of both user‐facing CLI and internal progress callbacks.
- Asserting file diffs, backup existence, and rerun idempotency demonstrates correctness, error handling, and stability.

## Build Steps
1. Add Jest (and ts-jest or babel-jest) plus `execa` and `fs-extra` to devDependencies, configure `jest.config.js` for integration tests (`test/integration/**/*.test.ts`).
2. Create a test helper that, before each test, uses `fs-extra.copy()` to clone `test/fixtures/` into a fresh `os.tmpdir()/migration-test-<uuid>/`.
3. For each fixture group (legacy, yaml-already, none, malformed, edge), write parameterized Jest tests that:
   - Run `execa('node', ['bin/cli.js', ...args], { cwd: sandboxPath })` with various options (`--dry-run`, `--backup-dir`).
   - Assert exit codes are correct (0 on success, 1 on errors).
   - If not dry-run, read files in sandbox and compare to pre‐computed expected outputs (in `test/expected/...`).
   - Check for backup files in the correct directory and valid timestamped names.
4. Test idempotency by running the CLI twice in the same sandbox and asserting that the second run makes no changes (using file content snapshots or checksums).
5. Inject a fake `onProgress` callback into a direct `MigrationOrchestrator` run to capture progress reports; assert correct ordering and status values.
6. Clean up sandboxes in `afterEach` to remove temp directories.
7. Add CI step to run `jest --coverage --config=jest.config.js` and enforce coverage thresholds, failing the build on regressions.
