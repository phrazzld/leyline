---
id: read-replica-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: maintainability
enforced_by: architecture review & monitoring
---

# Binding: Design Maintainable Read Replica Patterns

Read replica implementations must prioritize long-term maintainability by using clear separation patterns, explicit consistency guarantees, and predictable failover behaviors. Design for operational simplicity and graceful degradation rather than complex optimization schemes that are difficult to maintain.

## Rationale

This binding implements maintainability by ensuring that read replica patterns remain comprehensible and manageable as systems scale. Read replicas often solve immediate performance problems but can create complex distributed systems that become operational nightmares without careful design.

Think of read replicas like having multiple copies of a reference book distributed across different libraries. Each copy helps serve more readers simultaneously, but you need clear policies about which copy to consult for which purposes, how to handle outdated or unavailable copies, and what to do when the main book is updated.

The challenge with read replicas is that they introduce distributed system complexity—replication lag, eventual consistency, and failure scenarios—into previously simple systems. Maintainable replica patterns establish clear, consistent approaches to these challenges.

## Rule Definition

Maintainable read replica patterns require designing database scaling solutions that remain operationally simple and predictable over time:

**Consistency Management:**
- **Explicit Consistency Levels**: Define clear read consistency requirements for each operation (strong, eventual, or stale-acceptable)
- **Lag Tolerance Specification**: Document acceptable replication lag for each data type and operation
- **Fallback Strategies**: Implement predictable degradation when replicas are unavailable or too stale

**Read/Write Separation:**
- **Clear Operation Classification**: Explicitly route reads and writes to appropriate data stores
- **Transaction Boundary Management**: Handle cross-replica operations with clear consistency guarantees
- **Session Affinity Patterns**: Manage user session consistency across replica reads

**Operational Simplicity:**
- **Monitoring and Alerting**: Implement comprehensive lag monitoring and automated health checks
- **Failover Automation**: Design simple, testable failover mechanisms with clear recovery procedures
- **Capacity Planning**: Provide clear guidelines for replica scaling and performance tuning

## Practical Implementation

1. **Implement Explicit Read Routing**: Create clear patterns for directing reads to appropriate replicas:

   ```typescript
   enum ConsistencyLevel {
     STRONG = 'strong',           // Must read from primary
     EVENTUAL = 'eventual',       // Can read from replica with any lag
     BOUNDED_STALE = 'bounded',   // Can read from replica within time bound
   }

   interface ReadOptions {
     consistency: ConsistencyLevel;
     maxStaleness?: number; // milliseconds
     timeout?: number;
   }

   class DatabaseRouter {
     constructor(
       private primary: DatabaseConnection,
       private replicas: DatabaseConnection[],
       private replicationMonitor: ReplicationMonitor
     ) {}

     async read<T>(
       query: string,
       params: any[],
       options: ReadOptions = { consistency: ConsistencyLevel.EVENTUAL }
     ): Promise<T> {
       try {
         switch (options.consistency) {
           case ConsistencyLevel.STRONG:
             return await this.readFromPrimary(query, params, options.timeout);

           case ConsistencyLevel.BOUNDED_STALE:
             const replica = await this.selectReplicaWithinBound(options.maxStaleness || 1000);
             if (replica) {
               return await this.readFromReplica(replica, query, params, options.timeout);
             }
             // Fallback to primary if no suitable replica
             return await this.readFromPrimary(query, params, options.timeout);

           case ConsistencyLevel.EVENTUAL:
             const healthyReplica = await this.selectHealthyReplica();
             if (healthyReplica) {
               return await this.readFromReplica(healthyReplica, query, params, options.timeout);
             }
             // Fallback to primary if no healthy replica
             return await this.readFromPrimary(query, params, options.timeout);

           default:
             throw new Error(`Unknown consistency level: ${options.consistency}`);
         }
       } catch (error) {
         // Always fallback to primary on error
         if (options.consistency !== ConsistencyLevel.STRONG) {
           try {
             return await this.readFromPrimary(query, params, options.timeout);
           } catch (primaryError) {
             throw new DatabaseError('Primary and replica reads failed', {
               replicaError: error,
               primaryError
             });
           }
         }
         throw error;
       }
     }

     async write<T>(query: string, params: any[], timeout?: number): Promise<T> {
       // All writes go to primary
       return await this.primary.execute(query, params, timeout);
     }

     private async selectReplicaWithinBound(maxStalenessMs: number): Promise<DatabaseConnection | null> {
       for (const replica of this.replicas) {
         const lag = await this.replicationMonitor.getLag(replica);
         if (lag !== null && lag <= maxStalenessMs) {
           return replica;
         }
       }
       return null;
     }

     private async selectHealthyReplica(): Promise<DatabaseConnection | null> {
       for (const replica of this.replicas) {
         if (await this.replicationMonitor.isHealthy(replica)) {
           return replica;
         }
       }
       return null;
     }
   }
   ```

2. **Design Session Consistency Management**: Handle user sessions that require read-after-write consistency:

   ```typescript
   class SessionConsistencyManager {
     private userLastWrites = new Map<string, number>();

     async handleRead<T>(
       userId: string,
       readOperation: () => Promise<T>,
       options: ReadOptions & { requireReadAfterWrite?: boolean } = {}
     ): Promise<T> {
       if (options.requireReadAfterWrite) {
         const lastWriteTime = this.userLastWrites.get(userId);
         if (lastWriteTime) {
           const timeSinceWrite = Date.now() - lastWriteTime;
           if (timeSinceWrite < 5000) { // Within 5 seconds, read from primary
             return await this.dbRouter.read(
               readOperation,
               { consistency: ConsistencyLevel.STRONG }
             );
           }
         }
       }

       return await this.dbRouter.read(readOperation, options);
     }

     async handleWrite<T>(
       userId: string,
       writeOperation: () => Promise<T>
     ): Promise<T> {
       const result = await this.dbRouter.write(writeOperation);
       this.userLastWrites.set(userId, Date.now());

       // Clean up old entries periodically
       this.cleanupOldEntries();

       return result;
     }

     private cleanupOldEntries(): void {
       const cutoff = Date.now() - 60000; // 1 minute ago
       for (const [userId, timestamp] of this.userLastWrites.entries()) {
         if (timestamp < cutoff) {
           this.userLastWrites.delete(userId);
         }
       }
     }
   }
   ```

3. **Implement Replication Monitoring**: Create comprehensive monitoring for replica health and lag:

   ```typescript
   class ReplicationMonitor {
     private lagCache = new Map<string, { lag: number | null; timestamp: number }>();
     private readonly CACHE_TTL = 1000; // 1 second

     async getLag(replica: DatabaseConnection): Promise<number | null> {
       const replicaId = replica.getId();
       const cached = this.lagCache.get(replicaId);

       if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
         return cached.lag;
       }

       try {
         // Query replica for its lag behind primary
         const result = await replica.query(
           'SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) * 1000 as lag_ms'
         );

         const lag = result.rows[0]?.lag_ms || null;
         this.lagCache.set(replicaId, { lag, timestamp: Date.now() });

         // Alert if lag exceeds threshold
         if (lag !== null && lag > 10000) { // 10 seconds
           await this.alertManager.sendAlert({
             level: 'warning',
             message: `Replica ${replicaId} lag: ${lag}ms`,
             replica: replicaId,
             lag
           });
         }

         return lag;
       } catch (error) {
         this.lagCache.set(replicaId, { lag: null, timestamp: Date.now() });
         return null;
       }
     }

     async isHealthy(replica: DatabaseConnection): Promise<boolean> {
       try {
         // Simple health check query
         await replica.query('SELECT 1');

         // Check lag is within acceptable bounds
         const lag = await this.getLag(replica);
         return lag !== null && lag < 30000; // 30 seconds max
       } catch (error) {
         return false;
       }
     }

     async getHealthStatus(): Promise<ReplicationStatus> {
       const replicaStatuses = await Promise.all(
         this.replicas.map(async (replica) => ({
           id: replica.getId(),
           healthy: await this.isHealthy(replica),
           lag: await this.getLag(replica)
         }))
       );

       return {
         primaryHealthy: await this.isHealthy(this.primary),
         replicas: replicaStatuses,
         overallHealth: replicaStatuses.every(r => r.healthy) ? 'healthy' : 'degraded'
       };
     }
   }
   ```

4. **Implement Service-Level Patterns**: Create domain-specific read routing strategies:

   ```typescript
   class UserService {
     constructor(
       private dbRouter: DatabaseRouter,
       private sessionManager: SessionConsistencyManager
     ) {}

     // Profile reads can be eventually consistent
     async getUserProfile(userId: string): Promise<UserProfile> {
       return await this.dbRouter.read(
         'SELECT * FROM user_profiles WHERE user_id = $1',
         [userId],
         { consistency: ConsistencyLevel.EVENTUAL }
       );
     }

     // Security-sensitive reads require strong consistency
     async getUserPermissions(userId: string): Promise<Permission[]> {
       return await this.dbRouter.read(
         'SELECT * FROM user_permissions WHERE user_id = $1',
         [userId],
         { consistency: ConsistencyLevel.STRONG }
       );
     }

     // Recent activity should show user's own writes
     async getUserActivity(userId: string, requesterId: string): Promise<Activity[]> {
       const requireReadAfterWrite = userId === requesterId;

       return await this.sessionManager.handleRead(
         requesterId,
         () => this.dbRouter.read(
           'SELECT * FROM user_activities WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
           [userId],
           { consistency: ConsistencyLevel.EVENTUAL }
         ),
         { requireReadAfterWrite }
       );
     }

     // All writes go through session manager
     async updateUserProfile(userId: string, updates: Partial<UserProfile>): Promise<void> {
       await this.sessionManager.handleWrite(
         userId,
         () => this.dbRouter.write(
           'UPDATE user_profiles SET name = $1, email = $2 WHERE user_id = $3',
           [updates.name, updates.email, userId]
         )
       );
     }
   }
   ```

## Examples

```typescript
// ❌ BAD: Implicit routing with unclear consistency guarantees
class UserService {
  async getUser(id: string) {
    // Which database? What consistency? Unknown!
    return await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async updateUser(id: string, data: any) {
    await this.db.query('UPDATE users SET ... WHERE id = ?', [data, id]);
    // No consideration of read-after-write consistency
  }

  async getUserPosts(userId: string) {
    // Might hit replica, might not see user's recent posts
    return await this.db.query('SELECT * FROM posts WHERE user_id = ?', [userId]);
  }
}
```

```typescript
// ✅ GOOD: Explicit consistency levels and clear routing
class UserService {
  async getUser(id: string): Promise<User> {
    // Profile data can be eventually consistent
    return await this.dbRouter.read(
      'SELECT * FROM users WHERE id = $1',
      [id],
      { consistency: ConsistencyLevel.EVENTUAL }
    );
  }

  async getUserSensitiveData(id: string): Promise<UserSensitiveData> {
    // Security data requires strong consistency
    return await this.dbRouter.read(
      'SELECT * FROM user_sensitive WHERE id = $1',
      [id],
      { consistency: ConsistencyLevel.STRONG }
    );
  }

  async updateUser(id: string, data: UserUpdate): Promise<void> {
    await this.sessionManager.handleWrite(
      id,
      () => this.dbRouter.write(
        'UPDATE users SET name = $1, email = $2 WHERE id = $3',
        [data.name, data.email, id]
      )
    );
  }

  async getUserPosts(userId: string, requesterId: string): Promise<Post[]> {
    // Show user their own recent posts immediately
    const requireReadAfterWrite = userId === requesterId;

    return await this.sessionManager.handleRead(
      requesterId,
      () => this.dbRouter.read(
        'SELECT * FROM posts WHERE user_id = $1 ORDER BY created_at DESC',
        [userId],
        { consistency: ConsistencyLevel.BOUNDED_STALE, maxStaleness: 2000 }
      ),
      { requireReadAfterWrite }
    );
  }
}
```

## Related Bindings

- [maintainability](../../tenets/maintainability.md): Read replica patterns directly implement maintainability by creating comprehensible, modifiable database scaling solutions that remain operational as systems grow.

- [explicit-over-implicit](../../tenets/explicit-over-implicit.md): Replica patterns require explicit consistency level declarations and clear routing decisions rather than hidden or automatic behavior.

- [system-boundaries](../core/system-boundaries.md): Read replicas create new system boundaries that must be explicitly managed with clear contracts about consistency guarantees and failure modes.

- [use-structured-logging](../core/use-structured-logging.md): Replica operations require comprehensive logging to track routing decisions, lag monitoring, and failover events for operational visibility.
