---
id: commit-graph-optimization
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: content-addressable-history
enforced_by: 'git configuration, automated maintenance, CI/CD pipelines'
---
# Binding: Optimize Commit Graph Performance

Enable and maintain Git's commit-graph feature to dramatically improve performance of graph traversal operations. Keep the commit-graph file updated automatically to ensure consistent performance as the repository grows.

## Rationale

Git operations traversing the commit graph—log, merge-base, contains queries—traditionally require reading individual commit objects from disk. Commit-graph pre-computes relationships in binary format, improving operations by 10-100x.

Commit-graph transforms random disk access into sequential reads. Finding merge-base changes from O(n) object reads to O(1) file opens and O(log n) memory operations. Generation numbers enable quick reachability checks; Bloom filters accelerate file history queries.

## Rule Definition

**Commit-Graph Requirements:**

- **Enable Core Features**: Configure Git to write and use commit-graph files automatically
- **Maintain Freshness**: Update commit-graph after significant operations
- **Enable Optimizations**: Activate generation numbers and Bloom filters
- **Monitor Coverage**: Ensure >95% of commits are covered by commit-graph
- **Incremental Updates**: Use split commit-graph for efficient updates

**Configuration Standards:**
```bash
# Required settings
core.commitGraph = true
gc.writeCommitGraph = true
commitGraph.generationVersion = 2
commitGraph.maxNewFilters = 100

# Performance settings
fetch.writeCommitGraph = true
maintenance.commit-graph.enabled = true
maintenance.incremental-repack.enabled = true
```

**Maintenance Schedule:**
- Automatic update on gc operations
- Incremental updates on fetch
- Full regeneration weekly
- Verification before major operations

## Practical Implementation

**Setup:**

```bash
# Core configuration
git config core.commitGraph true
git config gc.writeCommitGraph true
git config commitGraph.generationVersion 2
git config commitGraph.readChangedPaths true
git config maintenance.commit-graph.enabled true

# Generate initial commit-graph
git commit-graph write --reachable --changed-paths --progress

# Check coverage
COMMIT_COUNT=$(git rev-list --all --count)
GRAPH_COUNT=$(git commit-graph verify 2>&1 | grep "num_commits:" | awk '{print $2}')
echo "Coverage: $(( GRAPH_COUNT * 100 / COMMIT_COUNT ))%"
```

**Maintenance:**

```bash
#!/bin/bash
# Verify and update commit-graph
git commit-graph verify 2>/dev/null || rm -rf .git/objects/info/commit-graph*

# Incremental update
git commit-graph write --reachable --changed-paths --split=replace --progress

# Check coverage
TOTAL=$(git rev-list --all --count)
COVERED=$(git commit-graph verify 2>&1 | grep "num_commits" | awk '{print $2}')
COVERAGE=$(( COVERED * 100 / TOTAL ))

# Full rebuild if coverage low
[[ $COVERAGE -lt 95 ]] && git commit-graph write --reachable --changed-paths --progress

# Consolidate if too many splits
SPLIT_COUNT=$(ls .git/objects/info/commit-graphs/*.graph 2>/dev/null | wc -l)
[[ $SPLIT_COUNT -gt 10 ]] && git commit-graph write --reachable --changed-paths --split=replace
```

**GitHub Action:**

```yaml
name: Optimize Commit Graph
on:
  schedule: [cron: '0 2 * * 0']  # Weekly
  workflow_dispatch:

jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with: {fetch-depth: 0}
      - name: Generate commit-graph
        run: |
          git config core.commitGraph true
          git config commitGraph.generationVersion 2
          git commit-graph write --reachable --changed-paths --progress
          git commit-graph verify
```

**Monitoring:**

```bash
#!/bin/bash
# Health checks
[[ ! -f .git/objects/info/commit-graph ]] && echo "ERROR: Missing commit-graph" && exit 1
git commit-graph verify 2>/dev/null || { echo "ERROR: Corrupted commit-graph"; exit 1; }

# Coverage check
TOTAL=$(git rev-list --all --count)
COVERED=$(git commit-graph verify 2>&1 | grep "num_commits" | awk '{print $2}')
COVERAGE=$(( COVERED * 100 / TOTAL ))
[[ $COVERAGE -lt 95 ]] && echo "WARNING: Low coverage: $COVERAGE%"

# Age check
GRAPH_AGE=$(( ($(date +%s) - $(stat -f %m .git/objects/info/commit-graph)) / 86400 ))
[[ $GRAPH_AGE -gt 7 ]] && echo "WARNING: Commit-graph is $GRAPH_AGE days old"

echo "Health check passed"
```

## Performance Benchmarks

| Operation | Without | With | Improvement |
|---|---|---|---|
| `git log --graph` | 4.2s | 0.3s | 14x faster |
| `git merge-base` | 1.8s | 0.02s | 90x faster |
| `git tag --contains` | 8.3s | 0.4s | 20x faster |
| `git log -- file` | 6.1s | 0.2s | 30x faster |

## Advanced Features

**Generation Numbers v2:** `commitGraph.generationVersion 2` - improves merge-base, tag/branch --contains

**Bloom Filters:** `commitGraph.readChangedPaths true` - accelerates path-limited queries (log, blame, diff)

## Related Bindings

- [repository-performance-standards](./repository-performance-standards.md): Commit-graph is a key component of repository performance optimization.

- [linear-history-optimization](./linear-history-optimization.md): Linear history makes commit-graph traversal more efficient.

- [atomic-commits](./atomic-commits.md): Well-structured commits improve the effectiveness of Bloom filters.

- [automated-maintenance-workflows](../../../core/automated-quality-gates.md): Automated maintenance keeps commit-graph fresh and effective.

- [development-environment-consistency](../../../core/development-environment-consistency.md): Ensures all developers have commit-graph enabled for consistent performance.
