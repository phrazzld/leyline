---
derived_from: testability
enforced_by: pytest & pytest-cov & CI pipeline & code review
id: testing-patterns
last_modified: '2025-06-13'
version: '0.1.0'
---
# Binding: Test Behavior with pytest, Not Implementation Details

Write tests that verify behavior and outcomes, not internal implementation. Focus on testing what your code accomplishes, not how it accomplishes it. Use pytest's fixtures and parametrization to create clear, maintainable tests that document your system's expected behavior.

## Rationale

Implements testability by focusing on behavior verification rather than implementation coupling. Tests should verify outcomes users care about, not internal method calls.

## Rule Definition

**Core Requirements:**

- **Test Behavior, Not Implementation**: Verify outcomes and external behavior, not method calls or internal state
- **Descriptive Test Names**: Use names that explain expected behavior clearly
- **Arrange-Act-Assert Structure**: Set up test data, perform action, verify outcome
- **Test Independence**: Tests should not depend on each other or shared state
- **One Behavior Per Test**: Each test verifies one specific behavior
- **Use pytest Features**: Leverage fixtures, parametrization, and marks for maintainable tests

**Prohibited Practices:**
- Testing private methods directly
- Asserting on internal state that users don't care about
- Brittle tests that break when implementation changes but behavior doesn't
- Massive test functions testing multiple behaviors

## Practical Implementation

**Essential Configuration:**

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["--strict-markers", "--cov=src/myproject", "--cov-fail-under=85"]
markers = ["slow", "integration", "unit"]
```

**Fixture Patterns:**

```python
# conftest.py
@pytest.fixture
def db_session():
    session = create_test_db()
    yield session
    session.rollback()

@pytest.fixture
def sample_user():
    return User(id=1, email="test@example.com")
```

## Examples

```python
# ❌ BAD: Testing implementation details
def test_user_service_calls_email_service():
    email_service = Mock()
    user_service = UserService(email_service)
    user_service.register_user("test@example.com", "password")
    # Brittle - breaks when implementation changes
    email_service.send_email.assert_called_once_with(...)

# ✅ GOOD: Testing behavior and outcomes
def test_user_registration_creates_active_account(db_session, mock_email_service):
    user_service = UserService(db_session, mock_email_service)

    user = user_service.register_user("test@example.com", "password123")

    assert user.email == "test@example.com"
    assert user.is_active is True
    assert mock_email_service.send_welcome_email.called

def test_registration_rejects_duplicate_email(db_session):
    user_service = UserService(db_session)
    user_service.register_user("test@example.com", "password1")

    with pytest.raises(DuplicateEmailError):
        user_service.register_user("test@example.com", "password2")
```

```python
# ❌ BAD: Testing private methods
def test_user_service_internal_validation():
    service = UserService()
    assert service._validate_email_format("test@example.com") is True
    assert service._hash_password("password") != "password"

# ✅ GOOD: Testing public behavior
def test_user_service_email_validation():
    service = UserService()

    valid_user = service.create_user("valid@example.com", "password")
    assert valid_user.email == "valid@example.com"

    with pytest.raises(InvalidEmailError):
        service.create_user("invalid-email", "password")
```

```python
# ❌ BAD: Testing multiple behaviors in one function
def test_order_processing():
    order_service = OrderService()
    order = order_service.create_order(user_id=1, items=[{"id": 1, "qty": 2}])
    assert order.total == 20.00
    payment_result = order_service.process_payment(order.id, "credit_card")
    assert payment_result.success is True
    # If this fails, we don't know which behavior broke

# ✅ GOOD: Focused tests for individual behaviors
def test_order_creation_calculates_total():
    order_service = OrderService()
    order = order_service.create_order(
        user_id=1,
        items=[{"id": 1, "price": 10.00, "quantity": 2}]
    )
    assert order.total == 20.00

def test_payment_processing_with_valid_card():
    order_service = OrderService()
    order = create_sample_order()

    result = order_service.process_payment(order.id, "credit_card")
    assert result.success is True
```

```python
# Using pytest parametrization effectively
@pytest.mark.parametrize("email,password,should_succeed", [
    ("valid@example.com", "strong_password123", True),
    ("", "strong_password123", False),
    ("invalid-email", "strong_password123", False),
    ("valid@example.com", "weak", False),
])
def test_user_registration_validation(email, password, should_succeed):
    service = UserService()

    if should_succeed:
        user = service.register_user(email, password)
        assert user.email == email
    else:
        with pytest.raises((InvalidEmailError, WeakPasswordError)):
            service.register_user(email, password)

@pytest.fixture
def user_with_orders():
    user = User(email="customer@example.com")
    user.orders = [
        Order(id=1, total=25.00, status="completed"),
        Order(id=2, total=15.00, status="pending"),
    ]
    return user

def test_user_total_spent_calculation(user_with_orders):
    total_spent = user_with_orders.calculate_total_spent()
    assert total_spent == 25.00  # Only completed orders count
```

```python
# Integration test for business workflows
@pytest.mark.integration
def test_complete_user_registration_workflow(db_session):
    email_service = EmailService()
    user_service = UserService(db_session, email_service)

    user = user_service.register_user("newuser@example.com", "secure_password")

    # Verify complete business outcome
    saved_user = db_session.query(User).filter_by(email="newuser@example.com").first()
    assert saved_user.is_active is True

    # Welcome email sent
    sent_emails = email_service.get_sent_emails()
    welcome_emails = [e for e in sent_emails if "welcome" in e.subject.lower()]
    assert len(welcome_emails) == 1

    # User can log in immediately
    authenticated_user = user_service.authenticate("newuser@example.com", "secure_password")
    assert authenticated_user.id == saved_user.id
```

## Test Categories

- **Unit Tests**: Test individual functions in isolation, use mocks for external dependencies, fast execution
- **Integration Tests**: Test interactions between components, use real implementations, verify data flows
- **End-to-End Tests**: Test complete user journeys with minimal mocking, slower but highest confidence

## Related Bindings

- [testability](../../../tenets/testability.md): Code should be designed to make testing straightforward and meaningful
- [no-internal-mocking](../../core/no-internal-mocking.md): Avoid mocking internal collaborators; refactor for testability instead
- [type-hinting](../../docs/bindings/categories/python/type-hinting.md): Explicit type hints enable more effective testing by catching errors at development time
- [package-structure](../../docs/bindings/categories/python/package-structure.md): Well-organized packages enable focused, maintainable test suites
