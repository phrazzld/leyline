# Leyline CLI Sync Now Available

**Date:** June 20, 2025

We're excited to announce the release of the Leyline CLI sync command, providing a simple and direct way to sync development standards to your projects.

## What's New

The new `leyline sync` command offers:

- **Direct syncing** - No workflow files or automation needed
- **Explicit category selection** - You control exactly what gets synced
- **Smart conflict detection** - Preserves your local modifications by default
- **Force mode** - Override local changes when needed
- **Clear feedback** - See exactly what was copied or skipped

## Getting Started

```bash
# Install the gem
gem install leyline

# Sync TypeScript standards to docs/leyline/
leyline sync --categories typescript

# Sync multiple categories
leyline sync --categories go,rust,web

# See detailed output
leyline sync --categories typescript --verbose
```

## Design Philosophy

Following John Carmack's approach: we built the simplest thing that works. No auto-detection magic, no complex UI, no unnecessary features. You tell it what categories you want, it syncs them. That's it.

## Feedback Welcome

This is the minimal viable implementation. We'll add features based on real user needs, not speculation. Please share your experience and suggestions via GitHub issues.

## Migration from Workflow

If you're currently using the GitHub Actions workflow, you can continue using it or switch to the CLI for more direct control. Both methods are fully supported.
