```
## Chosen Approach
End-to-end CLI-driven tests using temp directories and real fixtures, verifying file system outcomes and idempotency.

## Rationale
- **Simplicity**: Tests mirror real usage through CLI calls without complex mocking
- **Modularity**: Isolated test cases per fixture type with clean temp environments
- **Testability**: Verifies actual file transformations and CLI exit codes
- **Docs Alignment**: Matches "no internal mocking" principle by testing full workflow

## Build Steps
1. Create `test/integration` directory with Jest test structure
2. Implement temp directory lifecycle management:
```typescript
import { mkdtemp, rm } from 'fs/promises'
import { join } from 'path'
import { spawnSync } from 'child_process'

describe('CLI Integration', () => {
  let testDir: string

  beforeEach(async () => {
    testDir = await mkdtemp(join(__dirname, 'migration-'))
    // Copy fixture files into testDir
  })

  afterEach(() => rm(testDir, { recursive: true }))
})
```
3. Add test matrix for core scenarios:
```typescript
const testMatrix = [
  {
    name: 'legacy-file',
    fixture: 'legacy-basic-binding.md',
    expects: ['yaml-frontmatter', 'backup-file']
  },
  {
    name: 'dry-run',
    args: ['--dry-run'],
    expects: ['no-file-changes']
  },
  {
    name: 'idempotency-check',
    runs: 2,
    expects: ['same-output-after-rerun']
  }
]
```
4. Implement file system assertions:
```typescript
function verifyMigration(output: string, testDir: string) {
  // Check backup creation
  // Validate YAML structure
  // Confirm content preservation
  // Verify error reporting for malformed files
}
```
5. Add CLI execution helper:
```typescript
function runCLI(args: string[], cwd: string) {
  return spawnSync('ts-node', ['src/cli.ts', ...args], {
    cwd,
    encoding: 'utf-8'
  })
}
```
