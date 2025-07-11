---
id: api-versioning-strategy
last_modified: '2025-06-14'
version: '0.2.0'
derived_from: adaptability-and-reversibility
enforced_by: API design review & breaking change detection
---
# Binding: Version APIs to Enable Evolution Without Breaking Changes

Design API versioning strategies that allow backwards-compatible evolution while providing clear migration paths when breaking changes are unavoidable. Prioritize additive changes and graceful deprecation over frequent version bumps.

## Rationale

This binding implements our adaptability-and-reversibility tenet by acknowledging that APIs must evolve to meet changing business needs while maintaining compatibility with existing consumers. Without a versioning strategy, APIs become brittle—either frozen in time to avoid breaking consumers, or constantly breaking existing integrations with each change.

Think of API versioning like renovating a building while people continue to live and work in it. You can add new rooms, improve existing spaces, and gradually replace outdated systems, but you can't suddenly change the location of the main entrance or remove the elevators without giving residents time to adapt. Similarly, API versioning allows you to improve and extend your API while giving consumers time to migrate when necessary.

This binding also supports our simplicity tenet by establishing consistent patterns for version management rather than ad-hoc approaches that create confusion and maintenance overhead.

## Rule Definition

This binding establishes versioning principles for API evolution:

- **Version Placement Strategy**: Choose one primary versioning approach:
  - URL versioning: `/v1/users`, `/v2/users` (most visible, cache-friendly)
  - Header versioning: `Accept: application/vnd.api+json;version=1` (cleaner URLs)
  - Query parameter: `/users?version=1` (simple, but easily overlooked)

- **Breaking Change Definition**: Establish what constitutes a breaking change:
  - Removing fields from responses
  - Changing field types or formats
  - Adding required request parameters
  - Changing HTTP status codes for existing scenarios
  - Modifying error response structures

- **Backwards Compatibility Requirements**: Default to additive changes:
  - Add optional fields to responses
  - Add optional parameters to requests
  - Add new endpoints
  - Expand enum values (with careful client consideration)

- **Deprecation Timeline**: Provide adequate notice for breaking changes:
  - Minimum 6 months notice for deprecated features
  - Clear migration documentation before deprecation
  - Monitoring of deprecated feature usage
  - Communication plan for affected consumers

## Implementation

Apply versioning consistently across your API:

1. **Version Strategy Selection**: Choose URL versioning for public APIs (visibility), header versioning for internal APIs (flexibility).

2. **Version Scope**: Version at the appropriate granularity:
   - Major version for breaking changes: `v1` → `v2`
   - Minor version for significant additions: `v1.1`, `v1.2`
   - Avoid micro-versioning for bug fixes

3. **Default Version Handling**: Always specify behavior when no version is provided:
   - Redirect to latest stable version
   - Provide deprecation headers
   - Document version selection logic

4. **Migration Support**: For breaking changes, provide:
   - Side-by-side version support during transition
   - Automated migration tools where possible
   - Clear mapping between old and new formats

## Anti-patterns

- **Version Proliferation**: Creating new versions for every change
- **Immediate Deprecation**: Removing old versions without adequate notice
- **Hidden Breaking Changes**: Making incompatible changes within the same version
- **Version Inconsistency**: Using different versioning approaches across endpoints
- **Perpetual Beta**: Keeping APIs in "beta" to avoid version commitments

## Enforcement

This binding should be enforced through:

- **Breaking Change Detection**: Automated tools that identify API contract changes
- **Version Lifecycle Management**: Clear policies for version introduction and retirement
- **Consumer Impact Analysis**: Assessment of changes on existing integrations
- **Documentation Updates**: Automatic documentation generation for each version

## Exceptions

Valid deviations from standard versioning:

- **Internal APIs**: May use simpler versioning for controlled environments
- **Prototype APIs**: Experimental endpoints may have relaxed compatibility requirements
- **Emergency Fixes**: Security patches may require immediate breaking changes
- **Sunset Services**: End-of-life APIs may have accelerated deprecation timelines

Always document versioning decisions and their rationale.

## Related Bindings

- [rest-api-standards](../../docs/bindings/categories/api/rest-api-standards.md): RESTful design principles that support versioning
- [api-documentation-requirements](../../docs/bindings/categories/api/api-documentation-requirements.md): Documenting version differences
- [preferred-technology-patterns](../../core/preferred-technology-patterns.md): Technology choices for version management
