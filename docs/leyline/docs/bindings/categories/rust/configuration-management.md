---
id: configuration-management
last_modified: '2025-06-03'
version: '0.1.0'
derived_from: adaptability-and-reversibility
enforced_by: 'Cargo features, serde configuration, environment validation, code review'
---
# Binding: Enable Adaptable Systems Through Rust's Configuration and Feature Management

Design systems that can adapt to changing requirements without code changes by leveraging Rust's powerful configuration management, feature flags, and conditional compilation capabilities. Build applications that can be configured for different environments, use cases, and deployment scenarios while maintaining type safety and performance.

## Rationale

This binding implements adaptability-and-reversibility by using Rust's configuration capabilities to make decisions reversible without code changes. Configuration management works like designing a Swiss Army knife—each feature can be deployed or retracted based on context.

Rust's type system and feature management provide compile-time safety, ensuring you can't accidentally enable incompatible features or deploy with invalid configurations.

## Rule Definition

Configuration management patterns must establish these Rust-specific practices:

- **Compile-Time Feature Selection**: Use Cargo features to enable/disable functionality at compile time, creating optimized binaries for specific use cases without runtime overhead.
- **Type-Safe Runtime Configuration**: Define configuration structures using serde and strong typing to ensure invalid configurations are caught early and configuration access is safe.
- **Environment-Specific Builds**: Structure feature flags and configuration to support different deployment environments (development, staging, production) with appropriate defaults and validation.
- **Gradual Feature Rollouts**: Implement feature flag patterns that enable safe, gradual deployment of new functionality with the ability to roll back without code changes.
- **Configuration Composition**: Design configuration systems that can be layered (default → environment → user-specific) while maintaining type safety and validation.
- **Build-Time Optimization**: Use conditional compilation to eliminate unused code paths entirely from production builds, ensuring zero runtime cost for disabled features.

**Feature Management Patterns:**
- Optional dependencies through Cargo features
- Conditional compilation with `cfg` attributes
- Feature flag runtime toggles
- Environment-specific configuration loading
- Default configuration with override patterns

**Configuration Sources:**
- Cargo.toml feature definitions
- Environment variables (12-factor app compliance)
- Configuration files (TOML, JSON, YAML)
- Command-line arguments
- Default values with fallbacks

## Practical Implementation

1. **Design Cargo Features for Optional Functionality**: Use features to create adaptable build configurations:

   ```toml
   # Cargo.toml
   [features]
   default = ["web-server", "database-sqlite"]
   web-server = ["axum", "tower"]
   grpc-server = ["tonic", "prost"]
   database-sqlite = ["sqlx/sqlite"]
   database-postgres = ["sqlx/postgres"]
   auth-jwt = ["jsonwebtoken"]
   metrics-prometheus = ["prometheus"]

   [dependencies]
   serde = { version = "1.0", features = ["derive"] }
   axum = { version = "0.7", optional = true }
   sqlx = { version = "0.7", optional = true }
   prometheus = { version = "0.13", optional = true }
   ```

   ```rust
   // Conditional compilation based on features
   #[derive(Debug, Clone)]
   pub struct ServerConfig {
       pub host: String,
       pub port: u16,
       #[cfg(feature = "web-server")]
       pub web: WebServerConfig,
   }

   #[cfg(feature = "web-server")]
   #[derive(Debug, Clone)]
   pub struct WebServerConfig {
       pub max_connections: usize,
       pub request_timeout: Duration,
   }

   // Database configuration with compile-time selection
   #[derive(Debug, Clone)]
   pub enum DatabaseConfig {
       #[cfg(feature = "database-sqlite")]
       Sqlite { path: String, max_connections: u32 },
       #[cfg(feature = "database-postgres")]
       Postgres { url: String, max_connections: u32 },
   }
   ```

2. **Implement Type-Safe Runtime Configuration**: Create robust configuration loading with validation:

   ```rust
   use serde::{Deserialize, Serialize};
   use std::time::Duration;

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct AppConfig {
       pub environment: Environment,
       pub server: ServerConfig,
       pub database: DatabaseConfig,
       pub features: FeatureFlags,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub enum Environment {
       Development,
       Staging,
       Production,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct ServerConfig {
       pub host: String,
       pub port: u16,
       pub request_timeout: Duration,
       pub max_connections: usize,
   }

   impl AppConfig {
       pub fn load() -> Result<Self, ConfigError> {
           let settings = config::Config::builder()
               .add_source(config::File::with_name("config/default"))
               .add_source(config::Environment::with_prefix("APP"))
               .build()?;

           let app_config: AppConfig = settings.try_deserialize()?;
           app_config.validate()?;
           Ok(app_config)
       }

       fn validate(&self) -> Result<(), ConfigError> {
           if matches!(self.environment, Environment::Production)
               && self.server.host == "127.0.0.1" {
               return Err(ConfigError::Message(
                   "Production host cannot be localhost".to_string()
               ));
           }
           Ok(())
       }
   }
   ```

3. **Create Feature Flag Systems for Runtime Adaptability**: Implement feature flags that can be toggled without restarts:

   ```rust
   #[derive(Debug, Clone)]
   pub struct FeatureFlagManager {
       flags: Arc<RwLock<HashMap<String, bool>>>,
   }

   impl FeatureFlagManager {
       pub async fn new(config: &AppConfig) -> Self {
           let mut flags = HashMap::new();
           flags.insert("new_user_onboarding".to_string(), config.features.new_user_onboarding);
           flags.insert("experimental_search".to_string(), config.features.experimental_search);

           Self {
               flags: Arc::new(RwLock::new(flags)),
           }
       }

       pub async fn is_enabled(&self, flag_name: &str) -> bool {
           let flags = self.flags.read().await;
           flags.get(flag_name).copied().unwrap_or(false)
       }

       pub async fn set_flag(&self, flag_name: &str, enabled: bool) {
           let mut flags = self.flags.write().await;
           flags.insert(flag_name.to_string(), enabled);
       }
   }

   // Usage in application code
   pub async fn handle_search_request(
       manager: &FeatureFlagManager,
       query: String,
   ) -> SearchResult {
       if manager.is_enabled("experimental_search").await {
           experimental_search(query).await
       } else {
           standard_search(query).await
       }
   }
   ```

4. **Design Environment-Specific Configuration Patterns**: Create configuration that adapts to deployment environments:

   ```rust
   impl AppConfig {
       pub fn for_environment(env: Environment) -> Self {
           match env {
               Environment::Development => Self {
                   environment: env,
                   server: ServerConfig {
                       host: "127.0.0.1".to_string(),
                       port: 8080,
                       request_timeout: Duration::from_secs(30),
                       max_connections: 100,
                   },
                   database: DatabaseConfig::Sqlite {
                       path: "./dev.db".to_string(),
                       max_connections: 10,
                   },
                   features: FeatureFlags {
                       new_user_onboarding: true,
                       experimental_search: true,
                   },
               },
               Environment::Production => Self {
                   environment: env,
                   server: ServerConfig {
                       host: "0.0.0.0".to_string(),
                       port: 80,
                       request_timeout: Duration::from_secs(30),
                       max_connections: 1000,
                   },
                   database: DatabaseConfig::Postgres {
                       url: std::env::var("DATABASE_URL").expect("DATABASE_URL required"),
                       max_connections: 50,
                   },
                   features: FeatureFlags {
                       new_user_onboarding: false,
                       experimental_search: false,
                   },
               },
               _ => unreachable!(),
           }
       }
   }
   ```

## Examples

```rust
// ❌ BAD: Hardcoded configuration mixed throughout codebase
pub struct WebServer {
    port: u16,
}

impl WebServer {
    pub fn new() -> Self {
        Self {
            port: 8080, // Hardcoded
        }
    }

    pub async fn start(&self) {
        let cors = if cfg!(debug_assertions) {
            CorsLayer::permissive() // Hardcoded debug behavior
        } else {
            CorsLayer::new() // Different production behavior
        };

        let app = Router::new()
            .route("/health", get(health_check))
            .layer(cors);

        axum::Server::bind(&format!("127.0.0.1:{}", self.port).parse().unwrap())
            .serve(app.into_make_service())
            .await
            .unwrap();
    }
}
```

```rust
// ✅ GOOD: Feature-gated compilation for optimized builds
// Cargo.toml
[features]
default = ["web-server", "database-postgres", "auth-jwt"]

// Server types
web-server = ["axum", "tower"]
grpc-server = ["tonic", "prost"]

// Database backends (choose one)
database-postgres = ["sqlx/postgres"]
database-sqlite = ["sqlx/sqlite"]
database-mysql = ["sqlx/mysql"]

// Authentication (choose one or more)
auth-jwt = ["jsonwebtoken"]
auth-oauth = ["oauth2"]

[dependencies]
// Core dependencies
serde = { version = "1.0", features = ["derive"] }
tokio = "1.0"

// Optional dependencies
axum = { version = "0.7", optional = true }
tonic = { version = "0.10", optional = true }
sqlx = { version = "0.7", optional = true }

// Conditional compilation based on features
#[cfg(any(feature = "auth-jwt", feature = "auth-oauth"))]
pub enum AuthProvider {
    #[cfg(feature = "auth-jwt")]
    Jwt(JwtAuth),

    #[cfg(feature = "auth-oauth")]
    OAuth(OAuthAuth),
}

// Build examples:
// Minimal microservice: cargo build --no-default-features --features="web-server,database-sqlite,auth-jwt"
// Full-featured service: cargo build --features="web-server,grpc-server,database-postgres,auth-oauth"

// Benefits:
// - Smaller binaries with only needed features
// - Faster compilation by excluding unused dependencies
// - Reduced attack surface by excluding unused code
// - Optimized for specific deployment scenarios
// - Zero runtime cost for disabled features
```

## Related Bindings

- [centralized-configuration.md](../../core/centralized-configuration.md): Rust configuration management implements centralized configuration principles through type-safe config loading and validation. Both bindings work together to ensure configuration is authoritative, validated, and consistently applied across the system.

- [error-handling.md](../../docs/bindings/categories/rust/error-handling.md): Configuration management requires robust error handling for invalid configs, missing environment variables, and validation failures. Rust's Result types and error handling patterns ensure configuration problems are caught early and reported clearly.

- [flexible-architecture-patterns.md](../../core/flexible-architecture-patterns.md): Configuration-driven behavior is a key component of flexible architecture. This binding provides the Rust-specific mechanisms for implementing runtime adaptability through feature flags and environment-specific builds.

- [adaptability-and-reversibility.md](../../tenets/adaptability-and-reversibility.md): This binding directly implements the adaptability-and-reversibility tenet by using Rust's configuration and feature systems to make decisions reversible without code changes. Feature flags, environment-specific configs, and conditional compilation enable systems that can adapt to changing requirements while maintaining type safety and performance.
