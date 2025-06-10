# Platform Integration Examples

This directory provides comprehensive, production-ready examples that demonstrate the platform integration standards defined in Leyline's core bindings. These examples implement security-first automation across the entire development workflow.

## Quick Start

Choose the example that matches your development environment and follow the setup instructions:

```bash
# For GitHub Actions projects
cp github-actions-complete.yml .github/workflows/ci-cd.yml

# For GitLab CI projects
cp gitlab-ci-complete.yml .gitlab-ci.yml

# For pre-commit hooks (any project)
cp pre-commit-comprehensive.yaml .pre-commit-config.yaml
pre-commit install

# For containerized development
cp -r devcontainer-template/.devcontainer ./
```

## Example Files

### CI/CD Pipelines
- **`github-actions-complete.yml`** - Comprehensive GitHub Actions workflow with security scanning, quality gates, and automated deployment
- **`gitlab-ci-complete.yml`** - Equivalent GitLab CI pipeline with the same validation stages and security measures

### Development Environment
- **`pre-commit-comprehensive.yaml`** - Multi-framework git hooks configuration supporting pre-commit, husky, and lefthook patterns
- **`devcontainer-template/`** - Complete containerized development environment with VS Code integration

### Migration Guides
- **`migration-guides/`** - Step-by-step guides for migrating from common anti-patterns to these comprehensive examples

## Core Principles Demonstrated

All examples implement these platform integration standards:

### 🔒 Security-First Approach
- Secret detection and vulnerability scanning at every stage
- Dependency auditing with automatic failure on high-severity issues
- Container security scanning and compliance validation
- No hardcoded secrets or credentials anywhere in the examples

### ⚡ Automated Quality Gates
- Code formatting, linting, and complexity analysis
- Comprehensive testing with coverage requirements
- Performance benchmarking and bundle size limits
- Documentation validation and API contract verification

### 🚀 Fail-Fast Principles
- Immediate feedback on quality issues
- Parallel execution where possible to minimize build times
- Clear, actionable error messages with remediation guidance
- Escalating validation rigor through the pipeline

### 🔄 Integration Consistency
- Local development environment matches CI/CD exactly
- Same tools and versions across all environments
- Consistent configuration patterns across different platforms
- Automated setup and maintenance procedures

## Version Pinning Strategy

All examples use specific, tested versions of tools and actions:

- **GitHub Actions**: Pinned to specific major versions (e.g., `@v4`)
- **Docker Images**: Specific versions with digest hashes where critical
- **Node.js/Language Versions**: Exact versions specified in multiple places
- **Pre-commit Hooks**: Specific revision hashes for reproducibility

## Customization Guidelines

### Adapting for Your Project

1. **Update Language Versions**: Modify version specifications in all relevant files
2. **Adjust Security Thresholds**: Configure audit levels and coverage requirements
3. **Add Project-Specific Steps**: Insert additional validation or build steps
4. **Configure Secrets**: Set up environment variables and secret management

### Technology Stack Variations

These examples support multiple technology stacks:

- **Frontend**: Node.js, TypeScript, React, Vue, Angular
- **Backend**: Go, Python, Rust, Node.js APIs
- **Full-Stack**: Multi-language monorepos with coordinated pipelines
- **Infrastructure**: Terraform, Kubernetes, Docker compositions

## Troubleshooting

### Common Issues

**Pre-commit hooks failing**: Ensure all language runtimes are installed locally
**CI pipeline timeouts**: Optimize parallel execution and caching strategies
**Container build failures**: Check base image compatibility and dependency versions
**Security scan false positives**: Configure allowlists for approved exceptions

### Performance Optimization

- Enable caching for dependencies and build artifacts
- Use matrix builds for testing across multiple environments
- Optimize Docker layer caching and multi-stage builds
- Configure parallel job execution within platform limits

## Integration with Leyline Bindings

These examples directly implement the following Leyline bindings:

- [git-hooks-automation.md](../../docs/bindings/core/git-hooks-automation.md) - Pre-commit validation
- [ci-cd-pipeline-standards.md](../../docs/bindings/core/ci-cd-pipeline-standards.md) - Pipeline automation
- [version-control-workflows.md](../../docs/bindings/core/version-control-workflows.md) - Branch protection
- [development-environment-consistency.md](../../docs/bindings/core/development-environment-consistency.md) - Environment setup

## Contributing

When adding new examples or updating existing ones:

1. Test all configurations in isolated environments
2. Include version pinning for all dependencies
3. Add migration guides for common anti-patterns
4. Update this README with new features or changes
5. Validate syntax with platform-specific tools

## License

These examples are provided under the same license as the Leyline project. See the main repository LICENSE file for details.
