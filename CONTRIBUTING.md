# Contributing to Leyline

Thank you for your interest in contributing to Leyline! This document provides
guidelines for proposing changes to our tenets and bindings.

> **Note**: This guide is for contributors to Leyline itself. If you're looking to integrate Leyline into your project, see the [Pull-Based Integration Guide](docs/integration/pull-model-guide.md).

## Core Principles

Leyline maintains two types of documents:

1. **Tenets**: Immutable truths and principles that guide our development philosophy
1. **Bindings**: Enforceable rules derived from tenets, with specific implementation
   guidance

## Natural Language First Approach

Leyline adopts a "natural language first" approach to documentation. This means our
tenets and bindings are written to be:

1. **Accessible to humans** with different technical backgrounds
1. **Effective as context for large language models (LLMs)**
1. **Principle-focused** rather than implementation-focused

All new tenets and bindings should follow this approach. Please refer to our
[Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md) for detailed
writing guidelines and examples.

## Document Conciseness Requirements

Leyline enforces strict length limits to ensure documents remain tight, punchy, and focused on core value:

**Tenets**: Maximum 100 lines (warning), 150 lines (failure)
**Bindings**: Maximum 200 lines (warning), 300 lines (failure)

These limits are automatically enforced through CI validation using `tools/enforce_doc_limits.rb`. Documents exceeding these limits will be rejected until they meet conciseness standards. For details on the enforcement rules and exemption process, see:
- [Document Length Enforcement](docs/document-length-enforcement.md)
- [Enforcement Exemption Process](docs/enforcement-exemption-process.md)

### The One Example Rule

Show each pattern once, clearly, rather than multiple times in different languages. Choose the most appropriate technology for your audience and provide language-agnostic principles alongside specific examples.

For complete guidance on writing concise, effective documentation, see our [Conciseness Guide](docs/CONCISENESS_GUIDE.md).

## Proposing Changes

### Process Overview

1. Fork the repository
1. Create a branch with a descriptive name
1. Make your changes following the guidelines below
1. Run validation tools locally
1. Submit a pull request with the appropriate label (`tenet` or `binding`)

### Front-Matter Standards

All tenet and binding documents **MUST** use YAML front-matter format for metadata. This
format is standardized across the project and is required for our toolchain to function
properly.

### Key Front-Matter Requirements

1. **Format**: Use YAML front-matter enclosed by triple dashes (`---`)
1. **Required Fields**:
   - For tenets: `id`, `last_modified`, and `version`
   - For bindings: `id`, `last_modified`, `version`, `derived_from`, and `enforced_by`
1. **All dates** must be in ISO format (YYYY-MM-DD) and enclosed in quotes (e.g.,
   `'2025-05-09'`)
1. **Version field** must match the current VERSION file content (e.g., `'0.1.0'`).
   This tracks which repository version the document was last modified in and enables
   semantic versioning and breaking change detection.

Binding applicability is determined by its location in the directory structure:
- `/docs/bindings/core/` - Core bindings that apply to all projects
- `/docs/bindings/categories/<category>/` - Category-specific bindings

This directory-based organization supports Leyline's pull-based distribution model, allowing consumers to selectively sync only the categories relevant to their projects.

For detailed guidance on front-matter requirements, including examples, format
conversion, and troubleshooting, refer to [TENET_FORMATTING.md](TENET_FORMATTING.md).

## Development Setup

### Pre-commit Hooks (Mandatory)

To ensure quality and consistency, you must install pre-commit hooks that automatically validate your changes:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks in your local repository
pre-commit install

# Test hooks manually (optional)
pre-commit run --all-files
```

The pre-commit hooks will automatically:
- Validate YAML front-matter format and required fields
- Check index consistency with strict validation
- Fix trailing whitespace and ensure proper file endings
- Validate YAML syntax

### Manual Validation

You can also run validation tools manually before submitting your PR:

```bash
# Validate front-matter format and required fields
ruby tools/validate_front_matter.rb

# Regenerate index files
ruby tools/reindex.rb
```

## Tooling Version Management

### Current Tooling Versions

Leyline uses a combination of pinned and latest versions for its CI toolchain. This strategy balances stability with access to the latest features and security updates.

#### Language Runtimes (Pinned)
- **Python**: 3.11
- **Ruby**: 3.0
- **Node.js**: 20

#### Code Quality Tools (Latest)
- **flake8**: latest (Python linting)
- **mypy**: latest (Python type checking)
- **markdown-link-check**: latest via npm (link validation)
- **gitleaks**: latest from GitHub releases (secret scanning)

#### Tool Configuration Standards
- **flake8**: `--max-line-length=88`, `--extend-ignore=E203,W503` (black compatibility)
- **mypy**: `--strict`, `--no-error-summary`, `--show-column-numbers`

### Version Pinning Policy

#### When to Pin Versions

**Pin versions for:**
1. **Language runtimes** - Ensures consistent behavior across development and CI environments
2. **Tools with breaking configuration changes** - When tools frequently introduce incompatible CLI or config changes
3. **Security-critical tools** - When specific versions are required for compliance or security analysis

**Use latest versions for:**
1. **Code quality tools** - Benefit from latest rules, bug fixes, and performance improvements
2. **Non-breaking tooling** - Tools with stable APIs and backward-compatible updates
3. **Community-maintained tools** - Leverage community improvements and security patches

#### Version Update Process

**Quarterly Review (Recommended):**
1. **Audit current versions** - Review CI logs for deprecation warnings or version conflicts
2. **Test major updates** - Create test branch to validate new language runtime versions
3. **Update documentation** - Reflect any changes in this policy document

**Emergency Updates:**
1. **Security vulnerabilities** - Update immediately when critical security issues are identified
2. **Blocking bugs** - Update tools that prevent CI from functioning correctly
3. **Breaking changes** - Pin versions when tools introduce breaking changes affecting our workflow

#### Implementation Locations

**CI Configuration**: `.github/workflows/validate.yml`
- Language runtime versions specified in setup actions
- Tool installations via package managers (pip, npm, curl)

**Tool Configuration**: `tools/validate_python_examples.rb`
- flake8 and mypy configuration constants
- Command-line arguments and flags

**Documentation**: This file (`CONTRIBUTING.md`)
- Current version inventory and policy decisions
- Update procedures and responsibilities

### Maintenance Responsibilities

**For Contributors:**
- Follow the current tool versions when developing locally
- Report version conflicts or deprecation warnings in pull requests
- Suggest tool updates when they provide significant value

**For Maintainers:**
- Monitor tool releases for security updates
- Test tool updates in isolated branches before merging
- Update this documentation when version policies change
- Coordinate with community when breaking changes affect workflows

### Troubleshooting Version Issues

**Common Issues:**
1. **Tool not found** - Ensure tools are installed with correct versions for local development
2. **Configuration conflicts** - Check tool documentation for configuration changes between versions
3. **CI failures** - Review CI logs for version-specific error messages

**Resolution Steps:**
1. Check current CI configuration for expected versions
2. Update local development environment to match CI versions
3. Consult tool-specific documentation for configuration updates
4. Open issue if persistent problems affect the development workflow

## CI Dependency Management

### Dependency Installation Principles

Leyline's CI pipeline follows a strategic approach to external tool installation that prioritizes reliability, maintainability, and clear failure diagnostics. These principles guide all CI dependency management decisions:

#### 1. Prefer Official Actions Over Manual Installation

**Primary Strategy**: Use official GitHub Actions when available
- **Reliability**: Actions are maintained by tool authors with built-in error handling
- **Simplicity**: No need to manage URLs, versions, or platform compatibility
- **Maintenance**: Automatic updates through action versioning

**Example**: `gitleaks/gitleaks-action@v2` vs. manual curl/tar installation

#### 2. Implement Intelligent Fallback Strategies

**Multi-Tier Approach**: Design resilient installation chains
- **Primary**: Official GitHub Action (highest reliability)
- **Fallback 1**: GitHub API + dynamic URL resolution (handles action failures)
- **Fallback 2**: Package manager installation (handles network/API issues)
- **Fallback 3**: Clear error diagnostics (handles total failures)

**Conditional Execution**: Fallbacks only run when needed (`continue-on-error` + outcome checking)

#### 3. Provide Actionable Error Diagnostics

**Clear Failure Guidance**: Every failure mode includes specific troubleshooting steps
- **Installation Issues**: Check GitHub Actions service status, API rate limits, network connectivity
- **Tool Issues**: Validate tool functionality, check version compatibility, review logs
- **Configuration Issues**: Verify tool arguments, check file paths, validate permissions

### Preferred Installation Methods

Follow this decision matrix for adding new CI dependencies:

#### Tier 1: Official GitHub Actions (Preferred)
```yaml
- name: Tool scan
  uses: official/tool-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    args: --target=specific-directory
```

**When to Use**: Tool provides official action, action is actively maintained, covers your use case

**Benefits**: Built-in error handling, platform compatibility, automatic updates, community support

#### Tier 2: GitHub API + Manual Installation (Fallback)
```yaml
- name: Install tool manually
  if: steps.official-action.outcome == 'failure'
  run: |
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/tool/tool/releases/latest")
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url.*linux_x64.tar.gz" | cut -d '"' -f 4)
    curl -sSfL "$DOWNLOAD_URL" | tar -xzf - -C /tmp
    sudo mv /tmp/tool /usr/local/bin/tool
```

**When to Use**: Official action fails, tool provides GitHub releases, need specific configuration

**Benefits**: Dynamic URL resolution, handles release format changes, works with various tools

#### Tier 3: Package Manager Installation (Emergency Fallback)
```yaml
- name: Install via package manager
  if: steps.manual-install.outcome == 'failure'
  run: sudo apt-get update && sudo apt-get install -y tool-name
```

**When to Use**: All other methods fail, tool available in Ubuntu packages, emergency reliability needed

**Benefits**: System-native installation, dependency resolution, ultimate fallback

#### Anti-Patterns to Avoid

**❌ Hardcoded URLs**: Fragile, breaks when releases change format
```yaml
# Don't do this
curl -sSfL https://github.com/tool/tool/releases/latest/download/tool_linux_x64.tar.gz
```

**❌ Single Point of Failure**: No fallback when primary method fails
```yaml
# Risky - what if the action is unavailable?
- uses: unofficial/tool-action@v1  # No fallback strategy
```

**❌ Silent Failures**: No error diagnostics for troubleshooting
```yaml
# Provides no guidance when things go wrong
- run: install-tool || exit 1
```

### Common CI Failures and Troubleshooting

#### Installation Failures

**Symptoms**: Tool installation steps fail with various errors

**Troubleshooting Steps**:
1. **Check GitHub Actions Status**: Visit [status.github.com](https://status.github.com) for service outages
2. **Verify Action Availability**: Confirm the action repository exists and the version tag is valid
3. **Review API Rate Limits**: Check for GitHub API rate limiting messages in logs
4. **Test Network Connectivity**: Verify runner can access external resources
5. **Check Release Format**: Confirm tool maintainers haven't changed release artifact naming

**Resolution Strategies**:
- Use fallback installation methods automatically triggered by workflow logic
- Pin specific action versions if latest introduces breaking changes
- Implement retry logic for transient network issues

**Example Diagnostic Output**:
```
🔧 Installation troubleshooting:
- Check GitHub Actions service status
- Verify gitleaks/gitleaks-action@v2 is available
- Check for GitHub API rate limiting
- Review network connectivity
```

#### Tool Execution Failures

**Symptoms**: Tool installs successfully but fails during execution

**Troubleshooting Steps**:
1. **Validate Tool Installation**: Confirm tool is accessible and reports correct version
2. **Check File Paths**: Verify target directories exist and are accessible
3. **Review Tool Arguments**: Confirm command-line arguments match tool expectations
4. **Examine Permissions**: Ensure runner has necessary file access permissions
5. **Test Tool Configuration**: Validate any configuration files or environment variables

**Resolution Strategies**:
- Add tool version logging for debugging
- Implement health checks before tool execution
- Provide clear error context for common tool failures

#### Configuration Drift Issues

**Symptoms**: CI works in one environment but fails in another

**Troubleshooting Steps**:
1. **Compare Tool Versions**: Check for version mismatches between environments
2. **Review Configuration Changes**: Look for recent updates to tool configurations
3. **Validate Dependencies**: Ensure all required dependencies are present
4. **Check Environment Variables**: Verify environment-specific settings

**Resolution Strategies**:
- Document expected tool versions in this file
- Use consistent configuration across environments
- Implement version validation in CI health checks

### Implementation Best Practices

#### Step Naming and Organization
```yaml
- name: Primary tool execution
  id: primary-step
  uses: official/action@v2
  continue-on-error: true

- name: Fallback - Manual installation
  id: fallback-step
  if: steps.primary-step.outcome == 'failure'
  run: |
    echo "⚠️ Primary method failed, attempting fallback..."
    # Fallback logic here
```

#### Error Context and Logging
```yaml
- name: Report tool results
  if: failure()
  run: |
    echo "❌ Tool execution failed!"
    if [ "${{ steps.primary-step.outcome }}" == "failure" ]; then
      echo "🔧 Primary installation failed - check action availability"
    fi
    echo "📝 For configuration issues:"
    echo "- Verify tool arguments and file paths"
    echo "- Check tool documentation for recent changes"
```

#### Health Monitoring
```yaml
- name: Log tool versions
  run: |
    echo "📊 CI Tool Inventory:"
    echo "Ruby: $(ruby --version)"
    echo "Tool: $(tool --version)"
    echo "Environment: $(uname -a)"
```

### Maintenance Guidelines

#### For Contributors
- **Report CI Issues**: Include full error logs and environment details
- **Test Locally**: Verify changes work with current tool versions
- **Follow Patterns**: Use established fallback strategies for consistency

#### For Maintainers
- **Monitor CI Health**: Review tool installation success rates regularly
- **Update Fallback Logic**: Enhance error handling based on real failure patterns
- **Maintain Documentation**: Keep troubleshooting guides current with actual issues

#### Quarterly CI Review Process
1. **Audit Tool Versions**: Review current versions against latest releases
2. **Test Fallback Strategies**: Verify backup installation methods still work
3. **Update Documentation**: Reflect any changes in troubleshooting procedures
4. **Clean Up Dead Code**: Remove obsolete fallback logic for deprecated tools

This approach ensures Leyline's CI pipeline remains robust, maintainable, and provides clear guidance for resolving issues when they occur.

### Markdown Guidelines

All markdown files in this repository should follow consistent style guidelines:

1. **Write clear, readable markdown** - Focus on content over strict formatting
2. **Use proper heading hierarchy** - Structure documents logically
3. **Maintain appropriate whitespace** - Use blank lines to separate content sections
4. **Be consistent with lists and indentation** - Follow standard markdown conventions

The pre-commit hooks will handle basic formatting like trailing whitespace and line endings.

## Guidelines for Specific Contributions

### Proposing a New Tenet

**Requirements:**

- PR must have the "tenet" label
- Must represent a fundamental, enduring principle
- Must follow the natural language style guidance

**File Structure:**

- Create file in `docs/tenets/` directory with a descriptive slug (e.g.,
  `simplicity.md`)
- Use the [tenet template](docs/templates/tenet_template.md) as your starting point
- Follow YAML front-matter format as specified in
  [TENET_FORMATTING.md](TENET_FORMATTING.md):
  ```yaml
  ---
  # Unique identifier for this tenet (must match filename without .md)
  id: your-tenet-slug
  # Date of last modification in ISO format with single quotes
  last_modified: '2025-05-09'
  ---
  ```
- Use the standard markdown structure:
  ```markdown
  # Tenet: Your Tenet Title

  [A concise 1-2 sentence principle statement that captures the essence of this tenet in plain, accessible language.]

  ## Core Belief

  [2-4 paragraphs explaining why this principle matters, using a conversational tone and relatable analogies.]

  ## Practical Guidelines

  1. **First Guideline**: [Explanation of how to apply the principle in practical terms]
  2. **Second Guideline**: [Another practical application of the principle]
  ...

  ## Warning Signs

  - **First Warning Sign**: [Description of behavior indicating the principle is being violated]
  ...

  ## Related Tenets

  - [Simplicity](docs/tenets/simplicity.md): [Explanation of how these tenets relate to each other]
  ...
  ```

### Proposing a New Binding

**Requirements:**

- PR must have the "binding" label
- Must be derived from an existing tenet
- Must be enforceable (through tools, reviews, etc.)
- Must follow the natural language style guidance

**File Structure:**

- Place the file in the directory that defines its scope:
  - `docs/bindings/core/` for bindings that apply to all projects
  - `docs/bindings/categories/<category>/` for category-specific bindings
    - Valid categories: `go`, `rust`, `typescript`, `cli`, `frontend`, `backend`

- Use a descriptive filename without category prefixes (e.g., `no-any.md` rather than `ts-no-any.md`)

- Use the [binding template](docs/templates/binding_template.md) as your starting point

- Follow YAML front-matter format as specified in
  [TENET_FORMATTING.md](TENET_FORMATTING.md):

  ```yaml
  ---
  # Unique identifier for this binding (must match filename without .md)
  id: your-binding-slug
  # Date of last modification in ISO format with single quotes
  last_modified: '2025-05-09'
  # ID of the parent tenet this binding implements
  derived_from: parent-tenet-id
  # Tool, rule, or process that enforces this binding
  enforced_by: description of enforcement mechanism
  ---
  ```

- Use the standard markdown structure:

  ````markdown
  # Binding: Your Binding Title

  [A concise 1-2 sentence statement of the rule in plain language.]

  ## Rationale

  [2-3 paragraphs explaining why this rule exists and how it connects to the parent tenet. Include analogies where appropriate to make abstract concepts more relatable.]

  ## Rule Definition

  [Clear, conversational explanation of the rule, its scope, and boundaries.]

  ## Practical Implementation

  [Actionable guidelines for implementing the rule in different contexts.]

  ## Examples

  ```language
  // ❌ BAD: Anti-pattern example
  code here

  // ✅ GOOD: Correct pattern
  code here
  ````

  ## Related Bindings

  - [Dependency Inversion](docs/bindings/dependency-inversion.md): \[Explanation of how
    these bindings work together or complement each other\] ...

  ```

### Security-Specific Bindings

Security bindings require additional considerations beyond the standard binding requirements:

**Location**: All security bindings are placed in `docs/bindings/categories/security/`

**Additional Requirements:**
- Must follow [Security Binding Documentation Standards](docs/security-binding-standards.md)
- Examples must use only placeholder credentials (never real secrets)
- Must specify concrete security tools in the `enforced_by` field
- Must address realistic security threats and vulnerabilities
- Must be reviewed for security domain accuracy

**Security Content Standards:**
- **No sensitive information**: Examples must contain only placeholder credentials like `your-api-key-here` or `${API_KEY}`
- **Realistic scenarios**: Address actual security challenges developers face
- **Clear enforcement**: Specify concrete security tools and processes
- **Threat-focused**: Connect security practices to real threats and attack vectors

For complete guidelines on creating security bindings, including enforcement patterns, content standards, and security-specific template adaptations, see the [Security Binding Documentation Standards](docs/security-binding-standards.md).

### Cross-Cutting Bindings Strategy

When deciding where to place bindings that could apply across multiple categories, follow these guidelines to determine the definitive directory placement (see the [Implementation Guide](docs/implementation-guide.md) for detailed placement guidance):

1. **Core Bindings**:
   - Place a binding in `docs/bindings/core/` if:
     - It should apply to virtually all projects regardless of language or context
     - It represents a fundamental principle that transcends specific languages or environments
     - It can be described in language-agnostic terms

2. **Category Bindings**:
   - Place a binding in `docs/bindings/categories/<category>/` if:
     - It should apply primarily to a specific programming language or context
     - It uses language-specific syntax or features
     - It addresses concerns specific to a particular category

3. **Cross-Cutting Decision Process**:
   - Identify the primary category where the binding is most relevant
   - Place the binding in that primary category directory
   - In the binding document, clearly explain its relevance to other categories
   - Reference the binding from relevant documentation in other categories

### Cross-Category Reference Standards

When bindings need to reference patterns from other categories (e.g., security bindings referencing observability patterns), follow these standardized approaches to maintain clarity and consistency:

#### Reference Path Structure

Use relative paths with consistent format based on the target location:

**For Core Bindings:**
```markdown
[binding-name](../../docs/bindings/core/binding-name.md)
```

**For Category Bindings:**
```markdown
[binding-name](../../docs/bindings/categories/category-name/binding-name.md)
```

**For Tenets:**
```markdown
[tenet-name](../../docs/tenets/tenet-name.md)
```

#### Reference Context Requirements

Every cross-category reference must include explanatory text that:

1. **Explains the relationship**: How the bindings work together or complement each other
2. **Describes the functional connection**: What specific aspects relate and why
3. **Provides implementation guidance**: How following both bindings leads to better outcomes

**Example Reference Format:**
```markdown
- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Security monitoring requires structured logging to enable automated threat detection and incident correlation. Both bindings work together to create comprehensive security observability through machine-readable logs that security tools can analyze for anomalies and attack patterns.
```

#### Security-Specific Cross-Category Patterns

Security bindings commonly reference these patterns from other categories:

**Core Observability Bindings:**
- `use-structured-logging.md` - For security monitoring and incident correlation
- `context-propagation.md` - For security event tracing across system boundaries

**Core Configuration Bindings:**
- `external-configuration.md` - For secure credential management and environment-specific security settings
- `fail-fast-validation.md` - For input validation security patterns

**Core Automation Bindings:**
- `git-hooks-automation.md` - For security validation in development workflows
- `ci-cd-pipeline-standards.md` - For security gates in deployment pipelines

#### Bidirectional Reference Guidelines

When security bindings are referenced by other categories:

1. **Core bindings referencing security**: Use standard relative path format
2. **Category bindings referencing security**: Include security domain context in explanation
3. **Maintain consistency**: Follow the same explanation format regardless of direction

**Example of Category → Security Reference:**
```markdown
- [input-validation-standards](../../docs/bindings/categories/security/input-validation-standards.md): TypeScript's type system provides compile-time input validation that complements runtime security validation. Both approaches create layered protection against invalid data and injection attacks.
```

#### Cross-Category Reference Maintenance

To ensure references remain accurate and valuable:

1. **Validate during reviews**: Check that cross-references accurately describe relationships
2. **Update when needed**: Modify reference text when binding functionality changes
3. **Remove broken references**: Clean up references to deprecated or moved bindings
4. **Test reference paths**: Ensure all relative paths resolve correctly

This standardized approach ensures that cross-category relationships are clear, maintainable, and provide genuine value to readers understanding how different patterns work together.

### Editing Existing Documents

**For Tenets:**

- Changes should be clarifications, not fundamental alterations
- Update `last_modified` date to today's date in ISO format with single quotes (e.g.,
  `'2025-05-09'`)
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)
- Ensure the document uses YAML front-matter format for metadata as described in [TENET_FORMATTING.md](TENET_FORMATTING.md)

**For Bindings:**

- Can evolve more freely as implementation practices change
- Update `last_modified` date to today's date in ISO format with single quotes
- Ensure changes maintain or improve natural language quality
- Follow the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)
- Verify that all required front-matter fields are present and formatted correctly
- Ensure the document uses YAML front-matter format for metadata

## Writing Effective Natural Language Documentation

To create effective documentation that works well for both humans and LLMs, follow these
key principles:

1. **Principle-First Approach**: Start with the "why" before moving to the "how"
1. **Conversational Tone**: Use active voice and direct address
1. **Relatable Analogies**: Use analogies to explain complex concepts
1. **Clear Connections**: Establish explicit relationships between related concepts
1. **Narrative Structure**: Follow a problem → principle → solution → examples flow
1. **Balanced Detail**: Provide enough detail for understanding without overwhelming

For detailed guidance with examples, see the
[Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md).

## Release Process

- **Patch Releases** (typo fixes, clarifications): Quick review and merge
- **MINOR Releases** (new bindings): Standard review process
- **MAJOR Releases** (new/changed tenets, breaking binding changes): More thorough
  review

Each release must maintain consistent front-matter standards in YAML format as described in [TENET_FORMATTING.md](TENET_FORMATTING.md).

When new content is released, consumers using the pull-based model can update at their own pace by adjusting the `leyline_ref` in their sync workflow. See the [Versioning Guide](docs/integration/versioning-guide.md) for consumer versioning best practices.

## Versioning Policy

Leyline follows [Semantic Versioning](https://semver.org/) with special considerations for the pre-1.0 development phase.

### Current Version Strategy (Pre-1.0)

While Leyline is in active development (versions 0.x.x), we use a modified semantic versioning approach:

- **Breaking Changes**: Increment the **minor** version (0.1.0 → 0.2.0)
- **New Features**: Increment the **minor** version (0.1.0 → 0.2.0)
- **Bug Fixes/Clarifications**: Increment the **patch** version (0.1.0 → 0.1.1)

### Post-1.0 Strategy (Stable API)

Once Leyline reaches 1.0.0 (marking our commitment to API stability), we will follow standard semantic versioning:

- **Breaking Changes**: Increment the **major** version (1.0.0 → 2.0.0)
- **New Features**: Increment the **minor** version (1.0.0 → 1.1.0)
- **Bug Fixes/Clarifications**: Increment the **patch** version (1.0.0 → 1.0.1)

### What Constitutes Breaking Changes

Breaking changes in Leyline include:

1. **Removed or renamed tenet files** (e.g., deleting `docs/tenets/simplicity.md`)
2. **Removed or renamed binding files** (e.g., deleting `docs/bindings/core/pure-functions.md`)
3. **Changes to YAML front-matter schema** (e.g., renaming required fields, changing date format)
4. **Directory restructuring** (e.g., moving bindings between categories)
5. **Changes to binding metadata structure** that affect consumer tooling

### Path to 1.0.0

Version 1.0.0 will be released when:

- The core tenet and binding structure is stable
- Consumer integration patterns are well-established and tested
- The pull-based distribution model is fully mature
- Breaking changes become infrequent and well-justified

This represents our commitment to API stability and backward compatibility for consumers who depend on Leyline's structure and content.

## Code of Conduct

All contributors are expected to adhere to our code of conduct, which emphasizes:

- Respectful, professional communication
- Evidence-based technical discussions
- Collaborative problem-solving

## Questions?

If you have questions about contributing, please open an issue with the "question"
label.
