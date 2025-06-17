---
id: transaction-management-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: modularity
enforced_by: code review & transaction monitoring
---

# Binding: Use Explicit, Well-Bounded Transaction Management

Database transactions must be explicitly scoped with clear boundaries that align with business operations and maintain ACID compliance. Design transactions as modular, composable units that can be easily reasoned about, tested, and maintained.

## Rationale

This binding implements our modularity tenet by treating transactions as well-defined, independent units of work with clear boundaries. Like shipping containers that have explicit boundaries and don't affect other containers when they fail, well-bounded transactions encapsulate logical units of work and provide isolation so failures don't cascade.

Without explicit transaction boundaries, you get tangled, unpredictable behavior where it's unclear which operations are atomic, how failures propagate, and what state the system will be in after partial failures. Modular transaction management creates predictable behavior and enables proper error handling.

## Rule Definition

Transaction management requires these core elements:

- **Clear Boundaries**: Scope transactions to single business operations, not implementation details
- **Explicit Control**: Explicitly begin, commit, and rollback transactions rather than relying on framework defaults
- **Isolation Levels**: Choose appropriate isolation levels based on business requirements and concurrency needs
- **Error Handling**: Handle failures explicitly with proper rollback and recovery strategies
- **Composability**: Design transactions that can be safely coordinated when business operations require multiple transactions

What this prohibits:
- Long-running transactions that hold locks unnecessarily
- Implicit transaction management without explicit boundaries
- Mixing transactional and non-transactional operations without clear separation
- Complex nested transactions without proper coordination patterns

## Practical Implementation

1. **Business-Aligned Transaction Boundaries**: Scope transactions to complete business operations:

   ```typescript
   import { DataSource, EntityManager, IsolationLevel } from 'typeorm';

   export class OrderService {
       constructor(private dataSource: DataSource) {}

       async createOrder(orderRequest: CreateOrderRequest): Promise<Order> {
           return await this.dataSource.transaction(IsolationLevel.READ_COMMITTED, async (manager) => {
               // Single business operation: create order with all components

               // 1. Validate and lock inventory
               const items = await this.validateInventory(manager, orderRequest.items);

               // 2. Create order atomically
               const order = manager.create(Order, {
                   customerId: orderRequest.customerId,
                   items: items,
                   status: 'pending'
               });
               await manager.save(order);

               // 3. Reserve inventory (part of same transaction)
               await this.reserveInventory(manager, orderRequest.items);

               return order;
           });
       }

       async updateOrderStatus(orderId: number, newStatus: OrderStatus): Promise<void> {
           // Separate business operation with appropriate isolation
           await this.dataSource.transaction(IsolationLevel.SERIALIZABLE, async (manager) => {
               const order = await manager.findOne(Order, {
                   where: { id: orderId },
                   lock: { mode: 'pessimistic_write' }
               });

               if (!order) throw new Error('Order not found');

               order.status = newStatus;
               await manager.save(order);
           });
       }
   }
   ```

2. **Explicit Error Handling and Recovery**: Handle transaction failures with proper cleanup:

   ```typescript
   interface TransactionError {
       operation: string;
       cause: Error;
       retryable: boolean;
   }

   export class PaymentService {
       async processPayment(orderId: number, amount: number): Promise<void> {
           const maxRetries = 3;

           for (let attempt = 1; attempt <= maxRetries; attempt++) {
               try {
                   await this.executePaymentTransaction(orderId, amount);
                   return;
               } catch (error) {
                   const txError = this.classifyError(error);

                   if (!txError.retryable || attempt === maxRetries) {
                       throw error;
                   }

                   await this.delay(100 * attempt); // Exponential backoff
               }
           }
       }

       private async executePaymentTransaction(orderId: number, amount: number): Promise<void> {
           await this.dataSource.transaction(async (manager) => {
               // 1. Lock order for update
               const order = await manager.findOne(Order, {
                   where: { id: orderId },
                   lock: { mode: 'pessimistic_write' }
               });

               if (!order || order.status !== 'pending') {
                   throw new Error('Order not eligible for payment');
               }

               // 2. Process payment
               const paymentResult = await this.processExternalPayment(orderId, amount);

               // 3. Update order atomically
               order.status = 'paid';
               order.paymentId = paymentResult.id;
               await manager.save(order);

               // 4. Create payment record
               await manager.save(manager.create(Payment, {
                   orderId,
                   amount,
                   externalId: paymentResult.id,
                   status: 'completed'
               }));
           });
       }
   }
   ```

3. **Transaction Composition for Complex Operations**: Coordinate multiple transactions with Saga pattern:

   ```typescript
   interface CompensatableStep {
       execute(orderId: number): Promise<void>;
       compensate(orderId: number): Promise<void>;
   }

   export class OrderFulfillmentSaga {
       private steps: CompensatableStep[] = [
           new ReserveInventoryStep(),
           new CreateShippingLabelStep(),
           new UpdateOrderStatusStep(),
           new SendConfirmationStep()
       ];

       async fulfillOrder(orderId: number): Promise<FulfillmentResult> {
           const executedSteps: CompensatableStep[] = [];

           try {
               for (const step of this.steps) {
                   await step.execute(orderId);
                   executedSteps.push(step);
               }

               return { success: true, orderId };
           } catch (error) {
               // Compensate in reverse order
               for (const step of executedSteps.reverse()) {
                   try {
                       await step.compensate(orderId);
                   } catch (compensationError) {
                       console.error(`Compensation failed: ${compensationError.message}`);
                   }
               }

               return { success: false, orderId, error: error.message };
           }
       }
   }
   ```

## Examples

```typescript
// ❌ BAD: Long-running transaction with mixed concerns
async function badOrderProcessing(orderId: number) {
    await dataSource.transaction(async (manager) => {
        const order = await manager.findOne(Order, { where: { id: orderId } });

        // External API call holding transaction open
        await this.callExternalService(order);

        // Unrelated operations mixed in
        await manager.update(Product, {}, { lastChecked: new Date() });

        // Business logic mixed with infrastructure concerns
        await this.sendEmail(order.customerEmail);

        await manager.save(order);
    });
}
```

```typescript
// ✅ GOOD: Focused transaction with clear boundaries
async function processOrderPayment(orderId: number, amount: number) {
    // Single business operation with explicit boundaries
    await dataSource.transaction(IsolationLevel.READ_COMMITTED, async (manager) => {
        // Lock order for update
        const order = await manager.findOne(Order, {
            where: { id: orderId },
            lock: { mode: 'pessimistic_write' }
        });

        if (!order || order.status !== 'pending') {
            throw new Error('Order not eligible for payment');
        }

        // Update order status atomically
        order.status = 'paid';
        order.paidAt = new Date();
        await manager.save(order);

        // Create payment record in same transaction
        await manager.save(manager.create(Payment, {
            orderId,
            amount,
            status: 'completed'
        }));
    });

    // External operations after transaction commits
    await this.sendPaymentConfirmation(orderId);
    await this.triggerFulfillment(orderId);
}
```

## Related Bindings

- [migration-management-strategy](../../docs/bindings/categories/database/migration-management-strategy.md): Transaction management patterns complement migration strategies by ensuring both schema changes and data operations maintain proper boundaries.

- [fail-fast-validation](../../core/fail-fast-validation.md): Transaction boundaries should include input validation to fail fast when preconditions aren't met, preventing invalid operations from beginning transactions.
