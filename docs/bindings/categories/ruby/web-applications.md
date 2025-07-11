---
derived_from: maintainability
enforced_by: Rails conventions & review
id: ruby-web-applications
last_modified: '2025-07-01'
version: '0.2.0'
---
# Binding: Ruby Web Applications

Follow Rails conventions for maintainable web application architecture.

## Rules

- **Thin controllers, fat services** - business logic in service objects
- **RESTful routing** with nested resources where appropriate
- **Concerns** for shared controller/model behavior
- **Strong parameters** for all form inputs
- **Environment-based configuration** via Rails credentials

## Examples

```ruby
# ✅ GOOD: Thin controller
class UsersController < ApplicationController
  def create
    result = UserCreationService.new(user_params).call

    if result.success?
      render json: result.user, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password)
  end
end

# RESTful routes
Rails.application.routes.draw do
  resources :users do
    resources :posts, only: [:index, :create, :destroy]
  end

  namespace :admin do
    resources :users
  end
end

# Concern for shared behavior
module Timestampable
  extend ActiveSupport::Concern

  included do
    scope :recent, -> { where('created_at > ?', 1.week.ago) }
  end
end

class User < ApplicationRecord
  include Timestampable
end
```

```ruby
# ❌ BAD: Fat controller
class UsersController < ApplicationController
  def create
    @user = User.new(params[:user])  # No strong params

    if @user.valid?
      @user.password = BCrypt::Password.create(params[:user][:password])
      @user.save!

      # Business logic in controller
      WelcomeMailer.deliver(@user)
      Analytics.track('user_created', @user.id)

      render json: @user
    else
      render json: @user.errors
    end
  end
end

# Non-RESTful routes
get '/create_user'
post '/make_user'
delete '/remove_user/:id'
```

```yaml
# ✅ GOOD: Environment configuration
production:
  database_url: <%= Rails.application.credentials.database_url %>
  redis_url: <%= Rails.application.credentials.redis_url %>

development:
  database: myapp_development
  redis_url: redis://localhost:6379/0
```
