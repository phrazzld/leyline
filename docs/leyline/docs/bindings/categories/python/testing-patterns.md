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

This binding implements our testability tenet by ensuring that tests provide meaningful feedback about system correctness rather than coupling to implementation details. Good tests verify that your code produces correct outputs for given inputs, regardless of internal algorithms used. Behavior-focused tests serve as living documentation that tells the story of what your system does for users, not how classes collaborate internally.

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

**pytest Configuration:**

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = [
    "--strict-markers",
    "--cov=src/myproject",
    "--cov-report=term-missing",
    "--cov-fail-under=85"
]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests"
]
```

**Test Organization:**

```
tests/
├── conftest.py              # Shared fixtures
├── test_users/
│   ├── test_user_models.py
│   ├── test_user_services.py
│   └── test_user_api.py
└── integration/
    └── test_user_registration_flow.py
```

**Fixture Patterns:**

```python
# conftest.py
import pytest
from unittest.mock import Mock
from myproject.users.models import User

@pytest.fixture
def db_session():
    """Provide a clean database session for each test."""
    session = create_test_db()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def sample_user():
    """Provide a sample user for testing."""
    return User(id=1, email="test@example.com", name="Test User")

@pytest.fixture
def mock_email_service():
    """Provide a mock email service."""
    return Mock()
```

## Examples

```python
# ❌ BAD: Testing implementation details instead of behavior
def test_user_service_calls_email_service_with_correct_parameters():
    email_service = Mock()
    user_service = UserService(email_service)

    user_service.register_user("test@example.com", "password")

    # This test breaks if we change how emails are sent internally
    email_service.send_email.assert_called_once_with(
        to="test@example.com",
        template="welcome",
        context={"name": "test@example.com"}
    )

def test_user_repository_save_method_called():
    repo = Mock()
    service = UserService(repo)

    service.create_user("test@example.com")

    # Testing that a method was called, not what the user experiences
    repo.save.assert_called_once()

# ✅ GOOD: Testing behavior and outcomes users care about
def test_user_registration_creates_active_user_account(db_session, mock_email_service):
    """User registration should create an active account and send welcome email."""
    user_service = UserService(db_session, mock_email_service)

    # Act: Register a new user
    user = user_service.register_user("test@example.com", "password123")

    # Assert: Verify the behavior users care about
    assert user.email == "test@example.com"
    assert user.is_active is True
    assert user.created_at is not None

    # Verify welcome email was sent (behavior, not implementation)
    assert mock_email_service.send_welcome_email.called
    welcome_call = mock_email_service.send_welcome_email.call_args
    assert welcome_call[0][0] == "test@example.com"

def test_user_registration_fails_with_duplicate_email(db_session):
    """Registration should reject duplicate email addresses."""
    user_service = UserService(db_session)

    # Arrange: Create existing user
    user_service.register_user("test@example.com", "password1")

    # Act & Assert: Attempt duplicate registration
    with pytest.raises(DuplicateEmailError):
        user_service.register_user("test@example.com", "password2")
```

```python
# ❌ BAD: Brittle test that breaks when implementation changes
def test_user_service_internal_validation():
    service = UserService()

    # Testing internal private methods
    assert service._validate_email_format("test@example.com") is True
    assert service._hash_password("password") != "password"
    assert len(service._generate_user_id()) == 36  # UUID length

# ✅ GOOD: Robust test focused on public behavior
def test_user_service_email_validation():
    """User service should accept valid emails and reject invalid ones."""
    service = UserService()

    # Test through public interface - what users experience
    valid_user = service.create_user("valid@example.com", "password")
    assert valid_user.email == "valid@example.com"

    # Test error cases through public interface
    with pytest.raises(InvalidEmailError):
        service.create_user("invalid-email", "password")

    with pytest.raises(InvalidEmailError):
        service.create_user("", "password")
```

```python
# ❌ BAD: Massive test function testing multiple behaviors
def test_order_processing():
    order_service = OrderService()

    # Creating order, processing payment, sending confirmation, updating inventory
    order = order_service.create_order(user_id=1, items=[{"id": 1, "qty": 2}])
    assert order.total == 20.00

    payment_result = order_service.process_payment(order.id, "credit_card")
    assert payment_result.success is True
    # ... more assertions - if any step fails, we don't know which behavior broke

# ✅ GOOD: Focused tests for individual behaviors
def test_order_creation_calculates_correct_total():
    """Order creation should calculate total based on item prices and quantities."""
    order_service = OrderService()

    order = order_service.create_order(
        user_id=1,
        items=[
            {"id": 1, "price": 10.00, "quantity": 2},
            {"id": 2, "price": 5.00, "quantity": 1}
        ]
    )

    assert order.total == 25.00

def test_payment_processing_succeeds_with_valid_card():
    """Payment processing should succeed with valid payment details."""
    order_service = OrderService()
    order = create_sample_order()  # Helper function

    result = order_service.process_payment(
        order.id,
        payment_method="credit_card",
        card_number="4111111111111111"
    )

    assert result.success is True
    assert result.transaction_id is not None
```

```python
# Using pytest features effectively for business logic
@pytest.mark.parametrize("email,password,should_succeed", [
    ("valid@example.com", "strong_password123", True),
    ("", "strong_password123", False),  # Empty email
    ("invalid-email", "strong_password123", False),  # Invalid format
    ("valid@example.com", "", False),  # Empty password
    ("valid@example.com", "weak", False),  # Weak password
])
def test_user_registration_validation(email, password, should_succeed):
    """User registration should validate input according to business rules."""
    service = UserService()

    if should_succeed:
        user = service.register_user(email, password)
        assert user.email == email
        assert user.is_active is True
    else:
        with pytest.raises((InvalidEmailError, WeakPasswordError)):
            service.register_user(email, password)

@pytest.fixture
def user_with_orders():
    """Create a user with sample orders for testing."""
    user = User(email="customer@example.com")
    user.orders = [
        Order(id=1, total=25.00, status="completed"),
        Order(id=2, total=15.00, status="pending"),
    ]
    return user

def test_user_total_spent_calculation(user_with_orders):
    """User should calculate total spent across all completed orders."""
    total_spent = user_with_orders.calculate_total_spent()

    # Only completed orders should count
    assert total_spent == 25.00
```

```python
# ✅ GOOD: Integration test focused on business workflows
@pytest.mark.integration
def test_complete_user_registration_workflow(db_session):
    """Complete user registration workflow should create user and send welcome email."""
    email_service = EmailService()
    user_service = UserService(db_session, email_service)

    # Act: Complete registration workflow
    user = user_service.register_user("newuser@example.com", "secure_password")

    # Assert: Verify complete business outcome
    # User exists in database
    saved_user = db_session.query(User).filter_by(email="newuser@example.com").first()
    assert saved_user is not None
    assert saved_user.is_active is True

    # Welcome email was sent
    sent_emails = email_service.get_sent_emails()
    welcome_emails = [e for e in sent_emails if "welcome" in e.subject.lower()]
    assert len(welcome_emails) == 1
    assert welcome_emails[0].to == "newuser@example.com"

    # User can immediately log in (business requirement)
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
