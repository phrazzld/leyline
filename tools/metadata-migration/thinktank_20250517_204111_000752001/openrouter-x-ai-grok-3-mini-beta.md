## Chosen Approach
Run end-to-end integration tests using Jest to invoke the CLI on test fixtures, verify file system changes, and check for idempotency without internal mocking.

## Rationale
- **Simplicity Wins:** This option uses straightforward CLI invocation and file assertions, aligning with the philosophy's emphasis on simplicity by avoiding complex test harnesses or wrappers, reducing accidental complexity while meeting requirements.
- **Modularity and Separation:** Maintains strict separation by treating the CLI as the entry point and using real file operations, adhering to module boundaries without internal mocks, as per the hierarchy's second priority.
- **Testability with Minimal Mocking:** Leverages actual integrations by mocking only external boundaries (e.g., via Jest's fs mocking for isolation), ensuring end-to-end verification while eliminating internal mocking, directly supporting the third philosophy tenet.
- **Coding Standards:** Complies with mandatory TypeScript standards like strict typing and no `any`, enforced through ESLint, with tests structured as clean, independent functions to avoid violations.
- **Documentation Approach:** Tests include TSDoc comments explaining rationale and setup, aligning with the philosophy's focus on documenting "why" over "how" for maintainable, self-documenting code.

## Build Steps
1. Install dependencies: Run `npm install --save-dev jest ts-jest @types/jest` to set up the testing environment.
2. Configure Jest: Create `jest.config.js` with settings for TypeScript support and file system mocking, ensuring fixtures are copied to a temporary directory per test.
3. Write test suites: Develop tests in `test/integration/cli.integration.test.ts` that invoke the CLI via `child_process`, assert fixture outputs, and verify options like dry-run and backups.
4. Implement assertions: Use Jest matchers to check file contents against expected YAML fixtures, test error scenarios, and confirm idempotency by running migrations twice.
5. Add progress and error handling: Integrate callbacks for progress reporting and capture errors in test summaries, running tests via CI with coverage checks.
6. Document tests: Add TSDoc comments in test files explaining the workflow and edge cases, and update project README with test execution instructions.
