---
derived_from: explicit-over-implicit
enforced_by: code review & RuboCop
id: ruby-language-syntax
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Modern Ruby Syntax

Use Ruby 3.0+ features for clarity and safety. Prefer explicit over clever.

## Rules

- **Keyword arguments** for methods with 2+ parameters
- **Safe navigation** (`&.`) over defensive nil checks
- **Frozen strings** (`# frozen_string_literal: true`)
- **Pattern matching** for complex conditionals
- **Functional methods** (`map`, `select`) over manual loops

## Examples

```ruby
# ✅ GOOD
def activate_user(id:, notify: true)
  user = repository.find(id)
  return false unless user&.pending?

  user.activate!
  notifier&.send_email(to: user.email) if notify
end

# Pattern matching for data extraction
case response
in { status: 'success', data: user_data }
  create_user(user_data)
in { status: 'error', message: msg }
  handle_error(msg)
end

# Functional style
active_users = users.select(&:active?).map(&:name)
```

```ruby
# ❌ BAD
def activate_user(id, notify)  # No keywords
  if user != nil && user.pending != nil  # Defensive checks
    # Manual loops, string concatenation
    names = []
    users.each { |u| names << u.name if u.active }
  end
end
```
