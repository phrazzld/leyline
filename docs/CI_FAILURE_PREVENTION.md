# CI Failure Prevention Guide

*Streamlined approach to preventing CI failures through fast, essential validation*

## Philosophy: Enable Documentation Work

CI should **enable** documentation work, not hinder it. This guide focuses on essential quality gates that serve the repository's knowledge management purpose while avoiding overengineered validation that creates friction without proportional value.

Our simplified CI approach prioritizes:
- **Fast feedback loops** (<10 seconds for essential validation)
- **Essential quality gates** that enable automation and basic quality
- **Developer flow** over comprehensive checking
- **Content creation velocity** over technical perfection

## Quick Start

**Essential Command (Daily Development):**
```bash
# Fast validation for daily work - essential quality gates only
ruby tools/run_ci_checks.rb --essential
```

**Optional Comprehensive Feedback:**
```bash
# Optional advisory validation for interested authors
ruby tools/run_advisory_checks.rb
```

## Essential Validation (CI-Blocking)

Our simplified CI validates only what's essential for repository automation and basic quality:

### 1. YAML Front-matter Validation

**Why Essential:** Enables automation, indexing, and content management
**Execution Time:** ~0.2 seconds

**Prevention:**
```bash
# Validate all YAML front-matter
ruby tools/validate_front_matter.rb

# Validate specific file during editing
ruby tools/validate_front_matter.rb -f docs/bindings/categories/typescript/your-binding.md
```

**Quick Fix Checklist:**
- [ ] Required fields present: `id`, `version`, `derived_from`
- [ ] Proper YAML syntax (indentation, no tabs)
- [ ] Valid values for each field
- [ ] No trailing spaces or special characters

### 2. Index Consistency Validation

**Why Essential:** Prevents navigation breakage in generated documentation
**Execution Time:** ~0.1 seconds

**Prevention:**
```bash
# Check and regenerate indexes
ruby tools/reindex.rb --strict

# Auto-fix indexes
ruby tools/reindex.rb
```

**Quick Fix:**
- Run `ruby tools/reindex.rb` if CI reports index inconsistency
- Commit updated index files with your changes

## Advisory Validation (Optional)

These checks provide helpful feedback but **never block development:**

### Cross-reference Links (Advisory)
- **Purpose:** Identify broken internal links
- **Tool:** `ruby tools/validate_cross_references.rb`
- **Status:** Informational only - fix when convenient

### TypeScript Examples (Advisory)
- **Purpose:** Compilation feedback on educational examples
- **Tool:** `ruby tools/validate_typescript_bindings.rb`
- **Status:** Educational clarity prioritized over compilation perfection

### Security Scanning (Advisory)
- **Purpose:** Identify potential secrets in educational content
- **Tool:** `gitleaks detect --source=. --no-git`
- **Status:** False positives expected in educational examples

### Document Length (Advisory)
- **Purpose:** Encourage concise, focused content
- **Tool:** `ruby tools/check_document_length.rb`
- **Status:** Guidelines, not requirements

## Development Workflow

### Daily Authoring Workflow

```bash
# 1. Start with clean validation
ruby tools/run_ci_checks.rb --essential

# 2. Create/edit content focusing on knowledge transfer

# 3. Quick validation during development (as needed)
ruby tools/run_ci_checks.rb --essential

# 4. Before committing
ruby tools/run_ci_checks.rb --essential && git commit -m "docs: your change"
```

### When to Use Advisory Validation

**Use advisory validation when:**
- Preparing high-visibility content
- Wanting comprehensive feedback on your work
- Troubleshooting specific issues
- You have time and interest in comprehensive review

**Command:**
```bash
# Get comprehensive advisory feedback (all findings are informational)
ruby tools/run_advisory_checks.rb
```

## Troubleshooting Essential Validation

### YAML Front-matter Failures

**Symptoms:** CI fails with "Invalid YAML front-matter" errors

**Common Issues:**
```yaml
# ❌ BAD: Using tabs for indentation
	version: 0.1.0

# ✅ GOOD: Using spaces
  version: 0.1.0

# ❌ BAD: Missing required fields
---
summary: Just a summary
---

# ✅ GOOD: All required fields
---
id: example-binding
version: 0.1.0
derived_from: ../../../tenets/simplicity.md
summary: Example binding for demonstration
---
```

**Quick Fix:**
1. Check indentation (spaces only, no tabs)
2. Verify all required fields are present
3. Test locally: `ruby tools/validate_front_matter.rb -f your-file.md`

### Index Consistency Failures

**Symptoms:** CI fails with "Index file is out of date"

**Cause:** Documentation indexes need regeneration after content changes

**Quick Fix:**
```bash
# Regenerate indexes
ruby tools/reindex.rb

# Add updated indexes to your commit
git add docs/tenets/00-index.md docs/bindings/00-index.md
git commit --amend --no-edit
```

## Pre-commit Integration

Our simplified pre-commit hooks focus on essential checks only:

**What runs automatically:**
- Trailing whitespace cleanup
- End-of-file fixes
- YAML syntax validation
- YAML front-matter validation
- Index consistency validation

**Execution time:** <5 seconds

**Optional pre-push hook:**
```bash
#!/bin/bash
# .git/hooks/pre-push
echo "🔄 Running essential validation..."
ruby tools/run_ci_checks.rb --essential
if [ $? -ne 0 ]; then
    echo "❌ Essential validation failed. Fix issues before pushing."
    exit 1
fi
echo "✅ Essential validation passed."
```

## Advisory Validation Guidance

If you choose to use advisory validation, understand these tools are informational only:

### Security Scanning Patterns

For educational "bad examples" that demonstrate security anti-patterns:

```typescript
// ✅ GOOD: Clear markers prevent false positives
const config = {
  apiKey: 'sk_live_[EXAMPLE]',        // Clear example marker
  token: '[YOUR_API_TOKEN_HERE]',     // Template-style placeholder
  secret: 'whsec_[REDACTED]'          // Obvious redaction
};

// ✅ GOOD: Educational anti-pattern with warning
// ❌ DON'T DO THIS: Hardcoded secrets
const badConfig = {
  apiKey: 'sk-example-not-real-key',  // Obviously fake
  token: '[DEMO-TOKEN-ONLY]'          // Clear demo marker
};
```

### TypeScript Example Guidance

Educational TypeScript should prioritize clarity:

```typescript
// ✅ GOOD: Clear educational example
function calculateTax(price: number): number {
  return price * 0.08; // Simple, clear, educational
}

// ❌ AVOID: Over-engineered for education
interface TaxCalculationStrategy {
  calculate(amount: Money, jurisdiction: TaxJurisdiction): TaxResult;
}
// ... complex implementation that obscures the concept
```

## Migration from Comprehensive Validation

**If you're used to comprehensive validation:**

1. **Start with essential mode:** Focus on YAML and index consistency only
2. **Use advisory validation optionally:** When you want comprehensive feedback
3. **Focus on content velocity:** Prioritize knowledge transfer over technical perfection
4. **Remember the philosophy:** CI should enable, not hinder documentation work

**Key mindset shifts:**
- Essential validation keeps automation working
- Advisory validation provides optional feedback
- Content quality comes from clear knowledge transfer, not technical compliance
- Fast feedback enables frequent validation and quality improvement

## Performance and Efficiency

**Essential validation performance:**
- YAML validation: ~0.2s
- Index consistency: ~0.1s
- **Total essential validation: <0.5s**

**Advisory validation performance:**
- Cross-references: ~0.2s
- TypeScript compilation: 30-60s
- Security scanning: 5-10s
- **Total advisory validation: 1-5 minutes**

## Best Practices Summary

### Essential Practices (Required)
1. **Run `ruby tools/run_ci_checks.rb --essential` frequently**
2. **Maintain valid YAML front-matter** in all tenet/binding files
3. **Keep indexes synchronized** by running `ruby tools/reindex.rb` after content changes

### Advisory Practices (Optional)
1. **Use advisory validation** when you want comprehensive feedback
2. **Follow secure documentation patterns** with clear example markers
3. **Prioritize clarity over compilation** in educational examples
4. **Fix advisory findings when convenient** but don't let them block work

### Philosophy Practices (Mindset)
1. **Enable rather than hinder** documentation work
2. **Prioritize content velocity** over technical compliance
3. **Use validation effort proportional** to repository value and purpose
4. **Focus on knowledge transfer effectiveness**

## Support and Resources

**Essential validation tools:**
- `ruby tools/run_ci_checks.rb --essential --help`
- `ruby tools/validate_front_matter.rb --help`
- `ruby tools/reindex.rb --help`

**Advisory validation tools:**
- `ruby tools/run_advisory_checks.rb --help`
- `ruby tools/validate_cross_references.rb --help`
- `ruby tools/validate_typescript_bindings.rb --help`

**Documentation:**
- **Authoring workflow:** `docs/AUTHORING_WORKFLOW.md`
- **Main guidance:** `CLAUDE.md`

**Remember:** The simplified CI system exists to enable your documentation work, not to create barriers. Focus on creating valuable knowledge-sharing content, and let essential validation handle the technical details.
