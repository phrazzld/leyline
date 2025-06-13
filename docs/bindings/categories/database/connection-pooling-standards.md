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

This binding directly implements our simplicity tenet by ensuring that database
connection management remains predictable and maintainable. Database connections
are expensive resources that require careful management—creating them is slow,
keeping too many idle wastes memory, and having too few creates bottlenecks.
Connection pooling solves this problem, but only when configured simply and
explicitly based on real application needs.

Think of a connection pool like a parking garage for a busy office building.
You need enough spaces for peak usage, but not so many that you're wasting
valuable real estate. You also need clear policies: how long can a car stay
parked? When do you know a space is actually available versus just temporarily
occupied? What happens when the garage is full? A simple, well-managed garage
with clear rules works smoothly, while an over-engineered system with complex
adaptive policies often creates more problems than it solves.

The complexity of modern applications makes simple connection pooling especially
important. When you have microservices, auto-scaling, and variable load patterns,
you need connection pool behavior that you can reason about and predict. Complex
pooling algorithms that try to be "smart" often become sources of mysterious
performance issues and resource exhaustion. Simple, explicitly configured pools
with good monitoring provide the reliability and predictability that production
systems demand.

## Rule Definition

Simple connection pooling means configuring pools with explicit, static settings
based on measured application behavior rather than relying on adaptive algorithms
or default configurations. This requires understanding your application's
connection usage patterns and setting clear boundaries.

Key principles for connection pooling:

- **Size Based on Load**: Set pool sizes based on actual measured concurrency, not guesswork
- **Explicit Timeouts**: Configure connection and idle timeouts explicitly for your use case
- **Health Monitoring**: Implement connection validation and monitoring to detect issues early
- **Fail Fast**: Configure pools to fail quickly rather than queuing indefinitely
- **Resource Cleanup**: Ensure connections are properly returned and cleaned up

Common patterns this binding requires:

- Measuring actual concurrent connection usage before setting pool sizes
- Setting explicit timeout values for connection acquisition and idle time
- Implementing connection validation queries for health checks
- Configuring maximum wait times rather than unlimited queuing
- Monitoring pool utilization and connection lifecycle metrics

What this explicitly prohibits:

- Using default pool configurations without understanding their implications
- Implementing complex adaptive pooling algorithms
- Setting pool sizes based on speculation rather than measurement
- Ignoring connection leaks or resource cleanup issues
- Relying on unlimited connection queuing as a solution

## Practical Implementation

1. **Size Pools Based on Measured Concurrency**: Determine your actual concurrent
   connection needs through load testing and monitoring, then set explicit limits
   with some headroom for spikes.

   ```java
   // Java with HikariCP - explicit configuration based on measurements
   @Configuration
   public class DatabaseConfig {

       @Bean
       public DataSource dataSource() {
           HikariConfig config = new HikariConfig();

           // Measured: Peak concurrent queries = 15, average = 8
           // Calculation: 15 * 1.5 (headroom) = 22, round down for simplicity
           config.setMaximumPoolSize(20);
           config.setMinimumIdle(5);  // Keep some connections ready

           // Connection lifecycle - explicit timeouts
           config.setConnectionTimeout(10000);    // 10 seconds max wait
           config.setIdleTimeout(300000);         // 5 minutes idle timeout
           config.setMaxLifetime(1800000);        // 30 minutes max connection age

           // Health checks - simple validation
           config.setConnectionTestQuery("SELECT 1");
           config.setValidationTimeout(5000);     // 5 second validation timeout

           // Fail fast rather than queue indefinitely
           config.setLeakDetectionThreshold(60000); // Detect leaks after 1 minute

           // Monitoring and observability
           config.setRegisterMbeans(true);
           config.setPoolName("MainPool");

           config.setJdbcUrl(environment.getProperty("database.url"));
           config.setUsername(environment.getProperty("database.username"));
           config.setPassword(environment.getProperty("database.password"));

           return new HikariDataSource(config);
       }
   }
   ```

2. **Implement Connection Health Monitoring**: Set up monitoring to track pool
   utilization, connection health, and potential leaks. Make pool performance
   visible to operations teams.

   ```python
   # Python with SQLAlchemy - explicit pool configuration and monitoring
   import time
   import logging
   from sqlalchemy import create_engine, event
   from sqlalchemy.pool import QueuePool

   logger = logging.getLogger('connection_pool')

   class PoolMonitor:
       def __init__(self):
           self.pool_stats = {
               'created': 0,
               'closed': 0,
               'checked_out': 0,
               'checked_in': 0,
               'leaked': 0
           }

       def track_connection_created(self, dbapi_connection, connection_record):
           self.pool_stats['created'] += 1
           logger.info("Connection created", extra={
               'total_created': self.pool_stats['created'],
               'connection_id': id(dbapi_connection)
           })

       def track_connection_checked_out(self, dbapi_connection, connection_record, connection_proxy):
           self.pool_stats['checked_out'] += 1
           connection_record.checkout_time = time.time()

       def track_connection_checked_in(self, dbapi_connection, connection_record):
           self.pool_stats['checked_in'] += 1
           if hasattr(connection_record, 'checkout_time'):
               duration = time.time() - connection_record.checkout_time
               if duration > 60:  # Log long-running connections
                   logger.warning("Long-running connection detected", extra={
                       'duration': duration,
                       'connection_id': id(dbapi_connection)
                   })

   def create_database_engine():
       # Explicit pool configuration based on load testing
       # Results: 95th percentile concurrent connections = 12
       engine = create_engine(
           DATABASE_URL,
           poolclass=QueuePool,
           pool_size=15,                    # Slightly above measured peak
           max_overflow=5,                  # Limited overflow for spikes
           pool_timeout=30,                 # Fail after 30 seconds
           pool_recycle=3600,               # Recycle connections after 1 hour
           pool_pre_ping=True,              # Validate connections before use
           connect_args={
               "connect_timeout": 10,        # 10 second connection timeout
               "application_name": "MyApp"   # For monitoring/debugging
           }
       )

       # Set up monitoring
       monitor = PoolMonitor()
       event.listen(engine, 'connect', monitor.track_connection_created)
       event.listen(engine, 'checkout', monitor.track_connection_checked_out)
       event.listen(engine, 'checkin', monitor.track_connection_checked_in)

       return engine
   ```

3. **Configure Explicit Resource Cleanup**: Implement patterns that ensure
   connections are always returned to the pool, even in error conditions. Use
   language-specific resource management idioms.

   ```javascript
   // Node.js with pg-pool - proper resource management
   const { Pool } = require('pg');
   const logger = require('./logger');

   class DatabasePool {
       constructor() {
           // Explicit configuration based on application profiling
           this.pool = new Pool({
               host: process.env.DB_HOST,
               port: process.env.DB_PORT,
               database: process.env.DB_NAME,
               user: process.env.DB_USER,
               password: process.env.DB_PASSWORD,

               // Pool sizing based on measured load
               min: 2,                      // Keep minimum connections ready
               max: 10,                     // Maximum concurrent connections

               // Explicit timeouts
               connectionTimeoutMillis: 5000,    // 5 second connection timeout
               idleTimeoutMillis: 30000,         // 30 second idle timeout
               query_timeout: 10000,             // 10 second query timeout

               // Health checks
               allowExitOnIdle: false,
               statement_timeout: false
           });

           this.setupMonitoring();
       }

       setupMonitoring() {
           // Monitor pool events for debugging and alerting
           this.pool.on('connect', (client) => {
               logger.info('Database connection established', {
                   total_connections: this.pool.totalCount,
                   idle_connections: this.pool.idleCount,
                   waiting_requests: this.pool.waitingCount
               });
           });

           this.pool.on('error', (err, client) => {
               logger.error('Database pool error', { error: err.message });
           });

           // Regular health monitoring
           setInterval(() => {
               const stats = {
                   total: this.pool.totalCount,
                   idle: this.pool.idleCount,
                   waiting: this.pool.waitingCount
               };

               // Alert if pool is consistently full
               if (stats.waiting > 0) {
                   logger.warn('Connection pool backlog detected', stats);
               }

               // Alert if no idle connections (potential sizing issue)
               if (stats.total > 0 && stats.idle === 0) {
                   logger.warn('No idle connections available', stats);
               }
           }, 30000);  // Check every 30 seconds
       }

       // Proper resource management with automatic cleanup
       async withConnection(callback) {
           const client = await this.pool.connect();
           try {
               return await callback(client);
           } finally {
               client.release();  // Always return connection to pool
           }
       }

       // Transaction management with guaranteed cleanup
       async withTransaction(callback) {
           return this.withConnection(async (client) => {
               await client.query('BEGIN');
               try {
                   const result = await callback(client);
                   await client.query('COMMIT');
                   return result;
               } catch (error) {
                   await client.query('ROLLBACK');
                   throw error;
               }
           });
       }
   }

   module.exports = new DatabasePool();
   ```

4. **External Configuration Management**: Make all pool settings configurable
   externally so they can be tuned for different environments without code changes.
   Document the reasoning behind each setting.

   ```go
   // Go with database/sql - external configuration
   package database

   import (
       "database/sql"
       "fmt"
       "log"
       "time"

       _ "github.com/lib/pq"
   )

   type PoolConfig struct {
       // Connection settings
       Host     string `env:"DB_HOST" default:"localhost"`
       Port     int    `env:"DB_PORT" default:"5432"`
       Database string `env:"DB_NAME" required:"true"`
       Username string `env:"DB_USER" required:"true"`
       Password string `env:"DB_PASSWORD" required:"true"`

       // Pool sizing - document reasoning
       MaxOpenConns int `env:"DB_MAX_OPEN_CONNS" default:"25"` // Based on load testing: peak 20 + 25% headroom
       MaxIdleConns int `env:"DB_MAX_IDLE_CONNS" default:"5"`  // Keep some ready for quick response

       // Timeouts - explicit for each environment
       ConnMaxLifetime time.Duration `env:"DB_CONN_MAX_LIFETIME" default:"30m"` // Prevent stale connections
       ConnMaxIdleTime time.Duration `env:"DB_CONN_MAX_IDLE_TIME" default:"5m"`  // Free up idle resources
   }

   func NewDatabase(config PoolConfig) (*sql.DB, error) {
       dsn := fmt.Sprintf(
           "host=%s port=%d dbname=%s user=%s password=%s sslmode=require",
           config.Host, config.Port, config.Database, config.Username, config.Password,
       )

       db, err := sql.Open("postgres", dsn)
       if err != nil {
           return nil, fmt.Errorf("failed to open database: %w", err)
       }

       // Apply explicit pool configuration
       db.SetMaxOpenConns(config.MaxOpenConns)
       db.SetMaxIdleConns(config.MaxIdleConns)
       db.SetConnMaxLifetime(config.ConnMaxLifetime)
       db.SetConnMaxIdleTime(config.ConnMaxIdleTime)

       // Validate configuration with ping
       if err := db.Ping(); err != nil {
           return nil, fmt.Errorf("failed to ping database: %w", err)
       }

       log.Printf("Database pool configured: max_open=%d, max_idle=%d, max_lifetime=%v",
           config.MaxOpenConns, config.MaxIdleConns, config.ConnMaxLifetime)

       return db, nil
   }

   // Connection stats for monitoring
   func LogPoolStats(db *sql.DB) {
       stats := db.Stats()
       log.Printf("Pool stats: open=%d, idle=%d, in_use=%d, wait_count=%d, wait_duration=%v",
           stats.OpenConnections,
           stats.Idle,
           stats.InUse,
           stats.WaitCount,
           stats.WaitDuration,
       )

       // Alert on concerning metrics
       if stats.WaitCount > 0 {
           log.Printf("WARNING: Connection pool waiting detected, consider increasing pool size")
       }

       if float64(stats.InUse)/float64(stats.OpenConnections) > 0.8 {
           log.Printf("WARNING: Pool utilization high (%.1f%%), monitor for capacity issues",
               float64(stats.InUse)/float64(stats.OpenConnections)*100)
       }
   }
   ```

5. **Implement Health Checks and Circuit Breaking**: Add health monitoring
   that can detect connection issues and take protective action before they
   cascade into system-wide failures.

   ```csharp
   // C# with Entity Framework Core - health monitoring
   using Microsoft.EntityFrameworkCore;
   using Microsoft.Extensions.Diagnostics.HealthChecks;
   using Microsoft.Extensions.Logging;

   public class DatabaseHealthCheck : IHealthCheck
   {
       private readonly AppDbContext _context;
       private readonly ILogger<DatabaseHealthCheck> _logger;

       public DatabaseHealthCheck(AppDbContext context, ILogger<DatabaseHealthCheck> logger)
       {
           _context = context;
           _logger = logger;
       }

       public async Task<HealthCheckResult> CheckHealthAsync(
           HealthCheckContext context,
           CancellationToken cancellationToken = default)
       {
           try
           {
               // Simple health check query with timeout
               using var command = _context.Database.GetDbConnection().CreateCommand();
               command.CommandText = "SELECT 1";
               command.CommandTimeout = 5; // 5 second timeout

               await _context.Database.OpenConnectionAsync(cancellationToken);
               var result = await command.ExecuteScalarAsync(cancellationToken);

               return HealthCheckResult.Healthy("Database connection successful");
           }
           catch (Exception ex)
           {
               _logger.LogError(ex, "Database health check failed");
               return HealthCheckResult.Unhealthy(
                   "Database connection failed",
                   ex,
                   new Dictionary<string, object>
                   {
                       ["exception"] = ex.Message,
                       ["timestamp"] = DateTime.UtcNow
                   });
           }
           finally
           {
               await _context.Database.CloseConnectionAsync();
           }
       }
   }

   // Startup configuration
   public void ConfigureServices(IServiceCollection services)
   {
       services.AddDbContext<AppDbContext>(options =>
       {
           options.UseNpgsql(connectionString, npgsqlOptions =>
           {
               // Explicit connection settings
               npgsqlOptions.CommandTimeout(30);
               npgsqlOptions.EnableRetryOnFailure(
                   maxRetryCount: 3,
                   maxRetryDelay: TimeSpan.FromSeconds(5),
                   errorCodesToAdd: null);
           });

           // Pool configuration through connection string parameters
           // Example: "Host=localhost;Database=mydb;Username=user;Password=pass;Maximum Pool Size=20;Connection Idle Lifetime=300"
       });

       services.AddHealthChecks()
           .AddCheck<DatabaseHealthCheck>("database");
   }
   ```

## Examples

```python
# ❌ BAD: Default configuration without understanding
from sqlalchemy import create_engine

# Uses SQLAlchemy defaults - no explicit sizing or timeouts
engine = create_engine(DATABASE_URL)

# No monitoring, no health checks, no resource management
def get_data():
    with engine.connect() as conn:
        return conn.execute("SELECT * FROM users").fetchall()

# ✅ GOOD: Explicit configuration based on measurements
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool
import logging

logger = logging.getLogger(__name__)

# Configuration based on load testing results
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,                    # Measured peak: 8 concurrent connections
    max_overflow=5,                  # Allow limited overflow for spikes
    pool_timeout=30,                 # Fail fast rather than wait indefinitely
    pool_recycle=3600,               # Prevent stale connections
    pool_pre_ping=True,              # Validate before use
    echo_pool=True                   # Log pool events for monitoring
)

def get_data():
    try:
        with engine.connect() as conn:
            result = conn.execute("SELECT * FROM users").fetchall()
            logger.info(f"Query successful, pool stats: {engine.pool.status()}")
            return result
    except Exception as e:
        logger.error(f"Database query failed: {e}")
        raise
```

```java
// ❌ BAD: Unclear configuration with potential resource leaks
@Bean
public DataSource dataSource() {
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl(jdbcUrl);
    config.setUsername(username);
    config.setPassword(password);
    // Using defaults - unclear what they are or if they're appropriate
    return new HikariDataSource(config);
}

// Manual connection management prone to leaks
public List<User> getUsers() {
    Connection conn = dataSource.getConnection();
    PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users");
    ResultSet rs = stmt.executeQuery();
    // Missing finally block - resources may leak on exceptions
    return processResults(rs);
}

// ✅ GOOD: Explicit configuration with proper resource management
@Bean
public DataSource dataSource() {
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl(jdbcUrl);
    config.setUsername(username);
    config.setPassword(password);

    // Explicit configuration based on application profiling
    config.setMaximumPoolSize(15);          // Based on load test: 12 peak + 25% margin
    config.setMinimumIdle(3);               // Keep some ready for fast response
    config.setConnectionTimeout(10_000);    // 10 second max wait
    config.setIdleTimeout(300_000);         // 5 minute idle timeout
    config.setMaxLifetime(1_800_000);       // 30 minute max age
    config.setLeakDetectionThreshold(60_000); // Detect leaks after 1 minute

    // Health and monitoring
    config.setConnectionTestQuery("SELECT 1");
    config.setRegisterMbeans(true);
    config.setPoolName("MainPool");

    return new HikariDataSource(config);
}

// Proper resource management with try-with-resources
public List<User> getUsers() {
    String sql = "SELECT * FROM users";
    try (Connection conn = dataSource.getConnection();
         PreparedStatement stmt = conn.prepareStatement(sql);
         ResultSet rs = stmt.executeQuery()) {

        return processResults(rs);
    } catch (SQLException e) {
        logger.error("Failed to fetch users", e);
        throw new DatabaseException("User query failed", e);
    }
}
```

```javascript
// ❌ BAD: No connection pooling or resource management
const { Client } = require('pg');

// Creates new connection for every request - very inefficient
async function getUser(id) {
    const client = new Client({
        connectionString: process.env.DATABASE_URL
    });

    await client.connect();
    const result = await client.query('SELECT * FROM users WHERE id = $1', [id]);
    await client.end();  // May not run if query throws

    return result.rows[0];
}

// ✅ GOOD: Proper pooling with resource management
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    // Explicit configuration based on application needs
    min: 2,                          // Keep minimum ready
    max: 8,                          // Based on measured concurrency
    connectionTimeoutMillis: 5000,   // 5 second connection timeout
    idleTimeoutMillis: 30000,        // 30 second idle timeout
    allowExitOnIdle: false
});

// Monitor pool health
pool.on('error', (err) => {
    console.error('Database pool error:', err);
});

// Proper resource management with automatic cleanup
async function getUser(id) {
    const client = await pool.connect();
    try {
        const result = await client.query('SELECT * FROM users WHERE id = $1', [id]);
        return result.rows[0];
    } catch (error) {
        console.error('Query failed:', error);
        throw error;
    } finally {
        client.release(); // Always return to pool
    }
}

// Graceful shutdown
process.on('SIGINT', async () => {
    await pool.end();
    process.exit(0);
});
```

## Related Bindings

- [external-configuration](../../core/external-configuration.md): Connection pool
  settings must be externally configurable rather than hardcoded. This allows for
  environment-specific tuning based on different load patterns and resource constraints
  without requiring code changes.

- [use-structured-logging](../../core/use-structured-logging.md): Connection pool
  monitoring requires structured logging to track utilization, detect leaks, and
  correlate performance issues with pool configuration. Both bindings work together
  to create observable, well-managed database connections.

- [fail-fast-validation](../../core/fail-fast-validation.md): Connection pools
  should be configured to fail fast when resources are exhausted rather than
  queuing requests indefinitely. This prevents cascade failures and makes resource
  limits explicit and actionable.
