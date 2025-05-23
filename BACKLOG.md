# BACKLOG

- incorporate top tier pragmatic programming principles

## High Priority

### System Architecture Simplification & Core Tooling

-   **[Refactor]**: **Eliminate Dual Metadata Formats in Tenets and Bindings**
    *   **Complexity**: Medium
    *   **Rationale**: Supporting both YAML front-matter and legacy horizontal rule formats increases tooling complexity, introduces contributor confusion, and creates parsing brittleness. Standardization is key to Simplicity and Automation.
    *   **Expected Outcome**: All tenet and binding Markdown files use exclusively YAML front-matter. All validation, indexing, and generation tools are simplified, containing no logic for the legacy format. Documentation is updated to reflect the YAML-only approach.
    *   **Dependencies**: "Create One-Time Migration Script for Legacy Metadata".
-   [x] **[Chore]**: **Create One-Time Migration Script for Legacy Metadata to YAML**
    *   **Complexity**: Simple
    *   **Rationale**: To support the "Eliminate Dual Metadata Formats" initiative by programmatically converting all existing files, ensuring no data loss and minimizing manual effort.
    *   **Expected Outcome**: A robust script that reliably converts all legacy horizontal rule metadata blocks to YAML front-matter. All existing documents in the repository are successfully migrated.
    *   **Dependencies**: None.
-   **[Refactor]**: **Use Directory Structure as Single Source of Truth for Binding Categorization**
    *   **Complexity**: Medium
    *   **Rationale**: The deprecated `applies_to` metadata field creates redundancy and potential conflict with directory-based categorization. Simplifying to a single source of truth (directory location) streamlines logic, improves clarity, and aligns with the Simplicity tenet.
    *   **Expected Outcome**: The `applies_to` metadata field is removed from all bindings and their templates. Tooling, CI, and documentation solely rely on directory location (e.g., `/core`, `/categories/go`) to determine a binding's category.
    *   **Dependencies**: "Eliminate Dual Metadata Formats" (as metadata is being modified).
-   **[Refactor/Enhancement]**: **Unify Leyline Tooling into a CLI and Rewrite in TypeScript or Go**
    *   **Complexity**: Complex
    *   **Rationale**: Disparate Ruby scripts are hard to maintain, extend, and onboard contributors to. A unified CLI in a more common language (TS/Go) improves developer experience, maintainability, testability, and aligns the project's own tooling with languages it provides guidance for.
    *   **Expected Outcome**: A single, well-documented CLI application (e.g., `leyline-cli`) with subcommands for all validation, indexing, generation, and migration tasks. All existing Ruby scripts are deprecated and removed. The new CLI is written in either TypeScript or Go, with comprehensive test coverage.
    *   **Dependencies**: "Eliminate Dual Metadata Formats", "Use Directory Structure as Single Source of Truth for Binding Categorization".
-   **[Enhancement/Operational Excellence]**: **Automate Validation, Indexing, and Generation via Pre-commit Hooks & CI**
    *   **Complexity**: Medium
    *   **Rationale**: Ensures that all contributions adhere to standards (metadata, formatting, valid links, up-to-date indexes) automatically, reducing manual review burden, preventing errors, and improving repository health. Aligns with Automation tenet.
    *   **Expected Outcome**: Pre-commit hooks and CI jobs, utilizing the new unified CLI, automatically validate front-matter, generate/update indexes, check for broken links, and enforce formatting. Builds fail if critical standards are not met.
    *   **Dependencies**: "Unify Leyline Tooling into a CLI and Rewrite in TypeScript or Go".
-   **[Feature/Refactor]**: **Transform Philosophy Documents and Indexes into Generated Artifacts**
    *   **Complexity**: Medium
    *   **Rationale**: Manually maintained overview documents (like `DEVELOPMENT_PHILOSOPHY.md`) and indexes (like `00-index.md`) are prone to drift and create significant maintenance overhead. Making individual tenets/bindings the source of truth and auto-generating overviews ensures consistency, accuracy, and reduces manual effort. Aligns with Document Decisions and Automation tenets.
    *   **Expected Outcome**: Key overview documents and all index files are automatically generated from the content and structure of individual tenet and binding files. Manual editing of these generated files is disallowed and potentially enforced.
    *   **Dependencies**: "Unify Leyline Tooling into a CLI and Rewrite in TypeScript or Go", "Use Directory Structure as Single Source of Truth for Binding Categorization".
-   **[Process/Architecture]**: **Standardize on a Pull-Based Distribution Model for Consumers**
    *   **Complexity**: Simple
    *   **Rationale**: Clarifies and simplifies how consumer repositories integrate with Leyline, removing ambiguity around the "Warden System" and promoting a decentralized, scalable approach. Improves Simplicity for consumers.
    *   **Expected Outcome**: All documentation, examples, and CI/CD integration patterns (e.g., `vendor.yml`) consistently promote a pull-based mechanism (e.g., GitHub Actions reusable workflow) for consumers to sync tenets and bindings.
    *   **Dependencies**: None.

## Medium Priority

### Content Expansion & Key Features

-   **[Enhancement]**: **Expand Observability Binding to Cover Full Spectrum (Logs, Metrics, Tracing)**
    *   **Complexity**: Medium
    *   **Rationale**: To provide comprehensive guidance on observability beyond structured logging, incorporating metrics and distributed tracing, as outlined in T045 of `DEVELOPMENT_PHILOSOPHY.md`. This is crucial for Maintainability and understanding complex systems.
    *   **Expected Outcome**: The existing `use-structured-logging.md` binding is significantly expanded, or new, related bindings are created, to holistically cover the three pillars of observability.
    *   **Dependencies**: "Rewrite All Tenets and Bindings to be Natural Language First".
-   **[Feature/Enhancement]**: **Set Up and Maintain Generated Website for Displaying Tenets and Bindings**
    *   **Complexity**: Medium
    *   **Rationale**: A browsable, searchable, and well-organized website significantly improves the accessibility, discoverability, and usability of Leyline's standards for all consumers. Addresses Value Delivery and Developer Experience.
    *   **Expected Outcome**: A publicly accessible website that is automatically updated, accurately reflecting all tenets and bindings, with good navigation and search functionality.
    *   **Dependencies**: "Transform Philosophy Documents and Indexes into Generated Artifacts".
-   **[Feature]**: **Add Bindings for Preferred Tools and Packages**
    *   **Complexity**: Medium
    *   **Rationale**: To provide opinionated guidance on preferred technologies (e.g., pnpm > npm, Vitest > Jest, uv > pip, Playwright > Cypress) to promote consistency, leverage community best practices, and accelerate developer onboarding. Addresses Technical Excellence.
    *   **Expected Outcome**: New bindings created, likely within relevant categories (e.g., frontend, python), outlining preferred tools, rationale for preferences, and basic usage patterns.
    *   **Dependencies**: "Rewrite All Tenets and Bindings to be Natural Language First".
-   **[Feature]**: **Add Tenets/Bindings for Strongly Opinionated Design over Endless Configuration**
    *   **Complexity**: Simple
    *   **Rationale**: To formally capture and promote the philosophy of favoring simpler, opinionated systems with sensible defaults over highly configurable ones, which often lead to increased complexity and poorer UX. Aligns with Simplicity tenet.
    *   **Expected Outcome**: A new tenet and/or binding that articulates the value of opinionated design, provides guidance on when to prefer it, and how it contributes to better software.
    *   **Dependencies**: "Rewrite All Tenets and Bindings to be Natural Language First".
-   **[Enhancement/Feature]**: **Add/Enhance Storybook Tenets/Bindings**
    *   **Complexity**: Medium
    *   **Rationale**: To formalize and strengthen guidance for Storybook usage, promoting component-driven development, automated visual testing, and living documentation for UI components, based on `STORYBOOK_TENETS_SLASH_BINDINGS.md`.
    *   **Expected Outcome**: New or enhanced Frontend bindings covering Storybook-first development workflows, requirements for stories (variants, controls, actions), documentation within Storybook, and integration with testing and CI.
    *   **Dependencies**: "Rewrite All Tenets and Bindings to be Natural Language First".

## Low Priority

### Further Content Expansion & Operational Polish

-   **[Feature]**: **Add Other Technology/Area Bindings**
    *   **Complexity**: Medium (collectively)
    *   **Rationale**: To broaden Leyline's applicability and provide guidance for other relevant technologies and domains used within the organization.
    *   **Expected Outcome**: New category directories and initial sets of tenets/bindings created for:
        *   Python
        *   Bash scripting
        *   CLI (Command Line Interface) design
        *   Swift / iOS
        *   Android / Kotlin
        *   Mobile in general
        *   Chrome Browser Extension development
    *   **Dependencies**: "Use Directory Structure as Single Source of Truth for Binding Categorization", "Rewrite All Tenets and Bindings to be Natural Language First".
-   **[Enhancement/Operational Excellence]**: **Automate Security and Dependency Auditing for Leyline Itself**
    *   **Complexity**: Simple
    *   **Rationale**: To ensure Leyline's own toolchain and dependencies are secure and up-to-date, practicing what it preaches regarding software quality and security.
    *   **Expected Outcome**: CI pipeline for Leyline is enhanced with automated security vulnerability scans (e.g., `npm audit`, `cargo audit`, `govulncheck` depending on chosen CLI language) and dependency update checks.
    *   **Dependencies**: "Unify Leyline Tooling into a CLI and Rewrite in TypeScript or Go".
