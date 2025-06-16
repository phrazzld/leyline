# Document Refactoring Template

## Target: Reduce [DOCUMENT_NAME] from [CURRENT_LINES] to ≤400 lines

### Pre-Refactoring Checklist

- [ ] **Read full document** to understand core value and structure
- [ ] **Identify YAML front-matter** and ensure it's preserved exactly
- [ ] **Map examples by language** to apply "one example rule"
- [ ] **Identify cross-references** that must be maintained

### Core Refactoring Strategies

#### 1. Apply "One Example Rule"
- **Before**: Multiple language examples (TypeScript + Python + Go + Java)
- **After**: Single comprehensive example in most appropriate language
- **Decision criteria**: Choose language that best demonstrates the pattern
- **Preserve**: Language-agnostic principles and concepts

#### 2. Focus on Principles Over Implementation
- **Cut**: Tool-specific configurations and version details
- **Cut**: Step-by-step installation instructions
- **Cut**: Environment setup procedures
- **Keep**: Core principles and decision-making guidance
- **Keep**: Essential patterns and anti-patterns

#### 3. Consolidate Repetitive Content
- **Merge**: Similar bullet points and explanations
- **Eliminate**: Redundant warnings and guidelines
- **Streamline**: Verbose analogies to single clear metaphor
- **Tighten**: Prose without losing meaning

#### 4. Restructure for Conciseness
- **Rationale**: 2-3 paragraphs maximum, focus on "why"
- **Rule Definition**: Bullet points, not prose
- **Practical Implementation**: 3-4 key strategies with focused examples
- **Examples**: One bad, one good pattern demonstration
- **Related Bindings**: Brief explanations of relationships

### Section-by-Section Guidelines

#### Header & YAML (preserve exactly)
```yaml
---
id: [preserve]
last_modified: [update to current date]
version: [preserve]
derived_from: [preserve]
enforced_by: [preserve, may need shortening]
---
```

#### Title & Opening (2-3 lines)
- Clear, direct statement of binding purpose
- Avoid verbose introductions

#### Rationale (2-3 paragraphs, ~6-8 lines total)
- Essential "why" explanation
- One clear analogy maximum
- Connection to parent tenet
- Remove historical context and verbose justifications

#### Rule Definition (bullet points)
- 4-6 core rules maximum
- Each rule: 1-2 lines
- Sub-bullets only for essential clarification
- Remove tool-specific details

#### Practical Implementation (3-4 strategies)
- Each strategy: brief description + focused example
- Examples: 10-30 lines of code maximum
- Remove multi-language repetition
- Focus on pattern demonstration

#### Examples Section (streamlined)
- One "bad" example (5-15 lines)
- One "good" example (15-30 lines)
- Clear, impactful contrast
- Remove lengthy explanations

#### Related Bindings (preserve but condense)
- Keep all cross-references
- Shorten explanations to 1-2 lines each
- Focus on relationship clarity

### Validation Checklist

- [ ] **Length**: Document ≤400 lines
- [ ] **YAML**: Front-matter unchanged and valid
- [ ] **Examples**: All code examples syntax-valid
- [ ] **Cross-references**: All links functional
- [ ] **Value preservation**: Core principles intact
- [ ] **Actionability**: Guidance remains implementable

### Quality Gates

1. **60%+ reduction achieved** while preserving essential value
2. **Single example rule applied** - no multi-language repetition
3. **Cross-references maintained** - no broken links
4. **Principles preserved** - actionable guidance intact
5. **Ruby validation passes** - YAML and document structure valid

## Language Priority for Examples

1. **TypeScript**: Web applications, full-stack patterns, type safety
2. **Python**: Data processing, automation, scientific computing
3. **Go**: System services, microservices, infrastructure
4. **Rust**: Performance-critical, systems programming
5. **Other**: Only if pattern is language-specific

## Common Verbosity Patterns to Remove

- Multiple installation procedures across platforms
- Detailed tool configuration examples
- Repetitive explanations of same concept
- Verbose analogies and metaphors
- Historical context and evolution discussions
- Defensive explanations of design decisions
- Tool comparison matrices
- Platform-specific implementation details
- Step-by-step tutorials
- Extensive troubleshooting sections
