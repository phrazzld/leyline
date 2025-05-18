```
## Chosen Approach
Single pass documentation with TSDoc standards, prioritizing module-level explanations, explicit API contracts, and "why" documentation.

## Rationale
- **Simplicity:** Single pass ensures consistent documentation approach across all modules without complex staging
- **Modularity:** Each module's documentation stands alone while fitting into system architecture
- **Testability:** Well-documented APIs make testing intentions clearer
- **Coding Standards:** Strict adherence to TSDoc standards matches project requirements
- **Docs Approach:** Focuses on "why" and API contracts per development philosophy

## Build Steps
1. **Setup Documentation Template**
   - Create TSDoc template with required sections (@param, @returns, @throws)
   - Define module-level documentation structure

2. **Document Core Types First (types.ts)**
   - Document all interfaces and enums
   - Explain type relationships and system roles

3. **Document Utility Modules**
   - logger.ts (structured logging approach)
   - fileWalker.ts (file discovery strategy)
   - metadataInspector.ts (format detection logic)

4. **Document Processing Pipeline**
   - legacyParser.ts (conversion requirements)
   - metadataConverter.ts (transformation rules)
   - yamlSerializer.ts (output standards)

5. **Document System Components**
   - fileRewriter.ts (atomic write guarantees)
   - backupManager.ts (safety mechanisms)
   - migrationEngine.ts (core workflow)

6. **Document Integration Points**
   - cliHandler.ts (argument contracts)
   - migrationOrchestrator.ts (coordination logic)
   - nodeFileSystemAdapter.ts (abstraction purpose)

7. **Review and Validate**
   - Verify all public exports documented
   - Check for consistent style and depth
   - Confirm examples cover key use cases
```
