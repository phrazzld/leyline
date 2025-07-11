# Security Binding Documentation Standards

This document establishes standards specific to security binding creation, building upon the existing [binding metadata schema](binding-metadata.md) and [binding template](templates/binding_template.md).

## Security Binding Categorization

Security bindings are placed in `docs/bindings/categories/security/` and follow the standard categorization approach:

- **Primary Focus**: Security-specific patterns, practices, and controls
- **Scope**: Cross-cutting security concerns that apply to multiple languages/contexts
- **Derivation**: Derived from security-relevant tenets (e.g., `no-secret-suppression`, `explicit-over-implicit`, `automation`, `fail-fast-validation`)

## YAML Front-Matter Standards

Security bindings use the standard binding metadata format with **no additional fields required**:

```yaml
---
id: unique-security-binding-id
last_modified: 'YYYY-MM-DD'
version: '0.2.0'
derived_from: relevant-tenet-id
enforced_by: specific enforcement mechanism
---
```

### Security-Specific `enforced_by` Patterns

For security bindings, the `enforced_by` field should specify concrete security tools and processes:

- **Static Analysis**: `eslint-security-plugin`, `bandit`, `semgrep`, `codeql`
- **Secret Detection**: `trufflehog`, `detect-secrets`, `gitleaks`
- **Dependency Scanning**: `npm audit`, `pip-audit`, `govulncheck`
- **Infrastructure Security**: `tfsec`, `checkov`, `kube-score`
- **Process Controls**: `security code review`, `threat modeling process`, `compliance audit`
- **Combined Approaches**: `pre-commit hooks + CI security gates + manual review`

### Example Front-Matter for Security Bindings

```yaml
---
id: input-validation-standards
last_modified: '2025-06-11'
version: '0.2.0'
derived_from: fail-fast-validation
enforced_by: static analysis tools (semgrep, codeql) + security code review
---
```

## Security Content Standards

### Security Example Guidelines

Security binding examples must follow these strict guidelines:

#### ✅ **Required Practices**
- **Use placeholder credentials**: `your-api-key-here`, `<YOUR_SECRET>`, `${API_KEY}`
- **Demonstrate realistic scenarios**: Common security vulnerabilities and proper mitigations
- **Show clear before/after**: Anti-pattern followed by secure implementation
- **Include multiple contexts**: Different languages/frameworks where applicable
- **Focus on principles**: Explain *why* the security approach matters

#### ❌ **Prohibited Content**
- **Real credentials**: No actual API keys, passwords, tokens, or secrets
- **Working exploits**: No functional vulnerability demonstrations
- **Sensitive patterns**: No real connection strings, internal hostnames, or system details
- **Outdated practices**: Avoid deprecated security approaches unless specifically comparing
- **Security through obscurity**: Don't rely on hiding information for security

### Security Enforcement Documentation

Each security binding must clearly document:

1. **Automated Enforcement**: Tools that can automatically detect violations
2. **Manual Verification**: Review processes and checklists for complex scenarios
3. **Integration Points**: How enforcement integrates with CI/CD, pre-commit hooks, etc.
4. **Failure Handling**: What happens when security violations are detected

### Security Anti-Pattern Examples

```markdown
## Examples

```javascript
// ❌ BAD: Hardcoded secret in source code
const apiKey = "sk-real1234567890abcdef"; // NEVER do this
fetch(`https://api.service.com/data?key=${apiKey}`);

// ✅ GOOD: External configuration with validation
const apiKey = process.env.API_KEY;
if (!apiKey) {
  throw new Error("API_KEY environment variable is required");
}
fetch(`https://api.service.com/data?key=${apiKey}`);
\```
```

## Security Template Adaptations

### Enhanced Rationale Section

Security bindings should emphasize:
- **Security impact**: Specific vulnerabilities or threats addressed
- **Attack scenarios**: Real-world security risks prevented
- **Defense depth**: How this binding fits into overall security strategy
- **Compliance alignment**: Relevant security standards or regulations

### Security-Focused Practical Implementation

Structure implementation guidance around:

1. **Security Controls**: Primary security mechanisms to implement
2. **Tool Integration**: Specific security tool configuration and setup
3. **Detection and Response**: How to identify and respond to violations
4. **Monitoring and Validation**: Ongoing security validation approaches
5. **Exception Handling**: Secure approaches to handle edge cases

### Security-Specific Related Bindings

Security bindings should reference:
- **Foundation bindings**: Core security automation, external configuration
- **Complementary security**: Other security bindings that work together
- **Supporting practices**: Non-security bindings that enhance security posture

## Validation and Quality Assurance

### Security Content Review Checklist

Before finalizing security bindings, verify:

- [ ] **No sensitive information**: Examples contain only placeholder credentials
- [ ] **Realistic scenarios**: Examples represent actual security challenges
- [ ] **Clear enforcement**: Enforcement mechanisms are specific and actionable
- [ ] **Principle focus**: Content emphasizes security principles over implementation details
- [ ] **Tool integration**: Enforcement tools are documented with configuration examples
- [ ] **Cross-references**: Related security bindings are appropriately linked
- [ ] **Threat alignment**: Content addresses real security threats and attack vectors

### Security Expertise Integration

Security binding content should be reviewed by:
1. **Security practitioners**: Validate technical accuracy and threat coverage
2. **Development teams**: Ensure practical applicability and implementation clarity
3. **Compliance experts**: Verify alignment with relevant security standards (if applicable)

## Migration from Existing Security Content

When migrating existing security guidance:

1. **Audit for sensitive content**: Remove any real credentials or system details
2. **Update enforcement mechanisms**: Specify current security tools and processes
3. **Validate threat relevance**: Ensure security threats addressed are current
4. **Align with tenet derivation**: Connect security practices to foundational tenets
5. **Test automation integration**: Verify security tools can enforce the binding

## Security Binding Naming Conventions

Security binding filenames should be:
- **Descriptive and specific**: `input-validation-standards.md` not `validation.md`
- **Action-oriented**: Focus on what developers should do
- **Threat-specific**: Address specific security concerns when applicable
- **Platform-agnostic**: Avoid language-specific prefixes unless truly specific

### Example Security Binding Names
- `secure-by-design-principles.md`
- `input-validation-standards.md`
- `authentication-authorization-patterns.md`
- `secrets-management-practices.md`
- `secure-coding-checklist.md`

This standards document ensures security bindings maintain high quality while providing actionable, enforceable security guidance that integrates seamlessly with existing development workflows.
