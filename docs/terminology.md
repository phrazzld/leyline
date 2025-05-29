# Leyline Terminology

This document provides canonical definitions for key Leyline concepts to ensure consistent usage across all documentation and clear communication with users.

## "Warden System" vs. "Pull-Based Sync"

### Warden System

The **Warden System** refers to Leyline's *philosophy* of standardized principles that:

- Centralizes the definition of development tenets and bindings
- Ensures consistent standards across codebases
- Establishes a single source of truth for development principles

The Warden System is a conceptual framework, not a technical implementation. It describes the value and purpose of having standardized development principles that are centrally defined and consistently applied across multiple projects.

### Pull-Based Sync

**Pull-Based Sync** is the *consumer-initiated implementation* that enables repositories to adopt the Warden System philosophy. It is implemented through the `sync-leyline-content.yml` GitHub Actions workflow, which:

- Is always initiated by the consumer repository
- Pulls content from the Leyline repository
- Never automatically pushes content to consumer repositories
- Gives consumers full control over when and what content is synchronized

The Pull-Based Sync model empowers consumers to control exactly when and how they receive updates to tenets and bindings, allowing for proper testing and integration planning.

## Important Distinctions

| Aspect | Warden System | Pull-Based Sync |
|--------|--------------|-----------------|
| Nature | Philosophy/Concept | Technical Implementation |
| Purpose | Standardize principles | Enable content synchronization |
| Control | N/A (conceptual) | Consumer-controlled |
| Direction | N/A (conceptual) | Consumer pulls from Leyline |
| Implementation | N/A (conceptual) | GitHub Actions workflow (`sync-leyline-content.yml`) |

## Documentation Guidelines

When writing or updating documentation:

1. Use "Warden System" when referring to the philosophy of standardized principles
2. Use "Pull-Based Sync" when referring to the technical implementation and mechanism
3. Always emphasize that synchronization is consumer-initiated (pull model)
4. Never imply that Leyline pushes content to consumers
5. When describing technical workflows, refer specifically to the `sync-leyline-content.yml` workflow
