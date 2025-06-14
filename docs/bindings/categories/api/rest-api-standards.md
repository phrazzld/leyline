---
id: rest-api-standards
last_modified: '2025-06-14'
version: '0.1.0'
derived_from: simplicity
enforced_by: API linting & code review
---
# Binding: Design RESTful APIs Around Resources, Not Actions

Structure APIs around nouns (resources) rather than verbs (actions), using standard HTTP methods to convey operations. This creates predictable, discoverable interfaces that clients can understand without extensive documentation.

## Rationale

This binding implements our simplicity tenet by leveraging the established semantics of HTTP rather than inventing custom conventions. When APIs follow RESTful resource patterns, developers can predict endpoint structures, understand relationships between entities, and implement clients with confidence. This predictability reduces cognitive load and prevents the accumulation of ad-hoc patterns that make APIs difficult to learn and maintain.

Think of RESTful design like organizing a library. In a well-organized library, you find books by subject, author, or title—not by actions like "get-science-book" or "return-fiction-novel." The organizational structure (resources) combined with standard operations (check out, return, reserve) creates a system everyone can understand. Similarly, RESTful APIs organize around resources (users, orders, products) with standard operations (GET, POST, PUT, DELETE) that have universally understood meanings.

## Rule Definition

This binding establishes standards for RESTful API design:

- **Resource Identification**: Design URLs around resources, not actions:
  - ✅ `GET /users/123` (resource-oriented)
  - ❌ `GET /getUser?id=123` (action-oriented)
  - ✅ `POST /orders` (create resource)
  - ❌ `POST /createOrder` (action-oriented)

- **HTTP Method Semantics**: Use HTTP methods according to their defined meanings:
  - `GET`: Retrieve without side effects (idempotent)
  - `POST`: Create new resources or non-idempotent operations
  - `PUT`: Replace entire resources (idempotent)
  - `PATCH`: Partial updates (idempotent)
  - `DELETE`: Remove resources (idempotent)

- **Resource Relationships**: Express relationships through URL structure:
  - Collection: `/users`
  - Instance: `/users/123`
  - Nested: `/users/123/orders`
  - Filtering: `/users?status=active`

- **Status Code Consistency**: Use standard HTTP status codes appropriately:
  - `200 OK`: Successful GET, PUT, PATCH
  - `201 Created`: Successful POST creating resource
  - `204 No Content`: Successful DELETE or update with no response body
  - `400 Bad Request`: Client error in request format
  - `404 Not Found`: Resource doesn't exist
  - `409 Conflict`: Business logic conflict

## Implementation

Apply RESTful principles consistently:

1. **Resource Modeling**: Identify core business entities as resources. If you're tempted to use a verb in the URL, reconsider the resource model.

2. **Collection Patterns**: Use consistent patterns for collections:
   - Pagination: `?page=2&per_page=50`
   - Sorting: `?sort=created_at&order=desc`
   - Filtering: `?status=active&category=electronics`

3. **Action Handling**: For operations that don't map to CRUD:
   - Model as state transitions: `PUT /orders/123/status`
   - Create sub-resources: `POST /orders/123/cancellations`
   - Use custom actions sparingly: `POST /users/123/reset-password`

4. **Response Consistency**: Maintain consistent response structures across endpoints, including error formats.

## Anti-patterns

- **RPC-style Endpoints**: URLs like `/api/getUserById` or `/api/processOrder`
- **Misused HTTP Methods**: Using POST for all operations or GET for updates
- **Inconsistent Pluralization**: Mixing `/user` and `/products`
- **Deep Nesting**: URLs like `/users/123/orders/456/items/789/reviews`
- **Business Logic in URLs**: Endpoints like `/api/calculateTax` instead of resources

## Enforcement

This binding should be enforced through:

- **API Design Reviews**: Review endpoint designs before implementation
- **OpenAPI Specifications**: Define APIs formally before coding
- **Automated Linting**: Tools that validate RESTful patterns
- **Client Feedback**: Regular reviews with API consumers

## Exceptions

Valid deviations from pure REST:

- **Batch Operations**: `POST /users/batch` for bulk operations
- **Search Endpoints**: `POST /search` for complex query bodies
- **Webhooks/Callbacks**: Event-driven patterns that don't fit REST
- **Real-time Features**: WebSocket or Server-Sent Events for live data
- **Legacy Compatibility**: Gradual migration from existing patterns

Document why REST doesn't fit when deviating.

## Related Bindings

- [api-versioning-strategy](./api-versioning-strategy.md): Versioning RESTful APIs
- [api-documentation-requirements](./api-documentation-requirements.md): Documenting resource models
- [toolchain-selection-criteria](../../core/toolchain-selection-criteria.md): Framework selection for API development
