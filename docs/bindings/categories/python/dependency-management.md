---
derived_from: automation
enforced_by: uv (primary) & alternative tools (poetry, pipenv, pip-tools) & CI lockfile validation
id: python-dependency-management
last_modified: '2025-06-15'
version: '0.1.0'
---
# Binding: Use Isolated Virtual Environments and Pin Dependencies in Lockfiles

Use isolated virtual environments and generate lockfiles that pin exact dependency versions. Never install packages globally or rely on system Python. Always commit lockfiles to ensure reproducible builds.

## Rationale

This binding implements automation by transforming manual dependency management into automated, reproducible processes. It creates explicit, versioned contracts for all external code dependencies.

Virtual environments work like clean rooms in manufacturing—pristine environments isolated from contamination. Installing packages globally creates conflicts and makes troubleshooting nearly impossible.

Lockfiles serve as exact recipes for recreating dependency environments. Without them, dependency installation varies unpredictably. With lockfiles, you guarantee identical outcomes across environments.

## Rule Definition

Python dependency management requires isolation and version pinning:

**Required practices:**
- Use virtual environments for all projects
- Generate and commit lockfiles pinning exact versions
- Separate development and production dependencies
- Validate lockfile integrity in CI/CD

**Prohibited practices:**
- Installing dependencies in global Python
- Committing loose version specifiers without lockfiles
- Manual dependency installation
- Excluding lockfiles from version control

**Tools:**
- **uv** for fast dependency resolution and automatic virtual environments
- **conda** for scientific computing with non-Python dependencies

## Practical Implementation

### uv Installation

**Install uv on your system:**

```bash
# macOS and Linux (via curl)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (via PowerShell)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# via pip (cross-platform)
pip install uv

# via Homebrew (macOS)
brew install uv

# via conda
conda install -c conda-forge uv
```

**Verify installation:**

```bash
uv --version
# Should output: uv 0.4.18 (or similar recent version)
```

### uv Setup (Recommended)

**1. Initialize a new project:**

```bash
# Create new project
uv init my-project
cd my-project

# Or initialize in existing directory
uv init
```

**2. Configure pyproject.toml:**

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description"
authors = [{name = "Your Name", email = "email@example.com"}]
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

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

**3. Install and generate lockfile:**

```bash
# Install dependencies and create uv.lock
uv sync

# Add new dependencies
uv add requests
uv add --dev pytest

# Update dependencies
uv lock --upgrade
```

**4. Daily Workflow Examples:**

```bash
# Start working on an existing project
cd my-project
uv sync  # Install exact versions from uv.lock

# Run commands in the virtual environment
uv run python main.py
uv run pytest
uv run mypy .
uv run python -m pip list  # See installed packages

# Add dependencies for different environments
uv add requests  # Add to main dependencies
uv add --dev black ruff  # Add to dev dependencies
uv add --dev --optional docs sphinx  # Add to optional docs group

# Work with virtual environment directly
uv venv  # Create .venv if it doesn't exist
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
python main.py  # Run directly in activated environment
deactivate

# Update and sync dependencies
uv add requests==2.31.0  # Pin to specific version
uv lock  # Update lockfile with new constraints
```

**Managing dependency groups:**

```bash
# Install only production dependencies
uv sync --no-dev

# Install specific groups
uv sync --extra dev
uv add --optional test pytest
```

## Alternative Tools

**Poetry**: For existing projects with complex publishing workflows
**conda**: For scientific computing with non-Python dependencies
**pip-tools**: For minimal overhead with existing pip workflows

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
    - name: Install uv
      uses: astral-sh/setup-uv@v3
    - name: Install dependencies
      run: uv sync
    - name: Verify lockfile integrity
      run: uv lock --locked
    - name: Run tests
      run: uv run pytest
```

## Examples

```bash
# ❌ BAD: Installing globally creates conflicts and non-reproducible environments
pip install requests flask pytest  # Installs into system Python
python app.py  # Which versions are running? Unclear!
```

```bash
# ✅ GOOD: Virtual environment with lockfile ensures reproducibility
uv init my-app
cd my-app
uv add requests flask
uv add --dev pytest
uv sync  # Creates isolated environment + lockfile
uv run python app.py  # Clear dependency versions
```

```python
# ❌ BAD: Loose version specifiers in requirements.txt
# requirements.txt
requests
flask
pytest
```

```toml
# ✅ GOOD: Precise dependency specification with lockfile generation
# pyproject.toml
[project]
requires-python = ">=3.9"
dependencies = [
    "requests>=2.28.0",
    "flask>=2.2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.2.0",
]

# This generates uv.lock with exact versions:
# requests==2.28.2
# flask==2.2.2
# pytest==7.2.1
# ... plus all transitive dependencies
```

```bash
# ❌ BAD: Manual environment setup that's hard to reproduce
pip install virtualenv
virtualenv myenv
source myenv/bin/activate
pip install -r requirements.txt  # Loose versions, different results over time
```

```bash
# ✅ GOOD: Tool-managed environment with reproducible lockfile
uv sync  # Automatically creates virtual environment
uv shell    # Activate environment
uv run pytest  # Run commands in isolated environment

# Or with pip-tools:
python -m venv venv
source venv/bin/activate
pip install pip-tools
pip-compile requirements.in  # Generate requirements.txt lockfile
pip-sync requirements.txt    # Install exact versions
```

```dockerfile
# ❌ BAD: Dockerfile without lockfile leads to inconsistent builds
FROM python:3.9
COPY requirements.txt .
RUN pip install -r requirements.txt  # Different versions on each build!
COPY . .
CMD ["python", "app.py"]
```

```dockerfile
# ✅ GOOD: Dockerfile with lockfile ensures consistent container builds
FROM python:3.9

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application code
COPY . .

CMD ["uv", "run", "python", "app.py"]
```

```yaml
# ❌ BAD: CI without lockfile validation allows drift
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    - run: pip install -r requirements.txt  # Versions could drift
    - run: pytest
```

```yaml
# ✅ GOOD: CI with lockfile validation catches dependency drift
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    - name: Install uv
      uses: astral-sh/setup-uv@v3
    - name: Install dependencies
      run: uv sync
    - name: Verify lockfile integrity
      run: uv lock --locked  # Fails if lockfile is outdated
    - name: Run tests
      run: uv run pytest
```

```python
# ❌ BAD: Development script that assumes global packages
#!/usr/bin/env python
# setup.py or development script
import requests  # Assumes requests is globally installed
import subprocess

def deploy():
    response = requests.get('https://api.example.com/status')
    if response.status_code == 200:
        subprocess.run(['python', 'app.py'])  # Which Python? Which packages?

if __name__ == '__main__':
    deploy()
```

```python
# ✅ GOOD: Development script that uses managed environment
#!/usr/bin/env python
# scripts/deploy.py - run with: uv run python scripts/deploy.py
import requests  # Installed via uv in isolated environment
import subprocess
import sys
from pathlib import Path

def deploy():
    """Deploy application using managed environment."""
    # Verify we're in the right environment
    project_root = Path(__file__).parent.parent
    if not (project_root / 'uv.lock').exists():
        print("Error: No uv.lock found. Run 'uv sync' first.")
        sys.exit(1)

    response = requests.get('https://api.example.com/status')
    if response.status_code == 200:
        # Run in same managed environment
        subprocess.run(['uv', 'run', 'python', 'app.py'], cwd=project_root)
    else:
        print(f"Service not available: {response.status_code}")
        sys.exit(1)

if __name__ == '__main__':
    deploy()
```

## Tool Selection

**uv**: Primary choice for all new projects - ultra-fast, simple configuration, seamless CI/CD
**Poetry**: Existing projects with complex publishing needs
**conda**: Scientific computing with non-Python dependencies
**pip-tools**: Legacy projects requiring minimal changes

## Related Bindings

### Core Tenets & Bindings
- [automation](../../../tenets/automation.md) - Dependency management should be automated to prevent human error and ensure consistency
- [dependency-management](../../core/dependency-management.md) - Explicit versioning and isolation prevent hidden complexity from accumulating
- [development-environment-consistency](../../core/development-environment-consistency.md) - Virtual environments ensure development matches production
- [ci-cd-pipeline-standards](../../core/ci-cd-pipeline-standards.md) - Dependency validation should be integrated into automated pipelines

### Language-Specific Analogies
- [dependency-injection-patterns](../go/dependency-injection-patterns.md) - Go approach to managing dependencies through interfaces and dependency injection
- [module-organization](../typescript/module-organization.md) - TypeScript patterns for organizing and managing module dependencies

### Related Python Patterns
- [package-structure](../../docs/bindings/categories/python/package-structure.md) - Well-organized packages support cleaner dependency management
- [testing-patterns](../../docs/bindings/categories/python/testing-patterns.md) - Isolated dependencies enable more reliable and reproducible testing
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md) - uv serves as the foundation for the unified modern Python toolchain approach
- [pyproject-toml-configuration](../../docs/bindings/categories/python/pyproject-toml-configuration.md) - Dependency management should use pyproject.toml as the single configuration source
