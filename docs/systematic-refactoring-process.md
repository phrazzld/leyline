# Systematic Document Refactoring Process

This document outlines the systematic approach for refactoring oversized leyline documents to meet conciseness standards (≤150 lines for tenets, ≤400 lines for bindings).

## Process Overview

The systematic refactoring process consists of:

1. **Analysis**: Automated verbosity pattern detection
2. **Prioritization**: Community usage-based priority matrix
3. **Template Application**: Consistent refactoring approach
4. **Batch Processing**: Structured workflow with validation
5. **Quality Assurance**: Comprehensive validation suite

## Tools and Scripts

### Core Analysis Tools

#### `tools/analyze_verbosity_patterns.rb`
Analyzes all oversized documents to identify common verbosity patterns:

```bash
# Run complete verbosity analysis
ruby tools/analyze_verbosity_patterns.rb
```

**Output:**
- Documents categorized by community priority (TypeScript→Python→Go→remaining)
- Top verbosity patterns across all documents
- High-impact refactoring recommendations
- Quick wins identification
- Detailed per-document analysis with reduction potential

#### `tools/check_document_length.rb`
Validates document length compliance:

```bash
# Check all documents for length violations
ruby tools/check_document_length.rb

# Check specific document
ruby tools/check_document_length.rb docs/bindings/core/api-design.md
```

### Refactoring Support Tools

#### `tools/refactoring-template.md`
Comprehensive template providing:
- Section-by-section refactoring guidelines
- "One example rule" application strategy
- Common verbosity patterns to remove
- Quality gates and validation checklist
- Language priority for examples

#### `tools/refactoring-priority-matrix.md`
Strategic prioritization framework:
- **Tier 1 (High Impact)**: TypeScript, Go, critical Database bindings
- **Tier 2 (Medium Impact)**: Core bindings, remaining Python
- **Tier 3 (Quick Wins)**: Nearly compliant documents
- **Tier 4 (Systematic)**: Remaining documents for batch processing

Weekly sprint planning with target reductions and success metrics.

### Batch Processing Workflow

#### `tools/batch_refactoring_workflow.rb`
Automated workflow for systematic refactoring:

```bash
# Process all documents
ruby tools/batch_refactoring_workflow.rb

# Process specific tier only
ruby tools/batch_refactoring_workflow.rb 1    # High impact
ruby tools/batch_refactoring_workflow.rb 2    # Medium impact
ruby tools/batch_refactoring_workflow.rb 3    # Quick wins
```

**Workflow Steps:**
1. Loads priority documents from matrix
2. Creates automatic backups
3. Runs pre-validation checks
4. Provides document-specific refactoring guidance
5. Waits for manual refactoring completion
6. Validates refactored results
7. Runs comprehensive validation suite
8. Generates summary report with metrics

## Refactoring Strategy

### Core Principles

#### 1. "One Example Rule"
- **Before**: Multiple language examples (TypeScript + Python + Go + Java)
- **After**: Single comprehensive example in most appropriate language
- **Priority**: TypeScript → Python → Go → Rust → Other

#### 2. Focus on Principles Over Implementation
- **Remove**: Tool-specific configurations, version details, installation procedures
- **Keep**: Core principles, decision-making guidance, essential patterns

#### 3. Consolidate Repetitive Content
- **Merge**: Similar bullet points and explanations
- **Eliminate**: Redundant warnings and extensive analogies
- **Streamline**: Verbose prose while preserving meaning

#### 4. Target Structure Optimization
- **Rationale**: 2-3 paragraphs maximum
- **Rule Definition**: Bullet points, not prose
- **Implementation**: 3-4 key strategies with focused examples
- **Examples**: One bad, one good demonstration
- **Related Bindings**: Brief relationship explanations

### Document Structure Template

```markdown
---
[preserve YAML exactly]
---
# [Clear, direct title]

[2-3 line opening statement]

## Rationale

[2-3 paragraphs, ~6-8 lines total]
[One clear analogy maximum]
[Connection to parent tenet]

## Rule Definition

[4-6 core rules maximum]
- [1-2 lines per rule]
- [Sub-bullets only for essential clarification]

## Practical Implementation

[3-4 strategies with focused examples]
[10-30 lines of code maximum per example]
[Single language examples]

## Examples

```language
// ❌ BAD: [5-15 lines]
```

```language
// ✅ GOOD: [15-30 lines]
```

## Related Bindings

- [Brief 1-2 line explanations]
```

## Quality Gates

### Pre-Refactoring Validation
- [ ] Document structure is valid
- [ ] YAML front-matter is compliant
- [ ] Current line count and excess calculated
- [ ] Backup created successfully

### Refactoring Quality Checks
- [ ] **Length Compliance**: ≤400 lines (≤150 for tenets)
- [ ] **Reduction Achieved**: 60%+ reduction for high-excess documents
- [ ] **Value Preservation**: Core principles and guidance intact
- [ ] **Example Quality**: Clear, working code examples
- [ ] **Structure Integrity**: All required sections present

### Post-Refactoring Validation
- [ ] **YAML Validation**: `ruby tools/validate_front_matter.rb`
- [ ] **Length Check**: `ruby tools/check_document_length.rb`
- [ ] **Cross-References**: `ruby tools/fix_cross_references.rb`
- [ ] **Index Regeneration**: `ruby tools/reindex.rb --strict`
- [ ] **Link Integrity**: No broken internal references

## Usage Examples

### Individual Document Refactoring

```bash
# 1. Analyze specific document patterns
ruby tools/analyze_verbosity_patterns.rb | grep "async-patterns.md"

# 2. Review refactoring template
cat tools/refactoring-template.md

# 3. Check current compliance
ruby tools/check_document_length.rb docs/bindings/categories/typescript/async-patterns.md

# 4. Apply manual refactoring following template
# 5. Validate results
ruby tools/validate_front_matter.rb -f docs/bindings/categories/typescript/async-patterns.md
ruby tools/check_document_length.rb docs/bindings/categories/typescript/async-patterns.md
```

### Batch Processing

```bash
# 1. Run comprehensive analysis
ruby tools/analyze_verbosity_patterns.rb > refactoring_analysis.txt

# 2. Review priority matrix
cat tools/refactoring-priority-matrix.md

# 3. Process high-impact documents first
ruby tools/batch_refactoring_workflow.rb 1

# 4. Check progress
ruby tools/check_document_length.rb
```

## Success Metrics

### Overall Targets
- **Documents Compliant**: 49/49 under length limits
- **Total Line Reduction**: ~4,800 lines (60% average reduction)
- **Quality Preservation**: All essential guidance maintained
- **Link Integrity**: Zero broken cross-references

### Per-Document Targets
- **High Impact Documents**: 60-90% line reduction
- **Medium Impact Documents**: 40-60% line reduction
- **Quick Wins**: 20-40% line reduction
- **Quality Score**: All validation checks passing

## Continuous Improvement

### Pattern Detection Enhancement
Regular analysis of new verbosity patterns:

```bash
# Monthly verbosity pattern analysis
ruby tools/analyze_verbosity_patterns.rb > monthly_analysis.txt
```

### Template Refinement
Based on refactoring experience:
- Update common verbosity patterns
- Refine section-specific guidelines
- Improve example selection criteria

### Automation Opportunities
Future enhancements:
- Automated pattern detection and flagging
- Semi-automated example consolidation
- AI-assisted content summarization
- Real-time length validation in editors

## Integration with Development Workflow

### Pre-commit Hooks
Document length validation integrated into development workflow:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: check-document-length
      name: Check document length limits
      entry: ruby tools/check_document_length.rb
      language: system
      files: '\.(md)$'
```

### CI/CD Pipeline
Automated validation in pull requests:
- Document length compliance
- YAML front-matter validation
- Cross-reference integrity
- Index generation success

### Community Contribution
Guidelines for new document creation:
- Reference refactoring template for structure
- Follow "one example rule" from start
- Use priority language selection criteria
- Target length limits from beginning
