# Strategic Task Decomposition - Multi-Expert TODO Generation for Leyline

Transform high-level plans into discrete, actionable TODO.md items using legendary programmer perspectives, tailored for the Leyline Ruby CLI gem and knowledge management system.

**Usage**: `/project:ticket`

## GOAL

Synthesize implementation plans into a TODO.md file composed of discrete, well-defined, narrowly scoped, highly detailed, context-rich, atomic and actionable task items that align with Leyline's philosophy of simplicity, testability, and knowledge sharing.

## ANALYZE

Transform the current plan or requirements into the most effective task breakdown possible for the Leyline project context.

### Phase 1: Context Analysis
1. Read any existing plans, TASK.md, or requirements documentation
2. Understand Leyline's Ruby CLI architecture and Thor framework patterns
3. Review existing TODO.md structure and task ID conventions (T001, T-MB1, etc.)
4. Check BACKLOG.md for related work chunks and dependencies
5. Study relevant leyline tenets and bindings for implementation guidance
6. Identify dependencies, risks, and critical path items in the context of:
   - Cache infrastructure (`lib/leyline/cache/`)
   - Git sync functionality (`lib/leyline/sync/`)
   - CLI interface patterns (`lib/leyline/cli.rb`)
   - Testing architecture (RSpec patterns in `spec/`)

### Phase 2: Multi-Expert Task Decomposition
Launch parallel subagents embodying legendary programmer perspectives using the Task tool:

**Task 1: John Carmack - Engineering Excellence & Performance**
Prompt: "As John Carmack, break down this plan into atomic engineering tasks focused on Leyline's performance targets (<1 second cached sync, >80% cache hit ratio). Each task should be technically precise, implementation-focused, and optimized for the Ruby runtime. Consider cache optimization, memory efficiency, and algorithmic clarity. What are the most fundamental units of work that maintain Leyline's speed-first philosophy?"

**Task 2: Yukihiro Matsumoto (Matz) - Ruby Happiness & Simplicity**
Prompt: "As Yukihiro Matsumoto, decompose this plan into tasks that honor Ruby's principle of developer happiness and Leyline's simplicity tenet. Each task should feel natural in Ruby, leverage appropriate gems (Thor, RSpec), and create delightful developer experiences. Focus on readable, maintainable code that brings joy to both implementers and users of the Leyline gem."

**Task 3: Kent Beck - Test-Driven Development & Quality**
Prompt: "As Kent Beck, break down this plan into testable increments aligned with Leyline's testability tenet. Each task should represent a verifiable behavior change with clear test scenarios. Structure tasks to enable test-first development, integration with RSpec patterns, and validation of both performance benchmarks and functional correctness. Consider both unit tests and integration tests for CLI functionality."

**Task 4: DHH - Convention Over Configuration & Pragmatic Development**
Prompt: "As DHH, identify tasks that follow Rails philosophy applied to CLI tools. Focus on convention over configuration, intelligent defaults, and progressive disclosure of complexity. Consider Leyline's CLI interface, user experience, and how to make complex caching invisible to users while providing power-user options. Each task should improve the tool's usability and developer ergonomics."

**Task 5: Linus Torvalds - Pragmatic Systems & Reliability**
Prompt: "As Linus Torvalds, create tasks that ensure system reliability, error handling, and robustness. Focus on git integration patterns, file system operations, cache corruption recovery, and edge case handling. Each task should contribute to a tool that 'just works' under various conditions while maintaining backward compatibility with existing Leyline workflows."

### Phase 3: Task Characteristics
Each expert should ensure their tasks are:
- **Atomic**: Cannot be meaningfully subdivided (focused on single responsibility)
- **Actionable**: Clear implementation path with specific file locations
- **Measurable**: Obvious completion criteria and success validation
- **Independent**: Minimal blocking dependencies where possible
- **Timeboxed**: Completable in reasonable time (2-8 hours of focused work)
- **Context-rich**: Include file paths, method names, and integration points
- **Leyline-aligned**: Honor simplicity, testability, and performance tenets

## EXECUTE

1. **Gather Context**
   - Read all relevant planning documents and requirements
   - Map out Leyline's technical implementation landscape:
     * Ruby gem structure and Thor CLI patterns
     * Cache architecture and performance targets
     * Git sync workflows and error handling
     * Testing patterns and fixtures organization
   - Identify key milestones aligned with BACKLOG.md priorities

2. **Launch Expert Subagents**
   - Use the Task tool to create independent subagents for each perspective
   - Have each expert create their task breakdown independently
   - Focus on Leyline-specific concerns: Ruby idioms, CLI UX, cache performance, knowledge management mission
   - Collect all task lists with rationales

3. **Synthesis Round**
   - Launch a synthesis subagent to merge all expert task lists
   - Eliminate duplicates while preserving unique insights from each perspective
   - Order tasks by dependencies and critical path analysis
   - Ensure comprehensive coverage of both technical and user experience requirements
   - Apply Leyline's 80/20 solution patterns to prioritize high-value tasks

4. **Task Formatting for Leyline**
   - Format each task as: `- [ ] **[Context] Specific action: implementation details**`
   - Use Leyline's task ID conventions when appropriate (T001, T-HP1, T-MB1 patterns)
   - Include file paths, method names, and validation criteria
   - Group related tasks under clear headings aligned with Leyline's architecture
   - Reference relevant leyline tenets and bindings where applicable

5. **Generate TODO.md (Leyline Style)**
   Create a comprehensive TODO.md file following Leyline's established patterns:
   ```markdown
   # TODO: [Brief Description]

   *Next focused PR: [What this accomplishes]*

   ## PR [Number]: [Feature Name] (Target: [Performance/Quality Goal])

   ### Core Implementation Tasks
   - [ ] **[Component] Action**: Detailed implementation with file paths and method names
   - [ ] **[Integration] Action**: How it connects with existing systems

   ### Testing & Validation Tasks
   - [ ] **[Unit Testing] Action**: Specific test scenarios and coverage goals
   - [ ] **[Integration Testing] Action**: End-to-end validation criteria
   - [ ] **[Performance Testing] Action**: Benchmark targets and measurement

   ### Code Quality Tasks
   - [ ] **[Backward Compatibility] Action**: Ensure existing functionality preserved
   - [ ] **[Error Handling] Action**: Graceful degradation and recovery
   - [ ] **[Documentation] Action**: CLI help, CLAUDE.md updates, comments

   ### Success Criteria Validation
   - [ ] **[Performance] Action**: Specific metrics and targets
   - [ ] **[Quality] Action**: Test coverage, linting, cross-platform validation
   ```

6. **PR Scope Sanity Check**
   After generating the initial TODO.md:
   - Analyze total scope against Leyline's development patterns
   - Estimate if completing all tasks would create a PR that is:
     * Too large (>500 lines of Ruby code changes)
     * Too broad in scope (touching >10 files or multiple subsystems)
     * Too difficult to review (mixing cache optimization with new CLI features)
   - Consider Leyline's focused PR philosophy: "Make one thing work really well"

7. **Scope Management (Leyline Style)**
   If breaking up is needed:
   - Take the highest priority chunk that aligns with BACKLOG.md priorities
   - Regenerate TODO.md with only tasks for this focused scope
   - Write remaining chunks to BACKLOG.md:
     * Read existing BACKLOG.md structure and integrate elegantly
     * Follow established priority levels (Priority 1: Performance, etc.)
     * Maintain John Carmack philosophy references and performance targets

   Enhanced BACKLOG.md format for new chunks:
   ```markdown
   #### PR [Number]: [Feature Name] (Target: [Goal])
   - **Problem**: [What user pain this solves]
   - **Solution**: [High-level approach aligned with Leyline tenets]
   - **Implementation**:
     - [High-level task items organized by component]
   - **Dependencies**: [What needs to be done first, reference to other PRs]
   - **Success**: [Measurable outcomes and validation criteria]
   ```

## Leyline-Specific Considerations

### Ruby CLI Architecture
- **Thor Framework**: Integrate with existing command structure and option parsing
- **Gem Conventions**: Follow Ruby packaging standards and version management
- **Error Handling**: Provide clear, actionable error messages with recovery guidance
- **Testing**: Leverage RSpec patterns and fixtures for comprehensive coverage

### Performance Philosophy
- **Cache-First**: Every task should consider cache interaction and performance impact
- **Benchmark-Driven**: Include specific timing targets (<1s warm cache, >80% hit ratio)
- **Graceful Degradation**: Ensure functionality works even when optimizations fail

### Knowledge Management Mission
- **Simplicity Tenet**: Prefer clear, maintainable solutions over clever optimizations
- **80/20 Patterns**: Focus on features that deliver maximum user value
- **Developer Experience**: Make complex functionality invisible to users while providing power options

### Integration Patterns
- **Backward Compatibility**: All existing CLI commands must continue working unchanged
- **File System**: Respect git workflows and existing directory structures
- **Cross-Platform**: Ensure functionality works on macOS, Linux, and Windows

## Success Criteria

- Every task is immediately actionable without further clarification
- Complete task list covers all aspects of the plan with Leyline architecture awareness
- Tasks are properly sequenced with dependencies clear and minimal blocking
- Each task includes sufficient context for Ruby implementation (file paths, method names)
- The breakdown enables parallel work where possible within Ruby's threading constraints
- No critical steps are missing from the implementation path
- TODO.md scope is appropriate for a single, reviewable PR focused on one major improvement
- Larger work is properly organized in BACKLOG.md following established priority structure
- All tasks align with relevant Leyline tenets and support the knowledge management mission
- Performance targets and quality standards are clearly defined and measurable

Execute this comprehensive task decomposition process now, ensuring all tasks honor Leyline's commitment to performance, simplicity, and developer happiness.
