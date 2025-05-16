# Plan: One-Time Migration - Legacy Horizontal Rule Metadata to YAML Front-Matter

## Task Overview
Create a one-time migration script to convert legacy horizontal rule metadata format to YAML front-matter in all tenet and binding Markdown files.

## Architecture & Approach

### Chosen Approach
A TypeScript/Node.js script will be developed to identify Markdown files (tenets and bindings) with legacy horizontal rule metadata, parse this metadata, convert it to standard YAML front-matter, and rewrite the files in-place, prioritizing data integrity, idempotency, and comprehensive logging.

### Key Components
1. **FileWalker**: Responsible for recursively finding all target Markdown files
2. **MetadataInspector**: Detects the type of metadata present and extracts raw metadata block and main content
3. **LegacyParser**: Parses the raw legacy horizontal rule metadata into a structured object
4. **MetadataConverter**: Transforms legacy metadata object into a standard YAML metadata object
5. **YamlSerializer**: Converts the metadata object into a correctly formatted YAML string
6. **FileRewriter**: Constructs new file content and writes it back to the file system
7. **MigrationOrchestrator**: Coordinates the workflow and handles control flow
8. **Logger**: Utility for structured logging of actions, warnings, errors, and summary
9. **CliHandler**: Manages command-line arguments like dry-run and backup options

### Core Data Structures
```typescript
// Types
interface FileContext {
  filePath: string;
  originalContent: string;
}

interface InspectedContent {
  filePath: string;
  format: 'yaml' | 'legacy-hr' | 'none' | 'unknown';
  rawMetadataBlock?: string; // Only if legacy-hr
  mainContent: string; // Content excluding any metadata block
  yamlFrontMatter?: object; // If format is 'yaml'
}

interface LegacyMetadata {
  id?: string;
  last_modified?: string; // Original string form
  derived_from?: string;
  enforced_by?: string;
  applies_to?: string[]; // Deprecated, to be logged and dropped
  [key: string]: any; // To capture any unexpected fields
}

interface StandardYamlMetadata {
  id: string; // Mandatory
  last_modified: string; // Mandatory, ISO 8601 format
  derived_from?: string;
  enforced_by?: string;
  // No applies_to - deprecated field
}
```

### Error & Edge-Case Strategy
- **Idempotency**: Skip files with existing YAML front-matter
- **No Metadata**: Skip files with no recognizable metadata
- **Malformed Legacy Metadata**: Log error and skip file - never guess
- **Missing Required Fields**: Validate and skip if critical fields missing
- **Deprecated Fields**: Log presence and drop during conversion
- **Unexpected Fields**: Log as warnings, proceed with conversion of known fields
- **File I/O Safety**: Implement atomic file writes to prevent corruption
- **Content Preservation**: Carefully recombine new YAML with original content
- **Backup Option**: Allow specifying a backup directory
- **Dry Run Mode**: Perform all steps except file writing

## Implementation Steps

### 1. Project Setup (0.5 day)
- Create script directory under tools
- Initialize Node.js project with TypeScript
- Configure necessary dependencies
- Setup appropriate tsconfig and scripts

### 2. Core Modules Development (2 days)
- Implement Logger for structured logging
- Implement FileWalker with globbing support
- Implement MetadataInspector with format detection
- Implement LegacyParser to handle various metadata formats
- Implement MetadataConverter with validation and normalization
- Implement YamlSerializer for proper YAML generation
- Implement FileRewriter with atomic file operations
- Implement MigrationOrchestrator to coordinate workflow

### 3. Testing (1.5 days)
- Create comprehensive test fixtures for all scenarios
- Implement unit tests for each component
- Implement integration tests for end-to-end workflow
- Focus on edge cases and error conditions
- Verify proper handling of line endings and encoding

### 4. CLI & Documentation (0.5 day)
- Implement command-line argument parsing
- Create comprehensive README with usage instructions
- Add detailed TSDoc comments to all functions
- Document known limitations and edge cases

### 5. Validation & Execution (0.5 day)
- Perform dry runs on actual repository content
- Manually validate a sample of conversions
- Create backup of docs directory
- Execute final migration
- Verify all files have been properly converted

## Testing Strategy

### Unit Tests
- **LegacyParser**: Test with various valid and malformed legacy formats
- **MetadataInspector**: Test detection of different metadata formats
- **MetadataConverter**: Test field mapping and validation logic
- **YamlSerializer**: Verify correct YAML formatting

### Integration Tests
- Create test fixtures for:
  - Valid legacy format variations
  - Files already in YAML format
  - Files with no metadata
  - Files with malformed metadata
  - Files with deprecated fields
  - Files with unusual characters or formatting
- Run full migration workflow against test fixtures
- Verify correct file modifications and logging

### Edge Case Testing
- Empty metadata blocks
- Metadata with only comments
- Inconsistent horizontal rule formats
- Different line ending styles
- UTF-8 BOM handling

## Risk Mitigation

| Risk | Severity | Mitigation |
|------|----------|------------|
| Data loss/corruption | CRITICAL | Mandatory backup, atomic writes, thorough testing, dry-run mode |
| Incorrect parsing of legacy formats | HIGH | Analysis of existing formats, robust parser, graceful failure |
| Non-idempotent execution | MEDIUM | Reliable detection of existing YAML, skip processing |
| Loss of document formatting | MEDIUM | Careful separation and recombination of content |
| Edge cases in legacy format | MEDIUM | Iterative testing, logging of ambiguous cases |
| File permission issues | LOW | Clear documentation, graceful error handling |

## Success Criteria
1. All files with legacy horizontal rule metadata are converted to YAML front-matter
2. No data loss or corruption during conversion
3. Document content and formatting preserved
4. Comprehensive logging of all operations
5. All required metadata fields correctly mapped
6. Deprecated fields properly handled
7. Script is idempotent and can be safely run multiple times

## Follow-up Work
Once this migration is successfully completed, the following backlog items can proceed:
- "Eliminate Dual Metadata Formats in Tenets and Bindings"
- "Use Directory Structure as Single Source of Truth for Binding Categorization"
