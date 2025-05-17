### Chosen Approach
Implement `FileRewriter` as a pure, immutable module with atomic file writes and backup functionality, leveraging existing types and adhering to strict architectural principles.

### Rationale
- **Simplicity**: Directly addresses the core requirements with straightforward functions.
- **Modularity**: Isolates file writing concerns, aligning with Separation of Concerns.
- **Testability**: Pure functions and explicit dependencies make testing straightforward without internal mocking.
- **Coding Standards**: Strong typing and no `any` usage maintain code quality.
- **Docs Approach**: Clear function signatures and interfaces support self-documenting code.

### Build Steps
1. **Design Interfaces**: Define `FileRewriter` interface and `FileWriteOptions` type.
2. **Implement Atomic Write Logic**: Create `writeFileAtomically` function with temp file and rename.
3. **Add Backup Functionality**: Implement `createBackup` function using copy operations.
4. **Combine Content**: Create `constructNewFileContent` to merge YAML and document content.
5. **Integrate with Dependencies**: Use `YamlSerializer` and `Logger` appropriately.
6. **Error Handling**: Implement comprehensive error handling with structured logging.
7. **Testing**: Write unit tests focusing on file system interactions and edge cases.

### Detailed Implementation

#### 1. Define Interfaces and Types

```typescript
interface FileRewriter {
  rewriteFile(filePath: string, inspectedContent: InspectedContent, newMetadata: StandardYamlMetadata): Promise<void>;
}

interface FileWriteOptions {
  createBackup?: boolean;
  backupDir?: string;
  dryRun?: boolean;
}
```

#### 2. Implement Atomic Write Logic

```typescript
async function writeFileAtomically(filePath: string, content: string, logger: Logger): Promise<void> {
  const tempFilePath = `${filePath}.tmp`;
  try {
    await fs.promises.writeFile(tempFilePath, content, 'utf8');
    await fs.promises.rename(tempFilePath, filePath);
  } catch (error) {
    logger.error(`Atomic write failed for ${filePath}`, { error });
    try {
      await fs.promises.unlink(tempFilePath);
    } catch (cleanupError) {
      logger.warn(`Failed to clean up temporary file ${tempFilePath}`, { error: cleanupError });
    }
    throw error;
  }
}
```

#### 3. Add Backup Functionality

```typescript
async function createBackup(originalPath: string, backupDir: string, logger: Logger): Promise<string> {
  const backupPath = path.join(backupDir, `${path.basename(originalPath)}.${Date.now()}.bak`);
  try {
    await fs.promises.copyFile(originalPath, backupPath);
    return backupPath;
  } catch (error) {
    logger.error(`Backup creation failed for ${originalPath}`, { error });
    throw error;
  }
}
```

#### 4. Combine Content

```typescript
function constructNewFileContent(newMetadata: StandardYamlMetadata, content: string, lineBreakType: string): string {
  const yamlFrontMatter = `---\n${serializeToYaml(newMetadata)}---${lineBreakType}`;
  return `${yamlFrontMatter}${content}`;
}
```

#### 5. Integrate Dependencies

```typescript
class FileRewriterImpl implements FileRewriter {
  constructor(
    private readonly yamlSerializer: YamlSerializer,
    private readonly logger: Logger,
    private readonly options: FileWriteOptions = {}
  ) {}

  async rewriteFile(filePath: string, inspectedContent: InspectedContent, newMetadata: StandardYamlMetadata): Promise<void> {
    const { createBackup = false, backupDir = '', dryRun = false } = this.options;

    // Construct new file content
    const newContent = constructNewFileContent(newMetadata, inspectedContent.content, inspectedContent.lineBreakType);

    if (dryRun) {
      this.logger.info(`Dry run: Would rewrite ${filePath}`);
      return;
    }

    try {
      if (createBackup) {
        await createBackup(filePath, backupDir, this.logger);
      }
      await writeFileAtomically(filePath, newContent, this.logger);
    } catch (error) {
      this.logger.error(`Failed to rewrite file: ${filePath}`, { error });
      throw error;
    }
  }
}
```

#### 6. Error Handling
All functions use `try/catch` with structured logging. Errors are properly propagated for higher-level handling.

#### 7. Testing Approach
- Mock file system operations using `jest.mock('fs')` and `jest.mock('fs/promises')`.
- Test atomic write behavior by simulating failures during rename.
- Verify backup creation logic with different scenarios.
- Ensure line endings are preserved in `constructNewFileContent`.

### Summary
This implementation provides a robust, modular, and testable solution for rewriting files with YAML front-matter while ensuring atomic operations and optional backups. It strictly adheres to the given architectural principles and leverages existing types and modules effectively.
