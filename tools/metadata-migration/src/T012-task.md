# T012 Task Document

## Task ID: T012

## Title: Implement FileRewriter module

## Original Ticket Text:
- **T012 · Feature · P1: Implement FileRewriter module**
    - **Context:** Key Components - FileRewriter
    - **Action:**
        1. Create src/fileRewriter.ts
        2. Implement construction of new file content
        3. Implement atomic file writes and backup functionality
    - **Done‑when:**
        1. Module can write files atomically and create backups
    - **Depends‑on:** [T004, T005, T008, T011]

## Implementation Approach Analysis Prompt:
You are an AI assistant helping implement the FileRewriter module for a metadata migration tool. This module is responsible for:

1. Constructing new file content by combining YAML front-matter with the original document content
2. Writing files atomically to prevent data loss during failures
3. Creating backup files before overwriting original files

The module will work with these existing types and modules:
- StandardYamlMetadata (from types.ts)
- InspectedContent (from types.ts)
- YamlSerializer (from yamlSerializer.ts)
- Logger (from logger.ts)

Consider the following architectural principles from DEVELOPMENT_PHILOSOPHY.md:
- Pure functions where possible
- Immutable data structures
- Strong typing with no `any`
- Explicit over implicit
- Comprehensive error handling
- Structured logging

Design requirements:
1. The module should combine YAML front-matter with content
2. Use atomic writes (write to temp file, then rename) for safety
3. Create backup files before overwriting
4. Handle filesystem errors gracefully
5. Preserve original line endings (CRLF vs LF)
6. Support configurable backup directory

Please provide:
1. A clear module architecture
2. Function signatures with interfaces
3. Error handling strategy
4. Testing approach
5. Implementation considerations for filesystem operations
