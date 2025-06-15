---
id: ruff-code-quality
last_modified: '2025-06-14'
version: '0.1.0'
derived_from: automation
enforced_by: ruff check --no-fix & ruff format --check & CI pipeline validation
---

# Binding: Use Ruff for Comprehensive Python Code Quality

All Python projects must use ruff as the unified solution for linting, formatting, and import organization. Configure ruff to replace multiple legacy tools (black, isort, flake8, pylint) with a single, fast, and comprehensive quality checker that enforces consistent code standards.

## Rationale

This binding implements our automation tenet by consolidating multiple manual and fragmented code quality tools into a single, lightning-fast solution that catches errors, enforces style, and maintains consistency automatically. Instead of configuring and running separate tools for linting (flake8), formatting (black), import sorting (isort), and additional checks (pylint, bandit), teams get comprehensive coverage through one unified tool.

Think of ruff like a modern, all-in-one workshop tool that replaces a drawer full of single-purpose instruments. Just as a good multi-tool delivers the functionality of many specialized tools in a more convenient package, ruff provides the capabilities of black, isort, flake8, and many flake8 plugins in a single, extremely fast implementation. The result is not just convenience, but dramatically improved performance—ruff is often 10-100x faster than running the equivalent combination of legacy tools.

The cost of fragmented tooling is compounding complexity. Each additional tool requires its own configuration, has its own quirks and compatibility issues, and adds overhead to your development workflow. Teams often spend significant time debugging conflicts between formatters and linters, or dealing with inconsistent behavior across different environments. Ruff eliminates this complexity while providing more comprehensive checking than most teams achieve with their current tool combinations.

## Rule Definition

Ruff serves as the comprehensive code quality solution covering four essential areas:

**Core responsibilities:**
- **Code linting** with extensive rule sets covering style, bugs, security, and maintainability
- **Code formatting** with consistent, opinionated style that replaces black
- **Import organization** with intelligent sorting and grouping that replaces isort
- **Code improvement suggestions** including modernization and performance optimizations

**Configuration requirements:**
- All ruff configuration must be in `pyproject.toml` under `[tool.ruff]` sections
- Rule selection must be explicit and documented with rationale for enabled/disabled rules
- Formatting configuration must ensure consistent style across team members
- Integration with CI/CD must prevent any code quality violations from being merged

**Tool replacement strategy:**
- **Replace black** entirely with `ruff format`
- **Replace isort** entirely with ruff's import sorting capability
- **Replace flake8** and most flake8 plugins with ruff's comprehensive rule sets
- **Replace pylint** for most use cases with ruff's extensive checking capabilities

**Prohibited practices:**
- Using black, isort, or flake8 alongside ruff (creates conflicts and redundancy)
- Suppressing ruff errors with `# noqa` comments without documented justification
- Configuring different formatting rules across team members or environments
- Allowing unformatted or rule-violating code in version control

## Practical Implementation

### Complete Ruff Configuration

**Comprehensive pyproject.toml setup:**

```toml
[tool.ruff]
# Target Python version for rule compatibility
target-version = "py39"

# Line length (consistent with black default)
line-length = 88

# Rule selection - explicit and comprehensive
select = [
    # Core Python rules
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes

    # Import organization
    "I",    # isort

    # Code improvement
    "B",    # flake8-bugbear (common bugs)
    "C4",   # flake8-comprehensions (list/dict comprehensions)
    "UP",   # pyupgrade (modern Python idioms)
    "SIM",  # flake8-simplify (simplification suggestions)

    # Security and best practices
    "S",    # flake8-bandit (security issues)
    "N",    # pep8-naming (naming conventions)

    # Code complexity and maintainability
    "C90",  # mccabe (complexity checking)
    "PLR",  # pylint refactor suggestions
    "PLW",  # pylint warnings
    "PLE",  # pylint errors

    # Documentation
    "D",    # pydocstyle (docstring conventions)

    # Type annotations
    "ANN",  # flake8-annotations (type annotation coverage)

    # Pytest specific (if using pytest)
    "PT",   # flake8-pytest-style
]

# Rules to ignore with justification
ignore = [
    "E501",   # Line too long (handled by formatter)
    "D100",   # Missing docstring in public module (not always needed)
    "D104",   # Missing docstring in public package (not always needed)
    "ANN101", # Missing type annotation for self in method
    "ANN102", # Missing type annotation for cls in classmethod
    "S101",   # Use of assert (acceptable in tests and type checking)
    "PLR0913", # Too many arguments - case by case basis
]

# Files to exclude from checking
exclude = [
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    "build",
    "dist",
    "*.egg-info",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
]

# Formatting configuration
[tool.ruff.format]
# Use double quotes for strings
quote-style = "double"

# Use spaces for indentation
indent-style = "space"

# Skip magic trailing commas
skip-magic-trailing-comma = false

# Automatically detect line ending
line-ending = "auto"

# Import sorting configuration
[tool.ruff.isort]
# Known first-party modules (replace with your project name)
known-first-party = ["your_project"]

# Split imports onto separate lines
split-on-trailing-comma = true

# Combine star imports
combine-as-imports = true

# Rule-specific configuration
[tool.ruff.mccabe]
max-complexity = 10

[tool.ruff.pydocstyle]
convention = "google"  # or "numpy" or "pep257"

[tool.ruff.pylint]
max-args = 5
max-branches = 12
max-returns = 6
max-statements = 50

[tool.ruff.per-file-ignores]
# Tests can have different rules
"tests/**/*.py" = [
    "D",      # No docstring requirements in tests
    "S101",   # Allow assert in tests
    "PLR2004", # Allow magic values in tests
]

# Scripts may have more relaxed rules
"scripts/**/*.py" = [
    "D",      # No docstring requirements in scripts
    "T201",   # Allow print statements in scripts
]
```

### Development Workflow Integration

**Daily workflow commands:**

```bash
# Check code quality (dry run)
uv run ruff check .

# Fix auto-fixable issues
uv run ruff check . --fix

# Format code
uv run ruff format .

# Combined quality check and format
uv run ruff check . --fix && uv run ruff format .

# Check specific files
uv run ruff check src/my_module.py
uv run ruff format src/my_module.py

# Show all violations without fixing
uv run ruff check . --no-fix

# Show violations for specific rule categories
uv run ruff check . --select E,W,F
```

**Editor integration examples:**

VS Code (settings.json):
```json
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.linting.enabled": false,
    "python.formatting.provider": "none",
    "[python]": {
        "editor.defaultFormatter": "charliermarsh.ruff",
        "editor.codeActionsOnSave": {
            "source.organizeImports": true,
            "source.fixAll": true
        },
        "editor.formatOnSave": true
    },
    "ruff.args": ["--config", "pyproject.toml"]
}
```

### CI/CD Integration Patterns

**GitHub Actions workflow:**

```yaml
name: Code Quality
on: [push, pull_request]

jobs:
  ruff:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Install uv
      uses: astral-sh/setup-uv@v3

    - name: Install dependencies
      run: uv sync

    - name: Lint with ruff
      run: uv run ruff check . --output-format=github

    - name: Check formatting with ruff
      run: uv run ruff format --check .
```

**Pre-commit configuration:**

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

**Makefile integration:**

```makefile
.PHONY: lint format check

# Run linting with fixes
lint:
	uv run ruff check . --fix

# Format code
format:
	uv run ruff format .

# Check everything without making changes
check:
	uv run ruff check . --no-fix
	uv run ruff format --check .

# Complete quality gate
quality: check
	@echo "All quality checks passed!"
```

## Examples

```python
# ❌ BAD: Code that violates multiple ruff rules
import sys,os
import requests
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

    def process(self,data):
        return self._processInternal(data,self.config)
```

```python
# ✅ GOOD: Code following ruff rules and formatting
import os
import sys
from typing import Dict, Any, Optional

import requests


def process_user_data(
    user_data: Optional[Dict[str, Any]],
    include_extra: bool = False
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
        elif key == "email":
            if "@" in value:
                result["email"] = value.lower()

    if include_extra:
        result["extra"] = True

    return result


class DataProcessor:
    """Processes data according to configuration."""

    def __init__(self, config: Dict[str, Any]) -> None:
        self.config = config

    def process(self, data: Any) -> Any:
        """Process data using internal configuration."""
        return self._process_internal(data, self.config)
```

```bash
# ❌ BAD: Legacy multi-tool workflow
black .                    # Format code
isort .                    # Sort imports
flake8 .                   # Check linting
pylint src/                # Additional checks

# Multiple config files needed:
# - pyproject.toml (black config)
# - setup.cfg (isort, flake8 config)
# - .pylintrc (pylint config)
```

```bash
# ✅ GOOD: Unified ruff workflow
uv run ruff check . --fix  # Lint and fix issues
uv run ruff format .       # Format code

# Single configuration in pyproject.toml
# Faster execution, consistent results
```

```toml
# ❌ BAD: Fragmented tool configuration across multiple files
# pyproject.toml
[tool.black]
line-length = 88

# setup.cfg
[flake8]
max-line-length = 88
ignore = E203,W503

[isort]
profile = black
```

```toml
# ✅ GOOD: Unified ruff configuration
[tool.ruff]
line-length = 88
select = ["E", "W", "F", "I", "B", "C4", "UP"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"

[tool.ruff.isort]
profile = "black"

# Everything in one place, no conflicts
```

## Related Bindings

### Core Python Bindings
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md): ruff serves as the code quality component of the unified Python development stack
- [type-hinting](../../docs/bindings/categories/python/type-hinting.md): ruff's ANN rules enforce comprehensive type annotation coverage
- [dependency-management](../../docs/bindings/categories/python/dependency-management.md): ruff integrates with uv-based workflows for consistent development experience

### Core Tenets & Bindings
- [automation](../../../tenets/automation.md): ruff automates code quality checking and formatting to eliminate manual, error-prone processes
- [no-lint-suppression](../../core/no-lint-suppression.md): ruff violations must be addressed rather than suppressed with noqa comments
- [maintainability](../../../tenets/maintainability.md): consistent code style and quality checking improve long-term code maintainability

### Architecture Patterns
- [ci-cd-pipeline-standards](../../core/ci-cd-pipeline-standards.md): ruff integrates into CI/CD pipelines as an automated quality gate
- [development-environment-consistency](../../core/development-environment-consistency.md): ruff configuration ensures consistent code style across team members and environments
