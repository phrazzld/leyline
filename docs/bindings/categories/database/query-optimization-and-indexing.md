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

This binding directly implements our explicit-over-implicit tenet by ensuring
that database performance characteristics are visible, intentional, and
maintainable rather than left to chance. Database optimizers are sophisticated
but not omniscient—they make decisions based on statistics and heuristics that
may not align with your application's actual usage patterns. When you leave
optimization decisions implicit, you're essentially gambling with your users'
experience and your system's scalability.

Think of query optimization like urban planning. A city that grows organically
without explicit planning often ends up with traffic congestion, inefficient
infrastructure, and poor resource distribution. Similarly, a database that
relies solely on implicit optimization often develops performance bottlenecks,
resource contention, and unpredictable response times. Explicit optimization
is like having a master plan—you intentionally design indexes, monitor traffic
patterns (query execution), and make informed decisions about infrastructure
(database design) based on real usage data.

The complexity of modern applications makes implicit optimization particularly
dangerous. What works well with 1,000 users and 10,000 records may fail
catastrophically with 100,000 users and 10 million records. By making
optimization decisions explicit, you create a system where performance
characteristics are predictable, where bottlenecks can be anticipated and
prevented, and where the reasoning behind design decisions is preserved for
future maintainers.

## Rule Definition

Explicit query optimization means taking deliberate, informed actions to
ensure database performance rather than hoping the database will figure it
out on its own. This requires understanding how your queries execute, making
conscious decisions about indexes and query structure, and continuously
validating performance assumptions.

Key principles for explicit optimization:

- **Analyze Before Optimizing**: Always examine query execution plans before making changes
- **Index with Purpose**: Create indexes based on actual query patterns, not speculation
- **Monitor Continuously**: Establish baseline performance metrics and track changes over time
- **Document Decisions**: Record why indexes exist and what queries they're meant to optimize
- **Validate Impact**: Measure the actual performance impact of optimization changes

Common patterns this binding requires:

- Query plan analysis for complex or frequently-executed queries
- Index creation with specific query patterns in mind
- Performance benchmarking before and after optimization changes
- Regular review of index usage and effectiveness
- Explicit query hints when optimizer decisions need override

What this explicitly prohibits:

- Creating indexes "just in case" without understanding their purpose
- Ignoring query execution plans and hoping for the best
- Making optimization changes without measuring their impact
- Leaving slow queries unanalyzed and unoptimized
- Relying solely on database defaults for performance-critical systems

## Practical Implementation

1. **Establish Query Plan Analysis as Standard Practice**: Make examining
   execution plans a routine part of query development. Understand how your
   database decides to execute queries and identify potential performance issues
   before they reach production.

   ```sql
   -- PostgreSQL: Always analyze execution plans for complex queries
   EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
   SELECT p.name, p.price, c.name as category, COUNT(r.id) as review_count
   FROM products p
   JOIN categories c ON p.category_id = c.id
   LEFT JOIN reviews r ON p.id = r.product_id
   WHERE p.status = 'active'
     AND p.price BETWEEN 50 AND 200
   GROUP BY p.id, p.name, p.price, c.name
   ORDER BY review_count DESC
   LIMIT 20;

   -- Look for:
   -- - Sequential scans on large tables (need indexes)
   -- - High buffer usage (memory inefficiency)
   -- - Expensive sort operations (consider different ordering)
   -- - Nested loop joins with large datasets (need better indexes)
   ```

2. **Create Purpose-Driven Indexes**: Design indexes specifically for your
   application's query patterns. Document what each index is meant to optimize
   and regularly review their effectiveness.

   ```sql
   -- Document index purpose and monitor usage

   -- Index for product search with price filtering
   -- Supports: WHERE status = 'active' AND price BETWEEN x AND y
   -- Query pattern: Product catalog with price filters
   CREATE INDEX idx_products_active_price
   ON products (status, price)
   WHERE status = 'active';

   -- Composite index for order history queries
   -- Supports: WHERE customer_id = x ORDER BY created_at DESC
   -- Query pattern: Customer order history pagination
   CREATE INDEX idx_orders_customer_created
   ON orders (customer_id, created_at DESC);

   -- Partial index for active user sessions
   -- Supports: WHERE expires_at > NOW() AND user_id = x
   -- Query pattern: Session validation
   CREATE INDEX idx_sessions_active_user
   ON user_sessions (user_id)
   WHERE expires_at > NOW();

   -- Track index usage
   SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
   FROM pg_stat_user_indexes
   WHERE idx_scan < 100  -- Identify unused indexes
   ORDER BY idx_scan;
   ```

3. **Implement Performance Monitoring and Alerting**: Establish baseline
   performance metrics and create alerts for degradation. Make query
   performance visible to the development team.

   ```python
   # Django example with query performance monitoring
   import time
   import logging
   from django.db import connection
   from django.conf import settings

   logger = logging.getLogger('query_performance')

   class QueryPerformanceMiddleware:
       def __init__(self, get_response):
           self.get_response = get_response

       def __call__(self, request):
           if settings.DEBUG or settings.MONITOR_QUERIES:
               initial_queries = len(connection.queries)
               start_time = time.time()

           response = self.get_response(request)

           if settings.DEBUG or settings.MONITOR_QUERIES:
               total_time = time.time() - start_time
               total_queries = len(connection.queries) - initial_queries

               # Log slow requests
               if total_time > 1.0:  # 1 second threshold
                   logger.warning(
                       "Slow request detected",
                       extra={
                           'path': request.path,
                           'method': request.method,
                           'duration': total_time,
                           'query_count': total_queries,
                           'queries': connection.queries[initial_queries:] if settings.DEBUG else None
                       }
                   )

               # Alert on high query count (potential N+1)
               if total_queries > 20:
                   logger.error(
                       "High query count detected",
                       extra={
                           'path': request.path,
                           'query_count': total_queries,
                           'duration': total_time
                       }
                   )

           return response
   ```

4. **Use Database-Specific Optimization Features**: Leverage your database's
   specific features for optimization, but document why you're using them and
   what problems they solve.

   ```sql
   -- PostgreSQL: Use query hints when optimizer needs guidance

   -- Force index usage when statistics are misleading
   /*+ IndexScan(products idx_products_active_price) */
   SELECT * FROM products
   WHERE status = 'active' AND price > 100;

   -- Use materialized views for complex aggregations
   CREATE MATERIALIZED VIEW product_stats AS
   SELECT
       p.category_id,
       COUNT(*) as product_count,
       AVG(p.price) as avg_price,
       COUNT(r.id) as total_reviews,
       AVG(r.rating) as avg_rating
   FROM products p
   LEFT JOIN reviews r ON p.id = r.product_id
   WHERE p.status = 'active'
   GROUP BY p.category_id;

   -- Refresh strategy documented and automated
   CREATE UNIQUE INDEX ON product_stats (category_id);

   -- Automated refresh (called by application or cron)
   REFRESH MATERIALIZED VIEW CONCURRENTLY product_stats;
   ```

5. **Regular Performance Review Process**: Establish a routine for reviewing
   and optimizing database performance. Make this an explicit part of your
   development process rather than a reactive firefighting exercise.

   ```go
   // Go example: Database performance audit tool
   package main

   import (
       "database/sql"
       "fmt"
       "log"
       "time"
   )

   type QueryStats struct {
       Query       string
       Calls       int64
       TotalTime   time.Duration
       MeanTime    time.Duration
       MaxTime     time.Duration
   }

   type PerformanceAuditor struct {
       db *sql.DB
   }

   func (pa *PerformanceAuditor) GetSlowQueries() ([]QueryStats, error) {
       // PostgreSQL: Find slow queries from pg_stat_statements
       query := `
           SELECT
               query,
               calls,
               total_exec_time,
               mean_exec_time,
               max_exec_time
           FROM pg_stat_statements
           WHERE mean_exec_time > 100  -- Queries slower than 100ms
           ORDER BY mean_exec_time DESC
           LIMIT 20
       `

       rows, err := pa.db.Query(query)
       if err != nil {
           return nil, err
       }
       defer rows.Close()

       var stats []QueryStats
       for rows.Next() {
           var s QueryStats
           var totalTime, meanTime, maxTime float64

           err := rows.Scan(
               &s.Query,
               &s.Calls,
               &totalTime,
               &meanTime,
               &maxTime,
           )
           if err != nil {
               return nil, err
           }

           s.TotalTime = time.Duration(totalTime) * time.Millisecond
           s.MeanTime = time.Duration(meanTime) * time.Millisecond
           s.MaxTime = time.Duration(maxTime) * time.Millisecond

           stats = append(stats, s)
       }

       return stats, nil
   }

   func (pa *PerformanceAuditor) GetUnusedIndexes() error {
       // Find indexes that are never used
       query := `
           SELECT schemaname, tablename, indexname, idx_scan
           FROM pg_stat_user_indexes
           WHERE idx_scan = 0
             AND indexname NOT LIKE '%_pkey'  -- Exclude primary keys
           ORDER BY pg_relation_size(indexname::regclass) DESC
       `

       rows, err := pa.db.Query(query)
       if err != nil {
           return err
       }
       defer rows.Close()

       fmt.Println("Unused indexes (consider dropping):")
       for rows.Next() {
           var schema, table, index string
           var scans int
           rows.Scan(&schema, &table, &index, &scans)
           fmt.Printf("  %s.%s.%s (scans: %d)\n", schema, table, index, scans)
       }

       return nil
   }
   ```

## Examples

```sql
-- ❌ BAD: Creating indexes without understanding query patterns
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_created_at ON users (created_at);
CREATE INDEX idx_users_status ON users (status);
CREATE INDEX idx_users_name ON users (name);

-- No analysis of which queries actually need these indexes
-- No documentation of their purpose
-- Potential for unused indexes consuming space and slowing writes

-- ✅ GOOD: Purpose-driven index creation with analysis
-- Analysis: User authentication queries always filter by email
-- Query pattern: SELECT * FROM users WHERE email = ?
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, email, password_hash FROM users WHERE email = 'user@example.com';

-- Decision: Create index to support login queries
CREATE INDEX idx_users_email_login ON users (email)
WHERE status = 'active';  -- Partial index for better selectivity

-- Document in schema migration
COMMENT ON INDEX idx_users_email_login IS
'Supports user authentication queries. Created 2025-01-12 for login performance.';
```

```python
# ❌ BAD: Ignoring query performance in application code
def get_user_dashboard_data(user_id):
    user = User.objects.get(id=user_id)

    # These queries will be inefficient without analysis
    recent_orders = user.orders.filter(
        created_at__gte=timezone.now() - timedelta(days=30)
    )[:10]

    favorite_products = Product.objects.filter(
        favorites__user=user
    ).order_by('-favorites__created_at')[:5]

    return {
        'user': user,
        'recent_orders': recent_orders,
        'favorite_products': favorite_products
    }

# ✅ GOOD: Explicit optimization with query analysis
def get_user_dashboard_data(user_id):
    # Analyze the query patterns first:
    # EXPLAIN SELECT * FROM orders WHERE user_id = X AND created_at >= Y ORDER BY created_at DESC LIMIT 10
    # Result: Need index on (user_id, created_at) for efficient filtering and sorting

    # Optimize with explicit query strategy
    with connection.cursor() as cursor:
        # Log query performance for monitoring
        start_time = time.time()

        recent_orders = Order.objects.filter(
            user_id=user_id,
            created_at__gte=timezone.now() - timedelta(days=30)
        ).select_related('status', 'shipping_address').order_by('-created_at')[:10]

        query_time = time.time() - start_time
        if query_time > 0.1:  # 100ms threshold
            logger.warning(f"Slow dashboard query: {query_time:.3f}s for user {user_id}")

    # Use explicit join for favorites with proper index support
    favorite_products = Product.objects.filter(
        favorites__user_id=user_id
    ).select_related('category').order_by('-favorites__created_at')[:5]

    return {
        'user': User.objects.get(id=user_id),
        'recent_orders': list(recent_orders),
        'favorite_products': list(favorite_products)
    }
```

```typescript
// ❌ BAD: Complex queries without optimization analysis
class ReportService {
    async getMonthlyReport(companyId: number, month: string) {
        // Complex aggregation without query plan analysis
        const report = await this.repository.query(`
            SELECT
                u.department,
                COUNT(*) as employee_count,
                SUM(s.amount) as total_sales,
                AVG(s.amount) as avg_sale
            FROM users u
            JOIN sales s ON u.id = s.user_id
            WHERE u.company_id = $1
                AND s.created_at >= $2
                AND s.created_at < $3
            GROUP BY u.department
            ORDER BY total_sales DESC
        `, [companyId, month + '-01', nextMonth + '-01']);

        return report;
    }
}

// ✅ GOOD: Explicit optimization with performance monitoring
class ReportService {
    private logger = new Logger('ReportService');

    async getMonthlyReport(companyId: number, month: string): Promise<MonthlyReport[]> {
        // Document optimization strategy:
        // 1. Analyzed query plan - needed composite index on (company_id, created_at)
        // 2. Added index: CREATE INDEX idx_sales_company_date ON sales (company_id, created_at)
        // 3. Baseline performance: ~50ms for 100k records

        const startTime = Date.now();

        try {
            const report = await this.repository.query(`
                -- Optimized query with explicit index hints where supported
                SELECT
                    u.department,
                    COUNT(*) as employee_count,
                    SUM(s.amount) as total_sales,
                    AVG(s.amount) as avg_sale
                FROM users u
                INNER JOIN sales s ON u.id = s.user_id
                WHERE u.company_id = $1
                    AND s.created_at >= $2::date
                    AND s.created_at < ($2::date + INTERVAL '1 month')
                GROUP BY u.department
                ORDER BY total_sales DESC
            `, [companyId, month + '-01']);

            const duration = Date.now() - startTime;

            // Monitor performance and alert on regressions
            this.logger.log(`Monthly report generated in ${duration}ms for company ${companyId}`);

            if (duration > 1000) {  // 1 second threshold
                this.logger.warn(`Slow report query detected: ${duration}ms`, {
                    companyId,
                    month,
                    queryTime: duration
                });
            }

            return report;

        } catch (error) {
            this.logger.error('Report generation failed', { companyId, month, error });
            throw error;
        }
    }
}
```

## Related Bindings

- [orm-usage-patterns](orm-usage-patterns.md): ORM query optimization works
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
