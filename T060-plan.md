# T060 Plan: Fix broken links causing MkDocs build failure

## Issue Analysis

The CI failure audit indicates that the MkDocs build is failing in strict mode due to
invalid links in index.md. The specific issues are:

1. Links in README.md (which is likely being treated as index.md) using paths that don't
   match the documentation structure:

   - `./docs/migration-guide.md`
   - `./examples/github-workflows/language-specific-sync.yml`
   - `./docs/implementation-guide.md`

1. Additionally, all links in README.md that reference `./tenets/` and `./bindings/` are
   likely broken since these directories have been moved to `docs/tenets/` and
   `docs/bindings/`.

## Approach

1. First, determine if README.md is being used as the index.md in the MkDocs site. The
   mkdocs.yml has `docs_dir: docs` and references `index.md` in the navigation, but we
   need to confirm the relationship.

1. Fix the broken links in README.md:

   - Update references to `./docs/migration-guide.md` to use the correct path
   - Update references to `./examples/github-workflows/language-specific-sync.yml` to
     ensure it's accessible
   - Update references to `./docs/implementation-guide.md` to use the correct path
   - Fix all references to `./tenets/` and `./bindings/` to point to the correct
     locations

1. Verify the changes locally by running `mkdocs build --strict`

## Implementation Plan

1. For README.md (if used as index.md):

   - Change `./docs/migration-guide.md` → `migration-guide.md`
   - Fix link to language-specific workflow example to use correct relative path
   - Change `./docs/implementation-guide.md` → `implementation-guide.md`
   - Update all `./tenets/` references to `docs/tenets/` or the appropriate relative
     path
   - Update all `./bindings/` references to `docs/bindings/` or the appropriate relative
     path

1. Test the build using `mkdocs build --strict` to ensure no warnings or errors

This plan should resolve the CI failures related to broken links in the documentation.
