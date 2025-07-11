---
derived_from: explicit-over-implicit
enforced_by: flake8-bugbear & pylint & bandit
id: python-error-handling
last_modified: '2025-06-13'
version: '0.2.0'
---
# Binding: Handle Errors Explicitly with Specific Exception Types

Never use bare `except:` clauses or catch overly broad exception types without explicit justification. Always handle specific exceptions that you expect and can meaningfully respond to. When you must catch broad exceptions, immediately re-raise them or handle them in a documented, deliberate way.

## Rationale

Explicit error handling makes failure modes visible and intentional. Specific exception types document what can go wrong and how code responds. Bare `except:` clauses hide problems and mask debugging information, while specific exceptions enable meaningful error recovery and clear failure communication.

## Rule Definition

**Required Practices:**
- Catch specific exception types you expect and can handle meaningfully
- Use exception chaining (`raise ... from ...`) when re-raising with context
- Log sufficient context when catching exceptions
- Always specify exception type: `except ValueError:` not `except:`

**Prohibited Practices:**
- Bare `except:` clauses catching all exceptions including system exits
- Catching `Exception` without immediate re-raising
- Silent exception swallowing without logging
- Using exceptions for normal control flow

**Acceptable Exceptions:**
- `except Exception:` at application boundaries (with logging and re-raising)
- Specific exception types with documented recovery strategies

## Practical Implementation

**Configuration:**
```ini
[flake8]
select = E,W,F,B  # B001: Do not use bare `except:`
```

**Essential Patterns:**
```python
# 1. Catch specific exceptions
def parse_config_file(filepath: str) -> Optional[Dict[str, Any]]:
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.warning(f"Config file not found: {filepath}")
        return None
    except json.JSONDecodeError as e:
        raise ConfigurationError("Malformed config file") from e

# 2. Exception chaining for context
def process_user_data(user_data: Dict[str, Any]) -> User:
    try:
        return User(id=int(user_data['id']), email=user_data['email'])
    except KeyError as e:
        raise ValidationError(f"Missing field: {e}") from e
    except ValueError as e:
        raise ValidationError(f"Invalid format: {e}") from e

# 3. Application boundary handling
def api_handler(request: Request) -> Response:
    try:
        result = process_business_logic(request.data)
        return Response(result, status=200)
    except ValidationError as e:
        return Response({"error": str(e)}, status=400)
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return Response({"error": "Internal error"}, status=500)
```

## Examples

```python
# ❌ BAD: Bare except catches everything, silent failure
def risky_operation(data):
    try:
        return process_data(data)
    except:  # Catches KeyboardInterrupt, SystemExit!
        return None  # Lost all error information

# ✅ GOOD: Specific exceptions with meaningful handling
def risky_operation(data: str) -> Optional[str]:
    try:
        return process_data(data)
    except ValueError as e:
        logger.warning(f"Invalid data format: {e}")
        return None
    except ProcessingError:
        raise  # Re-raise if can't provide alternative

# ❌ BAD: Overly broad catching
def fetch_data(url):
    try:
        response = requests.get(url)
        return response.json()
    except Exception:  # Too broad!
        return {}

# ✅ GOOD: Specific exceptions with context
def fetch_data(url: str) -> Dict[str, Any]:
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.ConnectionError as e:
        raise DataFetchError("Connection failed") from e
    except requests.Timeout as e:
        raise DataFetchError("Request timeout") from e
    except json.JSONDecodeError as e:
        raise DataParsingError("Invalid JSON") from e

# ❌ BAD: Exception for control flow
def find_user(email):
    try:
        return database.query(f"SELECT * FROM users WHERE email = '{email}'")[0]
    except IndexError:
        return None

# ✅ GOOD: Explicit checks
def find_user(email: str) -> Optional[User]:
    users = database.query("SELECT * FROM users WHERE email = ?", (email,))
    return User.from_db_row(users[0]) if users else None
```

## Related Bindings

- [explicit-over-implicit](../../../tenets/explicit-over-implicit.md): Error handling strategies should be visible and intentional
- [use-structured-logging](../../core/use-structured-logging.md): Proper error logging provides debugging context
- [fail-fast-validation](../../core/fail-fast-validation.md): Explicit error handling works with early validation
- [modern-python-toolchain](modern-python-toolchain.md): Unified toolchain supports consistent error handling
