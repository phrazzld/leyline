---
id: git-monitoring-metrics
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-reliability-engineering
enforced_by: 'monitoring systems, metrics dashboards, alerting rules, SLO tracking'
---

# Binding: Monitor Git Operations as Production Services

Implement comprehensive monitoring for Git operations, treating version control performance and reliability as critical production metrics. Track SLIs, define SLOs, and create actionable alerts that prevent Git from becoming a hidden bottleneck in development velocity.

## Rationale

Git operations remain unmeasured despite critical impact on developer productivity. Slow clones or frequent conflicts waste more engineering hours than many production incidents, yet go undetected until developers complain.

Monitoring Git like a production service transforms version control into a measured, optimized system. Track metrics that matter: clone times, push success rates, conflict frequency. Metrics become a shared language for Git performance discussions, replacing vague complaints with specific data.

## Rule Definition

Git monitoring must treat version control as a tier-1 service with comprehensive observability:

- **Performance Metrics**: Track operation latency for clone, fetch, push, and pull operations at percentile levels (p50, p95, p99).

- **Reliability Metrics**: Monitor success rates, error types, and retry patterns for all Git operations.

- **Scale Metrics**: Track repository growth, object count, and pack file efficiency to prevent performance degradation.

- **Workflow Metrics**: Measure merge conflict rates, rebase complexity, and branch lifetime to optimize team processes.

- **Infrastructure Metrics**: Monitor Git server CPU, memory, disk I/O, and network bandwidth to prevent resource exhaustion.

**Core Metrics to Track**:
- Operation latency (clone, fetch, push, pull)
- Operation success/failure rates
- Repository size and growth rate
- Active branch count and age
- Merge conflict frequency and resolution time
- Git protocol bandwidth usage
- Server resource utilization
- Backup success rates and duration

**SLO Examples**:
- 95% of clones complete in < 60 seconds
- 99% of pushes succeed without retry
- Merge conflicts affect < 5% of PRs
- Repository growth < 10% per month

## Practical Implementation

1. **Instrument Git Operations**:
   ```python
   from prometheus_client import Histogram, Counter, Gauge
   import time, subprocess

   git_operation_duration = Histogram('git_operation_duration_seconds', 'Duration of Git operations', ['operation', 'repository', 'result'])
   git_operation_total = Counter('git_operation_total', 'Total Git operations', ['operation', 'repository', 'result'])
   repository_size_bytes = Gauge('git_repository_size_bytes', 'Size of Git repository', ['repository'])

   def track_git_operation(operation, repository, command):
       start = time.time()
       try:
           result = subprocess.run(command, capture_output=True, check=True)
           status = 'success'
       except subprocess.CalledProcessError as e:
           status, result = 'failure', e
       finally:
           duration = time.time() - start
           git_operation_duration.labels(operation, repository, status).observe(duration)
           git_operation_total.labels(operation, repository, status).inc()
       return result
   ```

2. **Git Performance Dashboards**:
   ```json
   {
     "panels": [
       {"title": "Clone Time (p95)", "expr": "histogram_quantile(0.95, git_operation_duration_seconds{operation='clone'})"},
       {"title": "Push Success Rate", "expr": "rate(git_operation_total{operation='push',result='success'}[5m]) / rate(git_operation_total{operation='push'}[5m])"},
       {"title": "Repository Growth", "expr": "rate(git_repository_size_bytes[1d])"},
       {"title": "Conflict Rate", "expr": "rate(git_merge_conflicts_total[1h]) / rate(git_merge_attempts_total[1h])"}
     ]
   }
   ```

3. **SLO-Based Alerts**:
   ```yaml
   groups:
   - name: git_slo_alerts
     rules:
     - alert: GitCloneSLOViolation
       expr: histogram_quantile(0.95, rate(git_operation_duration_seconds_bucket{operation="clone"}[5m])) > 60
       for: 10m
       annotations: {summary: "Git clone p95 latency {{ $value }}s (SLO: <60s)"}
     - alert: GitPushFailureRate
       expr: rate(git_operation_total{operation="push",result="failure"}[5m]) / rate(git_operation_total{operation="push"}[5m]) > 0.01
       for: 5m
       annotations: {summary: "Git push failure rate {{ $value | humanizePercentage }}"}
     - alert: GitRepositoryGrowth
       expr: rate(git_repository_size_bytes[1d]) / git_repository_size_bytes > 0.1
       for: 1h
       annotations: {summary: "Repository {{ $labels.repository }} growing >10% daily"}
   ```

4. **Workflow Metrics**:
   ```sql
   CREATE VIEW git_workflow_metrics AS
   SELECT DATE_TRUNC('week', created_at) as week,
          COUNT(DISTINCT pull_request_id) as total_prs,
          AVG(CASE WHEN has_conflict THEN 1 ELSE 0 END) as conflict_rate,
          AVG(EXTRACT(EPOCH FROM (merged_at - created_at))/3600) as avg_pr_lifetime_hours
   FROM pull_requests WHERE created_at > NOW() - INTERVAL '90 days'
   GROUP BY week ORDER BY week DESC;
   ```

5. **Continuous Optimization**:
   ```python
   def optimize_repository(repo_path, metrics):
       optimizations = []
       if metrics['loose_objects'] > 10000:
           subprocess.run(['git', 'gc', '--aggressive'], cwd=repo_path)
           optimizations.append('aggressive_gc')
       if metrics['repository_size'] > 5_000_000_000:  # 5GB
           optimizations.append('partial_clone_recommended')
       if find_large_files(repo_path, 100_000_000):  # 100MB+
           optimizations.append('lfs_migration_recommended')
       return optimizations
   ```

## Examples

```yaml
# ❌ BAD: No Git monitoring, reactive fixes
# ✅ GOOD: Comprehensive observability
metrics:
  git_clone_duration_p95: {value: 45s, slo: <60s, status: healthy}
  git_push_success_rate: {value: 99.7%, slo: >99%, status: healthy}
  merge_conflict_rate: {value: 3.2%, slo: <5%, status: healthy}

alerts:
  - Clone performance degrading (p95: 45s → 52s over 7d)
  - Repository growth rate high (15% this week)
```

```bash
# ❌ BAD: Manual checking - "Seems slow, oh well"
# ✅ GOOD: Every operation tracked, alerts triggered
git clone https://git.company.com/main-app
# Metrics: duration=151s, size=2.3GB, objects=1.2M
# Alert: Clone time exceeds SLO
```

## Related Bindings

- [git-backup-strategy.md](git-backup-strategy.md): Track backup success rates and duration as reliability indicators
- [automated-rollback-procedures.md](automated-rollback-procedures.md): Metrics inform rollback decisions
- [distributed-conflict-resolution.md](distributed-conflict-resolution.md): Conflict metrics identify patterns and hotspots
- [use-structured-logging.md](../../core/use-structured-logging.md): Structured logging enables detailed analysis
- [quality-metrics-and-monitoring.md](../../core/quality-metrics-and-monitoring.md): Git metrics provide development velocity insights
