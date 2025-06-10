#!/bin/bash
# post-start.sh - Runs every time the container starts
# Ensures development environment is ready for immediate use

set -euo pipefail

echo "🚀 Running post-start initialization..."

cd /workspace

# ============================================================================
# SERVICE HEALTH CHECKS
# ============================================================================

echo "🔍 Checking development environment health..."

# Check essential services and tools
HEALTH_STATUS=0

check_service() {
    if command -v "$1" &> /dev/null; then
        echo "✅ $1 is available"
    else
        echo "❌ $1 is not available"
        HEALTH_STATUS=1
    fi
}

# Core development tools
check_service "git"
check_service "node"
check_service "python3"
check_service "docker"

# Language-specific tools (if project uses them)
if [ -f "go.mod" ]; then
    check_service "go"
fi

if [ -f "Cargo.toml" ]; then
    check_service "cargo"
fi

# ============================================================================
# DOCKER AND CONTAINER SERVICES
# ============================================================================

echo "🐳 Checking Docker services..."

# Ensure Docker daemon is running
if command -v docker &> /dev/null; then
    # Wait for Docker daemon to be ready
    DOCKER_READY=0
    for i in {1..30}; do
        if docker ps &> /dev/null; then
            echo "✅ Docker daemon is ready"
            DOCKER_READY=1
            break
        fi
        echo "⏳ Waiting for Docker daemon... ($i/30)"
        sleep 2
    done

    if [ $DOCKER_READY -eq 0 ]; then
        echo "⚠️  Docker daemon not ready after 60 seconds"
        HEALTH_STATUS=1
    fi

    # Start development services if docker-compose.yml exists
    if [ -f "docker-compose.yml" ] && [ $DOCKER_READY -eq 1 ]; then
        echo "🐳 Starting Docker Compose services..."
        docker-compose up -d --remove-orphans || echo "⚠️  Could not start Docker services"

        # Wait for services to be healthy
        echo "⏳ Waiting for services to be ready..."
        docker-compose ps
    fi
else
    echo "⚠️  Docker is not available"
fi

# ============================================================================
# DEVELOPMENT SERVER PREPARATION
# ============================================================================

echo "🔧 Preparing development servers..."

# Pre-warm development caches
if [ -f "package.json" ] && [ -d "node_modules" ]; then
    echo "📦 Warming Node.js module cache..."
    # Pre-compile TypeScript if applicable
    if [ -f "tsconfig.json" ] && command -v tsc &> /dev/null; then
        echo "📝 Pre-compiling TypeScript..."
        tsc --noEmit || echo "⚠️  TypeScript compilation issues detected"
    fi
fi

if [ -f "Cargo.toml" ]; then
    echo "🦀 Warming Rust build cache..."
    # Pre-compile dependencies
    cargo check --quiet || echo "⚠️  Rust compilation issues detected"
fi

# ============================================================================
# DEVELOPMENT ENVIRONMENT VALIDATION
# ============================================================================

echo "✅ Validating development environment..."

# Check workspace permissions
if [ ! -w "/workspace" ]; then
    echo "❌ Workspace is not writable"
    HEALTH_STATUS=1
else
    echo "✅ Workspace permissions are correct"
fi

# Validate Git configuration
if [ -d ".git" ]; then
    if git config user.name &> /dev/null && git config user.email &> /dev/null; then
        echo "✅ Git is configured"
    else
        echo "⚠️  Git user configuration missing"
        echo "   Run: git config --global user.name 'Your Name'"
        echo "   Run: git config --global user.email 'your.email@example.com'"
    fi
fi

# Check for development secrets/environment variables
if [ -f ".env" ]; then
    echo "📝 Environment configuration found"
elif [ -f ".env.example" ]; then
    echo "⚠️  .env.example found but no .env file"
    echo "   Copy .env.example to .env and configure your environment"
fi

# ============================================================================
# PROJECT-SPECIFIC INITIALIZATION
# ============================================================================

echo "🎯 Running project-specific initialization..."

# Initialize database if needed
if [ -f "docker-compose.yml" ] && grep -q "postgres\|mysql\|mongodb" docker-compose.yml; then
    echo "🗄️  Database services detected"

    # Wait for database to be ready
    if command -v docker-compose &> /dev/null; then
        # Check if we need to run migrations
        if [ -f "scripts/migrate.sh" ]; then
            echo "🗄️  Running database migrations..."
            bash scripts/migrate.sh || echo "⚠️  Migration script failed"
        elif [ -f "package.json" ] && grep -q "migrate" package.json; then
            echo "🗄️  Running npm migrations..."
            npm run migrate || echo "⚠️  npm migration failed"
        fi
    fi
fi

# Start development monitoring if available
if [ -f "package.json" ] && grep -q "dev:watch\|watch" package.json; then
    echo "👀 Development monitoring available"
    echo "   Run: npm run dev:watch (or similar) for live reloading"
fi

# ============================================================================
# SECURITY STARTUP CHECKS
# ============================================================================

echo "🔒 Running security startup checks..."

# Quick secret scan if TruffleHog is available
if command -v trufflehog &> /dev/null; then
    echo "🔍 Quick security scan..."
    trufflehog git file://. --since-commit HEAD~5 --only-verified --fail || echo "⚠️  Potential secrets detected"
fi

# Check file permissions for sensitive files
for file in .env .env.local .env.production .secrets; do
    if [ -f "$file" ]; then
        PERMS=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
        if [[ "$PERMS" == *"644"* ]] || [[ "$PERMS" == *"664"* ]] || [[ "$PERMS" == *"666"* ]]; then
            echo "⚠️  $file has overly permissive permissions: $PERMS"
            chmod 600 "$file" || echo "❌ Could not fix permissions for $file"
        fi
    fi
done

# ============================================================================
# DEVELOPMENT WORKFLOW READINESS
# ============================================================================

echo "🚀 Finalizing development environment..."

# Create development status file
cat > .devcontainer-runtime-status.json << EOF
{
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "health_status": $HEALTH_STATUS,
  "services": {
    "docker": $(docker ps &> /dev/null && echo "true" || echo "false"),
    "git": $([ -d ".git" ] && echo "true" || echo "false"),
    "node": $([ -f "package.json" ] && echo "true" || echo "false"),
    "python": $([ -f "requirements.txt" ] || [ -f "pyproject.toml" ] && echo "true" || echo "false"),
    "go": $([ -f "go.mod" ] && echo "true" || echo "false"),
    "rust": $([ -f "Cargo.toml" ] && echo "true" || echo "false")
  },
  "workspace_ready": true
}
EOF

# Update shell history with helpful commands
if [ -f "$HOME/.zsh_history" ]; then
    # Add useful development commands to history
    echo ": $(date +%s):0;npm run dev" >> "$HOME/.zsh_history" 2>/dev/null || true
    echo ": $(date +%s):0;npm test" >> "$HOME/.zsh_history" 2>/dev/null || true
    echo ": $(date +%s):0;git status" >> "$HOME/.zsh_history" 2>/dev/null || true
    echo ": $(date +%s):0;docker-compose logs -f" >> "$HOME/.zsh_history" 2>/dev/null || true
fi

# ============================================================================
# COMPLETION NOTIFICATION
# ============================================================================

echo ""
echo "🎉 Development environment is ready!"
echo ""
echo "📊 Environment Status:"
echo "   • Health Check: $([ $HEALTH_STATUS -eq 0 ] && echo "✅ Healthy" || echo "⚠️  Issues detected")"
echo "   • Docker: $(docker ps &> /dev/null && echo "✅ Running" || echo "❌ Not available")"
echo "   • Workspace: ✅ Ready"
echo "   • User: $(whoami)"
echo ""

# Show available development commands
echo "🚀 Quick Start Commands:"
if [ -f "package.json" ]; then
    echo "   • npm run dev          - Start development server"
    echo "   • npm test             - Run tests"
    echo "   • npm run build        - Build for production"
fi

if [ -f "scripts/dev.sh" ]; then
    echo "   • scripts/dev.sh       - Start all development services"
fi

if [ -f "docker-compose.yml" ]; then
    echo "   • docker-compose logs  - View service logs"
    echo "   • docker-compose ps    - Check service status"
fi

echo "   • git status           - Check repository status"
echo ""

# Show next steps based on project state
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "⚠️  Next Step: Copy .env.example to .env and configure your environment"
fi

if [ -d ".git" ] && ! git config user.name &> /dev/null; then
    echo "⚠️  Next Step: Configure Git with your name and email"
fi

echo "✨ Happy coding!"
