---
id: configuration-management
last_modified: '2025-06-03'
derived_from: adaptability-and-reversibility
enforced_by: 'Cargo features, serde configuration, environment validation, code review'
---

# Binding: Enable Adaptable Systems Through Rust's Configuration and Feature Management

Design systems that can adapt to changing requirements without code changes by leveraging Rust's powerful configuration management, feature flags, and conditional compilation capabilities. Build applications that can be configured for different environments, use cases, and deployment scenarios while maintaining type safety and performance.

## Rationale

This binding implements our adaptability-and-reversibility tenet by using Rust's configuration capabilities to make decisions reversible and systems adaptable to change. In software systems, requirements evolve, deployment environments differ, and business needs shift. Rather than hardcoding decisions into the application logic, well-designed configuration systems allow you to modify behavior without touching the codebase.

Think of configuration management like designing a Swiss Army knife. Each tool (feature) can be deployed or retracted based on the situation you're facing. You don't need a different knife for every possible scenario—you have one tool that adapts to different contexts. Similarly, Rust's configuration systems let you build one codebase that can adapt to different environments, feature sets, and operational requirements. Cargo features act like the individual tools that can be enabled or disabled, while runtime configuration acts like the settings that determine how each tool behaves.

Without proper configuration management, applications become like single-purpose tools that require recompilation or code changes for different use cases. This leads to code branching, deployment complexity, and the inability to respond quickly to changing requirements. Rust's type system and feature management provide the safety net that ensures your adaptable system remains reliable—you can't accidentally enable incompatible features or deploy with invalid configurations because the compiler and type system catch these errors at build time.

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
   [package]
   name = "my-service"
   version = "0.1.0"
   edition = "2021"

   [features]
   default = ["web-server", "database-sqlite"]

   # Core features
   web-server = ["axum", "tower", "tokio/full"]
   grpc-server = ["tonic", "prost", "tokio/full"]

   # Database backends (mutually exclusive)
   database-sqlite = ["sqlx/sqlite"]
   database-postgres = ["sqlx/postgres", "sqlx/uuid"]
   database-mysql = ["sqlx/mysql"]

   # Authentication providers
   auth-jwt = ["jsonwebtoken", "serde_json"]
   auth-oauth = ["oauth2", "reqwest"]
   auth-saml = ["saml2"]

   # Observability
   metrics-prometheus = ["prometheus", "metrics"]
   metrics-datadog = ["datadog-statsd", "metrics"]
   tracing-jaeger = ["opentelemetry", "opentelemetry-jaeger"]
   tracing-zipkin = ["opentelemetry", "opentelemetry-zipkin"]

   # Performance optimizations
   jemalloc = ["jemallocator"]
   mimalloc = ["mimalloc"]

   # Development features
   dev-tools = ["console-subscriber", "tokio-console"]
   hot-reload = ["notify", "async-watch"]

   [dependencies]
   serde = { version = "1.0", features = ["derive"] }
   config = "0.13"

   # Optional dependencies enabled by features
   axum = { version = "0.7", optional = true }
   tower = { version = "0.4", optional = true }
   tonic = { version = "0.10", optional = true }
   prost = { version = "0.12", optional = true }
   sqlx = { version = "0.7", features = ["runtime-tokio"], optional = true }
   jsonwebtoken = { version = "9.0", optional = true }
   prometheus = { version = "0.13", optional = true }
   jemallocator = { version = "0.5", optional = true }
   ```

   ```rust
   // ✅ GOOD: Conditional compilation based on features

   // Server configuration based on enabled features
   #[derive(Debug, Clone)]
   pub struct ServerConfig {
       pub host: String,
       pub port: u16,
       #[cfg(feature = "web-server")]
       pub web: WebServerConfig,
       #[cfg(feature = "grpc-server")]
       pub grpc: GrpcServerConfig,
   }

   #[cfg(feature = "web-server")]
   #[derive(Debug, Clone)]
   pub struct WebServerConfig {
       pub max_connections: usize,
       pub request_timeout: Duration,
       pub cors_origins: Vec<String>,
   }

   #[cfg(feature = "grpc-server")]
   #[derive(Debug, Clone)]
   pub struct GrpcServerConfig {
       pub max_message_size: usize,
       pub keepalive_interval: Duration,
       pub tls_config: Option<TlsConfig>,
   }

   // Database configuration with compile-time selection
   #[derive(Debug, Clone)]
   pub enum DatabaseConfig {
       #[cfg(feature = "database-sqlite")]
       Sqlite {
           path: String,
           max_connections: u32,
       },
       #[cfg(feature = "database-postgres")]
       Postgres {
           url: String,
           max_connections: u32,
           ssl_mode: String,
       },
       #[cfg(feature = "database-mysql")]
       Mysql {
           url: String,
           max_connections: u32,
       },
   }

   // Authentication configuration
   #[derive(Debug, Clone)]
   pub struct AuthConfig {
       #[cfg(feature = "auth-jwt")]
       pub jwt: Option<JwtConfig>,
       #[cfg(feature = "auth-oauth")]
       pub oauth: Option<OAuthConfig>,
       #[cfg(feature = "auth-saml")]
       pub saml: Option<SamlConfig>,
   }

   #[cfg(feature = "auth-jwt")]
   #[derive(Debug, Clone)]
   pub struct JwtConfig {
       pub secret: String,
       pub expiration: Duration,
       pub issuer: String,
   }

   // Global allocator selection
   #[cfg(feature = "jemalloc")]
   #[global_allocator]
   static ALLOC: jemallocator::Jemalloc = jemallocator::Jemalloc;

   #[cfg(feature = "mimalloc")]
   #[global_allocator]
   static ALLOC: mimalloc::MiMalloc = mimalloc::MiMalloc;
   ```

2. **Implement Type-Safe Runtime Configuration**: Create robust configuration loading with validation:

   ```rust
   // ✅ GOOD: Type-safe configuration with serde and validation

   use serde::{Deserialize, Serialize};
   use std::time::Duration;
   use std::path::PathBuf;

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct AppConfig {
       #[serde(default = "default_environment")]
       pub environment: Environment,

       #[serde(default)]
       pub server: ServerConfig,

       #[serde(default)]
       pub database: DatabaseConfig,

       #[serde(default)]
       pub auth: AuthConfig,

       #[serde(default)]
       pub logging: LoggingConfig,

       #[serde(default)]
       pub features: FeatureFlags,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   #[serde(rename_all = "lowercase")]
   pub enum Environment {
       Development,
       Staging,
       Production,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct ServerConfig {
       #[serde(default = "default_host")]
       pub host: String,

       #[serde(default = "default_port")]
       pub port: u16,

       #[serde(default = "default_workers")]
       pub workers: usize,

       #[serde(with = "serde_duration")]
       #[serde(default = "default_timeout")]
       pub request_timeout: Duration,

       #[serde(default)]
       pub cors_origins: Vec<String>,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct FeatureFlags {
       #[serde(default)]
       pub new_user_onboarding: bool,

       #[serde(default)]
       pub experimental_search: bool,

       #[serde(default)]
       pub advanced_analytics: bool,

       #[serde(default = "default_cache_enabled")]
       pub redis_cache: bool,

       #[serde(default = "default_rate_limiting")]
       pub rate_limiting: bool,
   }

   // Default value functions
   fn default_environment() -> Environment { Environment::Development }
   fn default_host() -> String { "127.0.0.1".to_string() }
   fn default_port() -> u16 { 8080 }
   fn default_workers() -> usize { num_cpus::get() }
   fn default_timeout() -> Duration { Duration::from_secs(30) }
   fn default_cache_enabled() -> bool { true }
   fn default_rate_limiting() -> bool { false }

   impl Default for ServerConfig {
       fn default() -> Self {
           Self {
               host: default_host(),
               port: default_port(),
               workers: default_workers(),
               request_timeout: default_timeout(),
               cors_origins: vec![],
           }
       }
   }

   impl Default for FeatureFlags {
       fn default() -> Self {
           Self {
               new_user_onboarding: false,
               experimental_search: false,
               advanced_analytics: false,
               redis_cache: default_cache_enabled(),
               rate_limiting: default_rate_limiting(),
           }
       }
   }

   // Configuration loading with layered sources
   impl AppConfig {
       pub fn load() -> Result<Self, ConfigError> {
           let mut settings = config::Config::builder()
               // Start with default values
               .add_source(config::Config::try_from(&AppConfig::default())?)

               // Layer environment-specific config file
               .add_source(
                   config::File::with_name("config/default").required(false)
               )

               // Layer environment-specific overrides
               .add_source(
                   config::File::with_name(&format!(
                       "config/{}",
                       std::env::var("APP_ENV").unwrap_or_else(|_| "development".to_string())
                   )).required(false)
               )

               // Layer local overrides (for development)
               .add_source(
                   config::File::with_name("config/local").required(false)
               )

               // Layer environment variables (12-factor app pattern)
               .add_source(
                   config::Environment::with_prefix("APP")
                       .prefix_separator("_")
                       .separator("__")
               );

           let config = settings.build()?;
           let app_config: AppConfig = config.try_deserialize()?;

           // Validate configuration
           app_config.validate()?;

           Ok(app_config)
       }

       fn validate(&self) -> Result<(), ConfigError> {
           // Environment-specific validation
           match self.environment {
               Environment::Production => {
                   if self.server.host == "127.0.0.1" {
                       return Err(ConfigError::Message(
                           "Production host cannot be localhost".to_string()
                       ));
                   }

                   if self.features.experimental_search {
                       return Err(ConfigError::Message(
                           "Experimental features not allowed in production".to_string()
                       ));
                   }
               }
               _ => {}
           }

           // Port validation
           if self.server.port < 1024 && std::env::var("USER").unwrap_or_default() != "root" {
               return Err(ConfigError::Message(
                   "Privileged ports require root access".to_string()
               ));
           }

           Ok(())
       }
   }

   #[derive(Debug, thiserror::Error)]
   pub enum ConfigError {
       #[error("Configuration error: {0}")]
       Message(String),

       #[error("Config parsing error: {0}")]
       Config(#[from] config::ConfigError),
   }
   ```

3. **Create Feature Flag Systems for Runtime Adaptability**: Implement feature flags that can be toggled without restarts:

   ```rust
   // ✅ GOOD: Runtime feature flag system with hot reloading

   use std::sync::Arc;
   use std::collections::HashMap;
   use tokio::sync::RwLock;
   use serde::{Deserialize, Serialize};

   #[derive(Debug, Clone)]
   pub struct FeatureFlagManager {
       flags: Arc<RwLock<HashMap<String, FeatureFlag>>>,
       config: Arc<AppConfig>,
   }

   #[derive(Debug, Clone, Serialize, Deserialize)]
   pub struct FeatureFlag {
       pub name: String,
       pub enabled: bool,
       pub rollout_percentage: f32,
       pub user_whitelist: Vec<String>,
       pub environment_filter: Vec<Environment>,
       pub created_at: chrono::DateTime<chrono::Utc>,
       pub updated_at: chrono::DateTime<chrono::Utc>,
   }

   #[derive(Debug, Clone)]
   pub struct FeatureContext {
       pub user_id: Option<String>,
       pub environment: Environment,
       pub request_id: String,
   }

   impl FeatureFlagManager {
       pub async fn new(config: Arc<AppConfig>) -> Result<Self, Box<dyn std::error::Error>> {
           let manager = Self {
               flags: Arc::new(RwLock::new(HashMap::new())),
               config,
           };

           // Load initial flags from configuration
           manager.load_flags_from_config().await?;

           // Start background task to reload flags periodically
           #[cfg(feature = "hot-reload")]
           manager.start_flag_reloader().await;

           Ok(manager)
       }

       async fn load_flags_from_config(&self) -> Result<(), Box<dyn std::error::Error>> {
           let mut flags = self.flags.write().await;

           // Load from static configuration
           flags.insert("new_user_onboarding".to_string(), FeatureFlag {
               name: "new_user_onboarding".to_string(),
               enabled: self.config.features.new_user_onboarding,
               rollout_percentage: 100.0,
               user_whitelist: vec![],
               environment_filter: vec![],
               created_at: chrono::Utc::now(),
               updated_at: chrono::Utc::now(),
           });

           flags.insert("experimental_search".to_string(), FeatureFlag {
               name: "experimental_search".to_string(),
               enabled: self.config.features.experimental_search,
               rollout_percentage: 10.0, // Gradual rollout
               user_whitelist: vec!["admin".to_string(), "beta_tester".to_string()],
               environment_filter: vec![Environment::Development, Environment::Staging],
               created_at: chrono::Utc::now(),
               updated_at: chrono::Utc::now(),
           });

           flags.insert("advanced_analytics".to_string(), FeatureFlag {
               name: "advanced_analytics".to_string(),
               enabled: self.config.features.advanced_analytics,
               rollout_percentage: 50.0,
               user_whitelist: vec![],
               environment_filter: vec![],
               created_at: chrono::Utc::now(),
               updated_at: chrono::Utc::now(),
           });

           Ok(())
       }

       pub async fn is_enabled(&self, flag_name: &str, context: &FeatureContext) -> bool {
           let flags = self.flags.read().await;

           let Some(flag) = flags.get(flag_name) else {
               // Default to disabled for unknown flags
               return false;
           };

           // Check if flag is globally disabled
           if !flag.enabled {
               return false;
           }

           // Check environment filter
           if !flag.environment_filter.is_empty()
               && !flag.environment_filter.contains(&context.environment) {
               return false;
           }

           // Check user whitelist
           if let Some(user_id) = &context.user_id {
               if flag.user_whitelist.contains(user_id) {
                   return true;
               }
           }

           // Check rollout percentage
           if flag.rollout_percentage >= 100.0 {
               return true;
           }

           // Use deterministic hash for consistent rollout
           let hash_input = format!("{}{}", flag_name, context.request_id);
           let hash = seahash::hash(hash_input.as_bytes());
           let percentage = (hash % 100) as f32;

           percentage < flag.rollout_percentage
       }

       #[cfg(feature = "hot-reload")]
       async fn start_flag_reloader(&self) {
           let flags = self.flags.clone();
           let config = self.config.clone();

           tokio::spawn(async move {
               let mut interval = tokio::time::interval(Duration::from_secs(30));

               loop {
                   interval.tick().await;

                   // Reload flags from external source (database, API, etc.)
                   if let Ok(updated_flags) = Self::fetch_flags_from_external_source().await {
                       let mut flags_guard = flags.write().await;
                       *flags_guard = updated_flags;
                       tracing::info!("Feature flags reloaded from external source");
                   }
               }
           });
       }

       #[cfg(feature = "hot-reload")]
       async fn fetch_flags_from_external_source() -> Result<HashMap<String, FeatureFlag>, Box<dyn std::error::Error>> {
           // Implementation would fetch from external service
           // For example: LaunchDarkly, Split.io, or custom service
           Ok(HashMap::new())
       }
   }

   // Usage in application code
   pub async fn handle_search_request(
       manager: &FeatureFlagManager,
       context: FeatureContext,
       query: String,
   ) -> SearchResult {
       if manager.is_enabled("experimental_search", &context).await {
           // Use new search algorithm
           experimental_search(query).await
       } else {
           // Use stable search algorithm
           standard_search(query).await
       }
   }

   // Macro for cleaner feature flag usage
   macro_rules! feature_gate {
       ($manager:expr, $flag:expr, $context:expr, $enabled_block:block, $disabled_block:block) => {
           if $manager.is_enabled($flag, $context).await {
               $enabled_block
           } else {
               $disabled_block
           }
       };
   }

   // Usage with macro
   pub async fn handle_user_creation(
       manager: &FeatureFlagManager,
       context: FeatureContext,
       user_data: CreateUserRequest,
   ) -> Result<User, UserError> {
       let user = create_user(user_data).await?;

       feature_gate!(manager, "new_user_onboarding", &context, {
           // Enable new onboarding flow
           start_onboarding_flow(&user).await?;
           send_welcome_email_v2(&user).await?;
       }, {
           // Use legacy onboarding
           send_welcome_email(&user).await?;
       });

       Ok(user)
   }
   ```

4. **Design Environment-Specific Configuration Patterns**: Create configuration that adapts to deployment environments:

   ```rust
   // ✅ GOOD: Environment-specific configuration with safe defaults

   use std::env;
   use std::path::PathBuf;

   #[derive(Debug, Clone)]
   pub struct EnvironmentConfig {
       pub database: DatabaseConfig,
       pub redis: RedisConfig,
       pub logging: LoggingConfig,
       pub security: SecurityConfig,
       pub performance: PerformanceConfig,
   }

   impl EnvironmentConfig {
       pub fn for_environment(env: &Environment) -> Self {
           match env {
               Environment::Development => Self::development(),
               Environment::Staging => Self::staging(),
               Environment::Production => Self::production(),
           }
       }

       fn development() -> Self {
           Self {
               database: DatabaseConfig {
                   url: env::var("DATABASE_URL")
                       .unwrap_or_else(|_| "sqlite:./dev.db".to_string()),
                   max_connections: 10,
                   connect_timeout: Duration::from_secs(5),
                   idle_timeout: Duration::from_secs(300),
                   enable_logging: true,
               },
               redis: RedisConfig {
                   url: env::var("REDIS_URL")
                       .unwrap_or_else(|_| "redis://localhost:6379".to_string()),
                   pool_size: 5,
                   timeout: Duration::from_secs(1),
               },
               logging: LoggingConfig {
                   level: "debug".to_string(),
                   format: LogFormat::Pretty,
                   output: LogOutput::Stdout,
                   enable_file_logging: true,
                   file_path: Some("logs/dev.log".into()),
               },
               security: SecurityConfig {
                   cors_origins: vec!["http://localhost:3000".to_string()],
                   enable_https: false,
                   jwt_secret: "dev-secret-key".to_string(),
                   session_timeout: Duration::from_secs(3600), // 1 hour
                   rate_limit_requests: 1000,
                   rate_limit_window: Duration::from_secs(60),
               },
               performance: PerformanceConfig {
                   enable_caching: true,
                   cache_ttl: Duration::from_secs(300),
                   max_request_size: 1024 * 1024, // 1MB
                   worker_threads: 2,
                   enable_compression: false,
               },
           }
       }

       fn staging() -> Self {
           Self {
               database: DatabaseConfig {
                   url: env::var("DATABASE_URL")
                       .expect("DATABASE_URL must be set in staging"),
                   max_connections: 20,
                   connect_timeout: Duration::from_secs(10),
                   idle_timeout: Duration::from_secs(600),
                   enable_logging: false,
               },
               redis: RedisConfig {
                   url: env::var("REDIS_URL")
                       .expect("REDIS_URL must be set in staging"),
                   pool_size: 10,
                   timeout: Duration::from_secs(2),
               },
               logging: LoggingConfig {
                   level: "info".to_string(),
                   format: LogFormat::Json,
                   output: LogOutput::Stdout,
                   enable_file_logging: false,
                   file_path: None,
               },
               security: SecurityConfig {
                   cors_origins: env::var("CORS_ORIGINS")
                       .unwrap_or_default()
                       .split(',')
                       .map(|s| s.trim().to_string())
                       .collect(),
                   enable_https: true,
                   jwt_secret: env::var("JWT_SECRET")
                       .expect("JWT_SECRET must be set in staging"),
                   session_timeout: Duration::from_secs(1800), // 30 minutes
                   rate_limit_requests: 500,
                   rate_limit_window: Duration::from_secs(60),
               },
               performance: PerformanceConfig {
                   enable_caching: true,
                   cache_ttl: Duration::from_secs(600),
                   max_request_size: 5 * 1024 * 1024, // 5MB
                   worker_threads: 4,
                   enable_compression: true,
               },
           }
       }

       fn production() -> Self {
           Self {
               database: DatabaseConfig {
                   url: env::var("DATABASE_URL")
                       .expect("DATABASE_URL must be set in production"),
                   max_connections: 50,
                   connect_timeout: Duration::from_secs(30),
                   idle_timeout: Duration::from_secs(1800),
                   enable_logging: false,
               },
               redis: RedisConfig {
                   url: env::var("REDIS_URL")
                       .expect("REDIS_URL must be set in production"),
                   pool_size: 20,
                   timeout: Duration::from_secs(5),
               },
               logging: LoggingConfig {
                   level: env::var("LOG_LEVEL").unwrap_or_else(|_| "warn".to_string()),
                   format: LogFormat::Json,
                   output: LogOutput::Stdout,
                   enable_file_logging: false,
                   file_path: None,
               },
               security: SecurityConfig {
                   cors_origins: env::var("CORS_ORIGINS")
                       .expect("CORS_ORIGINS must be set in production")
                       .split(',')
                       .map(|s| s.trim().to_string())
                       .collect(),
                   enable_https: true,
                   jwt_secret: env::var("JWT_SECRET")
                       .expect("JWT_SECRET must be set in production"),
                   session_timeout: Duration::from_secs(900), // 15 minutes
                   rate_limit_requests: 100,
                   rate_limit_window: Duration::from_secs(60),
               },
               performance: PerformanceConfig {
                   enable_caching: true,
                   cache_ttl: Duration::from_secs(3600),
                   max_request_size: 10 * 1024 * 1024, // 10MB
                   worker_threads: num_cpus::get(),
                   enable_compression: true,
               },
           }
       }
   }

   // Configuration validation for each environment
   impl EnvironmentConfig {
       pub fn validate(&self, environment: &Environment) -> Result<(), ConfigValidationError> {
           match environment {
               Environment::Production => self.validate_production(),
               Environment::Staging => self.validate_staging(),
               Environment::Development => self.validate_development(),
           }
       }

       fn validate_production(&self) -> Result<(), ConfigValidationError> {
           // Strict production validation
           if self.security.jwt_secret == "dev-secret-key" {
               return Err(ConfigValidationError::InsecureProduction(
                   "JWT secret must not be default value in production".to_string()
               ));
           }

           if self.security.cors_origins.contains(&"*".to_string()) {
               return Err(ConfigValidationError::InsecureProduction(
                   "CORS cannot allow all origins in production".to_string()
               ));
           }

           if !self.security.enable_https {
               return Err(ConfigValidationError::InsecureProduction(
                   "HTTPS must be enabled in production".to_string()
               ));
           }

           if self.logging.enable_file_logging {
               return Err(ConfigValidationError::InvalidConfiguration(
                   "File logging should be disabled in production (use log aggregation)".to_string()
               ));
           }

           Ok(())
       }

       fn validate_staging(&self) -> Result<(), ConfigValidationError> {
           // Moderate staging validation
           if self.security.jwt_secret == "dev-secret-key" {
               return Err(ConfigValidationError::InsecureStaging(
                   "JWT secret should not be default value in staging".to_string()
               ));
           }

           Ok(())
       }

       fn validate_development(&self) -> Result<(), ConfigValidationError> {
           // Permissive development validation
           if self.database.max_connections > 50 {
               tracing::warn!("High database connection count in development: {}",
                   self.database.max_connections);
           }

           Ok(())
       }
   }

   #[derive(Debug, thiserror::Error)]
   pub enum ConfigValidationError {
       #[error("Production security violation: {0}")]
       InsecureProduction(String),

       #[error("Staging configuration warning: {0}")]
       InsecureStaging(String),

       #[error("Invalid configuration: {0}")]
       InvalidConfiguration(String),
   }
   ```

5. **Implement Build-Time Optimization Through Conditional Compilation**: Use cfg attributes to eliminate unused code:

   ```rust
   // ✅ GOOD: Conditional compilation for optimized builds

   // Metrics collection - only compiled when metrics features are enabled
   #[cfg(any(feature = "metrics-prometheus", feature = "metrics-datadog"))]
   pub mod metrics {
       use std::time::Instant;

       pub struct Metrics {
           #[cfg(feature = "metrics-prometheus")]
           prometheus: prometheus::Registry,

           #[cfg(feature = "metrics-datadog")]
           datadog: datadog_statsd::Client,
       }

       impl Metrics {
           pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
               Ok(Self {
                   #[cfg(feature = "metrics-prometheus")]
                   prometheus: prometheus::Registry::new(),

                   #[cfg(feature = "metrics-datadog")]
                   datadog: datadog_statsd::Client::new("127.0.0.1:8125")?,
               })
           }

           pub fn record_request_duration(&self, endpoint: &str, duration: std::time::Duration) {
               #[cfg(feature = "metrics-prometheus")]
               {
                   // Prometheus implementation
                   let histogram = prometheus::HistogramVec::new(
                       prometheus::HistogramOpts::new("request_duration", "Request duration"),
                       &["endpoint"]
                   ).unwrap();
                   histogram.with_label_values(&[endpoint]).observe(duration.as_secs_f64());
               }

               #[cfg(feature = "metrics-datadog")]
               {
                   // DataDog implementation
                   self.datadog.histogram("request.duration", duration.as_millis() as f64, &[
                       format!("endpoint:{}", endpoint)
                   ]).ok();
               }
           }
       }
   }

   // No-op metrics when no metrics features are enabled
   #[cfg(not(any(feature = "metrics-prometheus", feature = "metrics-datadog")))]
   pub mod metrics {
       pub struct Metrics;

       impl Metrics {
           pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
               Ok(Self)
           }

           #[inline]
           pub fn record_request_duration(&self, _endpoint: &str, _duration: std::time::Duration) {
               // No-op when metrics disabled
           }
       }
   }

   // Authentication system with conditional compilation
   pub mod auth {
       use serde::{Deserialize, Serialize};

       #[derive(Debug, Clone)]
       pub enum AuthProvider {
           #[cfg(feature = "auth-jwt")]
           Jwt(JwtAuth),

           #[cfg(feature = "auth-oauth")]
           OAuth(OAuthAuth),

           #[cfg(feature = "auth-saml")]
           Saml(SamlAuth),

           None,
       }

       impl AuthProvider {
           pub fn from_config(config: &AuthConfig) -> Result<Self, AuthError> {
               #[cfg(feature = "auth-jwt")]
               if let Some(jwt_config) = &config.jwt {
                   return Ok(AuthProvider::Jwt(JwtAuth::new(jwt_config)?));
               }

               #[cfg(feature = "auth-oauth")]
               if let Some(oauth_config) = &config.oauth {
                   return Ok(AuthProvider::OAuth(OAuthAuth::new(oauth_config)?));
               }

               #[cfg(feature = "auth-saml")]
               if let Some(saml_config) = &config.saml {
                   return Ok(AuthProvider::Saml(SamlAuth::new(saml_config)?));
               }

               Ok(AuthProvider::None)
           }

           pub async fn authenticate(&self, token: &str) -> Result<User, AuthError> {
               match self {
                   #[cfg(feature = "auth-jwt")]
                   AuthProvider::Jwt(jwt) => jwt.verify_token(token).await,

                   #[cfg(feature = "auth-oauth")]
                   AuthProvider::OAuth(oauth) => oauth.verify_token(token).await,

                   #[cfg(feature = "auth-saml")]
                   AuthProvider::Saml(saml) => saml.verify_assertion(token).await,

                   AuthProvider::None => Err(AuthError::NoAuthProviderConfigured),
               }
           }
       }
   }

   // Development-only features
   #[cfg(feature = "dev-tools")]
   pub mod dev_tools {
       use tokio::net::TcpListener;

       pub async fn start_debug_server() -> Result<(), Box<dyn std::error::Error>> {
           let listener = TcpListener::bind("127.0.0.1:3001").await?;
           tracing::info!("Debug server started on http://127.0.0.1:3001");

           // Implementation of debug endpoints
           Ok(())
       }

       pub fn init_dev_logging() {
           tracing_subscriber::fmt()
               .with_env_filter("debug")
               .with_target(false)
               .compact()
               .init();
       }
   }

   // Main application startup with conditional feature initialization
   pub async fn start_application(config: AppConfig) -> Result<(), Box<dyn std::error::Error>> {
       // Initialize logging
       #[cfg(feature = "dev-tools")]
       if matches!(config.environment, Environment::Development) {
           dev_tools::init_dev_logging();
           dev_tools::start_debug_server().await?;
       }

       // Initialize metrics
       let metrics = metrics::Metrics::new()?;

       // Initialize authentication
       let auth_provider = auth::AuthProvider::from_config(&config.auth)?;

       // Start servers based on enabled features
       let mut tasks = vec![];

       #[cfg(feature = "web-server")]
       {
           let web_server = start_web_server(config.clone(), auth_provider.clone(), metrics.clone());
           tasks.push(tokio::spawn(web_server));
       }

       #[cfg(feature = "grpc-server")]
       {
           let grpc_server = start_grpc_server(config.clone(), auth_provider.clone(), metrics.clone());
           tasks.push(tokio::spawn(grpc_server));
       }

       // Wait for any server to complete
       if let Some((result, _index, _remaining)) = futures::future::select_all(tasks).await {
           result??;
       }

       Ok(())
   }
   ```

## Examples

```rust
// ❌ BAD: Hardcoded configuration scattered throughout the codebase
const DATABASE_URL: &str = "postgres://localhost/myapp";
const REDIS_URL: &str = "redis://localhost:6379";
const JWT_SECRET: &str = "my-secret-key";
const MAX_CONNECTIONS: usize = 10;

async fn connect_database() -> Result<Database, Error> {
    // Hardcoded connection string
    Database::connect(DATABASE_URL).await
}

async fn create_user(user: CreateUserRequest) -> Result<User, Error> {
    // Hardcoded feature behavior
    let user = save_user_to_database(user).await?;

    // Always send email, no way to disable
    send_welcome_email(&user).await?;

    // Always use new onboarding flow
    start_advanced_onboarding(&user).await?;

    Ok(user)
}

// JWT verification with hardcoded secret
fn verify_jwt_token(token: &str) -> Result<Claims, JwtError> {
    let key = jsonwebtoken::DecodingKey::from_secret(JWT_SECRET.as_ref());
    jsonwebtoken::decode::<Claims>(token, &key, &jsonwebtoken::Validation::default())
        .map(|data| data.claims)
}

// Problems:
// - Cannot adapt to different environments without recompilation
// - No way to disable features or change behavior
// - Secrets hardcoded in source code
// - Testing requires modifying constants
// - Cannot roll out features gradually
```

```rust
// ✅ GOOD: Configurable system that adapts to different environments and requirements
#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    pub environment: Environment,
    pub database: DatabaseConfig,
    pub redis: RedisConfig,
    pub features: FeatureFlags,
    pub auth: AuthConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct FeatureFlags {
    pub welcome_email: bool,
    pub advanced_onboarding: bool,
    pub new_user_analytics: bool,
    #[serde(default = "default_onboarding_version")]
    pub onboarding_version: OnboardingVersion,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OnboardingVersion {
    Legacy,
    Standard,
    Advanced,
}

fn default_onboarding_version() -> OnboardingVersion {
    OnboardingVersion::Standard
}

impl AppConfig {
    pub fn load() -> Result<Self, ConfigError> {
        let config = config::Config::builder()
            // Environment-specific defaults
            .add_source(config::Config::try_from(&Self::default_for_env()?)?)

            // Environment-specific config files
            .add_source(config::File::with_name(&format!(
                "config/{}",
                std::env::var("APP_ENV").unwrap_or_else(|_| "development".to_string())
            )).required(false))

            // Environment variables override everything
            .add_source(config::Environment::with_prefix("APP").separator("__"))
            .build()?;

        let app_config: AppConfig = config.try_deserialize()?;
        app_config.validate()?;
        Ok(app_config)
    }

    fn default_for_env() -> Result<Self, ConfigError> {
        let env = std::env::var("APP_ENV").unwrap_or_else(|_| "development".to_string());
        let environment = match env.as_str() {
            "production" => Environment::Production,
            "staging" => Environment::Staging,
            _ => Environment::Development,
        };

        Ok(match environment {
            Environment::Development => Self::development_defaults(),
            Environment::Staging => Self::staging_defaults(),
            Environment::Production => Self::production_defaults(),
        })
    }
}

async fn connect_database(config: &DatabaseConfig) -> Result<Database, Error> {
    Database::connect(&config.url)
        .max_connections(config.max_connections)
        .connect_timeout(config.connect_timeout)
        .await
}

async fn create_user(
    user: CreateUserRequest,
    config: &AppConfig,
    feature_flags: &FeatureFlagManager,
    context: &FeatureContext,
) -> Result<User, Error> {
    let user = save_user_to_database(user).await?;

    // Configurable email sending
    if config.features.welcome_email {
        if let Err(err) = send_welcome_email(&user).await {
            // Don't fail user creation if email fails
            tracing::warn!("Failed to send welcome email: {}", err);
        }
    }

    // Feature flag controlled onboarding
    if feature_flags.is_enabled("advanced_onboarding", context).await {
        match config.features.onboarding_version {
            OnboardingVersion::Legacy => start_legacy_onboarding(&user).await?,
            OnboardingVersion::Standard => start_standard_onboarding(&user).await?,
            OnboardingVersion::Advanced => start_advanced_onboarding(&user).await?,
        }
    }

    // Analytics based on feature flag
    if config.features.new_user_analytics {
        tokio::spawn(async move {
            if let Err(err) = track_user_creation_analytics(&user).await {
                tracing::error!("Failed to track user analytics: {}", err);
            }
        });
    }

    Ok(user)
}

fn verify_jwt_token(token: &str, auth_config: &AuthConfig) -> Result<Claims, JwtError> {
    let key = jsonwebtoken::DecodingKey::from_secret(auth_config.jwt_secret.as_ref());
    let mut validation = jsonwebtoken::Validation::default();
    validation.iss = auth_config.jwt_issuer.clone();
    validation.leeway = auth_config.jwt_leeway.as_secs();

    jsonwebtoken::decode::<Claims>(token, &key, &validation)
        .map(|data| data.claims)
}

// Benefits:
// - Adapts to different environments without code changes
// - Features can be enabled/disabled through configuration
// - Secrets loaded from environment variables
// - Easy testing with different configurations
// - Gradual feature rollouts through feature flags
// - Type-safe configuration with validation
```

```rust
// ❌ BAD: Single binary with all features always compiled in
// Cargo.toml
[dependencies]
axum = "0.7"              # Always included
tonic = "0.10"            # Always included
sqlx = { version = "0.7", features = ["postgres", "sqlite", "mysql"] }  # All DB drivers
prometheus = "0.13"       # Always included
datadog-statsd = "3.0"    # Always included
oauth2 = "4.4"            # Always included
saml2 = "0.6"             # Always included
redis = "0.24"            # Always included

// All authentication providers always compiled
pub enum AuthProvider {
    Jwt(JwtAuth),      // Always available
    OAuth(OAuthAuth),  // Always available
    Saml(SamlAuth),    // Always available
}

// All metrics backends always included
pub struct Metrics {
    prometheus: prometheus::Registry,      // Always compiled
    datadog: datadog_statsd::Client,       // Always compiled
}

// Problems:
// - Large binary size with unused features
// - All dependencies included even if not used
// - Cannot optimize for specific deployment scenarios
// - Security risk from unused attack surface
// - Longer compilation times
```

```rust
// ✅ GOOD: Feature-gated compilation for optimized builds
// Cargo.toml
[features]
default = ["web-server", "database-postgres", "auth-jwt"]

# Server types
web-server = ["axum", "tower"]
grpc-server = ["tonic", "prost"]

# Database backends (choose one)
database-postgres = ["sqlx/postgres"]
database-sqlite = ["sqlx/sqlite"]
database-mysql = ["sqlx/mysql"]

# Authentication (choose one or more)
auth-jwt = ["jsonwebtoken"]
auth-oauth = ["oauth2"]
auth-saml = ["saml2"]

# Metrics (choose one)
metrics-prometheus = ["prometheus"]
metrics-datadog = ["datadog-statsd"]

# Optional features
redis-cache = ["redis"]
dev-tools = ["console-subscriber"]

[dependencies]
# Core dependencies
serde = { version = "1.0", features = ["derive"] }
tokio = "1.0"

# Optional dependencies
axum = { version = "0.7", optional = true }
tonic = { version = "0.10", optional = true }
sqlx = { version = "0.7", optional = true }
prometheus = { version = "0.13", optional = true }
datadog-statsd = { version = "3.0", optional = true }
oauth2 = { version = "4.4", optional = true }
saml2 = { version = "0.6", optional = true }
redis = { version = "0.24", optional = true }

// Conditional compilation based on features
#[cfg(any(feature = "auth-jwt", feature = "auth-oauth", feature = "auth-saml"))]
pub enum AuthProvider {
    #[cfg(feature = "auth-jwt")]
    Jwt(JwtAuth),

    #[cfg(feature = "auth-oauth")]
    OAuth(OAuthAuth),

    #[cfg(feature = "auth-saml")]
    Saml(SamlAuth),
}

#[cfg(not(any(feature = "auth-jwt", feature = "auth-oauth", feature = "auth-saml")))]
pub enum AuthProvider {
    None,
}

// Metrics only compiled when needed
#[cfg(feature = "metrics-prometheus")]
pub type Metrics = prometheus::Registry;

#[cfg(feature = "metrics-datadog")]
pub type Metrics = datadog_statsd::Client;

#[cfg(not(any(feature = "metrics-prometheus", feature = "metrics-datadog")))]
pub struct Metrics;

// Build examples:
// Minimal microservice: cargo build --no-default-features --features="web-server,database-sqlite,auth-jwt"
// Full-featured service: cargo build --features="web-server,grpc-server,database-postgres,auth-oauth,metrics-prometheus,redis-cache"
// Development build: cargo build --features="dev-tools"

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
