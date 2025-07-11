---
id: browser-extension-security-patterns
last_modified: '2025-06-14'
version: '0.2.0'
derived_from: explicit-over-implicit
enforced_by: 'Manifest validation, security review process, automated permission auditing'
---
# Binding: Implement Security-First Browser Extension Architecture

Design browser extensions using Manifest V3 with minimal permissions, secure message passing, and robust content script isolation. Treat browser extensions as high-risk applications that require defense-in-depth security strategies due to their privileged access to user data and web content.

## Rationale

This binding implements our explicit-over-implicit tenet by requiring that browser extension security concerns be visible, documented, and intentional architectural decisions rather than hidden assumptions about permission usage and data access patterns.

Think of browser extensions like security guards in a building—they need enough access to do their job effectively, but granting excessive permissions creates catastrophic risk if they're compromised. A malicious or vulnerable extension can steal passwords, intercept banking information, or modify web pages to inject malicious content. The principle of least privilege isn't just good practice for extensions; it's an essential security boundary that protects users from both malicious actors and accidental vulnerabilities.

Manifest V3's security model acknowledges these risks by enforcing stricter permissions, eliminating dangerous capabilities like remotely hosted code, and requiring explicit declarations of extension behavior. This isn't just Google being restrictive—it's a recognition that the browser extension ecosystem has been a major attack vector for malware and privacy violations.

The investment in security-first extension architecture protects both users and developers. Users gain confidence that extensions won't abuse their trust, while developers avoid the reputational and legal risks that come with security incidents. Extensions that follow security best practices also tend to be more reliable and performant, as security constraints often force better architectural decisions.

## Rule Definition

This rule applies to all browser extension development, including Chrome extensions, Edge extensions, and cross-browser extension development. The rule specifically requires:

- **Manifest V3 Compliance**: All new extensions must use Manifest V3 architecture and security model
- **Minimal Permissions**: Request only the minimum permissions necessary for core functionality
- **Secure Messaging**: Use structured message passing with validation between extension components
- **Content Script Isolation**: Isolate content scripts from web page context and validate all data exchange
- **No Remote Code**: Eliminate dynamically loaded or remotely hosted code execution

The rule prohibits Manifest V2 for new development, overly broad permissions (like `<all_urls>` without justification), direct DOM manipulation without validation, and any architecture that bypasses browser security boundaries.

Exceptions may be appropriate for extensions that genuinely require broad access patterns, but these must undergo additional security review and implement compensating controls.

## Practical Implementation

1. **Design Permission-First Architecture**: Before writing code, list the minimum permissions your extension actually needs. Design your feature set around what's possible with minimal permissions rather than requesting broad access for convenience.

2. **Implement Structured Message Passing**: Create typed message interfaces between background scripts, content scripts, and popup components. Validate all messages at boundaries and never trust data from web page context.

3. **Isolate Content Script Operations**: Run content scripts in isolated worlds separate from web page JavaScript. Validate any data extracted from web pages and sanitize content before processing or storage.

4. **Use Declarative APIs**: Leverage Manifest V3's declarative APIs (declarativeNetRequest, scripting API) instead of imperative approaches that require broader permissions or persistent background scripts.

5. **Implement Content Security Policy**: Configure strict CSP headers that prevent injection attacks and restrict resource loading to trusted sources only.

## Examples

```json
// ❌ BAD: Overly broad permissions
{
  "manifest_version": 3,
  "permissions": [
    "tabs",
    "activeTab",
    "storage",
    "<all_urls>",
    "background"
  ],
  "host_permissions": ["*://*/*"]
}

// ✅ GOOD: Minimal, specific permissions
{
  "manifest_version": 3,
  "permissions": [
    "activeTab",
    "storage"
  ],
  "host_permissions": [
    "https://api.example.com/*"
  ],
  "action": {},
  "content_scripts": [{
    "matches": ["https://targetsite.com/*"],
    "js": ["content.js"]
  }]
}
```

```javascript
// ❌ BAD: Direct DOM manipulation without validation
// content.js
const userInput = document.querySelector('#user-input').value;
chrome.runtime.sendMessage({
  action: 'processData',
  data: userInput  // Unsanitized data from web page
});

// ✅ GOOD: Validated message passing with type safety
// content.js
const userInput = document.querySelector('#user-input')?.value;
if (userInput && typeof userInput === 'string' && userInput.length < 1000) {
  const sanitizedInput = userInput.replace(/<[^>]*>/g, ''); // Basic HTML stripping
  chrome.runtime.sendMessage({
    action: 'processData',
    data: sanitizedInput,
    source: 'content-script',
    timestamp: Date.now()
  });
}

// background.js
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (!sender.tab || !message.action) return;

  if (message.action === 'processData' &&
      typeof message.data === 'string' &&
      message.source === 'content-script') {
    // Process validated data
    processUserData(message.data);
  }
});
```

```javascript
// ❌ BAD: Executing remote code or eval()
fetch('https://api.example.com/config.js')
  .then(response => response.text())
  .then(code => eval(code)); // Security violation

// ✅ GOOD: Declarative configuration with validation
fetch('https://api.example.com/config.json')
  .then(response => response.json())
  .then(config => {
    if (isValidConfig(config)) {
      applyConfiguration(config);
    }
  });

function isValidConfig(config) {
  return config &&
         typeof config.apiEndpoint === 'string' &&
         config.apiEndpoint.startsWith('https://') &&
         typeof config.timeout === 'number' &&
         config.timeout > 0 && config.timeout < 30000;
}
```

## Related Bindings

- [secure-by-design-principles.md](../security/secure-by-design-principles.md): Browser extension security directly implements secure-by-design by making security considerations primary architectural constraints rather than afterthoughts.

- [input-validation-standards.md](../security/input-validation-standards.md): Extension security requires rigorous input validation at all boundaries between extension components and between extension and web page contexts, as these boundaries represent critical trust transitions.
