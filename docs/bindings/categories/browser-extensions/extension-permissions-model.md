---
id: extension-permissions-model
last_modified: '2025-06-14'
version: '0.2.0'
derived_from: no-secret-suppression
enforced_by: security review & user testing
---
# Binding: Request Minimal Browser Extension Permissions with Clear Justification

Request only the permissions necessary for core functionality, with clear explanations of why each permission is needed. Use optional permissions for advanced features and implement graceful degradation when permissions are denied.

## Rationale

This binding implements our no-secret-suppression tenet by making extension capabilities and data access explicit to users. Browser extensions operate in a position of significant trust, with access to sensitive user data, browsing history, and web content. When extensions request excessive permissions or fail to explain their necessity, they violate user trust and create security risks that users cannot assess.

Think of extension permissions like keys to different rooms in a house. A house guest needs keys to common areas but shouldn't automatically receive keys to private bedrooms, safes, or storage areas unless there's a specific, justified need. Similarly, extensions should request access only to the browser capabilities they actually use, with clear explanations of why each "key" is necessary for the promised functionality.

This binding also supports our simplicity tenet by encouraging focused extension functionality rather than feature creep that requires additional permissions.

## Rule Definition

This binding establishes principles for extension permission management:

- **Minimal Permission Principle**: Request only permissions required for core functionality:
  - Analyze actual usage patterns vs. requested permissions
  - Remove unused permissions during development
  - Prefer specific origins over broad host permissions
  - Use optional permissions for non-essential features

- **Permission Justification**: Provide clear explanations for each permission:
  - User-facing documentation explaining why each permission is needed
  - Examples of how the permission enables specific features
  - Privacy policy sections addressing data access and usage
  - In-extension UI explaining permission requirements

- **Optional Permission Strategy**: Implement progressive permission requests:
  - Core functionality works with minimal permissions
  - Advanced features request additional permissions when needed
  - Graceful degradation when optional permissions are denied
  - Clear UI indicating which features require additional permissions

- **Permission Scope Minimization**: Use the most restrictive permission that meets needs:
  - Specific host patterns instead of `<all_urls>`
  - `activeTab` instead of persistent tab access
  - `storage` instead of `unlimitedStorage` when possible
  - Contextual permissions instead of persistent access

## Implementation

Design permission strategies that respect user privacy:

1. **Core Functionality Analysis**: Identify absolutely essential permissions:
   - Map each permission to specific user-facing features
   - Document the minimal viable permission set
   - Remove any permissions not actively used in current version

2. **Progressive Enhancement**: Design for optional permissions:
   - Implement feature detection for optional capabilities
   - Provide alternative workflows when permissions are unavailable
   - Use `chrome.permissions` API for runtime permission requests

3. **User Communication**: Explain permissions clearly:
   - Create permission explanation pages or dialogs
   - Use plain language instead of technical permission names
   - Show examples of what the extension will and won't do
   - Provide privacy policy links in extension listings

4. **Permission Monitoring**: Track permission usage:
   - Audit code for unused permission declarations
   - Monitor user permission grant/deny rates
   - Review permission requirements during feature development

## Anti-patterns

- **Permission Hoarding**: Requesting permissions "just in case" for future features
- **Vague Justification**: Generic explanations that don't connect permissions to features
- **All-or-Nothing**: Requiring all permissions for any functionality
- **Hidden Usage**: Using permissions in ways not explained to users
- **Scope Creep**: Gradually expanding permission usage without user notification

## Enforcement

This binding should be enforced through:

- **Security Reviews**: Regular audits of permission usage vs. declarations
- **Privacy Impact Assessments**: Analysis of data access and usage patterns
- **User Testing**: Testing permission grant rates and user understanding
- **Code Reviews**: Checking new features against permission requirements

## Exceptions

Valid cases for broader permissions:

- **Development/Testing**: Test versions may need additional permissions for debugging
- **User-Requested Features**: Users explicitly requesting functionality requiring new permissions
- **Security Features**: Tools that need broad access for security analysis
- **Accessibility Tools**: Extensions providing accessibility features may need extensive access

Always document exceptions and their security implications.

## Related Bindings

- [extension-update-strategy](extension-update-strategy.md): Communicating permission changes during updates
- [cross-browser-compatibility](cross-browser-compatibility.md): Permission differences across browsers
- [secrets-management-practices](../../security/secrets-management-practices.md): Protecting sensitive data in extensions
