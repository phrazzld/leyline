---
id: transaction-management-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: modularity
enforced_by: code review & transaction monitoring
---

# Binding: Use Explicit, Well-Bounded Transaction Management

Database transactions must be explicitly scoped with clear boundaries that
align with business operations and maintain ACID compliance. Design transaction
patterns as modular, composable units that can be easily reasoned about,
tested, and maintained without complex interdependencies.

## Rationale

This binding directly implements our modularity tenet by ensuring that database
transactions are treated as well-defined, independent units of work with clear
boundaries and explicit interfaces. Just as modularity creates natural seams
in code architecture, proper transaction management creates natural seams in
data operations, allowing us to reason about each transaction's scope, behavior,
and side effects independently.

Think of transactions like shipping containers in global logistics. Each
container has explicit boundaries (what's inside vs. outside), clear ownership
(who's responsible for its contents), and well-defined operations (load, ship,
unload). When a container fails, it doesn't affect other containers in the
shipment. Similarly, well-bounded transactions encapsulate a logical unit of
work, maintain clear responsibility for data consistency, and provide isolation
so that transaction failures don't cascade to unrelated operations.

The modularity principle becomes especially important in complex applications
where multiple business operations may need to coordinate database changes.
Without explicit transaction boundaries, you end up with tangled, unpredictable
behavior where it's unclear which operations are atomic, how failures propagate,
and what state the system will be in after partial failures. Modular transaction
management creates predictable behavior, enables proper error handling, and
allows different parts of the system to evolve independently while maintaining
data consistency guarantees.

## Rule Definition

Explicit transaction management means treating each transaction as a discrete
module with clear entry and exit points, well-defined error handling, and
explicit dependencies. This requires understanding ACID properties, choosing
appropriate isolation levels, and designing transaction boundaries that align
with business logic rather than technical convenience.

Key principles for modular transaction management:

- **Clear Boundaries**: Transaction scope aligns with business operations, not implementation details
- **Explicit Control**: Transaction lifecycle is explicitly managed, not left to framework defaults
- **Isolation Awareness**: Choose isolation levels based on business requirements and data consistency needs
- **Error Handling**: Handle transaction failures explicitly with appropriate rollback and recovery strategies
- **Composability**: Design transactions that can be safely nested or coordinated when needed

Common patterns this binding requires:

- Scoping transactions to single business operations or consistent units of work
- Explicitly beginning, committing, and rolling back transactions
- Choosing appropriate isolation levels for different operation types
- Implementing proper error handling with transaction cleanup
- Using transaction management patterns like Unit of Work or Command pattern

What this explicitly prohibits:

- Long-running transactions that hold locks unnecessarily
- Implicit transaction management without explicit boundaries
- Mixing transactional and non-transactional operations without clear separation
- Ignoring isolation levels and potential concurrency issues
- Complex nested transactions without proper coordination patterns

## Practical Implementation

1. **Define Clear Transaction Boundaries**: Align transaction scope with business
   operations and logical units of work. Each transaction should represent a
   complete, meaningful operation from the business perspective.

   ```java
   // Java with Spring @Transactional - explicit business boundaries
   @Service
   public class OrderService {

       @Transactional(isolation = Isolation.READ_COMMITTED, timeout = 30)
       public Order createOrder(CreateOrderRequest request) {
           // Single business operation: create order with all its components

           // 1. Validate customer and inventory
           Customer customer = customerService.validateCustomer(request.getCustomerId());
           List<Product> products = productService.validateProducts(request.getProductIds());

           // 2. Reserve inventory (part of the same business transaction)
           inventoryService.reserveItems(request.getItems());

           // 3. Create order and order items atomically
           Order order = new Order(customer, request);
           order = orderRepository.save(order);

           for (OrderItemRequest item : request.getItems()) {
               orderItemRepository.save(new OrderItem(order, item));
           }

           // 4. Publish domain event (still within transaction for consistency)
           eventPublisher.publishEvent(new OrderCreatedEvent(order));

           return order;
           // Transaction commits automatically or rolls back on any exception
       }

       @Transactional(isolation = Isolation.SERIALIZABLE, timeout = 10)
       public void updateOrderStatus(Long orderId, OrderStatus newStatus) {
           // Separate business operation with stricter isolation for status updates
           Order order = orderRepository.findById(orderId)
               .orElseThrow(() -> new OrderNotFoundException(orderId));

           order.updateStatus(newStatus);
           orderRepository.save(order);
       }
   }
   ```

2. **Implement Explicit Transaction Control**: Use explicit transaction management
   patterns that make transaction boundaries visible and testable. Avoid relying
   on framework magic or implicit transaction behavior.

   ```python
   # Python with SQLAlchemy - explicit transaction management
   from contextlib import contextmanager
   from sqlalchemy.exc import SQLAlchemyError
   import logging

   logger = logging.getLogger(__name__)

   class DatabaseTransaction:
       def __init__(self, session):
           self.session = session
           self.is_active = False

       def __enter__(self):
           self.session.begin()
           self.is_active = True
           logger.info("Transaction started")
           return self

       def __exit__(self, exc_type, exc_val, exc_tb):
           if exc_type is not None:
               self.session.rollback()
               self.is_active = False
               logger.error(f"Transaction rolled back due to {exc_type.__name__}: {exc_val}")
               return False
           else:
               try:
                   self.session.commit()
                   self.is_active = False
                   logger.info("Transaction committed successfully")
               except SQLAlchemyError as e:
                   self.session.rollback()
                   self.is_active = False
                   logger.error(f"Transaction commit failed: {e}")
                   raise

   class UserService:
       def __init__(self, db_session):
           self.session = db_session

       def register_user_with_profile(self, user_data, profile_data):
           """Business operation: atomically create user and profile"""
           with DatabaseTransaction(self.session) as tx:
               # Create user
               user = User(
                   email=user_data['email'],
                   username=user_data['username'],
                   password_hash=hash_password(user_data['password'])
               )
               self.session.add(user)
               self.session.flush()  # Get user ID without committing

               # Create profile
               profile = UserProfile(
                   user_id=user.id,
                   full_name=profile_data['full_name'],
                   bio=profile_data.get('bio', '')
               )
               self.session.add(profile)

               # Send welcome email (non-transactional, but still within scope for error handling)
               try:
                   self._send_welcome_email(user.email)
               except EmailError as e:
                   logger.warning(f"Welcome email failed for user {user.id}: {e}")
                   # Don't fail the transaction for email issues

               return user
   ```

3. **Choose Appropriate Isolation Levels**: Select isolation levels based on the
   specific business requirements and concurrency needs of each operation. Make
   isolation level choices explicit and document the reasoning.

   ```typescript
   // TypeScript with TypeORM - explicit isolation levels
   import { DataSource, EntityManager, IsolationLevel } from 'typeorm';

   export class BankingService {
       constructor(private dataSource: DataSource) {}

       async transferFunds(fromAccountId: number, toAccountId: number, amount: number): Promise<void> {
           // High isolation for financial operations to prevent dirty reads
           await this.dataSource.transaction(IsolationLevel.SERIALIZABLE, async (manager: EntityManager) => {
               // 1. Lock accounts in consistent order to prevent deadlocks
               const [fromAccount, toAccount] = await this.lockAccountsInOrder(
                   manager, fromAccountId, toAccountId
               );

               // 2. Validate business rules
               if (fromAccount.balance < amount) {
                   throw new InsufficientFundsError(`Account ${fromAccountId} has insufficient funds`);
               }

               // 3. Perform atomic balance updates
               fromAccount.balance -= amount;
               toAccount.balance += amount;

               await manager.save([fromAccount, toAccount]);

               // 4. Create audit trail
               await manager.save(new Transaction({
                   fromAccountId,
                   toAccountId,
                   amount,
                   type: 'TRANSFER',
                   timestamp: new Date()
               }));
           });
       }

       async generateDailyReport(date: Date): Promise<ReportData> {
           // Lower isolation for reporting - reads don't need strict consistency
           return await this.dataSource.transaction(IsolationLevel.READ_COMMITTED, async (manager) => {
               // Reading data that might be slightly stale is acceptable for reports
               const transactions = await manager.find(Transaction, {
                   where: {
                       createdAt: Between(startOfDay(date), endOfDay(date))
                   }
               });

               return this.processReportData(transactions);
           });
       }

       private async lockAccountsInOrder(manager: EntityManager, id1: number, id2: number) {
           // Always lock accounts in ascending ID order to prevent deadlocks
           const [firstId, secondId] = id1 < id2 ? [id1, id2] : [id2, id1];

           const firstAccount = await manager.findOne(Account, {
               where: { id: firstId },
               lock: { mode: 'pessimistic_write' }
           });
           const secondAccount = await manager.findOne(Account, {
               where: { id: secondId },
               lock: { mode: 'pessimistic_write' }
           });

           if (!firstAccount || !secondAccount) {
               throw new AccountNotFoundError('One or both accounts not found');
           }

           return id1 < id2 ? [firstAccount, secondAccount] : [secondAccount, firstAccount];
       }
   }
   ```

4. **Implement Robust Error Handling and Recovery**: Design transaction patterns
   that handle failures gracefully and provide clear error information. Include
   retry logic where appropriate and ensure resources are properly cleaned up.

   ```go
   // Go with database/sql - explicit error handling and recovery
   package service

   import (
       "context"
       "database/sql"
       "fmt"
       "log"
       "time"
   )

   type OrderService struct {
       db *sql.DB
   }

   type TransactionError struct {
       Operation string
       Cause     error
       Retryable bool
   }

   func (e *TransactionError) Error() string {
       return fmt.Sprintf("transaction failed during %s: %v", e.Operation, e.Cause)
   }

   func (s *OrderService) ProcessPayment(ctx context.Context, orderID int64, paymentAmount float64) error {
       // Implement retry logic for retryable transaction failures
       const maxRetries = 3
       const retryDelay = 100 * time.Millisecond

       for attempt := 1; attempt <= maxRetries; attempt++ {
           err := s.doProcessPayment(ctx, orderID, paymentAmount)
           if err == nil {
               return nil
           }

           // Check if error is retryable
           if txErr, ok := err.(*TransactionError); ok && txErr.Retryable && attempt < maxRetries {
               log.Printf("Transaction attempt %d failed (retryable): %v", attempt, err)
               time.Sleep(retryDelay * time.Duration(attempt)) // Exponential backoff
               continue
           }

           return err
       }

       return fmt.Errorf("transaction failed after %d attempts", maxRetries)
   }

   func (s *OrderService) doProcessPayment(ctx context.Context, orderID int64, paymentAmount float64) error {
       // Start explicit transaction with timeout
       tx, err := s.db.BeginTx(ctx, &sql.TxOptions{
           Isolation: sql.LevelReadCommitted,
       })
       if err != nil {
           return &TransactionError{
               Operation: "begin_transaction",
               Cause:     err,
               Retryable: false,
           }
       }

       // Ensure transaction is always closed
       defer func() {
           if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
               log.Printf("Failed to rollback transaction: %v", err)
           }
       }()

       // 1. Lock order for update
       var orderStatus string
       err = tx.QueryRowContext(ctx,
           "SELECT status FROM orders WHERE id = $1 FOR UPDATE",
           orderID,
       ).Scan(&orderStatus)
       if err == sql.ErrNoRows {
           return &TransactionError{
               Operation: "lock_order",
               Cause:     fmt.Errorf("order %d not found", orderID),
               Retryable: false,
           }
       } else if err != nil {
           return &TransactionError{
               Operation: "lock_order",
               Cause:     err,
               Retryable: true,
           }
       }

       // 2. Validate order state
       if orderStatus != "pending" {
           return &TransactionError{
               Operation: "validate_order_state",
               Cause:     fmt.Errorf("order %d is not in pending state: %s", orderID, orderStatus),
               Retryable: false,
           }
       }

       // 3. Process payment (simulated external call)
       paymentResult, err := s.processExternalPayment(ctx, orderID, paymentAmount)
       if err != nil {
           return &TransactionError{
               Operation: "process_payment",
               Cause:     err,
               Retryable: true, // Payment failures might be temporary
           }
       }

       // 4. Update order with payment information
       _, err = tx.ExecContext(ctx,
           "UPDATE orders SET status = $1, payment_id = $2, updated_at = NOW() WHERE id = $3",
           "paid", paymentResult.PaymentID, orderID,
       )
       if err != nil {
           return &TransactionError{
               Operation: "update_order",
               Cause:     err,
               Retryable: true,
           }
       }

       // 5. Create payment record
       _, err = tx.ExecContext(ctx,
           "INSERT INTO payments (order_id, amount, payment_id, status) VALUES ($1, $2, $3, $4)",
           orderID, paymentAmount, paymentResult.PaymentID, "completed",
       )
       if err != nil {
           return &TransactionError{
               Operation: "create_payment_record",
               Cause:     err,
               Retryable: true,
           }
       }

       // 6. Commit transaction
       if err = tx.Commit(); err != nil {
           return &TransactionError{
               Operation: "commit_transaction",
               Cause:     err,
               Retryable: true,
           }
       }

       log.Printf("Payment processed successfully for order %d", orderID)
       return nil
   }
   ```

5. **Design for Transaction Composition**: Create transaction patterns that can
   be safely composed or coordinated when business operations require multiple
   transactions. Use patterns like Saga or Two-Phase Commit for distributed scenarios.

   ```csharp
   // C# with Entity Framework Core - composable transaction patterns
   public interface IUnitOfWork : IDisposable
   {
       Task<int> SaveChangesAsync();
       Task BeginTransactionAsync();
       Task CommitTransactionAsync();
       Task RollbackTransactionAsync();
   }

   public class OrderFulfillmentOrchestrator
   {
       private readonly IUnitOfWork _unitOfWork;
       private readonly IInventoryService _inventoryService;
       private readonly IShippingService _shippingService;
       private readonly INotificationService _notificationService;

       public async Task<FulfillmentResult> FulfillOrderAsync(long orderId)
       {
           // Saga pattern for coordinating multiple business operations
           var steps = new List<ICompensatableStep>
           {
               new ReserveInventoryStep(_inventoryService),
               new CreateShippingLabelStep(_shippingService),
               new UpdateOrderStatusStep(_unitOfWork),
               new SendConfirmationStep(_notificationService)
           };

           var executedSteps = new Stack<ICompensatableStep>();

           try
           {
               await _unitOfWork.BeginTransactionAsync();

               foreach (var step in steps)
               {
                   await step.ExecuteAsync(orderId);
                   executedSteps.Push(step);
               }

               await _unitOfWork.CommitTransactionAsync();
               return FulfillmentResult.Success(orderId);
           }
           catch (Exception ex)
           {
               await _unitOfWork.RollbackTransactionAsync();

               // Compensate executed steps in reverse order
               while (executedSteps.Count > 0)
               {
                   var step = executedSteps.Pop();
                   try
                   {
                       await step.CompensateAsync(orderId);
                   }
                   catch (Exception compensationEx)
                   {
                       // Log compensation failures but don't re-throw
                       _logger.LogError(compensationEx,
                           "Compensation failed for step {StepType} on order {OrderId}",
                           step.GetType().Name, orderId);
                   }
               }

               return FulfillmentResult.Failure(orderId, ex.Message);
           }
       }
   }

   public interface ICompensatableStep
   {
       Task ExecuteAsync(long orderId);
       Task CompensateAsync(long orderId);
   }

   public class ReserveInventoryStep : ICompensatableStep
   {
       private readonly IInventoryService _inventoryService;

       public async Task ExecuteAsync(long orderId)
       {
           // Each step manages its own transaction boundary
           await _inventoryService.ReserveInventoryForOrderAsync(orderId);
       }

       public async Task CompensateAsync(long orderId)
       {
           await _inventoryService.ReleaseReservationAsync(orderId);
       }
   }
   ```

## Examples

```sql
-- ❌ BAD: Long-running transaction holding locks unnecessarily
BEGIN;
    SELECT * FROM inventory WHERE product_id = 123 FOR UPDATE;
    -- External API call that could take minutes
    -- Other unrelated operations
    UPDATE products SET last_checked = NOW();
    -- More operations mixing different business concerns
COMMIT;

-- ✅ GOOD: Focused transaction with minimal lock time
BEGIN;
    -- Reserve inventory atomically
    UPDATE inventory
    SET reserved_quantity = reserved_quantity + 5,
        updated_at = NOW()
    WHERE product_id = 123
      AND available_quantity >= 5;

    INSERT INTO inventory_reservations (product_id, quantity, order_id)
    VALUES (123, 5, 456);
COMMIT;

-- External operations happen outside transaction
-- Separate transaction for unrelated operations
```

```python
# ❌ BAD: Implicit transaction management with unclear boundaries
def create_user_account(user_data):
    # No explicit transaction boundary
    user = User.objects.create(**user_data)

    # Multiple operations with unclear atomicity
    profile = UserProfile.objects.create(user=user, **profile_data)
    send_welcome_email(user.email)  # External operation mixed in
    log_user_creation(user.id)      # Separate concern

    # Unclear what happens if any step fails
    return user

# ✅ GOOD: Explicit transaction boundaries with clear error handling
@transaction.atomic
def create_user_account(user_data, profile_data):
    """Atomically create user and profile"""
    try:
        user = User.objects.create(**user_data)
        profile = UserProfile.objects.create(user=user, **profile_data)

        # Audit within same transaction for consistency
        UserAuditLog.objects.create(
            user=user,
            action='USER_CREATED',
            timestamp=timezone.now()
        )

        return user
    except IntegrityError as e:
        logger.error(f"User creation failed: {e}")
        raise UserCreationError("Failed to create user account")

def register_user(user_data, profile_data):
    """Complete user registration process"""
    # Transactional data operations
    user = create_user_account(user_data, profile_data)

    # Non-transactional operations after successful commit
    try:
        send_welcome_email(user.email)
    except EmailError as e:
        logger.warning(f"Welcome email failed for user {user.id}: {e}")
        # Don't fail the registration for email issues

    return user
```

```javascript
// ❌ BAD: Nested transactions without proper coordination
async function complexOrderUpdate(orderId, updates) {
    await db.transaction(async (trx1) => {
        const order = await trx1('orders').where('id', orderId).first();

        // Nested transaction that could create deadlocks
        await db.transaction(async (trx2) => {
            await trx2('order_items').where('order_id', orderId).update(updates.items);

            // Another nested transaction
            await db.transaction(async (trx3) => {
                await trx3('inventory').decrement('quantity', updates.quantity);
            });
        });

        await trx1('orders').where('id', orderId).update(updates.order);
    });
}

// ✅ GOOD: Single well-bounded transaction with clear coordination
async function updateOrderWithInventory(orderId, updates) {
    return await db.transaction(async (trx) => {
        // Lock order first to prevent concurrent modifications
        const order = await trx('orders')
            .where('id', orderId)
            .forUpdate()
            .first();

        if (!order) {
            throw new Error(`Order ${orderId} not found`);
        }

        // Validate business rules before any changes
        const currentInventory = await trx('inventory')
            .where('product_id', updates.productId)
            .first();

        if (currentInventory.quantity < updates.quantity) {
            throw new Error('Insufficient inventory');
        }

        // Perform all updates atomically
        await trx('order_items')
            .where('order_id', orderId)
            .update(updates.items);

        await trx('inventory')
            .where('product_id', updates.productId)
            .decrement('quantity', updates.quantity);

        await trx('orders')
            .where('id', orderId)
            .update({
                ...updates.order,
                updated_at: new Date()
            });

        return order;
    });
}
```

## Related Bindings

- [migration-management-strategy](../../docs/bindings/categories/database/migration-management-strategy.md): Transaction
  management patterns complement migration strategies by ensuring that database
  schema changes and data operations both maintain proper transaction boundaries.
  Both patterns work together to ensure data integrity during system evolution.

- [fail-fast-validation](../../core/fail-fast-validation.md): Transaction
  boundaries should include input validation and business rule checking to
  fail fast when preconditions aren't met. This prevents invalid operations
  from beginning transactions and helps maintain system integrity through
  explicit error handling.

- [use-structured-logging](../../core/use-structured-logging.md): Transaction
  operations require structured logging to track transaction lifecycle, monitor
  for deadlocks and contention, and correlate business operations with database
  performance. Both patterns support observability and debugging of complex
  transactional systems.
