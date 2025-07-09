# Document Length Enforcement Exemption Process

This document defines the process for requesting and managing exemptions to Leyline's document length enforcement rules. Exemptions should be rare and well-justified.

## Principles

1. **Exemptions are exceptional**: The limits exist for good reasons
2. **Reduction first**: Always attempt content reduction before requesting exemption
3. **Temporary over permanent**: Prefer time-boxed exemptions
4. **Transparency**: All exemptions must be documented and reviewed

## When Exemptions May Be Considered

### Valid Reasons

- **Security bindings**: Comprehensive security checklists that cannot be condensed without losing critical information
- **Migration guides**: Step-by-step processes requiring complete detail
- **Legal/compliance**: Documentation with regulatory requirements
- **Complex algorithms**: Mathematical or algorithmic content requiring full explanation

### Invalid Reasons

- "Too much work to reduce"
- "Everything is important"
- "Users need all details"
- "Historical reasons"

## Exemption Request Process

### Step 1: Attempt Reduction

Before requesting an exemption:

1. Follow the [Systematic Refactoring Process](./systematic-refactoring-process.md)
2. Apply the "one example rule"
3. Extract verbose sections to separate guides
4. Convert explanations to bullet points
5. Document your reduction attempts

### Step 2: Prepare Justification

Create a clear justification including:

- Current line count and target
- Why standard limits cannot work
- What reduction strategies were tried
- Impact of not granting exemption
- Proposed alternative solutions

### Step 3: Submit Request

1. Create a GitHub issue with title: `[Exemption Request] <document-path>`
2. Use the exemption request template (see below)
3. Tag with `enforcement-exemption`
4. Assign to documentation maintainers

### Step 4: Review Process

1. **Initial Review** (2-3 days):
   - Maintainer reviews justification
   - May suggest additional reduction strategies
   - Requests clarification if needed

2. **Team Discussion** (if needed):
   - Complex cases discussed in team meeting
   - Alternative approaches considered
   - Decision documented

3. **Decision**:
   - Approved: Exemption configuration added
   - Rejected: Guidance provided for meeting limits
   - Deferred: More information requested

## Exemption Request Template

```markdown
## Exemption Request: [Document Path]

### Current Status
- Document: `path/to/document.md`
- Current lines: XXX
- Limit: XXX
- Overage: XXX lines

### Justification
[Explain why this document needs an exemption]

### Reduction Attempts
- [ ] Applied systematic refactoring process
- [ ] Extracted examples to external files
- [ ] Converted prose to bullet points
- [ ] Removed redundant content
- [ ] Combined similar sections

### Strategies Tried
1. [Strategy 1]: [Result]
2. [Strategy 2]: [Result]
3. [Strategy 3]: [Result]

### Impact Analysis
**If exemption granted**: [Benefits]
**If exemption denied**: [Consequences]

### Proposed Alternatives
1. [Alternative approach 1]
2. [Alternative approach 2]

### Exemption Type Requested
- [ ] Permanent exemption
- [ ] Temporary exemption until: [date]
- [ ] Partial exemption to: [new limit] lines
```

## Types of Exemptions

### 1. Temporary Exemptions

- **Duration**: 30-90 days maximum
- **Purpose**: Allow time for proper refactoring
- **Review**: Automatic expiration requires renewal

Example configuration:
```yaml
temporary_exemptions:
  - path: docs/bindings/security/comprehensive-audit.md
    expires: 2024-03-01
    limit: 350
    reason: "Refactoring security checklist, needs decomposition"
```

### 2. Permanent Exemptions

- **Approval**: Requires 2+ maintainer approval
- **Review**: Quarterly review cycle
- **Documentation**: Must be extensively justified

Example configuration:
```yaml
permanent_exemptions:
  - path: docs/bindings/migration/v1-to-v2-guide.md
    limit: 400
    reason: "Step-by-step migration cannot be condensed without losing critical steps"
    approved_by: ["maintainer1", "maintainer2"]
    approved_date: 2024-01-15
```

### 3. Category Exemptions

- **Scope**: Entire category of documents
- **Use case**: Special documentation types
- **Approval**: Requires architecture review

Example:
```yaml
category_exemptions:
  - pattern: "docs/bindings/security/*.md"
    limit: 300
    reason: "Security bindings require comprehensive coverage"
```

## Implementation (Future)

Currently, exemptions must be handled manually. Future implementation will support:

### Configuration File: `.enforcement-exemptions.yml`

```yaml
# Temporary exemptions (auto-expire)
temporary:
  - path: docs/bindings/core/complex-example.md
    limit: 250
    expires: 2024-06-01
    issue: "#123"

# Permanent exemptions (require justification)
permanent:
  - path: docs/legal/compliance-checklist.md
    limit: 500
    reason: "Regulatory requirement for complete checklist"
    approved: 2024-01-01
    reviewers: ["legal-team", "doc-team"]

# Category-based exemptions
categories:
  - pattern: "docs/reference/*.md"
    limit: 400
    reason: "Reference documentation requires completeness"
```

### Enforcement Script Updates

```ruby
# Future enforcement script will:
# 1. Load .enforcement-exemptions.yml
# 2. Check expiration dates
# 3. Apply custom limits
# 4. Report exemption usage
```

## Monitoring and Review

### Quarterly Reviews

All exemptions reviewed quarterly for:
- Continued necessity
- Reduction opportunities
- Pattern identification
- Process improvements

### Metrics Tracked

- Number of active exemptions
- Average overage amount
- Exemption duration
- Success rate of reductions

### Reporting

Monthly report includes:
- New exemption requests
- Expired exemptions
- Successfully reduced documents
- Trending patterns

## Best Practices

### For Document Authors

1. **Plan ahead**: Know limits before writing
2. **Modular design**: Break complex topics into multiple documents
3. **Progressive disclosure**: Link to details rather than embed
4. **Regular review**: Check line counts as you write

### For Reviewers

1. **Suggest alternatives**: Don't just reject, help find solutions
2. **Share examples**: Point to well-reduced documents
3. **Consider user needs**: Balance conciseness with completeness
4. **Document decisions**: Record why exemptions granted/denied

### For Maintainers

1. **Monitor trends**: Watch for systematic issues
2. **Update limits**: Adjust if many exemptions needed
3. **Improve tooling**: Make reduction easier
4. **Educate team**: Share reduction techniques

## Appeals Process

If an exemption request is denied:

1. **Clarification**: Request specific feedback on denial reasons
2. **Revision**: Address concerns and resubmit
3. **Escalation**: Appeal to architecture team if needed
4. **Alternative**: Propose documentation restructuring

## Success Stories

Examples of successful reductions:

- `secure-coding-checklist.md`: 401 → 147 lines (63% reduction)
  - Split into focused checklists
  - Linked to detailed guides
  - Maintained all critical information

- `typescript-setup.md`: 321 → 197 lines (39% reduction)
  - Consolidated duplicate examples
  - Extracted troubleshooting to FAQ
  - Improved clarity

## FAQ

**Q: What if regulatory requirements mandate verbosity?**
A: Document the specific regulation and request permanent exemption with legal review.

**Q: Can I get a "grace period" for new documents?**
A: New documents should meet limits from creation. Use drafts folder if needed.

**Q: What about generated documentation?**
A: Generated docs should be post-processed to meet limits or excluded from checks.

**Q: How do I handle mandatory templates?**
A: Extract template to separate file, reference from main document.

## Conclusion

The exemption process exists to handle truly exceptional cases while maintaining Leyline's commitment to concise, focused documentation. When in doubt, invest effort in reduction rather than exemption.
