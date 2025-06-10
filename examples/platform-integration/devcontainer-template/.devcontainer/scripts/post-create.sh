#!/bin/bash
# post-create.sh - Runs after the container and workspace are fully set up
# Implements final development environment consistency checks and optimizations

set -euo pipefail

echo "🚀 Running post-create optimizations..."

# ============================================================================
# DEPENDENCY INSTALLATION AND CACHING
# ============================================================================

cd /workspace

# Install Node.js dependencies if package.json exists
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    if command -v npm &> /dev/null; then
        npm install --prefer-offline --no-audit --progress=false || echo "⚠️  Could not install npm dependencies"
    fi
fi

# Install Python dependencies if requirements files exist
if [ -f "requirements.txt" ] && [ -d ".venv" ]; then
    echo "🐍 Installing Python dependencies..."
    .venv/bin/pip install -r requirements.txt || echo "⚠️  Could not install Python dependencies"
fi

if [ -f "pyproject.toml" ] && [ -d ".venv" ]; then
    echo "🐍 Installing Python project dependencies..."
    .venv/bin/pip install -e . || echo "⚠️  Could not install Python project"
fi

# Download Go dependencies if go.mod exists
if [ -f "go.mod" ]; then
    echo "🚀 Downloading Go dependencies..."
    go mod download || echo "⚠️  Could not download Go dependencies"
fi

# Build Rust dependencies if Cargo.toml exists
if [ -f "Cargo.toml" ]; then
    echo "🦀 Building Rust dependencies..."
    cargo build || echo "⚠️  Could not build Rust dependencies"
fi

# ============================================================================
# DEVELOPMENT TOOL VALIDATION
# ============================================================================

echo "🔍 Validating development environment..."

# Verify critical tools are available
TOOLS_CHECK=0

check_tool() {
    if command -v "$1" &> /dev/null; then
        echo "✅ $1 is available"
    else
        echo "❌ $1 is not available"
        TOOLS_CHECK=1
    fi
}

# Check essential development tools
check_tool "git"
check_tool "node"
check_tool "npm"
check_tool "python3"
check_tool "pip3"
check_tool "go"
check_tool "cargo"
check_tool "docker"
check_tool "kubectl"
check_tool "terraform"

# Verify pre-commit if configuration exists
if [ -f ".pre-commit-config.yaml" ]; then
    if command -v pre-commit &> /dev/null; then
        echo "✅ pre-commit is available"
        pre-commit --version
    else
        echo "❌ pre-commit is not available"
        TOOLS_CHECK=1
    fi
fi

# ============================================================================
# SECURITY VALIDATION
# ============================================================================

echo "🔒 Running security validation..."

# Check for secrets in the workspace
if command -v trufflehog &> /dev/null; then
    echo "🔍 Scanning for secrets with TruffleHog..."
    trufflehog git file://. --only-verified --fail || echo "⚠️  TruffleHog scan completed with warnings"
fi

# Validate file permissions
echo "🔍 Checking file permissions..."
find /workspace -type f -perm /o+w 2>/dev/null | grep -v "^/workspace/.git/" | head -5 | while read -r file; do
    echo "⚠️  World-writable file detected: $file"
done

# ============================================================================
# PERFORMANCE OPTIMIZATIONS
# ============================================================================

echo "⚡ Applying performance optimizations..."

# Configure Git for better performance
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256

# Set up shell completion for development tools
if [ -f "$HOME/.zshrc" ]; then
    # Add kubectl completion
    echo 'source <(kubectl completion zsh)' >> "$HOME/.zshrc" || echo "⚠️  Could not add kubectl completion"

    # Add terraform completion
    echo 'complete -C /usr/local/bin/terraform terraform' >> "$HOME/.zshrc" || echo "⚠️  Could not add terraform completion"
fi

# ============================================================================
# DEVELOPMENT WORKFLOW SETUP
# ============================================================================

echo "🔧 Setting up development workflow..."

# Create common development scripts if they don't exist
if [ ! -f "scripts/dev.sh" ]; then
    mkdir -p scripts
    cat > scripts/dev.sh << 'EOF'
#!/bin/bash
# Development startup script

set -euo pipefail

echo "🚀 Starting development environment..."

# Start development servers based on project type
if [ -f "package.json" ]; then
    echo "📦 Starting Node.js development server..."
    npm run dev &
fi

if [ -f "Cargo.toml" ]; then
    echo "🦀 Starting Rust development server..."
    cargo watch -x run &
fi

echo "✅ Development environment started"
echo "📝 Use 'scripts/stop.sh' to stop all services"
EOF
    chmod +x scripts/dev.sh
fi

# Create stop script
if [ ! -f "scripts/stop.sh" ]; then
    cat > scripts/stop.sh << 'EOF'
#!/bin/bash
# Stop development services

set -euo pipefail

echo "🛑 Stopping development services..."

# Kill development servers
pkill -f "npm run dev" || echo "No Node.js dev server running"
pkill -f "cargo watch" || echo "No Rust watch process running"

echo "✅ Development services stopped"
EOF
    chmod +x scripts/stop.sh
fi

# Create test script
if [ ! -f "scripts/test.sh" ]; then
    cat > scripts/test.sh << 'EOF'
#!/bin/bash
# Run all tests for the project

set -euo pipefail

echo "🧪 Running comprehensive test suite..."

# Run tests based on project type
if [ -f "package.json" ]; then
    echo "📦 Running Node.js tests..."
    npm test
fi

if [ -f "Cargo.toml" ]; then
    echo "🦀 Running Rust tests..."
    cargo test
fi

if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "🐍 Running Python tests..."
    if [ -d ".venv" ]; then
        .venv/bin/python -m pytest
    else
        python -m pytest
    fi
fi

echo "✅ Test suite completed"
EOF
    chmod +x scripts/test.sh
fi

# ============================================================================
# FINAL VALIDATION AND REPORTING
# ============================================================================

echo "📊 Final environment validation..."

# Generate environment report
cat > /workspace/.devcontainer-status.json << EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tools_check": $TOOLS_CHECK,
  "workspace_path": "/workspace",
  "user": "$(whoami)",
  "git_status": "$(git status --porcelain | wc -l) files modified",
  "node_version": "$(node --version 2>/dev/null || echo 'not available')",
  "python_version": "$(python3 --version 2>/dev/null || echo 'not available')",
  "go_version": "$(go version 2>/dev/null | cut -d' ' -f3 || echo 'not available')",
  "rust_version": "$(cargo --version 2>/dev/null | cut -d' ' -f2 || echo 'not available')"
}
EOF

# Display final status
echo ""
echo "🎉 Post-create setup completed!"
echo "📊 Environment Status:"
echo "   • Tools validation: $([ $TOOLS_CHECK -eq 0 ] && echo "✅ Passed" || echo "⚠️  Some issues detected")"
echo "   • Workspace: /workspace"
echo "   • User: $(whoami)"
echo "   • Node.js: $(node --version 2>/dev/null || echo 'not available')"
echo "   • Python: $(python3 --version 2>/dev/null || echo 'not available')"
echo "   • Go: $(go version 2>/dev/null | cut -d' ' -f3 || echo 'not available')"
echo "   • Rust: $(cargo --version 2>/dev/null | cut -d' ' -f2 || echo 'not available')"
echo ""
echo "🚀 Ready for development! Use 'scripts/dev.sh' to start."

# Set correct permissions for all scripts
chmod +x scripts/*.sh 2>/dev/null || true
sudo chown -R vscode:vscode /workspace || echo "⚠️  Could not set final permissions"
