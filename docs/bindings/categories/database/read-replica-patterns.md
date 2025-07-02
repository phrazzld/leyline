---
id: read-replica-patterns
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: maintainability
enforced_by: architecture review & monitoring
---

# Binding: Design Maintainable Read Replica Patterns

Read replica implementations must prioritize long-term maintainability through clear separation patterns, explicit consistency guarantees, and predictable failover behaviors. Design for operational simplicity rather than complex optimizations.

## Rationale

This binding implements maintainability by ensuring read replica patterns remain comprehensible and manageable as systems scale. Read replicas solve performance problems but can create operational complexity without careful design.

Read replicas introduce distributed system complexity—replication lag, eventual consistency, and failure scenarios—into previously simple systems. Maintainable patterns establish clear, consistent approaches to these challenges.

## Rule Definition

**Required Components:**
- **Explicit Consistency Levels**: Define clear requirements (strong, eventual, bounded-stale) for each operation
- **Clear Routing**: Explicitly classify and route reads vs writes to appropriate data stores
- **Fallback Strategies**: Implement predictable degradation when replicas fail or lag
- **Session Consistency**: Manage read-after-write consistency for user sessions
- **Lag Monitoring**: Monitor replication lag with automated alerts and health checks
- **Simple Failover**: Design testable failover with clear recovery procedures

**Prohibited Practices:**
- Implicit or automatic routing decisions without clear consistency guarantees
- Complex optimization schemes that sacrifice operational clarity
- Session consistency patterns that create unpredictable user experiences

## Practical Implementation

**1. Explicit Read Routing**

Define clear consistency levels and routing logic:

```typescript
enum ConsistencyLevel {
  STRONG = 'strong',       // Read from primary
  EVENTUAL = 'eventual',   // Read from any healthy replica
  BOUNDED_STALE = 'bounded' // Read from replica within lag bound
}

class DatabaseRouter {
  async read<T>(query: string, params: any[], options: {
    consistency: ConsistencyLevel;
    maxStaleness?: number;
  }): Promise<T> {
    switch (options.consistency) {
      case ConsistencyLevel.STRONG:
        return await this.primary.execute(query, params);

      case ConsistencyLevel.BOUNDED_STALE:
        const replica = await this.selectReplicaWithinBound(options.maxStaleness || 1000);
        return replica
          ? await replica.execute(query, params)
          : await this.primary.execute(query, params); // Fallback

      case ConsistencyLevel.EVENTUAL:
        const healthyReplica = await this.selectHealthyReplica();
        return healthyReplica
          ? await healthyReplica.execute(query, params)
          : await this.primary.execute(query, params); // Fallback
    }
  }

  async write<T>(query: string, params: any[]): Promise<T> {
    return await this.primary.execute(query, params); // All writes to primary
  }
}
```

**2. Session Consistency Management**

Handle read-after-write consistency for user sessions:

```typescript
class SessionConsistencyManager {
  private userLastWrites = new Map<string, number>();

  async handleRead<T>(userId: string, readFn: () => Promise<T>, requireConsistency = false): Promise<T> {
    if (requireConsistency) {
      const lastWrite = this.userLastWrites.get(userId);
      if (lastWrite && Date.now() - lastWrite < 5000) {
        // Recent write - read from primary
        return await this.dbRouter.read(readFn, { consistency: ConsistencyLevel.STRONG });
      }
    }
    return await readFn();
  }

  async handleWrite<T>(userId: string, writeFn: () => Promise<T>): Promise<T> {
    const result = await writeFn();
    this.userLastWrites.set(userId, Date.now());
    return result;
  }
}
```

**3. Replication Monitoring**

Monitor replica health and lag:

```typescript
class ReplicationMonitor {
  async getLag(replica: DatabaseConnection): Promise<number | null> {
    try {
      const result = await replica.query(
        'SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) * 1000 as lag_ms'
      );
      const lag = result.rows[0]?.lag_ms || null;

      if (lag > 10000) { // Alert on 10+ second lag
        await this.alertManager.warn(`Replica lag: ${lag}ms`);
      }

      return lag;
    } catch {
      return null;
    }
  }

  async isHealthy(replica: DatabaseConnection): Promise<boolean> {
    try {
      await replica.query('SELECT 1');
      const lag = await this.getLag(replica);
      return lag !== null && lag < 30000; // 30 second max
    } catch {
      return false;
    }
  }
}
```

**4. Service-Level Patterns**

Apply consistency requirements at the service level:

```typescript
class UserService {
  // Profile data - eventually consistent
  async getUserProfile(userId: string): Promise<UserProfile> {
    return await this.dbRouter.read(
      'SELECT * FROM profiles WHERE user_id = $1',
      [userId],
      { consistency: ConsistencyLevel.EVENTUAL }
    );
  }

  // Security data - strong consistency
  async getUserPermissions(userId: string): Promise<Permission[]> {
    return await this.dbRouter.read(
      'SELECT * FROM permissions WHERE user_id = $1',
      [userId],
      { consistency: ConsistencyLevel.STRONG }
    );
  }

  // User's own data - read-after-write consistency
  async getUserActivity(userId: string, requesterId: string): Promise<Activity[]> {
    return await this.sessionManager.handleRead(
      requesterId,
      () => this.dbRouter.read(/* query */),
      userId === requesterId // Require consistency for own data
    );
  }
}
```

## Examples

```typescript
// ❌ BAD: Implicit routing with unclear consistency
class UserService {
  async getUser(id: string) {
    // Which database? What consistency? Unknown!
    return await this.db.query('SELECT * FROM users WHERE id = ?', [id]);
  }

  async updateUser(id: string, data: any) {
    await this.db.query('UPDATE users SET ... WHERE id = ?', [data, id]);
    // No read-after-write consideration
  }
}
```

```typescript
// ✅ GOOD: Explicit consistency and clear routing
class UserService {
  async getUser(id: string): Promise<User> {
    // Profile data - eventually consistent
    return await this.dbRouter.read(
      'SELECT * FROM users WHERE id = $1', [id],
      { consistency: ConsistencyLevel.EVENTUAL }
    );
  }

  async getUserPermissions(id: string): Promise<Permission[]> {
    // Security data - strong consistency
    return await this.dbRouter.read(
      'SELECT * FROM permissions WHERE user_id = $1', [id],
      { consistency: ConsistencyLevel.STRONG }
    );
  }

  async updateUser(id: string, data: UserUpdate): Promise<void> {
    await this.sessionManager.handleWrite(id, () =>
      this.dbRouter.write('UPDATE users SET ... WHERE id = $1', [data, id])
    );
  }

  async getUserPosts(userId: string, requesterId: string): Promise<Post[]> {
    // Show user their own recent posts immediately
    return await this.sessionManager.handleRead(
      requesterId,
      () => this.dbRouter.read(/* query */, [userId], {
        consistency: ConsistencyLevel.BOUNDED_STALE,
        maxStaleness: 2000
      }),
      userId === requesterId // Require consistency for own data
    );
  }
}
```

## Related Bindings

- [maintainability](../../tenets/maintainability.md): Read replica patterns directly implement maintainability by creating comprehensible, modifiable database scaling solutions that remain operational as systems grow.

- [explicit-over-implicit](../../tenets/explicit-over-implicit.md): Replica patterns require explicit consistency level declarations and clear routing decisions rather than hidden or automatic behavior.

- [system-boundaries](../core/system-boundaries.md): Read replicas create new system boundaries that must be explicitly managed with clear contracts about consistency guarantees and failure modes.

- [use-structured-logging](../core/use-structured-logging.md): Replica operations require comprehensive logging to track routing decisions, lag monitoring, and failover events for operational visibility.
