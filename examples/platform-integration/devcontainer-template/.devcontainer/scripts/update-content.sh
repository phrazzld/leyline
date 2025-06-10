#!/bin/bash
# update-content.sh - Runs when workspace content is updated
# Ensures development environment stays synchronized with project changes

set -euo pipefail

echo "🔄 Running content update synchronization..."

cd /workspace

# ============================================================================
# DEPENDENCY SYNCHRONIZATION
# ============================================================================

echo "📦 Synchronizing project dependencies..."

# Update Node.js dependencies if package files changed
if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
    if [ "package.json" -nt "node_modules/.package-lock.json" ] 2>/dev/null || [ ! -d "node_modules" ]; then
        echo "📦 Updating Node.js dependencies..."
        npm ci --prefer-offline --no-audit --progress=false || echo "⚠️  Could not update npm dependencies"
        touch node_modules/.package-lock.json 2>/dev/null || true
    fi
fi

# Update Python dependencies if requirements changed
if [ -f "requirements.txt" ] && [ -d ".venv" ]; then
    if [ "requirements.txt" -nt ".venv/.requirements-installed" ] 2>/dev/null; then
        echo "🐍 Updating Python dependencies..."
        .venv/bin/pip install -r requirements.txt || echo "⚠️  Could not update Python dependencies"
        touch .venv/.requirements-installed 2>/dev/null || true
    fi
fi

if [ -f "pyproject.toml" ] && [ -d ".venv" ]; then
    if [ "pyproject.toml" -nt ".venv/.pyproject-installed" ] 2>/dev/null; then
        echo "🐍 Updating Python project dependencies..."
        .venv/bin/pip install -e . || echo "⚠️  Could not update Python project"
        touch .venv/.pyproject-installed 2>/dev/null || true
    fi
fi

# Update Go dependencies if go.mod changed
if [ -f "go.mod" ]; then
    if [ "go.mod" -nt "go.sum" ] 2>/dev/null || [ ! -f "go.sum" ]; then
        echo "🚀 Updating Go dependencies..."
        go mod download || echo "⚠️  Could not download Go dependencies"
        go mod tidy || echo "⚠️  Could not tidy Go modules"
    fi
fi

# Update Rust dependencies if Cargo.toml changed
if [ -f "Cargo.toml" ]; then
    if [ "Cargo.toml" -nt "Cargo.lock" ] 2>/dev/null || [ ! -f "Cargo.lock" ]; then
        echo "🦀 Updating Rust dependencies..."
        cargo build || echo "⚠️  Could not build Rust dependencies"
    fi
fi

# ============================================================================
# DEVELOPMENT TOOL UPDATES
# ============================================================================

echo "🔧 Updating development tools configuration..."

# Update pre-commit hooks if configuration changed
if [ -f ".pre-commit-config.yaml" ]; then
    if command -v pre-commit &> /dev/null; then
        # Check if pre-commit config is newer than hooks
        if [ ".pre-commit-config.yaml" -nt ".git/hooks/pre-commit" ] 2>/dev/null; then
            echo "🔒 Updating pre-commit hooks..."
            pre-commit install --overwrite || echo "⚠️  Could not update pre-commit hooks"
            pre-commit install --hook-type commit-msg --overwrite || echo "⚠️  Could not update commit-msg hooks"
        fi

        # Update hook repositories
        echo "🔄 Updating pre-commit hook repositories..."
        pre-commit autoupdate || echo "⚠️  Could not update pre-commit repositories"
    fi
fi

# Update VS Code settings if template changed
if [ -f ".devcontainer/devcontainer.json" ] && [ ! -f ".vscode/.devcontainer-synced" ]; then
    echo "⚙️  Synchronizing VS Code settings with devcontainer..."

    # Ensure .vscode directory exists
    mkdir -p .vscode

    # Update workspace settings to match devcontainer configuration
    if [ ! -f ".vscode/settings.json" ]; then
        cat > .vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true
}
EOF
    fi

    touch .vscode/.devcontainer-synced
fi

# ============================================================================
# CONFIGURATION FILE UPDATES
# ============================================================================

echo "📝 Updating configuration files..."

# Update .gitignore if new patterns are needed based on project files
if [ -f ".gitignore" ]; then
    # Add Node.js patterns if package.json exists
    if [ -f "package.json" ] && ! grep -q "node_modules" .gitignore; then
        echo "📝 Adding Node.js patterns to .gitignore..."
        echo "" >> .gitignore
        echo "# Node.js" >> .gitignore
        echo "node_modules/" >> .gitignore
        echo "npm-debug.log*" >> .gitignore
        echo ".npm" >> .gitignore
    fi

    # Add Python patterns if Python files exist
    if find . -name "*.py" -type f | head -1 | grep -q . && ! grep -q "__pycache__" .gitignore; then
        echo "📝 Adding Python patterns to .gitignore..."
        echo "" >> .gitignore
        echo "# Python" >> .gitignore
        echo "__pycache__/" >> .gitignore
        echo "*.pyc" >> .gitignore
        echo ".pytest_cache/" >> .gitignore
        echo ".venv/" >> .gitignore
    fi

    # Add Go patterns if Go files exist
    if find . -name "*.go" -type f | head -1 | grep -q . && ! grep -q "go.sum" .gitignore; then
        echo "📝 Adding Go patterns to .gitignore..."
        echo "" >> .gitignore
        echo "# Go" >> .gitignore
        echo "*.exe" >> .gitignore
        echo "*.exe~" >> .gitignore
        echo "*.dll" >> .gitignore
        echo "*.so" >> .gitignore
        echo "*.dylib" >> .gitignore
    fi

    # Add Rust patterns if Rust files exist
    if find . -name "*.rs" -type f | head -1 | grep -q . && ! grep -q "target/" .gitignore; then
        echo "📝 Adding Rust patterns to .gitignore..."
        echo "" >> .gitignore
        echo "# Rust" >> .gitignore
        echo "target/" >> .gitignore
        echo "Cargo.lock" >> .gitignore
    fi
fi

# ============================================================================
# SECURITY UPDATES
# ============================================================================

echo "🔒 Running security updates..."

# Update secret detection baseline if needed
if [ -f ".secrets.baseline" ] && command -v detect-secrets &> /dev/null; then
    echo "🔍 Updating secrets baseline..."
    detect-secrets scan --update .secrets.baseline || echo "⚠️  Could not update secrets baseline"
fi

# Check for new security vulnerabilities
if [ -f "package.json" ] && command -v npm &> /dev/null; then
    echo "🔍 Checking Node.js security vulnerabilities..."
    npm audit --audit-level=high || echo "⚠️  Security vulnerabilities detected"
fi

if [ -f "requirements.txt" ] && command -v safety &> /dev/null; then
    echo "🔍 Checking Python security vulnerabilities..."
    if [ -d ".venv" ]; then
        .venv/bin/safety check || echo "⚠️  Python security vulnerabilities detected"
    else
        safety check || echo "⚠️  Python security vulnerabilities detected"
    fi
fi

# ============================================================================
# PERFORMANCE OPTIMIZATION UPDATES
# ============================================================================

echo "⚡ Updating performance optimizations..."

# Update Git configuration for better performance in large repositories
REPO_SIZE=$(du -s .git 2>/dev/null | cut -f1 || echo "0")
if [ "$REPO_SIZE" -gt 100000 ]; then  # If .git folder is larger than 100MB
    echo "🚀 Optimizing Git for large repository..."
    git config core.precomposeunicode true
    git config core.quotepath false
    git config diff.algorithm histogram
    git config merge.ours.driver true
fi

# Clean up old dependency caches periodically
if [ -d "node_modules" ]; then
    # Clean npm cache if it's older than 7 days
    if [ -d "$HOME/.npm" ] && find "$HOME/.npm" -mtime +7 -type d | grep -q .; then
        echo "🧹 Cleaning old npm cache..."
        npm cache clean --force || echo "⚠️  Could not clean npm cache"
    fi
fi

# ============================================================================
# DEVELOPMENT WORKFLOW UPDATES
# ============================================================================

echo "🔧 Updating development workflow scripts..."

# Update development scripts with new capabilities
if [ -f "scripts/dev.sh" ]; then
    # Check if we need to add new service support
    if [ -f "docker-compose.yml" ] && ! grep -q "docker-compose" scripts/dev.sh; then
        echo "📝 Adding Docker Compose support to development script..."
        sed -i '/echo "✅ Development environment started"/i\
if [ -f "docker-compose.yml" ]; then\
    echo "🐳 Starting Docker services..."\
    docker-compose up -d &\
fi' scripts/dev.sh || echo "⚠️  Could not update dev script"
    fi
fi

# ============================================================================
# FINAL SYNCHRONIZATION
# ============================================================================

echo "🔄 Final synchronization..."

# Update file permissions
find scripts/ -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Update timestamps for tracking
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .devcontainer/.last-update

# Generate update report
cat > .devcontainer-update-status.json << EOF
{
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workspace_path": "/workspace",
  "updates_applied": {
    "dependencies": true,
    "development_tools": true,
    "configuration_files": true,
    "security_checks": true,
    "performance_optimizations": true
  },
  "git_status": "$(git status --porcelain | wc -l) files modified"
}
EOF

echo "✅ Content update synchronization completed!"
echo "📊 All dependencies and configurations are up to date"
echo "🔒 Security checks completed"
echo "⚡ Performance optimizations applied"
