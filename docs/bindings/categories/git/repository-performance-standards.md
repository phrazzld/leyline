---
id: repository-performance-standards
last_modified: '2025-06-24'
version: '0.2.0'
derived_from: content-addressable-history
enforced_by: 'git configuration, CI/CD validation, monitoring tools'
---
# Binding: Maintain Repository Performance Standards

Configure and maintain Git repositories for optimal performance through systematic application of Git's performance features, appropriate configuration tuning, and architectural decisions that scale efficiently.

## Rationale

Git's performance characteristics change dramatically with repository size, history length, and usage patterns. A repository that performs well with 1,000 commits and 10 developers can become unusable at 100,000 commits and 100 developers without proper configuration and maintenance. This binding establishes standards that keep repositories performant at scale.

From a systems perspective, Git performance bottlenecks fall into several categories: object enumeration (walking the DAG), delta compression (pack file generation), network transfer (clone/fetch operations), and working directory operations (checkout/status). Each requires different optimization strategies.

The key insight is that Git provides powerful performance features, but they're not always enabled by default for backward compatibility. Modern Git versions include commit-graph files, multi-pack indexes, partial clone, and sparse checkout—features that can improve performance by orders of magnitude when properly configured.

Performance isn't just about speed—it's about developer productivity. A slow `git status` breaks flow. A 30-minute clone blocks onboarding. A sluggish `git log` impedes debugging. By maintaining performance standards, we preserve Git's promise of fast, local operations even as repositories grow.

## Rule Definition

**Performance Standards and Thresholds:**

- **Clone Time**: Full clone must complete in under 5 minutes on standard developer hardware
- **Status Check**: `git status` must return in under 2 seconds
- **Log Operations**: `git log` with default options must start streaming in under 1 second
- **Fetch Time**: Daily fetch operations must complete in under 30 seconds
- **Pack Size**: Repository size after aggressive packing should not exceed 1GB without justification

**Required Optimizations:**
- Enable commit-graph and maintain it automatically
- Configure appropriate gc settings for repository size
- Implement partial clone for large repositories
- Use sparse-checkout for monorepos
- Separate large binaries via Git LFS

**Monitoring Requirements:**
- Track repository size growth weekly
- Monitor clone/fetch times in CI
- Alert on performance degradation
- Regular maintenance windows for optimization

## Practical Implementation

**Core Performance Configuration:**

```bash
# Enable commit-graph for faster graph operations
git config core.commitGraph true
git config gc.writeCommitGraph true

# Optimize pack settings for performance
git config pack.useBitmaps true
git config pack.writeBitmapHashCache true
git config pack.threads 0  # Use all CPU cores

# Tune garbage collection for large repos
git config gc.auto 6700  # Increase threshold
git config gc.autoPackLimit 50
git config gc.bigPackThreshold 200m

# Enable multi-pack index for better performance
git config core.multiPackIndex true

# Configure delta compression window
git config pack.window 250  # Higher = better compression, slower
git config pack.depth 50

# Enable filesystem monitor (if available)
git config core.fsmonitor true
```

**Repository Maintenance Script:**

```bash
#!/bin/bash
# git-maintenance.sh - Regular maintenance for performance

echo "🔧 Starting Git repository maintenance..."

# Update commit-graph
echo "📊 Updating commit-graph..."
git commit-graph write --reachable --changed-paths

# Repack with optimal settings
echo "📦 Repacking repository..."
git repack -a -d -f --depth=250 --window=250

# Write bitmap index
echo "🗺️ Writing bitmap index..."
git repack -b

# Prune old objects
echo "✂️ Pruning unreachable objects..."
git prune --expire=2.weeks.ago

# Update multi-pack index
echo "📑 Updating multi-pack index..."
git multi-pack-index write

# Clean up redundant packs
echo "🧹 Cleaning redundant packs..."
git multi-pack-index expire
git multi-pack-index repack

echo "✅ Maintenance complete!"

# Report statistics
echo "📈 Repository Statistics:"
git count-objects -v
du -sh .git
```

**Partial Clone Configuration (for large repositories):**

```bash
# Clone with blob filtering
git clone --filter=blob:none <url>

# Configure partial clone
git config remote.origin.promisor true
git config remote.origin.partialclonefilter blob:none

# Fetch only needed blobs on demand
git config core.repositoryFormatVersion 1
git config extensions.partialClone origin
```

**Sparse Checkout for Monorepos:**

```bash
# Enable sparse checkout
git sparse-checkout init --cone

# Configure paths to include
git sparse-checkout set src/frontend docs

# Add more paths as needed
git sparse-checkout add src/shared

# List current sparse paths
git sparse-checkout list
```

**Git LFS for Binary Assets:**

```bash
# Track large files with LFS
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "assets/videos/*"

# Migrate existing files to LFS
git lfs migrate import --include="*.psd,*.zip"

# Configure LFS batch size for performance
git config lfs.concurrenttransfers 8
git config lfs.batch true
```

**Performance Monitoring GitHub Action:**

```yaml
name: Repository Performance Check
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly
  workflow_dispatch:

jobs:
  performance-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Measure repository size
        run: |
          REPO_SIZE=$(du -sh .git | cut -f1)
          echo "Repository size: $REPO_SIZE"
          echo "REPO_SIZE=$REPO_SIZE" >> $GITHUB_ENV

      - name: Measure operation performance
        run: |
          # Time git status
          STATUS_TIME=$(( time git status >/dev/null ) 2>&1 | grep real | awk '{print $2}')
          echo "Git status time: $STATUS_TIME"

          # Time git log
          LOG_TIME=$(( time git log --oneline -n 1000 >/dev/null ) 2>&1 | grep real | awk '{print $2}')
          echo "Git log time: $LOG_TIME"

          # Count objects
          git count-objects -v

      - name: Check commit-graph
        run: |
          if [ -f .git/objects/info/commit-graph ]; then
            echo "✅ Commit-graph exists"
            git commit-graph verify
          else
            echo "❌ No commit-graph found"
            exit 1
          fi

      - name: Alert on performance issues
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Repository Performance Degradation Detected',
              body: 'Weekly performance check failed. See workflow run for details.'
            })
```

## Performance Benchmarks

**Impact of Optimizations:**

```bash
# Before optimization (100k commits, 50k files)
git status: 8.3s
git log --oneline: 4.2s
git blame large-file.js: 12.1s
Clone size: 2.8 GB

# After optimization
git status: 0.8s (90% improvement)
git log --oneline: 0.3s (93% improvement)
git blame large-file.js: 1.2s (90% improvement)
Clone size: 890 MB (68% reduction)
```

## Repository Architecture Guidelines

**1. Repository Sizing:**
- Keep repositories under 1GB when possible
- Split mega-repositories into focused repos
- Use submodules for optional dependencies

**2. History Management:**
- Archive old history beyond 2 years if needed
- Use shallow clones for CI (--depth=1)
- Implement history rewriting for cleanup (carefully!)

**3. Binary File Strategy:**
- Use Git LFS for files over 10MB
- Store build artifacts externally
- Version control source, not generated files

## Related Bindings

- [linear-history-optimization](./linear-history-optimization.md): Linear history improves performance by simplifying graph traversal operations.

- [atomic-commits](./atomic-commits.md): Well-structured commits improve delta compression efficiency.

- [commit-graph-optimization](./commit-graph-optimization.md): Detailed guidance on leveraging Git's commit-graph feature for performance.

- [version-control-workflows](../../docs/bindings/core/version-control-workflows.md): Workflow patterns that maintain repository performance at scale.

- [development-environment-consistency](../../docs/bindings/core/development-environment-consistency.md): Ensures all developers have optimized Git configurations.
