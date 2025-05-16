---
id: modularity
last_modified: '2025-01-15'
---

# Tenet: Modularity Through Small, Focused Components

Build systems from small, focused modules with single responsibilities and clear
boundaries. Each module should do one thing well, with minimal dependencies and
well-defined interfaces.

## Core Belief

Modularity is fundamental to managing complexity in software systems. When you
decompose a system into small, focused modules, you create natural boundaries that
make the system easier to understand, test, and modify.

Think of software modules like LEGO blocks. Each block has a specific shape and
purpose, with standardized connection points that allow them to combine in predictable
ways. You can understand what a single block does without needing to understand the
entire structure, and you can rearrange blocks to create new structures without
breaking existing connections.

## Practical Guidelines

1. **Single Responsibility**: Each module should have one reason to change. If you find
   yourself using "and" to describe what a module does, it's probably doing too much.

2. **Clear Boundaries**: Modules should communicate through well-defined interfaces,
   not through shared state or global variables.

## Related Tenets

- [Simplicity](simplicity.md): Modularity and simplicity work together—simple modules
  with clear responsibilities combine to create understandable systems.
