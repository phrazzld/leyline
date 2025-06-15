---
id: api-documentation-requirements
last_modified: '2025-06-14'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: documentation review & automated generation
---
# Binding: Maintain Comprehensive, Example-Rich API Documentation

Create and maintain API documentation that serves as the authoritative reference for all consumers. Documentation must include complete schemas, realistic examples, error scenarios, and be automatically generated from code to ensure accuracy.

## Rationale

This binding implements our explicit-over-implicit tenet by making API contracts, expectations, and behaviors visible and discoverable. Poor or missing documentation forces consumers to reverse-engineer APIs through trial and error, leading to misuse, brittle integrations, and support overhead. When documentation is comprehensive and accurate, it becomes the primary interface between API providers and consumers.

Think of API documentation like a building's blueprint. Just as architects and contractors rely on detailed blueprints to understand structure, materials, and systems, developers rely on API documentation to understand endpoints, data formats, and integration patterns. Incomplete blueprints lead to construction errors and unsafe buildings; incomplete API documentation leads to integration failures and unreliable software.

This binding also supports our automation tenet by requiring documentation generation from code, ensuring that documentation remains accurate as implementations change.

## Rule Definition

This binding establishes requirements for API documentation:

- **Format Standards**: Use OpenAPI (Swagger) specifications as the primary documentation format:
  - Complete schema definitions for all request/response objects
  - HTTP method and status code specifications
  - Parameter descriptions and constraints
  - Authentication and authorization requirements

- **Example Requirements**: Provide realistic examples for all endpoints:
  - Complete request examples with realistic data
  - Success response examples for each status code
  - Error response examples for common failure scenarios
  - Code samples in primary consumer languages

- **Schema Completeness**: Document all data structures thoroughly:
  - Field descriptions that explain business purpose
  - Data type specifications with format constraints
  - Required vs optional field distinctions
  - Enum value definitions and meanings

- **Error Documentation**: Comprehensive error handling guidance:
  - Error code catalog with descriptions
  - Common error scenarios and resolution steps
  - Rate limiting and retry guidance
  - Debugging information availability

## Implementation

Create documentation that serves consumers effectively:

1. **Documentation-First Design**: Write OpenAPI specs before implementation to clarify contracts and identify design issues early.

2. **Automated Generation**: Generate documentation from code annotations to ensure accuracy:
   - Use tools like `swagger-jsdoc`, `redoc`, or framework-specific generators
   - Validate that implementation matches documentation in CI
   - Auto-update documentation with each deployment

3. **Interactive Examples**: Provide working examples consumers can test:
   - Interactive API explorers (Swagger UI, Postman collections)
   - curl command examples with real endpoints
   - SDK code samples in popular languages

4. **Consumer-Focused Organization**: Structure documentation for discoverability:
   - Group endpoints by business function, not technical implementation
   - Provide getting-started guides for common use cases
   - Include authentication setup instructions

## Anti-patterns

- **Stale Documentation**: Documentation that doesn't match current implementation
- **Schema-Only Documentation**: Technical specs without business context or examples
- **Implementation Details**: Exposing internal architecture rather than consumer contracts
- **Manual Documentation**: Hand-written docs that quickly become outdated
- **Single Format**: Only providing documentation in one format (e.g., only Swagger UI)

## Enforcement

This binding should be enforced through:

- **Documentation CI Checks**: Automated validation that documentation matches implementation
- **Review Requirements**: Documentation updates required for all API changes
- **Consumer Testing**: Regular validation that documentation enables successful integration
- **Metrics Tracking**: Monitor documentation usage and identify gaps

## Exceptions

Acceptable variations in documentation approach:

- **Internal APIs**: May use simpler documentation for controlled consumer environments
- **Prototype APIs**: Early-stage APIs may have reduced documentation requirements
- **Generated APIs**: APIs generated from database schemas may use automated documentation
- **Legacy APIs**: Existing APIs may be documented incrementally during maintenance

Even with exceptions, maintain enough documentation for safe consumption.

## Related Bindings

- [rest-api-standards](./rest-api-standards.md): RESTful patterns that documentation should reflect
- [api-versioning-strategy](./api-versioning-strategy.md): Documenting version differences
- [unified-documentation](../../core/unified-documentation.md): Single source of truth principles
