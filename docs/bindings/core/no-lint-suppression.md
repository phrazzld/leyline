---
derived_from: no-secret-suppression
enforced_by: code review & custom linters
id: no-lint-suppression
last_modified: '2025-05-14'
version: '0.1.0'
---
# Binding: Document Why You're Silencing Warnings

Never disable or suppress linter warnings, static analysis errors, or type checking
flags without including a detailed comment explaining why the suppression is necessary,
what makes the code safe despite the warning, and why fixing the issue properly isn't
feasible. Unexplained suppressions are strictly forbidden.

## Rationale

This binding directly implements our no-secret-suppression tenet by requiring
transparency and justification when bypassing automated quality guardrails. When you
silence a warning without explanation, you're essentially making a unilateral decision
that future developers must trust blindly, with no way to evaluate whether your bypass
was warranted or remains necessary as the code evolves.

Think of lint suppressions like prescription medication warnings—they exist for
important reasons, and choosing to ignore them requires informed, documented
justification. Just as a doctor who overrides a medication warning must record their
reasoning in the patient's chart for other medical professionals to understand the
decision, a developer who bypasses a linter warning must document their reasoning for
future maintainers. Without this documentation, others have no way to distinguish
between legitimate exceptions and dangerous technical debt.

The dangers of undocumented suppressions compound over time. As codebases grow and team
members change, the original context and reasoning behind suppressions are lost. New
developers encountering a silent suppression must either blindly trust it or spend
precious time reverse-engineering the intent. Worse, when the code surrounding a
suppression changes, there's no way to know if the conditions that justified the
exception still apply. By requiring clear documentation for every suppression, we create
a history of deliberate decisions rather than mysterious exceptions, making the codebase
more maintainable, safer, and ultimately, more trustworthy.

## Rule Definition

This binding establishes clear requirements for any code that suppresses automated
quality checks:

- **Document Every Suppression**: All directives that disable linter rules, type
  checking, or other automated quality checks must include an explanatory comment that:

  - Identifies why the underlying rule is triggering in this specific case
  - Explains why the code is actually correct/safe despite the warning
  - Clarifies why fixing the issue properly isn't currently feasible
  - Ideally includes a ticket reference or timeline for revisiting the suppression

- **Suppression Methods Covered**: This rule applies to all forms of quality check
  suppressions, including but not limited to:

  - Language-specific linter suppression comments (e.g., `// eslint-disable-line`,
    `// nolint`, `// NOSONAR`)
  - Compiler flag suppressions (e.g., `#pragma warning disable`, `#[allow(...)]`,
    `@SuppressWarnings`)
  - Inline type assertions that bypass type checking (e.g., `as any`, type casts,
    `@ts-ignore`)
  - Configuration-based suppressions in linter config files
  - CI/build script flags that bypass quality checks (`--no-lint`, `--force`, etc.)

- **Limit Suppression Scope**: Beyond documentation, suppressions must be:

  - As narrow as possible in scope (line-level rather than file-level when available)
  - As specific as possible (targeting only the exact rule being suppressed)
  - Temporary by default (include a timeline or conditions for removal when possible)

- **Exceptions**: This binding recognizes limited scenarios where suppressions may be
  necessary:

  - Integration with external code you can't modify (third-party libraries, generated
    code)
  - Known false positives in the quality tools
  - Temporary emergency fixes that will be properly addressed in a timely manner
  - Cases where the automated rule conflicts with a higher-priority requirement

  Even in these exception cases, the documentation requirement still applies—exceptions
  must be explained, not merely asserted.

## Practical Implementation

**Write Informative Comments:**
```typescript
// ❌ BAD: No explanation
// eslint-disable-next-line no-console
console.log('User logged in');

// ✅ GOOD: Clear explanation
// eslint-disable-next-line no-console
// Production login events need console.log for monitoring tools per ARCH-2023-05
console.log('User logged in', { userId, timestamp });
```

**Make Suppressions Temporary:**
```java
// ❌ BAD: Permanent with vague reasoning
@SuppressWarnings("unchecked")
// We know this is safe
List<User> users = (List<User>) result;

// ✅ GOOD: Temporary with timeline
@SuppressWarnings("unchecked")
// Temporary cast until UserRepository uses generics (JIRA-1234, Q2)
List<User> users = (List<User>) result;
```

**Enforce with Tooling:**
```yaml
# ESLint rule configuration
rules:
  "eslint-comments/require-description": ["error"]
```

**Create Team Standards:** Document common suppression patterns
**Regular Audits:** Periodically review and clean up suppressions

## Examples

**Type Assertions:**
```typescript
// ❌ BAD: Unexplained assertion
const endpoint = config.endpoint as string;

// ✅ GOOD: Validation instead
if (!config.endpoint) throw new Error('API endpoint required');
fetch(config.endpoint);
```

**Function Complexity:**
```python
# ❌ BAD: Unexplained suppression
# pylint: disable=too-many-arguments
def process_data(arg1, arg2, arg3, arg4, arg5, arg6, arg7):
    pass

# ✅ GOOD: Refactor to class
class DataProcessor:
    def __init__(self, config): self.config = config
    def process(self): return self._format_results()

# If refactoring not possible:
# pylint: disable=too-many-arguments
# Legacy import process requires many parameters (JIRA-5678, Q3 refactor)
def process_data_legacy(arg1, arg2, arg3, arg4, arg5, arg6, arg7):
    pass
```

**Error Handling:**
```go
// ❌ BAD: Silent error ignore
data, _ := ioutil.ReadFile("config.json")

// ✅ GOOD: Proper error handling
data, err := ioutil.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("reading config: %w", err)
}

// If ignoring is justified:
// #nosec G304 - Only checking existence, path injection not sensitive
_, err := os.Stat(path)
return err == nil
```

## Related Bindings

- [require-conventional-commits](../../docs/bindings/core/require-conventional-commits.md): Documents changes at repository level
- [use-structured-logging](../../docs/bindings/core/use-structured-logging.md): Tracks runtime information carefully
- [external-configuration](../../docs/bindings/core/external-configuration.md): Handles necessary deviations transparently
