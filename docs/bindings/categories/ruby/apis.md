---
derived_from: modularity
enforced_by: API specs & review
id: ruby-apis
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Ruby APIs

Build consistent, maintainable JSON APIs using Rails conventions.

## Rules

- **JSON:API or custom serializers** for consistent response format
- **API versioning** via URL path (`/api/v1/`)
- **Token-based authentication** with proper scoping
- **Rate limiting** to prevent abuse
- **OpenAPI documentation** for all endpoints

## Examples

```ruby
# ✅ GOOD: API controller structure
class Api::V1::UsersController < Api::BaseController
  before_action :authenticate_api_user!
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    users = User.page(params[:page]).per(25)
    render json: UserSerializer.new(users, meta: pagination_meta(users))
  end

  def show
    render json: UserSerializer.new(@user)
  end

  private

  def user_params
    params.require(:user).permit(:email, :name)
  end

  def set_user
    @user = User.find(params[:id])
  end
end

# Serializer for consistent JSON structure
class UserSerializer
  include JSONAPI::Serializer

  attributes :email, :name, :created_at

  has_many :posts

  attribute :display_name do |user|
    user.name.presence || 'Anonymous'
  end
end

# API authentication
class Api::BaseController < ApplicationController
  before_action :authenticate_api_user!

  private

  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(api_token: token)

    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
end
```

```ruby
# ❌ BAD: Inconsistent API patterns
class UsersController < ApplicationController
  def index
    # No serialization, exposes internal structure
    render json: User.all
  end

  def show
    # Inconsistent error handling
    user = User.find(params[:id]) rescue nil
    if user
      render json: { user: user.attributes }
    else
      render json: 'not found'
    end
  end
end

# No versioning
# /users instead of /api/v1/users

# No authentication or rate limiting
```

```yaml
# ✅ GOOD: Rate limiting configuration
# config/application.rb
config.middleware.use Rack::Attack

# Rate limiting rules
Rack::Attack.throttle('api_requests', limit: 100, period: 1.hour) do |req|
  req.env['HTTP_AUTHORIZATION'] if req.path.start_with?('/api/')
end
```
