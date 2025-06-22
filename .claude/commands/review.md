# Multi-Agent Code Review for Leyline

Generate a comprehensive code review using parallel expert analysis, tailored for Leyline's Ruby CLI gem and knowledge management system.

**Usage**: `/project:review`

## WORKFLOW

### Phase 1: Context Preparation
1. **Get Branch Information**
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null || echo "master")
   CHANGED_FILES=$(git diff --name-only ${BASE_BRANCH}...HEAD | wc -l | tr -d ' ')
   ```

2. **Generate Full Diff and Context**
   ```bash
   git diff --name-status ${BASE_BRANCH}...HEAD > changed_files_summary.txt
   ```

3. **Create REVIEW-CONTEXT.md**
   ```bash
   # IMPORTANT: DO NOT READ THE FULL DIFF - IT'S TOO LARGE
   # Use bash commands to create the file efficiently

   cat > REVIEW-CONTEXT.md << 'EOF'
   # Code Review Context

   ## PR Details
   Branch: ${CURRENT_BRANCH}
   Base Branch: ${BASE_BRANCH}
   Files Changed: ${CHANGED_FILES}

   ## Changed Files Summary
   $(cat changed_files_summary.txt)

   ## Leyline Architecture Context
   - **Project Type**: Ruby CLI gem using Thor framework
   - **Core Mission**: Knowledge management system for sharing development principles
   - **Architecture**: Cache-aware git sync with performance targets (<1s warm cache, >80% hit ratio)
   - **Key Components**:
     * CLI interface (`lib/leyline/cli.rb`)
     * Cache infrastructure (`lib/leyline/cache/`)
     * Git sync system (`lib/leyline/sync/`)
     * Validation tools (`tools/`)
     * Knowledge base (tenets and bindings in `docs/`)

   ## Full Diff
   EOF

   # Append the full diff directly without reading it
   git diff ${BASE_BRANCH}...HEAD >> REVIEW-CONTEXT.md
   ```

### Phase 2: Parallel Expert Review
Launch subagents using the Task tool for independent analysis:

**Task 1: John Carmack - Performance & Algorithmic Excellence**
Prompt: "As John Carmack, review the code diff in REVIEW-CONTEXT.md focusing on algorithmic efficiency, performance optimization, and first principles engineering. Consider Leyline's performance targets (<1 second cached sync, >80% cache hit ratio), memory usage, computational complexity, and mathematical elegance. Evaluate cache optimization strategies, SHA256 content addressing efficiency, and file I/O patterns. What could be more algorithmically sound or performant?"

**Task 2: Yukihiro Matsumoto (Matz) - Ruby Happiness & Simplicity**
Prompt: "As Yukihiro Matsumoto, review this code for Ruby developer happiness, idiomatic patterns, and Leyline's simplicity tenet. Evaluate Thor CLI integration, module organization, method naming, and Ruby conventions. Consider how well the code serves Leyline's knowledge sharing mission while maintaining Ruby's principle of least surprise. Focus on readable, maintainable code that brings joy to both gem users and contributors."

**Task 3: DHH - Convention Over Configuration & CLI Excellence**
Prompt: "As DHH, review this code from Rails philosophy applied to CLI tools. Evaluate convention over configuration, intelligent defaults, progressive disclosure of complexity, and developer ergonomics. Consider Leyline's CLI interface design, optional parameters, and how the tool balances simplicity with power. Assess how well the code serves knowledge management goals while maintaining intuitive user experience."

**Task 4: Martin Fowler - Architecture & Knowledge Systems**
Prompt: "As Martin Fowler, review this code for architectural patterns, system design, and knowledge management effectiveness. Evaluate how well the code supports Leyline's mission of sharing development principles through tenets and bindings. Consider separation of concerns, abstraction levels, domain modeling, and how the architecture facilitates both content delivery and system evolution. Assess the balance between technical excellence and knowledge sharing goals."

**Task 5: Kent Beck - Test-Driven Development & Quality**
Prompt: "As Kent Beck, review this code for testability, quality practices, and Leyline's testability tenet. Evaluate test coverage, test design, behavior-driven patterns, and integration with RSpec. Consider how well the code enables test-first development, supports regression testing, and maintains quality gates. Assess both unit tests and integration tests for CLI functionality, cache behavior, and git operations."

### Phase 3: Leyline-Specific Quality Analysis
**Task 6: Leyline Standards Compliance**
Prompt: "Review this code specifically for Leyline standards compliance. Check alignment with core tenets (simplicity, testability, maintainability, modularity, etc.) and applicable bindings. Evaluate YAML front-matter standards, conventional commits compliance, documentation quality, and adherence to Leyline's 80/20 solution patterns. Assess how well changes support the knowledge management mission and maintain backward compatibility."

### Phase 4: Leyline-Specific Validation

```bash
# Run Leyline's essential validation suite
ruby tools/run_ci_checks.rb --essential

# Check specific Ruby patterns if applicable
if [[ -f .rubocop.yml ]]; then
  bundle exec rubocop --format simple
fi

# Validate any new bindings or tenets
if git diff --name-only ${BASE_BRANCH}...HEAD | grep -q "docs/.*\.md"; then
  ruby tools/validate_front_matter.rb
fi
```

### Phase 5: Final Synthesis
**Create Final CODE_REVIEW.md:**
   ```markdown
   # Code Review: ${CURRENT_BRANCH}

   ## Executive Summary
   [High-level overview combining all expert perspectives]

   ## Leyline Standards Compliance
   ### ✅ Tenet Alignment
   - **Simplicity**: [Assessment of adherence to simplicity tenet]
   - **Testability**: [Evaluation of test design and coverage]
   - **Maintainability**: [Long-term maintenance considerations]
   - **Modularity**: [Component design and separation of concerns]

   ### 📋 Binding Compliance
   [Check against applicable core bindings and Ruby-specific patterns]

   ## Critical Issues
   ### 🚨 Blockers (Must Fix Before Merge)
   [Issues that prevent merge - crashes, breaking changes, security vulnerabilities]

   ### ⚠️ High Priority (Should Fix Before Merge)
   [Important issues affecting performance, maintainability, or user experience]

   ### 📝 Medium Priority (Consider for Future)
   [Improvements worth considering but not blocking]

   ## Architecture & Design Analysis
   ### 🏗️ System Design
   [Architectural impact from Martin Fowler perspective]

   ### 🎯 Knowledge Management Mission
   [How changes support or impact Leyline's core knowledge sharing goals]

   ### 🔄 Cache & Performance Impact
   [Performance analysis from John Carmack perspective, cache hit ratio implications]

   ## Ruby Excellence Assessment
   ### 💎 Idiomatic Ruby (Matz Perspective)
   [Ruby happiness, conventions, principle of least surprise]

   ### 🚀 CLI/UX Design (DHH Perspective)
   [Convention over configuration, developer ergonomics, progressive disclosure]

   ### 🧪 Testing Quality (Kent Beck Perspective)
   [Test design, coverage, TDD compliance, quality gates]

   ## Security & Reliability
   [Combined security and reliability insights from all perspectives]

   ## Performance Considerations
   ### ⚡ Cache System Impact
   [Impact on <1s warm cache target and >80% hit ratio goal]

   ### 📊 Benchmark Results
   [Any performance measurements or projections]

   ## Positive Aspects
   [Good practices, improvements, and commendable implementations noted]

   ## Recommendations
   ### 🎯 Immediate Actions (Priority Order)
   1. [Most critical fixes with specific file/line references]
   2. [Performance optimizations with measurable impact]
   3. [Ruby idiom improvements with clear examples]

   ### 🔮 Future Considerations
   [Longer-term improvements and architectural evolution suggestions]

   ## Leyline Tool Integration
   ### 🛠️ Validation Commands
   ```bash
   # Essential validation (fast)
   ruby tools/run_ci_checks.rb --essential

   # Full validation suite
   ruby tools/run_ci_checks.rb --full

   # Cache performance validation (if applicable)
   ruby tools/validate_cache_performance.rb
   ```

   ### 📚 Documentation Updates Needed
   [CLAUDE.md, README.md, or other documentation requiring updates]

   ## Review Metadata
   - **Reviewers**: John Carmack, Matz, DHH, Martin Fowler, Kent Beck, Leyline Standards
   - **Thinktank Models**: [List of models used]
   - **Performance Targets**: <1s warm cache, >80% hit ratio maintained: [✅/❌]
   - **Breaking Changes**: [Yes/No with migration guide if needed]
   - **Backward Compatibility**: [Assessment]
   ```

### Phase 6: Cleanup & Validation
```bash
# Clean up temporary files
rm -f REVIEW-CONTEXT.md changed_files_summary.txt

# Preserve final review
echo "✅ Code review complete: CODE_REVIEW.md"
echo "📊 Run Leyline validation: ruby tools/run_ci_checks.rb --essential"
```

## Leyline-Specific Considerations

### Ruby CLI Architecture
- **Thor Framework**: Integration with existing command structure and option parsing
- **Gem Conventions**: Ruby packaging standards, version management, runtime dependencies
- **Error Handling**: Clear, actionable error messages with recovery guidance aligned with CLI best practices
- **Testing**: RSpec patterns, fixtures organization, integration tests for CLI functionality

### Knowledge Management Mission
- **Simplicity Over Complexity**: Honor simplicity tenet - prefer clear solutions over clever ones
- **Knowledge Sharing**: Prioritize solutions that enhance the system's ability to share development wisdom
- **80/20 Solution Patterns**: Focus on the 20% of features that deliver 80% of user value
- **Tenet Alignment**: Ensure changes support and don't conflict with established tenets

### Performance Philosophy
- **Cache-First**: Every change should consider cache interaction and performance impact
- **Benchmark-Driven**: Validate against <1s warm cache and >80% hit ratio targets
- **Graceful Degradation**: Ensure functionality works even when optimizations fail
- **Git Efficiency**: Optimize sparse-checkout patterns and git operations

### Integration Patterns
- **Backward Compatibility**: All existing CLI commands must continue working unchanged
- **File System**: Respect git workflows and existing directory structures
- **Cross-Platform**: Ensure functionality works on macOS, Linux, and Windows
- **Tool Integration**: Leverage existing validation tools and maintain CI compliance

## Success Criteria

- ✅ All expert perspectives represented with domain-specific insights
- ✅ Thinktank models provide diverse, comprehensive analysis
- ✅ Synthesis demonstrates collective intelligence without redundancy
- ✅ Actionable recommendations with clear priorities and file references
- ✅ Leyline tenet and binding compliance assessed
- ✅ Performance impact on cache targets evaluated
- ✅ Ruby idiom and CLI design excellence validated
- ✅ Knowledge management mission impact considered
- ✅ Integration with existing Leyline toolchain confirmed

Execute this comprehensive Leyline-aware code review process now.
