---
id: automation
last_modified: "2025-05-04"
---

# Tenet: Automation as a Force Multiplier

Treat manual, repetitive tasks as bugs in your process. Invest in automating every feasible recurring activity to eliminate human error, ensure consistency, and free your most valuable resource—developer focus and creativity—for solving meaningful problems rather than performing mechanical tasks.

## Core Belief

Automation is fundamentally about respecting the scarcity of human attention and creativity. When you automate repetitive tasks, you're making a statement about where human intelligence adds the most value—in creative problem-solving, critical thinking, and innovation, not in executing the same mechanical steps over and over.

Think of automation like compound interest for your development process—the time invested upfront multiplies in value over the lifecycle of your project. A few hours spent automating a task pays dividends every time that task would have been performed manually, not just in time saved but in consistency of outcomes, elimination of human error, and improved team morale. Just as compound interest grows exponentially over time, the benefits of automation increase with each execution of the automated process.

Automation isn't merely a convenience or an optional enhancement to your workflow; it's a foundational practice that enables everything from reliable testing to consistent deployments to predictable quality. Without comprehensive automation, modern software development at scale becomes impractical if not impossible. Teams that excel at automation can deploy with confidence multiple times per day, while teams that rely on manual processes struggle to release monthly without introducing errors.

The pursuit of automation isn't about eliminating human judgment or creativity—quite the opposite. By freeing developers from mechanical, error-prone tasks, automation creates space for deeper thinking, more thorough design, and the creativity that leads to elegant solutions. Automation handles the mundane so humans can focus on the meaningful.

## Practical Guidelines

1. **Apply the "Three Strikes" Rule**: Never perform the same task manually more than twice without automating it. The third time you find yourself repeating a process, stop and ask: "How can I automate this so I never have to manually do it again?" This creates a natural prioritization mechanism—tasks that occur frequently get automated first, providing the highest return on investment. This simple heuristic can transform your workflow from reactive to proactive.

2. **Make Automation Mandatory, Not Optional**: Treat automation as a non-negotiable part of your development process, not as a "nice-to-have" addition. When you create automated processes like linting, testing, or build verification, enforce their use through mechanisms like pre-commit hooks, CI/CD pipelines, and protected branches. Ask yourself: "How can I make it impossible to skip this automated check?" Remember that optional automation will eventually be bypassed, especially under time pressure—precisely when it's most needed.

3. **Start with Developer Experience**: Focus first on automating tasks that directly impact the developer workflow, creating a tight feedback loop between writing code and verifying its correctness. This includes automating linting, formatting, type checking, and testing that can run locally before code is even committed. Ask: "What manual tasks are slowing down developers' ability to iterate quickly?" By automating these high-frequency activities, you create immediate benefits that motivate further investment in automation.

4. **Automate at the Right Level of Abstraction**: Choose the appropriate tools and approaches based on the task's frequency, complexity, and audience. For developer-facing automation (like linting or testing), prioritize speed and clear feedback. For operational automation (like deployments), prioritize reliability and observability. Ask yourself: "Who will be using this automation, and what do they need from it?" This ensures your automation serves its intended purpose effectively without unnecessary complexity.

5. **Invest in Automation Maintenance**: Treat automation code as production code that requires regular maintenance, refactoring, and improvement. Set aside dedicated time to review and update your automation tools, scripts, and workflows. Ask: "Are our automated processes still serving their purpose effectively?" Regular maintenance prevents automation decay, where automated processes become outdated or begin to fail, potentially leading teams to work around them rather than rely on them.

## Warning Signs

- **"It's faster to just do it manually"** being used as a justification for skipping automation. This short-term thinking ignores the cumulative cost of repetition and inconsistency. Consider how many times this task will be performed over the project's lifetime, not just the immediate time comparison. Manual approaches only seem faster because they ignore the hidden costs of inconsistency and errors.

- **Using `--no-verify` flags or similar bypasses** to circumvent automated checks. These overrides should be exceptional, not routine. If developers regularly bypass automation, it indicates either that the automation is broken/too slow or that there's insufficient understanding of its value. Fix the root cause rather than normalizing the workaround.

- **Documentation that contains manual steps** for routine operations like building, testing, or deploying. These manual instructions inevitably become outdated and lead to inconsistent results. Each manual step documented should be viewed as an automation opportunity not yet addressed. Ask: "Why hasn't this been automated yet?" and prioritize converting these instructions into scripts.

- **"Works on my machine"** problems occurring regularly, indicating environment inconsistencies that automation could prevent. These issues signal the need for better containerization, configuration management, or environment setup automation. They represent a significant productivity drain as team members waste time debugging environment differences rather than focusing on actual features.

- **Release processes that take more than a day** or require coordinated manual effort from multiple team members. Complex release processes are prime candidates for automation, as they're both critical to project success and prone to human error. Long release cycles often indicate fear of deployment due to insufficient automated testing and verification.

- **Developers spending more time on process than on problem-solving**. If your team is spending a significant portion of their time on routine tasks rather than creative work, your automation is insufficient. Measure and track the percentage of time spent on repetitive vs. creative tasks as a key metric for automation effectiveness.

- **Inconsistent outcomes from the same process** when performed by different team members or at different times. This variability is a clear indicator that a process relies too heavily on human execution and memory rather than automated, deterministic steps. Automation eliminates this variability, ensuring consistent results regardless of who initiates the process.

## Related Tenets

- [Testability](/tenets/testability.md): Automation is essential for implementing comprehensive testing practices. Without automated tests, achieving thorough test coverage becomes impractical, and tests tend to be run inconsistently. Automation enables the frequent, consistent execution of tests that makes testability valuable, while testability provides clear feedback on design qualities that make automation more effective.

- [Simplicity](/tenets/simplicity.md): Effective automation requires simplicity to be maintainable and reliable. Overly complex automation becomes a burden rather than an asset. Simplicity guides you to create automation that is straightforward to understand and modify, while automation helps maintain simplicity by enforcing consistent practices and standards.

- [Maintainability](/tenets/maintainability.md): Automation significantly improves maintainability by ensuring consistent code quality, comprehensive testing, and reliable deployment processes. Well-designed automation makes maintenance activities more predictable and less error-prone. Meanwhile, a focus on maintainability helps ensure that automated processes themselves remain valuable and adaptable over time.

- [No Secret Suppression](/tenets/no-secret-suppression.md): Automated security scanning and compliance checking are essential for enforcing the "no secret suppression" tenet at scale. Without automation, security checks become inconsistent and vulnerable to human oversight. These tenets complement each other—automation makes consistent security practices possible, while security consciousness ensures automation doesn't introduce new vulnerabilities.