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

This binding implements our modularity tenet by creating clear boundaries and dependencies between different parts of your system. It also supports our simplicity tenet by making the codebase's structure immediately apparent to anyone reading it.

Think of package structure like organizing a library. A well-organized library groups books by subject (history, science, literature) rather than by physical characteristics (size, color, publisher). Similarly, a well-structured Python package groups code by business purpose rather than technical implementation details. When someone looks for "user authentication," they should find it in a `users` or `auth` module, not scattered across `models`, `views`, and `controllers` directories.

Good package structure serves as a map for your codebase. Just as city planners design neighborhoods with clear boundaries and logical connections, package designers should create modules with clear responsibilities and minimal coupling. This organization becomes critical as projects grow—what starts as a simple script can evolve into a complex system, and early structural decisions determine whether that evolution is smooth or painful.

## Rule Definition

Python's module system allows flexible organization, but this flexibility can lead to chaos without consistent guidelines. This binding requires:

**Required practices:**
- Organize code by business domain/feature, not technical layer
- Use the `src/` layout for installable packages to prevent import confusion
- Keep modules focused on a single responsibility
- Import from higher-level modules to lower-level ones, never the reverse
- Use `__init__.py` to create clean public APIs for packages

**Prohibited practices:**
- Circular imports between modules
- Organizing code primarily by technical layer (models/, views/, controllers/)
- Mixing business logic with framework-specific code in the same module
- Deep nesting (more than 3-4 levels) without clear justification

**Package layout principles:**
- **Top-level**: Business domains or major features
- **Module-level**: Specific capabilities within domains
- **Function/class-level**: Individual operations or data structures

## Practical Implementation

### Recommended src/ Layout

```
my-project/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── users/
│       │   ├── __init__.py
│       │   ├── models.py
│       │   ├── services.py
│       │   └── auth.py
│       ├── orders/
│       │   ├── __init__.py
│       │   ├── models.py
│       │   ├── services.py
│       │   └── billing.py
│       ├── shared/
│       │   ├── __init__.py
│       │   ├── database.py
│       │   ├── config.py
│       │   └── utils.py
│       └── api/
│           ├── __init__.py
│           ├── main.py
│           ├── users.py
│           └── orders.py
├── tests/
│   ├── test_users/
│   └── test_orders/
├── pyproject.toml
└── README.md
```

### Import Organization with isort

**Configure isort in pyproject.toml:**

```toml
[tool.isort]
profile = "black"
multi_line_output = 3
line_length = 88
known_first_party = ["myproject"]
known_third_party = ["fastapi", "pydantic", "sqlalchemy"]
sections = ["FUTURE", "STDLIB", "THIRDPARTY", "FIRSTPARTY", "LOCALFOLDER"]
```

**Example well-organized imports:**

```python
# Standard library imports
import datetime
import logging
from pathlib import Path
from typing import List, Optional

# Third-party imports
import requests
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String

# First-party imports
from myproject.shared.database import Base
from myproject.shared.config import settings

# Local imports
from .models import User
from .services import UserService
```

### Clean Package APIs

**Use __init__.py to expose clean interfaces:**

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
# ❌ BAD: Layer-based organization mixes concerns
# myproject/
# ├── models/
# │   ├── user.py      # User data structure
# │   ├── order.py     # Order data structure
# │   └── product.py   # Product data structure
# ├── views/
# │   ├── user.py      # User HTTP endpoints
# │   ├── order.py     # Order HTTP endpoints
# │   └── product.py   # Product HTTP endpoints
# └── controllers/
#     ├── user.py      # User business logic
#     ├── order.py     # Order business logic
#     └── product.py   # Product business logic

# This creates tight coupling across layers
from myproject.models.user import User
from myproject.models.order import Order
from myproject.controllers.user import UserController
from myproject.views.order import OrderView
# Changes to user functionality require editing 3+ files
```

```python
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

# Clean domain imports
from myproject.users import User, UserService
from myproject.orders import Order, OrderService
# Changes to user functionality stay within users/ module
```

```python
# ❌ BAD: Circular import between modules
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

# This creates circular dependency: users -> orders -> users
```

```python
# ✅ GOOD: Clear dependency hierarchy prevents circular imports
# shared/models.py - Base domain objects
from abc import ABC
from typing import Any, Dict

class BaseModel(ABC):
    """Base model with common functionality."""
    id: int

    @classmethod
    def find_by_id(cls, obj_id: int) -> Any:
        """Find object by ID."""
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
    # Database model
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True)

def hash_password(password):
    # Utility function
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt())

@app.route('/users', methods=['POST'])
def create_user():
    # HTTP endpoint
    data = request.json
    user = User(email=data['email'])
    db.session.add(user)
    return jsonify({'id': user.id})

def send_welcome_email(user_email):
    # Email service
    # ... email sending logic
```

```python
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
from typing import Optional
from .models import User
from .notifications import send_welcome_email

class UserService:
    """User business operations."""

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password securely."""
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    @classmethod
    def create_user(cls, email: str, password: str) -> User:
        """Create new user with welcome email."""
        hashed_pw = cls.hash_password(password)
        user = User(email=email, password_hash=hashed_pw)
        db.session.add(user)
        db.session.commit()
        send_welcome_email(user.email)
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

# users/notifications.py
def send_welcome_email(user_email: str) -> None:
    """Send welcome email to new user."""
    # ... email sending logic
```

```python
# ❌ BAD: No src/ layout causes import confusion
# myproject/
# ├── myproject/
# │   ├── __init__.py
# │   └── core.py
# ├── tests/
# │   └── test_core.py
# └── setup.py

# In tests/test_core.py:
import myproject.core  # This could import from current directory OR installed package!
```

```
# ✅ GOOD: src/ layout prevents import ambiguity
myproject/
├── src/
│   └── myproject/
│       ├── __init__.py
│       └── core.py
├── tests/
│   └── test_core.py
├── pyproject.toml
└── setup.py

# In tests/test_core.py:
import myproject.core  # Unambiguously imports from installed package
```

```python
# ❌ BAD: Poor __init__.py exposes internal implementation
# users/__init__.py
from .models import *
from .services import *
from .internal_helpers import *
from .database_utils import *
# Exposes everything, including internal details

# Using the package:
from myproject.users import UserDatabaseConnection, _internal_cache_helper
# Users can accidentally depend on internal implementation
```

```python
# ✅ GOOD: Clean __init__.py exposes only public API
# users/__init__.py
"""User management domain.

This package provides user creation, authentication, and management
functionality. For most use cases, import User and UserService.
"""

from .models import User, UserRole
from .services import UserService
from .exceptions import AuthenticationError, UserNotFoundError

__all__ = [
    "User",
    "UserRole",
    "UserService",
    "AuthenticationError",
    "UserNotFoundError",
]

# Using the package:
from myproject.users import User, UserService
# Clean, stable API that won't break when internals change
```

## Tool Configuration

### flake8-import-order

```ini
# .flake8
[flake8]
import-order-style = pycharm
application-import-names = myproject
```

### isort Integration

```toml
# pyproject.toml
[tool.isort]
profile = "black"
src_paths = ["src", "tests"]
known_first_party = ["myproject"]
force_sort_within_sections = true
```

## Related Bindings

### Core Tenets & Bindings
- [modularity](../../../tenets/modularity.md) - Package structure is the primary mechanism for creating modular systems in Python
- [simplicity](../../../tenets/simplicity.md) - Clear organization reduces cognitive overhead and makes systems easier to understand
- [dependency-inversion](../../core/dependency-inversion.md) - Proper package structure enables clean dependency management
- [interface-contracts](../../core/interface-contracts.md) - Package APIs serve as contracts between different parts of the system

### Language-Specific Analogies
- [package-design](../go/package-design.md) - Go approach to organizing code by business domain with clear package boundaries
- [module-organization](../typescript/module-organization.md) - TypeScript patterns for organizing modules by feature with clean import hierarchies

### Related Python Patterns
- [dependency-management](../../docs/bindings/categories/python/dependency-management.md) - Well-structured packages support cleaner dependency management and isolation
- [testing-patterns](../../docs/bindings/categories/python/testing-patterns.md) - Good package structure enables more effective testing and test organization
- [pyproject-toml-configuration](../../docs/bindings/categories/python/pyproject-toml-configuration.md) - Package metadata and build configuration should be centralized in pyproject.toml
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md) - Unified toolchain approach supports consistent package structure patterns
