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

Modern applications spend most time waiting for I/O operations, yet mixing synchronous and asynchronous patterns leads to thread pool starvation, deadlocks, and poor scalability.

Incorrect async usage compounds quickly: a single synchronous database call blocks threads, reducing concurrent request capacity. Proper async patterns enable thousands of concurrent operations with small thread pools.

## Rule Definition

**Requirements:**

- **Core Patterns**: Use async/await for I/O; ConfigureAwait(false) in libraries; CancellationToken as last parameter
- **API Design**: Async-first APIs; no sync-over-async; async void only for event handlers; Async suffix
- **Performance**: ValueTask for hot paths; IAsyncEnumerable for streaming; avoid capturing context
- **Error Handling**: Await Tasks before catching; handle OperationCanceledException; no fire-and-forget

Prohibits: blocking on async code, async void outside events, sync wrappers over async methods.

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

2. **ValueTask for Hot Paths**:
   ```csharp
   public interface ICache<TKey, TValue> where TKey : notnull
   {
       ValueTask<TValue?> GetAsync(TKey key, CancellationToken cancellationToken = default);
   }

   public ValueTask<TValue?> GetAsync(TKey key, CancellationToken cancellationToken = default)
   {
       return _cache.TryGetValue(key, out var value) ? new(value) : new(default(TValue?));
   }
   ```

3. **IAsyncEnumerable for Streaming**:
   ```csharp
   public async IAsyncEnumerable<Order> GetOrdersAsync(
       DateTime startDate, [EnumeratorCancellation] CancellationToken cancellationToken = default)
   {
       await using var connection = await _connectionFactory.CreateConnectionAsync(cancellationToken).ConfigureAwait(false);
       await using var reader = await connection.ExecuteReaderAsync(sql, new { startDate }, cancellationToken: cancellationToken).ConfigureAwait(false);

       while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
           yield return reader.GetOrder();
   }

   // Usage
   await foreach (var order in GetOrdersAsync(startDate, cancellationToken))
       await ProcessOrderAsync(order, cancellationToken);
   ```

4. **Cancellation Handling**:
   ```csharp
   public async Task<ProcessResult> ProcessDataAsync(DataRequest request, IProgress<int>? progress = null, CancellationToken cancellationToken = default)
   {
       var items = await _repository.GetItemsAsync(request.Filter, cancellationToken).ConfigureAwait(false);
       var results = new List<ProcessedItem>(items.Count);

       for (int i = 0; i < items.Count; i++)
       {
           cancellationToken.ThrowIfCancellationRequested();
           var result = await ProcessItemAsync(items[i], cancellationToken).ConfigureAwait(false);
           results.Add(result);
           progress?.Report((i + 1) * 100 / items.Count);
       }
       return new ProcessResult(results);
   }
   ```

5. **Event Handler Exception Management**:
   ```csharp
   private async void OnButtonClick(object sender, EventArgs e) // Only acceptable async void
   {
       try
       {
           await ProcessUserActionAsync();
       }
       catch (OperationCanceledException) { /* Expected */ }
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
// ❌ BAD: Missing ConfigureAwait, no cancellation, Task allocation
public async Task<string> ReadFileAsync(string path)
{
    return await reader.ReadToEndAsync(); // Captures UI context
}

public async Task<CachedValue?> GetFromCacheAsync(string key)
{
    return await Task.FromResult(value); // Unnecessary allocation
}

// ✅ GOOD: ConfigureAwait, cancellation, ValueTask
public async Task<string> ReadFileAsync(string path, CancellationToken cancellationToken = default)
{
    using var reader = new StreamReader(path);
    return await reader.ReadToEndAsync(cancellationToken).ConfigureAwait(false);
}

public ValueTask<CachedValue?> GetFromCacheAsync(string key)
{
    return _cache.TryGetValue(key, out var value) ? new(value) : new(default(CachedValue?));
}

public async IAsyncEnumerable<Product> GetAllProductsAsync([EnumeratorCancellation] CancellationToken cancellationToken = default)
{
    await foreach (var product in _context.Products.AsAsyncEnumerable().WithCancellation(cancellationToken).ConfigureAwait(false))
        yield return product;
}
```

## Related Bindings

- [io-bound-async.md](../../tenets/io-bound-async.md): Implements I/O-bound async tenet for scalability
- [cancellation-tokens.md](../core/cancellation-tokens.md): Consistent cancellation throughout async call chains
- [memory-efficient-patterns.md](../core/memory-efficient-patterns.md): ValueTask and IAsyncEnumerable reduce allocations
- [api-design-patterns.md](../api/api-design-patterns.md): Async-first API design patterns
- [performance-by-default.md](../core/performance-by-default.md): Async patterns enable efficient resource utilization
