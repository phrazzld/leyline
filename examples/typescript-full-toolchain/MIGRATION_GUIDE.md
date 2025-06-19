# TypeScript Bindings Migration Guide

This guide provides practical steps for integrating new TypeScript toolchain bindings with existing Leyline bindings in your projects.

## Migration Approaches

### Approach A: Greenfield Projects (Recommended)

**Use Case**: New TypeScript projects starting from scratch

**Steps**:

1. Use the `typescript-full-toolchain` example as your project template
2. Copy all configuration files (`package.json`, `tsconfig.json`, `eslint.config.js`, etc.)
3. Follow both existing and new bindings from day one
4. Implement full automation and quality gates immediately

**Benefits**:

- Maximum toolchain efficiency from the start
- No migration overhead or technical debt
- Complete automation and quality enforcement
- Proven working configuration

### Approach B: Incremental Integration (Existing Projects)

**Use Case**: Existing TypeScript projects that need gradual improvement

**Phase 1: Foundation (Week 1-2)**

1. **Package Management Enhancement**:

   ```bash
   # If not using pnpm, migrate
   rm node_modules package-lock.json yarn.lock
   pnpm install

   # Apply package.json standards
   # - Add packageManager field
   # - Add engines requirements
   # - Add security scripts
   ```

2. **Code Quality Automation**:

   ```bash
   # Install ESLint/Prettier toolchain
   pnpm add -D eslint prettier @typescript-eslint/eslint-plugin

   # Copy eslint.config.js from example project
   # Adapt to your existing code patterns
   ```

**Phase 2: Testing Infrastructure (Week 3-4)**

1. **Add Vitest Framework**:

   ```bash
   # Replace existing test framework gradually
   pnpm add -D vitest @vitest/coverage-v8

   # Copy vitest.config.ts from example project
   # Migrate existing tests incrementally
   ```

2. **Test Coverage Enforcement**:
   ```bash
   # Add coverage thresholds
   # Start with current coverage level, increase gradually
   ```

**Phase 3: Build System (Week 5-6)**

1. **For Library Projects**:

   ```bash
   # Add tsup for dual ESM/CJS builds
   pnpm add -D tsup

   # Copy tsup.config.ts from example project
   # Replace existing build system
   ```

2. **For Application Projects**:
   ```bash
   # Keep existing build system (Vite, Next.js, etc.)
   # Apply TypeScript configuration standards
   ```

**Phase 4: State Management (Week 7-8)**

1. **For API-Heavy Applications**:

   ```bash
   # Add TanStack Query for server state
   pnpm add @tanstack/react-query

   # Keep existing client state management (Redux, Zustand, etc.)
   # Use TanStack Query for server state only
   ```

2. **Apply Type-Safe Patterns**:
   ```typescript
   // Enhance existing state with strict typing
   // Follow type-safe-state-management.md patterns
   ```

### Approach C: Selective Adoption

**Use Case**: Large projects where full migration is impractical

**High-Impact, Low-Risk Changes**:

1. **Package.json Standards** (✅ Low risk, high automation value)
2. **ESLint/Prettier Setup** (✅ Gradual rollout possible)
3. **Testing Framework** (✅ Can coexist with existing tests)

**Defer Until Major Refactor**:

1. **Build System Changes** (⚠️ Higher risk, coordinate with releases)
2. **State Management Changes** (⚠️ Requires application architecture review)

## Compatibility Verification Checklist

Before starting migration, verify your project meets these prerequisites:

### Technical Prerequisites

- [ ] Node.js >= 18.0.0
- [ ] TypeScript >= 5.0.0
- [ ] Existing project builds without errors
- [ ] Test suite passes (if exists)

### Project Prerequisites

- [ ] Development team buy-in for new tooling
- [ ] CI/CD pipeline supports pnpm
- [ ] Project timeline allows for gradual migration
- [ ] Stakeholder approval for automation changes

## Common Migration Challenges

### Challenge 1: ESLint Configuration Conflicts

**Symptom**: Linting errors on configuration files
**Solution**: Use the split configuration pattern from the example project:

```javascript
// Separate rules for source files vs config files
// Type-aware linting only for source code
```

### Challenge 2: Package Manager Switching

**Symptom**: CI pipeline failures after switching to pnpm
**Solution**: Update CI configuration:

```yaml
# GitHub Actions example
- uses: pnpm/action-setup@v2
  with:
    version: 10.2.0
- run: pnpm install --frozen-lockfile
```

### Challenge 3: Test Framework Migration

**Symptom**: Complex Jest configurations don't transfer to Vitest
**Solution**: Incremental migration:

```bash
# Keep Jest for existing tests
# Use Vitest for new tests
# Migrate one test file at a time
```

### Challenge 4: Build Output Changes

**Symptom**: Consumers break when switching to tsup dual builds
**Solution**: Coordinate with package consumers:

```json
// Maintain backward compatibility in package.json exports
// Provide migration timeline for consumers
```

## Success Metrics

Track these metrics during migration:

### Development Experience

- [ ] Faster dependency installs (pnpm benefit)
- [ ] Fewer linting configuration issues
- [ ] Faster test execution (Vitest benefit)
- [ ] Reduced CI pipeline times

### Code Quality

- [ ] Increased test coverage
- [ ] Fewer production bugs
- [ ] Reduced manual code review time
- [ ] Improved TypeScript compliance

### Team Productivity

- [ ] Reduced "works on my machine" issues
- [ ] Faster onboarding for new developers
- [ ] More consistent code formatting
- [ ] Improved development workflow automation

## Rollback Plan

If migration causes significant issues:

### Phase 1 Rollback (Package Management)

```bash
# Revert to previous package manager
rm pnpm-lock.yaml
npm install  # or yarn install
```

### Phase 2 Rollback (Code Quality)

```bash
# Disable new ESLint rules temporarily
# Keep Prettier formatting
# Address issues incrementally
```

### Phase 3 Rollback (Testing)

```bash
# Revert to previous test framework
# Keep Vitest configuration for reference
# Plan migration with smaller scope
```

## Team Training Resources

### For Developers

- [ ] Hands-on workshop with `typescript-full-toolchain` example
- [ ] Documentation of new commands and workflows
- [ ] Pair programming sessions for complex migrations

### For DevOps

- [ ] CI/CD pipeline configuration training
- [ ] pnpm and build system setup
- [ ] Security scanning tool configuration

### For Project Managers

- [ ] Migration timeline and milestone planning
- [ ] Risk assessment and mitigation strategies
- [ ] Communication plan for stakeholders

## Support and Troubleshooting

### Internal Resources

- Reference the `typescript-full-toolchain` example project
- Review compatibility matrix for specific binding interactions
- Check integration guide for common gotchas

### Community Resources

- Leyline documentation and binding specifications
- Tool-specific documentation (Vitest, tsup, TanStack Query)
- Community discussion forums and issue trackers

## Next Steps

After completing migration:

1. **Document lessons learned** for future projects
2. **Update team onboarding materials** with new toolchain
3. **Share success metrics** to demonstrate value
4. **Consider contributing improvements** back to Leyline bindings
