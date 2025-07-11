---
derived_from: maintainability
enforced_by: Brakeman & code review
id: ruby-security-production
last_modified: '2025-07-01'
version: '0.2.0'
---
# Binding: Ruby Security & Production

Implement security-first patterns for Ruby applications, especially Rails.

## Rules

- **Input validation** on all external data
- **Parameterized queries** to prevent SQL injection
- **Strong parameters** in Rails controllers
- **Secrets management** via encrypted credentials
- **Brakeman** static analysis in CI

## Examples

```ruby
# ✅ GOOD: Strong parameters and validation
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name)
  end
end

# Model validation
class User < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 100 }
end

# Parameterized queries
User.where('email = ?', user_email)  # Safe
User.joins(:posts).where('posts.status = ?', 'published')

# Secrets management
Rails.application.credentials.database_password
Rails.application.credentials.api_key
```

```ruby
# ❌ BAD: Security vulnerabilities
# String interpolation in SQL
User.where("email = '#{user_email}'")  # SQL injection risk

# Mass assignment without strong params
User.create(params[:user])  # Dangerous

# Hardcoded secrets
API_KEY = 'sk-1234567890abcdef'  # Never commit secrets

# No input validation
def process_input(data)
  eval(data)  # Code injection risk
end
```

```yaml
# ✅ GOOD: Brakeman configuration
# .brakeman.yml
quiet: true
confidence_level: 2
check_arguments: true
```
