---
id: modern-python-toolchain
last_modified: '2025-06-14'
version: '0.1.0'
derived_from: automation
enforced_by: uv & ruff & mypy & pytest & CI configuration validation
---

# Binding: Use the Modern Python Toolchain Stack

All Python projects must use the modern, unified toolchain consisting of uv for dependency management, ruff for linting and formatting, mypy for type checking, and pytest for testing. Configure all tools through pyproject.toml to create a cohesive, automated development environment.

## Rationale

Unified toolchain automates all essential development tasks through consistent configuration. Modern tools (uv, ruff, mypy, pytest) work together seamlessly via pyproject.toml configuration, eliminating fragmentation and tool conflicts. Legacy approaches create inefficiency through multiple config files and slow dependency resolution.

## Rule Definition

**Required Tools:**
- **uv**: dependency management, virtual environments, package installation
- **ruff**: linting, formatting, import organization (replaces black, isort, flake8)
- **mypy**: static type checking and type safety verification
- **pytest**: test discovery, execution, and reporting

**Configuration Requirements:**
- All tool configuration in `pyproject.toml` (no separate config files)
- Tools configured to work together without conflicts
- CI/CD validates all tools pass before merges
- Reproducible development environment setup

**Prohibited Approaches:**
- Legacy tools (setuptools, black+isort separately, pip-tools) for new projects
- Mixed configuration files when pyproject.toml can handle configuration
- Unformatted or untyped code passing CI validation
- Manual dependency management or environment setup

## Practical Implementation

### pyproject.toml Configuration

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.9"
dependencies = ["requests>=2.31.0", "pydantic>=2.0.0"]

[project.optional-dependencies]
dev = ["pytest>=7.4.0", "mypy>=1.5.0", "ruff>=0.1.0"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = ["pytest>=7.4.0", "mypy>=1.5.0", "ruff>=0.1.0"]

[tool.ruff]
target-version = "py39"
line-length = 88
select = ["E", "W", "F", "I", "B", "C4", "UP"]
ignore = ["E501", "B008"]

[tool.ruff.format]
quote-style = "double"

[tool.ruff.isort]
known-first-party = ["my_project"]

[tool.mypy]
python_version = "3.9"
strict = true
warn_return_any = true
disallow_any_generics = true
disallow_untyped_calls = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["--strict-markers", "--verbose", "--cov=src", "--cov-fail-under=85"]
markers = ["slow: slow tests", "integration: integration tests"]
```

### Development Workflow

**Setup and Daily Commands:**
```bash
# Setup
uv init my-project && cd my-project
uv add requests pydantic
uv add --dev pytest mypy ruff

# Daily workflow
uv sync                               # Install/update dependencies
uv run ruff check . && uv run ruff format .  # Lint and format
uv run mypy . && uv run pytest       # Type check and test
```

**CI/CD Integration:**
```yaml
# GitHub Actions
name: Quality Gate
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: astral-sh/setup-uv@v3
    - run: uv sync --all-extras
    - run: uv run ruff check .
    - run: uv run ruff format --check .
    - run: uv run mypy .
    - run: uv run pytest --cov=src
```

## Examples

```bash
# ❌ BAD: Fragmented toolchain, multiple config files
pip install -r requirements.txt  # Slow dependency management
black . && isort . && flake8 .   # Separate tools
# Config scattered: requirements.txt, setup.cfg, .flake8, mypy.ini

# ✅ GOOD: Modern unified toolchain, single config file
uv sync                          # Fast dependency management
uv run ruff check . && uv run ruff format .  # Combined linting/formatting
# All configuration in pyproject.toml
```

```
# ❌ BAD: Legacy project structure
my-project/
├── requirements.txt, requirements-dev.txt, setup.cfg, .flake8, mypy.ini
├── src/my_project/
└── tests/

# ✅ GOOD: Modern project structure
my-project/
├── pyproject.toml              # Single configuration file
├── uv.lock                     # Reproducible dependencies
├── src/my_project/
└── tests/
```

## Related Bindings

- [automation](../../../tenets/automation.md): Modern toolchain automates all essential development tasks
- [dependency-management](dependency-management.md): uv provides foundation for lockfiles and virtual environments
- [error-handling](error-handling.md): Unified toolchain supports consistent error handling patterns
- [development-environment-consistency](../../core/development-environment-consistency.md): Tool configuration ensures consistent environments
