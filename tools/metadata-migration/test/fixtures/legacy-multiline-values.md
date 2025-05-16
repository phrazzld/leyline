______________________________________________________________________

id: require-conventional-commits derived_from: automation enforced_by: pre-commit hooks & CI validation summary: Use conventional commit format for all commit messages description: All commit messages MUST follow the Conventional Commits specification
to enable automated changelog generation and semantic versioning. This
standardization provides consistency across teams and enables tooling
to understand the semantic meaning of changes. last_modified: '2025-01-15'

______________________________________________________________________

# Binding: Use Conventional Commits for All Messages

All commit messages must follow the Conventional Commits specification. This standardized
format enables automated tooling for changelog generation, semantic versioning, and
release automation while making the git history more readable and searchable.

## Rationale

This binding implements our automation tenet by standardizing commit messages to enable
automated processes. Conventional commits create a structured, machine-readable format
that tools can parse to understand the nature and impact of changes.
