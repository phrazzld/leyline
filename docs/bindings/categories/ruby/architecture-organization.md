---
derived_from: modularity
enforced_by: code review
id: ruby-architecture-organization
last_modified: '2025-07-01'
version: '0.2.0'
---
# Binding: Ruby Architecture Organization

Structure Ruby applications with clear separation of concerns using service objects and modules.

## Rules

- **Service objects** for complex business logic
- **Modules** for shared behavior and namespacing
- **Single responsibility** per class/module
- **Avoid fat models** - keep ActiveRecord lean
- **Decorators/Presenters** for view logic

## Examples

```ruby
# ✅ GOOD: Service object
class UserRegistrationService
  def initialize(user_params:, notifier:)
    @user_params = user_params
    @notifier = notifier
  end

  def call
    user = User.create!(@user_params)
    @notifier.send_welcome_email(user)
    user
  end
end

# Module for shared behavior
module Timestampable
  extend ActiveSupport::Concern

  included do
    scope :recent, -> { where('created_at > ?', 1.week.ago) }
  end
end

# Presenter for view logic
class UserPresenter
  def initialize(user)
    @user = user
  end

  def display_name = @user.name.presence || 'Anonymous'
  def avatar_url = @user.avatar.attached? ? @user.avatar.url : '/default.png'
end
```

```ruby
# ❌ BAD: Fat model
class User < ApplicationRecord
  def register_and_notify!
    save!
    WelcomeMailer.deliver(self)
    Analytics.track('user_registered', self)
    # ... 50 more lines
  end

  def display_name_with_fallback
    # View logic in model
  end
end
```
