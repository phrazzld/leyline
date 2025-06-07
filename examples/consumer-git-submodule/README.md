# Git Submodule Integration Example

This example demonstrates how to integrate Leyline into your project using Git submodules. This approach gives you direct access to all Leyline content and validation tools.

## When to Use Git Submodules

✅ **Good for:**
- Projects that want direct access to Leyline validation tools
- Teams that prefer explicit version control of dependencies
- Projects that need to customize or extend Leyline bindings
- Organizations that want to track exactly which Leyline version they're using

❌ **Consider alternatives if:**
- You only need a subset of Leyline tenets/bindings
- Your team isn't familiar with Git submodules
- You prefer automated content synchronization
- You want Leyline content to be automatically updated

## Quick Start

### 1. Add Leyline as a Submodule

```bash
# Add Leyline as a submodule in your project
git submodule add https://github.com/phrazzld/leyline.git leyline

# Pin to a specific version (recommended)
cd leyline
git checkout v0.1.5  # Replace with your desired version
cd ..

# Commit the submodule
git add .gitmodules leyline
git commit -m "feat: add Leyline as submodule for development standards"
```

### 2. Copy the Validation Workflow

Copy the provided GitHub Actions workflow to your repository:

```bash
mkdir -p .github/workflows
cp leyline/examples/consumer-git-submodule/.github/workflows/leyline-validation.yml .github/workflows/
```

### 3. Create Project Configuration

Create a configuration file to specify which Leyline standards apply to your project:

```bash
cp leyline/examples/consumer-git-submodule/leyline-config.yml .
```

Edit `leyline-config.yml` to match your project's needs.

## Project Structure

```
your-project/
├── .github/workflows/
│   └── leyline-validation.yml     # Validation workflow
├── leyline/                       # Git submodule
│   ├── docs/tenets/              # Leyline tenets
│   ├── docs/bindings/            # Leyline bindings
│   └── tools/                    # Validation tools
├── leyline-config.yml            # Your project's Leyline config
├── .gitmodules                   # Git submodules config
└── [your project files]
```

## Version Management

### Updating Leyline Version

```bash
# Navigate to the submodule
cd leyline

# Fetch latest changes
git fetch origin

# Update to a specific version
git checkout v0.2.0  # Replace with desired version

# Return to your project root
cd ..

# Commit the version update
git add leyline
git commit -m "chore: update Leyline to v0.2.0"
```

### Checking Current Version

```bash
# See which Leyline version you're using
cd leyline
git describe --tags --exact-match HEAD 2>/dev/null || git rev-parse --short HEAD
cd ..
```

## Validation Integration

The included GitHub Actions workflow validates your project against applicable Leyline standards:

1. **Automatic Validation**: Runs on every pull request
2. **Configurable Scope**: Only validates standards relevant to your project
3. **Clear Reporting**: Shows which standards pass/fail with actionable feedback
4. **Version Aware**: Uses the exact Leyline version in your submodule

## Configuration Options

Edit `leyline-config.yml` to customize which standards apply:

```yaml
# Which Leyline tenets your project follows
tenets:
  - simplicity
  - testability
  - explicit-over-implicit

# Which binding categories apply to your project
binding_categories:
  - core              # Universal bindings
  - typescript        # If you use TypeScript
  - go                # If you use Go
  - rust              # If you use Rust

# Specific bindings to exclude (optional)
excluded_bindings:
  - no-any            # If you haven't migrated away from 'any' yet

# Custom validation rules (optional)
custom_rules:
  enforce_conventional_commits: true
  require_changelog: true
```

## Best Practices

### 1. Pin to Specific Versions
Always pin your submodule to a specific Leyline release tag:
```bash
cd leyline && git checkout v0.1.5
```

### 2. Regular Updates
Update Leyline quarterly or when new relevant standards are released:
```bash
# Check for new releases
cd leyline
git fetch origin
git tag -l | sort -V | tail -5

# Update to latest stable
git checkout v0.2.0
cd ..
git add leyline
git commit -m "chore: update Leyline to v0.2.0"
```

### 3. Team Onboarding
Include submodule initialization in your project setup:
```bash
# When cloning the repository
git clone --recurse-submodules https://github.com/your-org/your-project.git

# Or if already cloned
git submodule update --init --recursive
```

### 4. Automated Checks
Consider adding a script to verify Leyline version:
```bash
#!/bin/bash
# scripts/check-leyline-version.sh
cd leyline
CURRENT_VERSION=$(git describe --tags --exact-match HEAD 2>/dev/null)
EXPECTED_VERSION="v0.1.5"

if [[ "$CURRENT_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Warning: Leyline submodule is at $CURRENT_VERSION, expected $EXPECTED_VERSION"
  exit 1
fi
```

## Migration Path

### From Manual Standards to Leyline Submodule

1. **Assessment**: Identify which existing practices align with Leyline tenets
2. **Configuration**: Create `leyline-config.yml` reflecting current state
3. **Gradual Adoption**: Enable additional standards incrementally
4. **Team Training**: Educate team on Leyline principles and tools

### From Automated Sync to Submodule

If migrating from the automated sync pattern:

1. **Remove Sync Workflow**: Delete the automated sync GitHub Actions workflow
2. **Add Submodule**: Follow the setup instructions above
3. **Update Documentation**: Update project docs to reference the submodule approach
4. **Team Communication**: Ensure team understands the new manual update process

## Troubleshooting

### Submodule Not Updating
```bash
# Force submodule update
git submodule update --remote --merge

# Reset submodule to tracked commit
git submodule update --init --recursive
```

### Validation Errors
```bash
# Run Leyline validation locally
cd leyline
ruby tools/validate_front_matter.rb
ruby tools/reindex.rb --strict

# Check your configuration
ruby tools/validate_project_config.rb ../leyline-config.yml
```

### Version Conflicts
```bash
# See submodule status
git submodule status

# Reset to committed version
git submodule update --init
```

## Example Projects

- **Small TypeScript Library**: Uses core + TypeScript bindings only
- **Go Microservice**: Uses core + Go bindings with custom rules
- **Full-Stack Application**: Uses all categories with selective exclusions

## Next Steps

1. **Review Configuration**: Ensure `leyline-config.yml` matches your project
2. **Run Validation**: Test the GitHub Actions workflow on a sample PR
3. **Team Training**: Share this documentation with your development team
4. **Iterate**: Gradually adopt additional standards as your project matures
