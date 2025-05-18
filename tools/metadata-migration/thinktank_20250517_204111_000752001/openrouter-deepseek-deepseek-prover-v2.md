```markdown
## Chosen Approach
Implement integration tests using Jest to verify the complete end-to-end migration workflow with real fixtures, ensuring all modules collaborate correctly and handle various edge cases.

## Rationale
- **Simplicity**: Using Jest with real file operations simplifies testing by avoiding complex mocks and focusing on actual behavior.
- **Modularity**: Tests are structured to mirror the migration workflow, ensuring each module's role is clearly verified.
- **Testability**: Real file operations and fixtures provide concrete validation of the tool's functionality.
- **Coding Standards**: Adheres to Jest and TypeScript best practices, ensuring maintainable and readable tests.
- **Docs Approach**: Clear test descriptions and comments explain the purpose and expected behavior of each test case.

## Build Steps
1. **Set up Jest with TypeScript**: Configure Jest to work with TypeScript using `ts-jest`.
2. **Create test files**: Place integration tests in `test/integration` directory with names like `migrationWorkflow.test.ts`.
3. **Prepare fixtures**: Use real markdown files from `test/fixtures` to simulate different scenarios.
4. **Write test cases**: For each fixture, write a test that runs the migration and verifies the output.
5. **Test CLI options**: Validate dry-run, backup, and other CLI flags using programmatic execution of the CLI.
6. **Check idempotency**: Ensure running the migration twice does not alter the file further.
7. **Verify error handling**: Test with malformed files to ensure errors are handled gracefully.
8. **Run tests**: Execute tests using `jest` command and ensure all pass before merging.
```
