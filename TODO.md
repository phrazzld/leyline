# Todo

## Core Modules: YAMLLineTracker
- [x] **T001 · Feature · P0: create YAMLLineTracker class with Psych parsing**
    - **Context:** PLAN.md > Detailed Build Steps > 1. Extract YAMLLineTracker Class
    - **Action:**
        1. Create `lib/yaml_line_tracker.rb` with the `YAMLLineTracker` class.
        2. Implement a `self.parse` method that uses `Psych.parse` and rescues `Psych::SyntaxError`, storing any syntax errors in a returned `:errors` array.
    - **Done‑when:**
        1. The class correctly parses valid YAML.
        2. The class captures `Psych::SyntaxError` with line/column info and returns it in the `errors` array.
    - **Depends‑on:** none

- [x] **T002 · Feature · P0: implement key-to-line-number mapping in YAMLLineTracker**
    - **Context:** PLAN.md > Detailed Build Steps > 1. Extract YAMLLineTracker Class > Implementation
    - **Action:**
        1. Enhance `YAMLLineTracker.parse` to scan the raw YAML text.
        2. Build and return a `line_map` hash mapping each top-level key to its corresponding line number.
    - **Done‑when:**
        1. The `:line_map` hash is accurately populated for valid YAML input.
    - **Depends‑on:** [T001]

- [x] **T003 · Test · P1: add unit tests for YAMLLineTracker**
    - **Context:** PLAN.md > Testing Strategy > Unit Tests
    - **Action:**
        1. Write tests to verify correct key-to-line number mapping.
        2. Write tests to confirm `Psych::SyntaxError` is handled gracefully.
        3. Write tests for edge cases like unquoted dates and empty front-matter.
    - **Done‑when:**
        1. Unit tests for `YAMLLineTracker` achieve >=95% coverage.
    - **Depends‑on:** [T002]

## Core Modules: ErrorCollector
- [x] **T004 · Feature · P0: create ErrorCollector for structured error aggregation**
    - **Context:** PLAN.md > Detailed Build Steps > 2. Create ErrorCollector Class
    - **Action:**
        1. Create `lib/error_collector.rb` with the `ErrorCollector` class.
        2. Implement an `add_error` method that accepts keyword arguments (`file:`, `line:`, `field:`, `type:`, `message:`, `suggestion:`).
        3. Implement an internal array to store structured error objects.
    - **Done‑when:**
        1. The `add_error` method correctly stores structured error data.
        2. A method exists to retrieve all collected errors.
    - **Depends‑on:** none

- [x] **T005 · Test · P1: add unit tests for ErrorCollector**
    - **Context:** PLAN.md > Testing Strategy > Unit Tests
    - **Action:**
        1. Write tests to verify that multiple errors are added and stored correctly.
        2. Assert that all contextual data is preserved for each error.
    - **Done‑when:**
        1. Unit tests for `ErrorCollector` achieve >=95% coverage.
    - **Depends‑on:** [T004]

## Core Modules: ErrorFormatter
- [x] **T006 · Feature · P1: build ErrorFormatter with colorization and TTY support**
    - **Context:** PLAN.md > Detailed Build Steps > 3. Build ErrorFormatter Class
    - **Action:**
        1. Create `lib/error_formatter.rb` with the `ErrorFormatter` class and a `render` method.
        2. Implement TTY detection (`STDOUT.tty?`) and `ENV['NO_COLOR']` support to toggle ANSI color codes.
        3. Group rendered errors by filename.
    - **Done‑when:**
        1. The `render` method produces colorized output in a TTY and plain text otherwise.
        2. Output is correctly grouped by file.
    - **Verification:**
        1. Run script in a terminal; confirm colors appear.
        2. Run script with `NO_COLOR=1` or pipe output (`| cat`); confirm output is plain text.
    - **Depends‑on:** [T005]

- [x] **T007 · Feature · P2: add context snippets to ErrorFormatter output**
    - **Context:** PLAN.md > Detailed Build Steps > 3. Build ErrorFormatter Class > Features
    - **Action:**
        1. Modify the `ErrorFormatter.render` method to accept the original file content.
        2. For errors with a line number, extract and display the problematic line with 1-2 lines of surrounding context.
    - **Done‑when:**
        1. Error messages with line numbers are accompanied by a relevant code snippet.
    - **Verification:**
        1. Trigger an error on a specific line in a test file.
        2. Confirm the formatted output includes the correct lines from the source file.
    - **Depends‑on:** [T006]

- [x] **T008 · Test · P2: add unit tests for ErrorFormatter**
    - **Context:** PLAN.md > Testing Strategy > Unit Tests
    - **Action:**
        1. Test colorization logic for TTY and `NO_COLOR` scenarios.
        2. Test file grouping logic.
        3. Test context snippet generation for various line positions (start, middle, end of file).
    - **Done‑when:**
        1. Unit tests for `ErrorFormatter` achieve >=95% coverage.
    - **Depends‑on:** [T007]

## Main Script & Validation Logic
- [x] **T009 · Refactor · P1: integrate new components into the main validation script**
    - **Context:** PLAN.md > Implementation Priorities > Phase 1
    - **Action:**
        1. Modify the main script to use `YAMLLineTracker.parse` for front-matter extraction.
        2. Instantiate `ErrorCollector` and replace all direct error reporting (`puts`, `raise`) with calls to `ErrorCollector#add_error`.
    - **Done‑when:**
        1. The script correctly uses the new parsing and error collection modules.
        2. The script's public CLI interface and basic exit codes (0/1) remain unchanged.
    - **Depends‑on:** [T002, T004]

- [x] **T010 · Feature · P1: enhance field validators with specific suggestions**
    - **Context:** PLAN.md > Detailed Build Steps > 4. Enhanced Field Validation
    - **Action:**
        1. Update validators to generate precise, actionable `suggestion` strings for common errors (e.g., unquoted dates, invalid formats, missing fields, unknown fields).
        2. Pass the line number from `YAMLLineTracker` to the validators to be included in the error context.
    - **Done‑when:**
        1. All core validation checks produce a helpful `suggestion` string and include the correct line number.
    - **Depends‑on:** [T009]

- [x] **T011 · Feature · P2: integrate ErrorFormatter for final output**
    - **Context:** PLAN.md > Architecture Blueprint > Data Flow
    - **Action:**
        1. At the end of the script's execution, check if the `ErrorCollector` has errors.
        2. If so, instantiate `ErrorFormatter`, call `render`, and print the formatted output to `STDERR`.
    - **Done‑when:**
        1. Running the script against an invalid file produces the new, richly formatted error output.
    - **Depends‑on:** [T008, T010]

- [x] **T012 · Chore · P2: preserve exit code strategy for CI compatibility**
    - **Context:** PLAN.md > Detailed Build Steps > 5. Maintain Script Structure
    - **Action:**
        1. Ensure the script strictly exits with `0` for success and `1` for any validation error by default.
        2. Implement (but do not enable by default) the optional granular exit codes (`2` for syntax, `3` for field errors) behind a feature flag for future use.
    - **Done‑when:**
        1. The default exit code behavior is confirmed by integration tests.
    - **Depends‑on:** [T011]

## Security
- [x] **T013 · Security · P2: implement file path sanitization**
    - **Context:** PLAN.md > Security & Configuration > Input Validation
    - **Action:**
        1. Add a check at script startup to validate any input file paths.
        2. Ensure the path exists, is a file, and does not contain directory traversal sequences.
    - **Done‑when:**
        1. The script exits with a clear error if a malicious or invalid path is provided.
    - **Depends‑on:** none

- [x] **T014 · Security · P1: confirm safe YAML parsing is used exclusively**
    - **Context:** PLAN.md > Security & Configuration > YAML Safety
    - **Action:**
        1. Confirm that `YAMLLineTracker` uses `Psych.parse` or `YAML.safe_load` and not the unsafe `YAML.load`.
        2. Add a unit test with a malicious YAML payload to ensure it does not execute code.
    - **Done‑when:**
        1. All YAML parsing is confirmed safe.
    - **Depends‑on:** [T002]

- [x] **T015 · Security · P2: implement secret detection and redaction in error output**
    - **Context:** PLAN.md > Security & Configuration > Secrets Handling
    - **Action:**
        1. Add a validation check to identify common secret key names (e.g., `api_key`, `token`, `password`).
        2. When a potential secret is found, ensure its value is NEVER displayed in any error message or log.
    - **Done‑when:**
        1. The validator flags potential secrets without exposing their values.
    - **Depends‑on:** [T010]

## Testing & Quality Assurance
- [x] **T016 · Chore · P1: create fixture files for all error scenarios**
    - **Context:** PLAN.md > Testing Strategy > Integration Tests
    - **Action:**
        1. Create a `spec/fixtures` directory.
        2. Add separate markdown files that each demonstrate one specific error: YAML syntax error, missing field, invalid format, unknown field, and a potential secret.
        3. Include one fully valid fixture file.
    - **Done‑when:**
        1. A comprehensive set of fixture files exists to cover all defined error conditions.
    - **Depends‑on:** none

- [x] **T017 · Test · P2: write end-to-end integration tests using fixtures**
    - **Context:** PLAN.md > Testing Strategy > Integration Tests
    - **Action:**
        1. Create an integration test suite that runs the main script as a subprocess against each fixture file.
        2. Assert the correct exit code is returned (`1` for invalid, `0` for valid).
        3. Assert that the `STDERR` output for invalid files contains the expected formatted error message.
    - **Done‑when:**
        1. The integration suite provides E2E coverage for all defined error scenarios.
    - **Depends‑on:** [T011, T012, T016]

- [x] **T018 · Test · P2: validate non-TTY output for CI compatibility**
    - **Context:** PLAN.md > Risk Matrix & Mitigations > Color output in CI
    - **Action:**
        1. Add an integration test that runs the script and pipes its output to simulate a non-TTY environment.
        2. Assert that the output in this mode contains no ANSI color codes.
    - **Done‑when:**
        1. CI-specific output behavior is verified by an automated test.
    - **Depends‑on:** [T017]

- [x] **T019 · Chore · P3: profile performance against baseline**
    - **Context:** PLAN.md > Risk Matrix & Mitigations > Performance regression
    - **Action:**
        1. Create a benchmark script to run the validator against a large set of files.
        2. Measure the execution time of the new implementation and document the results.
        3. Optimize if any significant performance degradation is found.
    - **Done‑when:**
        1. Performance is measured and confirmed to be acceptable.
    - **Depends‑on:** [T017]
