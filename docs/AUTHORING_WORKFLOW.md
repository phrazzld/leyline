# Documentation Authoring Workflow

*Streamlined guidance for creating effective knowledge-sharing content*

## Philosophy: Content Over Compliance

This guide reflects Leyline's shift from production software engineering standards to knowledge management best practices. Our simplified CI system enables you to focus on **knowledge transfer** rather than **technical perfection**.

### Core Principles

- **Clarity beats compilation** - Educational examples should teach concepts clearly, not be production-ready
- **Fast feedback loops** - Essential validation completes in seconds, not minutes
- **Educational authenticity** - "Bad examples" that demonstrate anti-patterns are valuable and expected
- **Content-first workflow** - Technical validation supports content creation, never blocks it

---

## Validation Modes

### Essential Mode (Daily Development)
*Fast feedback for content creation*

**When to use:** Regular content development, quick iteration, daily authoring work

**What it validates:**
- YAML front-matter syntax and required fields
- Index consistency (generated navigation)
- Basic markdown structure

**Execution time:** ~10 seconds

**Command:**
```bash
ruby tools/run_ci_checks.rb --essential
```

**CI behavior:** This is what runs automatically in pull requests and CI

### Full Mode (Comprehensive Review)
*Optional comprehensive validation*

**When to use:**
- Before major releases
- When you want comprehensive feedback
- For content that will be widely referenced
- When troubleshooting edge cases

**What it validates:**
- Everything in essential mode
- Cross-reference link validation (advisory)
- TypeScript binding compilation (advisory)
- Security scanning (advisory)
- Dependency auditing (advisory)
- External link checking (advisory)

**Execution time:** 1-3 minutes

**Command:**
```bash
ruby tools/run_ci_checks.rb --full
```

**Important:** Full mode failures are **advisory only** - they provide feedback but won't block your work

### Advisory Mode (Comprehensive Author Feedback)
*Optional comprehensive validation for interested authors*

**When to use:**
- When you want comprehensive feedback on all aspects of your content
- For high-visibility content that will be widely referenced
- When troubleshooting specific issues with examples or links
- When you want to understand all potential improvements

**What it validates:**
- Cross-reference link validation
- Document length validation
- TypeScript binding compilation
- Security scanning
- Dependency auditing
- External link checking
- Python code example validation

**Execution time:** 1-5 minutes (depending on system and example projects)

**Command:**
```bash
ruby tools/run_advisory_checks.rb
```

**Philosophy:** Completely optional tool that provides comprehensive feedback for authors who want it. All findings are informational only and never block development.

---

## Content Creation Workflow

### 1. Start with Essential Validation

Begin every authoring session by running essential validation to ensure your starting point is clean:

```bash
ruby tools/run_ci_checks.rb --essential
```

### 2. Focus on Content Quality

Write content that prioritizes:
- **Clear explanations** over technical accuracy
- **Practical examples** over abstract concepts
- **Learning outcomes** over comprehensive coverage
- **Readable code** over production patterns

### 3. Handle YAML Front-matter

Every tenet and binding file must include valid YAML front-matter. Essential validation will catch syntax errors immediately.

**Required fields:**
```yaml
---
id: descriptive-file-name
version: 0.1.0
summary: One-line description of the content
tenet: reference-to-related-tenet
---
```

**Validation:** YAML errors fail essential validation (blocking)

### 4. Maintain Index Consistency

The documentation system auto-generates index files. If you add new content, regenerate indexes:

```bash
ruby tools/reindex.rb
```

**Validation:** Index inconsistencies fail essential validation (blocking)

---

## Writing Effective Examples

### Prioritize Educational Value

**Good example characteristics:**
- Demonstrates the concept clearly
- Uses familiar, relatable scenarios
- Shows common real-world patterns
- Includes context about when/why to use

**Avoid:**
- Production-grade complexity
- Obscure edge cases as primary examples
- Over-engineered demonstrations
- Examples that require extensive setup

### Code Examples: Clear Over Compilable

Educational code should teach concepts, not pass strict compilation:

```typescript
// ✅ Good: Clear educational example
function calculateTax(price: number): number {
  const taxRate = 0.08; // Clear, understandable
  return price * taxRate;
}

// ❌ Avoid: Over-engineered for education
interface TaxCalculationConfig {
  rate: number;
  jurisdiction: string;
  exemptions: string[];
}

class TaxCalculator {
  constructor(private config: TaxCalculationConfig) {}
  // ... complex implementation
}
```

### "Bad Examples" - Anti-Pattern Demonstrations

Educational content often needs to show what **not** to do. These examples are valuable and expected:

**Pattern: Use clear markers for anti-patterns**

```typescript
// ❌ DON'T DO THIS: Hardcoded secrets
const apiKey = "sk-1234567890abcdef"; // [EXAMPLE] Not a real key

// ✅ DO THIS: Environment variables
const apiKey = process.env.API_KEY;
```

**Avoiding false positives:**
- Use `[EXAMPLE]` or `[DEMO]` markers in educational secrets
- Choose obviously fake values (`example.com`, `user@example.org`)
- Include anti-pattern warnings in comments

---

## Managing Advisory Validation

Full validation mode includes advisory checks that may flag educational content. These are **informational only** and won't block your work.

### Cross-Reference Links (Advisory)

Broken internal links are flagged but not blocking. Common situations:

- **Work-in-progress content** - Links to planned but not-yet-created content
- **Reorganization periods** - Links temporarily broken during restructuring
- **Example references** - Links to hypothetical future content

**Action:** Fix when convenient, don't let it block content creation

### TypeScript Compilation (Advisory)

Educational TypeScript examples may not compile perfectly:

- **Simplified imports** - Examples might omit complex import statements for clarity
- **Partial implementations** - Focus on the concept being taught
- **Type shortcuts** - May use `any` temporarily for educational clarity

**Action:** Compilation feedback is helpful but not required for educational content

### Security Scanning (Advisory)

Educational examples that demonstrate security anti-patterns will trigger security scanners:

- **Password examples** - Use obvious placeholders like `[PASSWORD]` or `example123`
- **API keys** - Mark clearly with `[EXAMPLE]` or `[DEMO]`
- **Vulnerable patterns** - Include clear warnings and explanations

**Action:** Ensure examples are obviously educational, not accidentally realistic

---

## Pre-commit Workflow

For optimal experience, run essential validation frequently:

```bash
# Quick validation during development
ruby tools/run_ci_checks.rb --essential

# Before committing changes
git add .
ruby tools/run_ci_checks.rb --essential
git commit -m "docs: add example patterns for authentication"
```

**Optional:** Set up a pre-push hook for automatic validation:

```bash
# Add to .git/hooks/pre-push
#!/bin/bash
echo "🔄 Running essential validation..."
ruby tools/run_ci_checks.rb --essential
```

---

## Troubleshooting Common Issues

### YAML Front-matter Errors

**Symptom:** Essential validation fails with YAML parsing errors

**Solutions:**
- Check indentation (use spaces, not tabs)
- Ensure quotes around strings with special characters
- Validate required fields are present
- Run: `ruby tools/validate_front_matter.rb -f path/to/file.md`

### Index Out of Sync

**Symptom:** Essential validation fails with "Index file is out of date"

**Solution:**
```bash
ruby tools/reindex.rb
git add docs/bindings/00-index.md docs/tenets/00-index.md
```

### Advisory Validation Noise

**Symptom:** Full validation reports many "failures"

**Understanding:** Advisory validation provides feedback but doesn't block work. These "failures" are informational warnings, not blocking errors.

**Action:** Review feedback for improvements, but don't let it stop content creation

---

## Success Metrics

**Primary goals:**
- Content creation velocity increases
- Author frustration with CI decreases
- Educational quality remains high
- Knowledge transfer effectiveness improves

**Quality indicators:**
- Essential validation passes consistently
- Content focuses on learning outcomes
- Examples prioritize clarity over complexity
- Authors spend time on content, not tool compliance

---

## Getting Help

**For YAML or index issues:**
```bash
ruby tools/validate_front_matter.rb --help
ruby tools/reindex.rb --help
```

**For validation mode questions:**
```bash
ruby tools/run_ci_checks.rb --help
```

**For content guidance:**
- Review existing tenet and binding files in `docs/`
- Focus on knowledge transfer over technical perfection
- When in doubt, prioritize clarity and educational value

Remember: The simplified CI system exists to **enable** your documentation work, not hinder it. Focus on creating valuable knowledge-sharing content, and let the essential validation handle the technical details.
