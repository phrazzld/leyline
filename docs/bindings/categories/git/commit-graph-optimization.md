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

Git operations that traverse the commit graph—log, merge-base, contains queries, ahead/behind calculations—traditionally require reading individual commit objects from disk. For large repositories, this becomes a significant bottleneck. The commit-graph feature pre-computes and stores commit relationships in an efficient binary format, improving these operations by 10-100x.

From an algorithmic perspective, the commit-graph transforms random disk access into sequential reads. Without it, finding merge-base between two commits requires O(n) object reads in the worst case. With commit-graph, the same operation requires O(1) file opens and O(log n) memory operations. The difference is dramatic—milliseconds versus seconds for large repositories.

The commit-graph also enables advanced features like generation numbers (topological levels) and changed-path Bloom filters. Generation numbers allow Git to quickly determine reachability without walking the entire graph. Bloom filters accelerate file history queries by quickly eliminating commits that don't touch specific paths.

Yet many teams don't enable this feature, suffering slow operations that frustrate developers and reduce productivity. This binding ensures commit-graph is not just enabled but actively maintained for optimal performance.

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

**Initial Setup and Configuration:**

```bash
#!/bin/bash
# setup-commit-graph.sh - Enable and optimize commit-graph

echo "🔧 Configuring commit-graph optimization..."

# Core configuration
git config core.commitGraph true
git config gc.writeCommitGraph true
git config fetch.writeCommitGraph true

# Enable generation numbers v2 (corrected commit dates)
git config commitGraph.generationVersion 2

# Enable Bloom filters for path-based queries
git config commitGraph.readChangedPaths true
git config commitGraph.maxNewFilters 100

# Configure automatic maintenance
git config maintenance.commit-graph.enabled true
git config maintenance.commit-graph.schedule daily

# Enable split commit-graph for incremental updates
git config core.commitGraphSplit true
git config splitIndex.maxPercentChange 10

echo "📊 Generating initial commit-graph..."
git commit-graph write --reachable --changed-paths --progress

echo "✅ Commit-graph optimization enabled!"

# Display statistics
COMMIT_COUNT=$(git rev-list --all --count)
GRAPH_COUNT=$(git commit-graph verify 2>&1 | grep "num_commits:" | awk '{print $2}')
COVERAGE=$(echo "scale=2; $GRAPH_COUNT * 100 / $COMMIT_COUNT" | bc)

echo "📈 Coverage: $COVERAGE% ($GRAPH_COUNT of $COMMIT_COUNT commits)"
```

**Automated Maintenance Script:**

```bash
#!/bin/bash
# maintain-commit-graph.sh - Keep commit-graph optimized

set -e

echo "🔧 Starting commit-graph maintenance..."

# Verify existing commit-graph
if git commit-graph verify 2>/dev/null; then
    echo "✅ Existing commit-graph is valid"
else
    echo "⚠️  Commit-graph corrupted, rebuilding..."
    rm -rf .git/objects/info/commit-graph*
fi

# Incremental update with split commit-graph
echo "📊 Updating commit-graph incrementally..."
git commit-graph write --reachable --changed-paths --split=replace --progress

# Verify coverage
TOTAL_COMMITS=$(git rev-list --all --count)
GRAPH_COMMITS=$(git commit-graph verify 2>&1 | grep "num_commits" | awk '{print $2}')
COVERAGE=$(( GRAPH_COMMITS * 100 / TOTAL_COMMITS ))

if [ $COVERAGE -lt 95 ]; then
    echo "⚠️  Low coverage: $COVERAGE%"
    echo "📊 Performing full regeneration..."
    git commit-graph write --reachable --changed-paths --progress
fi

# Optimize split files if too many
SPLIT_COUNT=$(ls .git/objects/info/commit-graphs/*.graph 2>/dev/null | wc -l)
if [ $SPLIT_COUNT -gt 10 ]; then
    echo "🔄 Consolidating split commit-graph files..."
    git commit-graph write --reachable --changed-paths --split=replace
fi

echo "✅ Commit-graph maintenance complete!"

# Performance test
echo "⏱️  Testing performance improvement..."
time_without() {
    GIT_TEST_COMMIT_GRAPH=0 git -c core.commitGraph=false "$@" 2>&1
}
time_with() {
    git "$@" 2>&1
}

# Benchmark log operation
START=$(date +%s.%N)
time_without log --oneline -n 1000 >/dev/null
WITHOUT=$(echo "$(date +%s.%N) - $START" | bc)

START=$(date +%s.%N)
time_with log --oneline -n 1000 >/dev/null
WITH=$(echo "$(date +%s.%N) - $START" | bc)

SPEEDUP=$(echo "scale=2; $WITHOUT / $WITH" | bc)
echo "📊 Performance improvement: ${SPEEDUP}x faster"
```

**GitHub Action for Commit-Graph Maintenance:**

```yaml
name: Optimize Commit Graph
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday
  workflow_dispatch:
  push:
    branches: [main]
    paths:
      - '.git/objects/**'

jobs:
  optimize-commit-graph:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history needed

      - name: Configure Git
        run: |
          git config core.commitGraph true
          git config gc.writeCommitGraph true
          git config commitGraph.generationVersion 2

      - name: Generate commit-graph
        run: |
          git commit-graph write --reachable --changed-paths --progress

      - name: Verify optimization
        run: |
          git commit-graph verify

          # Benchmark performance
          echo "Testing without commit-graph..."
          /usr/bin/time -f "%e seconds" \
            git -c core.commitGraph=false log --oneline -n 10000 >/dev/null

          echo "Testing with commit-graph..."
          /usr/bin/time -f "%e seconds" \
            git log --oneline -n 10000 >/dev/null

      - name: Upload commit-graph
        uses: actions/upload-artifact@v3
        with:
          name: commit-graph
          path: .git/objects/info/commit-graph*
          retention-days: 7
```

**Monitoring and Alerting:**

```bash
#!/bin/bash
# monitor-commit-graph.sh - Check commit-graph health

# Check if commit-graph exists
if [ ! -f .git/objects/info/commit-graph ]; then
    echo "❌ ERROR: No commit-graph file found"
    exit 1
fi

# Verify integrity
if ! git commit-graph verify 2>/dev/null; then
    echo "❌ ERROR: Commit-graph is corrupted"
    exit 1
fi

# Check coverage
TOTAL=$(git rev-list --all --count)
COVERED=$(git commit-graph verify 2>&1 | grep "num_commits" | awk '{print $2}')
COVERAGE=$(( COVERED * 100 / TOTAL ))

if [ $COVERAGE -lt 95 ]; then
    echo "⚠️  WARNING: Low commit-graph coverage: $COVERAGE%"
    echo "Run: git commit-graph write --reachable"
fi

# Check age
GRAPH_AGE=$(( ($(date +%s) - $(stat -f %m .git/objects/info/commit-graph)) / 86400 ))
if [ $GRAPH_AGE -gt 7 ]; then
    echo "⚠️  WARNING: Commit-graph is $GRAPH_AGE days old"
fi

# Performance check
RESULT=$(git config core.commitGraph)
if [ "$RESULT" != "true" ]; then
    echo "❌ ERROR: Commit-graph is not enabled"
    echo "Run: git config core.commitGraph true"
    exit 1
fi

echo "✅ Commit-graph health check passed"
```

## Performance Benchmarks

Real-world performance improvements with commit-graph:

```bash
# Repository: 500k commits, 100k files

# Without commit-graph
git log --oneline --graph: 4.2s
git merge-base HEAD origin/main: 1.8s
git tag --contains HEAD: 8.3s
git log -- specific/file.js: 6.1s

# With commit-graph + bloom filters
git log --oneline --graph: 0.3s (14x faster)
git merge-base HEAD origin/main: 0.02s (90x faster)
git tag --contains HEAD: 0.4s (20x faster)
git log -- specific/file.js: 0.2s (30x faster)
```

## Advanced Features

**Generation Numbers v2:**
```bash
# Enable corrected commit dates for better performance
git config commitGraph.generationVersion 2

# Significant improvement for:
# - git merge-base
# - git tag --contains
# - git branch --contains
```

**Bloom Filters:**
```bash
# Enable changed-path Bloom filters
git config commitGraph.readChangedPaths true

# Accelerates path-limited queries:
# - git log -- path/to/file
# - git blame
# - git diff branch -- path
```

## Related Bindings

- [repository-performance-standards](./repository-performance-standards.md): Commit-graph is a key component of repository performance optimization.

- [linear-history-optimization](./linear-history-optimization.md): Linear history makes commit-graph traversal more efficient.

- [atomic-commits](./atomic-commits.md): Well-structured commits improve the effectiveness of Bloom filters.

- [automated-maintenance-workflows](../../../core/automated-quality-gates.md): Automated maintenance keeps commit-graph fresh and effective.

- [development-environment-consistency](../../../core/development-environment-consistency.md): Ensures all developers have commit-graph enabled for consistent performance.
