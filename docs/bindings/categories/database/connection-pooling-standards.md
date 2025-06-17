---
id: connection-pooling-standards
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: simplicity
enforced_by: configuration management & monitoring
---

# Binding: Use Simple, Well-Configured Connection Pools

Database connection pools must be configured with simple, explicit settings
based on actual application load patterns rather than complex adaptive algorithms.
Establish clear pool sizing, connection lifecycle management, and health
monitoring to ensure predictable resource usage and system reliability.

## Rationale

This binding implements our simplicity tenet by ensuring database connection management remains predictable and maintainable. Database connections are expensive resources—creating them is slow, keeping too many idle wastes memory, and having too few creates bottlenecks.

Connection pooling solves this problem when configured simply and explicitly based on real application needs. Complex adaptive algorithms often become sources of mysterious performance issues. Simple, explicitly configured pools with good monitoring provide the reliability that production systems demand.

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

**Comprehensive Connection Pool Configuration with Monitoring and Resource Management:**

```python
# Complete example demonstrating all key patterns
import time
import logging
from contextlib import contextmanager
from sqlalchemy import create_engine, event
from sqlalchemy.pool import QueuePool

logger = logging.getLogger('database_pool')

class DatabaseManager:
    def __init__(self, database_url):
        # Explicit configuration based on load testing
        # Measured: 95th percentile concurrent connections = 12
        self.engine = create_engine(
            database_url,
            poolclass=QueuePool,
            pool_size=15,                    # Peak + 25% headroom
            max_overflow=5,                  # Limited overflow for spikes
            pool_timeout=30,                 # Fail fast - 30 second timeout
            pool_recycle=3600,               # Recycle after 1 hour
            pool_pre_ping=True,              # Validate before use
            connect_args={
                "connect_timeout": 10,        # 10 second connection timeout
                "application_name": "MyApp",  # For monitoring
                "sslmode": "require"
            }
        )

        self.pool_stats = {
            'created': 0, 'checked_out': 0, 'checked_in': 0, 'leaked': 0
        }

        self._setup_monitoring()

    def _setup_monitoring(self):
        """Set up comprehensive pool monitoring."""

        @event.listens_for(self.engine, 'connect')
        def track_connection_created(dbapi_connection, connection_record):
            self.pool_stats['created'] += 1
            logger.info("Connection created", extra={
                'total_created': self.pool_stats['created'],
                'pool_size': self.engine.pool.size(),
                'pool_checked_in': self.engine.pool.checkedin()
            })

        @event.listens_for(self.engine, 'checkout')
        def track_connection_checkout(dbapi_connection, connection_record, connection_proxy):
            self.pool_stats['checked_out'] += 1
            connection_record.checkout_time = time.time()

        @event.listens_for(self.engine, 'checkin')
        def track_connection_checkin(dbapi_connection, connection_record):
            self.pool_stats['checked_in'] += 1
            if hasattr(connection_record, 'checkout_time'):
                duration = time.time() - connection_record.checkout_time
                if duration > 60:  # Log long-running connections
                    logger.warning("Long-running connection", extra={
                        'duration': duration,
                        'connection_id': id(dbapi_connection)
                    })

    @contextmanager
    def get_connection(self):
        """Context manager for safe connection handling."""
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
                connection.close()  # Return to pool

    @contextmanager
    def get_transaction(self):
        """Context manager for safe transaction handling."""
        with self.get_connection() as conn:
            trans = conn.begin()
            try:
                yield conn
                trans.commit()
            except Exception:
                trans.rollback()
                raise

    def health_check(self, timeout=5):
        """Simple health check with timeout."""
        try:
            with self.get_connection() as conn:
                result = conn.execute("SELECT 1").scalar()
                return result == 1
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

    def get_pool_status(self):
        """Get current pool statistics for monitoring."""
        pool = self.engine.pool
        stats = {
            'size': pool.size(),
            'checked_in': pool.checkedin(),
            'overflow': pool.overflow(),
            'checked_out': pool.checked_out_connections,
            'stats': self.pool_stats.copy()
        }

        # Alert on concerning metrics
        utilization = stats['checked_out'] / (stats['size'] + stats['overflow']) if stats['size'] > 0 else 0
        if utilization > 0.8:
            logger.warning(f"High pool utilization: {utilization:.1%}", extra=stats)

        return stats

    def close(self):
        """Gracefully close all connections."""
        self.engine.dispose()
        logger.info("Database pool closed")

# Usage examples
def example_usage():
    # Initialize with externally configured URL
    db = DatabaseManager(DATABASE_URL)

    # Simple query with automatic resource management
    with db.get_connection() as conn:
        result = conn.execute("SELECT * FROM users WHERE active = true").fetchall()

    # Transaction with automatic rollback on error
    with db.get_transaction() as conn:
        conn.execute("INSERT INTO users (name, email) VALUES (?, ?)", ["John", "john@example.com"])
        conn.execute("UPDATE users SET last_login = NOW() WHERE email = ?", ["john@example.com"])

    # Monitor pool health
    if not db.health_check():
        logger.error("Database health check failed")

    # Log pool statistics
    stats = db.get_pool_status()
    logger.info("Pool status", extra=stats)

    # Graceful shutdown
    db.close()

# External configuration example
class PoolConfig:
    def __init__(self):
        self.host = os.getenv('DB_HOST', 'localhost')
        self.port = int(os.getenv('DB_PORT', 5432))
        self.database = os.getenv('DB_NAME')  # Required
        self.username = os.getenv('DB_USER')  # Required
        self.password = os.getenv('DB_PASSWORD')  # Required

        # Pool sizing based on load testing results
        self.pool_size = int(os.getenv('DB_POOL_SIZE', 15))  # Peak 12 + 25% headroom
        self.max_overflow = int(os.getenv('DB_MAX_OVERFLOW', 5))
        self.pool_timeout = int(os.getenv('DB_POOL_TIMEOUT', 30))

    def to_url(self):
        return f"postgresql://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}"

# Testing pool under load
def test_pool_concurrency():
    import concurrent.futures
    import threading

    db = DatabaseManager(DATABASE_URL)

    def worker():
        with db.get_connection() as conn:
            result = conn.execute("SELECT pg_sleep(0.1), 1").scalar()
            return result

    # Test with multiple concurrent connections
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
        futures = [executor.submit(worker) for _ in range(50)]
        results = [f.result() for f in concurrent.futures.as_completed(futures)]

    # Verify pool handled load correctly
    stats = db.get_pool_status()
    assert stats['stats']['checked_out'] == stats['stats']['checked_in']

    db.close()
```

## Examples

```python
# ❌ BAD: Default configuration, no monitoring, resource leaks
from sqlalchemy import create_engine

# Uses defaults - no explicit sizing, timeouts, or monitoring
engine = create_engine(DATABASE_URL)

def get_users():
    # No resource management, potential connection leaks
    conn = engine.connect()
    result = conn.execute("SELECT * FROM users").fetchall()
    # Connection never explicitly returned to pool
    return result

# ✅ GOOD: Explicit configuration with proper resource management
from contextlib import contextmanager
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Explicit configuration based on load testing results
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,                    # Measured peak: 8 concurrent connections
    max_overflow=5,                  # Limited overflow for spikes
    pool_timeout=30,                 # Fail fast - 30 second timeout
    pool_recycle=3600,               # Prevent stale connections
    pool_pre_ping=True               # Validate connections before use
)

@contextmanager
def get_connection():
    """Safe connection management with guaranteed cleanup."""
    conn = None
    try:
        conn = engine.connect()
        yield conn
    except Exception as e:
        logger.error(f"Database operation failed: {e}")
        if conn:
            conn.rollback()
        raise
    finally:
        if conn:
            conn.close()  # Always return to pool

def get_users():
    """Proper resource management with monitoring."""
    with get_connection() as conn:
        result = conn.execute("SELECT * FROM users").fetchall()
        # Log pool health for monitoring
        logger.info(f"Query completed, pool stats: {engine.pool.status()}")
        return result

def health_check():
    """Simple health check with timeout."""
    try:
        with get_connection() as conn:
            conn.execute("SELECT 1").scalar()
            return True
    except Exception:
        return False
```

## Related Bindings

- [external-configuration](../../core/external-configuration.md): Pool settings must be externally configurable for environment-specific tuning without code changes.

- [use-structured-logging](../../core/use-structured-logging.md): Pool monitoring requires structured logging to track utilization and detect leaks.

- [fail-fast-validation](../../core/fail-fast-validation.md): Pools should fail fast when exhausted rather than queuing indefinitely to prevent cascade failures.
