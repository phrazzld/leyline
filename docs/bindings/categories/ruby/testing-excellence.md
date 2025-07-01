---
derived_from: testability
enforced_by: CI & code review
id: ruby-testing-excellence
last_modified: '2025-07-01'
version: '0.1.0'
---
# Binding: Ruby Testing Excellence

Write behavior-focused tests using RSpec with clear setup and meaningful assertions.

## Rules

- **RSpec** over Minitest for readability
- **Factories** (FactoryBot) over fixtures
- **Test pyramid** - mostly unit, some integration
- **Describe behavior** not implementation
- **Explicit setup** - avoid before(:all)

## Examples

```ruby
# ✅ GOOD: Behavior-focused RSpec
RSpec.describe UserRegistrationService do
  let(:user_params) { { email: 'test@example.com', name: 'Test' } }
  let(:notifier) { instance_double(EmailNotifier) }
  let(:service) { described_class.new(user_params: user_params, notifier: notifier) }

  describe '#call' do
    context 'with valid params' do
      it 'creates user and sends welcome email' do
        expect(notifier).to receive(:send_welcome_email)

        user = service.call

        expect(user).to be_persisted
        expect(user.email).to eq('test@example.com')
      end
    end

    context 'with invalid params' do
      let(:user_params) { { email: 'invalid' } }

      it 'raises validation error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

# Factory
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
  end
end
```

```ruby
# ❌ BAD: Testing implementation
describe '#save' do
  it 'calls database insert' do
    expect(ActiveRecord::Base).to receive(:insert)
    user.save
  end
end

# Fixtures instead of factories
users:
  one:
    email: test@example.com
```
