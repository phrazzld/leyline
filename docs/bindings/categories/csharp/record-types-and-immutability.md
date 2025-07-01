---
id: record-types-and-immutability
last_modified: '2025-07-01'
version: '0.1.0'
derived_from: maintainability
enforced_by: 'Code review, Roslyn analyzers, Architecture tests'
---

# Binding: Records and Immutability Patterns

Use record types for all data transfer objects, value objects, and domain events. Prefer init-only properties for objects requiring partial mutability. Default to immutable collections and builder patterns for complex object construction. Make mutability the exception that requires justification, not the default.

## Rationale

This binding implements our immutable-by-default tenet by leveraging C#'s record types and modern immutability features to create safer, more predictable code. Mutable state remains one of the primary sources of bugs in software: race conditions in concurrent code, unexpected side effects from shared references, and defensive copying throughout codebases.

Consider the compound cost of mutable objects: every method receiving an object must either trust it won't be modified elsewhere or create defensive copies. In concurrent scenarios, mutable shared state requires complex synchronization. When debugging, you can't trust that an object's state remains constant between observations. These issues multiply as systems grow, creating fragile architectures where changes in one area cause unexpected failures elsewhere.

Record types and immutability patterns eliminate entire categories of bugs. When objects are immutable, they can be safely shared across threads without synchronization. Method signatures become honest—when you pass an object to a method, you know it can't be modified. Testing becomes simpler as you don't need to verify objects weren't unexpectedly mutated. The mental model becomes clearer: data flows through transformations rather than being modified in place.

## Rule Definition

This rule applies to all C# code defining data structures, DTOs, domain models, and value objects. The rule specifically requires:

**Type Selection Standards:**
- Use `record` for all DTOs and API contracts
- Use `record struct` for small value types (≤ 16 bytes)
- Use `record class` with init-only properties for domain entities
- Regular classes only for services, handlers, and types with behavior
- Immutable collections for all collection properties

**Immutability Patterns:**
- All properties must be init-only or get-only
- No public setters on data-holding types
- Use `with` expressions for creating modified copies
- Builder pattern for complex object construction
- Factory methods for valid object creation

**Collection Standards:**
- Return `IReadOnlyList<T>`, `IReadOnlyDictionary<TKey, TValue>`, etc.
- Use `ImmutableArray<T>`, `ImmutableList<T>` for internal storage
- Never expose `List<T>`, `Dictionary<TKey, TValue>` as properties
- Empty collections instead of null

**Mutation Boundaries:**
- Mutations only in explicit command handlers or services
- Immutable domain events for all state changes
- Mutable builders with immutable results
- Document any mutable types with justification

The rule prohibits public setters on DTOs, mutable collection properties, and modification of objects after construction without explicit architectural justification.

## Practical Implementation

1. **Record Types for DTOs**: Define clean data contracts:
   ```csharp
   // API request/response DTOs
   public record CreateOrderRequest(
       string CustomerId,
       IReadOnlyList<OrderItemDto> Items,
       AddressDto ShippingAddress)
   {
       // Additional validation in primary constructor
       public CreateOrderRequest : this
       {
           ArgumentException.ThrowIfNullOrEmpty(CustomerId);
           if (Items.Count == 0)
               throw new ArgumentException("Order must contain at least one item");
       }
   }

   public record OrderItemDto(
       string ProductId,
       int Quantity,
       decimal UnitPrice);

   public record AddressDto(
       string Street,
       string City,
       string PostalCode,
       string Country);
   ```

2. **Domain Models with Init Properties**: Controlled mutability for entities:
   ```csharp
   public record class Order
   {
       public string Id { get; init; }
       public string CustomerId { get; init; }
       public OrderStatus Status { get; init; }
       public ImmutableArray<OrderItem> Items { get; init; }
       public DateTime CreatedAt { get; init; }
       public DateTime? ShippedAt { get; init; }

       // Factory method ensures valid state
       public static Order Create(string customerId, IEnumerable<OrderItem> items)
       {
           return new Order
           {
               Id = Guid.NewGuid().ToString(),
               CustomerId = customerId,
               Status = OrderStatus.Pending,
               Items = items.ToImmutableArray(),
               CreatedAt = DateTime.UtcNow,
               ShippedAt = null
           };
       }

       // Methods return new instances
       public Order Ship() => this with
       {
           Status = OrderStatus.Shipped,
           ShippedAt = DateTime.UtcNow
       };
   }
   ```

3. **Value Objects with Record Structs**: Efficient immutable values:
   ```csharp
   public readonly record struct Money(decimal Amount, string Currency)
   {
       // Validation in primary constructor
       public Money : this
       {
           if (Amount < 0)
               throw new ArgumentException("Amount cannot be negative");
           ArgumentException.ThrowIfNullOrEmpty(Currency);
       }

       // Immutable operations return new instances
       public Money Add(Money other)
       {
           if (Currency != other.Currency)
               throw new InvalidOperationException($"Cannot add {Currency} and {other.Currency}");

           return this with { Amount = Amount + other.Amount };
       }

       // Convenient operators
       public static Money operator +(Money left, Money right) => left.Add(right);
   }
   ```

4. **Immutable Collections**: Safe collection handling:
   ```csharp
   public record ProductCatalog
   {
       private readonly ImmutableDictionary<string, Product> _products;

       public ProductCatalog(IEnumerable<Product> products)
       {
           _products = products.ToImmutableDictionary(p => p.Id);
       }

       // Expose as read-only interface
       public IReadOnlyDictionary<string, Product> Products => _products;

       // Operations return new instances
       public ProductCatalog AddProduct(Product product)
       {
           return new ProductCatalog(_products.Values.Append(product));
       }

       public ProductCatalog RemoveProduct(string productId)
       {
           return new ProductCatalog(_products.Values.Where(p => p.Id != productId));
       }
   }
   ```

5. **Builder Pattern for Complex Objects**: Mutable builder, immutable result:
   ```csharp
   public class OrderBuilder
   {
       private string? _customerId;
       private readonly List<OrderItem> _items = new();
       private ShippingAddress? _shippingAddress;

       public OrderBuilder ForCustomer(string customerId)
       {
           _customerId = customerId;
           return this;
       }

       public OrderBuilder AddItem(string productId, int quantity, decimal unitPrice)
       {
           _items.Add(new OrderItem(productId, quantity, unitPrice));
           return this;
       }

       public OrderBuilder ShipTo(ShippingAddress address)
       {
           _shippingAddress = address;
           return this;
       }

       public Order Build()
       {
           if (_customerId is null)
               throw new InvalidOperationException("Customer ID is required");
           if (_items.Count == 0)
               throw new InvalidOperationException("Order must contain at least one item");
           if (_shippingAddress is null)
               throw new InvalidOperationException("Shipping address is required");

           return Order.Create(_customerId, _items, _shippingAddress);
       }
   }
   ```

6. **Configuration for Immutability**: Analyzer rules and conventions:
   ```xml
   <!-- Directory.Build.props -->
   <Project>
     <ItemGroup>
       <!-- Immutability analyzers -->
       <PackageReference Include="ImmutabilityAnalyzer" Version="1.0.0" />
     </ItemGroup>
   </Project>
   ```

   ```ini
   # .editorconfig
   # Prefer readonly fields
   dotnet_diagnostic.CA1051.severity = error  # Do not declare visible instance fields
   dotnet_diagnostic.CA2227.severity = error  # Collection properties should be read only

   # Prefer init-only properties
   dotnet_diagnostic.IDE0032.severity = suggestion  # Use auto property
   dotnet_diagnostic.IDE0045.severity = suggestion  # Use conditional expression
   ```

## Examples

```csharp
// ❌ BAD: Mutable DTO with public setters
public class UserDto
{
    public string Id { get; set; }
    public string Name { get; set; }
    public List<string> Roles { get; set; }  // Mutable collection!
}

// ✅ GOOD: Immutable record with read-only collection
public record UserDto(
    string Id,
    string Name,
    IReadOnlyList<string> Roles);
```

```csharp
// ❌ BAD: In-place mutation
public class ShoppingCart
{
    public List<CartItem> Items { get; } = new();
    public decimal Total { get; set; }

    public void AddItem(CartItem item)
    {
        Items.Add(item);  // Mutating collection
        Total += item.Price;  // Mutating property
    }
}

// ✅ GOOD: Immutable operations
public record ShoppingCart(
    ImmutableList<CartItem> Items,
    Money Total)
{
    public ShoppingCart AddItem(CartItem item)
    {
        return this with
        {
            Items = Items.Add(item),
            Total = Total + item.Price
        };
    }
}
```

```csharp
// ❌ BAD: Defensive copying due to mutability
public class OrderService
{
    public void ProcessOrder(Order order)
    {
        // Must defensive copy to avoid external mutations
        var orderCopy = new Order
        {
            Id = order.Id,
            Items = new List<OrderItem>(order.Items),
            // ... copy all properties
        };

        // Process with copy
    }
}

// ✅ GOOD: No defensive copying needed
public class OrderService
{
    public void ProcessOrder(Order order)
    {
        // Order is immutable - safe to use directly
        foreach (var item in order.Items)
        {
            ProcessItem(item);
        }
    }
}
```

## Related Bindings

- [immutable-by-default.md](../core/immutable-by-default.md): This binding directly implements the immutable-by-default tenet using C#'s record types and modern immutability features.

- [defensive-programming.md](../core/defensive-programming.md): Immutability eliminates the need for defensive copying, allowing defensive programming to focus on actual edge cases rather than protecting against mutations.

- [pure-functions.md](../core/pure-functions.md): Immutable types naturally lead to pure functions, as methods can't have side effects on immutable data structures.

- [thread-safety.md](../core/thread-safety.md): Immutable objects are inherently thread-safe, eliminating complex synchronization requirements in concurrent scenarios.

- [domain-modeling.md](../core/domain-modeling.md): Record types and immutability patterns enable rich domain modeling where invalid states are unrepresentable and business rules are enforced through types.
