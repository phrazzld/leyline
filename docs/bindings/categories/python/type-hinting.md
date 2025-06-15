---
derived_from: explicit-over-implicit
enforced_by: mypy --strict & pyright & flake8-annotations
id: type-hinting
last_modified: '2025-06-14'
version: '0.1.0'
---
# Binding: Use Explicit Type Hints for All Functions

All functions, methods, and class attributes must include explicit type hints. This includes function parameters, return types, and class variables for both public and private code. Never rely on type inference or leave types implicit where they could be ambiguous.

## Rationale

This binding implements our explicit-over-implicit tenet by making function contracts and data structures visible through the type system rather than hidden in documentation or comments.

Think of type hints as a contract between your code and its users. Just as a legal contract specifies exactly what each party agrees to provide, type hints specify exactly what data your functions accept and return. When you omit type hints, you're asking users to guess what your function expects—like handing someone a contract with blank spaces where the important details should be.

Type hints serve as both documentation and validation. They document your intentions for future maintainers and provide the static analysis tools with enough information to catch errors before they reach production. This dual purpose makes them far superior to comments, which can become outdated, or docstrings, which aren't checked by tools.

## Rule Definition

Python's type hint system allows you to specify the expected types for variables, function parameters, and return values. This binding requires explicit type annotations for:

- **All function parameters and return types** (public, private, and internal)
- **All class attributes and instance variables**
- **Module-level constants and variables**
- **All methods, regardless of visibility or usage scope**

Limited exceptions where type hints may be omitted:
- **Simple lambda functions** with obvious single-purpose usage (e.g., `lambda x: x * 2`)
- **Well-established dunder methods** with standardized signatures (`__str__`, `__repr__`, `__len__`)
- **Trivial property getters/setters** where the type is immediately obvious from context

You must avoid:
- Relying on type inference for any function interface
- Using overly broad types like `Any` or `object` without documented justification
- Missing return type annotations (use `-> None` for functions that don't return values)
- Assuming that "private" functions don't need type hints

## Practical Implementation

### mypy Configuration

Set up strict type checking in your `pyproject.toml` or `mypy.ini`:

```toml
[tool.mypy]
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_any_generics = true
disallow_subclassing_any = true
disallow_untyped_calls = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
```

### Essential Type Imports

```python
from typing import (
    Any, Dict, List, Optional, Union, Tuple,
    Callable, TypeVar, Generic, Protocol
)
from collections.abc import Sequence, Mapping, Iterable
```

### Function Type Hints

Always specify parameter and return types:

```python
def calculate_discount(price: float, discount_rate: float) -> float:
    """Calculate discounted price."""
    return price * (1 - discount_rate)

def process_items(items: List[str], max_count: Optional[int] = None) -> Dict[str, int]:
    """Process items and return frequency count."""
    result = {}
    count = 0
    for item in items:
        if max_count is not None and count >= max_count:
            break
        result[item] = result.get(item, 0) + 1
        count += 1
    return result
```

### Class Type Hints

Annotate class attributes and instance variables:

```python
class UserAccount:
    """Represents a user account."""

    # Class variable
    default_permissions: List[str] = ["read"]

    def __init__(self, username: str, email: str) -> None:
        # Instance variables
        self.username: str = username
        self.email: str = email
        self.permissions: List[str] = self.default_permissions.copy()
        self.last_login: Optional[datetime] = None

    def grant_permission(self, permission: str) -> bool:
        """Grant a permission to the user."""
        if permission not in self.permissions:
            self.permissions.append(permission)
            return True
        return False
```

## Examples

```python
# ❌ BAD: No type hints make the function contract unclear
def fetch_user_data(user_id, include_permissions=False):
    # What type is user_id? string? int?
    # What does this function return?
    # What type is include_permissions supposed to be?
    if include_permissions:
        return {"id": user_id, "name": "John", "permissions": ["read", "write"]}
    return {"id": user_id, "name": "John"}
```

```python
# ✅ GOOD: Clear type hints make the contract explicit
from typing import Dict, Union, Any

def fetch_user_data(
    user_id: int,
    include_permissions: bool = False
) -> Dict[str, Union[int, str, List[str]]]:
    """Fetch user data with optional permissions."""
    if include_permissions:
        return {"id": user_id, "name": "John", "permissions": ["read", "write"]}
    return {"id": user_id, "name": "John"}
```

```python
# ❌ BAD: Class without type hints
class DataProcessor:
    def __init__(self, config):
        self.config = config
        self.cache = {}
        self.max_size = 100

    def process(self, data):
        # What type of data? What does it return?
        result = self.transform(data)
        self.cache[data] = result
        return result
```

```python
# ✅ GOOD: Class with explicit type hints
from typing import Dict, Any, Optional

class DataProcessor:
    """Processes data with caching."""

    def __init__(self, config: Dict[str, Any]) -> None:
        self.config: Dict[str, Any] = config
        self.cache: Dict[str, str] = {}
        self.max_size: int = 100

    def process(self, data: str) -> str:
        """Process data and cache the result."""
        result = self.transform(data)
        self.cache[data] = result
        return result

    def transform(self, data: str) -> str:
        """Transform the input data."""
        return data.upper()
```

```python
# ❌ BAD: Generic function without proper typing
def merge_collections(collection1, collection2):
    # Are these lists? dicts? sets?
    # What gets returned?
    result = collection1.copy()
    result.update(collection2)
    return result
```

```python
# ✅ GOOD: Generic function with proper typing
from typing import TypeVar, Dict

K = TypeVar('K')  # Key type
V = TypeVar('V')  # Value type

def merge_collections(
    collection1: Dict[K, V],
    collection2: Dict[K, V]
) -> Dict[K, V]:
    """Merge two dictionaries, with collection2 values taking precedence."""
    result = collection1.copy()
    result.update(collection2)
    return result
```

```python
# ❌ BAD: Complex data processing without types
def analyze_sales_data(data):
    totals = {}
    for record in data:
        region = record["region"]
        amount = record["amount"]
        if region in totals:
            totals[region] += amount
        else:
            totals[region] = amount

    sorted_regions = sorted(totals.items(), key=lambda x: x[1], reverse=True)
    return {
        "top_region": sorted_regions[0][0],
        "total_sales": sum(totals.values()),
        "regional_breakdown": dict(sorted_regions)
    }
```

```python
# ✅ GOOD: Complex data processing with clear types
from typing import List, Dict, Any

def analyze_sales_data(data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Analyze sales data and return summary statistics."""
    totals: Dict[str, float] = {}

    for record in data:
        region: str = record["region"]
        amount: float = record["amount"]
        if region in totals:
            totals[region] += amount
        else:
            totals[region] = amount

    sorted_regions = sorted(totals.items(), key=lambda x: x[1], reverse=True)

    return {
        "top_region": sorted_regions[0][0],
        "total_sales": sum(totals.values()),
        "regional_breakdown": dict(sorted_regions)
    }
```

```python
# ❌ BAD: Private functions without type hints create maintenance burden
class UserService:
    def get_user_profile(self, user_id: int) -> Dict[str, Any]:
        """Public method with type hints."""
        raw_data = self._fetch_from_db(user_id)  # What does this return?
        processed = self._process_user_data(raw_data)  # What does this expect/return?
        return self._format_response(processed)  # Unclear types throughout

    def _fetch_from_db(self, user_id):  # Missing types
        # Implementation details...
        return {"id": user_id, "name": "John", "created_at": "2023-01-01"}

    def _process_user_data(self, data):  # Missing types
        # What type of data? What's returned?
        return {
            "user_id": data["id"],
            "display_name": data["name"].title(),
            "member_since": data["created_at"]
        }

    def _format_response(self, data):  # Missing types
        # More unclear transformations...
        return data
```

```python
# ✅ GOOD: All functions typed for complete clarity and maintainability
from typing import Dict, Any
from datetime import datetime

class UserService:
    def get_user_profile(self, user_id: int) -> Dict[str, Any]:
        """Public method with type hints."""
        raw_data = self._fetch_from_db(user_id)
        processed = self._process_user_data(raw_data)
        return self._format_response(processed)

    def _fetch_from_db(self, user_id: int) -> Dict[str, str]:
        """Private method with explicit types for maintainability."""
        # Implementation details...
        return {"id": str(user_id), "name": "John", "created_at": "2023-01-01"}

    def _process_user_data(self, data: Dict[str, str]) -> Dict[str, Any]:
        """Private method with clear input/output contracts."""
        return {
            "user_id": int(data["id"]),
            "display_name": data["name"].title(),
            "member_since": datetime.fromisoformat(data["created_at"])
        }

    def _format_response(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Private method with explicit return type."""
        return {
            "user": data["user_id"],
            "name": data["display_name"],
            "memberSince": data["member_since"].isoformat()
        }
```

```python
# ❌ BAD: Mixed typing approach creates inconsistency
def process_orders(orders: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Public function with types, but calls untyped helpers."""
    validated = []
    for order in orders:
        if _is_valid_order(order):  # What does this expect/return?
            enriched = _enrich_order_data(order)  # Unclear interface
            validated.append(enriched)
    return validated

def _is_valid_order(order):  # No type hints
    return "id" in order and "amount" in order and order["amount"] > 0

def _enrich_order_data(order):  # No type hints
    order["processed_at"] = datetime.now().isoformat()
    order["status"] = "validated"
    return order
```

```python
# ✅ GOOD: Consistent typing throughout creates reliable interfaces
from typing import List, Dict, Any
from datetime import datetime

def process_orders(orders: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Public function with types, calls fully-typed helpers."""
    validated = []
    for order in orders:
        if _is_valid_order(order):
            enriched = _enrich_order_data(order)
            validated.append(enriched)
    return validated

def _is_valid_order(order: Dict[str, Any]) -> bool:
    """Private function with explicit contract."""
    return "id" in order and "amount" in order and order["amount"] > 0

def _enrich_order_data(order: Dict[str, Any]) -> Dict[str, Any]:
    """Private function with clear input/output types."""
    enriched_order = order.copy()
    enriched_order["processed_at"] = datetime.now().isoformat()
    enriched_order["status"] = "validated"
    return enriched_order
```

```python
# ✅ GOOD: Acceptable exceptions with clear justification
from typing import List, Callable

# Simple lambda with obvious purpose - exception allowed
numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x * 2, numbers))

# Well-established dunder method - exception allowed
class Product:
    def __init__(self, name: str, price: float) -> None:
        self.name = name
        self.price = price

    def __str__(self) -> str:  # Could omit typing, but including is better
        return f"{self.name}: ${self.price:.2f}"

    def __len__(self):  # Omitting type hints acceptable for standard dunder methods
        return len(self.name)

# Complex lambda should be typed or converted to function
def create_validator(min_value: int) -> Callable[[int], bool]:
    """Create a validator function with explicit types."""
    return lambda x: x >= min_value  # Simple lambda in this context is acceptable
```

## Related Bindings

### Core Tenets & Bindings
- [explicit-over-implicit](../../../tenets/explicit-over-implicit.md) - Type hints are a direct implementation of making implicit assumptions explicit
- [maintainability](../../../tenets/maintainability.md) - Well-typed code is easier to understand, modify, and debug over time
- [no-lint-suppression](../../core/no-lint-suppression.md) - Enforce that developers don't suppress type checking errors without documented justification
- [interface-contracts](../../core/interface-contracts.md) - Type hints serve as enforceable contracts between code components

### Language-Specific Analogies
- [no-any](../typescript/no-any.md) - TypeScript equivalent: avoiding `any` type for explicit type safety
- [interface-design](../go/interface-design.md) - Go approach to explicit contracts through interface definitions

### Related Python Patterns
- [python-error-handling](../../docs/bindings/categories/rust/error-handling.md) - Explicit type hints work best with explicit error handling for complete API contracts
- [testing-patterns](../../docs/bindings/categories/python/testing-patterns.md) - Well-typed code enables more effective and targeted testing strategies
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md) - mypy provides the type checking foundation for the unified modern Python toolchain
