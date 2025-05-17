## Chosen Approach
Hexagonal design: pure front-matter composer + FileRewriter core with injected IO adapters for atomic writes and backups.

## Rationale
- Simplicity: separates pure string composition from side-effecting file operations.
- Modularity: core logic depends only on interfaces; FS/backup are injected adapters.
- Testability: pure composer can be unit-tested; IO adapters can be faked for integration tests.
- Coding standards: strong typing, no `any`, immutable data, explicit DI.
- Structured logging & error handling: errors are wrapped with context; all operations logged at INFO/ERROR.

## Build Steps
1. Define interfaces:
   ```ts
   interface FrontMatterComposer {
     compose(metadata: StandardYamlMetadata, content: string, lineBreak: string): string;
   }
   interface FileWriter {
     writeAtomic(targetPath: string, data: string): Promise<void>;
   }
   interface BackupManager {
     backup(originalPath: string): Promise<string>;
   }
   ```
2. Implement `YamlComposer implements FrontMatterComposer` that uses `YamlSerializer` and preserves `lineBreak`.
3. Implement `LocalFileWriter implements FileWriter`:
   - write to `<target>.tmp`
   - `fs.rename(tmp→target)` once written
   - propagate errors
4. Implement `DirectoryBackupManager implements BackupManager`:
   - copy `originalPath → backupDir/<timestamp>_<basename>`
   - return backup path
5. Create `class FileRewriter` with constructor(opts: { writer: FileWriter; backup: BackupManager; composer: FrontMatterComposer; logger: Logger; }):
   ```ts
   async rewrite(path: string, newMeta: StandardYamlMetadata, inspected: InspectedContent): Promise<void>
   ```
   - `const body = composer.compose(newMeta, inspected.content, inspected.lineBreakType)`
   - `await backup.backup(path)`
   - `await writer.writeAtomic(path, body)`
   - log success or catch and log error with context
6. Error handling strategy:
   - wrap all FS errors in custom `FileRewriteError` with `path` and `operation` fields
   - propagate to CLI for aggregation in `MigrationResult`
7. Testing:
   - Unit-test `YamlComposer.compose`
   - Fake `FileWriter` & `BackupManager` to test `FileRewriter.rewrite` in isolation, asserting call order and error handling
   - Integration tests with temporary directories validating atomic rename, backup creation, and line-ending preservation.
