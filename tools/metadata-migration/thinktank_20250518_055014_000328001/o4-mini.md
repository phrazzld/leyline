## Chosen Approach
Automate TSDoc stub generation for all public exports via a custom ts-morph script, then manually enrich each stub following our TSDoc guidelines and enforce via eslint-plugin-tsdoc.

## Rationale
- Simplicity: A two-step process (stub generation + manual fill) minimizes manual error while avoiding over-engineering.
- Modularity: The ts-morph script is a standalone tool that cleanly separates doc scaffolding from code.
- Testability: Generated stubs guarantee every export is documented; eslint-plugin-tsdoc enforces coverage in CI.
- Coding Standards: All stubs follow a uniform template; eslint-plugin-tsdoc ensures adherence to TSDoc rules.
- Documentation Approach: Developers focus on “why” and examples rather than boilerplate, resulting in consistent, comprehensive docs.

## Build Steps
1. Add a dev script `generate-doc-stubs.ts` using ts-morph to scan `src/**/*.ts` for exported classes, interfaces, functions, and insert TSDoc blocks with `@todo` placeholders.
2. Install and configure `eslint-plugin-tsdoc` in `.eslintrc.js` to require TSDoc for all public exports and fail the build on missing or malformed comments.
3. Run `npm run gen-doc-stubs` to populate every export with a TSDoc stub.
4. Manually replace each `@todo` block by filling in module-level descriptions, rationale, @param, @returns, @throws, and examples per our documentation guidelines.
5. Add CI step to run `npm run gen-doc-stubs -- --check` (read-only) and `eslint --ext .ts .` to enforce doc coverage.
6. Review and refine; merge once all eslint-plugin-tsdoc checks pass.
