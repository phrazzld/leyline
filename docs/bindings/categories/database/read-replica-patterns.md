---
id: read-replica-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: maintainability
enforced_by: architecture review & monitoring
---

# Binding: Design Maintainable Read Replica Patterns

Read replica implementations must prioritize long-term maintainability by using
clear separation patterns, explicit consistency guarantees, and predictable
failover behaviors. Design for operational simplicity and graceful degradation
rather than complex optimization schemes that are difficult to maintain.

## Rationale

This binding directly implements our maintainability tenet by ensuring that read
replica patterns remain comprehensible and manageable as systems scale. Read
replicas are often introduced to solve immediate performance problems, but
without careful design, they can create complex distributed systems that become
operational nightmares. The key is building replica patterns that future
developers can understand, modify, and operate confidently.

Think of read replicas like having multiple copies of a reference book distributed
across different libraries. Each copy helps serve more readers simultaneously,
but you need clear policies about which copy to consult for which purposes,
how to handle situations when a copy is outdated or unavailable, and what to
do when the main book is updated. Without these policies, you end up with
confusion about which information is authoritative and how to handle
inconsistencies between copies.

The challenge with read replicas is that they introduce distributed system
complexity—replication lag, eventual consistency, and failure scenarios—into
previously simple systems. When these complexities are handled through ad-hoc
solutions or overly clever optimization schemes, they create maintenance
burdens that can outweigh the performance benefits. Maintainable replica patterns
establish clear, consistent approaches to these challenges that remain
understandable and modifiable as requirements evolve over time.

## Rule Definition

Maintainable read replica patterns mean designing database scaling solutions
that remain operationally simple and predictable over time. This requires
explicit handling of consistency trade-offs, clear separation of read and write
operations, and straightforward failover strategies that degrade gracefully
under various failure conditions.

Key principles for maintainable read replica patterns:

- **Clear Read/Write Separation**: Explicitly route read and write operations to appropriate instances
- **Explicit Consistency Guarantees**: Make consistency requirements visible in code and architecture
- **Predictable Lag Handling**: Handle replication lag through well-defined patterns, not ad-hoc solutions
- **Simple Failover Logic**: Design failover patterns that are easy to reason about and test
- **Observable Operations**: Make replica health and lag visible through monitoring and alerting

Common patterns this binding requires:

- Repository or service layer patterns that abstract replica routing decisions
- Explicit consistency markers that indicate read-after-write requirements
- Lag-aware caching strategies for non-critical reads
- Circuit breaker patterns for replica failures
- Monitoring and alerting for replica lag and availability

What this explicitly prohibits:

- Complex automatic load balancing that obscures routing decisions
- Implicit consistency assumptions without explicit handling
- Replica patterns that require deep database internals knowledge to maintain
- Silent degradation without visibility into replica status
- Over-optimization that sacrifices operational clarity

## Practical Implementation

1. **Implement Clear Read/Write Routing**: Create explicit patterns for directing
   operations to appropriate database instances. Make routing decisions visible
   and maintainable rather than hidden in complex connection logic.

   ```python
   # Python with explicit read/write separation
   from abc import ABC, abstractmethod
   from enum import Enum
   from typing import Optional, List
   from dataclasses import dataclass
   import logging

   logger = logging.getLogger(__name__)

   class ConsistencyLevel(Enum):
       EVENTUAL = "eventual"      # Can read from replica with potential lag
       READ_AFTER_WRITE = "read_after_write"  # Must read own writes
       STRONG = "strong"          # Must read from primary

   @dataclass
   class ReadOptions:
       consistency: ConsistencyLevel = ConsistencyLevel.EVENTUAL
       max_lag_seconds: Optional[int] = None
       allow_replica_fallback: bool = True

   class DatabaseRouter(ABC):
       """Abstract interface for routing database operations"""

       @abstractmethod
       def get_read_connection(self, options: ReadOptions):
           pass

       @abstractmethod
       def get_write_connection(self):
           pass

   class ReplicaAwareDatabaseRouter(DatabaseRouter):
       """Production router with replica awareness"""

       def __init__(self, primary_pool, replica_pools, lag_monitor):
           self.primary_pool = primary_pool
           self.replica_pools = replica_pools
           self.lag_monitor = lag_monitor

       def get_read_connection(self, options: ReadOptions):
           """Route reads based on explicit consistency requirements"""

           if options.consistency == ConsistencyLevel.STRONG:
               logger.info("Routing to primary for strong consistency")
               return self.primary_pool.get_connection()

           if options.consistency == ConsistencyLevel.READ_AFTER_WRITE:
               # Check if any replica is caught up enough
               for replica_pool in self.replica_pools:
                   lag = self.lag_monitor.get_lag_seconds(replica_pool.name)
                   if lag is not None and lag < 1.0:  # Less than 1 second lag
                       logger.info(f"Routing to replica {replica_pool.name} for read-after-write")
                       return replica_pool.get_connection()

               # Fall back to primary if no replica is caught up
               logger.warning("No replica available for read-after-write, using primary")
               return self.primary_pool.get_connection()

           # Eventual consistency - use best available replica
           return self._get_best_replica_connection(options)

       def _get_best_replica_connection(self, options: ReadOptions):
           """Select best replica based on lag and availability"""
           best_replica = None
           best_lag = float('inf')

           for replica_pool in self.replica_pools:
               if not replica_pool.is_healthy():
                   continue

               lag = self.lag_monitor.get_lag_seconds(replica_pool.name)
               if lag is None:
                   continue  # Skip replicas with unknown lag

               # Check if lag meets requirements
               if options.max_lag_seconds and lag > options.max_lag_seconds:
                   continue

               if lag < best_lag:
                   best_lag = lag
                   best_replica = replica_pool

           if best_replica:
               logger.info(f"Routing to replica {best_replica.name} with {best_lag}s lag")
               return best_replica.get_connection()

           # No suitable replica found
           if options.allow_replica_fallback:
               logger.warning("No suitable replica found, falling back to primary")
               return self.primary_pool.get_connection()
           else:
               raise ReplicaUnavailableError("No replica meets consistency requirements")

       def get_write_connection(self):
           """All writes go to primary"""
           return self.primary_pool.get_connection()

   class UserService:
       """Service layer with explicit consistency requirements"""

       def __init__(self, db_router: DatabaseRouter):
           self.db_router = db_router

       def create_user(self, user_data) -> User:
           """Write operation - always use primary"""
           with self.db_router.get_write_connection() as conn:
               user = User.create(conn, user_data)
               logger.info(f"Created user {user.id}")
               return user

       def get_user_profile(self, user_id: int,
                           read_own_updates: bool = False) -> Optional[User]:
           """Read operation with explicit consistency choice"""

           consistency = (ConsistencyLevel.READ_AFTER_WRITE
                         if read_own_updates
                         else ConsistencyLevel.EVENTUAL)

           options = ReadOptions(consistency=consistency)

           with self.db_router.get_read_connection(options) as conn:
               return User.find_by_id(conn, user_id)

       def search_users(self, query: str, max_lag_seconds: int = 30) -> List[User]:
           """Search operation - can tolerate some lag"""
           options = ReadOptions(
               consistency=ConsistencyLevel.EVENTUAL,
               max_lag_seconds=max_lag_seconds
           )

           with self.db_router.get_read_connection(options) as conn:
               return User.search(conn, query)
   ```

2. **Handle Replication Lag with Explicit Patterns**: Create predictable ways
   to handle replication lag that don't surprise developers or users. Make lag
   tolerance explicit rather than hidden in complex caching logic.

   ```java
   // Java with explicit lag handling and fallback patterns
   @Service
   public class OrderService {

       private final DatabaseRouter databaseRouter;
       private final ReplicationLagMonitor lagMonitor;
       private final MetricRegistry metrics;

       public OrderService(DatabaseRouter databaseRouter,
                          ReplicationLagMonitor lagMonitor,
                          MetricRegistry metrics) {
           this.databaseRouter = databaseRouter;
           this.lagMonitor = lagMonitor;
           this.metrics = metrics;
       }

       @Transactional
       public Order createOrder(CreateOrderRequest request) {
           // Writes always go to primary
           try (var connection = databaseRouter.getPrimaryConnection()) {
               Order order = new Order(request);
               orderRepository.save(connection, order);

               // Track the write timestamp for read-after-write scenarios
               lagMonitor.recordWrite(order.getId(), Instant.now());

               return order;
           }
       }

       public Optional<Order> getOrder(Long orderId, boolean readOwnWrites) {
           ReadStrategy strategy = determineReadStrategy(orderId, readOwnWrites);

           return executeWithFallback(
               () -> readOrderWithStrategy(orderId, strategy),
               () -> readOrderFromPrimary(orderId),
               "order_read"
           );
       }

       public List<Order> getRecentOrders(int limit, Duration maxAge) {
           // Recent orders can tolerate some lag, but not too much
           ReadOptions options = ReadOptions.builder()
               .consistencyLevel(ConsistencyLevel.EVENTUAL)
               .maxLagDuration(Duration.ofSeconds(10))
               .allowStaleReads(false)
               .build();

           return executeWithFallback(
               () -> readRecentOrdersFromReplica(limit, maxAge, options),
               () -> readRecentOrdersFromPrimary(limit, maxAge),
               "recent_orders_read"
           );
       }

       private ReadStrategy determineReadStrategy(Long orderId, boolean readOwnWrites) {
           if (readOwnWrites) {
               // Check if this order was recently written
               Optional<Instant> writeTime = lagMonitor.getWriteTime(orderId);
               if (writeTime.isPresent()) {
                   Duration timeSinceWrite = Duration.between(writeTime.get(), Instant.now());
                   if (timeSinceWrite.compareTo(Duration.ofSeconds(5)) < 0) {
                       // Recent write - need strong consistency
                       return ReadStrategy.PRIMARY_ONLY;
                   }
               }
               return ReadStrategy.READ_AFTER_WRITE;
           }

           return ReadStrategy.EVENTUAL_CONSISTENCY;
       }

       private <T> T executeWithFallback(Supplier<T> primaryAction,
                                        Supplier<T> fallbackAction,
                                        String operationName) {
           Timer.Context timer = metrics.timer(operationName + "_total").time();
           try {
               return primaryAction.get();
           } catch (ReplicaLagException | ReplicaUnavailableException e) {
               metrics.counter(operationName + "_fallback").inc();
               log.warn("Falling back to primary for {} due to: {}", operationName, e.getMessage());
               return fallbackAction.get();
           } finally {
               timer.stop();
           }
       }

       private Optional<Order> readOrderWithStrategy(Long orderId, ReadStrategy strategy) {
           ReadOptions options = ReadOptions.forStrategy(strategy);

           try (var connection = databaseRouter.getReadConnection(options)) {
               return orderRepository.findById(connection, orderId);
           }
       }

       private Optional<Order> readOrderFromPrimary(Long orderId) {
           try (var connection = databaseRouter.getPrimaryConnection()) {
               return orderRepository.findById(connection, orderId);
           }
       }
   }

   // Configuration class for explicit replica behavior
   @Configuration
   public class ReplicaConfiguration {

       @Bean
       public DatabaseRouter databaseRouter(@Value("${app.database.replica.max-lag-seconds:30}") int maxLagSeconds,
                                           @Value("${app.database.replica.health-check-interval:10}") int healthCheckInterval) {

           var config = ReplicaConfig.builder()
               .maxAcceptableLag(Duration.ofSeconds(maxLagSeconds))
               .healthCheckInterval(Duration.ofSeconds(healthCheckInterval))
               .circuitBreakerThreshold(5)  // Failed health checks before marking unhealthy
               .circuitBreakerTimeout(Duration.ofMinutes(2))  // Time before retry
               .build();

           return new ProductionDatabaseRouter(config);
       }

       @Bean
       public ReplicationLagMonitor lagMonitor() {
           return new ReplicationLagMonitor(
               Duration.ofSeconds(1),   // Check lag every second
               Duration.ofMinutes(5)    // Keep write timestamps for 5 minutes
           );
       }
   }
   ```

3. **Implement Circuit Breaker Patterns for Replica Failures**: Design failover
   logic that fails fast and recovers gracefully, making system behavior
   predictable during replica outages.

   ```typescript
   // TypeScript with circuit breaker and graceful degradation
   import { EventEmitter } from 'events';

   enum CircuitState {
     CLOSED = 'closed',     // Normal operation
     OPEN = 'open',         // Failing fast
     HALF_OPEN = 'half_open' // Testing recovery
   }

   interface ReplicaHealth {
     isHealthy: boolean;
     lastCheck: Date;
     consecutiveFailures: number;
     averageResponseTime: number;
     replicationLag: number | null;
   }

   class ReplicaCircuitBreaker extends EventEmitter {
     private state: CircuitState = CircuitState.CLOSED;
     private failureCount = 0;
     private lastFailureTime?: Date;
     private nextAttemptTime?: Date;

     constructor(
       private readonly replicaName: string,
       private readonly failureThreshold: number = 5,
       private readonly timeout: number = 60000, // 1 minute
       private readonly halfOpenMaxCalls: number = 3
     ) {
       super();
     }

     async execute<T>(operation: () => Promise<T>): Promise<T> {
       if (this.state === CircuitState.OPEN) {
         if (this.shouldAttemptReset()) {
           this.state = CircuitState.HALF_OPEN;
           this.emit('state_change', { replica: this.replicaName, state: this.state });
         } else {
           throw new CircuitBreakerOpenError(`Circuit breaker open for replica ${this.replicaName}`);
         }
       }

       try {
         const result = await operation();
         this.onSuccess();
         return result;
       } catch (error) {
         this.onFailure(error);
         throw error;
       }
     }

     private onSuccess(): void {
       this.failureCount = 0;
       this.lastFailureTime = undefined;

       if (this.state === CircuitState.HALF_OPEN) {
         this.state = CircuitState.CLOSED;
         this.emit('state_change', { replica: this.replicaName, state: this.state });
         this.emit('recovery', { replica: this.replicaName });
       }
     }

     private onFailure(error: Error): void {
       this.failureCount++;
       this.lastFailureTime = new Date();

       if (this.failureCount >= this.failureThreshold) {
         this.state = CircuitState.OPEN;
         this.nextAttemptTime = new Date(Date.now() + this.timeout);
         this.emit('state_change', { replica: this.replicaName, state: this.state });
         this.emit('circuit_opened', { replica: this.replicaName, error: error.message });
       }
     }

     private shouldAttemptReset(): boolean {
       return this.nextAttemptTime ? new Date() >= this.nextAttemptTime : false;
     }

     getState(): CircuitState {
       return this.state;
     }
   }

   class ReplicaManager {
     private circuitBreakers = new Map<string, ReplicaCircuitBreaker>();
     private replicaHealth = new Map<string, ReplicaHealth>();
     private healthCheckInterval: NodeJS.Timeout;

     constructor(
       private readonly replicas: DatabaseReplica[],
       private readonly lagMonitor: ReplicationLagMonitor,
       private readonly logger: Logger
     ) {
       this.initializeCircuitBreakers();
       this.startHealthChecking();
     }

     async getHealthyReplica(options: ReadOptions): Promise<DatabaseReplica | null> {
       const eligibleReplicas = this.replicas.filter(replica => {
         const breaker = this.circuitBreakers.get(replica.name);
         const health = this.replicaHealth.get(replica.name);

         // Skip replicas with open circuit breakers
         if (breaker?.getState() === CircuitState.OPEN) {
           return false;
         }

         // Skip unhealthy replicas
         if (!health?.isHealthy) {
           return false;
         }

         // Check lag requirements
         if (options.maxLagSeconds && health.replicationLag) {
           if (health.replicationLag > options.maxLagSeconds) {
             return false;
           }
         }

         return true;
       });

       if (eligibleReplicas.length === 0) {
         return null;
       }

       // Choose replica with lowest lag
       return eligibleReplicas.reduce((best, current) => {
         const bestHealth = this.replicaHealth.get(best.name)!;
         const currentHealth = this.replicaHealth.get(current.name)!;

         const bestLag = bestHealth.replicationLag ?? Infinity;
         const currentLag = currentHealth.replicationLag ?? Infinity;

         return currentLag < bestLag ? current : best;
       });
     }

     async executeQuery<T>(
       query: string,
       params: any[],
       options: ReadOptions
     ): Promise<T> {
       const replica = await this.getHealthyReplica(options);

       if (!replica) {
         if (options.allowPrimaryFallback) {
           this.logger.warn('No healthy replica available, falling back to primary');
           throw new NoReplicaAvailableError('Fallback to primary required');
         } else {
           throw new NoReplicaAvailableError('No replica meets requirements');
         }
       }

       const breaker = this.circuitBreakers.get(replica.name)!;

       return breaker.execute(async () => {
         const startTime = Date.now();
         try {
           const result = await replica.query<T>(query, params);

           // Update health metrics
           const duration = Date.now() - startTime;
           this.updateResponseTime(replica.name, duration);

           return result;
         } catch (error) {
           this.logger.error(`Query failed on replica ${replica.name}:`, error);
           throw error;
         }
       });
     }

     private initializeCircuitBreakers(): void {
       this.replicas.forEach(replica => {
         const breaker = new ReplicaCircuitBreaker(replica.name);

         breaker.on('circuit_opened', (event) => {
           this.logger.error(`Circuit breaker opened for replica ${event.replica}: ${event.error}`);
         });

         breaker.on('recovery', (event) => {
           this.logger.info(`Replica ${event.replica} recovered`);
         });

         this.circuitBreakers.set(replica.name, breaker);
       });
     }

     private startHealthChecking(): void {
       this.healthCheckInterval = setInterval(async () => {
         await this.checkAllReplicaHealth();
       }, 10000); // Check every 10 seconds
     }

     private async checkAllReplicaHealth(): Promise<void> {
       const healthChecks = this.replicas.map(replica =>
         this.checkReplicaHealth(replica)
       );

       await Promise.allSettled(healthChecks);
     }

     private async checkReplicaHealth(replica: DatabaseReplica): Promise<void> {
       try {
         const startTime = Date.now();
         await replica.healthCheck();
         const responseTime = Date.now() - startTime;

         const lag = await this.lagMonitor.getLag(replica.name);

         const health: ReplicaHealth = {
           isHealthy: true,
           lastCheck: new Date(),
           consecutiveFailures: 0,
           averageResponseTime: responseTime,
           replicationLag: lag
         };

         this.replicaHealth.set(replica.name, health);

       } catch (error) {
         const currentHealth = this.replicaHealth.get(replica.name);
         const health: ReplicaHealth = {
           isHealthy: false,
           lastCheck: new Date(),
           consecutiveFailures: (currentHealth?.consecutiveFailures ?? 0) + 1,
           averageResponseTime: currentHealth?.averageResponseTime ?? 0,
           replicationLag: null
         };

         this.replicaHealth.set(replica.name, health);
         this.logger.warn(`Health check failed for replica ${replica.name}:`, error);
       }
     }

     getReplicaStatus(): Map<string, ReplicaHealth> {
       return new Map(this.replicaHealth);
     }
   }
   ```

4. **Implement Observable Replica Operations**: Make replica health, routing
   decisions, and lag metrics visible through structured logging and monitoring.
   This enables operational teams to maintain the system effectively.

   ```go
   // Go with comprehensive observability for replica operations
   package database

   import (
       "context"
       "database/sql"
       "fmt"
       "log/slog"
       "time"

       "github.com/prometheus/client_golang/prometheus"
       "github.com/prometheus/client_golang/prometheus/promauto"
   )

   var (
       replicaLagGauge = promauto.NewGaugeVec(
           prometheus.GaugeOpts{
               Name: "database_replica_lag_seconds",
               Help: "Current replication lag in seconds",
           },
           []string{"replica_name"},
       )

       queryDurationHistogram = promauto.NewHistogramVec(
           prometheus.HistogramOpts{
               Name:    "database_query_duration_seconds",
               Help:    "Database query duration in seconds",
               Buckets: prometheus.DefBuckets,
           },
           []string{"operation", "database_type", "replica_name"},
       )

       replicaHealthGauge = promauto.NewGaugeVec(
           prometheus.GaugeOpts{
               Name: "database_replica_healthy",
               Help: "Whether replica is healthy (1) or not (0)",
           },
           []string{"replica_name"},
       )

       routingDecisionCounter = promauto.NewCounterVec(
           prometheus.CounterOpts{
               Name: "database_routing_decisions_total",
               Help: "Total number of routing decisions by type",
           },
           []string{"decision_type", "consistency_level"},
       )
   )

   type ReplicaRouter struct {
       primary    *sql.DB
       replicas   map[string]*sql.DB
       lagMonitor *LagMonitor
       logger     *slog.Logger
   }

   type QueryContext struct {
       OperationType   string
       ConsistencyLevel string
       MaxLagSeconds   *int
       UserID          string  // For tracing user-specific operations
       RequestID       string  // For request correlation
   }

   func (r *ReplicaRouter) ExecuteQuery(ctx context.Context, queryCtx QueryContext,
                                       query string, args ...interface{}) (*sql.Rows, error) {
       start := time.Now()

       // Determine routing decision
       target, reason, err := r.determineQueryTarget(ctx, queryCtx)
       if err != nil {
           return nil, fmt.Errorf("routing decision failed: %w", err)
       }

       // Log routing decision with full context
       r.logger.Info("Query routing decision",
           slog.String("request_id", queryCtx.RequestID),
           slog.String("user_id", queryCtx.UserID),
           slog.String("operation", queryCtx.OperationType),
           slog.String("consistency_level", queryCtx.ConsistencyLevel),
           slog.String("target", target.name),
           slog.String("reason", reason),
           slog.String("query", query),
       )

       // Record routing decision metrics
       routingDecisionCounter.WithLabelValues(target.targetType, queryCtx.ConsistencyLevel).Inc()

       // Execute query with observability
       rows, err := r.executeWithMetrics(ctx, target, queryCtx, query, args...)

       duration := time.Since(start)

       // Log query completion
       if err != nil {
           r.logger.Error("Query execution failed",
               slog.String("request_id", queryCtx.RequestID),
               slog.String("target", target.name),
               slog.Duration("duration", duration),
               slog.String("error", err.Error()),
           )
       } else {
           r.logger.Debug("Query execution completed",
               slog.String("request_id", queryCtx.RequestID),
               slog.String("target", target.name),
               slog.Duration("duration", duration),
           )
       }

       return rows, err
   }

   type QueryTarget struct {
       db         *sql.DB
       name       string
       targetType string  // "primary" or "replica"
       lagSeconds float64
   }

   func (r *ReplicaRouter) determineQueryTarget(ctx context.Context, queryCtx QueryContext) (*QueryTarget, string, error) {
       switch queryCtx.ConsistencyLevel {
       case "strong":
           return &QueryTarget{
               db:         r.primary,
               name:       "primary",
               targetType: "primary",
               lagSeconds: 0,
           }, "strong_consistency_required", nil

       case "read_after_write":
           return r.findReadAfterWriteTarget(ctx, queryCtx)

       case "eventual":
           return r.findEventualConsistencyTarget(ctx, queryCtx)

       default:
           return nil, "", fmt.Errorf("unknown consistency level: %s", queryCtx.ConsistencyLevel)
       }
   }

   func (r *ReplicaRouter) findReadAfterWriteTarget(ctx context.Context, queryCtx QueryContext) (*QueryTarget, string, error) {
       // Check for suitable replica with low lag
       for name, db := range r.replicas {
           lag, healthy := r.lagMonitor.GetReplicaStatus(name)
           if !healthy {
               continue
           }

           // For read-after-write, we need very low lag (< 1 second)
           if lag < 1.0 {
               return &QueryTarget{
                   db:         db,
                   name:       name,
                   targetType: "replica",
                   lagSeconds: lag,
               }, fmt.Sprintf("replica_suitable_for_read_after_write_lag_%.2fs", lag), nil
           }
       }

       // Fall back to primary if no suitable replica
       return &QueryTarget{
           db:         r.primary,
           name:       "primary",
           targetType: "primary",
           lagSeconds: 0,
       }, "no_replica_suitable_for_read_after_write", nil
   }

   func (r *ReplicaRouter) findEventualConsistencyTarget(ctx context.Context, queryCtx QueryContext) (*QueryTarget, string, error) {
       var bestTarget *QueryTarget
       var bestReason string

       maxLag := float64(30) // Default 30 seconds
       if queryCtx.MaxLagSeconds != nil {
           maxLag = float64(*queryCtx.MaxLagSeconds)
       }

       // Find best replica within lag tolerance
       for name, db := range r.replicas {
           lag, healthy := r.lagMonitor.GetReplicaStatus(name)
           if !healthy {
               r.logger.Debug("Skipping unhealthy replica",
                   slog.String("replica_name", name),
                   slog.String("request_id", queryCtx.RequestID),
               )
               continue
           }

           if lag > maxLag {
               r.logger.Debug("Skipping replica due to high lag",
                   slog.String("replica_name", name),
                   slog.Float64("lag_seconds", lag),
                   slog.Float64("max_lag_seconds", maxLag),
                   slog.String("request_id", queryCtx.RequestID),
               )
               continue
           }

           if bestTarget == nil || lag < bestTarget.lagSeconds {
               bestTarget = &QueryTarget{
                   db:         db,
                   name:       name,
                   targetType: "replica",
                   lagSeconds: lag,
               }
               bestReason = fmt.Sprintf("best_replica_lag_%.2fs", lag)
           }
       }

       if bestTarget != nil {
           return bestTarget, bestReason, nil
       }

       // No suitable replica, fall back to primary
       return &QueryTarget{
           db:         r.primary,
           name:       "primary",
           targetType: "primary",
           lagSeconds: 0,
       }, "no_replica_within_lag_tolerance", nil
   }

   func (r *ReplicaRouter) executeWithMetrics(ctx context.Context, target *QueryTarget,
                                            queryCtx QueryContext, query string,
                                            args ...interface{}) (*sql.Rows, error) {
       timer := prometheus.NewTimer(queryDurationHistogram.WithLabelValues(
           queryCtx.OperationType,
           target.targetType,
           target.name,
       ))
       defer timer.ObserveDuration()

       rows, err := target.db.QueryContext(ctx, query, args...)

       // Update replica health metrics
       if target.targetType == "replica" {
           if err != nil {
               replicaHealthGauge.WithLabelValues(target.name).Set(0)
           } else {
               replicaHealthGauge.WithLabelValues(target.name).Set(1)
               replicaLagGauge.WithLabelValues(target.name).Set(target.lagSeconds)
           }
       }

       return rows, err
   }

   // LagMonitor tracks replication lag for all replicas
   type LagMonitor struct {
       replicas map[string]*ReplicaStatus
       logger   *slog.Logger
   }

   type ReplicaStatus struct {
       LagSeconds    float64
       LastUpdate    time.Time
       IsHealthy     bool
       ErrorCount    int
   }

   func (lm *LagMonitor) StartMonitoring(ctx context.Context, interval time.Duration) {
       ticker := time.NewTicker(interval)
       defer ticker.Stop()

       for {
           select {
           case <-ctx.Done():
               return
           case <-ticker.C:
               lm.updateAllReplicaLag(ctx)
           }
       }
   }

   func (lm *LagMonitor) updateAllReplicaLag(ctx context.Context) {
       for replicaName := range lm.replicas {
           lag, err := lm.measureLag(ctx, replicaName)
           if err != nil {
               lm.logger.Error("Failed to measure replica lag",
                   slog.String("replica_name", replicaName),
                   slog.String("error", err.Error()),
               )

               status := lm.replicas[replicaName]
               status.ErrorCount++
               status.IsHealthy = status.ErrorCount < 3 // Unhealthy after 3 consecutive errors
               continue
           }

           status := lm.replicas[replicaName]
           status.LagSeconds = lag
           status.LastUpdate = time.Now()
           status.IsHealthy = true
           status.ErrorCount = 0

           // Update Prometheus metrics
           replicaLagGauge.WithLabelValues(replicaName).Set(lag)
           replicaHealthGauge.WithLabelValues(replicaName).Set(1)

           lm.logger.Debug("Updated replica lag",
               slog.String("replica_name", replicaName),
               slog.Float64("lag_seconds", lag),
           )
       }
   }
   ```

5. **Design for Configuration-Driven Behavior**: Make replica patterns
   configurable rather than hardcoded, enabling different environments and
   use cases to be maintained with the same codebase.

   ```csharp
   // C# with comprehensive configuration and policy patterns
   public class ReplicaConfiguration
   {
       public Dictionary<string, ReplicaSettings> Replicas { get; set; } = new();
       public RoutingPolicies Routing { get; set; } = new();
       public MonitoringSettings Monitoring { get; set; } = new();
   }

   public class ReplicaSettings
   {
       public string ConnectionString { get; set; }
       public int MaxLagSeconds { get; set; } = 30;
       public int HealthCheckIntervalSeconds { get; set; } = 10;
       public int CircuitBreakerThreshold { get; set; } = 5;
       public int CircuitBreakerTimeoutSeconds { get; set; } = 60;
       public int Weight { get; set; } = 1; // For load balancing
       public bool IsReadOnly { get; set; } = true;
   }

   public class RoutingPolicies
   {
       public bool AllowPrimaryFallback { get; set; } = true;
       public int ReadAfterWriteMaxLagSeconds { get; set; } = 1;
       public int DefaultMaxLagSeconds { get; set; } = 30;
       public bool EnableStickySessions { get; set; } = false;
       public string LoadBalancingStrategy { get; set; } = "LeastLag"; // LeastLag, RoundRobin, Weighted
   }

   [ApiController]
   [Route("api/[controller]")]
   public class OrderController : ControllerBase
   {
       private readonly IOrderService _orderService;
       private readonly IReplicaRoutingService _routingService;
       private readonly ILogger<OrderController> _logger;

       public OrderController(IOrderService orderService,
                             IReplicaRoutingService routingService,
                             ILogger<OrderController> logger)
       {
           _orderService = orderService;
           _routingService = routingService;
           _logger = logger;
       }

       [HttpPost]
       public async Task<ActionResult<Order>> CreateOrder([FromBody] CreateOrderRequest request)
       {
           var context = new QueryContext
           {
               RequestId = HttpContext.TraceIdentifier,
               UserId = User.FindFirst("sub")?.Value,
               OperationType = "order_create",
               ConsistencyLevel = ConsistencyLevel.Strong // Writes need strong consistency
           };

           try
           {
               var order = await _orderService.CreateOrderAsync(request, context);

               _logger.LogInformation("Order created successfully", new {
                   OrderId = order.Id,
                   RequestId = context.RequestId,
                   UserId = context.UserId
               });

               return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
           }
           catch (Exception ex)
           {
               _logger.LogError(ex, "Order creation failed", new {
                   RequestId = context.RequestId,
                   UserId = context.UserId
               });
               return StatusCode(500, "Order creation failed");
           }
       }

       [HttpGet("{id}")]
       public async Task<ActionResult<Order>> GetOrder(int id,
                                                      [FromQuery] bool readOwnWrites = false,
                                                      [FromQuery] int? maxLagSeconds = null)
       {
           var consistencyLevel = readOwnWrites
               ? ConsistencyLevel.ReadAfterWrite
               : ConsistencyLevel.Eventual;

           var context = new QueryContext
           {
               RequestId = HttpContext.TraceIdentifier,
               UserId = User.FindFirst("sub")?.Value,
               OperationType = "order_read",
               ConsistencyLevel = consistencyLevel,
               MaxLagSeconds = maxLagSeconds
           };

           try
           {
               var order = await _orderService.GetOrderAsync(id, context);

               if (order == null)
               {
                   return NotFound();
               }

               // Add headers to indicate the source of the data
               var routingInfo = await _routingService.GetLastRoutingDecision();
               Response.Headers.Add("X-Data-Source", routingInfo.TargetType);
               Response.Headers.Add("X-Replica-Lag", routingInfo.LagSeconds.ToString("F2"));

               return Ok(order);
           }
           catch (NoReplicaAvailableException ex)
           {
               _logger.LogWarning("No replica available for read", new {
                   RequestId = context.RequestId,
                   ConsistencyLevel = consistencyLevel,
                   MaxLagSeconds = maxLagSeconds
               });

               return StatusCode(503, "Service temporarily unavailable - try again with relaxed consistency requirements");
           }
       }

       [HttpGet]
       public async Task<ActionResult<PagedResult<Order>>> GetOrders(
           [FromQuery] int page = 1,
           [FromQuery] int pageSize = 20,
           [FromQuery] string status = null,
           [FromQuery] int maxLagSeconds = 30)
       {
           var context = new QueryContext
           {
               RequestId = HttpContext.TraceIdentifier,
               UserId = User.FindFirst("sub")?.Value,
               OperationType = "order_list",
               ConsistencyLevel = ConsistencyLevel.Eventual,
               MaxLagSeconds = maxLagSeconds
           };

           var filter = new OrderFilter
           {
               Status = status,
               Page = page,
               PageSize = pageSize
           };

           var orders = await _orderService.GetOrdersAsync(filter, context);

           // Provide observability headers
           var routingInfo = await _routingService.GetLastRoutingDecision();
           Response.Headers.Add("X-Data-Source", routingInfo.TargetType);
           Response.Headers.Add("X-Replica-Name", routingInfo.TargetName);
           Response.Headers.Add("X-Replica-Lag", routingInfo.LagSeconds.ToString("F2"));

           return Ok(orders);
       }
   }

   // Health check endpoint for replica status
   [ApiController]
   [Route("api/health")]
   public class HealthController : ControllerBase
   {
       private readonly IReplicaHealthService _replicaHealth;

       [HttpGet("replicas")]
       public async Task<ActionResult<Dictionary<string, object>>> GetReplicaHealth()
       {
           var health = await _replicaHealth.GetAllReplicaStatusAsync();

           var result = health.ToDictionary(
               kvp => kvp.Key,
               kvp => new {
                   healthy = kvp.Value.IsHealthy,
                   lagSeconds = kvp.Value.LagSeconds,
                   lastCheck = kvp.Value.LastCheck,
                   circuitBreakerState = kvp.Value.CircuitBreakerState,
                   consecutiveFailures = kvp.Value.ConsecutiveFailures
               }
           );

           var overallHealthy = health.Values.Any(h => h.IsHealthy);
           var statusCode = overallHealthy ? 200 : 503;

           return StatusCode(statusCode, result);
       }
   }
   ```

## Examples

```python
# ❌ BAD: Hidden complexity in automatic load balancing
class DatabaseService:
    def __init__(self, connection_string):
        # Magic connection string that handles routing internally
        self.db = SmartConnection(connection_string)

    def get_user(self, user_id):
        # No visibility into which database this hits
        # No control over consistency requirements
        return self.db.query("SELECT * FROM users WHERE id = %s", user_id)

    def create_user(self, user_data):
        # Unclear if this goes to primary or might hit a replica
        return self.db.query("INSERT INTO users ...", user_data)

# ✅ GOOD: Explicit routing with clear consistency guarantees
class UserService:
    def __init__(self, db_router: DatabaseRouter):
        self.db_router = db_router

    def get_user(self, user_id: int, read_own_writes: bool = False) -> Optional[User]:
        consistency = (ConsistencyLevel.READ_AFTER_WRITE
                      if read_own_writes
                      else ConsistencyLevel.EVENTUAL)

        options = ReadOptions(consistency=consistency)
        with self.db_router.get_read_connection(options) as conn:
            return User.find_by_id(conn, user_id)

    def create_user(self, user_data: dict) -> User:
        # Writes explicitly go to primary
        with self.db_router.get_write_connection() as conn:
            return User.create(conn, user_data)
```

```javascript
// ❌ BAD: Silent degradation without observability
async function getOrderHistory(userId) {
    try {
        // Might silently fall back to stale data or fail
        return await db.query('SELECT * FROM orders WHERE user_id = ?', [userId]);
    } catch (error) {
        // No information about what failed or why
        throw new Error('Failed to get order history');
    }
}

// ✅ GOOD: Observable operations with explicit degradation
async function getOrderHistory(userId, options = {}) {
    const readOptions = {
        consistency: options.readOwnWrites ? 'read_after_write' : 'eventual',
        maxLagSeconds: options.maxLagSeconds || 30,
        allowPrimaryFallback: true
    };

    const startTime = Date.now();
    try {
        const result = await replicaManager.executeQuery(
            'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
            [userId],
            readOptions
        );

        // Log successful routing decision
        logger.info('Order history retrieved', {
            userId,
            consistency: readOptions.consistency,
            duration: Date.now() - startTime,
            // Replica manager adds routing details
        });

        return result;
    } catch (error) {
        if (error instanceof NoReplicaAvailableError) {
            // Explicit fallback with visibility
            logger.warn('Falling back to primary for order history', {
                userId,
                reason: error.message
            });
            return await primaryDb.query(
                'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
                [userId]
            );
        }
        throw error;
    }
}
```

```java
// ❌ BAD: Hardcoded lag tolerances and routing decisions
@Service
public class ProductService {
    public List<Product> searchProducts(String query) {
        // Hardcoded to always use replica, no flexibility
        return replicaDb.query("SELECT * FROM products WHERE name LIKE ?", "%" + query + "%");
    }

    public Product getProduct(Long id) {
        // No consideration of read-after-write scenarios
        return replicaDb.queryForObject("SELECT * FROM products WHERE id = ?", id);
    }
}

// ✅ GOOD: Configurable policies with explicit requirements
@Service
public class ProductService {
    private final DatabaseRouter router;
    private final ReplicaConfiguration config;

    public List<Product> searchProducts(String query, SearchOptions options) {
        ReadOptions readOptions = ReadOptions.builder()
            .consistencyLevel(ConsistencyLevel.EVENTUAL)
            .maxLagSeconds(config.getSearchMaxLagSeconds())
            .allowPrimaryFallback(true)
            .build();

        return executeQuery(
            () -> router.executeQuery("product_search", readOptions,
                "SELECT * FROM products WHERE name LIKE ?", "%" + query + "%"),
            () -> primaryDb.query("SELECT * FROM products WHERE name LIKE ?", "%" + query + "%")
        );
    }

    public Product getProduct(Long id, boolean readOwnWrites) {
        ConsistencyLevel consistency = readOwnWrites
            ? ConsistencyLevel.READ_AFTER_WRITE
            : ConsistencyLevel.EVENTUAL;

        ReadOptions readOptions = ReadOptions.builder()
            .consistencyLevel(consistency)
            .maxLagSeconds(config.getDetailViewMaxLagSeconds())
            .build();

        return router.executeQuery("product_get", readOptions,
            "SELECT * FROM products WHERE id = ?", id);
    }
}
```

## Related Bindings

- [connection-pooling-standards](../../docs/bindings/categories/database/connection-pooling-standards.md): Read replica
  patterns must coordinate with connection pooling to manage connections
  efficiently across multiple database instances. Both patterns work together
  to create scalable, maintainable database architectures.

- [query-optimization-and-indexing](../../docs/bindings/categories/database/query-optimization-and-indexing.md): Read
  replicas require proper indexing strategies to perform well, and query
  optimization becomes more complex when queries may execute on different
  instances with different lag characteristics.

- [use-structured-logging](../../core/use-structured-logging.md): Read replica
  operations require comprehensive structured logging to track routing decisions,
  lag metrics, and fallback scenarios. Both patterns support observability and
  operational maintenance of complex distributed database systems.
