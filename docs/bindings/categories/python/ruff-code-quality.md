---
id: ruff-code-quality
last_modified: '2025-06-14'
version: '0.2.0'
derived_from: automation
enforced_by: ruff check --no-fix & ruff format --check & CI pipeline validation
---

# Binding: Use Ruff for Comprehensive Python Code Quality

All Python projects must use ruff as the unified solution for linting, formatting, and import organization. Configure ruff to replace multiple legacy tools (black, isort, flake8, pylint) with a single, fast, and comprehensive quality checker that enforces consistent code standards.

## Rationale

This binding implements our automation tenet by consolidating multiple manual and fragmented code quality tools into a single, lightning-fast solution. Instead of configuring and running separate tools for linting, formatting, import sorting, and additional checks, teams get comprehensive coverage through one unified tool that is often 10-100x faster than running equivalent legacy tool combinations while eliminating configuration conflicts and toolchain complexity.

## Rule Definition

**Core Requirements:**

- **Unified Tool Replacement**: Replace black, isort, flake8, and pylint with ruff for all code quality needs
- **Comprehensive Coverage**: Enable linting, formatting, import organization, and code improvement suggestions
- **Configuration Consolidation**: All ruff configuration must be in pyproject.toml under [tool.ruff] sections
- **CI Integration**: Prevent any code quality violations from being merged through automated checks
- **No Suppression**: Address ruff violations rather than suppressing with noqa comments

**Essential Components:**
- Code linting with extensive rule sets (style, bugs, security, maintainability)
- Code formatting with consistent, opinionated style
- Import organization with intelligent sorting and grouping
- Explicit rule selection with documented rationale for enabled/disabled rules

## Practical Implementation

**Complete Ruff Configuration:**

```toml
# pyproject.toml - Unified configuration replacing black, isort, flake8, pylint
[tool.ruff]
target-version = "py39"
line-length = 88

# Comprehensive rule selection
select = [
    "E", "W",   # pycodestyle errors/warnings
    "F",        # pyflakes
    "I",        # isort (import organization)
    "B",        # flake8-bugbear (common bugs)
    "C4",       # flake8-comprehensions
    "UP",       # pyupgrade (modern Python idioms)
    "SIM",      # flake8-simplify
    "S",        # flake8-bandit (security)
    "N",        # pep8-naming
    "C90",      # mccabe complexity
    "PLR", "PLW", "PLE",  # pylint refactor/warnings/errors
    "D",        # pydocstyle (docstrings)
    "ANN",      # flake8-annotations (type coverage)
    "PT",       # flake8-pytest-style
]

# Rules to ignore with justification
ignore = [
    "E501",     # Line too long (handled by formatter)
    "D100",     # Missing docstring in public module
    "ANN101",   # Missing type annotation for self
    "S101",     # Use of assert (acceptable in tests)
]

exclude = [".git", ".venv", "__pycache__", "build", "dist"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.ruff.isort]
known-first-party = ["your_project"]
split-on-trailing-comma = true

[tool.ruff.mccabe]
max-complexity = 10

[tool.ruff.pydocstyle]
convention = "google"

[tool.ruff.per-file-ignores]
"tests/**/*.py" = ["D", "S101", "PLR2004"]  # Relaxed rules for tests
```

**Development Workflow:**

```bash
# Daily workflow - replaces black, isort, flake8, pylint
uv run ruff check . --fix    # Lint and auto-fix issues
uv run ruff format .         # Format code

# CI validation
uv run ruff check . --no-fix  # Check without changes
uv run ruff format --check .  # Verify formatting
```

**CI Integration:**

```yaml
# .github/workflows/quality.yml
name: Code Quality
on: [push, pull_request]
jobs:
  ruff:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: astral-sh/setup-uv@v3
    - run: uv sync
    - run: uv run ruff check . --output-format=github
    - run: uv run ruff format --check .
```

**Pre-commit Hook:**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
```

## Examples

```python
# ❌ BAD: Code violating multiple ruff rules
import sys,os
from typing import *

def processUserData(userData,includeExtra=False):
    if userData==None:
        return {}
    result={}
    for k,v in userData.items():
        if k=='name':
            result['displayName']=v.title()
        elif k=='email':
            if '@' in v:
                result['email']=v.lower()
    if includeExtra==True:
        result['extra']=True
    return result

class dataProcessor:
    def __init__(self,config):
        self.config=config
```

```python
# ✅ GOOD: Code following ruff rules and formatting
import os
import sys
from typing import Any, Dict, Optional

def process_user_data(
    user_data: Optional[Dict[str, Any]],
    include_extra: bool = False,
) -> Dict[str, Any]:
    """Process user data with optional extra information.

    Args:
        user_data: Dictionary containing user information
        include_extra: Whether to include extra metadata

    Returns:
        Processed user data dictionary
    """
    if user_data is None:
        return {}

    result = {}
    for key, value in user_data.items():
        if key == "name":
            result["display_name"] = value.title()
        elif key == "email" and "@" in value:
            result["email"] = value.lower()

    if include_extra:
        result["extra"] = True

    return result


class DataProcessor:
    """Processes data according to configuration."""

    def __init__(self, config: Dict[str, Any]) -> None:
        self.config = config
```

```bash
# ❌ BAD: Legacy multi-tool workflow with conflicts
black .                    # Format code
isort .                    # Sort imports
flake8 .                   # Check linting
pylint src/                # Additional checks
# Multiple config files, slow execution, potential conflicts

# ✅ GOOD: Unified ruff workflow
uv run ruff check . --fix  # Lint and fix issues
uv run ruff format .       # Format code
# Single config file, fast execution, no conflicts
```

## Related Bindings

- [type-hinting](../../docs/bindings/categories/python/type-hinting.md): Ruff's ANN rules enforce comprehensive type annotation coverage required by this binding
- [pyproject-toml-configuration](../../docs/bindings/categories/python/pyproject-toml-configuration.md): Ruff configuration consolidates into pyproject.toml as the single source of truth
- [automation](../../../tenets/automation.md): Ruff automates code quality checking and formatting to eliminate manual, error-prone processes
- [no-lint-suppression](../../core/no-lint-suppression.md): Ruff violations must be addressed rather than suppressed with noqa comments
