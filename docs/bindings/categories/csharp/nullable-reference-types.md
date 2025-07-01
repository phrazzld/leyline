---
id: nullable-reference-types
last_modified: '2025-07-01'
version: '0.1.0'
derived_from: explicit-over-implicit
enforced_by: 'Roslyn compiler, .editorconfig, CI validation'
---

# Binding: Enable and Enforce Nullable Reference Types

Enable nullable reference types project-wide with warnings treated as errors. All reference types must explicitly declare nullability intent, and all nullable warnings must be resolved through proper null handling rather than suppressions. New code must be null-safe from inception, while legacy code requires documented migration plans.

## Rationale

This binding implements our strict null checking tenet by leveraging C#'s nullable reference types feature to eliminate entire classes of runtime errors at compile time. NullReferenceException remains one of the most common production failures, yet it's entirely preventable with proper static analysis.

Consider the hidden cost of null reference exceptions: they manifest as runtime crashes often far from their source, require extensive defensive null checking throughout codebases, and create implicit contracts that aren't enforced by the type system. When a method returns a reference type, callers must guess whether null is a valid return value, leading to either excessive null checks or latent bugs.

Nullable reference types transform these runtime failures into compile-time errors. By making nullability explicit in the type system, we create self-documenting APIs where method signatures clearly communicate their contracts. This isn't just about preventing bugs—it's about designing more intentional APIs where the presence or absence of values is a deliberate choice rather than an implicit assumption.

## Rule Definition

This rule applies to all C# code in projects targeting .NET 6.0 or later. The rule specifically requires:

**Project Configuration:**
- Enable nullable reference types at the project level (`<Nullable>enable</Nullable>`)
- Treat all nullable warnings as errors (CS8600-CS8655 range)
- No file-level or line-level nullable disabling without architectural approval
- Configure comprehensive null-checking analyzer rules

**Code Requirements:**
- All reference type declarations must specify nullability intent
- Method parameters, return types, fields, and properties must use appropriate nullable annotations
- Generic type constraints must include nullability specifications
- No null-forgiving operator (`!`) without documented justification

**Migration Standards:**
- New files must have nullable reference types enabled from creation
- Legacy files require incremental migration with `#nullable enable` regions
- Migration progress tracked through warning counts in CI
- Complete migration required before major version updates

The rule prohibits suppressing nullable warnings through `#pragma warning disable`, the null-forgiving operator without justification, or setting `<Nullable>warnings</Nullable>`. Exceptions for interop scenarios must be isolated and documented.

## Practical Implementation

1. **Project-Level Configuration**: Enable nullable reference types globally:
   ```xml
   <Project Sdk="Microsoft.NET.Sdk">
     <PropertyGroup>
       <TargetFramework>net8.0</TargetFramework>
       <Nullable>enable</Nullable>
       <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
       <WarningsAsErrors>CS8600;CS8601;CS8602;CS8603;CS8604;CS8618;CS8625</WarningsAsErrors>
     </PropertyGroup>
   </Project>
   ```

2. **Analyzer Configuration**: Set strict nullability rules in .editorconfig:
   ```ini
   # Nullable reference types
   dotnet_diagnostic.CS8600.severity = error # Converting null literal or possible null value to non-nullable type
   dotnet_diagnostic.CS8601.severity = error # Possible null reference assignment
   dotnet_diagnostic.CS8602.severity = error # Dereference of a possibly null reference
   dotnet_diagnostic.CS8603.severity = error # Possible null reference return
   dotnet_diagnostic.CS8604.severity = error # Possible null reference argument
   dotnet_diagnostic.CS8618.severity = error # Non-nullable property must contain a non-null value
   dotnet_diagnostic.CS8625.severity = error # Cannot convert null literal to non-nullable reference type

   # Additional null-safety analyzers
   dotnet_diagnostic.CA1062.severity = error # Validate arguments of public methods
   dotnet_diagnostic.CA2000.severity = warning # Dispose objects before losing scope
   ```

3. **API Design Patterns**: Design null-safe APIs from the start:
   ```csharp
   public interface IUserRepository
   {
       // Explicitly nullable when user might not exist
       Task<User?> GetByIdAsync(int id, CancellationToken cancellationToken);

       // Non-nullable with exception on not found
       Task<User> GetRequiredByIdAsync(int id, CancellationToken cancellationToken);

       // Non-nullable collection (empty when no results)
       Task<IReadOnlyList<User>> GetActiveUsersAsync(CancellationToken cancellationToken);

       // Required parameters are non-nullable
       Task<User> CreateAsync(string email, string name, CancellationToken cancellationToken);
   }
   ```

4. **Null Handling Patterns**: Use proper null handling instead of suppressions:
   ```csharp
   // Pattern matching for null checks
   if (user is not null)
   {
       ProcessUser(user);
   }

   // Null-coalescing for defaults
   var displayName = user?.Name ?? "Anonymous";

   // Null-coalescing assignment for lazy initialization
   _cache ??= new Dictionary<string, object>();

   // Throw expressions for required values
   _repository = repository ?? throw new ArgumentNullException(nameof(repository));
   ```

5. **Generic Constraints**: Specify nullability in generic constraints:
   ```csharp
   // Constraint allows nullable types
   public interface ICache<TKey, TValue> where TKey : notnull
   {
       TValue? Get(TKey key);
       void Set(TKey key, TValue value);
   }

   // Constraint requires non-nullable
   public interface IValidator<T> where T : class
   {
       ValidationResult Validate(T instance);
   }
   ```

6. **Migration Strategy**: Incrementally enable nullable reference types:
   ```csharp
   #nullable enable

   public class UserService
   {
       private readonly IUserRepository _repository;
       private readonly ILogger<UserService> _logger;

       public UserService(IUserRepository repository, ILogger<UserService> logger)
       {
           _repository = repository ?? throw new ArgumentNullException(nameof(repository));
           _logger = logger ?? throw new ArgumentNullException(nameof(logger));
       }

       public async Task<UserDto?> GetUserAsync(int id)
       {
           var user = await _repository.GetByIdAsync(id, CancellationToken.None);
           return user is not null ? MapToDto(user) : null;
       }
   }

   #nullable restore
   ```

## Examples

```csharp
// ❌ BAD: Implicit nullability with defensive programming
public class UserService
{
    private IUserRepository _repository;  // Is this nullable?

    public User GetUser(string email)
    {
        if (email == null) throw new ArgumentNullException(nameof(email));

        var user = _repository?.FindByEmail(email);  // Defensive null check
        if (user == null) return null;  // Compiler warning: converting null to non-nullable

        return user;
    }
}

// ✅ GOOD: Explicit nullability with clear contracts
public class UserService
{
    private readonly IUserRepository _repository;  // Clearly non-nullable

    public User? GetUser(string email)  // Return type explicitly nullable
    {
        ArgumentNullException.ThrowIfNull(email);
        return _repository.FindByEmail(email);  // No defensive checks needed
    }
}
```

```csharp
// ❌ BAD: Suppressing warnings with null-forgiving operator
public string GetUserName(int userId)
{
    var user = _repository.GetById(userId);
    return user!.Name;  // Dangerous assumption!
}

// ✅ GOOD: Proper null handling
public string GetUserName(int userId)
{
    var user = _repository.GetById(userId);
    return user?.Name ?? throw new InvalidOperationException($"User {userId} not found");
}
```

```csharp
// ❌ BAD: Optional parameters without clear intent
public class EmailService
{
    public void SendEmail(string to, string subject, string body, string cc = null)
    {
        // Is cc actually optional? Can other parameters be null?
    }
}

// ✅ GOOD: Clear nullability intent
public class EmailService
{
    public void SendEmail(string to, string subject, string body, string? cc = null)
    {
        ArgumentNullException.ThrowIfNull(to);
        ArgumentNullException.ThrowIfNull(subject);
        ArgumentNullException.ThrowIfNull(body);
        // cc is explicitly optional
    }
}
```

## Related Bindings

- [strict-null-checking.md](../../tenets/strict-null-checking.md): This binding directly implements the strict null checking tenet, using C#'s nullable reference types as the enforcement mechanism for null safety.

- [immutable-by-default.md](../core/immutable-by-default.md): Nullable reference types complement immutability by making the absence of values explicit. Immutable types with nullable properties create clear contracts about optional data.

- [no-undefined-behavior.md](../core/no-undefined-behavior.md): By eliminating null reference exceptions, we remove a significant source of undefined behavior in C# applications, creating more predictable and reliable systems.

- [defensive-programming.md](../core/defensive-programming.md): Nullable reference types reduce the need for defensive null checks by making nullability explicit in the type system, allowing defensive programming to focus on actual edge cases rather than pervasive null checking.

- [api-type-safety.md](../api/api-type-safety.md): Nullable annotations are a crucial part of type-safe API design, ensuring that API contracts clearly communicate when values may be absent.
