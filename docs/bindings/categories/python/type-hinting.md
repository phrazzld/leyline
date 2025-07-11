---
derived_from: explicit-over-implicit
enforced_by: mypy --strict & pyright & flake8-annotations
id: type-hinting
last_modified: '2025-06-14'
version: '0.2.0'
---
# Binding: Use Explicit Type Hints for All Functions

All functions, methods, and class attributes must include explicit type hints. This includes function parameters, return types, and class variables for both public and private code. Never rely on type inference or leave types implicit where they could be ambiguous.

## Rationale

This binding implements our explicit-over-implicit tenet by making function contracts and data structures visible through the type system rather than hidden in documentation or comments. Type hints serve as both documentation and validation—they document your intentions for future maintainers and provide static analysis tools with enough information to catch errors before they reach production.

## Rule Definition

**Core Requirements:**

- **All Function Types**: Function parameters and return types must be explicitly typed
- **All Class Members**: Class attributes, instance variables, and methods must be typed
- **Module Constants**: Module-level constants and variables must be typed
- **Complete Coverage**: Both public and private code must include type hints

**Limited Exceptions:**
- Simple lambda functions with obvious single-purpose usage
- Well-established dunder methods with standardized signatures
- Trivial property getters/setters where type is immediately obvious

**Prohibited Practices:**
- Relying on type inference for function interfaces
- Using overly broad types like `Any` without documented justification
- Missing return type annotations (use `-> None` for functions that don't return values)
- Assuming "private" functions don't need type hints

## Practical Implementation

**mypy Configuration:**

```toml
# pyproject.toml
[tool.mypy]
strict = true
warn_return_any = true
disallow_any_generics = true
disallow_untyped_calls = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
warn_unused_ignores = true
warn_no_return = true
```

**Essential Type Imports:**

```python
from typing import Any, Dict, List, Optional, Union, Tuple, Callable, TypeVar
from collections.abc import Sequence, Mapping, Iterable
```

## Examples

```python
# ❌ BAD: No type hints make function contracts unclear
def fetch_user_data(user_id, include_permissions=False):
    # What type is user_id? string? int?
    # What does this function return?
    if include_permissions:
        return {"id": user_id, "name": "John", "permissions": ["read", "write"]}
    return {"id": user_id, "name": "John"}

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

# ✅ GOOD: Clear type hints make contracts explicit
from typing import Dict, Union, List, Any

def fetch_user_data(
    user_id: int,
    include_permissions: bool = False
) -> Dict[str, Union[int, str, List[str]]]:
    """Fetch user data with optional permissions."""
    if include_permissions:
        return {"id": user_id, "name": "John", "permissions": ["read", "write"]}
    return {"id": user_id, "name": "John"}

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
    result = collection1.copy()
    result.update(collection2)
    return result

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
        totals[region] = totals.get(region, 0) + amount

    sorted_regions = sorted(totals.items(), key=lambda x: x[1], reverse=True)
    return {
        "top_region": sorted_regions[0][0],
        "total_sales": sum(totals.values()),
        "regional_breakdown": dict(sorted_regions)
    }

# ✅ GOOD: Complex data processing with clear types
from typing import List, Dict, Any

def analyze_sales_data(data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Analyze sales data and return summary statistics."""
    totals: Dict[str, float] = {}

    for record in data:
        region: str = record["region"]
        amount: float = record["amount"]
        totals[region] = totals.get(region, 0) + amount

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
        raw_data = self._fetch_from_db(user_id)  # What does this return?
        processed = self._process_user_data(raw_data)  # What does this expect/return?
        return self._format_response(processed)  # Unclear types throughout

    def _fetch_from_db(self, user_id):  # Missing types
        return {"id": user_id, "name": "John", "created_at": "2023-01-01"}

    def _process_user_data(self, data):  # Missing types
        return {
            "user_id": data["id"],
            "display_name": data["name"].title(),
            "member_since": data["created_at"]
        }

# ✅ GOOD: All functions typed for complete clarity
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
# ✅ GOOD: Acceptable exceptions with clear justification
from typing import Callable

# Simple lambda with obvious purpose - exception allowed
numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x * 2, numbers))

# Well-established dunder method - exception allowed
class Product:
    def __init__(self, name: str, price: float) -> None:
        self.name = name
        self.price = price

    def __str__(self) -> str:
        return f"{self.name}: ${self.price:.2f}"

    def __len__(self):  # Omitting type hints acceptable for standard dunder methods
        return len(self.name)

# Complex functions should be fully typed
def create_validator(min_value: int) -> Callable[[int], bool]:
    """Create a validator function with explicit types."""
    return lambda x: x >= min_value
```

## Related Bindings

- [explicit-over-implicit](../../../tenets/explicit-over-implicit.md): Type hints directly implement making implicit assumptions explicit
- [interface-contracts](../../core/interface-contracts.md): Type hints serve as enforceable contracts between code components
- [testing-patterns](../../docs/bindings/categories/python/testing-patterns.md): Well-typed code enables more effective and targeted testing strategies
- [ruff-code-quality](../../docs/bindings/categories/python/ruff-code-quality.md): Type checking with mypy complements ruff's code quality enforcement
