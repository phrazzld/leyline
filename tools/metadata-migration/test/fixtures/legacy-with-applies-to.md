______________________________________________________________________

id: error-wrapping derived_from: explicit-over-implicit enforced_by: code review applies_to: go last_modified: '2025-01-15'

______________________________________________________________________

# Binding: Wrap Errors with Meaningful Context

Always wrap errors with meaningful context as they propagate up through layers of your
application. Use the standard library's `%w` verb in Go (or preferred error wrapping
in other languages) to maintain the error chain while adding layer-specific information
about what operation failed and with what inputs.

## Rationale

This binding implements our explicit-over-implicit tenet by requiring that errors
carry sufficient context to be debuggable without needing to trace through code.

In distributed systems and complex applications, errors often travel far from their
origin before being logged or presented to users. Without proper context at each layer,
debugging becomes a frustrating archaeology expedition through logs and code.
