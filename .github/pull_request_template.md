## Description

Brief description of the changes and their purpose.

## Type of Change

- [ ] New tenet
- [ ] New binding
- [ ] Documentation update
- [ ] Bug fix
- [ ] Tool/infrastructure change

## Checklist

### Content Quality
- [ ] Document follows the [Natural Language Style Guide](docs/STYLE_GUIDE_NATURAL_LANGUAGE.md)
- [ ] Content is principle-focused rather than implementation-focused
- [ ] Writing is clear, concise, and accessible to diverse technical backgrounds

### Document Conciseness
- [ ] **Tenet documents are ≤150 lines** (enforced by pre-commit hooks)
- [ ] **Binding documents are ≤400 lines** (enforced by pre-commit hooks)
- [ ] Follows the "one example rule" - shows patterns once, not multiple times
- [ ] Reviewed against [Conciseness Guide](docs/CONCISENESS_GUIDE.md) principles

### Technical Requirements
- [ ] YAML front-matter is properly formatted and includes all required fields
- [ ] All code examples are syntactically correct and compile/execute successfully
- [ ] Cross-references use correct relative paths and resolve properly
- [ ] Pre-commit hooks pass locally (`pre-commit run --all-files`)

### Integration
- [ ] Changes integrate properly with existing leyline content
- [ ] No content duplication with existing tenets or bindings
- [ ] Related documents are updated with appropriate cross-references
- [ ] Index files will regenerate correctly with new content

## Validation Results

- [ ] `ruby tools/validate_front_matter.rb` passes without errors
- [ ] `ruby tools/reindex.rb --strict` completes successfully
- [ ] Document length validation passes (if applicable)

## Additional Context

Add any other context about the pull request here.
