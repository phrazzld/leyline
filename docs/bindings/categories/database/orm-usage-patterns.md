---
id: orm-usage-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: simplicity
enforced_by: code review & style guides
---

# Binding: Prevent N+1 Queries and Control ORM Loading

Object-Relational Mapping (ORM) tools must be used in ways that prevent N+1 query
problems and maintain explicit control over data loading strategies. Always prefer
eager loading for known relationships, use query optimization techniques, and fall
back to raw SQL when ORMs introduce unnecessary complexity.

## Rationale

This binding directly implements our simplicity tenet by ensuring that database
interactions remain predictable and performant. ORMs promise to simplify database
access by abstracting SQL behind object-oriented interfaces, but this abstraction
can hide devastating performance problems if used carelessly. The most notorious
of these is the N+1 query problem, where what appears to be simple object access
triggers an avalanche of database queries.

Think of an ORM like a translator between two languages. A good translator doesn't
just convert words literally—they understand context and convey meaning efficiently.
Similarly, a well-used ORM should translate your data needs into efficient SQL, not
generate a flood of queries that would make any DBA weep. When you load a list of
authors and then access their books, you want one or two queries, not one query per
author plus one for the initial list.

The pursuit of simplicity doesn't mean avoiding ORMs entirely—they can significantly
reduce boilerplate code and provide valuable abstractions. Rather, it means using
them with full awareness of their behavior, maintaining explicit control over query
generation, and knowing when to bypass the abstraction for a simpler, more direct
approach. A simple system is one where database performance is predictable and
query patterns are intentional, not accidental.

## Rule Definition

Proper ORM usage requires understanding and controlling how your object model
translates to database queries. This means being explicit about data loading,
preventing cascading queries, and recognizing when the ORM abstraction is adding
rather than removing complexity.

Key principles for ORM usage:

- **Prevent N+1 Queries**: Always explicitly load related data that will be accessed
- **Explicit Loading Strategy**: Choose between eager and lazy loading intentionally, not by default
- **Query Awareness**: Understand the SQL your ORM generates and monitor it in development
- **Bounded Contexts**: Don't try to model your entire database in a single object graph
- **Performance First**: Optimize for common query patterns, not theoretical flexibility

Common patterns that this binding requires:

- Using includes/joins for associations you know you'll access
- Batching queries when loading collections
- Defining specific query objects for complex data needs
- Using projections to load only needed fields
- Implementing query result caching appropriately

What this explicitly prohibits:

- Accessing associations in loops without preloading
- Relying on lazy loading in production code paths
- Building deep object graphs that trigger cascade loads
- Using ORM-generated queries for reporting or analytics
- Ignoring query performance in favor of "clean" object models

## Practical Implementation

1. **Always Preload Known Associations**: When you know you'll access related data,
   load it eagerly in the initial query. This prevents N+1 queries and makes
   performance predictable.

   ```ruby
   # Rails/ActiveRecord example
   # ❌ BAD: N+1 query problem
   def index
     @posts = Post.published
     # View will trigger N queries when accessing post.author
   end

   # ✅ GOOD: Eager loading prevents N+1
   def index
     @posts = Post.published.includes(:author, :categories)
     # Single query with joins, no additional queries in view
   end

   # ✅ BETTER: Specific loading for different needs
   def index
     @posts = Post.published
                  .includes(:author)
                  .preload(:categories)  # Separate query, better for many-to-many
                  .select('posts.id, posts.title, posts.summary')  # Only needed fields
   end
   ```

2. **Use Query Objects for Complex Needs**: When queries become complex or are
   reused across different contexts, extract them into dedicated query objects
   that encapsulate the loading strategy.

   ```python
   # Django example with query objects
   class PublishedArticlesQuery:
       """Encapsulates the query logic for published articles with related data."""

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

3. **Monitor Queries in Development**: Use debugging tools to see actual SQL
   generated by your ORM. Make query counts and patterns visible during
   development to catch problems early.

   ```javascript
   // TypeORM with query logging
   import { DataSource } from "typeorm";

   const AppDataSource = new DataSource({
       type: "postgres",
       host: "localhost",
       // ... other config
       logging: process.env.NODE_ENV === 'development' ? ["query", "error"] : ["error"],
       maxQueryExecutionTime: 1000,  // Log slow queries
   });

   // Repository with explicit loading
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

4. **Implement the Repository Pattern**: Separate data access logic from business
   logic by implementing repositories that handle all ORM interactions. This makes
   loading strategies explicit and testable.

   ```csharp
   // C# Entity Framework Core example
   public interface IOrderRepository
   {
       Task<Order> GetOrderWithDetailsAsync(int orderId);
       Task<IEnumerable<Order>> GetRecentOrdersForCustomerAsync(int customerId);
   }

   public class OrderRepository : IOrderRepository
   {
       private readonly AppDbContext _context;

       public OrderRepository(AppDbContext context)
       {
           _context = context;
       }

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

5. **Know When to Use Raw SQL**: When ORMs make simple things complex or when
   you need specific database features, don't hesitate to use raw SQL. Wrap it
   in clean abstractions that maintain type safety.

   ```go
   // Go with sqlx (a thin wrapper, not full ORM)
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

## Examples

```python
# ❌ BAD: Classic N+1 problem in Django
def get_blog_data():
    posts = BlogPost.objects.filter(published=True)
    result = []

    for post in posts:  # 1 query
        result.append({
            'title': post.title,
            'author': post.author.name,  # N queries (one per post)
            'comment_count': post.comments.count(),  # N more queries
            'tags': [tag.name for tag in post.tags.all()]  # N more queries
        })

    return result
    # Total queries: 1 + N + N + N (catastrophic for large datasets)

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
            'author': post.author.name,  # No additional query
            'comment_count': post.comment_count,  # No additional query
            'tags': [tag.name for tag in post.tags.all()]  # No additional query
        })

    return result
    # Total queries: 3 (posts with author, tags, comment count)
```

```ruby
# ❌ BAD: Hidden N+1 in view layer (Rails)
# Controller
class ProductsController < ApplicationController
  def index
    @products = Product.available
  end
end

# View (index.html.erb)
<% @products.each do |product| %>
  <div>
    <%= product.name %>
    by <%= product.manufacturer.name %>  <!-- N+1 here -->
    in <%= product.category.name %>  <!-- Another N+1 -->

    <% if product.reviews.any? %>  <!-- Yet another N+1 -->
      Rating: <%= product.reviews.average(:rating).round(1) %>  <!-- And another -->
    <% end %>
  </div>
<% end %>

# ✅ GOOD: Explicit loading with bullet gem for detection
class ProductsController < ApplicationController
  def index
    @products = Product.available
                      .includes(:manufacturer, :category)
                      .left_joins(:reviews)
                      .group('products.id')
                      .select(
                        'products.*',
                        'AVG(reviews.rating) as average_rating',
                        'COUNT(reviews.id) as review_count'
                      )
  end
end

# View now triggers no additional queries
<% @products.each do |product| %>
  <div>
    <%= product.name %>
    by <%= product.manufacturer.name %>
    in <%= product.category.name %>

    <% if product.review_count > 0 %>
      Rating: <%= product.average_rating.round(1) %>
    <% end %>
  </div>
<% end %>
```

```typescript
// ❌ BAD: Cascading loads with TypeORM
class OrderService {
  async getOrderSummaries(customerId: number) {
    const customer = await this.customerRepo.findOne(customerId);

    // Each order access triggers a query
    const summaries = customer.orders.map(order => ({
      id: order.id,
      total: order.total,
      itemCount: order.items.length,  // N queries for items
      status: order.status.name  // N queries for status
    }));

    return summaries;
  }
}

// ✅ GOOD: Purpose-built query with explicit loading
class OrderService {
  async getOrderSummaries(customerId: number) {
    const orders = await this.orderRepo
      .createQueryBuilder('order')
      .where('order.customerId = :customerId', { customerId })
      .leftJoinAndSelect('order.status', 'status')
      .loadRelationCountAndMap('order.itemCount', 'order.items')
      .getMany();

    // Or use a raw query for complex cases
    const summaries = await this.connection.query(`
      SELECT
        o.id,
        o.total,
        s.name as status_name,
        COUNT(oi.id) as item_count
      FROM orders o
      LEFT JOIN order_status s ON o.status_id = s.id
      LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.customer_id = $1
      GROUP BY o.id, s.name
    `, [customerId]);

    return summaries;
  }
}
```

## Related Bindings

- [query-optimization-and-indexing](query-optimization-and-indexing.md): Proper ORM usage
  goes hand-in-hand with query optimization. Understanding the queries your ORM generates
  is essential for creating appropriate indexes and recognizing performance bottlenecks.
  Both bindings work together to ensure database interactions remain performant.

- [repository-pattern](../../core/modularity.md): The repository pattern provides a
  boundary where ORM-specific code is contained, making it easier to control loading
  strategies and prevent ORM concerns from leaking into business logic. This separation
  supports both simplicity and modularity.

- [fail-fast-validation](../../core/fail-fast-validation.md): ORMs should validate data
  at the boundaries before persisting. This includes type validation, constraint checking,
  and business rule enforcement. Failing fast prevents bad data from entering the system
  and provides clearer error messages than database constraint violations.
