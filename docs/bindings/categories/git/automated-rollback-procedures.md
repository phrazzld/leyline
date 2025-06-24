---
id: automated-rollback-procedures
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-reliability-engineering
enforced_by: 'deployment pipelines, rollback automation, git revert strategies, monitoring integration'
---

# Binding: Implement Automated Git Rollback Procedures

Design and implement automated rollback mechanisms that can quickly restore system state when problems occur. Create multiple rollback strategies—from simple reverts to complex state restoration—that work reliably under pressure without manual intervention.

## Rationale

This binding implements our Git reliability engineering tenet by acknowledging that failures are inevitable and preparing systematic responses. In distributed systems, we design for failure by implementing circuit breakers, fallbacks, and automated recovery. Git rollback procedures serve the same purpose for version control: when things go wrong, we need fast, reliable ways to restore good state without depending on human memory or availability.

Traditional rollback approaches often rely on manual Git commands executed under pressure: "Quick, someone git revert that commit!" This approach fails at scale because it requires the right person with the right permissions to execute the right commands while the system is degraded. By automating rollback procedures and integrating them with monitoring, we transform crisis response from a panic-driven scramble into a calm, measured process.

Think of automated rollback as your version control airbag—it deploys automatically when crashes are detected, protecting the system from further damage. Just as modern deployment systems can automatically roll back failed deployments, Git workflows need automated procedures for reverting problematic changes, restoring from known-good states, and recovering from corruption. These procedures must be tested regularly, documented thoroughly, and executable by anyone (or no one, in fully automated cases).

## Rule Definition

Automated rollback procedures must provide multiple strategies for different failure scenarios:

- **Commit-Level Rollback**: Automated reversion of specific commits that introduce problems, with dependency analysis.

- **Time-Based Rollback**: Ability to restore repository state to any point in time, useful for systemic issues.

- **Branch-Level Rollback**: Automated restoration of entire branches to previous states, including force-push scenarios.

- **Binary Search Rollback**: Automated git bisect procedures to identify and revert problematic changes.

- **State Verification**: Automated testing to ensure rollback achieved desired state without introducing new issues.

**Rollback Requirements**:
- One-click or fully automated rollback triggers
- Multiple rollback strategies for different scenarios
- Automated impact analysis before rollback
- Rollback verification and testing
- Audit trail of all rollback operations
- Integration with monitoring and alerting

**Rollback Strategies**:
- Simple revert: Reverse specific commits
- Range revert: Reverse series of commits
- Reset rollback: Force branch to previous state
- Cherry-pick rollback: Selective change removal
- Snapshot restore: Full repository state restoration

## Practical Implementation

1. **Create Automated Revert Pipelines**: Implement one-click revert mechanisms:
   ```yaml
   # GitHub Actions automated rollback workflow
   name: Automated Rollback
   on:
     workflow_dispatch:
       inputs:
         commit_sha:
           description: 'Commit SHA to rollback'
           required: true
         strategy:
           description: 'Rollback strategy'
           type: choice
           options:
             - revert
             - reset
             - bisect

   jobs:
     rollback:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
           with:
             fetch-depth: 0

         - name: Analyze Impact
           run: |
             # Check dependencies on this commit
             git log --oneline --grep="Depends on ${{ inputs.commit_sha }}"

             # Check subsequent changes to same files
             git diff --name-only ${{ inputs.commit_sha }}^ ${{ inputs.commit_sha }} > changed_files
             git log --oneline ${{ inputs.commit_sha }}..HEAD -- $(cat changed_files)

         - name: Execute Rollback
           run: |
             case "${{ inputs.strategy }}" in
               revert)
                 git revert ${{ inputs.commit_sha }} --no-edit
                 ;;
               reset)
                 git reset --hard ${{ inputs.commit_sha }}^
                 ;;
               bisect)
                 git bisect start HEAD ${{ inputs.commit_sha }}^
                 git bisect run npm test
                 BAD_COMMIT=$(git bisect view --oneline | head -1 | cut -d' ' -f1)
                 git bisect reset
                 git revert ${BAD_COMMIT} --no-edit
                 ;;
             esac

         - name: Verify Rollback
           run: |
             npm test
             npm run integration-tests

         - name: Create Rollback PR
           uses: peter-evans/create-pull-request@v5
           with:
             title: "🚨 Automated Rollback of ${{ inputs.commit_sha }}"
             body: |
               ## Automated Rollback

               **Reverted Commit**: ${{ inputs.commit_sha }}
               **Strategy**: ${{ inputs.strategy }}
               **Triggered By**: ${{ github.actor }}

               ### Verification Results
               - ✅ Tests passing
               - ✅ Build successful
               - ✅ No dependent commits found
   ```

2. **Implement Time-Based Recovery**: Enable point-in-time repository restoration:
   ```python
   # Time-based rollback system
   import git
   import datetime
   from typing import Optional

   class GitTimeRollback:
       def __init__(self, repo_path: str):
           self.repo = git.Repo(repo_path)

       def find_commit_at_time(self, target_time: datetime.datetime) -> Optional[str]:
           """Find the commit that was HEAD at specific time."""
           for commit in self.repo.iter_commits('HEAD', max_count=10000):
               if commit.committed_datetime <= target_time:
                   return commit.hexsha
           return None

       def rollback_to_time(self, target_time: datetime.datetime,
                           branch: str = 'main',
                           strategy: str = 'branch') -> dict:
           """Rollback repository to state at specific time."""
           target_commit = self.find_commit_at_time(target_time)

           if not target_commit:
               raise ValueError(f"No commits found before {target_time}")

           # Create rollback branch
           rollback_branch = f"rollback-{branch}-{int(target_time.timestamp())}"
           self.repo.create_head(rollback_branch, target_commit)

           # Verify the rollback state
           self.repo.heads[rollback_branch].checkout()
           verification = self.verify_repository_state()

           result = {
               'target_time': target_time,
               'target_commit': target_commit,
               'rollback_branch': rollback_branch,
               'verification': verification,
               'affected_commits': self.get_affected_commits(target_commit, branch)
           }

           if strategy == 'branch':
               # Update original branch
               self.repo.heads[branch].reference = target_commit
               result['branch_updated'] = True

           return result
   ```

3. **Create Binary Search Rollback**: Automate problematic commit identification:
   ```bash
   #!/bin/bash
   # automated-bisect.sh - Find and revert problematic commits

   set -euo pipefail

   GOOD_COMMIT=${1:-""}
   TEST_COMMAND=${2:-"npm test"}

   if [ -z "$GOOD_COMMIT" ]; then
       echo "Usage: $0 <known-good-commit> [test-command]"
       exit 1
   fi

   echo "Starting automated bisect from $GOOD_COMMIT to HEAD"

   # Start bisect
   git bisect start HEAD "$GOOD_COMMIT"

   # Create test script
   cat > .git/bisect-test.sh << EOF
   #!/bin/bash
   set -e

   # Run build
   npm install --silent
   npm run build

   # Run tests
   $TEST_COMMAND

   # Check for performance regression
   RESPONSE_TIME=\$(npm run perf-test --silent | grep "p95" | cut -d: -f2)
   if (( \$(echo "\$RESPONSE_TIME > 1000" | bc -l) )); then
       echo "Performance regression detected: \$RESPONSE_TIME ms"
       exit 1
   fi

   exit 0
   EOF

   chmod +x .git/bisect-test.sh

   # Run automated bisect
   git bisect run .git/bisect-test.sh

   # Get the bad commit
   BAD_COMMIT=$(git rev-parse refs/bisect/bad)

   echo "Found problematic commit: $BAD_COMMIT"
   git bisect reset

   # Create revert
   git revert "$BAD_COMMIT" --no-edit -m "Automated rollback of $BAD_COMMIT"
   ```

4. **Integrate with Monitoring**: Trigger rollbacks from production metrics:
   ```python
   # Monitoring-triggered rollback
   from prometheus_client import CollectorRegistry, Gauge
   import requests
   import subprocess

   class MonitoringRollbackTrigger:
       def __init__(self, prometheus_url, git_repo_path):
           self.prometheus_url = prometheus_url
           self.git_repo_path = git_repo_path
           self.error_threshold = 0.05  # 5% error rate
           self.latency_threshold = 2000  # 2s p95 latency

       def check_deployment_health(self, deployment_sha: str) -> dict:
           """Check if deployment meets SLOs."""
           # Query error rate
           error_query = f'''
               rate(http_requests_total{{status=~"5..",deployment="{deployment_sha}"}}[5m]) /
               rate(http_requests_total{{deployment="{deployment_sha}"}}[5m])
           '''
           error_rate = self.query_prometheus(error_query)

           # Query latency
           latency_query = f'''
               histogram_quantile(0.95,
                   rate(http_request_duration_seconds_bucket{{deployment="{deployment_sha}"}}[5m])
               )
           '''
           p95_latency = self.query_prometheus(latency_query)

           return {
               'healthy': (error_rate < self.error_threshold and
                          p95_latency < self.latency_threshold),
               'error_rate': error_rate,
               'p95_latency': p95_latency,
               'deployment_sha': deployment_sha
           }

       def trigger_rollback_if_needed(self, deployment_sha: str):
           """Automatically rollback if deployment fails SLOs."""
           health = self.check_deployment_health(deployment_sha)

           if not health['healthy']:
               print(f"🚨 Deployment {deployment_sha} failing SLOs!")
               print(f"Error rate: {health['error_rate']:.2%}")
               print(f"P95 latency: {health['p95_latency']}ms")

               # Trigger automated rollback
               subprocess.run([
                   'git', '-C', self.git_repo_path,
                   'revert', deployment_sha, '--no-edit'
               ])

               # Create emergency PR
               self.create_emergency_rollback_pr(deployment_sha, health)

               return True

           return False
   ```

5. **Test Rollback Procedures**: Regular drills ensure procedures work under pressure:
   ```yaml
   # Rollback drill automation
   name: Weekly Rollback Drill
   on:
     schedule:
       - cron: '0 10 * * 1'  # Every Monday at 10 AM

   jobs:
     rollback-drill:
       runs-on: ubuntu-latest
       steps:
         - name: Create Test Scenario
           run: |
             # Create a "broken" commit
             echo "// Intentional bug for drill" >> src/index.js
             git add src/index.js
             git commit -m "test: Rollback drill commit $(date +%s)"
             DRILL_COMMIT=$(git rev-parse HEAD)
             echo "DRILL_COMMIT=$DRILL_COMMIT" >> $GITHUB_ENV

         - name: Test Automated Rollback
           run: |
             # Trigger rollback workflow
             gh workflow run rollback.yml \
               -f commit_sha=${{ env.DRILL_COMMIT }} \
               -f strategy=revert

         - name: Verify Rollback Success
           run: |
             # Wait for rollback to complete
             sleep 30

             # Verify the commit was reverted
             if git log --oneline | grep -q "Revert.*$DRILL_COMMIT"; then
               echo "✅ Rollback drill successful"
             else
               echo "❌ Rollback drill failed"
               exit 1
             fi
   ```

## Examples

```bash
# ❌ BAD: Manual panic-driven rollback
# "Production is down! Someone revert that last commit!"
# SSH to server...
# git log --oneline  # Which commit was it?
# git revert abc123  # Hope this is the right one
# Merge conflict!  # Now what?
# Call the person who made the commit...

# ✅ GOOD: Automated rollback procedure
# Alert: Error rate spike detected after deployment abc123
# Automated response:
# 1. Rollback triggered by monitoring
# 2. Impact analysis completed
# 3. Revert PR created and auto-merged
# 4. Deployment rolled back
# 5. Incident report generated
# Total time: 90 seconds, zero human intervention
```

```yaml
# ❌ BAD: No rollback testing
rollback_plan:
  strategy: "We'll figure it out if needed"
  last_tested: never
  documentation: "Just git revert the bad commit"

# ✅ GOOD: Tested rollback procedures
rollback_plan:
  strategies:
    - type: monitoring_triggered
      threshold: "5% error rate"
      action: automatic_revert

    - type: time_based
      window: "4 hours"
      action: branch_reset

    - type: bisect_search
      trigger: performance_regression
      action: identify_and_revert

  testing:
    frequency: weekly
    last_drill: "2024-06-20"
    success_rate: "100%"
    avg_time_to_rollback: "87 seconds"
```

```python
# ❌ BAD: Complex manual rollback
def panic_rollback():
    # Figure out what went wrong
    # Find the right commits
    # Manually revert each one
    # Hope we didn't miss anything
    # Test... hopefully
    pass

# ✅ GOOD: Systematic rollback options
class RollbackSystem:
    def simple_revert(self, commit_sha):
        """Single problematic commit"""
        return self.execute_rollback('revert', commit_sha)

    def time_machine(self, when):
        """Everything after timestamp"""
        return self.execute_rollback('time_based', when)

    def smart_bisect(self, good_sha, test_cmd):
        """Find problem automatically"""
        return self.execute_rollback('bisect', good_sha, test_cmd)

    def emergency_reset(self, safe_sha):
        """Nuclear option - full reset"""
        return self.execute_rollback('reset', safe_sha)
```

## Related Bindings

- [git-monitoring-metrics.md](git-monitoring-metrics.md): Monitoring metrics trigger automated rollbacks based on SLO violations. Error rates, latency spikes, and other indicators can initiate rollback procedures without human intervention.

- [git-backup-strategy.md](git-backup-strategy.md): Backup strategies provide the foundation for rollback capabilities. Point-in-time backups enable restoration to any previous state when simple reverts aren't sufficient.

- [feature-flag-driven-development.md](feature-flag-driven-development.md): Feature flags provide instant rollback without Git operations. Combining feature flags with Git rollback gives multiple layers of recovery options.

- [atomic-commits.md](atomic-commits.md): Atomic commits make rollbacks predictable and safe. When each commit is self-contained, reverting doesn't create cascading failures or break dependencies.

- [ci-cd-pipeline-standards.md](../../core/ci-cd-pipeline-standards.md): Rollback procedures must integrate with CI/CD pipelines to ensure reverted code is properly built, tested, and deployed through standard processes.
