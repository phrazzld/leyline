---
id: csharp-async-patterns
last_modified: '2025-07-01'
version: '0.1.0'
derived_from: simplicity
enforced_by: 'Roslyn analyzers, .editorconfig, Code review'
---

# Binding: Modern Async/Await Patterns

Use async/await patterns correctly throughout C# applications. Always use ConfigureAwait(false) in library code, prefer ValueTask for hot paths, leverage IAsyncEnumerable for streaming data, and avoid async void except in event handlers. Design APIs to be async-first with synchronous wrappers only when absolutely necessary.

## Rationale

This binding implements our I/O-bound async operations tenet by establishing consistent patterns for asynchronous programming in C#. Modern applications spend most of their time waiting for I/O operations—database queries, HTTP calls, file operations—yet many codebases still mix synchronous and asynchronous patterns, leading to thread pool starvation, deadlocks, and poor scalability.

The cost of incorrect async usage compounds quickly: a single synchronous database call in an ASP.NET Core request can block a thread pool thread, reducing the application's ability to handle concurrent requests. Worse, mixing sync and async code often leads to deadlocks in UI applications or sync-over-async antipatterns that negate the benefits of asynchronous programming entirely.

Proper async patterns aren't just about performance—they're about application reliability and scalability. When every I/O operation is properly asynchronous, applications can handle thousands of concurrent operations with a small thread pool. When streaming operations use IAsyncEnumerable, memory usage remains constant regardless of result set size. When hot paths use ValueTask, allocations drop significantly. These improvements enable applications to scale efficiently with load rather than falling over at critical moments.

## Rule Definition

This rule applies to all C# code performing I/O operations or implementing async APIs. The rule specifically requires:

**Core Async Patterns:**
- All I/O operations must use async/await (no blocking calls like `.Result` or `.Wait()`)
- ConfigureAwait(false) required in all library code and non-UI contexts
- ValueTask for frequently-called methods that often complete synchronously
- IAsyncEnumerable for methods returning sequences of items asynchronously
- CancellationToken as the last parameter in all async methods

**API Design Requirements:**
- Public APIs must be async-first (sync methods only for specific scenarios)
- No sync-over-async wrappers (calling `.Result` on async methods)
- Event handlers are the only acceptable use of `async void`
- Async methods must have `Async` suffix (except for interface implementations)

**Performance Patterns:**
- ValueTask for hot paths and methods that often complete synchronously
- IAsyncEnumerable for streaming large result sets
- Avoid capturing async context in hot paths (use static lambdas)
- Consider pooling for extreme performance scenarios

**Error Handling:**
- No catching of Task without awaiting
- Proper exception propagation through async call chains
- Handle OperationCanceledException appropriately
- No fire-and-forget without explicit justification

The rule prohibits blocking on async code, using async void outside event handlers, and creating sync wrappers over async methods. Legacy code requiring sync methods must document migration timelines.

## Practical Implementation

1. **Library Code Configuration**: Always use ConfigureAwait(false):
   ```csharp
   public async Task<User?> GetUserAsync(int id, CancellationToken cancellationToken = default)
   {
       using var connection = await _connectionFactory
           .CreateConnectionAsync(cancellationToken)
           .ConfigureAwait(false);

       var user = await connection
           .QuerySingleOrDefaultAsync<User>(
               "SELECT * FROM Users WHERE Id = @id",
               new { id },
               cancellationToken: cancellationToken)
           .ConfigureAwait(false);

       return user;
   }
   ```

2. **ValueTask for Hot Paths**: Use ValueTask when performance matters:
   ```csharp
   public interface ICache<TKey, TValue> where TKey : notnull
   {
       ValueTask<TValue?> GetAsync(TKey key, CancellationToken cancellationToken = default);
       ValueTask SetAsync(TKey key, TValue value, CancellationToken cancellationToken = default);
   }

   public class MemoryCache<TKey, TValue> : ICache<TKey, TValue> where TKey : notnull
   {
       private readonly ConcurrentDictionary<TKey, TValue> _cache = new();

       public ValueTask<TValue?> GetAsync(TKey key, CancellationToken cancellationToken = default)
       {
           // Often completes synchronously - ValueTask avoids allocation
           return _cache.TryGetValue(key, out var value)
               ? new ValueTask<TValue?>(value)
               : new ValueTask<TValue?>(default(TValue?));
       }
   }
   ```

3. **IAsyncEnumerable for Streaming**: Stream large datasets efficiently:
   ```csharp
   public async IAsyncEnumerable<Order> GetOrdersAsync(
       DateTime startDate,
       [EnumeratorCancellation] CancellationToken cancellationToken = default)
   {
       const string sql = @"
           SELECT * FROM Orders
           WHERE CreatedDate >= @startDate
           ORDER BY CreatedDate";

       await using var connection = await _connectionFactory
           .CreateConnectionAsync(cancellationToken)
           .ConfigureAwait(false);

       await using var reader = await connection
           .ExecuteReaderAsync(sql, new { startDate }, cancellationToken: cancellationToken)
           .ConfigureAwait(false);

       while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
       {
           yield return reader.GetOrder();
       }
   }

   // Consumer can process items as they arrive
   await foreach (var order in GetOrdersAsync(startDate, cancellationToken))
   {
       await ProcessOrderAsync(order, cancellationToken);
   }
   ```

4. **Proper Cancellation Handling**: Support cancellation throughout:
   ```csharp
   public async Task<ProcessResult> ProcessDataAsync(
       DataRequest request,
       IProgress<int>? progress = null,
       CancellationToken cancellationToken = default)
   {
       var items = await _repository
           .GetItemsAsync(request.Filter, cancellationToken)
           .ConfigureAwait(false);

       var processed = 0;
       var results = new List<ProcessedItem>(items.Count);

       foreach (var item in items)
       {
           cancellationToken.ThrowIfCancellationRequested();

           var result = await ProcessItemAsync(item, cancellationToken)
               .ConfigureAwait(false);

           results.Add(result);
           progress?.Report(++processed * 100 / items.Count);
       }

       return new ProcessResult(results);
   }
   ```

5. **Event Handler Exception Management**: Proper async void usage:
   ```csharp
   // Only acceptable use of async void - event handlers
   private async void OnButtonClick(object sender, EventArgs e)
   {
       try
       {
           await ProcessUserActionAsync();
       }
       catch (OperationCanceledException)
       {
           // User cancelled - this is expected
       }
       catch (Exception ex)
       {
           _logger.LogError(ex, "Error processing user action");
           ShowErrorToUser("An error occurred. Please try again.");
       }
   }
   ```

6. **Analyzer Enforcement**: Configure analyzers for async patterns:
   ```ini
   # .editorconfig
   # Async method patterns
   dotnet_diagnostic.CA1849.severity = error  # Call async methods when in async method
   dotnet_diagnostic.CA2007.severity = error  # Consider ConfigureAwait(false)
   dotnet_diagnostic.CA2008.severity = error  # Do not create tasks without TaskScheduler
   dotnet_diagnostic.CA2012.severity = error  # Use ValueTasks correctly
   dotnet_diagnostic.CA2016.severity = error  # Forward CancellationToken

   # Disable CA2007 for test projects (UI context needed)
   [**/*Tests.cs]
   dotnet_diagnostic.CA2007.severity = none
   ```

## Examples

```csharp
// ❌ BAD: Blocking on async code
public User GetUser(int id)
{
    // This can cause deadlocks and thread pool starvation
    return _httpClient.GetAsync($"/users/{id}").Result;
}

// ✅ GOOD: Async all the way
public async Task<User?> GetUserAsync(int id, CancellationToken cancellationToken = default)
{
    var response = await _httpClient
        .GetAsync($"/users/{id}", cancellationToken)
        .ConfigureAwait(false);

    return response.IsSuccessStatusCode
        ? await response.Content.ReadFromJsonAsync<User>(cancellationToken).ConfigureAwait(false)
        : null;
}
```

```csharp
// ❌ BAD: Missing ConfigureAwait in library code
public async Task<string> ReadFileAsync(string path)
{
    using var reader = new StreamReader(path);
    return await reader.ReadToEndAsync();  // May capture UI context
}

// ✅ GOOD: Proper ConfigureAwait usage
public async Task<string> ReadFileAsync(string path, CancellationToken cancellationToken = default)
{
    using var reader = new StreamReader(path);
    return await reader
        .ReadToEndAsync(cancellationToken)
        .ConfigureAwait(false);
}
```

```csharp
// ❌ BAD: Allocating Task for synchronous completion
public async Task<CachedValue?> GetFromCacheAsync(string key)
{
    if (_cache.TryGetValue(key, out var value))
    {
        return await Task.FromResult(value);  // Unnecessary allocation
    }
    return null;
}

// ✅ GOOD: Using ValueTask for hot paths
public ValueTask<CachedValue?> GetFromCacheAsync(string key)
{
    return _cache.TryGetValue(key, out var value)
        ? new ValueTask<CachedValue?>(value)
        : new ValueTask<CachedValue?>(default(CachedValue?));
}
```

```csharp
// ❌ BAD: Loading entire result set into memory
public async Task<List<Product>> GetAllProductsAsync()
{
    return await _context.Products.ToListAsync();  // Loads everything at once
}

// ✅ GOOD: Streaming with IAsyncEnumerable
public async IAsyncEnumerable<Product> GetAllProductsAsync(
    [EnumeratorCancellation] CancellationToken cancellationToken = default)
{
    await foreach (var product in _context.Products
        .AsAsyncEnumerable()
        .WithCancellation(cancellationToken)
        .ConfigureAwait(false))
    {
        yield return product;
    }
}
```

## Related Bindings

- [io-bound-async.md](../../tenets/io-bound-async.md): This binding directly implements the I/O-bound async tenet, ensuring all I/O operations use proper async patterns for maximum scalability.

- [cancellation-tokens.md](../core/cancellation-tokens.md): Proper async patterns require consistent cancellation token usage, enabling cooperative cancellation throughout async call chains.

- [memory-efficient-patterns.md](../core/memory-efficient-patterns.md): ValueTask and IAsyncEnumerable patterns significantly reduce memory allocations in high-performance scenarios.

- [api-design-patterns.md](../api/api-design-patterns.md): Async-first API design ensures that public interfaces support modern async patterns from inception rather than requiring breaking changes later.

- [performance-by-default.md](../core/performance-by-default.md): Correct async patterns are fundamental to application performance, enabling efficient resource utilization and horizontal scalability.
