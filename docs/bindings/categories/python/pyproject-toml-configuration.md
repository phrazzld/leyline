---
id: pyproject-toml-configuration
last_modified: '2025-06-14'
version: '0.1.0'
derived_from: simplicity
enforced_by: repository structure validation & CI configuration checks
---

# Binding: Use pyproject.toml as the Single Source of Configuration Truth

All Python project configuration must be consolidated in pyproject.toml. Eliminate all legacy configuration files including setup.py, setup.cfg, requirements.txt, and tool-specific configuration files. This creates a single, unified source of truth that reduces complexity and improves maintainability.

## Rationale

This binding directly implements our simplicity tenet by eliminating a major source of accidental complexity—scattered configuration files across multiple formats and locations. Instead of managing separate files for dependencies (requirements.txt), package metadata (setup.py), tool configurations (setup.cfg, .flake8, mypy.ini), and build settings, teams get one canonical location that contains everything needed to understand and reproduce the project environment.

Think of pyproject.toml like a project's constitution—a single document that defines all the fundamental rules and structures governing the project. Just as a constitution provides clarity and prevents conflicts between different laws, pyproject.toml prevents configuration conflicts and inconsistencies that arise when settings are scattered across multiple files. When everything is in one place, it's impossible for different configuration files to contain contradictory instructions.

The cost of configuration fragmentation compounds over time. Each additional configuration file creates another place where settings can drift out of sync, another format to learn and remember, and another potential source of subtle bugs. Teams waste significant time debugging issues caused by configuration conflicts, outdated settings in forgotten files, or missing dependencies that weren't properly tracked. Consolidating everything into pyproject.toml eliminates these entire categories of problems while making the project structure immediately comprehensible to new team members.

## Rule Definition

Modern Python projects must use pyproject.toml as the exclusive configuration mechanism:

**Required consolidation:**
- **Project metadata** (name, version, description, authors) in `[project]` section
- **Dependencies** in `[project.dependencies]` and `[project.optional-dependencies]`
- **Build system** configuration in `[build-system]`
- **All tool configurations** under respective `[tool.*]` sections

**Prohibited legacy files:**
- **setup.py** (except for complex build requirements that cannot be expressed in pyproject.toml)
- **setup.cfg** (all settings must move to pyproject.toml)
- **requirements.txt** and requirements-*.txt files (use pyproject.toml dependencies)
- **Tool-specific config files** (.flake8, mypy.ini, pytest.ini, tox.ini) when pyproject.toml can handle the configuration

**Migration requirements:**
- Existing projects must migrate all scattered configuration to pyproject.toml
- CI/CD pipelines must validate that prohibited files do not exist or contain deprecated configuration
- Documentation must reflect the unified configuration approach

**Acceptable exceptions:**
- **Complex C extensions** that require custom setup.py logic (minimize and document)
- **IDE-specific settings** that cannot be expressed in pyproject.toml
- **Platform-specific configuration** that requires separate files for technical reasons

## Practical Implementation

### Complete pyproject.toml Template

**Comprehensive configuration example:**

```toml
# Project metadata (replaces setup.py/setup.cfg)
[project]
name = "my-awesome-project"
version = "1.0.0"
description = "A comprehensive Python project with modern configuration"
readme = "README.md"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "your.email@example.com"},
    {name = "Team Member", email = "teammate@example.com"},
]
maintainers = [
    {name = "Lead Maintainer", email = "lead@example.com"},
]
keywords = ["python", "example", "modern"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]

# Python version requirements
requires-python = ">=3.9"

# Production dependencies (replaces requirements.txt)
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
    "click>=8.1.0",
    "rich>=13.0.0",
]

# Optional dependencies (replaces requirements-dev.txt, etc.)
[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "mypy>=1.5.0",
    "ruff>=0.1.0",
    "pre-commit>=3.3.0",
]

docs = [
    "sphinx>=7.0.0",
    "sphinx-rtd-theme>=1.3.0",
    "myst-parser>=2.0.0",
]

test = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "pytest-xdist>=3.3.0",
    "pytest-mock>=3.11.0",
]

# Project URLs
[project.urls]
Homepage = "https://github.com/username/my-awesome-project"
Documentation = "https://my-awesome-project.readthedocs.io"
Repository = "https://github.com/username/my-awesome-project.git"
"Bug Tracker" = "https://github.com/username/my-awesome-project/issues"
Changelog = "https://github.com/username/my-awesome-project/blob/main/CHANGELOG.md"

# Entry points for CLI scripts
[project.scripts]
my-cli = "my_awesome_project.cli:main"
awesome-tool = "my_awesome_project.tools:cli_entry"

# Build system configuration (replaces setup.py)
[build-system]
requires = ["hatchling>=1.17.0"]
build-backend = "hatchling.build"

# Hatchling-specific configuration
[tool.hatch.build.targets.wheel]
packages = ["src/my_awesome_project"]

[tool.hatch.version]
path = "src/my_awesome_project/__init__.py"

# uv configuration
[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "mypy>=1.5.0",
    "ruff>=0.1.0",
]

# ruff configuration (replaces .flake8, setup.cfg [flake8])
[tool.ruff]
target-version = "py39"
line-length = 88
select = ["E", "W", "F", "I", "B", "C4", "UP", "SIM"]
ignore = ["E501"]
exclude = [".git", ".venv", "__pycache__", "build", "dist"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.ruff.isort]
known-first-party = ["my_awesome_project"]

# mypy configuration (replaces mypy.ini)
[tool.mypy]
python_version = "3.9"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_any_generics = true
show_error_codes = true
files = ["src", "tests"]

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false

# pytest configuration (replaces pytest.ini)
[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--verbose",
    "--tb=short",
    "--cov=src/my_awesome_project",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=85",
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
filterwarnings = [
    "error",
    "ignore::UserWarning",
    "ignore::DeprecationWarning",
]

# Coverage configuration (replaces .coveragerc)
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/test_*.py"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if self.debug:",
    "if settings.DEBUG",
    "raise AssertionError",
    "raise NotImplementedError",
    "if 0:",
    "if __name__ == .__main__.:",
    "class .*\\bProtocol\\):",
    "@(abc\\.)?abstractmethod",
]

# Pre-commit configuration (can be here or .pre-commit-config.yaml)
[tool.pre-commit]
repos = [
    {repo = "https://github.com/astral-sh/ruff-pre-commit", rev = "v0.1.0", hooks = [
        {id = "ruff", args = ["--fix"]},
        {id = "ruff-format"}
    ]},
    {repo = "https://github.com/pre-commit/mirrors-mypy", rev = "v1.5.0", hooks = [
        {id = "mypy", additional_dependencies = ["types-requests"]}
    ]},
]
```

### Migration Strategy

**Step-by-step migration from legacy configuration:**

```bash
# 1. Audit existing configuration files
find . -name "setup.py" -o -name "setup.cfg" -o -name "requirements*.txt" \
       -o -name ".flake8" -o -name "mypy.ini" -o -name "pytest.ini" \
       -o -name "tox.ini" -o -name ".coveragerc"

# 2. Create comprehensive pyproject.toml
# Use template above and migrate settings section by section

# 3. Test the migration
uv sync  # Test dependency resolution
uv run pytest  # Test pytest configuration
uv run mypy .  # Test mypy configuration
uv run ruff check .  # Test ruff configuration

# 4. Remove legacy files (after validation)
rm setup.py setup.cfg requirements*.txt .flake8 mypy.ini pytest.ini .coveragerc

# 5. Update CI/CD to validate pyproject.toml-only approach
```

**Migration checklist by file type:**

```yaml
# Migration mapping reference
Legacy Files -> pyproject.toml sections:

setup.py -> [project], [build-system], [tool.hatch.*]
setup.cfg -> [project], [tool.*] sections
requirements.txt -> [project.dependencies]
requirements-dev.txt -> [project.optional-dependencies.dev]
.flake8 -> [tool.ruff]
mypy.ini -> [tool.mypy]
pytest.ini -> [tool.pytest.ini_options]
tox.ini -> [tool.tox] (if using tox)
.coveragerc -> [tool.coverage.*]
```

### Validation and Enforcement

**CI validation example:**

```yaml
# .github/workflows/validate-config.yml
name: Configuration Validation
on: [push, pull_request]

jobs:
  validate-config:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Check for prohibited config files
      run: |
        LEGACY_FILES=(
          "setup.py"
          "setup.cfg"
          "requirements.txt"
          "requirements-dev.txt"
          ".flake8"
          "mypy.ini"
          "pytest.ini"
          ".coveragerc"
        )

        for file in "${LEGACY_FILES[@]}"; do
          if [ -f "$file" ]; then
            echo "❌ Legacy config file found: $file"
            echo "All configuration must be in pyproject.toml"
            exit 1
          fi
        done

        echo "✅ No legacy config files found"

    - name: Validate pyproject.toml
      uses: astral-sh/setup-uv@v3
    - run: uv sync --locked

    - name: Test all tool configurations
      run: |
        uv run ruff check . --no-fix
        uv run mypy .
        uv run pytest --co -q  # Collection only, validate config
```

## Examples

```bash
# ❌ BAD: Fragmented configuration across multiple files
my-project/
├── setup.py              # Package metadata and dependencies
├── setup.cfg              # Tool configurations
├── requirements.txt       # Production dependencies
├── requirements-dev.txt   # Development dependencies
├── .flake8               # Linting configuration
├── mypy.ini              # Type checking configuration
├── pytest.ini            # Testing configuration
├── .coveragerc           # Coverage configuration
└── tox.ini               # Testing environments

# Developer needs to understand 9+ different file formats
# Risk of configuration conflicts and inconsistencies
# Difficult to get complete picture of project setup
```

```bash
# ✅ GOOD: Unified configuration in single file
my-project/
├── pyproject.toml        # ALL configuration in one place
├── src/
│   └── my_project/
└── tests/

# Single source of truth for all project configuration
# No configuration conflicts possible
# Easy to understand complete project setup at a glance
```

```toml
# ❌ BAD: Mixed configuration approach (partial consolidation)
# pyproject.toml (incomplete)
[project]
name = "my-project"
dependencies = ["requests"]

# Plus these separate files still exist:
# setup.cfg - tool configurations
# requirements-dev.txt - dev dependencies
# .flake8 - linting rules
# mypy.ini - type checking
```

```toml
# ✅ GOOD: Complete configuration consolidation
[project]
name = "my-project"
dependencies = ["requests>=2.31.0"]

[project.optional-dependencies]
dev = ["pytest>=7.4.0", "mypy>=1.5.0", "ruff>=0.1.0"]

[tool.ruff]
line-length = 88
select = ["E", "W", "F", "I"]

[tool.mypy]
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["--cov=src", "--strict-markers"]

# Everything in one file, complete and consistent
```

```python
# ❌ BAD: setup.py with complex dependency management
from setuptools import setup, find_packages

# Dependencies scattered and hard to manage
setup(
    name="my-project",
    version="1.0.0",
    packages=find_packages(),
    install_requires=[
        "requests",  # No version constraints
        "click",     # Scattered across multiple files
    ],
    extras_require={
        "dev": ["pytest", "mypy"],  # Incomplete specifications
    }
)
```

```toml
# ✅ GOOD: Complete pyproject.toml specification
[project]
name = "my-project"
version = "1.0.0"
dependencies = [
    "requests>=2.31.0,<3.0.0",
    "click>=8.1.0",
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

# Clear, explicit, and complete
```

## Related Bindings

### Core Python Bindings
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md): pyproject.toml serves as the unified configuration foundation for the entire modern Python stack
- [ruff-code-quality](../../docs/bindings/categories/python/ruff-code-quality.md): ruff configuration consolidates into pyproject.toml rather than separate .flake8 or setup.cfg files
- [dependency-management](../../docs/bindings/categories/python/dependency-management.md): dependency specifications move from requirements.txt files into pyproject.toml structure

### Core Tenets & Bindings
- [simplicity](../../../tenets/simplicity.md): single configuration file dramatically reduces project complexity and cognitive overhead
- [explicit-over-implicit](../../../tenets/explicit-over-implicit.md): centralized configuration makes all project settings explicit and visible in one location
- [maintainability](../../../tenets/maintainability.md): unified configuration reduces maintenance burden and eliminates configuration drift issues

### Architecture Patterns
- [development-environment-consistency](../../core/development-environment-consistency.md): single configuration source ensures consistent environments across team members
- [ci-cd-pipeline-standards](../../core/ci-cd-pipeline-standards.md): unified configuration simplifies CI/CD setup and validation processes
