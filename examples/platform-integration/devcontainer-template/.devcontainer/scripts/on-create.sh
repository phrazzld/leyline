#!/bin/bash
# on-create.sh - Runs once when the container is created
# Implements development-environment-consistency standards for initial setup

set -euo pipefail

echo "🔧 Running on-create setup..."

# ============================================================================
# WORKSPACE INITIALIZATION
# ============================================================================

# Ensure workspace permissions are correct
sudo chown -R vscode:vscode /workspace || echo "⚠️  Could not set workspace permissions"

# Create common development directories
mkdir -p /workspace/{src,tests,docs,scripts,config}
mkdir -p /workspace/.vscode
mkdir -p /workspace/.github/workflows

# ============================================================================
# DEVELOPMENT TOOL INITIALIZATION
# ============================================================================

# Initialize Git repository if not already present
if [ ! -d "/workspace/.git" ]; then
    echo "📦 Initializing Git repository..."
    cd /workspace
    git init
    git branch -m main
fi

# Create .gitignore if it doesn't exist
if [ ! -f "/workspace/.gitignore" ]; then
    echo "📄 Creating comprehensive .gitignore..."
    cat > /workspace/.gitignore << 'EOF'
# Dependencies
node_modules/
*.egg-info/
__pycache__/
*.pyc
*.pyo
target/
Cargo.lock
vendor/

# Build outputs
dist/
build/
*.min.js
*.min.css
.next/
out/

# Environment and configuration
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
*.log
logs/

# IDE and editor files
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# OS-specific files
.DS_Store
Thumbs.db

# Testing and coverage
coverage/
.nyc_output/
*.lcov
.pytest_cache/
htmlcov/

# Temporary files
tmp/
temp/
*.tmp
*.temp

# Security
.secrets.baseline
.trufflehog_report.json
EOF
fi

# ============================================================================
# PACKAGE MANAGER INITIALIZATION
# ============================================================================

# Initialize package.json if Node.js project structure is detected
if [ ! -f "/workspace/package.json" ] && [ -d "/workspace/src" ]; then
    echo "📦 Creating package.json template..."
    cat > /workspace/package.json << 'EOF'
{
  "name": "workspace-project",
  "version": "0.1.0",
  "description": "Development workspace project",
  "main": "src/index.js",
  "scripts": {
    "dev": "npm run start:dev",
    "start": "node src/index.js",
    "start:dev": "nodemon src/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/ --ext .js,.jsx,.ts,.tsx",
    "lint:fix": "eslint src/ --ext .js,.jsx,.ts,.tsx --fix",
    "format": "prettier --write \"src/**/*.{js,jsx,ts,tsx,json,md}\"",
    "format:check": "prettier --check \"src/**/*.{js,jsx,ts,tsx,json,md}\"",
    "build": "npm run build:prod",
    "build:prod": "NODE_ENV=production webpack --mode=production",
    "build:dev": "NODE_ENV=development webpack --mode=development"
  },
  "keywords": ["development", "workspace"],
  "author": "Developer",
  "license": "MIT",
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "nodemon": "^3.0.0"
  }
}
EOF
fi

# ============================================================================
# PYTHON PROJECT INITIALIZATION
# ============================================================================

# Create Python project structure if Python files are detected
if [ -f "/workspace/requirements.txt" ] || [ -f "/workspace/pyproject.toml" ]; then
    echo "🐍 Setting up Python development environment..."

    # Create virtual environment
    python3 -m venv /workspace/.venv || echo "⚠️  Could not create virtual environment"

    # Install pre-commit if requirements.txt exists
    if [ -f "/workspace/requirements.txt" ]; then
        /workspace/.venv/bin/pip install -r /workspace/requirements.txt || echo "⚠️  Could not install Python dependencies"
    fi
fi

# ============================================================================
# GO PROJECT INITIALIZATION
# ============================================================================

# Initialize Go module if Go files are detected
if find /workspace -name "*.go" -type f | head -1 | grep -q .; then
    echo "🚀 Setting up Go development environment..."
    cd /workspace
    if [ ! -f "go.mod" ]; then
        go mod init workspace-project || echo "⚠️  Could not initialize Go module"
    fi
    go mod tidy || echo "⚠️  Could not tidy Go modules"
fi

# ============================================================================
# RUST PROJECT INITIALIZATION
# ============================================================================

# Initialize Cargo project if Rust files are detected
if find /workspace -name "*.rs" -type f | head -1 | grep -q .; then
    echo "🦀 Setting up Rust development environment..."
    cd /workspace
    if [ ! -f "Cargo.toml" ]; then
        cargo init --name workspace-project . || echo "⚠️  Could not initialize Cargo project"
    fi
fi

# ============================================================================
# DEVELOPMENT QUALITY TOOLS SETUP
# ============================================================================

# Install pre-commit hooks if configuration exists
if [ -f "/workspace/.pre-commit-config.yaml" ]; then
    echo "🔒 Setting up pre-commit hooks..."
    cd /workspace
    pre-commit install || echo "⚠️  Could not install pre-commit hooks"
    pre-commit install --hook-type commit-msg || echo "⚠️  Could not install commit-msg hooks"
fi

# ============================================================================
# VS CODE WORKSPACE CONFIGURATION
# ============================================================================

# Create VS Code workspace settings if not present
if [ ! -f "/workspace/.vscode/settings.json" ]; then
    echo "⚙️  Creating VS Code workspace settings..."
    mkdir -p /workspace/.vscode
    cat > /workspace/.vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "eslint.workingDirectories": ["src"],
  "typescript.preferences.quoteStyle": "single",
  "javascript.preferences.quoteStyle": "single",
  "python.defaultInterpreterPath": "./.venv/bin/python",
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "go.useLanguageServer": true,
  "go.formatTool": "goimports",
  "rust-analyzer.check.command": "clippy",
  "files.exclude": {
    "**/node_modules": true,
    "**/.git": true,
    "**/.DS_Store": true,
    "**/dist": true,
    "**/build": true,
    "**/__pycache__": true,
    "**/target": true
  }
}
EOF
fi

# Create launch.json for debugging if not present
if [ ! -f "/workspace/.vscode/launch.json" ]; then
    echo "🐛 Creating VS Code debug configuration..."
    cat > /workspace/.vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Node.js",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.js",
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    },
    {
      "name": "Launch Python",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/src/main.py",
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Launch Go",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}",
      "console": "integratedTerminal"
    }
  ]
}
EOF
fi

# ============================================================================
# FINAL PERMISSIONS AND CLEANUP
# ============================================================================

# Ensure all created files have correct ownership
sudo chown -R vscode:vscode /workspace/.vscode || echo "⚠️  Could not set .vscode permissions"
sudo chown -R vscode:vscode /workspace/.git || echo "⚠️  Could not set .git permissions"

echo "✅ on-create setup completed successfully!"
echo "📝 Workspace initialized with development tools and configurations"
echo "🔧 You can now start developing with a fully configured environment"
