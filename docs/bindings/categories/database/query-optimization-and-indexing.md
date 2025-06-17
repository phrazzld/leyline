---
id: query-optimization-and-indexing
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: performance monitoring & code review
---

# Binding: Make Query Optimization Decisions Explicit

All database query optimization decisions must be explicitly documented and
implemented rather than relying on database defaults or implicit behavior.
Create indexes intentionally, analyze query plans regularly, and establish
clear performance benchmarks with monitoring to detect regressions.

## Rationale

This binding implements our explicit-over-implicit tenet by ensuring database performance decisions are visible and intentional. Database optimizers make decisions based on statistics that may not align with actual usage patterns. Implicit optimization creates unpredictable performance that degrades as data scales. Explicit optimization enables predictable performance characteristics and preserves the reasoning behind design decisions.

## Rule Definition

**Core Requirements:**

- **Query Plan Analysis**: Examine execution plans before optimizing complex or frequent queries
- **Purpose-Driven Indexes**: Create indexes based on actual query patterns with documented purpose
- **Performance Monitoring**: Establish baseline metrics and track changes over time
- **Impact Validation**: Measure actual performance improvements from optimization changes
- **Regular Review**: Audit index usage and query performance as part of development process

**Key Patterns:**
- Explicit query plan analysis using `EXPLAIN ANALYZE`
- Index creation targeting specific query patterns
- Performance benchmarking and regression detection
- Documentation of optimization decisions and rationale

## Practical Implementation

**Comprehensive Query Optimization with Monitoring and Documentation:**

```sql
-- 1. Query Plan Analysis for Complex Queries
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.name, p.price, c.name as category, COUNT(r.id) as review_count
FROM products p
JOIN categories c ON p.category_id = c.id
LEFT JOIN reviews r ON p.id = r.product_id
WHERE p.status = 'active' AND p.price BETWEEN 50 AND 200
GROUP BY p.id, p.name, p.price, c.name
ORDER BY review_count DESC LIMIT 20;

-- 2. Purpose-Driven Index Creation with Documentation
-- Index for product search with price filtering
-- Supports: WHERE status = 'active' AND price BETWEEN x AND y
CREATE INDEX idx_products_active_price
ON products (status, price) WHERE status = 'active';

-- Composite index for order history queries
-- Supports: WHERE customer_id = x ORDER BY created_at DESC
CREATE INDEX idx_orders_customer_created
ON orders (customer_id, created_at DESC);

-- 3. Index Usage Monitoring
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan < 100  -- Identify unused indexes
ORDER BY idx_scan;

-- 4. Slow Query Detection
SELECT query, calls, mean_exec_time, max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries slower than 100ms
ORDER BY mean_exec_time DESC LIMIT 20;
```

```python
# Performance Monitoring Integration
import time
import logging
from django.db import connection

logger = logging.getLogger('query_performance')

class QueryPerformanceMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.time()
        initial_queries = len(connection.queries)

        response = self.get_response(request)

        total_time = time.time() - start_time
        total_queries = len(connection.queries) - initial_queries

        # Alert on performance issues
        if total_time > 1.0:  # 1 second threshold
            logger.warning("Slow request detected", extra={
                'path': request.path,
                'duration': total_time,
                'query_count': total_queries
            })

        if total_queries > 20:  # N+1 query detection
            logger.error("High query count detected", extra={
                'path': request.path,
                'query_count': total_queries
            })

        return response

# Optimized Query Implementation
def get_user_dashboard_data(user_id):
    # Documented optimization: Index on (user_id, created_at) for efficient sorting
    recent_orders = Order.objects.filter(
        user_id=user_id,
        created_at__gte=timezone.now() - timedelta(days=30)
    ).select_related('status').order_by('-created_at')[:10]

    # Performance monitoring
    start_time = time.time()
    orders_list = list(recent_orders)
    query_time = time.time() - start_time

    if query_time > 0.1:  # 100ms threshold
        logger.warning(f"Slow dashboard query: {query_time:.3f}s for user {user_id}")

    return {'recent_orders': orders_list}
```

## Examples

```sql
-- ❌ BAD: Creating indexes without understanding query patterns
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_created_at ON users (created_at);
CREATE INDEX idx_users_status ON users (status);
-- No analysis, documentation, or understanding of actual query needs

-- ✅ GOOD: Purpose-driven index creation with analysis
-- Analysis: User authentication queries always filter by email
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email, password_hash FROM users WHERE email = 'user@example.com';

-- Decision: Create index to support login queries
CREATE INDEX idx_users_email_login ON users (email) WHERE status = 'active';
COMMENT ON INDEX idx_users_email_login IS
'Supports user authentication queries. Created 2025-01-12 for login performance.';
```

```python
# ❌ BAD: Ignoring query performance in application code
def get_user_dashboard_data(user_id):
    # These queries will be inefficient without analysis
    recent_orders = user.orders.filter(
        created_at__gte=timezone.now() - timedelta(days=30)
    )[:10]
    return {'recent_orders': recent_orders}

# ✅ GOOD: Explicit optimization with query analysis
def get_user_dashboard_data(user_id):
    # Analysis: Need index on (user_id, created_at) for efficient filtering/sorting
    start_time = time.time()

    recent_orders = Order.objects.filter(
        user_id=user_id,
        created_at__gte=timezone.now() - timedelta(days=30)
    ).select_related('status').order_by('-created_at')[:10]

    query_time = time.time() - start_time
    if query_time > 0.1:  # 100ms threshold
        logger.warning(f"Slow dashboard query: {query_time:.3f}s for user {user_id}")

    return {'recent_orders': list(recent_orders)}
```
```

## Related Bindings

- [orm-usage-patterns](../../docs/bindings/categories/database/orm-usage-patterns.md): ORM query optimization works
  hand-in-hand with explicit optimization. Understanding how your ORM generates
  SQL is essential for creating appropriate indexes and recognizing when to bypass
  the ORM for performance-critical queries.

- [use-structured-logging](../../core/use-structured-logging.md): Performance
  monitoring requires structured logging to track query execution times, identify
  slow queries, and correlate performance issues with specific operations. Both
  bindings work together to create observable, optimized systems.

- [external-configuration](../../core/external-configuration.md): Optimization
  settings like query timeouts, connection pool sizes, and performance thresholds
  should be externally configurable rather than hardcoded. This allows for
  environment-specific tuning without code changes.
