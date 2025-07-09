# .leyline File Format

The `.leyline` configuration file allows you to define default settings for your project, eliminating the need to specify options every time you run leyline commands.

## Overview

The `.leyline` file is a YAML configuration file placed in your project root directory. It defines:

- **Categories**: Which leyline categories to sync by default
- **Version**: Compatibility constraints for leyline versions
- **Target Path**: Where to store synced leyline documents

## File Location

The configuration file must be named `.leyline` and placed in your project root directory:

```
your-project/
├── .leyline          # Configuration file
├── package.json
├── README.md
└── docs/
    └── leyline/       # Default target directory
```

## Basic Format

```yaml
# .leyline configuration file
categories:
  - typescript
  - go
  - security
version: ">=2.0.0"
docs_path: "docs/leyline"
```

## Configuration Fields

### `categories` (Optional)

**Type:** Array of strings
**Default:** `[]` (empty array)
**Description:** List of categories to sync by default

```yaml
categories:
  - typescript
  - go
  - rust
  - security
```

**Available Categories:**
- `api` - API design and documentation standards
- `browser-extensions` - Browser extension development patterns
- `cli` - Command-line interface development
- `csharp` - C# language bindings
- `database` - Database design and operation patterns
- `git` - Git workflow and repository management
- `go` - Go language bindings
- `python` - Python language bindings
- `react` - React framework patterns
- `ruby` - Ruby language bindings
- `rust` - Rust language bindings
- `security` - Security-focused development practices
- `typescript` - TypeScript language bindings
- `web` - Web development standards

**Notes:**
- Categories are case-sensitive
- Duplicate categories are automatically removed
- The `core` category is always included and doesn't need to be specified
- The `tenets` category is always included and contains foundational principles
- Using `all` as a category name will result in an error

### `version` (Optional)

**Type:** String
**Default:** No version constraint
**Description:** Version constraint for leyline compatibility

```yaml
version: ">=2.0.0"
version: "~>2.1.0"
version: ">=2.0.0,<3.0.0"
```

**Supported Operators:**
- `>=` - Greater than or equal to
- `>` - Greater than
- `<=` - Less than or equal to
- `<` - Less than
- `~>` - Pessimistic version constraint (compatible within minor version)

**Examples:**
```yaml
version: ">=2.0.0"         # Version 2.0.0 or higher
version: "~>2.1.0"         # Version 2.1.x, but not 2.2.0
version: ">=2.0.0,<3.0.0"  # Version 2.x.x, but not 3.0.0
```

### `docs_path` (Optional)

**Type:** String
**Default:** `"docs/leyline"`
**Description:** Target directory for synced leyline documents

```yaml
docs_path: "docs/leyline"
docs_path: "standards/leyline"
docs_path: "docs/development-standards"
```

**Notes:**
- Path is relative to your project root
- Directory will be created if it doesn't exist
- Existing files may be overwritten during sync

## Complete Examples

### Minimal Configuration

```yaml
# Sync TypeScript standards only
categories:
  - typescript
```

### Standard Configuration

```yaml
# Multi-language project with version constraint
categories:
  - typescript
  - go
  - security
  - database
version: ">=2.0.0"
docs_path: "docs/leyline"
```

### Full Configuration

```yaml
# Enterprise project with comprehensive standards
categories:
  - typescript
  - go
  - rust
  - security
  - database
  - api
  - git
version: ">=2.1.0,<3.0.0"
docs_path: "standards/development-practices"
```

### Custom Path Configuration

```yaml
# Custom documentation location
categories:
  - python
  - security
docs_path: "docs/coding-standards"
```

## Usage

Once you have a `.leyline` file configured, you can use simplified commands:

```bash
# Sync using configuration file settings
leyline sync

# Override categories from command line
leyline sync -c typescript,go

# Check status using configuration
leyline status

# All other commands work with configuration
leyline diff
leyline update
```

## Configuration Precedence

When leyline commands are run, configuration is applied in this order (highest to lowest precedence):

1. **Command-line options** (highest precedence)
2. **`.leyline` file configuration**
3. **Default values** (lowest precedence)

### Examples

```yaml
# .leyline file
categories:
  - typescript
  - go
```

```bash
# Uses TypeScript and Go from .leyline file
leyline sync

# Override: uses only Rust (ignores .leyline categories)
leyline sync -c rust

# Uses TypeScript and Go from .leyline file
leyline status

# Override: checks only TypeScript status
leyline status -c typescript
```

## Validation and Error Handling

The `.leyline` file is validated when loaded. Common validation errors include:

### Syntax Errors

```yaml
# ❌ Invalid YAML syntax
categories
  - typescript
```

**Error:** `YAML syntax error: (<unknown>): did not find expected ':' while scanning a simple key`

**Fix:**
```yaml
# ✅ Correct YAML syntax
categories:
  - typescript
```

### Invalid Data Types

```yaml
# ❌ Categories must be an array
categories: typescript
```

**Error:** `categories must be an array`

**Fix:**
```yaml
# ✅ Categories as array
categories:
  - typescript
```

### Invalid Categories

```yaml
# ❌ Invalid category name
categories:
  - typescript
  - invalid-category
```

**Error:** `Invalid categories: ["invalid-category"]`

**Fix:**
```yaml
# ✅ Valid category names only
categories:
  - typescript
  - go
```

### Invalid Version Constraints

```yaml
# ❌ Invalid version format
version: "2.0.0"
```

**Error:** `Invalid version constraint: 2.0.0`

**Fix:**
```yaml
# ✅ Version with operator
version: ">=2.0.0"
```

### Unknown Configuration Keys

```yaml
# ❌ Unknown configuration key
categories:
  - typescript
unknown_option: value
```

**Error:** `Unknown configuration keys: unknown_option`

**Fix:**
```yaml
# ✅ Only known keys
categories:
  - typescript
```

## Common Use Cases

### Single Language Project

```yaml
# TypeScript-only project
categories:
  - typescript
```

### Full-Stack Project

```yaml
# Frontend and backend with security
categories:
  - typescript
  - go
  - security
  - database
  - api
```

### Microservices Project

```yaml
# Multiple languages with shared practices
categories:
  - go
  - python
  - rust
  - security
  - database
  - git
version: ">=2.0.0"
```

### Library/Package Project

```yaml
# Language-specific library
categories:
  - rust
  - git
docs_path: "docs/development"
```

## Integration with CI/CD

The `.leyline` file works seamlessly with automated workflows:

```yaml
# .github/workflows/sync-standards.yml
name: Sync Development Standards
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.1'
      - name: Install leyline
        run: gem install leyline
      - name: Sync standards (uses .leyline config)
        run: leyline sync
      - name: Create PR
        run: |
          # Create pull request with changes
```

## Best Practices

### 1. Version Pinning

```yaml
# Pin to major version for stability
version: ">=2.0.0,<3.0.0"
```

### 2. Category Selection

```yaml
# Only include categories relevant to your project
categories:
  - typescript  # You use TypeScript
  - security    # Security is always relevant
  # Don't include 'go' if you don't use Go
```

### 3. Path Organization

```yaml
# Use consistent path naming
docs_path: "docs/leyline"        # Recommended
docs_path: "docs/standards"      # Alternative
docs_path: "standards/leyline"   # Alternative
```

### 4. Team Coordination

```yaml
# Document your choices for team members
# This project uses TypeScript with Go microservices
categories:
  - typescript
  - go
  - security
  - database
version: ">=2.1.0"
```

## Troubleshooting

### Configuration Not Loading

**Problem:** Commands ignore `.leyline` file

**Check:**
1. File is named exactly `.leyline` (no extension)
2. File is in project root directory
3. File contains valid YAML
4. Run `leyline sync --verbose` to see configuration loading

### Version Conflicts

**Problem:** `Version constraint not satisfied`

**Solution:**
```bash
# Check your leyline version
leyline version

# Update leyline if needed
gem update leyline

# Or adjust version constraint in .leyline
```

### Category Errors

**Problem:** `Invalid categories` error

**Solution:**
```bash
# Check available categories
leyline discovery categories

# Update .leyline with valid category names
```

## Schema Reference

Here's the complete schema for the `.leyline` file:

```yaml
# Complete .leyline file schema
categories:           # Array of strings (optional)
  - string            # Valid category name
version: "string"     # Version constraint string (optional)
docs_path: "string"   # Target directory path (optional)
```

**Constraints:**
- File must be valid YAML
- Root must be a hash/object
- `categories`: Array of non-empty strings, valid category names only
- `version`: String matching pattern `/^[><=~]+\s*\d+\.\d+(\.\d+)?/`
- `docs_path`: Non-empty string, will be normalized (whitespace stripped)
- Unknown keys will cause validation errors
- Empty file is valid (uses all defaults)
