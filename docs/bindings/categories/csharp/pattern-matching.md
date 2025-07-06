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

This binding implements our clarity tenet by leveraging C#'s pattern matching to create more expressive, safer code. Traditional if-else chains and type checking with casting create verbose, error-prone code that obscures business logic.

Pattern matching transforms conditional logic into declarative expressions. The compiler ensures exhaustiveness, catching missing cases at compile time. The result is code that clearly expresses intent while being safer and more performant.

## Rule Definition

**Required Patterns:**
- Use switch expressions for multi-branch conditionals
- Apply pattern matching for type testing and casting
- Leverage property patterns for object inspection
- Ensure exhaustive matching with discards or explicit defaults

**Prohibited:**
- Type checking with `is` followed by casting
- Long if-else chains for type/value checking
- Non-exhaustive switch expressions without justification

## Practical Implementation

1. **Type Pattern Matching**:
   ```csharp
   public decimal CalculateDiscount(object discount) => discount switch
   {
       decimal amount => amount,
       int percentage => percentage / 100m,
       string code => GetDiscountForCode(code),
       _ => throw new ArgumentException("Unsupported discount type")
   };
   ```

2. **Property Pattern Matching**:
   ```csharp
   public string GetShippingMethod(Order order) => order switch
   {
       { TotalAmount: > 100, Customer.IsPremium: true } => "Free Express",
       { TotalAmount: > 100 } => "Free Standard",
       { Customer.IsPremium: true } => "Express",
       _ => "Standard"
   };
   ```

3. **Relational and Tuple Patterns**:
   ```csharp
   public string GetGeneration(int birthYear) => birthYear switch
   {
       < 1946 => "Silent Generation",
       >= 1946 and <= 1964 => "Baby Boomer",
       >= 1965 and <= 1980 => "Generation X",
       _ => "Other"
   };

   public string GetGameResult(int p1, int p2) => (p1, p2) switch
   {
       var (a, b) when a > b => "Win",
       var (a, b) when a < b => "Loss",
       _ => "Draw"
   };
   ```

4. **List and LINQ Patterns**:
   ```csharp
   public string AnalyzeSequence(int[] numbers) => numbers switch
   {
       [] => "Empty",
       [var single] => $"Single: {single}",
       [1, 2, 3, ..] => "Starts with 1, 2, 3",
       _ => "Other"
   };

   var premiumOrders = orders.Where(o => o is { Customer.IsPremium: true, TotalAmount: > 1000 });
   ```

## Examples

```csharp
// ❌ BAD: if-else with unsafe casting
public double GetArea(Shape shape)
{
    if (shape is Circle) {
        var circle = (Circle)shape;  // Unsafe cast
        return Math.PI * circle.Radius * circle.Radius;
    }
    // Missing cases, verbose...
}

// ✅ GOOD: Pattern matching with safe extraction
public double GetArea(Shape shape) => shape switch
{
    Circle { Radius: var r } => Math.PI * r * r,
    Rectangle { Width: var w, Height: var h } => w * h,
    Triangle { Base: var b, Height: var h } => 0.5 * b * h,
    _ => throw new NotSupportedException()
};
```

```csharp
// ❌ BAD: Nested conditionals
public string GetStatus(Order order) {
    if (order.IsPaid) {
        if (order.IsShipped) {
            return order.DeliveryDate < DateTime.Now ? "Delivered" : "In Transit";
        }
        // More nesting...
    }
}

// ✅ GOOD: Property patterns
public string GetStatus(Order order) => order switch
{
    { IsPaid: false, PaymentDue: var due } when due < DateTime.Now => "Overdue",
    { IsShipped: true, DeliveryDate: var d } when d < DateTime.Now => "Delivered",
    { IsShipped: true } => "In Transit",
    _ => "Awaiting Payment"
};
```

## Related Bindings

- [clarity.md](../../tenets/clarity.md): Pattern matching directly implements the clarity tenet by making code intent explicit and reducing conditional complexity.

- [exhaustive-validation.md](../core/exhaustive-validation.md): Exhaustive pattern matching ensures all cases are handled at compile time, preventing runtime errors from missing cases.

- [type-driven-design.md](../core/type-driven-design.md): Pattern matching enables rich type-driven design where the type system guides correct implementation through exhaustive matching.

- [functional-patterns.md](../core/functional-patterns.md): Switch expressions and pattern matching support functional programming patterns, enabling expression-based programming over statement-based.

- [error-handling-patterns.md](../core/error-handling-patterns.md): Pattern matching provides elegant error handling through result types and discriminated unions, making error paths explicit and exhaustive.
