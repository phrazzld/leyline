# TypeScript Toolchain Integration Guide

This project demonstrates the complete integration of all 6 Leyline TypeScript bindings working together in harmony. It serves as both a validation of the toolchain and a reference implementation for new projects.

## Integrated Bindings

1. **modern-typescript-toolchain** - Foundation with unified tool selection
2. **vitest-testing-framework** - Testing with coverage thresholds and MSW
3. **tsup-build-system** - Dual ESM/CJS builds with TypeScript definitions
4. **package-json-standards** - pnpm-enforced dependency management
5. **tanstack-query-state** - Type-safe server state management
6. **eslint-prettier-setup** - Zero-suppression code quality automation

## Development Workflow

```bash
# Install dependencies (enforces pnpm usage)
pnpm install

# Development with hot reloading
pnpm dev

# Run tests with coverage
pnpm test:coverage

# Quality checks (lint + format)
pnpm quality:check

# Production build
pnpm build
```

## Integration Gotchas and Solutions

### 1. ESLint vs. Prettier Conflicts

**Problem**: ESLint and Prettier have overlapping styling rules, leading to conflicts.

**Solution**: We use `eslint-config-prettier` to disable ESLint's stylistic rules and `eslint-plugin-prettier` to run Prettier as an ESLint rule. This creates a single source of truth for formatting, visible directly in the linter's output.

### 2. Testing API Layers (Vitest + TanStack Query)

**Problem**: Testing code that fetches data requires mocking API responses reliably.

**Solution**: We use **Mock Service Worker (`msw`)** to intercept network requests during tests. This allows us to test the entire data fetching logic (`fetch`, query keys, data transformation) in an isolated, predictable environment without mocking `fetch` itself.

### 3. Dual CJS/ESM Package Compatibility

**Problem**: Supporting both `require` and `import` syntax for a library can be complex.

**Solution**: `tsup` is configured to build both formats (`esm`, `cjs`). The `package.json` `"exports"` field then correctly points to the right file based on the consumer's environment, which is the modern standard for dual-module packages.

### 4. Consistent TypeScript Module Resolution

**Problem**: Different tools (TypeScript compiler, `Vitest`, `tsup`) need to agree on how to resolve modules.

**Solution**: Setting `"moduleResolution": "bundler"` in `tsconfig.json` is the modern standard that works seamlessly across the entire toolchain, correctly handling both ESM and CJS dependency types.

### 5. Coverage Thresholds and Tool Integration

**Problem**: Vitest coverage needs to exclude certain files and work with the build pipeline.

**Solution**: The `vitest.config.ts` excludes test files, build artifacts, and configuration files from coverage calculations while maintaining strict thresholds (90%) for actual source code.

## Performance Benchmarks

- **Cold Install**: ~30 seconds (with pnpm caching)
- **Test Execution**: ~2 seconds for full suite with coverage
- **Build Time**: ~3 seconds for dual-format build with types
- **Lint + Format**: ~1 second for full codebase

## Architecture Patterns

### Type Safety

- Strict TypeScript configuration with no `any` allowed
- TanStack Query properly typed with interfaces
- Build-time type checking enforced in CI

### Testing Strategy

- Unit tests for core functions (90%+ coverage)
- Integration tests for API layer with MSW
- No internal mocking - real implementations tested

### Code Quality

- Zero-suppression ESLint policy
- Automatic formatting with Prettier
- Pre-commit hooks for quality gates
- CI enforcement of all quality standards

## Migration from Existing Projects

1. **Update package.json**: Add `packageManager` field and required engines
2. **Install dependencies**: Use pnpm exclusively for package management
3. **Configure toolchain**: Copy configuration files and adapt to your needs
4. **Update scripts**: Use the script patterns from this project
5. **Set up CI**: Implement the quality gates in your CI pipeline

## Troubleshooting

### Common Issues

**"Cannot find module" errors**

- Ensure `moduleResolution: "bundler"` in tsconfig.json
- Check that dependencies are installed with `pnpm install`

**ESLint conflicts with Prettier**

- Verify `eslint-config-prettier` is in your extends array
- Run `pnpm lint:fix` to auto-resolve conflicts

**Test failures in CI but not locally**

- Check Node.js version compatibility (>=18.0.0)
- Ensure pnpm lockfile is committed and up to date

**Build artifacts missing**

- Verify tsup configuration matches expected output formats
- Check that `dist/` directory is properly cleaned before builds

**Package.json exports warnings**

- Ensure "types" condition comes first in exports object
- Verify file paths in exports match actual build outputs (`.js` for ESM, `.cjs` for CJS)

## Integration Issues Found During Validation

During full toolchain integration testing, the following issues were identified and resolved:

### 1. ESLint Configuration Conflicts

**Issue**: ESLint was attempting to apply TypeScript-aware linting to configuration files (`eslint.config.js`, `tsup.config.ts`, `vitest.config.ts`) that weren't included in the main `tsconfig.json`.

**Resolution**: Split ESLint configuration into two rulesets:

- Type-aware linting for source files (`src/**/*.ts`, `tests/**/*.ts`)
- Basic linting for configuration files (no `project` parser option)

**Impact**: Prevents TypeScript parser errors during linting while maintaining strict quality standards for source code.

### 2. Package.json Exports Order

**Issue**: Build warnings about unused "types" condition due to incorrect ordering in package.json exports.

**Resolution**: Reorder exports conditions to place "types" first:

```json
"exports": {
  ".": {
    "types": "./dist/index.d.ts",
    "import": "./dist/index.js",
    "require": "./dist/index.cjs"
  }
}
```

**Impact**: Ensures proper TypeScript type resolution for consumers using both ESM and CJS imports.

### 3. File Path Mismatches

**Issue**: exports referenced `.mjs` extension that wasn't actually generated by tsup.

**Resolution**: Update exports to match actual build output (`.js` for ESM, `.cjs` for CJS).

**Impact**: Prevents module resolution errors when the package is consumed.

This integration guide serves as both documentation and troubleshooting reference for the complete Leyline TypeScript toolchain.
