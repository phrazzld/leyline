---
derived_from: automation
enforced_by: uv & poetry & pipenv & pip-tools & CI lockfile validation
id: python-dependency-management
last_modified: '2025-06-14'
version: '0.1.0'
---
# Binding: Use Isolated Virtual Environments and Pin Dependencies in Lockfiles

All Python projects must use isolated virtual environments and generate lockfiles that pin exact dependency versions. Never install packages globally or rely on system Python for development. Always commit lockfiles to version control to ensure reproducible builds across all environments.

## Rationale

This binding implements our automation tenet by transforming manual, error-prone dependency management into automated, reproducible processes. It also supports our dependency-management principle by creating explicit, versioned contracts for all external code dependencies.

Think of virtual environments like clean rooms in manufacturing. Just as semiconductor fabrication requires pristine environments isolated from contamination, Python development requires pristine dependency environments isolated from conflicts. When you install packages globally or use system Python, you're like a manufacturer mixing products from different production lines—contamination is inevitable, and troubleshooting becomes nearly impossible.

Lockfiles serve as exact recipes for recreating your dependency environment. Without them, saying "install Flask" is like telling a chef to "add some flour"—the results will vary depending on what's available. With lockfiles, you're providing precise measurements that guarantee the same outcome every time. This precision becomes critical when debugging issues, deploying to production, or onboarding new team members.

## Rule Definition

Python's dependency ecosystem requires careful isolation and version management. This binding mandates:

**Required practices:**
- Use virtual environments for all projects (via `venv`, `virtualenv`, `conda`, or tool-managed environments)
- Generate and commit lockfiles that pin exact versions and transitive dependencies
- Use dependency management tools that separate development and production dependencies
- Validate lockfile integrity in CI/CD pipelines

**Prohibited practices:**
- Installing project dependencies in global Python or system Python
- Committing loose version specifiers without lockfiles (e.g., `requests>=2.0`)
- Manual dependency installation without tool-managed environments
- Ignoring or excluding lockfiles from version control

**Recommended tools:**
- **uv** for ultra-fast dependency management with automatic virtual environment handling
- **Poetry** for modern dependency management (alternative approach)
- **Pipenv** for traditional pip-based workflows (alternative approach)
- **pip-tools** for minimal setups that compile requirements.txt files (alternative approach)
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
uv sync  # Install updated dependencies

# Clean up and troubleshoot
uv clean  # Remove cached builds
uv sync --reinstall  # Reinstall all packages
uv lock --upgrade-package requests  # Upgrade specific package
```

**5. Managing Dependency Groups:**

```bash
# Install only production dependencies
uv sync --no-dev

# Install specific dependency groups
uv sync --extra dev
uv sync --extra docs,test

# Add dependencies to specific groups
uv add --optional test pytest coverage
uv add --optional docs sphinx sphinx-rtd-theme
```

## Alternative Approaches

### Poetry Setup

**1. Initialize a new project:**

```bash
# Create new project
poetry new my-project
cd my-project

# Or initialize in existing directory
poetry init
```

**2. Configure pyproject.toml:**

```toml
[tool.poetry]
name = "my-project"
version = "0.1.0"
description = "Project description"
authors = ["Your Name <email@example.com>"]

[tool.poetry.dependencies]
python = "^3.9"
requests = "^2.28.0"
pydantic = "^1.10.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0.0"
ruff = "^0.1.0"
mypy = "^0.991"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

**3. Install and generate lockfile:**

```bash
# Install dependencies and create poetry.lock
poetry install

# Add new dependencies
poetry add requests
poetry add --group dev pytest

# Update dependencies
poetry update
```

### pip-tools Setup

**1. Create requirements files:**

```txt
# requirements.in
requests>=2.28.0
pydantic>=1.10.0

# requirements-dev.in
-r requirements.in
pytest>=7.0.0
ruff>=0.1.0
mypy>=0.991
```

**2. Generate lockfiles:**

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install pip-tools and compile lockfiles
pip install pip-tools
pip-compile requirements.in
pip-compile requirements-dev.in

# Install from lockfiles
pip-sync requirements.txt requirements-dev.txt
```

### CI/CD Integration

**GitHub Actions example:**

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'

    - name: Install uv
      uses: astral-sh/setup-uv@v3
      with:
        version: "latest"

    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: .venv
        key: venv-${{ runner.os }}-${{ hashFiles('**/uv.lock') }}

    - name: Install dependencies
      run: uv sync

    - name: Verify lockfile is up to date
      run: uv lock --locked

    - name: Run tests
      run: uv run pytest
```

**Matrix testing with multiple Python versions:**

```yaml
name: Test Matrix
on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.9', '3.10', '3.11', '3.12']

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install uv
      uses: astral-sh/setup-uv@v3

    - name: Install dependencies
      run: uv sync

    - name: Verify lockfile integrity
      run: uv lock --locked

    - name: Run linting
      run: |
        uv run ruff check .
        uv run ruff format --check .

    - name: Run type checking
      run: uv run mypy .

    - name: Run tests with coverage
      run: uv run pytest --cov=. --cov-report=xml

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      if: matrix.python-version == '3.11' && matrix.os == 'ubuntu-latest'
```

**Production deployment with uv:**

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Install uv
      uses: astral-sh/setup-uv@v3

    - name: Verify production lockfile
      run: |
        uv sync --no-dev --locked
        uv run python -c "import sys; print(sys.path)"

    - name: Build Docker image
      run: |
        docker build -t myapp .
        docker run --rm myapp uv run python --version
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

## Tool Comparison

| Tool | Strengths | Best For |
|------|-----------|----------|
| **uv** *(Recommended)* | Ultra-fast dependency resolution, automatic virtual environments, simple configuration, excellent performance | All new projects, teams wanting the fastest modern tooling |
| **Poetry** | Modern dependency resolution, automatic virtual environments, build system integration | Teams preferring established tooling, complex publishing workflows |
| **Pipenv** | Simple pip-compatible workflow, automatic .env loading | Teams transitioning from pip, Docker-first workflows |
| **pip-tools** | Minimal overhead, integrates with existing pip workflows | Legacy projects, minimal dependencies, simple requirements |
| **conda** | Non-Python dependencies, scientific computing packages | Data science, packages requiring compiled extensions |

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
- [package-structure](./package-structure.md) - Well-organized packages support cleaner dependency management
- [testing-patterns](./testing-patterns.md) - Isolated dependencies enable more reliable and reproducible testing
