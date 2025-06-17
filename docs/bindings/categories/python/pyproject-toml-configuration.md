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

This binding implements our simplicity tenet by eliminating scattered configuration files across multiple formats. Instead of managing separate files for dependencies, package metadata, tool configurations, and build settings, teams get one canonical location. Configuration fragmentation creates drift, conflicts, subtle bugs, and wastes time debugging inconsistencies. Consolidating everything into pyproject.toml eliminates these problems while making projects immediately comprehensible.

## Rule Definition

**Core Requirements:**

- **Single Configuration File**: All project configuration must be in pyproject.toml exclusively
- **Required Consolidation**: Project metadata in `[project]`, dependencies in `[project.dependencies]`, build system in `[build-system]`, tools in `[tool.*]`
- **Prohibited Legacy Files**: No setup.py, setup.cfg, requirements.txt, .flake8, mypy.ini, pytest.ini, or similar tool-specific files
- **Migration Mandate**: Existing projects must migrate all configuration; CI must validate no legacy files exist
- **Limited Exceptions**: Only for complex C extensions, IDE-specific settings, or platform-specific technical requirements

## Practical Implementation

**Complete pyproject.toml Configuration:**

```toml
# Project metadata (replaces setup.py/setup.cfg)
[project]
name = "my-awesome-project"
version = "1.0.0"
description = "A comprehensive Python project with modern configuration"
readme = "README.md"
license = {text = "MIT"}
authors = [{name = "Your Name", email = "your.email@example.com"}]
requires-python = ">=3.9"

# Production dependencies (replaces requirements.txt)
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0.0",
    "click>=8.1.0",
]

# Optional dependencies (replaces requirements-dev.txt)
[project.optional-dependencies]
dev = ["pytest>=7.4.0", "mypy>=1.5.0", "ruff>=0.1.0"]
test = ["pytest>=7.4.0", "pytest-cov>=4.1.0"]

[project.urls]
Homepage = "https://github.com/username/my-awesome-project"
Repository = "https://github.com/username/my-awesome-project.git"

[project.scripts]
my-cli = "my_awesome_project.cli:main"

# Build system configuration (replaces setup.py)
[build-system]
requires = ["hatchling>=1.17.0"]
build-backend = "hatchling.build"

# Tool configurations (replaces .flake8, mypy.ini, pytest.ini, etc.)
[tool.ruff]
target-version = "py39"
line-length = 88
select = ["E", "W", "F", "I", "B"]

[tool.mypy]
python_version = "3.9"
strict = true
files = ["src", "tests"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-fail-under=85",
]

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*"]
```

**Migration Process:**

```bash
# 1. Audit existing files
find . -name "setup.py" -o -name "requirements*.txt" -o -name ".flake8"

# 2. Migrate to pyproject.toml using template above

# 3. Test configuration
uv sync && uv run pytest && uv run mypy . && uv run ruff check .

# 4. Remove legacy files after validation
rm setup.py requirements*.txt .flake8 mypy.ini pytest.ini
```

**CI Validation:**

```yaml
# .github/workflows/validate-config.yml
name: Configuration Validation
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Check for prohibited files
      run: |
        if ls setup.py requirements*.txt .flake8 2>/dev/null; then
          echo "❌ Legacy config files found. Use pyproject.toml only."
          exit 1
        fi
    - uses: astral-sh/setup-uv@v3
    - run: uv sync --locked && uv run ruff check . && uv run mypy .
```

## Examples

```bash
# ❌ BAD: Fragmented configuration across multiple files
my-project/
├── setup.py              # Package metadata
├── requirements.txt       # Dependencies
├── requirements-dev.txt   # Dev dependencies
├── .flake8               # Linting config
├── mypy.ini              # Type checking config
└── pytest.ini            # Testing config

# Developer needs to understand 6+ different file formats
# Risk of configuration conflicts and inconsistencies
```

```bash
# ✅ GOOD: Unified configuration in single file
my-project/
├── pyproject.toml        # ALL configuration in one place
├── src/my_project/
└── tests/

# Single source of truth, no conflicts possible
```

```toml
# ❌ BAD: Partial consolidation with remaining separate files
[project]
name = "my-project"
dependencies = ["requests"]

# Plus: setup.cfg, requirements-dev.txt, .flake8, mypy.ini still exist
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
addopts = ["--cov=src"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# Everything in one file, complete and consistent
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
