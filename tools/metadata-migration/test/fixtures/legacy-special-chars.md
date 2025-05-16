______________________________________________________________________

id: no-lint-suppression derived_from: explicit-over-implicit enforced_by: linting rules & code review description: Linting rules should be fixed, not suppressed with `@ts-ignore` or `// eslint-disable`. special_field: This field has "quotes" and 'apostrophes' and some special chars: !@#$%^&*() last_modified: '2025-01-15'

______________________________________________________________________

# Binding: Fix Linting Issues, Don't Suppress Them

Never use lint suppression comments like `@ts-ignore`, `// eslint-disable`, or
`/* tslint:disable */` to bypass linting rules. Instead, fix the underlying issue or,
if the rule is genuinely inappropriate for your codebase, update the linting
configuration globally.

## Rationale

This binding implements our explicit-over-implicit tenet by preventing hidden quality
issues. When you suppress a linting rule, you're creating an invisible exception that
future maintainers might not notice.
