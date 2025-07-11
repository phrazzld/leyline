---
derived_from: maintainability
enforced_by: team standards & reviews
id: ruby-team-collaboration
last_modified: '2025-07-01'
version: '0.2.0'
---
# Binding: Ruby Team Collaboration

Establish workflow standards for effective Ruby team development.

## Rules

- **Code review** required for all changes
- **Conventional commits** with clear descriptions
- **YARD documentation** for public APIs
- **Shared RuboCop config** across projects
- **README** with setup and development instructions

## Examples

```ruby
# ✅ GOOD: YARD documentation
class UserService
  # Creates a new user account with email verification
  #
  # @param email [String] valid email address
  # @param name [String] user's full name
  # @param notify [Boolean] whether to send welcome email
  # @return [User] the created user
  # @raise [ValidationError] if email already exists
  def create_user(email:, name:, notify: true)
    # Implementation
  end
end

# Git workflow
git checkout -b feature/user-authentication
git add .
git commit -m "feat: add user authentication service

- Implement password hashing with bcrypt
- Add email validation
- Include welcome email notification"

# Pull request template
## Summary
Brief description of changes

## Testing
- [ ] Unit tests pass
- [ ] Integration tests added
- [ ] Manual testing completed

## Checklist
- [ ] RuboCop passes
- [ ] Documentation updated
- [ ] Security review completed
```

```markdown
# ✅ GOOD: README structure
## Development Setup

1. Install Ruby 3.2.0: `rbenv install 3.2.0`
2. Install dependencies: `bundle install`
3. Setup database: `rails db:create db:migrate`
4. Run tests: `bundle exec rspec`

## Running the Application

```bash
rails server
```

## Code Quality

```bash
bundle exec rubocop
bundle exec rspec
```
```

```ruby
# ❌ BAD: Collaboration issues
# No documentation
def process_data(x, y, z)
  # Complex logic with no explanation
end

# Unclear commit messages
git commit -m "fix stuff"
git commit -m "update"

# No code review process
git push origin main  # Direct to main branch
```
