---
id: use-structured-logging
last_modified: "2025-05-04"
derived_from: automation
enforced_by: linters & code review
applies_to:
  - all
  - typescript
  - javascript
  - go
---

# Binding: Write Logs for Machines, Not Just Humans

All operational logging must use structured formats (primarily JSON) that can be automatically parsed, indexed, and analyzed. Unstructured logging via `console.log`, `fmt.Println`, or similar text-based approaches is prohibited in production code. Every log entry must include a standard set of contextual fields that enable correlation and troubleshooting across distributed systems.

## Rationale

This binding directly implements our automation tenet by transforming logs from human-readable text into machine-readable data that can power automated monitoring, alerting, and analysis. When you use structured logging, you're not just recording what happened—you're creating a queryable database of application behavior that enables automated tooling to detect patterns, identify anomalies, and pinpoint the root causes of issues without manual log scanning.

Think of structured logging like postal addresses versus free-form directions. If you mail a letter with an unstructured address ("the blue house past the oak tree, near the river"), it requires human interpretation at every step and may never reach its destination. A properly structured address (street, city, state, zip code) can be automatically sorted and routed through sophisticated systems with minimal human intervention. Similarly, structured logs with consistent fields enable automated systems to process, route, and analyze millions of log entries without human bottlenecks.

The benefits of structured logging become critical as systems scale, particularly in distributed architectures where a single user request might traverse dozens of services. When each service produces consistent, structured logs with correlation identifiers, automated tools can trace the complete journey of a request across the system—something practically impossible with unstructured logs. This traceability changes troubleshooting from an archaeological expedition into a guided investigation, dramatically reducing the mean time to resolution for complex issues and enabling developers to focus on building new features rather than deciphering cryptic log messages.

## Rule Definition

This binding establishes clear requirements for all logging throughout your codebase:

- **Use Machine-Readable Formats**: All logging must output structured data, typically in JSON format:
  - Each log entry must be a complete, parseable JSON object
  - Field names must be consistent across all log entries
  - Values must be properly typed (strings, numbers, booleans, nested objects)
  - No templated strings or interpolated values within message fields
  - No HTML, ANSI color codes, or other formatting in production logs

- **Include Mandatory Context Fields**: Every log entry must contain these standard fields:
  - `timestamp`: ISO 8601 format in UTC (e.g., `2025-05-04T14:22:38.123Z`)
  - `level`: Standardized severity level (`debug`, `info`, `warn`, `error`, `fatal`)
  - `message`: Human-readable description of the event
  - `service`: Name of the application or service generating the log
  - `correlation_id`: Request ID, Trace ID that links related events
  - `component`: Module, class, or function name where the log originated
  - For error logs: `error` object with `type`, `message`, and `stack` fields

- **Avoid Unstructured Logging Methods**: These patterns are explicitly prohibited:
  - Direct use of console methods (`console.log`, `console.error`, etc.)
  - Print statements (`System.out.println`, `fmt.Println`, `print()`, etc.)
  - String concatenation or interpolation without structured context
  - Logging libraries in non-structured modes
  - Rolling your own logging instead of using established libraries

- **Maintain Type Safety**: Log field values must adhere to consistent typing:
  - IDs should be strings even when they appear numeric
  - Timestamps must use consistent ISO 8601 format
  - Durations should use consistent units (usually milliseconds)
  - Boolean flags should be actual booleans, not strings like "true"/"false"

- **Exceptions and Limitations**:
  - Development/debug-only logs may use unstructured formats but should be compiled out of production
  - CLI tools may use unstructured logs for direct human consumption
  - Interactive REPL environments may use console methods
  - Unit test outputs may use simplified logging

## Practical Implementation

Here are concrete strategies for implementing structured logging effectively:

1. **Choose Appropriate Logging Libraries**: Select libraries designed for structured logging in your language:

   - **JavaScript/TypeScript**:
   
     ```typescript
     // Setup with pino
     import pino from 'pino';
     
     const logger = pino({
       messageKey: 'message',
       timestamp: pino.stdTimeFunctions.isoTime,
       base: {
         service: 'user-service',
       },
     });
     
     // Usage with request context
     app.use((req, res, next) => {
       req.log = logger.child({
         correlation_id: req.headers['x-correlation-id'] || generateId(),
         component: 'http-handler'
       });
       next();
     });
     
     // Log with structured context
     req.log.info({ userId, action: 'login' }, 'User authentication successful');
     ```

   - **Go**:
   
     ```go
     // Setup with zerolog
     package main
     
     import (
       "github.com/rs/zerolog"
       "github.com/rs/zerolog/log"
       "os"
       "time"
     )
     
     func main() {
       // Configure global logger
       zerolog.TimeFieldFormat = zerolog.TimeFormatISO8601
       log := zerolog.New(os.Stdout).With().
         Timestamp().
         Str("service", "order-processor").
         Logger()
     
       // Create context-aware logger
       ctx := log.With().
         Str("correlation_id", getCorrelationId()).
         Str("component", "payment-handler").
         Logger()
     
       // Log with structured context
       ctx.Info().
         Str("order_id", "12345").
         Str("payment_provider", "stripe").
         Msg("Payment processed successfully")
     }
     ```

2. **Standardize Log Levels**: Use consistent severity levels across all services:

   ```
   debug: Detailed information useful during development and debugging
   info: Normal operational messages, milestones, and successful operations
   warn: Non-critical issues, degraded service, or potential problems
   error: Failed operations that impact a single request or operation
   fatal: Critical failures that require immediate attention or threaten system operation
   ```

   Configure production environments to log at `info` level or higher, while development environments can use `debug` to capture more detail.

3. **Implement Context Propagation**: Ensure correlation IDs flow through your entire system:

   ```typescript
   // Express middleware example
   function correlationMiddleware(req, res, next) {
     // Use existing ID or generate a new one
     const correlationId = req.headers['x-correlation-id'] || uuid.v4();
     
     // Add to response headers
     res.setHeader('x-correlation-id', correlationId);
     
     // Add to async context for logging
     asyncLocalStorage.run({ correlationId }, () => {
       next();
     });
   }
   
   // Logging middleware that automatically includes correlation_id
   function createLogger() {
     return pino({
       mixin() {
         // Pull from async context
         const context = asyncLocalStorage.getStore() || {};
         return { 
           correlation_id: context.correlationId || 'unknown',
           service: 'api-gateway'
         };
       }
     });
   }
   ```

   This ensures that every log message includes the trace context, even across asynchronous boundaries.

4. **Create Centralized Logging Interface**: Abstract logging details behind a consistent interface:

   ```go
   // logger.go
   package logger
   
   import (
     "context"
     "github.com/rs/zerolog"
     "github.com/rs/zerolog/log"
   )
   
   // Initialize creates a configured logger instance
   func Initialize(service string) {
     zerolog.TimeFieldFormat = zerolog.TimeFormatISO8601
     log.Logger = log.With().
       Timestamp().
       Str("service", service).
       Logger()
   }
   
   // FromContext extracts correlation information from context
   func FromContext(ctx context.Context) zerolog.Logger {
     correlationId := ctx.Value("correlation_id")
     if correlationId == nil {
       correlationId = "unknown"
     }
     
     return log.With().
       Str("correlation_id", correlationId.(string)).
       Logger()
   }
   
   // Usage elsewhere in application
   func ProcessOrder(ctx context.Context, order Order) {
     logger := logger.FromContext(ctx).With().
       Str("component", "order-processor").
       Str("order_id", order.ID).
       Logger()
     
     logger.Info().Msg("Processing order")
     
     // If an error occurs
     if err != nil {
       logger.Error().Err(err).Msg("Failed to process order")
     }
   }
   ```

5. **Configure Proper Log Collection**: Set up centralized log aggregation:

   - Use logging agents (Fluentd, Filebeat, Vector) to collect logs from all services
   - Configure direct transmission to log aggregation systems in containerized environments
   - Establish monitoring and alerting based on log patterns and error rates
   - Create dashboards that visualize log-based metrics
   - Set up log retention and archiving policies based on compliance requirements

## Examples

```typescript
// ❌ BAD: Unstructured logging with variable format
console.log("User", userId, "logged in at", new Date());
console.log(`Processing order ${orderId}`);
console.error("Failed to connect: " + error.message);

// ✅ GOOD: Structured logging with consistent fields
logger.info({
  component: "auth-service",
  correlation_id: requestId,
  user_id: userId,
  action: "login",
  duration_ms: loginTime
}, "User authentication successful");

logger.error({
  component: "order-service",
  correlation_id: requestId,
  order_id: orderId,
  error: {
    type: error.name,
    message: error.message,
    stack: error.stack
  }
}, "Order processing failed");
```

```go
// ❌ BAD: String concatenation and inconsistent format
fmt.Printf("Starting process for user %s\n", userID)
log.Printf("Order status: %s - Items: %d", order.Status, len(order.Items))
fmt.Printf("Error during checkout: %v", err)

// ✅ GOOD: Structured logging with typed fields
logger := log.With().
  Str("correlation_id", ctx.Value("correlation_id").(string)).
  Str("component", "checkout-service").
  Logger()

logger.Info().
  Str("user_id", userID).
  Str("order_id", orderID).
  Int("item_count", len(order.Items)).
  Float64("total_amount", order.Total).
  Msg("Order checkout started")

if err != nil {
  logger.Error().
    Err(err).
    Str("error_code", getErrorCode(err)).
    Msg("Checkout process failed")
}
```

```python
# ❌ BAD: Missing context and unstructured format
print(f"Processing user {user.name}")
logging.info("Payment completed for order %s", order_id)
logging.error("Database error: " + str(err))

# ✅ GOOD: Structured logging with required context
logger = structlog.get_logger().bind(
    correlation_id=context.correlation_id,
    component="payment-processor",
    service="order-api"
)

logger.info("Payment processing started", 
    user_id=user.id,
    order_id=order_id,
    payment_method=payment.type,
    amount=payment.amount
)

try:
    process_payment(payment)
    logger.info("Payment successful",
        order_id=order_id,
        transaction_id=payment.transaction_id,
        duration_ms=timer.elapsed_ms()
    )
except DatabaseError as err:
    logger.error("Payment processing failed",
        order_id=order_id,
        error_type="database_error",
        error_message=str(err)
    )
```

## Related Bindings

- [context-propagation](/bindings/context-propagation.md): Structured logging depends on proper context propagation to maintain correlation IDs and other contextual information across service boundaries. These bindings work together to create end-to-end traceability in distributed systems, with context propagation providing the means to connect logs from different services into a coherent narrative.

- [external-configuration](/bindings/external-configuration.md): Logging configuration (levels, destinations, formats) should be managed through external configuration rather than hardcoded. This allows for environment-specific logging settings and dynamic adjustment of logging verbosity without code changes. Together, these bindings ensure that logging is both well-structured and adaptable to different operational needs.

- [explicit-over-implicit](/bindings/explicit-over-implicit.md): Structured logging is a perfect application of the explicit-over-implicit principle, as it makes the context and meaning of log entries explicit rather than buried in unstructured text. Where traditional logging often relies on implicit context and human pattern recognition, structured logging makes all relevant data explicit, queryable, and machine-processable.