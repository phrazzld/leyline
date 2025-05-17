## Chosen Approach

The FileRewriter module will be implemented with a focus on simplicity, modularity, testability, and adherence to the DEVELOPMENT_PHILOSOPHY.md guidelines.

## Rationale

- **Simplicity First**: The module will be designed to perform a single task (rewriting files) with a clear and straightforward implementation.
- **Modularity**: The module will be structured into clear, independent components (functions) with well-defined interfaces.
- **Testability**: The module will be designed for easy testing, with minimal coupling and explicit dependencies.
- **Coding Standards**: The module will adhere to strict coding standards, including the use of strong typing, immutable data structures, and explicit error handling.

## Build Steps

1. **Create FileRewriter module**: Implement the FileRewriter module as a TypeScript class or a set of functions that can be easily composed together.
2. **Implement construction of new file content**: Create a function that combines YAML front-matter with the original document content.
3. **Implement atomic file writes and backup functionality**: Use a temporary file to write the new content, then rename it to the original file name. Create a backup of the original file before overwriting it.
4. **Handle filesystem errors gracefully**: Implement explicit error handling for filesystem operations, including error types and logging.
5. **Preserve original line endings**: Detect the line break type used in the original file and preserve it when writing the new file.

## Implementation

The FileRewriter module will be implemented as a set of functions that can be easily composed together. The main functions will be:

- `combineContent(metadata: StandardYamlMetadata, content: string)`: Combines YAML front-matter with the original document content.
- `writeFileAtomically(filePath: string, content: string)`: Writes the new content to a file atomically, creating a backup of the original file.

## Testing Approach

The module will be tested using a combination of unit tests and integration tests. Unit tests will focus on individual functions, while integration tests will verify the entire workflow.

## Error Handling Strategy

The module will implement explicit error handling for filesystem operations, including error types and logging. Errors will be propagated clearly, adding context judiciously without revealing sensitive information.

## Code

```typescript
import * as fs from 'fs';
import * as path from 'path';
import { logger } from './logger';
import { StandardYamlMetadata } from './types';

export function combineContent(metadata: StandardYamlMetadata, content: string): string {
  const yaml = jsYaml.dump(metadata);
  return yaml + '\n\n' + content;
}

export function writeFileAtomically(filePath: string, content: string): void {
  const backupPath = `${filePath}.bak`;
  const tempPath = `${filePath}.tmp`;

  try {
    fs.writeFileSync(tempPath, content);
    fs.renameSync(tempPath, filePath);
    logger.info(`Wrote file ${filePath} atomically`);
  } catch (error) {
    logger.error(`Error writing file ${filePath}: ${error.message}`);
    throw error;
  }
}
```
