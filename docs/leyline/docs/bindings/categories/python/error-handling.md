---
derived_from: explicit-over-implicit
enforced_by: flake8-bugbear & pylint & bandit
id: python-error-handling
last_modified: '2025-06-13'
version: '0.1.0'
---
# Binding: Handle Errors Explicitly with Specific Exception Types

Never use bare `except:` clauses or catch overly broad exception types without explicit justification. Always handle specific exceptions that you expect and can meaningfully respond to. When you must catch broad exceptions, immediately re-raise them or handle them in a documented, deliberate way.

## Rationale

This binding implements our explicit-over-implicit tenet by making error handling strategies visible and intentional rather than hidden behind catch-all exception handlers. It also supports our fix-broken-windows tenet by preventing the accumulation of silent failures that mask underlying problems.

Think of exception handling like a medical triage system. A good triage nurse doesn't treat every patient the same way—they assess specific symptoms and apply appropriate treatments. Similarly, good error handling identifies specific problems and applies appropriate responses. When you use bare `except:` clauses, you're like a triage nurse who gives everyone the same generic treatment regardless of their symptoms. This approach masks important information and often makes problems worse rather than better.

Explicit error handling serves as documentation for your code's failure modes. When someone reads `except ValueError:`, they immediately understand that this function expects string-to-number conversion failures. When they see `except (ConnectionError, TimeoutError):`, they know this code deals with network reliability issues. These specific exception types tell a story about what can go wrong and how the code handles each scenario.

## Rule Definition

Python's exception system allows you to catch and handle specific types of errors. This binding requires:

**Required practices:**
- Catch specific exception types that you expect and can handle meaningfully
- Use exception chaining (`raise ... from ...`) when re-raising with additional context
- Log sufficient context when catching exceptions to aid debugging
- Always specify the exception type: `except ValueError:` not `except:`

**Prohibited practices:**
- Bare `except:` clauses that catch all exceptions including system exits
- Catching `Exception` or `BaseException` without immediate re-raising
- Silent exception swallowing without logging or alternative action
- Using exceptions for normal control flow

**Acceptable exceptions:**
- `except Exception:` at application boundaries (with logging and re-raising)
- Specific exception types with documented recovery strategies
- Exception handlers that provide meaningful alternatives or fallbacks

## Practical Implementation

### flake8-bugbear Configuration

Add to your `.flake8` or `pyproject.toml`:

```ini
[flake8]
select = E,W,F,B
extend-ignore = E203,E501
per-file-ignores =
    __init__.py:F401

# B001: Do not use bare `except:`
# B008: Do not perform function calls in argument defaults
# B902: Invalid first argument for method
```

### Essential Exception Patterns

**1. Catch specific exceptions you can handle:**

```python
import json
from typing import Dict, Any, Optional

def parse_config_file(filepath: str) -> Optional[Dict[str, Any]]:
    """Parse configuration file with explicit error handling."""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.warning(f"Config file not found: {filepath}, using defaults")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in config file {filepath}: {e}")
        raise ConfigurationError(f"Malformed configuration file") from e
    except PermissionError:
        logger.error(f"Permission denied reading config file: {filepath}")
        raise ConfigurationError(f"Cannot access configuration file") from e
```

**2. Use exception chaining for context:**

```python
def process_user_data(user_data: Dict[str, Any]) -> User:
    """Process user data with proper error context."""
    try:
        return User(
            id=int(user_data['id']),
            email=user_data['email'],
            name=user_data['name']
        )
    except KeyError as e:
        raise ValidationError(f"Missing required field: {e}") from e
    except ValueError as e:
        raise ValidationError(f"Invalid data format: {e}") from e
```

**3. Application boundary exception handling:**

```python
def api_endpoint_handler(request: Request) -> Response:
    """Handle API requests with comprehensive error boundaries."""
    try:
        result = process_business_logic(request.data)
        return Response(result, status=200)
    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return Response({"error": str(e)}, status=400)
    except BusinessLogicError as e:
        logger.error(f"Business logic error: {e}")
        return Response({"error": "Processing failed"}, status=422)
    except Exception as e:
        # Only at application boundaries: catch all, log, and re-raise
        logger.exception(f"Unexpected error in API handler: {e}")
        return Response({"error": "Internal server error"}, status=500)
```

## Examples

```python
# ❌ BAD: Bare except clause hides all errors
def risky_operation(data):
    try:
        result = process_data(data)
        return result
    except:  # Catches EVERYTHING, including KeyboardInterrupt!
        return None  # Silent failure - we lost all error information
```

```python
# ✅ GOOD: Catch specific exceptions with meaningful handling
from typing import Optional

def risky_operation(data: str) -> Optional[str]:
    """Process data with explicit error handling."""
    try:
        result = process_data(data)
        return result
    except ValueError as e:
        logger.warning(f"Invalid data format: {e}")
        return None
    except ProcessingError as e:
        logger.error(f"Processing failed: {e}")
        # Re-raise if we can't provide a meaningful alternative
        raise
```

```python
# ❌ BAD: Overly broad exception catching
def fetch_and_parse_data(url):
    try:
        response = requests.get(url)
        data = response.json()
        return process_data(data)
    except Exception:  # Too broad! Catches network, parsing, AND processing errors
        return {}  # Can't tell what went wrong or how to fix it
```

```python
# ✅ GOOD: Specific exception handling with different strategies
import requests
from typing import Dict, Any

def fetch_and_parse_data(url: str) -> Dict[str, Any]:
    """Fetch and parse data with specific error handling."""
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
    except requests.ConnectionError as e:
        logger.error(f"Network connection failed: {e}")
        raise DataFetchError("Unable to connect to data source") from e
    except requests.Timeout as e:
        logger.warning(f"Request timeout: {e}")
        raise DataFetchError("Data source response timeout") from e
    except requests.HTTPError as e:
        logger.error(f"HTTP error {response.status_code}: {e}")
        raise DataFetchError(f"Data source returned error {response.status_code}") from e

    try:
        data = response.json()
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON response: {e}")
        raise DataParsingError("Invalid response format from data source") from e

    try:
        return process_data(data)
    except DataValidationError as e:
        logger.error(f"Data validation failed: {e}")
        raise DataProcessingError("Data source returned invalid data") from e
```

```python
# ❌ BAD: Exception used for control flow
def find_user_by_email(email):
    try:
        user = database.query(f"SELECT * FROM users WHERE email = '{email}'")
        return user[0]  # Assumes at least one result
    except IndexError:
        return None  # Using exception to detect "no results"
```

```python
# ✅ GOOD: Explicit checks instead of exception-based control flow
from typing import Optional

def find_user_by_email(email: str) -> Optional[User]:
    """Find user by email with explicit result checking."""
    users = database.query("SELECT * FROM users WHERE email = ?", (email,))
    if users:
        return User.from_db_row(users[0])
    return None
```

```python
# ❌ BAD: Silent exception swallowing loses important information
def update_user_preferences(user_id, preferences):
    try:
        validate_preferences(preferences)
        database.update_user(user_id, preferences)
        cache.invalidate_user(user_id)
    except:
        pass  # Silent failure - did validation fail? Database? Cache?
```

```python
# ✅ GOOD: Explicit handling with logging and recovery
def update_user_preferences(user_id: int, preferences: Dict[str, Any]) -> bool:
    """Update user preferences with comprehensive error handling."""
    try:
        validate_preferences(preferences)
    except ValidationError as e:
        logger.warning(f"Invalid preferences for user {user_id}: {e}")
        return False

    try:
        database.update_user(user_id, preferences)
    except DatabaseError as e:
        logger.error(f"Failed to update user {user_id} preferences: {e}")
        raise UserUpdateError("Unable to save preferences") from e

    try:
        cache.invalidate_user(user_id)
    except CacheError as e:
        # Cache failure is not critical - log but don't fail the operation
        logger.warning(f"Failed to invalidate cache for user {user_id}: {e}")

    return True
```

```python
# ❌ BAD: Re-raising without context loses the error chain
def process_config(config_path):
    try:
        with open(config_path) as f:
            config = yaml.safe_load(f)
            return validate_config(config)
    except FileNotFoundError:
        raise ConfigError("Configuration file missing")  # Lost original error
    except yaml.YAMLError:
        raise ConfigError("Invalid configuration format")  # Lost parsing details
```

```python
# ✅ GOOD: Exception chaining preserves complete error context
def process_config(config_path: str) -> Dict[str, Any]:
    """Process configuration file with complete error context."""
    try:
        with open(config_path) as f:
            config = yaml.safe_load(f)
    except FileNotFoundError as e:
        raise ConfigError(f"Configuration file not found: {config_path}") from e
    except yaml.YAMLError as e:
        raise ConfigError(f"Invalid YAML in configuration file: {config_path}") from e

    try:
        return validate_config(config)
    except ValidationError as e:
        raise ConfigError(f"Configuration validation failed") from e
```

## Related Bindings

### Core Tenets & Bindings
- [explicit-over-implicit](../../../tenets/explicit-over-implicit.md) - Error handling strategies should be visible and intentional
- [fix-broken-windows](../../../tenets/fix-broken-windows.md) - Silent failures and broad exception catching hide problems that compound over time
- [use-structured-logging](../../core/use-structured-logging.md) - Proper error logging provides context for debugging and monitoring
- [fail-fast-validation](../../core/fail-fast-validation.md) - Explicit error handling works best when combined with early validation

### Language-Specific Analogies
- [error-wrapping](../go/error-wrapping.md) - Go approach to explicit error context and chaining
- [error-context-propagation](../go/error-context-propagation.md) - Go patterns for maintaining error context through call stacks

### Related Python Patterns
- [type-hinting](../../docs/bindings/categories/python/type-hinting.md) - Explicit type hints complement explicit error handling for complete API contracts
- [testing-patterns](../../docs/bindings/categories/python/testing-patterns.md) - Explicit error handling enables better testing of failure scenarios
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md) - Unified toolchain supports consistent error handling patterns through structured logging and automation
