# Test Fixtures

This directory contains test fixture files for validating the YAML front-matter validation tools.

## Directory Structure

- `tenets/` - Tenet fixture files
- `bindings/` - Binding fixture files

## Valid Files

- `tenets/valid-tenet.md` - A properly formatted tenet file with all required fields
- `bindings/valid-binding.md` - A properly formatted binding file with all required fields

## Error Scenarios

### YAML Parsing Errors
- `bindings/yaml-syntax-error.md` - Contains malformed YAML with unclosed quotes
- `bindings/no-front-matter.md` - File without any YAML front-matter

### Field Validation Errors
- `bindings/missing-required-fields.md` - Missing required fields (derived_from, enforced_by, version)
- `bindings/invalid-field-formats.md` - Invalid formats for various fields (ID, date, version)
- `bindings/unknown-fields.md` - Contains fields not in the schema (deprecated fields, custom fields)

### Reference Validation Errors
- `bindings/nonexistent-tenet-reference.md` - References a tenet that doesn't exist

### Security Validation
- `bindings/potential-secrets.md` - Contains field names that might indicate secrets

## Usage

These fixtures are used by integration tests to verify that the validation tools correctly:
1. Accept valid files without errors
2. Detect and report specific error types with helpful messages
3. Provide appropriate suggestions for fixing issues

Each file tests specific validation scenarios and can be used with the `validate_front_matter.rb` script:

```bash
# Test a specific fixture
ruby tools/validate_front_matter.rb -f spec/fixtures/bindings/yaml-syntax-error.md

# Test all binding fixtures
for file in spec/fixtures/bindings/*.md; do
  echo "Testing $file"
  ruby tools/validate_front_matter.rb -f "$file"
done

# Test all tenet fixtures
for file in spec/fixtures/tenets/*.md; do
  echo "Testing $file"
  ruby tools/validate_front_matter.rb -f "$file"
done
```
