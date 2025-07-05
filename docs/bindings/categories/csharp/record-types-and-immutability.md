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

This binding implements our immutable-by-default tenet using C#'s record types to create safer, more predictable code. Mutable state causes race conditions, unexpected side effects, and requires defensive copying throughout codebases.

Record types and immutability eliminate entire bug categories. Immutable objects are thread-safe, prevent unexpected mutations, and simplify testing. Data flows through transformations rather than being modified in place.

## Rule Definition

**Type Selection:**
- Use `record` for DTOs and API contracts
- Use `record struct` for small value types (≤ 16 bytes)
- Use `record class` with init-only properties for domain entities
- Regular classes only for services and behavioral types

**Immutability Requirements:**
- All properties must be init-only or get-only
- No public setters on data-holding types
- Use `with` expressions for modifications
- Factory methods for object creation

**Collection Standards:**
- Return `IReadOnlyList<T>`, `IReadOnlyDictionary<TKey, TValue>`
- Use `ImmutableArray<T>` for internal storage
- Never expose `List<T>`, `Dictionary<TKey, TValue>` as properties

**Prohibited:**
- Public setters on DTOs
- Mutable collection properties
- Object modification after construction

## Practical Implementation

1. **Record Types for DTOs**:
   ```csharp
   public record CreateOrderRequest(
       string CustomerId,
       IReadOnlyList<OrderItemDto> Items,
       AddressDto ShippingAddress);

   public record OrderItemDto(string ProductId, int Quantity, decimal UnitPrice);
   ```

2. **Domain Models with Init Properties**:
   ```csharp
   public record class Order
   {
       public string Id { get; init; }
       public OrderStatus Status { get; init; }
       public ImmutableArray<OrderItem> Items { get; init; }

       public static Order Create(string customerId, IEnumerable<OrderItem> items) =>
           new() { Id = Guid.NewGuid().ToString(), Items = items.ToImmutableArray() };

       public Order Ship() => this with { Status = OrderStatus.Shipped };
   }
   ```

3. **Value Objects with Record Structs**:
   ```csharp
   public readonly record struct Money(decimal Amount, string Currency)
   {
       public Money Add(Money other) => Currency == other.Currency
           ? this with { Amount = Amount + other.Amount }
           : throw new InvalidOperationException("Currency mismatch");
   }
   ```

4. **Builder Pattern for Complex Objects**:
   ```csharp
   public class OrderBuilder
   {
       private string? _customerId;
       private readonly List<OrderItem> _items = new();

       public OrderBuilder ForCustomer(string customerId) { _customerId = customerId; return this; }
       public OrderBuilder AddItem(OrderItem item) { _items.Add(item); return this; }
       public Order Build() => Order.Create(_customerId!, _items);
   }
   ```

## Examples

```csharp
// ❌ BAD: Mutable DTO with public setters
public class UserDto
{
    public string Id { get; set; }
    public List<string> Roles { get; set; }  // Mutable collection
}

// ✅ GOOD: Immutable record
public record UserDto(string Id, IReadOnlyList<string> Roles);
```

```csharp
// ❌ BAD: In-place mutation
public class ShoppingCart
{
    public List<CartItem> Items { get; } = new();
    public void AddItem(CartItem item) => Items.Add(item);  // Mutation
}

// ✅ GOOD: Immutable operations
public record ShoppingCart(ImmutableList<CartItem> Items)
{
    public ShoppingCart AddItem(CartItem item) => this with { Items = Items.Add(item) };
}
```

## Related Bindings

- [immutable-by-default.md](../core/immutable-by-default.md): This binding directly implements the immutable-by-default tenet using C#'s record types and modern immutability features.

- [defensive-programming.md](../core/defensive-programming.md): Immutability eliminates the need for defensive copying, allowing defensive programming to focus on actual edge cases rather than protecting against mutations.

- [pure-functions.md](../core/pure-functions.md): Immutable types naturally lead to pure functions, as methods can't have side effects on immutable data structures.

- [thread-safety.md](../core/thread-safety.md): Immutable objects are inherently thread-safe, eliminating complex synchronization requirements in concurrent scenarios.

- [domain-modeling.md](../core/domain-modeling.md): Record types and immutability patterns enable rich domain modeling where invalid states are unrepresentable and business rules are enforced through types.
