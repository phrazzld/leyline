# Platform Translation Guides

This document provides comprehensive translation guides between different platforms used in the platform integration bindings, enabling teams to migrate or maintain equivalent functionality across multiple platforms.

## Overview

The platform integration bindings include examples for multiple platforms and tools. These translation guides help teams:

- **Migrate** from one platform to another while maintaining functionality
- **Maintain** equivalent configurations across multiple platforms
- **Evaluate** platform choices based on feature parity
- **Integrate** multi-platform environments effectively

## CI/CD Platform Translations

### GitHub Actions ↔ GitLab CI

#### Core Syntax Translation

| Concept | GitHub Actions | GitLab CI |
|---------|----------------|-----------|
| **Workflow/Pipeline File** | `.github/workflows/name.yml` | `.gitlab-ci.yml` |
| **Trigger Events** | `on: [push, pull_request]` | `rules: - if: $CI_PIPELINE_SOURCE == "push"` |
| **Jobs** | `jobs: job-name:` | `job-name:` |
| **Runner/Image** | `runs-on: ubuntu-latest` | `image: ubuntu:latest` |
| **Environment Variables** | `env: VAR: value` | `variables: VAR: value` |
| **Dependencies** | `needs: [job1, job2]` | `needs: [job1, job2]` |
| **Artifacts** | `actions/upload-artifact@v3` | `artifacts: paths: - file.txt` |
| **Caching** | `actions/cache@v3` | `cache: paths: - node_modules/` |

#### Complete Translation Example

**GitHub Actions Foundation Pipeline:**
```yaml
# .github/workflows/foundation.yml
name: 🚀 Foundation Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'
  COVERAGE_THRESHOLD: 70

jobs:
  validate:
    name: ✅ Essential Validation
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm run test -- --coverage --watchAll=false

      - name: Check coverage
        run: |
          COVERAGE=$(npm run test:coverage:report --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
          if [ ${COVERAGE%.*} -lt ${{ env.COVERAGE_THRESHOLD }} ]; then
            echo "Coverage ${COVERAGE}% below threshold ${{ env.COVERAGE_THRESHOLD }}%"
            exit 1
          fi

      - name: Security audit
        run: npm audit --audit-level=high
```

**Equivalent GitLab CI Pipeline:**
```yaml
# .gitlab-ci.yml
stages:
  - validate

variables:
  NODE_VERSION: "20"
  COVERAGE_THRESHOLD: "70"

validate:
  stage: validate
  image: node:${NODE_VERSION}
  cache:
    paths:
      - node_modules/
  before_script:
    - npm ci
  script:
    # Run tests with coverage
    - npm run test -- --coverage --watchAll=false

    # Check coverage threshold
    - |
      COVERAGE=$(npm run test:coverage:report --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
      if [ ${COVERAGE%.*} -lt $COVERAGE_THRESHOLD ]; then
        echo "Coverage ${COVERAGE}% below threshold ${COVERAGE_THRESHOLD}%"
        exit 1
      fi

    # Security audit
    - npm audit --audit-level=high

  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    expire_in: 1 week

  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

#### Platform-Specific Features

**GitHub Actions Advantages:**
- Rich marketplace ecosystem
- Native integration with GitHub features
- Advanced matrix builds
- Sophisticated environment protection

**GitLab CI Advantages:**
- Built-in container registry
- Integrated security scanning
- Advanced caching mechanisms
- Native compliance features

#### Translation Strategy

1. **Start with Core Functionality**: Translate basic jobs, triggers, and scripts first
2. **Add Platform-Specific Features**: Leverage unique capabilities of target platform
3. **Validate Equivalency**: Ensure translated pipeline provides same validation coverage
4. **Optimize for Platform**: Use platform-specific optimizations and best practices

### GitHub Actions ↔ Jenkins

#### Basic Translation Patterns

| GitHub Actions | Jenkins (Declarative Pipeline) |
|----------------|--------------------------------|
| `jobs:` | `pipeline { stages { stage() } }` |
| `runs-on: ubuntu-latest` | `agent { docker { image 'ubuntu:latest' } }` |
| `env:` | `environment { VAR = 'value' }` |
| `steps:` | `steps { sh 'command' }` |
| `uses: actions/checkout@v4` | `checkout scm` |

**GitHub Actions to Jenkins Translation:**
```groovy
// Jenkinsfile - Equivalent to GitHub Actions example above
pipeline {
    agent {
        docker {
            image 'node:20'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        NODE_VERSION = '20'
        COVERAGE_THRESHOLD = '70'
    }

    triggers {
        pollSCM('H/15 * * * *')  // Poll every 15 minutes
    }

    stages {
        stage('Validate') {
            steps {
                checkout scm

                sh 'npm ci'

                sh 'npm run test -- --coverage --watchAll=false'

                script {
                    def coverage = sh(
                        script: "npm run test:coverage:report --silent | grep 'All files' | awk '{print \$10}' | sed 's/%//'",
                        returnStdout: true
                    ).trim()

                    if (coverage.toInteger() < env.COVERAGE_THRESHOLD.toInteger()) {
                        error("Coverage ${coverage}% below threshold ${env.COVERAGE_THRESHOLD}%")
                    }
                }

                sh 'npm audit --audit-level=high'
            }

            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
    }

    post {
        failure {
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

## Git Hook Framework Translations

### pre-commit ↔ Husky

#### Configuration Translation

**pre-commit Configuration:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.2
    hooks:
      - id: trufflehog
        name: 🔒 Secret Detection
        entry: trufflehog git file://. --since-commit HEAD --only-verified --fail

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-json
      - id: check-yaml

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.56.0
    hooks:
      - id: eslint
        args: [--fix]
```

**Equivalent Husky Configuration:**
```json
// package.json
{
  "devDependencies": {
    "husky": "^8.0.3",
    "@commitlint/cli": "^18.4.0",
    "@commitlint/config-conventional": "^18.4.0"
  },
  "scripts": {
    "prepare": "husky install",
    "lint": "eslint . --fix",
    "format": "prettier --write .",
    "test:pre-commit": "npm run lint && npm run format && npm run test"
  }
}
```

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Secret detection
trufflehog git file://. --since-commit HEAD --only-verified --fail

# File hygiene
npx prettier --check .
if [ $? -ne 0 ]; then
  echo "Code formatting issues found. Run 'npm run format' to fix."
  exit 1
fi

# Remove trailing whitespace (manual implementation)
find . -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.md" | xargs sed -i 's/[[:space:]]*$//'

# Linting
npm run lint
```

```bash
# .husky/commit-msg
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no-install commitlint --edit "$1"
```

#### Translation Considerations

**pre-commit Advantages:**
- Language agnostic
- Rich ecosystem of hooks
- Automatic tool installation
- Better isolation between hooks

**Husky Advantages:**
- Native npm integration
- Simpler setup for Node.js projects
- Better performance for simple checks
- Direct script integration

#### Migration Strategy

**pre-commit to Husky:**
1. Install Husky and related dependencies
2. Create equivalent npm scripts for validation tasks
3. Translate hook entries to shell commands in `.husky/` files
4. Test hook execution and fix any path/environment issues

**Husky to pre-commit:**
1. Install pre-commit framework
2. Create `.pre-commit-config.yaml` with equivalent repos and hooks
3. Replace custom scripts with standard pre-commit hooks where possible
4. Add `pre-commit install` to setup documentation

## Container Platform Translations

### Docker ↔ devcontainer

#### Basic Development Environment Translation

**Docker Compose Development Environment:**
```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/workspace
      - node_modules:/workspace/node_modules
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
    environment:
      - NODE_ENV=development
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  node_modules:
  postgres_data:
```

**Equivalent devcontainer Configuration:**
```json
// .devcontainer/devcontainer.json
{
  "name": "Full-Stack Development Environment",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ms-vscode.vscode-docker"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": true
        },
        "typescript.preferences.importModuleSpecifier": "relative"
      }
    }
  },

  "forwardPorts": [3000, 5432, 6379],
  "portsAttributes": {
    "3000": {
      "label": "Application",
      "onAutoForward": "notify"
    },
    "5432": {
      "label": "PostgreSQL",
      "onAutoForward": "silent"
    }
  },

  "postCreateCommand": "npm ci && npm run db:migrate",
  "postStartCommand": "npm run dev",

  "mounts": [
    "source=${localWorkspaceFolder}/.git,target=/workspace/.git,type=bind,consistency=cached"
  ]
}
```

```yaml
# .devcontainer/docker-compose.yml
version: '3.8'
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspace:cached
    command: sleep infinity
    environment:
      - NODE_ENV=development
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  postgres-data:
```

#### Platform-Specific Optimizations

**Docker Compose Advantages:**
- Simpler service orchestration
- Better for non-VS Code environments
- More flexible networking configuration
- Easier local service management

**devcontainer Advantages:**
- Integrated VS Code development experience
- Automatic extension installation
- Standardized development environment
- Better cross-platform consistency

## Version Control Platform Translations

### GitHub ↔ GitLab Branch Protection

#### Branch Protection Translation

**GitHub Branch Protection Rules:**
```yaml
# .github/branch-protection.yml (using GitHub CLI or API)
name: main
protection:
  enforce_admins: true
  required_status_checks:
    strict: true
    contexts:
      - "ci/build"
      - "ci/test"
      - "ci/security-scan"

  required_pull_request_reviews:
    required_approving_review_count: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true

  restrictions:
    users: []
    teams: ["core-team"]
    apps: ["dependabot"]
```

**Equivalent GitLab Push Rules:**
```yaml
# .gitlab-ci.yml or GitLab API configuration
push_rules:
  deny_delete_tag: true
  member_check: true
  prevent_secrets: true
  commit_message_regex: '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

# Project settings (via API or UI)
merge_requests:
  merge_method: merge
  squash_option: default_on
  remove_source_branch_after_merge: true
  only_allow_merge_if_pipeline_succeeds: true
  only_allow_merge_if_all_discussions_are_resolved: true

approvals:
  approvals_required: 2
  reset_approvals_on_push: true
  disable_overriding_approvers_per_merge_request: false
```

#### Code Ownership Translation

**GitHub CODEOWNERS:**
```gitignore
# .github/CODEOWNERS
* @team/maintainers

/src/components/ @team/frontend-team
/src/api/ @team/backend-team
/docs/ @team/technical-writers

/.github/workflows/ @team/devops
/src/auth/ @team/backend-team @team/security
```

**GitLab Equivalent (Push Rules + Approval Rules):**
```yaml
# .gitlab/CODEOWNERS (GitLab Premium feature)
* @maintainers

[Frontend]
/src/components/ @frontend-team

[Backend]
/src/api/ @backend-team

[Documentation]
/docs/ @technical-writers

[DevOps]
/.gitlab-ci.yml @devops
/docker/ @devops

[Security]
/src/auth/ @backend-team @security-team
```

## Security Tool Translations

### Secret Detection Tool Equivalency

| Tool | Strengths | Configuration | Best Use Case |
|------|-----------|---------------|---------------|
| **TruffleHog** | High accuracy, verified secrets | `--only-verified --fail` | Production pipelines |
| **detect-secrets** | Pattern analysis, baseline management | `--baseline .secrets.baseline` | Development hooks |
| **GitLeaks** | Fast scanning, custom rules | `.gitleaks.toml` config | Large repositories |
| **git-secrets** | AWS-focused, simple setup | `git secrets --scan` | AWS environments |

#### Multi-Tool Security Configuration

```yaml
# Comprehensive secret detection (all tools)
# .pre-commit-config.yaml
repos:
  # Primary: TruffleHog for verified secrets
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.2
    hooks:
      - id: trufflehog
        name: 🔒 TruffleHog (Verified Secrets)
        entry: trufflehog git file://. --since-commit HEAD --only-verified --fail

  # Secondary: detect-secrets for pattern analysis
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        name: 🔒 Pattern Analysis
        args: ['--baseline', '.secrets.baseline']

  # Tertiary: GitLeaks for comprehensive scanning
  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        name: 🔒 GitLeaks
```

## Translation Automation

### Automated Platform Translation

```python
#!/usr/bin/env python3
# tools/translate_platform.py
"""
Automated platform translation tool for common configurations
"""

import yaml
import json
import argparse
from pathlib import Path

class PlatformTranslator:
    def __init__(self):
        self.github_to_gitlab_mapping = {
            'on': 'rules',
            'runs-on': 'image',
            'steps': 'script',
            'uses': 'include',
            'env': 'variables'
        }

    def translate_github_to_gitlab(self, github_workflow):
        """Translate GitHub Actions workflow to GitLab CI"""
        gitlab_config = {}

        # Basic structure translation
        if 'jobs' in github_workflow:
            gitlab_config['stages'] = list(github_workflow['jobs'].keys())

            for job_name, job_config in github_workflow['jobs'].items():
                gitlab_job = {}

                # Translate runner to image
                if 'runs-on' in job_config:
                    if job_config['runs-on'] == 'ubuntu-latest':
                        gitlab_job['image'] = 'ubuntu:latest'

                # Translate steps to script
                if 'steps' in job_config:
                    script = []
                    for step in job_config['steps']:
                        if 'run' in step:
                            script.append(step['run'])
                        elif 'uses' in step:
                            # Convert common actions
                            if 'actions/checkout' in step['uses']:
                                script.append('git clone $CI_REPOSITORY_URL .')
                            elif 'actions/setup-node' in step['uses']:
                                script.append('apt-get update && apt-get install -y nodejs npm')

                    gitlab_job['script'] = script

                gitlab_config[job_name] = gitlab_job

        return gitlab_config

    def translate_precommit_to_husky(self, precommit_config):
        """Translate pre-commit config to Husky setup"""
        package_json_updates = {
            "devDependencies": {"husky": "^8.0.3"},
            "scripts": {"prepare": "husky install"}
        }

        husky_hooks = {}

        for repo in precommit_config.get('repos', []):
            for hook in repo.get('hooks', []):
                hook_id = hook['id']

                # Map common hooks
                if hook_id == 'trailing-whitespace':
                    husky_hooks['pre-commit'] = husky_hooks.get('pre-commit', [])
                    husky_hooks['pre-commit'].append("find . -name '*.js' -o -name '*.ts' | xargs sed -i 's/[[:space:]]*$//'")

                elif hook_id == 'eslint':
                    husky_hooks['pre-commit'] = husky_hooks.get('pre-commit', [])
                    husky_hooks['pre-commit'].append("npx eslint . --fix")

                elif 'commitlint' in hook_id:
                    husky_hooks['commit-msg'] = ["npx --no-install commitlint --edit $1"]

        return package_json_updates, husky_hooks

def main():
    parser = argparse.ArgumentParser(description='Translate between platform configurations')
    parser.add_argument('--source', choices=['github', 'gitlab', 'precommit', 'husky'], required=True)
    parser.add_argument('--target', choices=['github', 'gitlab', 'precommit', 'husky'], required=True)
    parser.add_argument('--input', type=Path, required=True, help='Input configuration file')
    parser.add_argument('--output', type=Path, help='Output file (default: stdout)')

    args = parser.parse_args()

    translator = PlatformTranslator()

    # Load input configuration
    with open(args.input) as f:
        if args.input.suffix in ['.yml', '.yaml']:
            config = yaml.safe_load(f)
        else:
            config = json.load(f)

    # Perform translation
    if args.source == 'github' and args.target == 'gitlab':
        result = translator.translate_github_to_gitlab(config)
    elif args.source == 'precommit' and args.target == 'husky':
        package_updates, husky_hooks = translator.translate_precommit_to_husky(config)
        result = {'package_json_updates': package_updates, 'husky_hooks': husky_hooks}
    else:
        raise ValueError(f"Translation from {args.source} to {args.target} not implemented")

    # Output result
    output_text = yaml.dump(result, default_flow_style=False)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(output_text)
    else:
        print(output_text)

if __name__ == '__main__':
    main()
```

## Best Practices for Platform Translation

### 1. Maintain Functional Equivalency
- Ensure translated configurations provide the same validation coverage
- Test translated configurations in target platform environment
- Document any feature gaps or limitations

### 2. Leverage Platform Strengths
- Don't just translate literally - optimize for target platform
- Use platform-specific features that improve functionality
- Take advantage of native integrations and optimizations

### 3. Plan for Migration
- Create migration timeline with validation checkpoints
- Run platforms in parallel during transition period
- Maintain rollback capabilities until migration is complete

### 4. Document Differences
- Clearly document any functional differences between platforms
- Provide guidance on platform-specific troubleshooting
- Maintain platform comparison matrices for decision making

## Conclusion

These platform translation guides enable teams to move between different tools and platforms while maintaining equivalent functionality. By providing concrete examples and automated translation tools, teams can:

- **Migrate confidently** between platforms with minimal functionality loss
- **Maintain consistency** across multi-platform environments
- **Evaluate options** based on concrete feature comparisons
- **Implement efficiently** using battle-tested translation patterns

The guides serve as both reference documentation and practical implementation tools, ensuring that platform choices remain flexible while maintaining robust automation standards.
