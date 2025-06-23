# Strategic Task Executor - Systematic TODO Completion for Leyline

Methodically execute tasks from TODO.md with expert-level strategic planning and implementation, tailored for Leyline's Ruby CLI gem and knowledge management system.

**Usage**: `/project:execute`

## GOAL

Select and complete the next available task from TODO.md using comprehensive analysis, strategic planning, and flawless execution aligned with Leyline's tenets of simplicity, testability, and performance excellence.

## ACQUISITION

Select the next available ticket from TODO.md following this priority:
1. **Critical Blockers** marked with `- [ ] **T-MB#:` - Must fix before merge
2. **High Priority** marked with `- [ ] **T-HP#:` - Should fix before merge
3. **In-progress tasks** marked with `[~]` - Continue paused work
4. **Unblocked tasks** marked with `[ ]` - Start fresh work
5. Consider task dependencies and critical path analysis
6. Skip blocked tasks until dependencies are resolved

If all tasks in TODO.md are completed:
- Run comprehensive validation suite (`ruby tools/run_ci_checks.rb --full`)
- Celebrate completion appropriately with performance metrics
- Check BACKLOG.md for next PR scope
- Suggest next strategic moves aligned with Leyline priorities
- Halt

## CONTEXT GATHERING

Conduct comprehensive review before execution:

### 1. **Leyline Codebase Analysis**
- Read all files mentioned in or relevant to the task:
  - Ruby source files in `lib/leyline/`
  - CLI interface patterns in `lib/leyline/cli.rb`
  - Cache infrastructure in `lib/leyline/cache/`
  - Git sync functionality in `lib/leyline/sync/`
  - Test patterns in `spec/` directory
- Understand existing patterns: Thor CLI framework, RSpec testing, error handling
- Identify potential impact areas and dependencies within Leyline's architecture

### 2. **Knowledge Management Documentation Review**
- Study relevant leyline tenets for foundational principles:
  - Simplicity: Prefer clear solutions over clever ones
  - Testability: Design for test-first development
  - Performance: Honor <1s cached sync, >80% cache hit ratio targets
  - Maintainability: Support long-term system health
- Review applicable bindings, especially core and Ruby-specific ones
- Check CLAUDE.md for project-specific conventions and performance targets
- Review any architectural decisions in the codebase

### 3. **External Research (When Needed)**
- Use Context7 MCP server for Ruby gem/Thor CLI documentation
- Conduct web searches for Ruby best practices and common pitfalls
- Research cache optimization patterns and file system performance
- Study Thor CLI patterns and command-line UX best practices

### 4. **Advanced Analysis** (for complex tasks only)
- Consider security implications for file operations and cache management
- Evaluate performance impact on Leyline's speed-first philosophy
- Assess long-term maintainability implications

## STRATEGIC PLANNING

### Multi-Expert Planning Session

For complex tasks, use the Task tool to consult expert perspectives:

**Task 1: John Carmack - Performance & Algorithmic Excellence**
Prompt: "As John Carmack, analyze this Leyline implementation task. Focus on performance optimization for the <1 second cached sync target, algorithmic efficiency for cache hit ratio calculations, and memory-efficient file operations. What's the most elegant solution that honors Leyline's speed-first philosophy?"

**Task 2: Yukihiro Matsumoto (Matz) - Ruby Happiness & Simplicity**
Prompt: "As Matz, review this task for Ruby developer happiness and Leyline's simplicity tenet. How would you implement this in idiomatic Ruby that feels natural, leverages Thor CLI patterns, and brings joy to developers using the gem? Consider Ruby conventions and the principle of least surprise."

**Task 3: Kent Beck - Test-First & Quality**
Prompt: "As Kent Beck, plan this implementation with Leyline's testability tenet in mind. How would you approach it test-first using RSpec patterns? What's the smallest change that could possibly work? How do we ensure correctness while maintaining the test suite's speed and reliability?"

**Task 4: Linus Torvalds - Pragmatic Systems Excellence**
Prompt: "As Linus Torvalds, review this task for practical system reliability. Focus on git integration robustness, file system edge cases, cache corruption recovery, and error handling. What's the most pragmatic approach that ensures Leyline 'just works' across macOS, Linux, and Windows?"

### Plan Synthesis
- Combine expert insights into a cohesive strategy
- Apply Leyline's 80/20 solution patterns to focus on high-value implementation
- Create step-by-step implementation plan with Ruby-specific details
- Identify checkpoints for validation and performance measurement
- Plan for graceful degradation if cache optimizations fail

## IMPLEMENTATION

Execute the approved plan with precision:

### 1. **Pre-Implementation Setup**
- Ensure current branch is clean or create feature branch if major change
- Set up test infrastructure following RSpec patterns in `spec/`
- Prepare any necessary fixtures or test data
- Run baseline tests: `bundle exec rspec` to ensure starting point is clean

### 2. **Incremental Execution (Leyline Style)**
- Implement in small, testable increments honoring Ruby conventions
- Follow Leyline's file structure and naming patterns
- Run tests after each significant change: `bundle exec rspec [specific_spec]`
- Commit working states frequently with conventional commit messages
- Honor Leyline's code style and Thor CLI patterns

### 3. **Continuous Validation**
- Run essential validation frequently: `ruby tools/run_ci_checks.rb --essential`
- Execute relevant test suite after each component: `bundle exec rspec spec/[area]`
- Verify no regressions in cache performance or sync speed
- Check that CLI interface changes don't break existing commands
- Validate against Leyline's performance targets

### 4. **Adaptive Response**
If encountering unexpected situations:
- **HALT** implementation immediately
- Document the specific issue encountered with Ruby/CLI context
- Analyze implications for Leyline's architecture and performance goals
- Consider impact on cache optimization and git sync reliability
- Present findings to user with recommendations
- Wait for guidance before proceeding

## QUALITY ASSURANCE

Before marking task complete, ensure Leyline quality standards:

### 1. **Code Quality Checks**
- All tests pass: `bundle exec rspec`
- RuboCop compliance: `bundle exec rubocop` (if available)
- Essential validation: `ruby tools/run_ci_checks.rb --essential`
- No commented-out code or TODOs left
- Ruby documentation updated in comments if needed

### 2. **Functional Validation**
- Task requirements fully met per TODO.md specification
- Cache performance targets maintained (<1s warm sync, >80% hit ratio)
- CLI interface works as expected with Thor framework
- Edge cases handled appropriately (cache corruption, git failures)
- No breaking changes to existing gem functionality

### 3. **Integration Verification**
- Changes work with existing Leyline CLI commands
- Cache infrastructure integration functions correctly
- Git sync workflows remain reliable
- Backward compatibility preserved for gem users
- Performance benchmarks maintained or improved

## CLEANUP

Upon successful completion:

### 1. **Task Management**
- Update task status to `[x]` in TODO.md
- Add completion notes if helpful for future reference or performance validation
- Check for any follow-up tasks that are now unblocked
- Update any related documentation in CLAUDE.md

### 2. **Code Finalization**
- Ensure all changes committed with clear conventional commit messages
- Run comprehensive validation: `ruby tools/run_ci_checks.rb --full`
- Update CLI help text if interface changed
- Clean up any temporary files or test fixtures

### 3. **Progress Assessment**
- Review remaining tasks in TODO.md for newly unblocked work
- Measure performance impact of changes (if applicable)
- Consider if BACKLOG.md needs updates based on learnings
- Identify any emergent tasks from implementation
- Prepare summary of what was accomplished with metrics

## SUCCESS CRITERIA

- Task completed according to TODO.md specifications
- Code quality meets Leyline standards (RSpec tests, Ruby conventions)
- All tests pass and coverage maintained
- Implementation follows Leyline's Ruby/Thor CLI patterns
- Performance targets maintained or improved
- No technical debt introduced
- Cache optimization working correctly
- CLI interface remains intuitive and powerful
- Ready for code review and integration

## FAILURE PROTOCOLS

If unable to complete task:
- Document specific blockers encountered with technical context
- Update task with `[!]` blocked status and detailed blocker description
- Create new tasks for unblocking work if needed
- Consider impact on critical path and performance targets
- Communicate clearly about obstacles with suggested alternatives
- If cache/performance related, ensure graceful degradation still works

## LEYLINE-SPECIFIC VALIDATIONS

Before completion, verify:
- **Performance**: Cache operations don't degrade sync speed
- **Reliability**: Git operations have proper fallback when cache fails
- **Usability**: CLI commands remain simple and intuitive
- **Maintainability**: Code follows Ruby conventions and is well-tested
- **Compatibility**: Works across supported platforms (macOS, Linux, Windows)

Execute the next task with strategic excellence, Ruby mastery, and systematic precision, honoring Leyline's commitment to speed, simplicity, and developer happiness.
