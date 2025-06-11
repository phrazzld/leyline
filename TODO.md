# TODO - Critical Security and Stability Fixes

## Merge-Blocking Issues

- [x] **CRITICAL-001 · Security · P0: fix secret redaction regex vulnerability**
    - **Context:** Code Review Synthesis > BLOCK-001 - Secret Redaction Security Vulnerability
    - **Location:** `tools/validate_front_matter.rb:525-535`
    - **Issue:** Current regex `/\b#{Regexp.escape(value)}\b/` fails to redact secrets not on word boundaries
    - **Examples:** `"api_key":"sk-1234"`, `my_token=abc123`, multi-line secrets
    - **Action:**
        1. Replace word boundary regex with simple string replacement: `gsub(Regexp.escape(value), '[REDACTED]')`
        2. Add test cases for edge cases: colons, equals, quotes, multi-line values
        3. Verify no secrets leak in any error message format
    - **Done-when:**
        1. All secret values are redacted regardless of surrounding characters
        2. Test cases pass for all boundary scenarios
        3. Security audit confirms no secret exposure
    - **Verification:**
        1. Create test files with secrets in various formats
        2. Run validation and confirm all secrets show `[REDACTED]`
        3. Check both TTY and non-TTY output modes
    - **Depends-on:** none

- [~] **CRITICAL-002 · Bugfix · P0: fix script crash on invalid path detection**
    - **Context:** Code Review Synthesis > BLOCK-002 - Script Crash on Invalid Path Detection
    - **Location:** `tools/validate_front_matter.rb:356-363`
    - **Issue:** Script continues execution after detecting invalid path, causing nil `dir_base` crash
    - **Action:**
        1. Add explicit `exit 1` immediately after invalid path error message
        2. Ensure proper error message is displayed before exit
        3. Test single file validation with invalid paths
    - **Done-when:**
        1. Script exits cleanly with error code 1 on invalid paths
        2. No nil reference crashes occur
        3. Error message clearly indicates path issue
    - **Verification:**
        1. Test with files outside `/tenets/` and `/bindings/` paths
        2. Confirm script exits with code 1 and clear error message
        3. Verify no subsequent processing attempts
    - **Depends-on:** none

- [ ] **CRITICAL-003 · Bugfix · P0: standardize exit code handling throughout script**
    - **Context:** Code Review Synthesis > BLOCK-003 - Inconsistent Exit Code Handling
    - **Location:** Multiple exit points throughout script
    - **Issue:** Inconsistent exit code strategy could break CI/CD pipelines
    - **Action:**
        1. Audit all exit points in the script
        2. Ensure consistent exit code 0 for success, 1 for any error
        3. Remove any inconsistent or ambiguous exit codes
        4. Document exit code strategy
    - **Done-when:**
        1. All exit points use consistent codes (0=success, 1=error)
        2. CI/CD compatibility confirmed through testing
        3. Exit code behavior is predictable and documented
    - **Verification:**
        1. Test all error scenarios and confirm exit code 1
        2. Test successful validation and confirm exit code 0
        3. Run in CI simulation to verify compatibility
    - **Depends-on:** none
