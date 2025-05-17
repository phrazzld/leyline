# Todo: Metadata Migration Script

## Project Setup
- [x] **T001 · Chore · P1: Create migration script directory**
    - **Context:** Implementation Steps - 1. Project Setup
    - **Action:**
        1. Create a new directory named `metadata-migration` under the `tools/` directory
        2. Add an initial README.md placeholder
    - **Done‑when:**
        1. The directory exists with README.md
    - **Depends‑on:** none

- [x] **T002 · Chore · P1: Initialize Node.js project with TypeScript**
    - **Context:** Implementation Steps - 1. Project Setup
    - **Action:**
        1. Initialize a Node.js project (npm init -y)
        2. Install TypeScript and @types/node as development dependencies
    - **Done‑when:**
        1. package.json exists with TypeScript as a dev dependency
    - **Depends‑on:** [T001]

- [x] **T003 · Chore · P1: Configure necessary project dependencies**
    - **Context:** Implementation Steps - 1. Project Setup
    - **Action:**
        1. Install production dependencies: glob, js-yaml (or yaml)
        2. Install development dependencies: ts-node, test runner (jest or vitest), CLI argument parser (yargs or commander)
    - **Done‑when:**
        1. All dependencies are installed and listed in package.json
    - **Depends‑on:** [T002]

- [x] **T004 · Chore · P1: Setup tsconfig and npm scripts**
    - **Context:** Implementation Steps - 1. Project Setup
    - **Action:**
        1. Create tsconfig.json with strict settings
        2. Define npm scripts for build, start, test, lint, format
    - **Done‑when:**
        1. tsconfig.json exists and allows TypeScript compilation
        2. Basic npm scripts are functional
    - **Verification:**
        1. Run npm run build (compiles an empty index.ts)
        2. Run npm run test (runs an empty test suite)
    - **Depends‑on:** [T003]

## Core Data Structures
- [x] **T005 · Feature · P1: Define core data structure interfaces**
    - **Context:** Core Data Structures
    - **Action:**
        1. Create a types.ts file
        2. Define FileContext, InspectedContent, LegacyMetadata, StandardYamlMetadata interfaces
    - **Done‑when:**
        1. All interfaces are defined with TSDoc comments
    - **Depends‑on:** [T002]

## Core Modules
- [x] **T006 · Feature · P1: Implement Logger module**
    - **Context:** Key Components - Logger
    - **Action:**
        1. Create src/logger.ts
        2. Implement structured JSON logging with levels (DEBUG, INFO, WARN, ERROR)
    - **Done‑when:**
        1. Logger provides functions for each log level and outputs structured logs
    - **Depends‑on:** [T004, T005]

- [x] **T007 · Feature · P1: Implement FileWalker module**
    - **Context:** Key Components - FileWalker
    - **Action:**
        1. Create src/fileWalker.ts
        2. Implement function to recursively find Markdown files within specified directories
    - **Done‑when:**
        1. Module can identify and return markdown file paths
    - **Depends‑on:** [T004, T005]

- [x] **T008 · Feature · P1: Implement MetadataInspector module**
    - **Context:** Key Components - MetadataInspector
    - **Action:**
        1. Create src/metadataInspector.ts
        2. Implement detection of metadata format (yaml, legacy-hr, none, unknown)
        3. Extract content sections appropriately
    - **Done‑when:**
        1. Module correctly detects formats and separates metadata from content
    - **Depends‑on:** [T004, T005]

- [x] **T009 · Feature · P1: Implement LegacyParser module**
    - **Context:** Key Components - LegacyParser
    - **Action:**
        1. Create src/legacyParser.ts
        2. Analyze existing legacy formats to understand variations
        3. Implement parsing of raw metadata into LegacyMetadata object
    - **Done‑when:**
        1. Module correctly parses legacy metadata and handles malformed data
    - **Depends‑on:** [T004, T005, T006, T008]

- [x] **T010 · Feature · P1: Implement MetadataConverter module**
    - **Context:** Key Components - MetadataConverter
    - **Action:**
        1. Create src/metadataConverter.ts
        2. Implement transformation of LegacyMetadata to StandardYamlMetadata
        3. Validate required fields and normalize formats
    - **Done‑when:**
        1. Module correctly transforms metadata and handles special cases
    - **Depends‑on:** [T004, T005, T006, T009]

- [x] **T011 · Feature · P1: Implement YamlSerializer module**
    - **Context:** Key Components - YamlSerializer
    - **Action:**
        1. Create src/yamlSerializer.ts
        2. Implement conversion of StandardYamlMetadata to YAML string
    - **Done‑when:**
        1. Module produces valid YAML front-matter strings
    - **Depends‑on:** [T003, T004, T005]

- [ ] **T012 · Feature · P1: Implement FileRewriter module**
    - **Context:** Key Components - FileRewriter
    - **Action:**
        1. Create src/fileRewriter.ts
        2. Implement construction of new file content
        3. Implement atomic file writes and backup functionality
    - **Done‑when:**
        1. Module can write files atomically and create backups
    - **Depends‑on:** [T004, T005, T008, T011]

- [ ] **T013 · Feature · P1: Implement MigrationOrchestrator module**
    - **Context:** Key Components - MigrationOrchestrator
    - **Action:**
        1. Create src/migrationOrchestrator.ts
        2. Implement main workflow coordination
        3. Handle dry-run mode and error handling
    - **Done‑when:**
        1. Module correctly processes files through the full workflow
    - **Depends‑on:** [T006, T007, T008, T009, T010, T011, T012]

- [ ] **T014 · Feature · P1: Implement CliHandler module**
    - **Context:** Key Components - CliHandler
    - **Action:**
        1. Create src/cliHandler.ts
        2. Implement CLI argument parsing for target paths, --dry-run, --backup-dir
    - **Done‑when:**
        1. Module correctly parses arguments and provides help messages
    - **Depends‑on:** [T003, T004, T013]

## Testing
- [x] **T015 · Chore · P1: Create test fixtures**
    - **Context:** Testing Strategy
    - **Action:**
        1. Create test/fixtures/ directory
        2. Create various test files covering all scenarios:
            - Valid legacy formats
            - Files with YAML front-matter
            - Files with no metadata
            - Files with malformed metadata
            - Files with deprecated fields
            - Files with edge case formatting
    - **Done‑when:**
        1. Complete set of test fixtures exists
    - **Depends‑on:** [T001]

- [ ] **T016 · Test · P1: Implement unit tests for all modules**
    - **Context:** Testing Strategy - Unit Tests
    - **Action:**
        1. Create test files for each module
        2. Test normal operation and edge cases
    - **Done‑when:**
        1. All modules have comprehensive unit tests with >90% coverage
    - **Depends‑on:** [T006, T007, T008, T009, T010, T011, T012, T013, T014, T015]

- [ ] **T017 · Test · P1: Implement integration tests**
    - **Context:** Testing Strategy - Integration Tests
    - **Action:**
        1. Create tests for end-to-end workflow
        2. Test with various fixture combinations
    - **Done‑when:**
        1. Integration tests verify the complete workflow
    - **Depends‑on:** [T013, T015, T016]

## Documentation
- [ ] **T018 · Docs · P2: Write comprehensive README**
    - **Context:** Implementation Steps - CLI & Documentation
    - **Action:**
        1. Document purpose, installation, usage examples
        2. Document CLI options and flags
        3. Include warnings about backup importance
    - **Done‑when:**
        1. README provides complete usage guidance
    - **Depends‑on:** [T014]

- [ ] **T019 · Docs · P2: Add TSDoc comments**
    - **Context:** Documentation
    - **Action:**
        1. Add detailed TSDoc comments to all exported functions, classes, and interfaces
    - **Done‑when:**
        1. All public exports have comprehensive documentation
    - **Depends‑on:** [T006, T007, T008, T009, T010, T011, T012, T013, T014]

## Validation & Execution
- [ ] **T020 · Test · P1: Validate script on actual repository (dry-run)**
    - **Context:** Implementation Steps - Validation & Execution
    - **Action:**
        1. Run migration with --dry-run flag on actual repository files
        2. Analyze logs and verify expected behavior
    - **Done‑when:**
        1. Dry run completes successfully and logs expected changes
    - **Depends‑on:** [T013, T014, T017]

- [x] **T021 · Chore · P0: Create backup of docs directory**
    - **Context:** Implementation Steps - Validation & Execution
    - **Action:**
        1. Create a full backup of the docs directory before execution
    - **Done‑when:**
        1. Backup exists and integrity verified
    - **Depends‑on:** none

- [ ] **T022 · Feature · P1: Execute migration on repository**
    - **Context:** Implementation Steps - Validation & Execution
    - **Action:**
        1. Run the migration script on the actual repository
        2. Verify files are properly converted
    - **Done‑when:**
        1. All legacy metadata files are converted to YAML front-matter
    - **Verification:**
        1. Manually inspect a sample of converted files
        2. No errors or warnings in the logs that indicate data loss
    - **Depends‑on:** [T020, T021]

## Final Verification
- [ ] **T023 · Test · P1: Verify success criteria**
    - **Context:** Success Criteria
    - **Action:**
        1. Check that all files with legacy HR metadata were converted
        2. Verify no data loss or corruption occurred
        3. Confirm document content and formatting preserved
        4. Check all required fields were correctly mapped
        5. Verify script is idempotent (run again and confirm it skips already converted files)
    - **Done‑when:**
        1. All success criteria confirmed
    - **Depends‑on:** [T022]
