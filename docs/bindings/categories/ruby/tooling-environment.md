---
derived_from: automation
enforced_by: CI & team standards
id: ruby-tooling-environment
last_modified: '2025-07-01'
version: '0.2.0'
---
# Binding: Ruby Tooling Environment

Standardize Ruby development environment for consistent, reproducible builds.

## Rules

- **Version management** with rbenv or rvm
- **Bundler** for dependency management
- **RuboCop** for code style enforcement
- **Gemfile.lock** committed to version control
- **Ruby version** specified in `.ruby-version`

## Examples

```ruby
# ✅ GOOD: .ruby-version file
3.2.0

# Gemfile with explicit versions
source 'https://rubygems.org'

ruby '3.2.0'

gem 'rails', '~> 7.0'
gem 'pg', '~> 1.4'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

# .rubocop.yml configuration
AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable

Style/Documentation:
  Enabled: false

Metrics/LineLength:
  Max: 120
```

```bash
# ✅ GOOD: Setup commands
bundle install
bundle exec rubocop
bundle exec rspec

# CI consistency
bundle config set --local deployment true
bundle config set --local without development
```

```ruby
# ❌ BAD: No version specification
# Missing .ruby-version
# No Gemfile.lock in repo
# Inconsistent tool versions across team
```
