---
derived_from: modularity
enforced_by: flake8-import-order & isort & code review & project templates
id: package-structure
last_modified: '2025-06-13'
version: '0.2.0'
---
# Binding: Organize Code by Feature with Clear Module Boundaries

Structure Python packages by business domain or feature rather than technical layer. Use the `src/` layout for installable packages, maintain clear import hierarchies, and prevent circular dependencies. Each module should have a single, well-defined responsibility that's evident from its name and location.

## Rationale

Implements modularity through clear boundaries and dependencies. Organizing by business domain rather than technical layer makes code immediately comprehensible and maintainable.

## Rule Definition

**Core Requirements:**

- **Domain-Based Organization**: Organize code by business domain/feature, not technical layer (avoid models/, views/, controllers/ structure)
- **src/ Layout**: Use src/ layout for installable packages to prevent import confusion
- **Single Responsibility**: Keep modules focused on one clear responsibility
- **Import Hierarchy**: Import from higher-level modules to lower-level ones, never reverse
- **Clean APIs**: Use __init__.py to create clear public interfaces for packages
- **No Circular Dependencies**: Prevent circular imports between modules through clear dependency hierarchy

**Key Principles:**
- Top-level: Business domains or major features
- Module-level: Specific capabilities within domains
- Function/class-level: Individual operations or data structures

## Practical Implementation

**Recommended Package Structure:**

```
my-project/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── users/                    # Business domain: user management
│       │   ├── __init__.py
│       │   ├── models.py            # User data structures
│       │   ├── services.py          # User business logic
│       │   └── auth.py              # Authentication functionality
│       ├── orders/                   # Business domain: order processing
│       │   ├── __init__.py
│       │   ├── models.py
│       │   ├── services.py
│       │   └── billing.py
│       ├── shared/                   # Cross-cutting concerns
│       │   ├── __init__.py
│       │   ├── database.py
│       │   ├── config.py
│       │   └── utils.py
│       └── api/                      # HTTP interface layer
│           ├── __init__.py
│           ├── users.py
│           └── orders.py
├── tests/
│   ├── test_users/
│   └── test_orders/
└── pyproject.toml
```

**Clean Package APIs:**

```python
# src/myproject/users/__init__.py
"""User management domain."""

from .models import User, UserRole
from .services import UserService, AuthenticationError
from .auth import authenticate_user, generate_token

__all__ = [
    "User",
    "UserRole",
    "UserService",
    "AuthenticationError",
    "authenticate_user",
    "generate_token",
]
```

## Examples

```python
# ❌ BAD: Layer-based organization
# models/user.py, views/user.py, controllers/user.py
from myproject.models.user import User
from myproject.controllers.user import UserController
from myproject.views.order import OrderView

# ✅ GOOD: Domain-based organization
# users/models.py, users/services.py, users/api.py
from myproject.users import User, UserService
from myproject.orders import Order, OrderService
```

```python
# ❌ BAD: Circular imports
# users/models.py imports orders, orders/models.py imports users

# ✅ GOOD: Clear dependency hierarchy
# shared/models.py - Base objects
class BaseModel:
    id: int

# users/models.py - Base domain
from myproject.shared.models import BaseModel

class User(BaseModel):
    email: str

# orders/models.py - Depends on users
from myproject.users.models import User

class Order(BaseModel):
    user_id: int

    def get_user(self) -> User:
        return User.find_by_id(self.user_id)
```

```python
# ❌ BAD: Mixed concerns in single module
# user_stuff.py - database model, HTTP endpoint, utilities all mixed

# ✅ GOOD: Separated concerns across modules
# users/models.py
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)

# users/services.py
class UserService:
    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

# users/api.py
@app.route('/users', methods=['POST'])
def create_user_endpoint():
    data = request.json
    user = UserService.create_user(data['email'], data['password'])
    return jsonify({'id': user.id})
```

```python
# ❌ BAD: Exposes internals
from .models import *
from .internal_helpers import *

# ✅ GOOD: Clean public API
from .models import User, UserRole
from .services import UserService

__all__ = ["User", "UserRole", "UserService"]
```

## Related Bindings

- [modularity](../../../tenets/modularity.md): Package structure is the primary mechanism for creating modular systems in Python
- [dependency-inversion](../../core/dependency-inversion.md): Proper package structure enables clean dependency management through clear interfaces
- [interface-contracts](../../core/interface-contracts.md): Package APIs serve as contracts between different parts of the system
- [pyproject-toml-configuration](../../docs/bindings/categories/python/pyproject-toml-configuration.md): Package metadata and configuration should be centralized in pyproject.toml
