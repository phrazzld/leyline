---
id: orm-usage-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: simplicity
enforced_by: code review & style guides
---

# Binding: Prevent N+1 Queries and Control ORM Loading

Object-Relational Mapping (ORM) tools must be used in ways that prevent N+1 query problems and maintain explicit control over data loading strategies. Always prefer eager loading for known relationships, use query optimization techniques, and fall back to raw SQL when ORMs introduce unnecessary complexity.

## Rationale

This binding implements our simplicity tenet by ensuring that database interactions remain predictable and performant. ORMs promise to simplify database access, but this abstraction can hide devastating performance problems if used carelessly. The most notorious is the N+1 query problem, where what appears to be simple object access triggers an avalanche of database queries. Simple systems require predictable database performance and intentional query patterns.

## Rule Definition

**Core Requirements:**

- **Prevent N+1 Queries**: Always explicitly load related data that will be accessed in loops or iterations
- **Explicit Loading Strategy**: Choose between eager and lazy loading intentionally, not by default
- **Query Awareness**: Understand the SQL your ORM generates and monitor it in development
- **Bounded Contexts**: Don't try to model your entire database in a single object graph
- **Performance First**: Optimize for common query patterns, not theoretical flexibility

**Required Patterns:**
- Using includes/joins for associations you know you'll access
- Batching queries when loading collections
- Using projections to load only needed fields
- Implementing query result caching appropriately

**Prohibited Practices:**
- Accessing associations in loops without preloading
- Relying on lazy loading in production code paths
- Building deep object graphs that trigger cascade loads
- Using ORM-generated queries for reporting or analytics

## Practical Implementation

**Comprehensive ORM Usage Patterns:**

```python
# ❌ BAD: Classic N+1 problem
def get_blog_data():
    posts = BlogPost.objects.filter(published=True)  # 1 query
    result = []

    for post in posts:
        result.append({
            'title': post.title,
            'author': post.author.name,              # N queries (one per post)
            'comment_count': post.comments.count(),  # N more queries
            'tags': [tag.name for tag in post.tags.all()]  # N more queries
        })

    return result
    # Total: 1 + N + N + N queries (catastrophic for large datasets)

# ✅ GOOD: Optimized with proper eager loading
def get_blog_data():
    posts = (
        BlogPost.objects
        .filter(published=True)
        .select_related('author')  # JOIN for one-to-one/many-to-one
        .prefetch_related('tags')  # Separate query for many-to-many
        .annotate(comment_count=Count('comments'))  # Aggregation in database
    )

    result = []
    for post in posts:  # Still 1 base query
        result.append({
            'title': post.title,
            'author': post.author.name,              # No additional query
            'comment_count': post.comment_count,     # No additional query
            'tags': [tag.name for tag in post.tags.all()]  # No additional query
        })

    return result
    # Total: 3 queries (posts with author, tags, comment count)
```

**Query Objects for Complex Needs:**

```python
# Django - Encapsulate complex loading strategies
class PublishedArticlesQuery:
    """Encapsulates query logic for published articles with related data."""

    def __init__(self, user=None):
        self.user = user

    def execute(self):
        queryset = (
            Article.objects
            .filter(status='published')
            .select_related('author', 'category')  # One-to-one/many-to-one
            .prefetch_related('tags', 'comments')  # Many-to-many/reverse FK
        )

        if self.user:
            # Add user-specific annotations
            queryset = queryset.annotate(
                is_bookmarked=Exists(
                    Bookmark.objects.filter(
                        user=self.user,
                        article=OuterRef('pk')
                    )
                )
            )

        return queryset.order_by('-published_at')

# Usage is clean and intention is clear
articles = PublishedArticlesQuery(user=request.user).execute()
```

**Repository Pattern with Explicit Loading:**

```csharp
// C# Entity Framework Core - Repository with explicit strategies
public interface IOrderRepository
{
    Task<Order> GetOrderWithDetailsAsync(int orderId);
    Task<IEnumerable<Order>> GetRecentOrdersForCustomerAsync(int customerId);
}

public class OrderRepository : IOrderRepository
{
    private readonly AppDbContext _context;

    public async Task<Order> GetOrderWithDetailsAsync(int orderId)
    {
        // Explicit loading strategy for single order
        return await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.ShippingAddress)
            .AsSplitQuery()  // Prevent cartesian explosion
            .FirstOrDefaultAsync(o => o.Id == orderId);
    }

    public async Task<IEnumerable<Order>> GetRecentOrdersForCustomerAsync(int customerId)
    {
        // Different loading strategy for list view
        return await _context.Orders
            .Where(o => o.CustomerId == customerId)
            .Where(o => o.CreatedAt > DateTime.UtcNow.AddDays(-30))
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new Order
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CreatedAt = o.CreatedAt,
                TotalAmount = o.TotalAmount,
                Status = o.Status,
                // Projection to avoid loading unnecessary data
            })
            .ToListAsync();
    }
}
```

**Raw SQL for Complex Cases:**

```go
// Go with sqlx - When ORMs make simple things complex
type OrderStats struct {
    CustomerID   int       `db:"customer_id"`
    TotalOrders  int       `db:"total_orders"`
    TotalRevenue float64   `db:"total_revenue"`
    LastOrderAt  time.Time `db:"last_order_at"`
}

func (r *OrderRepository) GetCustomerStats(ctx context.Context, customerIDs []int) ([]OrderStats, error) {
    // Complex aggregation is clearer in SQL
    query := `
        SELECT
            customer_id,
            COUNT(*) as total_orders,
            SUM(total_amount) as total_revenue,
            MAX(created_at) as last_order_at
        FROM orders
        WHERE customer_id = ANY($1)
            AND status != 'cancelled'
        GROUP BY customer_id
    `

    var stats []OrderStats
    err := r.db.SelectContext(ctx, &stats, query, pq.Array(customerIDs))
    return stats, err
}
```

**Development Monitoring:**

```javascript
// TypeORM with query logging for development
const AppDataSource = new DataSource({
    type: "postgres",
    logging: process.env.NODE_ENV === 'development' ? ["query", "error"] : ["error"],
    maxQueryExecutionTime: 1000,  // Log slow queries
});

export class ArticleRepository {
    async findPublishedWithAuthor(): Promise<Article[]> {
        return this.createQueryBuilder("article")
            .leftJoinAndSelect("article.author", "author")
            .leftJoinAndSelect("article.categories", "category")
            .where("article.status = :status", { status: "published" })
            .orderBy("article.publishedAt", "DESC")
            .getMany();
        // Query count: 1 (with joins)
        // Without joins: 1 + N (one per article for author)
    }
}
```

## Related Bindings

- [query-optimization-and-indexing](../../docs/bindings/categories/database/query-optimization-and-indexing.md): Understanding ORM-generated queries is essential for creating appropriate indexes and recognizing performance bottlenecks
- [modularity](../../../tenets/modularity.md): Repository pattern provides boundaries where ORM-specific code is contained, preventing ORM concerns from leaking into business logic
- [fail-fast-validation](../../core/fail-fast-validation.md): ORMs should validate data at boundaries before persisting to prevent bad data from entering the system
