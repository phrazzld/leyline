---
id: connection-pooling-standards
last_modified: '2025-01-12'
version: '0.2.0'
derived_from: simplicity
enforced_by: configuration management & monitoring
---

# Binding: Use Simple, Well-Configured Connection Pools

Database connection pools must be configured with simple, explicit settings
based on actual application load patterns rather than complex adaptive algorithms.
Establish clear pool sizing, connection lifecycle management, and health
monitoring to ensure predictable resource usage and system reliability.

## Rationale

Database connections are expensive resources. Simple, explicit pool configuration based on measured load prevents both resource waste and bottlenecks. Complex adaptive algorithms create mysterious performance issues, while explicit settings with monitoring provide production reliability.

## Rule Definition

**Core Requirements:**

- **Size Based on Load**: Set pool sizes based on measured peak concurrency plus headroom, not defaults or guesswork
- **Explicit Timeouts**: Configure connection acquisition, idle, and lifetime timeouts explicitly for your environment
- **Health Monitoring**: Implement connection validation, pool utilization monitoring, and leak detection
- **Fail Fast**: Configure pools to fail quickly with clear error messages rather than queuing indefinitely
- **Resource Cleanup**: Ensure connections are properly returned using language-specific resource management patterns

**Prohibited Patterns:**
- Using default configurations without measurement
- Complex adaptive algorithms over simple explicit settings
- Unlimited connection queuing
- Missing resource cleanup in error conditions

## Practical Implementation

```python
from contextlib import contextmanager
from sqlalchemy import create_engine, event
from sqlalchemy.pool import QueuePool
import logging

logger = logging.getLogger('database_pool')

class DatabaseManager:
    def __init__(self, database_url):
        # Explicit configuration based on load testing
        self.engine = create_engine(
            database_url,
            poolclass=QueuePool,
            pool_size=15,                    # Peak + 25% headroom
            max_overflow=5,                  # Limited overflow
            pool_timeout=30,                 # Fail fast
            pool_recycle=3600,               # Recycle after 1 hour
            pool_pre_ping=True,              # Validate before use
            connect_args={
                "connect_timeout": 10,
                "application_name": "MyApp",
                "sslmode": "require"
            }
        )
        self._setup_monitoring()

    def _setup_monitoring(self):
        @event.listens_for(self.engine, 'checkout')
        def track_checkout(dbapi_conn, conn_record, conn_proxy):
            conn_record.checkout_time = time.time()

        @event.listens_for(self.engine, 'checkin')
        def track_checkin(dbapi_conn, conn_record):
            if hasattr(conn_record, 'checkout_time'):
                duration = time.time() - conn_record.checkout_time
                if duration > 60:
                    logger.warning(f"Long-running connection: {duration}s")

    @contextmanager
    def get_connection(self):
        connection = None
        try:
            connection = self.engine.connect()
            yield connection
        except Exception as e:
            logger.error(f"Database operation failed: {e}")
            if connection:
                connection.rollback()
            raise
        finally:
            if connection:
                connection.close()

    @contextmanager
    def get_transaction(self):
        with self.get_connection() as conn:
            trans = conn.begin()
            try:
                yield conn
                trans.commit()
            except Exception:
                trans.rollback()
                raise

    def health_check(self):
        try:
            with self.get_connection() as conn:
                return conn.execute("SELECT 1").scalar() == 1
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

    def get_pool_status(self):
        pool = self.engine.pool
        utilization = pool.checked_out_connections / (pool.size() + pool.overflow())
        if utilization > 0.8:
            logger.warning(f"High pool utilization: {utilization:.1%}")
        return {
            'size': pool.size(), 'checked_out': pool.checked_out_connections,
            'utilization': utilization
        }

# Usage
def example_usage():
    db = DatabaseManager(DATABASE_URL)

    with db.get_connection() as conn:
        result = conn.execute("SELECT * FROM users").fetchall()

    with db.get_transaction() as conn:
        conn.execute("INSERT INTO users (name) VALUES (?)", ["John"])

    if not db.health_check():
        logger.error("Database health check failed")
```

## Examples

```python
# ❌ BAD: Default configuration, no resource management
engine = create_engine(DATABASE_URL)  # Uses defaults
conn = engine.connect()
result = conn.execute("SELECT * FROM users").fetchall()
# Connection never returned to pool

# ✅ GOOD: Explicit configuration with resource management
engine = create_engine(
    DATABASE_URL,
    pool_size=10, max_overflow=5, pool_timeout=30,
    pool_recycle=3600, pool_pre_ping=True
)

@contextmanager
def get_connection():
    conn = None
    try:
        conn = engine.connect()
        yield conn
    finally:
        if conn:
            conn.close()

def get_users():
    with get_connection() as conn:
        return conn.execute("SELECT * FROM users").fetchall()
```

## Related Bindings

- [external-configuration](../../core/external-configuration.md): Pool settings must be externally configurable for environment-specific tuning without code changes.

- [use-structured-logging](../../core/use-structured-logging.md): Pool monitoring requires structured logging to track utilization and detect leaks.

- [fail-fast-validation](../../core/fail-fast-validation.md): Pools should fail fast when exhausted rather than queuing indefinitely to prevent cascade failures.
