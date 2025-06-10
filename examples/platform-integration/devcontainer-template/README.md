# Development Container Template

This template provides a comprehensive, production-ready development environment that implements Leyline's development-environment-consistency standards. The container includes multi-language support, security tools, and automated workflow management.

## Quick Start

1. **Copy template to your project:**
   ```bash
   cp -r devcontainer-template/.devcontainer ./
   ```

2. **Open in VS Code with Dev Containers extension:**
   ```bash
   code .
   # VS Code will detect the devcontainer and offer to reopen in container
   ```

3. **Or build and run manually:**
   ```bash
   cd .devcontainer
   docker build -t my-dev-env .
   docker run -it --privileged -v ${PWD}/..:/workspace my-dev-env
   ```

## What's Included

### 🚀 Language Support
- **Node.js 20.11.0** - JavaScript/TypeScript development with npm, yarn, pnpm
- **Python 3.11** - With pip, pipenv, poetry, and common development tools
- **Go 1.21** - Latest stable with standard toolchain and popular packages
- **Rust** - Latest stable with Cargo and essential crates
- **Shell scripting** - Zsh with Oh My Zsh for enhanced development experience

### 🔒 Security Tools
- **TruffleHog** - Git secret scanning and detection
- **detect-secrets** - Comprehensive secret pattern detection
- **Bandit** - Python security vulnerability scanner
- **Container security** - Non-root user, minimal permissions
- **File permission auditing** - Automatic detection of security issues

### 🐳 Container & Infrastructure
- **Docker-in-Docker** - Build and run containers within development environment
- **Kubernetes tools** - kubectl and Helm for container orchestration
- **Terraform** - Infrastructure as code development and testing
- **docker-compose** - Multi-service application development

### 🔧 Development Tools
- **Git** - Latest version with optimized configuration
- **GitHub CLI** - Repository management and CI/CD integration
- **Pre-commit hooks** - Automated quality gates and validation
- **VS Code integration** - Optimized settings and extensions
- **Performance monitoring** - htop, system utilities

### ⚡ Automated Workflows
- **Lifecycle scripts** - Automated setup, updates, and maintenance
- **Dependency management** - Automatic installation and synchronization
- **Quality validation** - Continuous security and performance checks
- **Development services** - Auto-start for databases and supporting services

## Container Lifecycle

The development container includes four lifecycle scripts that run automatically:

### 1. `on-create.sh` - Initial Setup
- Initializes workspace structure and Git repository
- Creates development scripts and configuration files
- Sets up language-specific project templates
- Configures VS Code workspace settings

### 2. `update-content.sh` - Content Synchronization
- Synchronizes dependencies when project files change
- Updates development tool configurations
- Applies security updates and vulnerability scans
- Optimizes performance for large repositories

### 3. `post-create.sh` - Final Environment Setup
- Installs and validates all project dependencies
- Runs comprehensive development environment checks
- Generates development workflow scripts
- Creates environment status reports

### 4. `post-start.sh` - Runtime Initialization
- Validates service health and availability
- Starts Docker services and development databases
- Performs security startup checks
- Provides development command suggestions

## Customization Guide

### Language Versions
Modify versions in the Dockerfile:
```dockerfile
ENV NODE_VERSION=20.11.0
ENV PYTHON_VERSION=3.11
ENV GO_VERSION=1.21.6
```

### Additional Tools
Add tools in the Dockerfile after the "ADDITIONAL DEVELOPMENT TOOLS" section:
```dockerfile
# Install your custom tools
RUN apt-get update && apt-get install -y \
    your-tool \
    another-tool \
    && apt-get clean
```

### VS Code Extensions
Edit the `devcontainer.json` extensions list:
```json
"extensions": [
  "your.extension-id",
  "another.extension-id"
]
```

### Environment Variables
Add project-specific variables in `devcontainer.json`:
```json
"containerEnv": {
  "YOUR_VAR": "value",
  "API_URL": "http://localhost:3001"
}
```

### Development Services
Add services via docker-compose.yml in your project root:
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"

  redis:
    image: redis:7
    ports:
      - "6379:6379"
```

## Security Features

### Secret Detection
- **TruffleHog** scans for secrets in Git history
- **detect-secrets** provides comprehensive pattern detection
- **Baseline management** for approved secrets and false positives
- **Pre-commit integration** prevents secret commits

### Container Security
- **Non-root user** (`vscode`) for all development activities
- **Minimal privileges** with sudo access only when needed
- **File permission monitoring** for sensitive configuration files
- **Network isolation** with controlled port forwarding

### Dependency Security
- **Vulnerability scanning** for Node.js, Python, and Rust dependencies
- **Automated updates** for security patches
- **License compliance** checking for legal requirements
- **Supply chain validation** through pinned versions

## Performance Optimizations

### Caching Strategy
- **Volume mounts** for language-specific dependency caches
- **Layer optimization** in Dockerfile for faster rebuilds
- **Git performance** tuning for large repositories
- **IDE responsiveness** through optimized VS Code settings

### Resource Management
- **Memory allocation** configured for development workloads
- **CPU limits** prevent resource exhaustion
- **Disk usage** monitoring and cleanup automation
- **Network optimization** for container-to-container communication

## Troubleshooting

### Common Issues

**Container build fails:**
```bash
# Clean Docker cache and rebuild
docker system prune -a
docker build --no-cache -t my-dev-env .
```

**Permission errors:**
```bash
# Fix workspace permissions
sudo chown -R vscode:vscode /workspace
```

**VS Code extensions not loading:**
```bash
# Reload VS Code and reinstall extensions
code --install-extension ms-vscode-remote.remote-containers
```

**Docker daemon not available:**
```bash
# Restart Docker service (host machine)
sudo systemctl restart docker
```

### Performance Issues

**Slow container startup:**
- Enable BuildKit: `export DOCKER_BUILDKIT=1`
- Use multi-stage builds for complex Dockerfiles
- Pre-pull base images: `docker pull ubuntu:22.04`

**IDE responsiveness:**
- Exclude large directories in VS Code settings
- Disable unused extensions
- Increase container memory allocation

**Network connectivity:**
- Check port forwarding configuration
- Verify firewall settings on host machine
- Use `--network=host` for debugging

## Integration with Leyline Bindings

This devcontainer template directly implements:

- **[development-environment-consistency.md](../../docs/bindings/core/development-environment-consistency.md)** - Container standardization
- **[git-hooks-automation.md](../../docs/bindings/core/git-hooks-automation.md)** - Pre-commit validation
- **[ci-cd-pipeline-standards.md](../../docs/bindings/core/ci-cd-pipeline-standards.md)** - Local CI/CD testing

## Contributing

When modifying this template:

1. Test all lifecycle scripts in isolation
2. Validate multi-language project support
3. Ensure security tools function correctly
4. Update documentation for new features
5. Maintain backward compatibility where possible

## License

This template is provided under the same license as the Leyline project.
