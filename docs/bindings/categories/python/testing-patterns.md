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

This binding implements our testability tenet by ensuring that tests provide meaningful feedback about system correctness rather than coupling to implementation details. It also supports our automation tenet by creating reliable automated verification that enables confident refactoring and continuous delivery.

Think of testing like quality control in manufacturing. A good quality inspector doesn't check whether workers use specific tools or follow particular motions—they verify that the final product meets specifications. Similarly, good tests verify that your code produces correct outputs for given inputs, regardless of the internal algorithms used. When you test implementation details, you're like an inspector who rejects products because workers used a different wrench, even when the product works perfectly.

Behavior-focused tests serve as living documentation for your system. When someone reads a test called `test_user_receives_welcome_email_after_registration()`, they immediately understand what the system should do. When they read `test_email_service_send_method_called_once()`, they only understand internal mechanics that might change. Tests should tell the story of what your system does for users, not the story of how your classes collaborate.

## Rule Definition

pytest provides powerful tools for writing expressive, maintainable tests. This binding requires:

**Required practices:**
- Test behavior and outcomes, not method calls or internal state
- Use descriptive test names that explain the expected behavior
- Organize tests to mirror your package structure
- Use fixtures for test setup and dependency injection
- Achieve meaningful test coverage (focus on critical paths, not percentage targets)

**Prohibited practices:**
- Testing private methods directly
- Asserting on internal state that users don't care about
- Brittle tests that break when implementation changes but behavior doesn't
- Massive test functions that test multiple behaviors

**Testing principles:**
- **Arrange-Act-Assert**: Set up test data, perform the action, verify the outcome
- **One behavior per test**: Each test should verify one specific behavior
- **Independence**: Tests should not depend on each other or shared state

## Practical Implementation

### pytest Configuration

**Configure pytest in pyproject.toml:**

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov=src/myproject",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=85"
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests"
]
```

### Test Organization

```
tests/
├── conftest.py              # Shared fixtures
├── test_users/
│   ├── test_user_models.py
│   ├── test_user_services.py
│   └── test_user_api.py
├── test_orders/
│   ├── test_order_models.py
│   └── test_order_services.py
└── integration/
    ├── test_user_registration_flow.py
    └── test_order_processing_flow.py
```

### Fixture Patterns

**Shared fixtures in conftest.py:**

```python
import pytest
from unittest.mock import Mock
from myproject.shared.database import create_test_db
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
    return User(
        id=1,
        email="test@example.com",
        name="Test User"
    )

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
```

```python
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

    # Testing internal private method
    assert service._validate_email_format("test@example.com") is True
    assert service._hash_password("password") != "password"
    assert len(service._generate_user_id()) == 36  # UUID length

    # These tests break if we change internal implementation
```

```python
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
    # This test does too much and is hard to debug when it fails
    order_service = OrderService()

    # Creating order
    order = order_service.create_order(user_id=1, items=[{"id": 1, "qty": 2}])
    assert order.total == 20.00

    # Processing payment
    payment_result = order_service.process_payment(order.id, "credit_card")
    assert payment_result.success is True

    # Sending confirmation
    confirmation = order_service.send_confirmation(order.id)
    assert confirmation.sent is True

    # Updating inventory
    inventory = order_service.update_inventory(order.id)
    assert inventory.updated is True

    # If any step fails, we don't know which behavior broke
```

```python
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

def test_order_confirmation_email_contains_order_details():
    """Order confirmation should include order details in email."""
    order_service = OrderService(mock_email_service)
    order = create_sample_order()

    order_service.send_confirmation(order.id)

    # Verify email was sent with order details
    sent_emails = mock_email_service.get_sent_emails()
    assert len(sent_emails) == 1
    assert order.id in sent_emails[0].body
    assert str(order.total) in sent_emails[0].body
```

```python
# ❌ BAD: Testing framework internals instead of business logic
@pytest.mark.parametrize("input_value", [1, 2, 3])
def test_pytest_parametrize_works(input_value):
    # This tests pytest, not our code
    assert isinstance(input_value, int)

def test_mock_framework_functionality():
    mock = Mock()
    mock.some_method.return_value = "test"

    # This tests the mock framework, not our business logic
    assert mock.some_method() == "test"
    assert mock.some_method.called is True
```

```python
# ✅ GOOD: Using pytest features to test business logic comprehensively
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
# ❌ BAD: Integration test that's actually testing implementation
def test_database_integration():
    # This tests the database, not our business logic
    session = create_db_session()
    user = User(email="test@example.com")
    session.add(user)
    session.commit()

    retrieved = session.query(User).filter_by(email="test@example.com").first()
    assert retrieved.email == "test@example.com"
    # This is testing SQLAlchemy, not our domain logic
```

```python
# ✅ GOOD: Integration test focused on business workflows
def test_complete_user_registration_workflow(db_session):
    """Complete user registration workflow should create user and send welcome email."""
    # This tests the entire business process from end to end
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

## Test Categories and Strategies

### Unit Tests
- Test individual functions and methods in isolation
- Use mocks for external dependencies
- Fast execution (< 100ms per test)
- Focus on edge cases and error conditions

### Integration Tests
- Test interactions between components
- Use real implementations where possible
- Test complete business workflows
- Verify data flows correctly through system boundaries

### End-to-End Tests
- Test complete user journeys
- Use minimal mocking
- Test critical business scenarios
- Slower but provide highest confidence

## Related Bindings

### Core Tenets & Bindings
- [testability](../../../tenets/testability.md) - Code should be designed to make testing straightforward and meaningful
- [automation](../../../tenets/automation.md) - Testing should be automated to provide continuous feedback and enable confident refactoring
- [no-internal-mocking](../../core/no-internal-mocking.md) - Avoid mocking internal collaborators; refactor for testability instead
- [dependency-inversion](../../core/dependency-inversion.md) - Proper dependency injection enables effective testing without tight coupling

### Language-Specific Analogies
- [interface-design](../go/interface-design.md) - Go testing approaches that leverage interfaces for clean, testable code
- [functional-composition-patterns](../typescript/functional-composition-patterns.md) - TypeScript patterns for composable, testable functions

### Related Python Patterns
- [type-hinting](../../docs/bindings/categories/python/type-hinting.md) - Explicit type hints enable more effective testing by catching errors at development time
- [error-handling](../../docs/bindings/categories/rust/error-handling.md) - Explicit error handling enables comprehensive testing of both success and failure scenarios
- [package-structure](../../docs/bindings/categories/python/package-structure.md) - Well-organized packages enable focused, maintainable test suites
- [modern-python-toolchain](../../docs/bindings/categories/python/modern-python-toolchain.md) - pytest configuration and test automation are integral parts of the unified Python toolchain
- [ruff-code-quality](../../docs/bindings/categories/python/ruff-code-quality.md) - Code quality standards apply to test code to ensure maintainable and reliable test suites
