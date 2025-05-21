# Metadata Migration Archive

This directory contains historical documentation about the metadata format migration that converted legacy horizontal rule format to standardized YAML front-matter in all tenet and binding files.

## Migration History

In May 2025, the Leyline repository underwent a migration from supporting two metadata formats (horizontal rule and YAML front-matter) to exclusively using YAML front-matter. This change was implemented to:

1. Standardize the metadata format across all files
2. Simplify the validation and indexing tools
3. Improve machine readability of metadata
4. Enhance compatibility with industry-standard documentation systems

## Migration Tools (Archived)

The migration process used:

- `tenet_metadata_migration.rb` - A Ruby script that converted tenet files from legacy horizontal rule format to YAML front-matter
- Backup directories were created to preserve the original files before migration

## Current Status

As of May 2025, all tenet and binding files use YAML front-matter exclusively, and all tools have been updated to only support YAML format.

Reference:
- See task T016 in `TODO.md` for details on the cleanup process
- See `tenet-metadata-migration-summary.md` for the migration results
