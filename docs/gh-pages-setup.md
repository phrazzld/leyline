# GitHub Pages Setup

This document explains how the GitHub Pages documentation site for Leyline is set up and deployed.

## Overview

The Leyline documentation site is built using [MkDocs](https://www.mkdocs.org/) with the [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme and deployed to GitHub Pages.

## Enabling GitHub Pages (Required after pushing to GitHub)

After pushing this repository to GitHub, you need to:

1. Wait for the GitHub Actions workflow to run

   - The workflow will create a `gh-pages` branch
   - The site will be built and pushed to this branch

1. Enable GitHub Pages in repository settings:

   - Go to the repository on GitHub
   - Navigate to Settings > Pages
   - Under "Source", select "Deploy from a branch"
   - Under "Branch", select "gh-pages" and "/ (root)"
   - Click "Save"

1. After a few minutes, the site will be available at:
   https://phrazzld.github.io/leyline/

Until these steps are completed, the site will show a 404 error.

## Structure

- Documentation source files are in the `docs/` directory
- Tenets and bindings in their respective directories are included in the documentation
- Configuration is defined in `mkdocs.yml` at the repository root

## Deployment

The documentation site is automatically deployed to GitHub Pages whenever changes are pushed to the `master` branch:

1. The GitHub Action workflow (`.github/workflows/gh-pages.yml`) is triggered
1. The workflow builds the site using MkDocs
1. The built site is deployed to the `gh-pages` branch
1. GitHub Pages serves the content from the `gh-pages` branch

## Local Development

To work on the documentation locally:

1. Install MkDocs and the Material theme:

   ```bash
   pip install mkdocs mkdocs-material
   ```

1. Run the local development server:

   ```bash
   mkdocs serve
   ```

1. Open `http://127.0.0.1:8000/` in your browser

1. Make changes to the documentation and see them instantly

## Configuration

The site configuration is defined in `mkdocs.yml` and includes:

- Site metadata (name, description, author)
- Navigation structure
- Theme configuration
- Markdown extensions
- Plugins

## Adding New Content

New documentation pages can be added by:

1. Creating Markdown files in the `docs/` directory
1. Updating the navigation in `mkdocs.yml` if needed

The documentation site automatically includes all tenets and bindings from their respective directories.
