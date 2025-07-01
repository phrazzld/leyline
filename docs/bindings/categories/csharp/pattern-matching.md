---
id: pattern-matching
last_modified: '2025-07-01'
version: '0.1.0'
derived_from: simplicity
enforced_by: 'Code review, .editorconfig style rules'
---

# Binding: Pattern Matching and Switch Expressions

Use pattern matching and switch expressions as the primary control flow mechanism for type checking, value inspection, and conditional logic. Prefer switch expressions over switch statements and if-else chains. Leverage exhaustive pattern matching to eliminate runtime errors and make illegal states unrepresentable.

## Rationale

This binding implements our clarity tenet by leveraging C#'s pattern matching to create more expressive, safer code that clearly communicates intent. Traditional if-else chains and type checking with casting create verbose, error-prone code that obscures the actual business logic behind ceremony.

Consider the cognitive load of traditional type checking: explicit type tests followed by unsafe casts, defensive null checks scattered throughout, and complex boolean conditions that require careful reading to understand. These patterns not only make code harder to read but also create opportunities for runtime errors when cases are missed or assumptions prove false.

Pattern matching transforms conditional logic into declarative expressions. When you use a switch expression with pattern matching, the code reads like a specification: "given this input, produce this output." The compiler ensures exhaustiveness, catching missing cases at compile time rather than runtime. Complex conditions become readable patterns. Type checking and decomposition happen in a single, safe operation. The result is code that clearly expresses its intent while being safer and often more performant.

## Rule Definition

This rule applies to all C# code performing type checking, value inspection, or conditional logic. The rule specifically requires:

**Pattern Matching Standards:**
- Use switch expressions for all multi-branch conditionals
- Apply pattern matching for type testing and casting
- Leverage property patterns for object inspection
- Use relational and logical patterns for ranges and combinations
- Ensure exhaustive matching with discards or explicit defaults

**Control Flow Patterns:**
- Replace if-else chains with switch expressions
- Use pattern matching in LINQ queries
- Apply patterns in exception filtering
- Leverage patterns for validation logic
- Use tuple patterns for multi-value conditions

**Exhaustiveness Requirements:**
- All switch expressions must be exhaustive
- Use discard pattern (`_`) only with justification
- Compiler warnings for non-exhaustive matches as errors
- Document any intentional non-exhaustive patterns

**Code Structure:**
- Single-expression methods using switch expressions
- Pattern variables scoped to their branch
- Consistent pattern style across codebase
- Meaningful pattern variable names

The rule prohibits type checking with `is` followed by casting, long if-else chains for type or value checking, and non-exhaustive switch expressions without explicit justification.

## Practical Implementation

1. **Type Pattern Matching**: Safe type checking and casting:
   ```csharp
   public decimal CalculateDiscount(object discount) => discount switch
   {
       null => throw new ArgumentNullException(nameof(discount)),
       decimal amount => amount,
       int percentage => percentage / 100m,
       string code => GetDiscountForCode(code),
       IDiscountPolicy policy => policy.Calculate(),
       _ => throw new ArgumentException($"Unsupported discount type: {discount.GetType()}")
   };

   // With pattern variables
   public string FormatValue(object value) => value switch
   {
       int n when n < 0 => $"({Math.Abs(n)})",
       int n => n.ToString(),
       decimal d => d.ToString("C"),
       DateTime dt => dt.ToString("yyyy-MM-dd"),
       null => "N/A",
       _ => value.ToString() ?? ""
   };
   ```

2. **Property Pattern Matching**: Declarative object inspection:
   ```csharp
   public string GetShippingMethod(Order order) => order switch
   {
       { TotalAmount: > 100, Customer.IsPremium: true } => "Free Express",
       { TotalAmount: > 100 } => "Free Standard",
       { Customer.IsPremium: true } => "Express",
       { Items.Count: 1, Items: [{ IsFragile: true }] } => "Special Handling",
       _ => "Standard"
   };

   // Nested property patterns
   public decimal CalculateTax(Purchase purchase) => purchase switch
   {
       { Customer: { Address: { State: "CA" } } } => purchase.Amount * 0.0725m,
       { Customer: { Address: { State: "NY" } } } => purchase.Amount * 0.08m,
       { Customer: { Address: { State: "TX" } } } => purchase.Amount * 0.0625m,
       { Customer: { Address: { Country: not "US" } } } => 0m,
       _ => purchase.Amount * 0.05m
   };
   ```

3. **Relational and Logical Patterns**: Expressive range checking:
   ```csharp
   public string GetGeneration(int birthYear) => birthYear switch
   {
       < 1946 => "Silent Generation",
       >= 1946 and <= 1964 => "Baby Boomer",
       >= 1965 and <= 1980 => "Generation X",
       >= 1981 and <= 1996 => "Millennial",
       >= 1997 and <= 2012 => "Generation Z",
       > 2012 => "Generation Alpha",
   };

   public PricingTier GetPricingTier(Customer customer) => customer switch
   {
       { Orders.Count: >= 100, TotalSpend: >= 10000 } => PricingTier.Platinum,
       { Orders.Count: >= 50 or TotalSpend: >= 5000 } => PricingTier.Gold,
       { Orders.Count: >= 10 } => PricingTier.Silver,
       _ => PricingTier.Bronze
   };
   ```

4. **Tuple Pattern Matching**: Multi-value conditions:
   ```csharp
   public string GetGameResult(int playerScore, int opponentScore) =>
       (playerScore, opponentScore) switch
       {
           var (p, o) when p > o => "Win",
           var (p, o) when p < o => "Loss",
           _ => "Draw"
       };

   public State ProcessTransition(State current, Event evt) => (current, evt) switch
   {
       (State.Idle, Event.Start) => State.Running,
       (State.Running, Event.Pause) => State.Paused,
       (State.Paused, Event.Resume) => State.Running,
       (State.Running or State.Paused, Event.Stop) => State.Idle,
       (State.Error, Event.Reset) => State.Idle,
       _ => State.Error  // Invalid transition
   };
   ```

5. **List Pattern Matching**: Collection inspection:
   ```csharp
   public string AnalyzeSequence(int[] numbers) => numbers switch
   {
       [] => "Empty sequence",
       [var single] => $"Single element: {single}",
       [var first, var second] => $"Pair: {first}, {second}",
       [1, 2, 3, ..] => "Starts with 1, 2, 3",
       [.., var last] => $"Ends with {last}",
       _ => $"Sequence of {numbers.Length} elements"
   };

   public bool IsValidCommand(string[] args) => args switch
   {
       ["--help" or "-h"] => true,
       ["--version" or "-v"] => true,
       ["run", _, ..] => true,
       ["test", "--filter", _, ..] => true,
       _ => false
   };
   ```

6. **Pattern Matching in LINQ**: Declarative query filters:
   ```csharp
   // Filter with pattern matching
   var premiumOrders = orders
       .Where(o => o is { Customer.IsPremium: true, TotalAmount: > 1000 })
       .Select(o => new { o.Id, o.TotalAmount });

   // Project with patterns
   var orderSummaries = orders
       .Select(o => o switch
       {
           { Status: OrderStatus.Shipped, ShippedDate: var date } =>
               $"Shipped on {date:yyyy-MM-dd}",
           { Status: OrderStatus.Processing } =>
               "Currently processing",
           { Status: OrderStatus.Cancelled, CancelReason: var reason } =>
               $"Cancelled: {reason}",
           _ => "Unknown status"
       });
   ```

## Examples

```csharp
// ❌ BAD: Traditional if-else with type checking
public double GetArea(Shape shape)
{
    if (shape == null)
        throw new ArgumentNullException(nameof(shape));

    if (shape is Circle)
    {
        var circle = (Circle)shape;  // Unsafe cast
        return Math.PI * circle.Radius * circle.Radius;
    }
    else if (shape is Rectangle)
    {
        var rect = (Rectangle)shape;  // Another unsafe cast
        return rect.Width * rect.Height;
    }
    else if (shape is Triangle)
    {
        var tri = (Triangle)shape;
        return 0.5 * tri.Base * tri.Height;
    }

    throw new NotSupportedException($"Unknown shape type: {shape.GetType()}");
}

// ✅ GOOD: Pattern matching with switch expression
public double GetArea(Shape shape) => shape switch
{
    null => throw new ArgumentNullException(nameof(shape)),
    Circle { Radius: var r } => Math.PI * r * r,
    Rectangle { Width: var w, Height: var h } => w * h,
    Triangle { Base: var b, Height: var h } => 0.5 * b * h,
    _ => throw new NotSupportedException($"Unknown shape type: {shape.GetType()}")
};
```

```csharp
// ❌ BAD: Complex nested conditions
public string GetStatus(Order order)
{
    if (order.IsPaid)
    {
        if (order.IsShipped)
        {
            if (order.DeliveryDate < DateTime.Now)
                return "Delivered";
            else
                return "In Transit";
        }
        else
        {
            if (order.Items.All(i => i.InStock))
                return "Ready to Ship";
            else
                return "Awaiting Stock";
        }
    }
    else
    {
        if (order.PaymentDue < DateTime.Now)
            return "Overdue";
        else
            return "Awaiting Payment";
    }
}

// ✅ GOOD: Clear pattern matching
public string GetStatus(Order order) => order switch
{
    { IsPaid: false, PaymentDue: var due } when due < DateTime.Now => "Overdue",
    { IsPaid: false } => "Awaiting Payment",
    { IsShipped: true, DeliveryDate: var delivery } when delivery < DateTime.Now => "Delivered",
    { IsShipped: true } => "In Transit",
    { Items: var items } when items.All(i => i.InStock) => "Ready to Ship",
    _ => "Awaiting Stock"
};
```

```csharp
// ❌ BAD: Multiple returns with type checking
public object Transform(object input)
{
    if (input is string s)
        return s.ToUpper();

    if (input is int i)
        return i * 2;

    if (input is List<int> list)
        return list.Sum();

    return input;  // Easy to miss cases
}

// ✅ GOOD: Exhaustive pattern matching
public object Transform(object input) => input switch
{
    string s => s.ToUpper(),
    int i => i * 2,
    IEnumerable<int> numbers => numbers.Sum(),
    null => throw new ArgumentNullException(nameof(input)),
    _ => input  // Explicit default case
};
```

## Related Bindings

- [clarity.md](../../tenets/clarity.md): Pattern matching directly implements the clarity tenet by making code intent explicit and reducing conditional complexity.

- [exhaustive-validation.md](../core/exhaustive-validation.md): Exhaustive pattern matching ensures all cases are handled at compile time, preventing runtime errors from missing cases.

- [type-driven-design.md](../core/type-driven-design.md): Pattern matching enables rich type-driven design where the type system guides correct implementation through exhaustive matching.

- [functional-patterns.md](../core/functional-patterns.md): Switch expressions and pattern matching support functional programming patterns, enabling expression-based programming over statement-based.

- [error-handling-patterns.md](../core/error-handling-patterns.md): Pattern matching provides elegant error handling through result types and discriminated unions, making error paths explicit and exhaustive.
