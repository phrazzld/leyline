# TypeScript Binding Version Specification Policy

**Date:** 2025-06-18
**Status:** Decided
**Context:** Issue #87 - TypeScript bindings implementation

## Decision

**Use semantic version ranges in configuration examples with exact pinning only when security or stability requires it.**

## Rationale

Based on leyline's dependency management and security principles, this approach balances:

### **Security Benefits**
- **Automated security patches**: Caret ranges (`^1.2.0`) allow patch-level updates containing security fixes
- **Lockfile reproducibility**: pnpm-lock.yaml provides exact version tracking for builds
- **Security scanning**: Automated tools can detect vulnerabilities within version ranges

### **Maintenance Benefits**
- **Reduced update overhead**: Compatible updates happen automatically within semantic version constraints
- **Ecosystem compatibility**: Standard Node.js practice supports better tooling integration
- **Progressive enhancement**: Start simple, add exact pinning only where proven necessary

## Implementation Guidelines

### **Default Pattern - Semantic Version Ranges**
```json
{
  "dependencies": {
    "express": "^4.18.0",        // Minor/patch updates allowed
    "lodash": "^4.17.21",        // Standard library - safe updates
    "helmet": "^7.0.0"           // Security middleware - allow patches
  },
  "devDependencies": {
    "vitest": "^1.0.0",          // Test framework - minor updates beneficial
    "eslint": "^8.0.0",          // Linting - updates often fix issues
    "tsup": "^8.0.0"             // Build tool - compatibility updates useful
  }
}
```

### **Exact Pinning - When Required**
```json
{
  "dependencies": {
    "jsonwebtoken": "9.0.0",     // Security-sensitive: CVE history requires control
    "node-forge": "1.3.1"       // Compliance requirement: audited version
  }
}
```

### **Documentation Requirements**
When exact pinning is used, include inline comments explaining:
- **Security rationale**: Known CVE patterns, security sensitivity
- **Compliance requirements**: Audit requirements, certification needs
- **Stability concerns**: Frequent breaking changes, unstable API

### **Enforcement Mechanisms**
- **pnpm lockfiles**: Ensure reproducible builds regardless of range specification
- **Automated security scanning**: CI pipeline catches vulnerabilities in ranges
- **Documentation validation**: Require rationale comments for exact versions

## Consequences

### **Positive**
- Automatic security patch adoption
- Reduced maintenance overhead for non-critical dependencies
- Better ecosystem tool compatibility
- Clear escalation path for dependencies requiring exact control

### **Negative**
- Potential for unexpected minor version incompatibilities
- Requires security scanning infrastructure
- More complex decision-making for version specification

## Compliance with Leyline Principles

- **Automation**: Automated updates and security scanning reduce manual overhead
- **Simplicity**: Default to ranges, escalate to exact pinning only when necessary
- **Security by Design**: Structured approach to security-sensitive dependencies
- **External Configuration**: Lockfiles handle exact version specification
- **80/20 Solution**: Focus exact pinning on the 20% of dependencies that create 80% of version-related issues
