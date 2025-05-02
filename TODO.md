# Leyline Implementation TODOs

## Repository Setup
- [ ] Create the actual GitHub repository `phrazzld/leyline`
- [ ] Set up branch protection rules (require reviews, status checks, linear history)
- [ ] Create v0.1.0 initial tag after content is finalized

## Deployment
- [ ] Enable GitHub Pages for the static site (point to gh-pages branch)
- [ ] Configure GitHub Actions permissions for cross-repo operations

## Integration & Testing
- [ ] Test Warden workflow with a pilot repository
- [ ] Populate targets.txt with consumer repositories
- [ ] Create example vendor-docs.yml for consumer repositories
- [ ] Set up cross-repo automation for bulk PR creation

## Consumer Repository Migration
- [ ] Remove legacy symlinks from consumer repositories
- [ ] Add GitHub workflow caller to each consumer repository
- [ ] Add pre-commit/husky hooks for vendor-check in consumer repositories
- [ ] Verify CI passes in all consumer repositories after migration

## Legacy Cleanup
- [ ] Create DEPRECATED_SYMLINKS.md in the old dotfiles repository
- [ ] Implement custom linter rule to forbid external symlinks
- [ ] Prune orphan branches referencing old symlinks

## Governance
- [x] Create a CONTRIBUTING.md file with guidelines for proposing new tenets/bindings
- [x] Set up GitHub repository labels for tenet/binding PRs
- [ ] Add contributing team members to core-maintainers team

## Documentation
- [ ] Document migration process for new repositories
- [ ] Create README.md with overview and purpose
- [ ] Update PLAN.md to reflect actual implementation choices