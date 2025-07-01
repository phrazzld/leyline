---
derived_from: distributed-resilience
enforced_by: monitoring & code review
id: ruby-performance-scalability
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Ruby Performance & Scalability

Optimize Ruby applications for production performance and scalability.

## Rules

- **Prevent N+1 queries** with `includes`/`preload`
- **Cache frequently accessed data** with Redis/Memcached
- **Background jobs** for long-running tasks
- **Database indexing** on query columns
- **Memory profiling** to prevent leaks

## Examples

```ruby
# ✅ GOOD: N+1 prevention
users = User.includes(:posts).limit(10)
users.each { |user| puts user.posts.count }  # No extra queries

# Caching
class PostsController < ApplicationController
  def index
    @posts = Rails.cache.fetch('recent_posts', expires_in: 1.hour) do
      Post.published.recent.includes(:author)
    end
  end
end

# Background jobs
class EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, message)
    user = User.find(user_id)
    NotificationMailer.send_email(user, message).deliver_now
  end
end

# Database optimization
class AddIndexToUsersEmail < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :email, unique: true
    add_index :posts, [:user_id, :created_at]
  end
end
```

```ruby
# ❌ BAD: Performance issues
# N+1 queries
users = User.limit(10)
users.each { |user| puts user.posts.count }  # Executes 11 queries

# Synchronous heavy operations
def send_notifications(users)
  users.each do |user|
    NotificationMailer.send_email(user).deliver_now  # Blocks
  end
end

# No caching of expensive operations
def expensive_calculation
  User.joins(:posts).group(:user_id).sum(:views)  # Runs every time
end
```

```ruby
# Monitoring and profiling
gem 'rack-mini-profiler'  # Development profiling
gem 'newrelic_rpm'       # Production monitoring
gem 'redis-rails'        # Caching
gem 'sidekiq'            # Background jobs
```
