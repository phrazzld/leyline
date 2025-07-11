---
id: rest-first-api-design
last_modified: '2025-06-14'
version: '0.2.0'
derived_from: simplicity
enforced_by: 'OpenAPI specification validation, API design review, documentation standards'
---
# Binding: Design REST APIs First, GraphQL When Necessary

Design APIs using REST principles with OpenAPI specifications as the default approach. Only consider GraphQL or other API paradigms when you have specific, documented requirements that REST cannot address effectively, such as complex data relationships or mobile bandwidth constraints.

## Rationale

This binding implements our simplicity tenet by establishing REST as the foundation for API design, avoiding the accidental complexity that often comes with more sophisticated API paradigms.

Think of API design like choosing a transportation system for a city. REST is like a well-planned road network—straightforward, universally understood, and capable of handling most traffic efficiently. GraphQL is like a subway system—powerful for specific use cases but requiring significant infrastructure investment and specialized knowledge. Most cities start with roads and only build subways when traffic patterns clearly justify the complexity.

REST's constraint-based architecture naturally aligns with simplicity principles. Its stateless nature, uniform interface, and cacheable responses create predictable patterns that developers can understand quickly. When you choose REST first, you're choosing an approach that prioritizes clear contracts, explicit resource modeling, and standard HTTP semantics over clever solutions that might seem more elegant but introduce hidden complexity.

The OpenAPI specification serves as REST's documentation foundation, creating machine-readable contracts that enable automatic validation, code generation, and testing. This explicit contract definition eliminates ambiguity about API behavior and creates a single source of truth that both API producers and consumers can rely on.

## Rule Definition

This rule applies to all API design decisions, whether for public APIs, internal microservices, or mobile backends. The rule specifically requires:

- **REST First**: Begin every API design process with REST principles and HTTP semantics
- **OpenAPI Documentation**: Create OpenAPI 3.0+ specifications before implementation begins
- **Justification for Alternatives**: Document specific technical requirements that REST cannot address before considering GraphQL, gRPC, or other paradigms
- **Resource Modeling**: Design APIs around resources and standard HTTP verbs (GET, POST, PUT, DELETE, PATCH)

The rule prohibits jumping to GraphQL or other complex API paradigms without demonstrating that REST's limitations create genuine problems for your specific use case. It also prohibits implementing APIs without proper OpenAPI documentation.

Exceptions may be appropriate for specialized domains like real-time systems, complex data aggregation requirements, or legacy integration constraints, but these must be documented with clear rationale.

## Practical Implementation

1. **Start with Resource Identification**: Begin API design by identifying the core resources in your domain. Model these as nouns (users, orders, products) rather than actions, and design URL structures that reflect resource hierarchies naturally.

2. **Create OpenAPI Specifications First**: Write OpenAPI specifications before implementing any API endpoints. Use these specifications to validate your API design with stakeholders and generate documentation, client SDKs, and validation schemas.

3. **Follow REST Conventions**: Use standard HTTP status codes, implement proper caching headers, design idempotent operations where appropriate, and follow established REST patterns for pagination, filtering, and sorting.

4. **Validate GraphQL Requirements**: Before considering GraphQL, document specific requirements such as: mobile bandwidth optimization, complex nested data fetching, real-time subscriptions, or client-specific data shaping needs that REST cannot address efficiently.

5. **Implement Consistent Error Handling**: Establish standard error response formats using HTTP status codes and structured error bodies that clients can handle predictably across all endpoints.

## Examples

```yaml
# ❌ BAD: Starting with GraphQL without justification
type Query {
  user(id: ID!): User
  posts(userId: ID!, limit: Int): [Post]
}

# ✅ GOOD: REST-first approach with clear resource modeling
paths:
  /users/{userId}:
    get:
      summary: Get user by ID
      responses:
        '200':
          description: User found
  /users/{userId}/posts:
    get:
      summary: Get posts for user
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
```

```http
# ❌ BAD: Non-RESTful API design
POST /api/getUserPosts
Content-Type: application/json
{
  "userId": 123,
  "action": "fetch",
  "options": {"limit": 10}
}

# ✅ GOOD: REST-compliant resource access
GET /api/users/123/posts?limit=10
Accept: application/json
```

```yaml
# ❌ BAD: Implementing API without OpenAPI specification
# (No specification exists, developers guess at contracts)

# ✅ GOOD: OpenAPI-first development
openapi: 3.0.3
info:
  title: User Management API
  version: 1.0.0
paths:
  /users/{userId}/posts:
    get:
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: integer
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Posts retrieved successfully
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Post'
```

## Related Bindings

- [api-design.md](../core/api-design.md): This binding builds on the core API design principles by providing specific guidance on API paradigm selection, while the core binding focuses on explicit contracts and clear interfaces.

- [explicit-over-implicit.md](../../tenets/explicit-over-implicit.md): REST's resource-based approach and OpenAPI specifications directly support explicitness by making API contracts, resource relationships, and operation semantics clearly visible and machine-readable.
