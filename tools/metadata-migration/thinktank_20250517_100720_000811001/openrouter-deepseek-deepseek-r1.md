```
## Chosen Approach
Structured atomic writer with backup preservation and pure content construction.

## Rationale
- **Simplicity**: Direct file operations with clear error propagation align with core principles
- **Modularity**: Separates content construction (pure) from I/O (impure) per hexagonal architecture
- **Testability**: Filesystem operations mockable via interface, content generation is pure
- **Standards**: Immutable data flow through transformation pipeline prevents side effects
- **Safety**: Atomic writes + backup creation satisfies data integrity requirements

## Build Steps
1. **Create `FileWriter` interface**:
```typescript
interface FileWriter {
  write(
    path: string,
    content: string,
    originalLineEnding: string
  ): Promise<WriteResult>;
}
```

2. **Implement atomic writer**:
```typescript
class AtomicFileWriter implements FileWriter {
  constructor(
    private readonly logger: Logger,
    private readonly backupDir?: string
  ) {}

  async write(path: string, content: string, lineEnding: string) {
    const tempPath = `${path}.tmp`;

    try {
      await fs.writeFile(tempPath, content.replace(/\n/g, lineEnding));
      if(this.backupDir) await this.createBackup(path);
      await fs.rename(tempPath, path);
    } catch (error) {
      await this.cleanupTempFile(tempPath);
      throw new FileWriteError(path, error);
    }
  }
}
```

3. **Build content composer**:
```typescript
function composeNewContent(
  metadata: StandardYamlMetadata,
  bodyContent: string,
  serializer: YamlSerializer
): string {
  const yamlFrontmatter = serializer.serialize(metadata);
  return `---\n${yamlFrontmatter}---\n\n${bodyContent}`;
}
```

4. **Create coordinator class**:
```typescript
class FileRewriter {
  constructor(
    private readonly writer: FileWriter,
    private readonly serializer: YamlSerializer
  ) {}

  async rewriteFile(
    file: FileContext,
    metadata: StandardYamlMetadata,
    inspected: InspectedContent
  ): Promise<WriteResult> {
    const newContent = composeNewContent(
      metadata,
      inspected.content,
      this.serializer
    );

    return this.writer.write(
      file.path,
      newContent,
      inspected.lineBreakType
    );
  }
}
```

5. **Error hierarchy**:
```typescript
class FileRewriteError extends Error {
  readonly name = 'FileRewriteError';
  constructor(
    public readonly path: string,
    public readonly cause: Error
  ) {
    super(`Failed to rewrite ${path}: ${cause.message}`);
  }
}
```
