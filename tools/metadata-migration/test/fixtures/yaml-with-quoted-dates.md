---
id: testability
last_modified: '2025-01-15'
---

# Tenet: Design for Testability from the Start

Structure code so that testing is natural and straightforward, not an afterthought.
Testable code has clear boundaries, minimal dependencies, and predictable behavior.
If testing feels difficult, the design needs improvement.

## Core Belief

Testability is not just about quality assurance—it's a fundamental design principle
that leads to better architecture. When code is hard to test, it's usually because
the design has problems: tight coupling, hidden dependencies, or mixed responsibilities.

Think of testability like maintaining a car. A well-designed car has clear access
points for checking fluids, replacing filters, and diagnosing problems. Similarly,
well-designed code has clear interfaces for verifying behavior, injecting dependencies,
and isolating functionality.

## Related Tenets

- [Simplicity](simplicity.md): Simple code is inherently more testable because it has
  fewer dependencies and clearer behavior.
- [Modularity](modularity.md): Modular code creates natural testing boundaries,
  allowing you to test components in isolation.
