---
id: feature-flag-driven-development
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: distributed-git-workflows
enforced_by: 'feature flag systems, deployment pipelines, monitoring dashboards, automated testing'
---

# Binding: Implement Feature Flag-Driven Development for Distributed Teams

Decouple code deployment from feature release using feature flags, enabling distributed teams to merge code continuously while maintaining control over feature availability. Every significant feature must be developed behind a flag that allows granular control over rollout and rollback.

## Rationale

This binding directly implements our distributed Git workflows tenet by solving one of the fundamental challenges of distributed development: how to integrate code continuously from multiple teams without blocking on feature completion or coordination. Feature flags transform the traditional "branch until ready" model into a "merge always, release when ready" model that aligns with distributed systems principles.

In distributed systems, we've learned that coupling deployment with release creates bottlenecks and reduces system reliability. The same principle applies to distributed development teams. When teams must coordinate merges based on feature readiness, they create synchronization points that don't scale across time zones and team boundaries. Feature flags eliminate these coordination requirements by allowing code to flow continuously while features remain dark until ready.

Think of feature flags as circuit breakers for functionality. Just as distributed systems use circuit breakers to isolate failures, feature flags isolate incomplete or risky features from users while allowing the code to live in production. This enables powerful workflows: gradual rollouts to percentages of users, instant rollback without deployment, and A/B testing of competing implementations. These capabilities are essential when teams are distributed and can't coordinate deploys in real-time.

## Rule Definition

Feature flag-driven development requires these distributed systems-inspired practices:

- **Continuous Integration Without Continuous Activation**: All code merges to main continuously, but features activate through flags, not deployments.

- **Granular Control Mechanisms**: Flags must support percentage rollouts, user targeting, and instant toggling without code changes.

- **Observable Flag State**: The state of all flags must be visible, audited, and monitorable like any critical system configuration.

- **Automated Flag Lifecycle**: Flags must be created, managed, and retired through automated processes to prevent flag debt accumulation.

**Core Requirements**:
- New features developed behind flags from day one
- Flags controllable without deployment
- Monitoring and alerting on flag changes
- Automated tests for both flag states
- Clear flag naming conventions and documentation
- Flag retirement process and technical debt tracking

**Flag Patterns**:
- Release flags: Control feature visibility
- Experiment flags: Enable A/B testing
- Ops flags: Control system behavior
- Permission flags: Enable feature access by user segment

## Practical Implementation

1. **Design Flags Into Architecture**: Build feature flag evaluation into your application's core architecture, not as an afterthought. Use a centralized flag service that can be updated without deployment:
   ```typescript
   // Centralized flag service with distributed team support
   class FeatureFlags {
     async isEnabled(flagName: string, context: UserContext): Promise<boolean> {
       // Evaluate against remote flag service
       // Include user context for targeted rollouts
       // Cache with short TTL for performance
     }
   }
   ```

2. **Implement Flag-Aware Testing**: Test both flag states in your CI pipeline to ensure features work correctly when enabled and are properly hidden when disabled:
   ```typescript
   describe('NewFeature', () => {
     it('should work when flag is enabled', async () => {
       mockFlags({ 'new-feature': true });
       // Test feature functionality
     });

     it('should be hidden when flag is disabled', async () => {
       mockFlags({ 'new-feature': false });
       // Verify feature is completely hidden
     });
   });
   ```

3. **Create Observable Flag Dashboards**: Build monitoring that shows flag states, change history, and impact metrics:
   ```yaml
   # Flag monitoring configuration
   alerts:
     - name: flag-change-rate-high
       condition: rate(flag_changes[5m]) > 10
       severity: warning

     - name: flag-evaluation-errors
       condition: rate(flag_evaluation_errors[1m]) > 0.01
       severity: critical
   ```

4. **Establish Flag Hygiene Processes**: Prevent flag accumulation through automated lifecycle management:
   ```bash
   # Automated flag retirement check
   flags older than 90 days:
     - send Slack reminder to owner
     - create JIRA ticket for retirement
     - add to technical debt dashboard
   ```

5. **Enable Distributed Team Workflows**: Structure flags to support async collaboration:
   ```typescript
   // Flag naming convention for distributed teams
   // team-feature-experiment-version
   const flags = {
     'payments-checkout-redesign-v2': {
       owner: 'payments-team',
       created: '2024-01-15',
       targets: ['beta-users'],
       rollout: 10, // percentage
     }
   };
   ```

## Examples

```typescript
// ❌ BAD: Feature development without flags
class UserProfile {
  render() {
    // New design is coupled to deployment
    return <NewProfileDesign />;
    // Can't merge until feature is 100% ready
    // Blocks other team's profile changes
  }
}

// ✅ GOOD: Flag-driven feature development
class UserProfile {
  async render() {
    const showNewDesign = await featureFlags.isEnabled(
      'profile-redesign-2024',
      { userId: this.user.id }
    );

    if (showNewDesign) {
      return <NewProfileDesign />;
    }
    return <ClassicProfileDesign />;
    // Can merge immediately, control rollout separately
  }
}
```

```yaml
# ❌ BAD: Deployment-coupled release process
deploy:
  - build new feature
  - test everything
  - coordinate with all teams
  - deploy to production
  - hope nothing breaks
  # High-risk, requires synchronous coordination

# ✅ GOOD: Flag-driven continuous deployment
deploy:
  - build all merged code
  - test with flags in various states
  - deploy automatically
  - features remain dark
release:
  - gradually enable flag for 1% of users
  - monitor metrics and errors
  - increase rollout or rollback instantly
  # Low-risk, async team coordination
```

```typescript
// ❌ BAD: Hard-coded feature variations
if (process.env.NODE_ENV === 'production') {
  // Use production algorithm
} else {
  // Use experimental algorithm
}
// Can't test in production, can't rollback

// ✅ GOOD: Flag-controlled experiments
const algorithm = await featureFlags.getVariant('search-algorithm', {
  userId: user.id,
  accountType: user.accountType
});

switch (algorithm) {
  case 'control':
    return classicSearch(query);
  case 'ml-powered':
    return mlSearch(query);
  case 'hybrid':
    return hybridSearch(query);
}
// Test in production, instant rollback, measure impact
```

## Related Bindings

- [atomic-commits.md](atomic-commits.md): Feature flags enable atomic commits by allowing partially complete features to be merged safely. Each commit can be complete and tested even if the overall feature isn't ready for users.

- [distributed-conflict-resolution.md](distributed-conflict-resolution.md): Feature flags reduce merge conflicts by eliminating long-lived feature branches. When all code merges to main continuously, conflicts are smaller and easier to resolve.

- [git-monitoring-metrics.md](../git-monitoring-metrics.md): Feature flag systems must be monitored like any critical infrastructure. Flag change rates, evaluation performance, and error rates are key metrics for system health.

- [automated-rollback-procedures.md](../automated-rollback-procedures.md): Feature flags provide instant rollback capability without deployment. This is essential for distributed teams who can't coordinate emergency deployments across time zones.

- [large-repository-patterns.md](../large-repository-patterns.md): Feature flags enable monorepo workflows by allowing teams to develop independently while sharing code. Teams can merge continuously without blocking on cross-team feature dependencies.
