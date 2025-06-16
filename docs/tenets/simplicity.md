---
id: simplicity
last_modified: '2025-06-16'
version: '0.1.0'
---
# Tenet: Simplicity Above All

Prefer the simplest design that solves the problem completely. Complexity is the root
cause of most software defects, maintenance challenges, and cognitive overload.
Rigorously seek solutions with the fewest moving parts.

## Core Belief

Simplicity is a fundamental requirement for building high-quality, maintainable
software, not just a nice-to-have goal. When you write simple code, you're making an
investment in the future health of your project. Simple code is easier to understand
when you return to it months later, easier to debug when something goes wrong, and
easier to extend when requirements change.

Think of code complexity like debt—it accrues interest over time. A complex solution
might seem efficient in the short term, but you'll pay for it many times over through
increased maintenance costs, onboarding challenges, and cognitive overload. Each additional
layer of complexity creates exponential growth in mental overhead needed to work with the code.

The pursuit of simplicity isn't about cutting corners or avoiding sophisticated
solutions when they're truly needed. Rather, it's about recognizing that there's
elegance in simplicity—finding the solution that solves the problem completely with the
least moving parts. It's about distinguishing between essential complexity (inherent in
the problem domain) and accidental complexity (introduced by our implementation
choices).

## Practical Guidelines

1. **Apply YAGNI Rigorously**: "You Aren't Gonna Need It" is more than just an
   acronym—it's a mindset that challenges you to question every piece of code that isn't
   solving an immediate, demonstrated need. When you feel the urge to add functionality
   "just in case," ask yourself: "Do we have concrete evidence we'll need this?" If not,
   defer it. The future requirement you're imagining may never materialize, or it might
   look completely different when it does.

1. **Minimize Moving Parts**: Each component, abstraction, configuration option, or
   dependency you add is a part that can break, must be understood, and needs
   maintenance. Before adding something new, ask: "What value does this add? Is there a
   simpler way to achieve the same outcome?" Be especially critical of dependencies—they
   bring their own complexity, security concerns, and update cycles into your project.

1. **Value Readability Over Cleverness**: Remember that code is read far more often than
   it's written. When writing code, you're not just communicating with the
   computer—you're communicating with other developers (including your future self).
   Prioritize clear, readable code over terse or clever approaches. Ask yourself: "Will
   someone unfamiliar with this code immediately understand what it does and why?" A
   solution that takes a few more lines but clearly expresses intent is better than a
   compact but cryptic alternative.

1. **Distinguish Complexity Types**: Learn to tell the difference between essential
   complexity (inherent in the problem domain) and accidental complexity (introduced by
   implementation choices). Essential complexity must be managed through good design and
   clear abstractions. Accidental complexity should be ruthlessly eliminated. When you
   find yourself creating complex structures, ask: "Is this complexity coming from the
   problem itself, or from my approach to solving it?"

1. **Refactor Towards Simplicity**: Codebases naturally drift toward complexity over
   time unless actively counteracted. Make simplification a continuous practice.
   Regularly step back and evaluate your existing code, asking: "How could this be
   simplified?" When you understand a piece of complex code, take the time to refactor
   it toward simplicity while its workings are fresh in your mind. This ongoing
   investment prevents complexity debt from accumulating.

1. **Ship Good-Enough Software**: Perfect software is the enemy of useful software.
   Focus on meeting actual user needs rather than pursuing theoretical perfection.
   Deliver value early and iterate based on real feedback rather than speculation.
   Ask yourself: "Is this good enough for our users, future maintainers, and business
   needs?" Quality has a cost, and over-engineering wastes resources that could be
   better spent on features users actually need. Know when to stop polishing and
   start delivering.

1. **Use Tracer Bullets for Early Validation**: When building new functionality,
   create a minimal end-to-end implementation first—a "tracer bullet" that touches
   all architectural layers but implements only core functionality. This simple
   approach validates assumptions about integration points, data flow, and user
   interaction early, when changes are cheap. Like actual tracer rounds that help
   gunners adjust their aim, tracer code helps you adjust your architecture before
   investing heavily in detailed implementation.

## Warning Signs

- **Over-engineering solutions** by creating elaborate frameworks for simple problems.
  Watch for solutions that feel disproportionate to the problem they solve.

- **Designing for imagined future requirements** rather than actual needs. Phrases like
  "We might need to..." without concrete use cases signal YAGNI violations. Focus on
  solving today's real problems, not tomorrow's hypothetical ones.

- **Premature abstraction** before seeing multiple concrete use cases. Creating abstractions
  too early often results in the wrong abstraction—which is worse than none at all. Wait
  until you see the same pattern at least three times before abstracting.

- **Implementing overly clever or obscure code** that requires significant mental effort
  to understand. If you find yourself thinking "this is clever," that's often a warning sign.

- **Deep nesting (> 2-3 levels)** of conditionals, loops, or functions, creating code
  that requires keeping multiple contexts in mind simultaneously. Consider refactoring
  deeply nested structures into smaller, more manageable pieces.

- **Excessively long functions/methods** that handle multiple responsibilities. When a
  function requires scrolling to view in its entirety, it's doing too much and should be
  decomposed into smaller, focused units.

- **Components violating the Single Responsibility Principle**, trying to handle
  multiple concerns. When you find yourself making frequent changes to the same file
  for different features, consider decomposing it.

- **Hearing justifications like "I'll make it generic so we can reuse it later"**
  without immediate demonstrated need. Generalization adds complexity and should be
  driven by actual requirements, not speculation.

## Related Tenets

- [Modularity](modularity.md): While Simplicity focuses on avoiding unnecessary
  complexity, Modularity guides how to break systems into focused, small components.
  Together, they help create systems that are both simple and well-structured.

- [Explicit over Implicit](explicit-over-implicit.md): Explicitness enhances simplicity
  by making code behavior clear and obvious, reducing mental overhead needed to
  understand what's happening.

- [Testability](testability.md): Simple code is inherently more testable. By keeping
  components focused and minimizing dependencies, you make them easier to test in
  isolation.

- [Maintainability](maintainability.md): Simplicity is a key contributor to
  maintainability. Simple systems are easier to understand, modify, and extend.

- [Empathize With Your User](empathize-with-your-user.md): User empathy naturally
  leads to simpler solutions because complex interfaces and interactions are harder
  for users to understand and navigate.

- [Product Value First](product-value-first.md): Product value focus naturally drives
  simplicity because unnecessary complexity doesn't serve users. When you consistently
  ask "How does this complexity benefit users?", you eliminate technical sophistication
  that exists purely for its own sake.
