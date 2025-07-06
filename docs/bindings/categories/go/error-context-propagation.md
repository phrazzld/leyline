---
id: error-context-propagation
last_modified: '2025-06-02'
version: '0.1.0'
derived_from: fix-broken-windows
enforced_by: 'Go error handling patterns, code review, static analysis'
---
# Binding: Propagate Error Context Through Go's Error Wrapping Patterns

Use Go's error wrapping mechanisms to preserve context and create clear error chains that enable effective debugging and monitoring. Properly wrapped errors maintain the full context of failure paths while providing actionable information for both developers and operations teams.

## Rationale

This binding implements our fix-broken-windows tenet by preventing error information decay. When errors lose context as they bubble up, debugging becomes exponentially harder.

Go's error wrapping maintains investigative trails. Without proper context, debugging production issues becomes solving mysteries with only outcomes and no clues.

## Rule Definition

**Requirements:**
- Use `fmt.Errorf` with `%w` verb to preserve original errors
- Include relevant identifiers (user IDs, request IDs) without exposing sensitive data
- Use `errors.Is()` and `errors.As()` for type checking through wrap layers
- Define sentinel errors with `errors.New()` for specific conditions
- Create custom error types with structured data (codes, retry info)
- Translate technical errors to user-facing messages

**Patterns:**
- Operation context: `"processing user order: %w"`
- Resource identification: `"failed to update user %s: %w"`
- Correlation IDs for request tracing

## Practical Implementation

1. **Error Wrapping with Context**:
   ```go
   func (s *OrderService) ProcessOrder(ctx context.Context, orderID string) error {
       order, err := s.orderRepo.GetOrder(ctx, orderID)
       if err != nil {
           return fmt.Errorf("failed to retrieve order %s: %w", orderID, err)
       }

       if err := s.processPayment(ctx, order); err != nil {
           return fmt.Errorf("payment failed for order %s amount $%.2f: %w",
                            orderID, order.Amount, err)
       }
       return nil
   }
   ```

2. **Structured Error Types**:
   ```go
   type PaymentError struct {
       Code      string
       Amount    float64
       Retryable bool
       Cause     error
   }

   func (e *PaymentError) Error() string {
       return fmt.Sprintf("payment failed: %s (amount: $%.2f)", e.Code, e.Amount)
   }

   func (e *PaymentError) Unwrap() error { return e.Cause }
   ```

3. **Error Chain Inspection**:
   ```go
   func (s *Service) handleError(err error) error {
       if errors.Is(err, sql.ErrNoRows) {
           return &NotFoundError{Cause: err}
       }

       var paymentErr *PaymentError
       if errors.As(err, &paymentErr) && paymentErr.Retryable {
           return s.scheduleRetry(paymentErr)
       }

       return fmt.Errorf("operation failed: %w", err)
   }
   ```

## Examples

```go
// ❌ BAD: Losing error context
func (s *OrderService) ProcessOrder(orderID string) error {
    _, err := s.repo.GetOrder(orderID)
    if err != nil {
        return err // Lost: which order failed?
    }

    err = s.processPayment(order)
    if err != nil {
        return errors.New("payment failed") // Lost: original error and context
    }
    return nil
}

// ✅ GOOD: Preserving error context
func (s *OrderService) ProcessOrder(ctx context.Context, orderID string) error {
    _, err := s.repo.GetOrder(ctx, orderID)
    if err != nil {
        return fmt.Errorf("failed to retrieve order %s: %w", orderID, err)
    }

    if err := s.processPayment(ctx, order); err != nil {
        return fmt.Errorf("payment failed for order %s: %w", orderID, err)
    }
    return nil
}
```

```go
// ❌ BAD: Generic errors without structure
func ChargeCard(amount float64) error {
    if err := api.Charge(amount); err != nil {
        return errors.New("payment failed") // No retry info or details
    }
    return nil
}

// ✅ GOOD: Structured errors with metadata
func ChargeCard(amount float64) error {
    if err := api.Charge(amount); err != nil {
        return &PaymentError{
            Code: "API_ERROR", Amount: amount, Retryable: true, Cause: err,
        }
    }
    return nil
}
```

## Related Bindings

- [error-wrapping](../../docs/bindings/categories/go/error-wrapping.md): This binding builds on basic error wrapping patterns to create comprehensive error chains with operational context.

- [technical-debt-tracking](../../core/technical-debt-tracking.md): Poor error context is technical debt that compounds over time; proper error handling prevents debugging debt accumulation.

- [use-structured-logging](../../core/use-structured-logging.md): Error contexts provide data for structured logging, while correlation IDs link errors to request traces.

- [fix-broken-windows](../../tenets/fix-broken-windows.md): Properly wrapped errors preserve debugging capability and prevent system decay from poor error handling.
