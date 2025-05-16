# Backups Directory

This directory contains backups of the docs directory created before running the metadata migration script.

## Current Backups

- `docs-backup-20250516-094826.tar.gz` - Full backup of docs directory (58 files)
  - Created: 2025-05-16 09:48:26
  - Size: 189K
  - Purpose: Pre-migration backup for T021

## Restore Instructions

To restore from a backup:

```bash
# Extract backup to restore docs directory
tar -xzf docs-backup-YYYYMMDD-HHMMSS.tar.gz -C /path/to/leyline/
```

## Verification

To verify backup contents:

```bash
# List contents
tar -tzf docs-backup-YYYYMMDD-HHMMSS.tar.gz

# Count files
tar -tzf docs-backup-YYYYMMDD-HHMMSS.tar.gz | wc -l
```
