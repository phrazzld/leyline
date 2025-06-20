# TypeScript Configuration File Locations

**Date:** 2025-06-18
**Status:** Decided
**Context:** Issue #87 - TypeScript bindings implementation

## Decision

**Use workspace root for shared tooling configuration with package-specific overrides only when domain requirements justify the complexity.**

## Rationale

Based on leyline's centralized configuration, simplicity, and module organization principles:

### **Centralized Configuration Benefits**
- **Single source of truth**: All shared tooling configuration in one authoritative location
- **Reduced duplication**: Shared TypeScript, ESLint, Prettier configurations avoid repetition
- **Easier maintenance**: Updates to shared tooling affect all packages consistently
- **Onboarding simplicity**: New developers find configuration in predictable workspace root location

### **Package-Specific Override Benefits**
- **Domain separation**: Business logic configuration stays close to the domain it serves
- **Independent evolution**: Packages can evolve tooling needs independently when justified
- **Environment isolation**: Different deployment environments per package when required

## Implementation Guidelines

### **Workspace Root (Default) - `./`**
Location for shared tooling and development configuration:

```
workspace-root/
├── tsconfig.json              # Base TypeScript configuration
├── tsconfig.build.json        # Production build configuration
├── eslint.config.js           # Shared linting rules
├── prettier.config.js         # Code formatting standards
├── vitest.config.ts           # Base test configuration
├── package.json               # packageManager, engines, shared scripts
└── pnpm-workspace.yaml        # Workspace configuration
```

**Examples:**
```json
// tsconfig.json - Base configuration
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true
  }
}
```

```javascript
// eslint.config.js - Shared linting
export default [
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      "@typescript-eslint/no-unused-vars": "error",
      "@typescript-eslint/explicit-function-return-type": "warn"
    }
  }
];
```

### **Package-Specific Overrides - `packages/*/`**
Only for configuration that legitimately varies by domain:

```
packages/user-service/
├── tsconfig.json              # Extends workspace, adds domain-specific paths
├── vitest.config.ts           # Domain-specific test setup
└── src/config/                # Business domain configuration
    ├── database.config.ts
    └── auth.config.ts
```

**Override Examples:**
```json
// packages/user-service/tsconfig.json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@user-service/*": ["src/*"],
      "@shared/*": ["../../shared/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["dist", "node_modules"]
}
```

```typescript
// packages/user-service/vitest.config.ts
import { defineConfig } from 'vitest/config';
import baseConfig from '../../vitest.config';

export default defineConfig({
  ...baseConfig,
  test: {
    ...baseConfig.test,
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      thresholds: {
        statements: 90, // Higher threshold for critical service
        branches: 85,
        functions: 90,
        lines: 90
      }
    }
  }
});
```

### **Decision Framework for Overrides**
Only create package-specific configuration when:

1. **Domain Requirements**: Business logic genuinely requires different configuration
2. **Environment Differences**: Package deploys to fundamentally different environments
3. **Dependency Variations**: Package has materially different dependency requirements
4. **Performance Needs**: Package has specific performance characteristics requiring tuning

**Anti-patterns to avoid:**
- Copying workspace configuration just to make minor tweaks
- Creating overrides for developer preferences rather than technical requirements
- Package-specific configuration that could be environment variables instead

### **Configuration Layering**
Follow leyline's external configuration pattern:

```
Workspace defaults → Package overrides → Environment variables → Runtime arguments
```

Example implementation:
```typescript
// packages/api-service/src/config/index.ts
import { z } from 'zod';

const configSchema = z.object({
  port: z.number().default(3000),
  database: z.object({
    host: z.string(),
    port: z.number().default(5432),
    name: z.string()
  }),
  auth: z.object({
    jwtSecret: z.string(),
    tokenExpiry: z.string().default('24h')
  })
});

// Environment variables override defaults
export const config = configSchema.parse({
  port: process.env.PORT ? parseInt(process.env.PORT) : undefined,
  database: {
    host: process.env.DB_HOST!,
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : undefined,
    name: process.env.DB_NAME!
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET!,
    tokenExpiry: process.env.JWT_EXPIRY
  }
});
```

## Consequences

### **Positive**
- Clear configuration hierarchy reduces cognitive overhead
- Shared tooling configuration ensures consistency across packages
- Package-specific overrides available when legitimately needed
- Follows established monorepo and TypeScript community patterns

### **Negative**
- Slight complexity in understanding inheritance chain
- Potential for configuration drift if overrides are overused
- Requires discipline to avoid unnecessary package-specific configuration

## Compliance with Leyline Principles

- **Centralized Configuration**: Workspace root serves as single source of truth for shared concerns
- **Simplicity**: Default to centralized, escalate to distributed only when justified
- **External Configuration**: Support environment-based overrides at all levels
- **Module Organization**: Package-specific configuration stays close to domain logic
- **Flexible Architecture**: Configuration-driven behavior enables runtime adaptation
