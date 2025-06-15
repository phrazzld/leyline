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

This binding directly implements our automation tenet by establishing a unified toolchain that automates all essential development tasks—dependency management, code formatting, quality checking, type verification, and testing. Instead of managing multiple disparate tools with different configuration files and conflicting approaches, teams get a cohesive stack that works together seamlessly.

Think of the modern Python toolchain like a well-designed assembly line. Each tool handles its specialized task efficiently, passing the work cleanly to the next stage. uv manages your dependencies with lightning speed, ruff ensures consistent code style and catches common errors, mypy validates type contracts, and pytest verifies behavior. When these tools are properly integrated, they create a development experience that's both powerful and frictionless.

The cost of not adopting this unified approach is fragmentation and inefficiency. Teams using outdated toolchains often struggle with slow dependency resolution, inconsistent formatting across developers, missed type errors, and complex CI setups. They spend cognitive energy managing tool incompatibilities rather than solving business problems. The modern stack eliminates these friction points, allowing developers to focus on creating value rather than wrestling with their development environment.

## Rule Definition

The modern Python toolchain standardizes four essential categories of development automation:

**Required tools and their responsibilities:**
- **uv** for dependency management, virtual environment handling, and package installation
- **ruff** for code linting, formatting, and import organization (replaces black, isort, flake8)
- **mypy** for static type checking and type safety verification
- **pytest** for test discovery, execution, and reporting

**Configuration requirements:**
- All tool configuration must reside in `pyproject.toml` (no separate config files)
- Tools must be configured to work together without conflicts
- CI/CD pipelines must validate all tools pass before allowing merges
- Development environment setup must be reproducible through tool configuration

**Prohibited approaches:**
- Using legacy tools like setuptools, black + isort separately, or pip-tools for new projects
- Mixing configuration files (setup.cfg, tox.ini, .flake8, etc.) when pyproject.toml can handle the configuration
- Allowing unformatted or untyped code to pass CI validation
- Manual dependency management or environment setup processes

## Practical Implementation

### Complete pyproject.toml Configuration

**Minimal configuration for new projects:**

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description"
authors = [{name = "Your Name", email = "your.email@example.com"}]
requires-python = ">=3.9"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "mypy>=1.5.0",
    "ruff>=0.1.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# uv configuration
[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "mypy>=1.5.0",
    "ruff>=0.1.0",
]

# ruff configuration (replaces black, isort, flake8)
[tool.ruff]
target-version = "py39"
line-length = 88
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
]
ignore = ["E501", "B008"]  # Line too long, do not perform function calls in argument defaults

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.ruff.isort]
known-first-party = ["my_project"]

# mypy configuration
[tool.mypy]
python_version = "3.9"
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

# pytest configuration
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--verbose",
    "--tb=short",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=85",
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### Development Workflow Integration

**Daily development commands:**

```bash
# Project setup (one-time)
uv init my-project
cd my-project
uv add requests pydantic
uv add --dev pytest mypy ruff

# Development workflow
uv sync                    # Install/update dependencies
uv run ruff check .        # Lint code
uv run ruff format .       # Format code
uv run mypy .              # Type check
uv run pytest             # Run tests

# Combined quality check
uv run ruff check . && uv run ruff format . && uv run mypy . && uv run pytest
```

**Pre-commit integration:**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.5.0
    hooks:
      - id: mypy
        additional_dependencies: [types-requests]
```

### CI/CD Pipeline Configuration

**GitHub Actions workflow:**

```yaml
name: Quality Gate
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]

    steps:
    - uses: actions/checkout@v4

    - name: Install uv
      uses: astral-sh/setup-uv@v3
      with:
        enable-cache: true

    - name: Set up Python ${{ matrix.python-version }}
      run: uv python install ${{ matrix.python-version }}

    - name: Install dependencies
      run: uv sync --all-extras

    - name: Lint with ruff
      run: uv run ruff check .

    - name: Check formatting with ruff
      run: uv run ruff format --check .

    - name: Type check with mypy
      run: uv run mypy .

    - name: Test with pytest
      run: uv run pytest --cov=src --cov-report=xml

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      if: matrix.python-version == '3.11'
```

**GitLab CI configuration:**

```yaml
# .gitlab-ci.yml
stages:
  - quality
  - test

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip
    - .venv/

before_script:
  - curl -LsSf https://astral.sh/uv/install.sh | sh
  - export PATH="$HOME/.cargo/bin:$PATH"
  - uv sync

quality_check:
  stage: quality
  script:
    - uv run ruff check .
    - uv run ruff format --check .
    - uv run mypy .

test:
  stage: test
  script:
    - uv run pytest --cov=src --cov-report=term --cov-fail-under=85
  coverage: '/TOTAL.*\s+(\d+%)$/'
```

## Examples

```bash
# ❌ BAD: Fragmented toolchain with multiple config files
pip install -r requirements.txt         # Slow dependency management
black .                                  # Separate formatting tool
isort .                                  # Separate import sorting
flake8 .                                 # Separate linting
mypy .                                   # Type checking (good)
pytest                                   # Testing (good)

# Configuration scattered across:
# - requirements.txt (dependencies)
# - setup.cfg (flake8, isort config)
# - pyproject.toml (black config)
# - mypy.ini (mypy config)
# - pytest.ini (pytest config)
```

```bash
# ✅ GOOD: Modern unified toolchain
uv sync                                  # Fast dependency management
uv run ruff check . && uv run ruff format .  # Combined linting and formatting
uv run mypy .                            # Type checking
uv run pytest                           # Testing

# All configuration in single pyproject.toml file
# Consistent, fast, and reliable workflow
```

```python
# ❌ BAD: Project structure without modern toolchain
my-project/
├── requirements.txt          # Legacy dependency management
├── requirements-dev.txt      # Separate dev dependencies
├── setup.cfg                 # Tool configurations
├── .flake8                   # More tool configurations
├── mypy.ini                  # Even more configurations
├── src/
│   └── my_project/
│       └── __init__.py
└── tests/
    └── test_example.py
```

```python
# ✅ GOOD: Project structure with modern toolchain
my-project/
├── pyproject.toml           # Single source of truth for all configuration
├── uv.lock                  # Locked dependencies for reproducibility
├── .pre-commit-config.yaml  # Optional: automated quality checks
├── src/
│   └── my_project/
│       └── __init__.py
└── tests/
    └── test_example.py

# Clean, minimal, and all tools configured in one place
```

```toml
# ❌ BAD: Mixed configuration approach
# pyproject.toml (partial)
[tool.black]
line-length = 88

[tool.isort]
profile = "black"

# Plus separate files: .flake8, setup.cfg, requirements.txt, etc.
```

```toml
# ✅ GOOD: Complete unified configuration
[project]
# ... project metadata

[tool.uv]
# ... dependency configuration

[tool.ruff]
# ... all linting, formatting, and import sorting

[tool.mypy]
# ... type checking configuration

[tool.pytest.ini_options]
# ... testing configuration

# Everything in one file, tools work together harmoniously
```

## Related Bindings

### Core Python Bindings
- [dependency-management](./dependency-management.md): uv provides the foundation for modern dependency management with lockfiles and virtual environments
- [type-hinting](./type-hinting.md): mypy enforces the comprehensive type hinting standards defined in the type-hinting binding
- [ruff-code-quality](./ruff-code-quality.md): ruff configuration and usage patterns for comprehensive code quality automation

### Core Tenets & Bindings
- [automation](../../../tenets/automation.md): The modern toolchain automates all essential development tasks to eliminate manual, error-prone processes
- [simplicity](../../../tenets/simplicity.md): Unified configuration and consistent tool interfaces reduce cognitive overhead and complexity
- [maintainability](../../../tenets/maintainability.md): Consistent tooling and automated quality checks improve long-term code maintainability

### Architecture Patterns
- [ci-cd-pipeline-standards](../../core/ci-cd-pipeline-standards.md): Modern toolchain integrates seamlessly with automated CI/CD quality gates
- [development-environment-consistency](../../core/development-environment-consistency.md): Tool configuration ensures consistent development environments across team members
