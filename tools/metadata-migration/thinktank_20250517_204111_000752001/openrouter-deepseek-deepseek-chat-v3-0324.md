```
## Chosen Approach
Implement integration tests using real file system operations with test fixtures, verifying end-to-end workflow through the CLI interface with various option combinations.

## Rationale
- **Simplicity**: Directly tests the complete workflow without complex mocking setups
- **Modularity**: Maintains strict separation by testing through public interfaces only
- **Testability**: Uses real file operations with fixtures as per testing principles
- **Coding Standards**: Follows project's TypeScript guidelines and testing strategy
- **Docs Approach**: Tests serve as executable documentation of expected behaviors

## Build Steps
1. Create test harness that:
   - Sets up temporary directories with fixture copies
   - Executes CLI with different argument combinations
   - Cleans up after tests

2. Implement test cases for:
   - Basic happy path with valid legacy files
   - Dry-run mode verification
   - Backup functionality validation
   - Error scenarios (malformed files)
   - Idempotency checks (re-running on same files)

3. Add verification methods:
   - File content comparison against expected outputs
   - Backup file existence checks
   - CLI exit code validation
   - Summary statistics verification

4. Structure tests by:
   - Creating describe blocks for each major scenario
   - Using beforeEach/afterEach for test isolation
   - Grouping assertions logically

5. Add progress callback tests:
   - Verify correct progress events are emitted
   - Test error reporting through callbacks
   - Validate final summary data

6. Implement file system assertions:
   - Check file modification timestamps
   - Verify backup file contents
   - Validate YAML front-matter formatting
```
