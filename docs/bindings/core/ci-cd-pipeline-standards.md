---
id: ci-cd-pipeline-standards
last_modified: '2025-06-09'
version: '0.1.0'
derived_from: automation
enforced_by: 'CI/CD platforms, automated quality gates, deployment pipelines, monitoring systems'
---
# Binding: Establish Standardized CI/CD Pipeline Architecture

Implement consistent, automated CI/CD pipelines that enforce quality gates, security standards, and deployment practices across all platforms. Create systematic automation that ensures every code change progresses through comprehensive validation before reaching production environments.

## Rationale

This binding extends our automation tenet by establishing CI/CD pipelines as the backbone of development workflow automation. While git hooks provide immediate local feedback, CI/CD pipelines serve as the authoritative quality enforcement layer that validates all changes in controlled, reproducible environments before they can impact users.

Think of CI/CD pipelines as a factory assembly line with rigorous quality control at every station. Each stage validates specific aspects of code quality, security, and functionality, with automated gates that prevent defective changes from advancing. Unlike manual testing and deployment processes that are prone to human error and inconsistent execution, automated pipelines apply the same rigorous standards to every change, regardless of time pressure or complexity.

The investment in comprehensive CI/CD automation pays exponential dividends through reduced manual effort, faster feedback cycles, and dramatically improved reliability. Teams with robust pipeline automation can deploy multiple times per day with confidence, while teams relying on manual processes struggle to deploy weekly without significant risk. This automation becomes the foundation that enables rapid iteration and continuous delivery of value to users.

## Rule Definition

Standardized CI/CD pipelines must implement these core stages and principles:

- **Standardized Pipeline Stages**: Every pipeline must include setup, validation, security scanning, testing, building, and deployment verification stages with consistent behavior across platforms.

- **Fail-Fast Principles**: Pipelines must fail immediately when critical issues are detected, providing rapid feedback and preventing waste of computational resources on fundamentally flawed changes.

- **Security-First Integration**: Security scanning, vulnerability assessment, and compliance validation must be mandatory pipeline stages that cannot be bypassed or disabled.

- **Comprehensive Quality Gates**: Integrate multiple validation layers including automated testing, code coverage analysis, performance benchmarking, and deployment verification.

- **Platform-Agnostic Patterns**: Use consistent approaches and tooling across different CI/CD platforms to minimize cognitive overhead and enable team mobility between projects.

- **Observability and Monitoring**: Include comprehensive logging, metrics collection, and alerting to enable rapid diagnosis of pipeline failures and performance issues.

**Required Pipeline Stages:**
- Environment setup and dependency installation
- Code quality validation (linting, formatting, complexity analysis)
- Security scanning (vulnerabilities, secrets, compliance)
- Automated testing (unit, integration, end-to-end)
- Performance and load testing for critical paths
- Build artifact creation and verification
- Deployment to staging/production environments
- Post-deployment verification and monitoring

**Quality Gate Enforcement:**
- All tests must pass with minimum coverage thresholds
- No critical or high-severity security vulnerabilities
- Performance benchmarks within acceptable ranges
- Successful deployment verification in staging environment

## Practical Implementation

1. **Establish Platform-Agnostic Standards**: Define consistent pipeline behavior that translates across GitHub Actions, GitLab CI, Jenkins, and other platforms. Focus on common patterns and tooling to minimize platform-specific complexity.

2. **Implement Layered Security Scanning**: Integrate multiple security tools at different pipeline stages - static analysis during build, dependency scanning before deployment, and runtime security monitoring after deployment.

3. **Create Reusable Pipeline Components**: Build modular, reusable pipeline steps that can be shared across projects to ensure consistency and reduce maintenance overhead. Use template repositories and shared action libraries.

4. **Configure Progressive Deployment**: Implement automated deployment strategies with built-in rollback capabilities, including blue-green deployments, canary releases, and feature flag integration.

5. **Enable Comprehensive Monitoring**: Integrate observability tools that provide end-to-end visibility into pipeline performance, deployment success rates, and application health metrics.

## Examples

```yaml
# ❌ BAD: Basic pipeline with minimal validation
# .github/workflows/basic.yml
name: Basic CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm test

  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to production"

# Problems:
# 1. No security scanning or vulnerability assessment
# 2. No code quality validation or coverage requirements
# 3. No build verification or artifact validation
# 4. Direct production deployment without staging verification
# 5. No rollback capability or deployment verification
# 6. Missing observability and monitoring integration
```

```yaml
# ✅ GOOD: Comprehensive CI/CD pipeline with security-first approach
# .github/workflows/ci-cd-complete.yml
name: Complete CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'
  COVERAGE_THRESHOLD: 85
  SECURITY_SCAN_LEVEL: 'high'

jobs:
  # Stage 1: Setup and Code Quality
  code-quality:
    runs-on: ubuntu-latest
    outputs:
      cache-key: ${{ steps.cache.outputs.cache-hit }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Cache dependencies
        id: cache
        uses: actions/cache@v3
        with:
          path: node_modules
          key: deps-${{ runner.os }}-${{ hashFiles('package-lock.json') }}

      - name: Lint code
        run: |
          npm run lint
          if [ $? -ne 0 ]; then
            echo "::error::Code quality validation failed"
            exit 1
          fi

      - name: Check formatting
        run: |
          npm run format:check
          if [ $? -ne 0 ]; then
            echo "::error::Code formatting validation failed"
            exit 1
          fi

      - name: Validate commit messages
        run: npx commitlint --from=origin/main --to=HEAD

  # Stage 2: Security Scanning (runs in parallel with code quality)
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run dependency audit
        run: |
          npm audit --audit-level=${{ env.SECURITY_SCAN_LEVEL }}
          if [ $? -ne 0 ]; then
            echo "::error::Security vulnerabilities detected in dependencies"
            exit 1
          fi

      - name: Scan for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
          head: HEAD
          extra_args: --debug --only-verified

      - name: Static security analysis
        uses: github/codeql-action/analyze@v2
        with:
          languages: javascript

      - name: Container security scan
        if: hashFiles('Dockerfile') != ''
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'

  # Stage 3: Automated Testing
  test:
    needs: [code-quality, security-scan]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: |
          npm run test:unit -- --coverage --watchAll=false
          if [ $? -ne 0 ]; then
            echo "::error::Unit tests failed"
            exit 1
          fi

      - name: Run integration tests
        run: |
          npm run test:integration
          if [ $? -ne 0 ]; then
            echo "::error::Integration tests failed"
            exit 1
          fi

      - name: Check coverage thresholds
        run: |
          COVERAGE=$(npm run test:coverage:report --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
          if [ ${COVERAGE%.*} -lt ${{ env.COVERAGE_THRESHOLD }} ]; then
            echo "::error::Test coverage ${COVERAGE}% below threshold ${{ env.COVERAGE_THRESHOLD }}%"
            exit 1
          fi
          echo "::notice::Test coverage: ${COVERAGE}%"

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  # Stage 4: Performance Testing
  performance:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Bundle size analysis
        run: |
          npm run analyze:bundle
          BUNDLE_SIZE=$(du -b dist/main.js | cut -f1)
          MAX_SIZE=1048576  # 1MB
          if [ $BUNDLE_SIZE -gt $MAX_SIZE ]; then
            echo "::error::Bundle size exceeds limit: ${BUNDLE_SIZE} bytes"
            exit 1
          fi

      - name: Load testing
        run: |
          npm run test:load
          if [ $? -ne 0 ]; then
            echo "::error::Performance benchmarks failed"
            exit 1
          fi

  # Stage 5: Build and Package
  build:
    needs: [test, performance]
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Build container image
        id: build
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: app:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Test container
        run: |
          docker run --rm -d -p 3000:3000 --name test-container app:latest
          sleep 10
          curl -f http://localhost:3000/health || exit 1
          docker stop test-container

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            dist/
            Dockerfile
          retention-days: 30

  # Stage 6: Staging Deployment
  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts

      - name: Deploy to staging
        run: |
          echo "Deploying to staging environment..."
          # Deployment logic here
          sleep 5

      - name: Verify staging deployment
        run: |
          curl -f https://staging.example.com/health
          if [ $? -ne 0 ]; then
            echo "::error::Staging deployment verification failed"
            exit 1
          fi

      - name: Run smoke tests
        run: |
          npm run test:smoke -- --env=staging
          if [ $? -ne 0 ]; then
            echo "::error::Staging smoke tests failed"
            exit 1
          fi

  # Stage 7: Production Deployment
  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts

      - name: Deploy to production
        run: |
          echo "Deploying to production environment..."
          # Blue-green deployment logic
          sleep 10

      - name: Verify production deployment
        run: |
          curl -f https://api.example.com/health
          if [ $? -ne 0 ]; then
            echo "::error::Production deployment verification failed"
            # Trigger rollback
            exit 1
          fi

      - name: Update monitoring dashboards
        run: |
          curl -X POST https://monitoring.example.com/deployments \
            -H "Content-Type: application/json" \
            -d '{"version": "${{ github.sha }}", "environment": "production"}'

      - name: Notify deployment success
        uses: 8398a7/action-slack@v3
        with:
          status: success
          channel: '#deployments'
          message: 'Production deployment successful: ${{ github.sha }}'
```

```yaml
# ✅ GOOD: GitLab CI equivalent with comprehensive validation
# .gitlab-ci.yml
stages:
  - validate
  - security
  - test
  - build
  - deploy-staging
  - deploy-production

variables:
  NODE_VERSION: "18"
  COVERAGE_THRESHOLD: "85"
  DOCKER_DRIVER: overlay2

# Security and quality validation (parallel)
code-quality:
  stage: validate
  image: node:${NODE_VERSION}
  before_script:
    - npm ci
  script:
    - npm run lint
    - npm run format:check
    - npx commitlint --from=origin/main --to=HEAD
  artifacts:
    reports:
      junit: reports/lint-results.xml
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "merge_request_event"

security-scan:
  stage: security
  image: node:${NODE_VERSION}
  before_script:
    - npm ci
  script:
    - npm audit --audit-level=high
    - docker run --rm -v "$PWD:/pwd" trufflesecurity/trufflehog:latest git file:///pwd --since-commit HEAD~1 --only-verified --fail
  artifacts:
    reports:
      sast: gl-sast-report.json
      dependency_scanning: gl-dependency-scanning-report.json
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "merge_request_event"

# Comprehensive testing
test:
  stage: test
  image: node:${NODE_VERSION}
  needs: ["code-quality", "security-scan"]
  before_script:
    - npm ci
  script:
    - npm run test:unit -- --coverage --watchAll=false
    - npm run test:integration
    - |
      COVERAGE=$(npm run test:coverage:report --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
      if [ ${COVERAGE%.*} -lt $COVERAGE_THRESHOLD ]; then
        echo "Coverage ${COVERAGE}% below threshold ${COVERAGE_THRESHOLD}%"
        exit 1
      fi
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      junit: reports/test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "merge_request_event"

# Build and package
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  needs: ["test"]
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker run --rm -d -p 3000:3000 --name test-container $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - sleep 10
    - curl -f http://localhost:3000/health || exit 1
    - docker stop test-container
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# Staging deployment with verification
deploy-staging:
  stage: deploy-staging
  image: alpine:latest
  needs: ["build"]
  environment:
    name: staging
    url: https://staging.example.com
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to staging..."
    - sleep 5
    - curl -f https://staging.example.com/health
    - echo "Staging deployment verified"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# Production deployment with monitoring
deploy-production:
  stage: deploy-production
  image: alpine:latest
  needs: ["deploy-staging"]
  environment:
    name: production
    url: https://api.example.com
  before_script:
    - apk add --no-cache curl
  script:
    - echo "Deploying to production..."
    - sleep 10
    - curl -f https://api.example.com/health
    - |
      curl -X POST https://monitoring.example.com/deployments \
        -H "Content-Type: application/json" \
        -d "{\"version\": \"$CI_COMMIT_SHA\", \"environment\": \"production\"}"
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Related Bindings

- [automated-quality-gates.md](../../docs/bindings/core/automated-quality-gates.md): CI/CD pipelines implement comprehensive automated quality gates across multiple validation layers. Both bindings work together to create systematic quality enforcement from local development through production deployment.

- [git-hooks-automation.md](../../docs/bindings/core/git-hooks-automation.md): Git hooks provide the first layer of quality validation while CI/CD pipelines serve as the authoritative enforcement layer. Together they create a complete automation strategy with immediate local feedback and comprehensive remote validation.

- [require-conventional-commits.md](../../docs/bindings/core/require-conventional-commits.md): CI/CD pipelines validate and leverage conventional commit messages for automated changelog generation and semantic versioning. Consistent commit standards enable reliable automation throughout the deployment pipeline.

- [use-structured-logging.md](../../docs/bindings/core/use-structured-logging.md): CI/CD pipelines must implement structured logging and observability to enable effective monitoring and debugging of automated processes. Both bindings support comprehensive system observability and operational excellence.
