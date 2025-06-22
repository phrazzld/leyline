# TASK: Implement Transparency Commands (Priority 3)

**Status**: 🟡 IN PROGRESS
**Priority**: HIGH
**From**: backlog.md Priority 3: Transparency (See What Changed)

## Overview

Implement transparency commands that allow users to see what changes will happen before they sync, providing better visibility and control over the sync process.

## Core Requirements

### 1. Diff Before Sync Command
```bash
leyline diff --categories typescript
# Shows what would change without syncing
```

**Functionality**:
- Compare local files against remote leyline content
- Show additions, deletions, and modifications
- Support category filtering with `--categories`
- Display in standard diff format
- Dry-run mode (no actual syncing)

### 2. Update Command
```bash
leyline update
# Shows which standards have updates available
# Preserves local modifications, shows conflicts
```

**Functionality**:
- Detect which local files have been modified
- Identify which remote files have updates
- Show conflicts between local changes and remote updates
- Preserve local modifications by default
- Provide clear guidance on resolving conflicts

### 3. Status Command
```bash
leyline status
# Shows:
# - Current leyline version synced
# - Which standards are modified locally
# - Which standards have updates available
```

**Functionality**:
- Display current synced leyline version
- List locally modified files (compared to synced version)
- List files with available updates
- Summary statistics (modified count, update count, etc.)
- Clear, actionable output format

## Technical Approach

### Core Components Needed

1. **FileComparator**: Compare local vs remote file content
2. **DiffFormatter**: Format differences in readable format
3. **ConflictDetector**: Identify merge conflicts between local/remote changes
4. **StatusReporter**: Generate status summaries and reports

### Implementation Strategy

1. **Leverage Existing Cache System**: Use current cache infrastructure for performance
2. **Reuse FileSyncer Logic**: Build on existing file comparison and hashing
3. **Git-style Output**: Follow familiar diff and status output conventions
4. **Category Support**: Integrate with existing category filtering system

### Key Design Decisions

- **Non-destructive by default**: Never modify files without explicit user consent
- **Performance-first**: Leverage cache for fast comparisons
- **Clear conflict resolution**: Provide actionable guidance for conflicts
- **Consistent UX**: Match existing leyline command patterns and output style

## Success Criteria

1. ✅ `leyline diff` shows pending changes without syncing
2. ✅ `leyline update` identifies available updates and conflicts
3. ✅ `leyline status` provides clear overview of sync state
4. ✅ All commands support `--categories` filtering
5. ✅ Performance: Commands complete in <2 seconds
6. ✅ User-friendly output with clear next steps
7. ✅ Integration with existing cache and category systems

## Files Likely to be Modified

- `lib/leyline/cli.rb` - Add new command definitions
- `lib/leyline/commands/` - New command classes for diff/update/status
- `lib/leyline/file_syncer.rb` - Extend for comparison operations
- `lib/leyline/` - New utility classes (FileComparator, DiffFormatter, etc.)
- `spec/` - Comprehensive test coverage for new commands

## Dependencies

- Existing cache system (completed)
- FileSyncer infrastructure (completed)
- Category system (completed)
- CLI framework (completed)

## Timeline Estimate

**2-3 days** for full implementation including tests and documentation.

---

*This task addresses Priority 3 from backlog.md and provides essential transparency features that users need to confidently manage their leyline syncs.*
