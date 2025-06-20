---
derived_from: modularity
enforced_by: flake8-import-order & isort & code review & project templates
id: package-structure
last_modified: '2025-06-13'
version: '0.1.0'
---
# Binding: Organize Code by Feature with Clear Module Boundaries

Structure Python packages by business domain or feature rather than technical layer. Use the `src/` layout for installable packages, maintain clear import hierarchies, and prevent circular dependencies. Each module should have a single, well-defined responsibility that's evident from its name and location.

## Rationale

This binding implements our modularity tenet by creating clear boundaries and dependencies between different parts of your system. Good package structure serves as a map for your codebase—organizing code by business purpose rather than technical implementation details makes the system immediately comprehensible to anyone reading it. When someone looks for "user authentication," they should find it in a `users` or `auth` module, not scattered across `models`, `views`, and `controllers` directories.

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

**Import Organization:**

```toml
# pyproject.toml - isort configuration
[tool.isort]
profile = "black"
line_length = 88
known_first_party = ["myproject"]
sections = ["FUTURE", "STDLIB", "THIRDPARTY", "FIRSTPARTY", "LOCALFOLDER"]
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
# ❌ BAD: Layer-based organization mixes concerns across files
# myproject/
# ├── models/
# │   ├── user.py      # User data structure
# │   ├── order.py     # Order data structure
# ├── views/
# │   ├── user.py      # User HTTP endpoints
# │   ├── order.py     # Order HTTP endpoints
# └── controllers/
#     ├── user.py      # User business logic
#     └── order.py     # Order business logic

# This creates tight coupling - changes require editing 3+ files
from myproject.models.user import User
from myproject.models.order import Order
from myproject.controllers.user import UserController
from myproject.views.order import OrderView

# ✅ GOOD: Domain-based organization groups related concerns
# myproject/
# ├── users/
# │   ├── models.py     # User data and behavior
# │   ├── services.py   # User business operations
# │   └── api.py        # User HTTP interface
# ├── orders/
# │   ├── models.py     # Order data and behavior
# │   ├── services.py   # Order business operations
# │   └── api.py        # Order HTTP interface
# └── shared/
#     ├── database.py   # Shared database utilities
#     └── config.py     # Shared configuration

# Clean domain imports - changes stay within feature modules
from myproject.users import User, UserService
from myproject.orders import Order, OrderService
```

```python
# ❌ BAD: Circular imports between modules
# users/models.py
from myproject.orders.models import Order

class User:
    def get_orders(self) -> List[Order]:
        return Order.find_by_user_id(self.id)

# orders/models.py
from myproject.users.models import User

class Order:
    def get_user(self) -> User:
        return User.find_by_id(self.user_id)
# Creates circular dependency: users -> orders -> users

# ✅ GOOD: Clear dependency hierarchy prevents circular imports
# shared/models.py - Base domain objects
from abc import ABC

class BaseModel(ABC):
    """Base model with common functionality."""
    id: int

    @classmethod
    def find_by_id(cls, obj_id: int):
        pass

# users/models.py - Users domain
from myproject.shared.models import BaseModel

class User(BaseModel):
    """User model with user-specific behavior."""
    email: str
    name: str

# orders/models.py - Orders domain (depends on users)
from myproject.shared.models import BaseModel
from myproject.users.models import User

class Order(BaseModel):
    """Order model that references users."""
    user_id: int
    total: float

    def get_user(self) -> User:
        return User.find_by_id(self.user_id)
```

```python
# ❌ BAD: Mixed concerns in single module
# myproject/user_stuff.py
import bcrypt
from flask import request, jsonify
from sqlalchemy import Column, Integer, String

class User(Base):
    # Database model mixed with...
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)

def hash_password(password):
    # Utility function mixed with...
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt())

@app.route('/users', methods=['POST'])
def create_user():
    # HTTP endpoint mixed with...
    data = request.json
    user = User(email=data['email'])
    return jsonify({'id': user.id})

def send_welcome_email(user_email):
    # Email service - all concerns mixed together
    pass

# ✅ GOOD: Clear separation of concerns across modules
# users/models.py
from sqlalchemy import Column, Integer, String
from myproject.shared.database import Base

class User(Base):
    """User database model."""
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True)

# users/services.py
import bcrypt
from .models import User

class UserService:
    """User business operations."""

    @staticmethod
    def hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    @classmethod
    def create_user(cls, email: str, password: str) -> User:
        hashed_pw = cls.hash_password(password)
        user = User(email=email, password_hash=hashed_pw)
        # Save and send welcome email
        return user

# users/api.py
from flask import request, jsonify
from .services import UserService

@app.route('/users', methods=['POST'])
def create_user_endpoint():
    """HTTP endpoint for user creation."""
    data = request.json
    user = UserService.create_user(data['email'], data['password'])
    return jsonify({'id': user.id})
```

```python
# ❌ BAD: Poor __init__.py exposes internal implementation
# users/__init__.py
from .models import *
from .services import *
from .internal_helpers import *
# Exposes everything, including internals

# ✅ GOOD: Clean __init__.py exposes only public API
# users/__init__.py
"""User management domain."""

from .models import User, UserRole
from .services import UserService
from .exceptions import AuthenticationError

__all__ = ["User", "UserRole", "UserService", "AuthenticationError"]
# Clean, stable API that won't break when internals change
```

## Related Bindings

- [modularity](../../../tenets/modularity.md): Package structure is the primary mechanism for creating modular systems in Python
- [dependency-inversion](../../core/dependency-inversion.md): Proper package structure enables clean dependency management through clear interfaces
- [interface-contracts](../../core/interface-contracts.md): Package APIs serve as contracts between different parts of the system
- [pyproject-toml-configuration](../../docs/bindings/categories/python/pyproject-toml-configuration.md): Package metadata and configuration should be centralized in pyproject.toml
