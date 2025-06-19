# Security Guide: TypeScript Full Toolchain

This document outlines security best practices, secure defaults, and boundary validation patterns for TypeScript projects using the Leyline toolchain.

## Security Philosophy

**Security by Design**: Security measures are built into the development workflow from the start, not added as an afterthought. Every configuration, pattern, and process includes security considerations as a first-class concern.

## Environment Variable Security

### Validation at Startup

All environment variables must be validated at application startup with explicit error messages:

```typescript
// config/environment.ts
interface EnvironmentConfig {
  readonly api: {
    readonly baseUrl: string;
    readonly timeout: number;
    readonly retryAttempts: number;
  };
  readonly auth: {
    readonly tokenKey: string;
    readonly refreshUrl: string;
    readonly requiresAuth: boolean;
    readonly sessionTimeoutMinutes: number;
  };
  readonly security: {
    readonly enableCsrf: boolean;
    readonly validateHeaders: boolean;
    readonly secureCookies: boolean;
  };
}

function validateEnvironment(): EnvironmentConfig {
  const errors: string[] = [];

  // Validate required variables
  const apiBaseUrl = process.env.VITE_API_BASE_URL || process.env.API_BASE_URL;
  if (!apiBaseUrl) {
    errors.push('API_BASE_URL is required. Set VITE_API_BASE_URL for client-side or API_BASE_URL for server-side.');
  }

  // Validate URL format
  if (apiBaseUrl && !isValidUrl(apiBaseUrl)) {
    errors.push(`Invalid API_BASE_URL format: ${apiBaseUrl}`);
  }

  // Validate numeric values
  const timeout = parseInt(process.env.VITE_API_TIMEOUT || '5000');
  if (isNaN(timeout) || timeout < 1000 || timeout > 30000) {
    errors.push('API_TIMEOUT must be a number between 1000 and 30000 milliseconds');
  }

  // Validate boolean values
  const requiresAuth = process.env.VITE_REQUIRE_AUTH !== 'false';
  const authTokenKey = process.env.VITE_AUTH_TOKEN_KEY || 'app_auth_token';

  if (requiresAuth && !authTokenKey.match(/^[a-zA-Z_][a-zA-Z0-9_]*$/)) {
    errors.push('AUTH_TOKEN_KEY must be a valid identifier (alphanumeric and underscores only)');
  }

  if (errors.length > 0) {
    throw new Error(`Environment validation failed:\n${errors.map(e => `  - ${e}`).join('\n')}`);
  }

  return {
    api: {
      baseUrl: apiBaseUrl!,
      timeout,
      retryAttempts: parseInt(process.env.VITE_API_RETRY_ATTEMPTS || '3'),
    },
    auth: {
      tokenKey: authTokenKey,
      refreshUrl: process.env.VITE_AUTH_REFRESH_URL || '/auth/refresh',
      requiresAuth,
      sessionTimeoutMinutes: parseInt(process.env.VITE_SESSION_TIMEOUT_MINUTES || '60'),
    },
    security: {
      enableCsrf: process.env.VITE_ENABLE_CSRF_PROTECTION !== 'false',
      validateHeaders: process.env.VITE_VALIDATE_SECURITY_HEADERS !== 'false',
      secureCookies: process.env.VITE_SECURE_COOKIES !== 'false',
    },
  };
}

function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}

// Initialize and export validated configuration
export const config = validateEnvironment();
```

### Environment-Specific Configuration

Use different configurations for development, staging, and production:

```typescript
// config/env-specific.ts
type Environment = 'development' | 'staging' | 'production';

interface SecurityConfig {
  readonly enableDevTools: boolean;
  readonly enableDebugLogging: boolean;
  readonly enforceHttps: boolean;
  readonly enableSourceMaps: boolean;
  readonly allowTestData: boolean;
}

function getSecurityConfig(env: Environment): SecurityConfig {
  switch (env) {
    case 'development':
      return {
        enableDevTools: true,
        enableDebugLogging: true,
        enforceHttps: false,
        enableSourceMaps: true,
        allowTestData: true,
      };

    case 'staging':
      return {
        enableDevTools: true,
        enableDebugLogging: false,
        enforceHttps: true,
        enableSourceMaps: true,
        allowTestData: true,
      };

    case 'production':
      return {
        enableDevTools: false,
        enableDebugLogging: false,
        enforceHttps: true,
        enableSourceMaps: false,
        allowTestData: false,
      };

    default:
      throw new Error(`Unknown environment: ${env}`);
  }
}

const currentEnv = (process.env.VITE_ENVIRONMENT || 'development') as Environment;
export const securityConfig = getSecurityConfig(currentEnv);
```

## API Security Patterns

### Secure HTTP Client Configuration

```typescript
// api/client.ts
import { config, securityConfig } from '../config/environment';

interface ApiClient {
  get<T>(path: string, options?: RequestOptions): Promise<T>;
  post<T>(path: string, data: unknown, options?: RequestOptions): Promise<T>;
  put<T>(path: string, data: unknown, options?: RequestOptions): Promise<T>;
  delete<T>(path: string, options?: RequestOptions): Promise<T>;
}

interface RequestOptions {
  readonly timeout?: number;
  readonly retries?: number;
  readonly headers?: Record<string, string>;
  readonly skipAuth?: boolean;
}

class SecureApiClient implements ApiClient {
  private readonly baseUrl: string;
  private readonly defaultTimeout: number;
  private readonly defaultRetries: number;

  constructor() {
    this.baseUrl = config.api.baseUrl;
    this.defaultTimeout = config.api.timeout;
    this.defaultRetries = config.api.retryAttempts;

    // Validate base URL at construction
    if (!this.baseUrl.startsWith('https://') && securityConfig.enforceHttps) {
      throw new Error('HTTPS is required in this environment');
    }
  }

  async get<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('GET', path, undefined, options);
  }

  async post<T>(path: string, data: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('POST', path, data, options);
  }

  async put<T>(path: string, data: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('PUT', path, data, options);
  }

  async delete<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('DELETE', path, undefined, options);
  }

  private async request<T>(
    method: string,
    path: string,
    data?: unknown,
    options?: RequestOptions
  ): Promise<T> {
    const url = this.buildUrl(path);
    const headers = await this.buildHeaders(options);

    const controller = new AbortController();
    const timeout = setTimeout(() => {
      controller.abort();
    }, options?.timeout || this.defaultTimeout);

    try {
      const response = await fetch(url, {
        method,
        headers,
        body: data ? JSON.stringify(data) : undefined,
        signal: controller.signal,
        credentials: 'include', // Include cookies for CSRF protection
      });

      clearTimeout(timeout);

      if (!response.ok) {
        throw await this.handleErrorResponse(response);
      }

      return await this.parseResponse<T>(response);
    } catch (error) {
      clearTimeout(timeout);

      if (error instanceof DOMException && error.name === 'AbortError') {
        throw new ApiError('TIMEOUT', 'Request timed out');
      }

      throw error;
    }
  }

  private buildUrl(path: string): string {
    // Validate path to prevent injection
    if (!path.startsWith('/')) {
      throw new Error('API path must start with /');
    }

    // Remove any dangerous characters
    const safePath = path.replace(/[^a-zA-Z0-9\-._~:/?#[\]@!$&'()*+,;=%]/g, '');

    return `${this.baseUrl}${safePath}`;
  }

  private async buildHeaders(options?: RequestOptions): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...options?.headers,
    };

    // Add authentication header if required
    if (!options?.skipAuth && config.auth.requiresAuth) {
      const token = await this.getAuthToken();
      if (token) {
        headers.Authorization = `Bearer ${token}`;
      }
    }

    // Add CSRF protection
    if (config.security.enableCsrf) {
      const csrfToken = await this.getCsrfToken();
      if (csrfToken) {
        headers['X-CSRF-Token'] = csrfToken;
      }
    }

    // Add security headers
    headers['X-Requested-With'] = 'XMLHttpRequest';

    return headers;
  }

  private async getAuthToken(): Promise<string | null> {
    try {
      const token = localStorage.getItem(config.auth.tokenKey);

      // Validate token format (basic check)
      if (token && !token.match(/^[A-Za-z0-9_.-]+$/)) {
        console.warn('Invalid token format detected, clearing token');
        localStorage.removeItem(config.auth.tokenKey);
        return null;
      }

      return token;
    } catch (error) {
      console.error('Error retrieving auth token:', error);
      return null;
    }
  }

  private async getCsrfToken(): Promise<string | null> {
    // Implementation would retrieve CSRF token from meta tag or API
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag?.getAttribute('content') || null;
  }

  private async handleErrorResponse(response: Response): Promise<never> {
    let errorData: any;

    try {
      errorData = await response.json();
    } catch {
      errorData = { message: 'Unknown error occurred' };
    }

    // Sanitize error messages in production
    const message = securityConfig.enableDebugLogging
      ? errorData.message || response.statusText
      : 'An error occurred';

    switch (response.status) {
      case 401:
        // Clear auth token on unauthorized
        localStorage.removeItem(config.auth.tokenKey);
        throw new ApiError('UNAUTHORIZED', 'Authentication required');

      case 403:
        throw new ApiError('FORBIDDEN', 'Access denied');

      case 404:
        throw new ApiError('NOT_FOUND', 'Resource not found');

      case 429:
        throw new ApiError('RATE_LIMITED', 'Too many requests');

      case 500:
        throw new ApiError('SERVER_ERROR', message);

      default:
        throw new ApiError('API_ERROR', message);
    }
  }

  private async parseResponse<T>(response: Response): Promise<T> {
    const contentType = response.headers.get('content-type');

    if (!contentType?.includes('application/json')) {
      throw new ApiError('INVALID_RESPONSE', 'Expected JSON response');
    }

    try {
      return await response.json();
    } catch (error) {
      throw new ApiError('PARSE_ERROR', 'Failed to parse response');
    }
  }
}

export class ApiError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly timestamp: number = Date.now()
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export const apiClient = new SecureApiClient();
```

## Input Validation and Sanitization

### Type-Safe Validation

```typescript
// validation/types.ts
export interface ValidationResult<T> {
  readonly success: boolean;
  readonly data?: T;
  readonly errors: readonly string[];
}

export type Validator<T> = (value: unknown) => ValidationResult<T>;

// Base validators
export const isString: Validator<string> = (value): ValidationResult<string> => {
  if (typeof value === 'string') {
    return { success: true, data: value, errors: [] };
  }
  return { success: false, errors: ['Must be a string'] };
};

export const isNumber: Validator<number> = (value): ValidationResult<number> => {
  if (typeof value === 'number' && !isNaN(value)) {
    return { success: true, data: value, errors: [] };
  }
  return { success: false, errors: ['Must be a valid number'] };
};

export const isEmail: Validator<string> = (value): ValidationResult<string> => {
  const stringResult = isString(value);
  if (!stringResult.success) {
    return stringResult;
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (emailRegex.test(stringResult.data!)) {
    return stringResult;
  }

  return { success: false, errors: ['Must be a valid email address'] };
};

// Sanitization helpers
export function sanitizeHtml(input: string): string {
  return input
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
}

export function sanitizeUrl(input: string): string {
  try {
    const url = new URL(input);
    // Only allow http and https protocols
    if (!['http:', 'https:'].includes(url.protocol)) {
      throw new Error('Invalid protocol');
    }
    return url.toString();
  } catch {
    throw new Error('Invalid URL format');
  }
}
```

## Security Testing

### Secret Detection Tests

```typescript
// tests/security.test.ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { glob } from 'glob';

describe('Security - Secret Detection', () => {
  it('should not contain hardcoded secrets in source files', async () => {
    const files = await glob('src/**/*.{ts,tsx,js,jsx}');
    const secretPatterns = [
      /api[_-]?key['"]\s*:\s*['"][^'"]+['"]/i,
      /password['"]\s*:\s*['"][^'"]+['"]/i,
      /secret['"]\s*:\s*['"][^'"]+['"]/i,
      /token['"]\s*:\s*['"][^'"]+['"]/i,
      /bearer\s+[a-zA-Z0-9_.-]+/i,
      /sk_live_[a-zA-Z0-9]+/,
      /pk_live_[a-zA-Z0-9]+/,
    ];

    const violations: string[] = [];

    for (const file of files) {
      const content = readFileSync(file, 'utf-8');

      for (const pattern of secretPatterns) {
        if (pattern.test(content)) {
          violations.push(`Potential secret found in ${file}`);
        }
      }
    }

    expect(violations).toEqual([]);
  });

  it('should not contain hardcoded URLs in source files', async () => {
    const files = await glob('src/**/*.{ts,tsx,js,jsx}');
    const urlPatterns = [
      /https?:\/\/(?!localhost|127\.0\.0\.1|0\.0\.0\.0)[^'"\s]+/g,
    ];

    const violations: string[] = [];

    for (const file of files) {
      const content = readFileSync(file, 'utf-8');

      for (const pattern of urlPatterns) {
        const matches = content.match(pattern);
        if (matches) {
          violations.push(`Hardcoded URL found in ${file}: ${matches.join(', ')}`);
        }
      }
    }

    expect(violations).toEqual([]);
  });
});
```

## CI/CD Security Integration

Security scanning and validation are integrated into the development workflow through automated tools and processes. See the CI configuration section below for implementation details.

## Security Checklist

### Development
- [ ] All secrets use environment variables
- [ ] Environment variables are validated at startup
- [ ] API URLs are configurable and validated
- [ ] Input validation is implemented for all user inputs
- [ ] Error messages don't leak sensitive information
- [ ] HTTPS is enforced in production environments

### Testing
- [ ] Secret detection tests pass
- [ ] Input validation tests cover edge cases
- [ ] Error handling tests verify sanitized messages
- [ ] Security integration tests validate authentication

### Deployment
- [ ] Environment-specific configurations are properly isolated
- [ ] Production secrets are stored in secure systems
- [ ] Security headers are configured
- [ ] CSRF protection is enabled
- [ ] Content Security Policy is enforced
