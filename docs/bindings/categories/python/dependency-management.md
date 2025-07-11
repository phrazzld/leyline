---
derived_from: automation
enforced_by: uv (primary) & alternative tools (poetry, pipenv, pip-tools) & CI lockfile validation
id: python-dependency-management
last_modified: '2025-06-15'
version: '0.2.0'
---
# Binding: Use Isolated Virtual Environments and Pin Dependencies in Lockfiles

Use isolated virtual environments and generate lockfiles that pin exact dependency versions. Never install packages globally or rely on system Python. Always commit lockfiles to ensure reproducible builds.

## Rationale

This binding implements automation by transforming manual dependency management into reproducible processes. Virtual environments provide isolation like clean rooms, preventing conflicts. Lockfiles serve as exact recipes for recreating dependency environments, guaranteeing identical outcomes across environments.

## Rule Definition

**Required Practices:**
- Use virtual environments for all projects
- Generate and commit lockfiles pinning exact versions
- Separate development and production dependencies
- Validate lockfile integrity in CI/CD

**Prohibited Practices:**
- Installing dependencies in global Python
- Committing loose version specifiers without lockfiles
- Manual dependency installation
- Excluding lockfiles from version control

**Recommended Tools:**
- **uv** (primary): Fast dependency resolution with automatic virtual environments
- **conda**: Scientific computing with non-Python dependencies

## Practical Implementation

**Installation & Setup:**

```bash
# Install uv (primary tool)
curl -LsSf https://astral.sh/uv/install.sh | sh  # macOS/Linux
# or: pip install uv

# Initialize project
uv init my-project && cd my-project
```

**Project Configuration:**

```toml
# pyproject.toml
[project]
name = "my-project"
requires-python = ">=3.9"
dependencies = [
    "requests>=2.28.0",
    "pydantic>=1.10.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "ruff>=0.1.0",
    "mypy>=0.991",
]
```

**Workflow:**

```bash
# Install dependencies and create lockfile
uv sync

# Add dependencies
uv add requests
uv add --dev pytest

# Run commands in isolated environment
uv run python main.py
uv run pytest

# Update dependencies
uv lock --upgrade
```

**Alternative Tools:**
- **Poetry**: Complex publishing workflows
- **conda**: Scientific computing with non-Python dependencies
- **pip-tools**: Minimal overhead with existing pip workflows

## CI/CD Integration

```yaml
# GitHub Actions with uv
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    - uses: astral-sh/setup-uv@v3
    - run: uv sync
    - run: uv lock --locked  # Verify lockfile integrity
    - run: uv run pytest
```

## Examples

```bash
# ❌ BAD: Global installation without isolation
pip install requests flask pytest  # System contamination
python app.py  # Which versions? Unknown!
```

```bash
# ✅ GOOD: Isolated environment with lockfile
uv init my-app && cd my-app
uv add requests flask
uv add --dev pytest
uv sync  # Creates .venv + uv.lock
uv run python app.py  # Clear, reproducible environment
```

```dockerfile
# ❌ BAD: Non-reproducible container builds
FROM python:3.9
COPY requirements.txt .
RUN pip install -r requirements.txt  # Different versions each build
```

```dockerfile
# ✅ GOOD: Reproducible container with lockfile
FROM python:3.9
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .
CMD ["uv", "run", "python", "app.py"]
```

## Related Bindings

- [automation](../../../tenets/automation.md): Dependency management should be automated to prevent human error
- [dependency-management](../../core/dependency-management.md): Explicit versioning prevents hidden complexity accumulation
- [development-environment-consistency](../../core/development-environment-consistency.md): Virtual environments ensure dev matches production
- [modern-python-toolchain](modern-python-toolchain.md): uv serves as foundation for unified Python toolchain
- [pyproject-toml-configuration](pyproject-toml-configuration.md): Use pyproject.toml as single configuration source
