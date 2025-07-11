---
derived_from: simplicity
enforced_by: code review & race detector
id: concurrency-patterns
last_modified: '2025-05-14'
version: '0.2.0'
---
# Binding: Use Goroutines and Channels Judiciously with Explicit Coordination

Implement Go concurrency using clear patterns that prevent leaks, race conditions, and
deadlocks. Use goroutines only when they genuinely simplify design or improve
performance, pass context for propagating cancellation, use channels with clear
ownership semantics, and apply synchronization primitives correctly when sharing memory.

## Rationale

Uncontrolled concurrency complexity compounds into systems with intermittent, hard-to-reproduce bugs. Each `go` statement creates potential non-determinism.

Disciplined concurrency—context propagation, channel ownership, proper synchronization—creates predictable systems that remain simple while leveraging concurrent execution.

## Rule Definition

**Requirements:**

- **Goroutine Lifecycle**: Clear termination strategy via context cancellation or done channels
- **Context Propagation**: I/O functions accept `context.Context` first parameter, respect cancellation
- **Channel Ownership**: Exactly one goroutine owns and closes each channel; use typed directions
- **Synchronization**: `sync.Mutex` for shared data, `sync.WaitGroup` for coordination, defer unlocks
- **Race Safety**: All code passes `go test -race ./...`

## Practical Implementation

**Key Patterns:**

```go
// Thread-safe cache with proper synchronization
type Cache struct {
    mu      sync.RWMutex
    entries map[string]string
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.entries[key]
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.entries[key] = value
}

// Worker pool with bounded concurrency
func ProcessItems(ctx context.Context, items []string) error {
    sem := make(chan struct{}, 3) // Limit to 3 workers
    var wg sync.WaitGroup

    for _, item := range items {
        select {
        case sem <- struct{}{}: // Acquire semaphore
        case <-ctx.Done():
            return ctx.Err()
        }

        wg.Add(1)
        go func(item string) {
            defer wg.Done()
            defer func() { <-sem }() // Release semaphore
            processItem(ctx, item)
        }(item)
    }

    wg.Wait()
    return nil
}

// Pipeline with channel ownership
func CreatePipeline(ctx context.Context) <-chan string {
    output := make(chan string)
    go func() {
        defer close(output) // Generator owns channel
        for i := 0; i < 10; i++ {
            select {
            case output <- fmt.Sprintf("item_%d", i):
            case <-ctx.Done():
                return
            }
        }
    }()
    return output
}
```

## Examples

```go
// ❌ BAD: Goroutine leak, race condition, unclear ownership
func BadConcurrency() {
    go func() {
        for { doWork() } // No cancellation - goroutine leak
    }()

    counter := 0
    for i := 0; i < 100; i++ {
        go func() { counter++ }() // Race condition
    }

    ch := make(chan int)
    go func() { ch <- 42 }() // Who closes? Potential deadlock
    result := <-ch
}

// ✅ GOOD: Proper lifecycle, synchronization, ownership
func GoodConcurrency(ctx context.Context) error {
    var mu sync.Mutex
    counter := 0

    go func() {
        ticker := time.NewTicker(1 * time.Second)
        defer ticker.Stop()
        for {
            select {
            case <-ctx.Done(): return
            case <-ticker.C:
                mu.Lock()
                counter++
                mu.Unlock()
            }
        }
    }()

    ch := make(chan int, 1)
    go func() {
        defer close(ch) // Clear ownership
        select {
        case ch <- 42:
        case <-ctx.Done():
        }
    }()

    select {
    case result := <-ch:
        fmt.Printf("Result: %d\n", result)
    case <-ctx.Done():
        return ctx.Err()
    }
    return nil
}
```

## Related Bindings

- [error-wrapping](../../docs/bindings/categories/go/error-wrapping.md): Context propagation enables effective debugging across goroutines
- [interface-design](../../docs/bindings/categories/go/interface-design.md): Clear interfaces enable safe concurrent operations
- [pure-functions](../../core/pure-functions.md): Pure functions are inherently thread-safe
- [immutable-by-default](../../core/immutable-by-default.md): Immutable data eliminates concurrency bugs
