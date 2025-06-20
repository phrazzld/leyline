# Migration Guide: Simplified CI Approach

*A guide for existing contributors adapting to our streamlined validation approach*

## Overview: What's Changed and Why

Leyline has evolved from applying **production software engineering standards** to embracing **knowledge management best practices**. This migration guide helps existing contributors understand the shift and adapt their workflows accordingly.

### The Fundamental Shift

**Before:** Documentation repository treated like production software
- Comprehensive validation blocking all development
- 60+ second CI feedback loops
- Technical compliance prioritized over content quality
- New contributions blocked by pre-existing technical debt

**After:** Documentation repository optimized for knowledge sharing
- Essential validation enabling fast feedback (<10 seconds)
- Content velocity prioritized over technical perfection
- Advisory validation available when desired
- Focus on knowledge transfer effectiveness

## What's Changed

### CI Pipeline Transformation

**Previously Required (Now Advisory):**
- ❌ Cross-reference link validation (blocking) → ✅ Advisory feedback only
- ❌ TypeScript binding compilation (blocking) → ✅ Advisory feedback only
- ❌ Security scanning (blocking) → ✅ Advisory feedback only
- ❌ Dependency auditing (blocking) → ✅ Advisory feedback only
- ❌ Document length validation (pre-commit blocking) → ✅ Advisory guidance only

**Still Required (Essential Validation):**
- ✅ YAML front-matter validation (enables automation)
- ✅ Index consistency validation (prevents navigation breakage)
- ✅ Basic file quality (trailing whitespace, end-of-file fixes)

### Workflow Changes

**Old Workflow:**
```bash
# Complex, slow validation (60+ seconds)
ruby tools/run_ci_checks.rb --full
# Fix ALL issues including advisory ones before proceeding
# Blocked by pre-existing issues unrelated to your changes
```

**New Workflow:**
```bash
# Fast essential validation (<10 seconds)
ruby tools/run_ci_checks.rb --essential

# Optional: Comprehensive feedback when you want it
ruby tools/run_advisory_checks.rb
```

## Understanding the Rationale

### Why This Change Was Necessary

**Problem with Previous Approach:**
1. **Blocking valuable contributions:** New documentation blocked by old, unrelated issues
2. **Mismatched standards:** Production software standards applied to educational content
3. **Development friction:** Long feedback loops discouraging frequent validation
4. **Focus misalignment:** Time spent on technical compliance instead of knowledge transfer

**Solution: Repository-Appropriate Standards:**
1. **Essential validation:** Maintain automation and basic quality
2. **Advisory validation:** Provide comprehensive feedback when desired
3. **Fast feedback:** Enable frequent validation and iteration
4. **Content focus:** Prioritize knowledge sharing effectiveness

### This Is Not "Lowering Standards"

**Common concern:** "Are we accepting lower quality documentation?"

**Reality:** We're applying **appropriate standards** for a **knowledge management repository**:

- **Educational examples** should prioritize clarity over compilation perfection
- **Cross-reference links** should be fixed when convenient, not block all development
- **Security scanning** in educational content creates false positives by design
- **Content velocity** enables more comprehensive knowledge sharing

**Different repositories have different quality requirements:**
- **Production software:** Comprehensive validation prevents bugs in user-facing systems
- **Documentation repository:** Essential validation enables knowledge work

## Migration Steps for Contributors

### 1. Update Your Mental Model

**Old mindset:** "All validation failures must be fixed before proceeding"
**New mindset:** "Essential validation enables automation; advisory validation provides helpful feedback"

### 2. Adapt Your Daily Workflow

**Replace this:**
```bash
# Old comprehensive approach (slow)
ruby tools/run_ci_checks.rb --full
# Wait 60+ seconds, fix all issues including advisory
```

**With this:**
```bash
# New essential approach (fast)
ruby tools/run_ci_checks.rb --essential
# Continue in <10 seconds with essential quality assured
```

### 3. Use Advisory Validation Selectively

**When to use advisory validation:**
- Preparing high-visibility content
- Want comprehensive feedback on your work
- Have time for optional improvements
- Troubleshooting specific issues

**Command:**
```bash
# Get comprehensive advisory feedback (never blocking)
ruby tools/run_advisory_checks.rb
```

### 4. Update Pre-commit Expectations

**Pre-commit hooks now focus on:**
- File quality (whitespace, end-of-file)
- YAML syntax and front-matter validation
- Index consistency
- **Execution time: <5 seconds**

**Pre-commit hooks no longer include:**
- Document length validation (moved to advisory)
- Cross-reference validation (advisory only)
- TypeScript compilation (advisory only)

## Addressing Common Concerns

### "Will documentation quality suffer?"

**No - quality comes from different sources:**

**Technical quality** (automation/basic structure):
- Still ensured by essential validation
- YAML front-matter enables automation
- Index consistency prevents navigation issues

**Content quality** (knowledge transfer effectiveness):
- Improved by removing barriers to contribution
- Fast feedback enables more iteration and refinement
- Authors can focus on knowledge sharing vs. technical compliance

### "What about broken links and examples?"

**Links:**
- Cross-reference validation is advisory - run when convenient
- External link validation available in advisory mode
- Broken links don't prevent knowledge transfer

**Examples:**
- Educational examples prioritize clarity over compilation
- TypeScript validation available as advisory feedback
- Security scanning provides feedback on educational patterns

### "How do I maintain high standards?"

**Use the tools that match your goals:**

**For daily authoring:**
```bash
ruby tools/run_ci_checks.rb --essential
```

**For comprehensive review:**
```bash
ruby tools/run_advisory_checks.rb
```

**For specific concerns:**
```bash
ruby tools/validate_cross_references.rb
ruby tools/validate_typescript_bindings.rb --verbose
```

### "What if I want the old comprehensive validation?"

**Available as advisory validation:**
- All removed validations available in `run_advisory_checks.rb`
- Full validation mode: `ruby tools/run_ci_checks.rb --full`
- Individual validation tools still available
- **Key difference:** Never blocks development workflow

## Best Practices for the New Approach

### Daily Development
1. **Start clean:** `ruby tools/run_ci_checks.rb --essential`
2. **Focus on content:** Prioritize knowledge transfer over technical perfection
3. **Validate frequently:** Fast feedback enables more iteration
4. **Use advisory selectively:** When you want comprehensive feedback

### Content Creation
1. **Clarity over complexity:** Educational examples should teach concepts clearly
2. **Realistic educational patterns:** Use obvious markers for "bad examples"
3. **Focus on learning outcomes:** What should readers understand?
4. **Iterate quickly:** Fast validation enables rapid improvement cycles

### Quality Assurance
1. **Essential validation:** Maintains automation and basic quality
2. **Advisory validation:** Provides comprehensive feedback when desired
3. **Content effectiveness:** Measure knowledge transfer success
4. **Contributor velocity:** Remove barriers to valuable contributions

## FAQ

**Q: Can I still run comprehensive validation?**
A: Yes! Use `ruby tools/run_advisory_checks.rb` or `ruby tools/run_ci_checks.rb --full`

**Q: Will my contributions be blocked by validation failures?**
A: Only essential validation (YAML + index) blocks CI. Advisory findings are informational.

**Q: How do I know if my TypeScript examples are correct?**
A: Use `ruby tools/validate_typescript_bindings.rb` for advisory feedback when desired.

**Q: What about security in documentation examples?**
A: Use clear markers like `[EXAMPLE]` or `[REDACTED]` for educational anti-patterns.

**Q: Should I fix advisory validation findings?**
A: When convenient and valuable, but they never block development workflow.

**Q: How do I report issues with the new approach?**
A: Use the project's issue tracking system to provide feedback and suggestions.

## Success Metrics

**Measure your adaptation success by:**

**Velocity metrics:**
- Faster contribution cycles
- More frequent validation during development
- Reduced time spent on technical compliance
- Increased focus on content quality

**Quality metrics:**
- Essential validation consistently passes
- Content clarity and educational effectiveness
- Knowledge transfer outcomes
- Reader/user feedback and engagement

**Workflow metrics:**
- Comfortable using essential vs. advisory validation
- Efficient local development workflow
- Effective use of validation tools when needed

## Support Resources

**Essential validation:**
- `ruby tools/run_ci_checks.rb --essential --help`
- `docs/CI_FAILURE_PREVENTION.md`

**Advisory validation:**
- `ruby tools/run_advisory_checks.rb --help`
- Individual tool documentation

**Content guidance:**
- `docs/AUTHORING_WORKFLOW.md`
- `CLAUDE.md`

**Philosophy and approach:**
- This migration guide
- TODO.md (for implementation context)

## Remember

The simplified CI approach exists to **enable your documentation work**, not create barriers. The shift from production software standards to knowledge management practices reflects the repository's true purpose: **sharing knowledge effectively**.

Focus on creating valuable content that helps others learn and understand. Let essential validation handle the automation requirements, and use advisory validation when you want comprehensive feedback.

**The goal:** More knowledge sharing, less technical friction.
