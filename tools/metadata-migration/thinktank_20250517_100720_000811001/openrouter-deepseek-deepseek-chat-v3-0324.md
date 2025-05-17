```
## Chosen Approach
Pure functional implementation with atomic write safety and backup support, leveraging existing types and modules while adhering to strict immutability and error handling principles.

## Rationale
- **Simplicity**: Single-purpose functions with clear inputs/outputs minimize complexity
- **Modularity**: Clean separation between content construction, file operations, and error handling
- **Testability**: Pure functions for content generation enable easy unit testing without filesystem mocks
- **Coding Standards**: Strong typing, immutable data structures, and no `any` usage
- **Docs Approach**: Self-documenting function signatures with clear interfaces

## Build Steps
1. Create `src/fileRewriter.ts` with core interfaces:
```typescript
import { InspectedContent, StandardYamlMetadata } from "./types";
import { Logger } from "./logger";
import { YamlSerializer } from "./yamlSerializer";

export interface FileWriteResult {
  success: boolean;
  backupPath?: string;
  error?: string;
}

export interface FileRewriter {
  rewriteFile(
    inspected: InspectedContent,
    metadata: StandardYamlMetadata,
    originalPath: string,
    backupDir?: string
  ): Promise<FileWriteResult>;
}
```

2. Implement atomic file writer with backup:
```typescript
import fs from "fs/promises";
import path from "path";
import { logger } from "./logger";

export class AtomicFileRewriter implements FileRewriter {
  constructor(private yamlSerializer: YamlSerializer) {}

  async rewriteFile(
    inspected: InspectedContent,
    metadata: StandardYamlMetadata,
    originalPath: string,
    backupDir?: string
  ): Promise<FileWriteResult> {
    try {
      // 1. Construct new content
      const newContent = this.constructNewContent(inspected, metadata);

      // 2. Create backup if requested
      let backupPath: string | undefined;
      if (backupDir) {
        backupPath = await this.createBackup(originalPath, backupDir);
      }

      // 3. Atomic write via temp file
      await this.atomicWrite(originalPath, newContent);

      return { success: true, backupPath };
    } catch (error) {
      logger.error("File rewrite failed", { error, path: originalPath });
      return {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error"
      };
    }
  }

  private constructNewContent(
    inspected: InspectedContent,
    metadata: StandardYamlMetadata
  ): string {
    const yamlContent = this.yamlSerializer.serializeToYaml(metadata);
    return `---${inspected.lineBreakType}${yamlContent}---${inspected.lineBreakType}${inspected.content}`;
  }

  private async createBackup(
    originalPath: string,
    backupDir: string
  ): Promise<string> {
    const backupPath = path.join(
      backupDir,
      `${path.basename(originalPath)}.bak`
    );
    await fs.copyFile(originalPath, backupPath);
    return backupPath;
  }

  private async atomicWrite(path: string, content: string): Promise<void> {
    const tempPath = `${path}.tmp`;
    await fs.writeFile(tempPath, content);
    await fs.rename(tempPath, path);
  }
}
```

3. Add comprehensive error handling:
```typescript
private async atomicWrite(path: string, content: string): Promise<void> {
  const tempPath = `${path}.tmp`;
  try {
    await fs.writeFile(tempPath, content);
    await fs.rename(tempPath, path);
  } catch (error) {
    // Clean up temp file if rename failed
    try {
      await fs.unlink(tempPath);
    } catch (cleanupError) {
      logger.warn("Failed to clean up temp file", {
        tempPath,
        error: cleanupError
      });
    }
    throw error;
  }
}
```
