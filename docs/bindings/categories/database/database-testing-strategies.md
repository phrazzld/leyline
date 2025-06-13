---
id: database-testing-strategies
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: testability
enforced_by: test coverage tools & CI pipeline
---

# Binding: Design Database Code for Comprehensive Testing

All database interactions must be designed and structured to enable reliable,
isolated, and maintainable testing. Create clear boundaries between database
logic and business logic, manage test data systematically, and ensure database
tests are fast, predictable, and independent.

## Rationale

This binding directly implements our testability tenet by ensuring that database
code follows the same principles of testable design as any other component.
Database interactions are often the most complex and error-prone parts of
applications, making comprehensive testing absolutely critical for system
reliability. When database code is designed for testability from the beginning,
it naturally becomes more modular, maintainable, and robust.

Think of database testing like testing electrical circuits. You need to be able
to test individual components in isolation (unit testing), verify that components
work together correctly (integration testing), and ensure the entire system
performs under load (performance testing). Just as you wouldn't wire a complex
circuit without being able to test each part independently, you shouldn't build
database-dependent code without clear testing strategies for each layer.

The challenge with database testing is that databases represent shared,
persistent state that can easily create test dependencies and flaky behavior.
When tests share database state or depend on specific data setups, they become
brittle and unreliable. Proper database testing strategy eliminates these
issues by creating predictable, isolated test environments where each test can
run independently and produce consistent results regardless of execution order
or parallel execution.

## Rule Definition

Testable database design means creating clear separation between data access,
business logic, and persistence concerns, while establishing reliable patterns
for test data management and database state control. This enables testing at
appropriate levels of granularity without sacrificing speed or reliability.

Key principles for testable database code:

- **Clear Boundaries**: Separate data access logic from business logic to enable isolated testing
- **Test Data Management**: Systematic creation, management, and cleanup of test data
- **Transaction Isolation**: Ensure tests don't interfere with each other through shared state
- **Mock Boundaries**: Mock database interfaces for unit tests, use real databases for integration tests
- **Performance Validation**: Include database performance testing in critical paths

Common patterns this binding requires:

- Repository or data access layer patterns that can be easily mocked
- Test database setup and teardown procedures
- Test data factories and builders for creating consistent test scenarios
- Transaction rollback strategies for test isolation
- Integration test suites that validate database interactions

What this explicitly prohibits:

- Testing business logic through database integration tests only
- Sharing test data across test cases without proper isolation
- Manual database setup that can't be automated or reproduced
- Ignoring database performance in test environments
- Complex test data scenarios that are difficult to understand or maintain

## Practical Implementation

1. **Separate Data Access from Business Logic**: Create clear boundaries between
   database operations and business logic to enable testing each layer
   independently with appropriate strategies.

   ```python
   # Python with Repository Pattern - clear separation for testing
   from abc import ABC, abstractmethod
   from dataclasses import dataclass
   from typing import List, Optional

   @dataclass
   class User:
       id: Optional[int]
       email: str
       username: str
       is_active: bool = True

   class UserRepository(ABC):
       """Abstract repository interface - easily mockable for unit tests"""

       @abstractmethod
       def create(self, user: User) -> User:
           pass

       @abstractmethod
       def find_by_email(self, email: str) -> Optional[User]:
           pass

       @abstractmethod
       def update(self, user: User) -> User:
           pass

       @abstractmethod
       def delete(self, user_id: int) -> bool:
           pass

   class SQLUserRepository(UserRepository):
       """Concrete implementation for production/integration tests"""

       def __init__(self, db_session):
           self.session = db_session

       def create(self, user: User) -> User:
           # Database-specific implementation
           db_user = UserModel(email=user.email, username=user.username)
           self.session.add(db_user)
           self.session.commit()
           return User(id=db_user.id, email=db_user.email, username=db_user.username)

       def find_by_email(self, email: str) -> Optional[User]:
           db_user = self.session.query(UserModel).filter_by(email=email).first()
           if db_user:
               return User(id=db_user.id, email=db_user.email, username=db_user.username)
           return None

   class UserService:
       """Business logic separated from data access - easily unit testable"""

       def __init__(self, user_repository: UserRepository):
           self.user_repository = user_repository

       def register_user(self, email: str, username: str) -> User:
           # Business logic that can be unit tested with mocked repository
           if self.user_repository.find_by_email(email):
               raise ValueError("Email already registered")

           if len(username) < 3:
               raise ValueError("Username must be at least 3 characters")

           new_user = User(id=None, email=email.lower(), username=username)
           return self.user_repository.create(new_user)

   # Unit Test - business logic with mocked database
   import pytest
   from unittest.mock import Mock

   def test_register_user_success():
       # Mock repository for pure business logic testing
       mock_repo = Mock(spec=UserRepository)
       mock_repo.find_by_email.return_value = None
       mock_repo.create.return_value = User(id=1, email="test@example.com", username="testuser")

       service = UserService(mock_repo)
       result = service.register_user("TEST@example.com", "testuser")

       # Verify business logic behavior
       assert result.email == "test@example.com"  # Email normalized
       mock_repo.find_by_email.assert_called_once_with("TEST@example.com")
       mock_repo.create.assert_called_once()

   def test_register_user_duplicate_email():
       mock_repo = Mock(spec=UserRepository)
       mock_repo.find_by_email.return_value = User(id=1, email="test@example.com", username="existing")

       service = UserService(mock_repo)

       with pytest.raises(ValueError, match="Email already registered"):
           service.register_user("test@example.com", "newuser")
   ```

2. **Implement Systematic Test Data Management**: Create test data factories and
   builders that produce consistent, predictable test scenarios while avoiding
   data pollution between tests.

   ```java
   // Java with Spring Boot - test data management
   @DataJpaTest
   @TestPropertySource(properties = {
       "spring.jpa.hibernate.ddl-auto=create-drop",
       "spring.datasource.url=jdbc:h2:mem:testdb"
   })
   public class OrderRepositoryTest {

       @Autowired
       private TestEntityManager entityManager;

       @Autowired
       private OrderRepository orderRepository;

       private Customer testCustomer;
       private Product testProduct;

       @BeforeEach
       void setUp() {
           // Clean, predictable test data setup
           testCustomer = CustomerTestDataBuilder.create()
               .withEmail("test@example.com")
               .withName("Test Customer")
               .build();
           testCustomer = entityManager.persistAndFlush(testCustomer);

           testProduct = ProductTestDataBuilder.create()
               .withName("Test Product")
               .withPrice(new BigDecimal("99.99"))
               .withStock(10)
               .build();
           testProduct = entityManager.persistAndFlush(testProduct);

           entityManager.clear(); // Ensure fresh queries
       }

       @Test
       void shouldCreateOrderWithItems() {
           // Create order using test data
           Order order = OrderTestDataBuilder.create()
               .withCustomer(testCustomer)
               .addItem(testProduct, 2)
               .build();

           Order savedOrder = orderRepository.save(order);

           // Verify database state
           assertThat(savedOrder.getId()).isNotNull();
           assertThat(savedOrder.getCustomer().getId()).isEqualTo(testCustomer.getId());
           assertThat(savedOrder.getItems()).hasSize(1);
           assertThat(savedOrder.getItems().get(0).getQuantity()).isEqualTo(2);

           // Verify persistence by reloading
           Order reloadedOrder = entityManager.find(Order.class, savedOrder.getId());
           assertThat(reloadedOrder).isNotNull();
           assertThat(reloadedOrder.getItems()).hasSize(1);
       }

       @Test
       void shouldFindOrdersByCustomer() {
           // Create multiple orders for testing
           Order order1 = OrderTestDataBuilder.create()
               .withCustomer(testCustomer)
               .addItem(testProduct, 1)
               .build();
           orderRepository.save(order1);

           Order order2 = OrderTestDataBuilder.create()
               .withCustomer(testCustomer)
               .addItem(testProduct, 3)
               .build();
           orderRepository.save(order2);

           // Create order for different customer to verify filtering
           Customer otherCustomer = CustomerTestDataBuilder.create()
               .withEmail("other@example.com")
               .build();
           otherCustomer = entityManager.persistAndFlush(otherCustomer);

           Order otherOrder = OrderTestDataBuilder.create()
               .withCustomer(otherCustomer)
               .addItem(testProduct, 1)
               .build();
           orderRepository.save(otherOrder);

           // Test the query
           List<Order> customerOrders = orderRepository.findByCustomerId(testCustomer.getId());

           assertThat(customerOrders).hasSize(2);
           assertThat(customerOrders).allMatch(order ->
               order.getCustomer().getId().equals(testCustomer.getId()));
       }
   }

   // Test Data Builder Pattern
   public class OrderTestDataBuilder {
       private Customer customer;
       private List<OrderItem> items = new ArrayList<>();
       private OrderStatus status = OrderStatus.PENDING;

       public static OrderTestDataBuilder create() {
           return new OrderTestDataBuilder();
       }

       public OrderTestDataBuilder withCustomer(Customer customer) {
           this.customer = customer;
           return this;
       }

       public OrderTestDataBuilder addItem(Product product, int quantity) {
           OrderItem item = new OrderItem();
           item.setProduct(product);
           item.setQuantity(quantity);
           item.setUnitPrice(product.getPrice());
           this.items.add(item);
           return this;
       }

       public Order build() {
           Order order = new Order();
           order.setCustomer(customer);
           order.setStatus(status);
           order.setCreatedAt(Instant.now());

           for (OrderItem item : items) {
               item.setOrder(order);
               order.getItems().add(item);
           }

           return order;
       }
   }
   ```

3. **Implement Transaction Isolation for Test Independence**: Use transaction
   rollback or database recreation strategies to ensure tests don't interfere
   with each other and can run in parallel safely.

   ```typescript
   // TypeScript with Jest and TypeORM - transaction isolation
   import { DataSource } from 'typeorm';
   import { User } from '../entities/User';
   import { UserService } from '../services/UserService';

   describe('UserService Integration Tests', () => {
     let dataSource: DataSource;
     let userService: UserService;

     beforeAll(async () => {
       // Set up test database connection
       dataSource = new DataSource({
         type: 'postgres',
         database: 'test_db',
         entities: [User],
         synchronize: true, // Auto-create schema for tests
         dropSchema: true,  // Clean slate for each test run
       });

       await dataSource.initialize();
       userService = new UserService(dataSource.getRepository(User));
     });

     afterAll(async () => {
       await dataSource.destroy();
     });

     // Each test runs in its own transaction that gets rolled back
     describe('with transaction isolation', () => {
       let queryRunner: QueryRunner;

       beforeEach(async () => {
         // Start a transaction for this test
         queryRunner = dataSource.createQueryRunner();
         await queryRunner.connect();
         await queryRunner.startTransaction();

         // Use the transactional entity manager for this test
         userService = new UserService(queryRunner.manager.getRepository(User));
       });

       afterEach(async () => {
         // Roll back the transaction - cleans up all changes
         await queryRunner.rollbackTransaction();
         await queryRunner.release();
       });

       test('should create user successfully', async () => {
         const userData = {
           email: 'test@example.com',
           username: 'testuser',
           firstName: 'Test',
           lastName: 'User'
         };

         const createdUser = await userService.createUser(userData);

         expect(createdUser.id).toBeDefined();
         expect(createdUser.email).toBe('test@example.com');

         // Verify user exists in database within this transaction
         const foundUser = await userService.findById(createdUser.id);
         expect(foundUser).toBeDefined();
         expect(foundUser.username).toBe('testuser');

         // Changes will be rolled back after test, not affecting other tests
       });

       test('should handle duplicate email error', async () => {
         // Create first user
         await userService.createUser({
           email: 'duplicate@example.com',
           username: 'user1',
           firstName: 'First',
           lastName: 'User'
         });

         // Attempt to create user with same email
         await expect(userService.createUser({
           email: 'duplicate@example.com',
           username: 'user2',
           firstName: 'Second',
           lastName: 'User'
         })).rejects.toThrow('Email already exists');

         // This test's data is isolated from other tests
       });
     });

     // Alternative: Database recreation strategy for true isolation
     describe('with database recreation', () => {
       beforeEach(async () => {
         // Drop and recreate all tables
         await dataSource.dropDatabase();
         await dataSource.synchronize();
       });

       test('should start with empty database', async () => {
         const users = await userService.findAll();
         expect(users).toHaveLength(0);
       });
     });
   });
   ```

4. **Create Integration Tests for Database-Specific Logic**: Build comprehensive
   integration tests that validate complex queries, transactions, and database
   constraints while maintaining reasonable execution speed.

   ```csharp
   // C# with xUnit and Entity Framework Core - integration testing
   [Collection("Database Integration Tests")]
   public class OrderProcessingIntegrationTests : IClassFixture<TestDatabaseFixture>
   {
       private readonly TestDatabaseFixture _fixture;
       private readonly AppDbContext _context;
       private readonly OrderService _orderService;

       public OrderProcessingIntegrationTests(TestDatabaseFixture fixture)
       {
           _fixture = fixture;
           _context = _fixture.CreateContext();
           _orderService = new OrderService(_context, new PaymentService(), new InventoryService());
       }

       [Fact]
       public async Task ProcessOrder_ShouldHandleInventoryReservationTransactionally()
       {
           // Arrange - create test data with known quantities
           var product = new Product
           {
               Name = "Test Product",
               Price = 100m,
               InventoryCount = 5
           };
           _context.Products.Add(product);

           var customer = new Customer { Email = "test@example.com", Name = "Test Customer" };
           _context.Customers.Add(customer);

           await _context.SaveChangesAsync();

           var orderRequest = new CreateOrderRequest
           {
               CustomerId = customer.Id,
               Items = new[]
               {
                   new OrderItemRequest { ProductId = product.Id, Quantity = 3 }
               }
           };

           // Act
           var result = await _orderService.ProcessOrderAsync(orderRequest);

           // Assert - verify order creation
           Assert.NotNull(result);
           Assert.Equal(OrderStatus.Confirmed, result.Status);
           Assert.Single(result.Items);
           Assert.Equal(3, result.Items.First().Quantity);

           // Assert - verify inventory was updated atomically
           var updatedProduct = await _context.Products.FindAsync(product.Id);
           Assert.Equal(2, updatedProduct.InventoryCount); // 5 - 3 = 2

           // Assert - verify database consistency
           var orderFromDb = await _context.Orders
               .Include(o => o.Items)
               .FirstAsync(o => o.Id == result.Id);
           Assert.Equal(300m, orderFromDb.TotalAmount); // 3 * 100
       }

       [Fact]
       public async Task ProcessOrder_ShouldRollbackOnPaymentFailure()
       {
           // Arrange - set up scenario where payment will fail
           var product = new Product { Name = "Expensive Product", Price = 1000m, InventoryCount = 10 };
           _context.Products.Add(product);

           var customer = new Customer { Email = "poor@example.com", Name = "Poor Customer" };
           _context.Customers.Add(customer);

           await _context.SaveChangesAsync();

           var orderRequest = new CreateOrderRequest
           {
               CustomerId = customer.Id,
               Items = new[]
               {
                   new OrderItemRequest { ProductId = product.Id, Quantity = 2 }
               },
               PaymentMethod = "FAILING_CARD" // Triggers payment failure
           };

           // Act & Assert
           await Assert.ThrowsAsync<PaymentProcessingException>(
               () => _orderService.ProcessOrderAsync(orderRequest)
           );

           // Assert - verify rollback occurred
           var productAfterFailure = await _context.Products.FindAsync(product.Id);
           Assert.Equal(10, productAfterFailure.InventoryCount); // Inventory not reserved

           var ordersForCustomer = await _context.Orders
               .Where(o => o.CustomerId == customer.Id)
               .ToListAsync();
           Assert.Empty(ordersForCustomer); // No order created
       }

       [Fact]
       public async Task ProcessConcurrentOrders_ShouldHandleInventoryContention()
       {
           // Arrange - create product with limited inventory
           var product = new Product { Name = "Limited Product", Price = 50m, InventoryCount = 5 };
           _context.Products.Add(product);

           var customer1 = new Customer { Email = "customer1@example.com", Name = "Customer 1" };
           var customer2 = new Customer { Email = "customer2@example.com", Name = "Customer 2" };
           _context.Customers.AddRange(customer1, customer2);

           await _context.SaveChangesAsync();

           // Act - simulate concurrent orders that together exceed inventory
           var order1Task = _orderService.ProcessOrderAsync(new CreateOrderRequest
           {
               CustomerId = customer1.Id,
               Items = new[] { new OrderItemRequest { ProductId = product.Id, Quantity = 3 } }
           });

           var order2Task = _orderService.ProcessOrderAsync(new CreateOrderRequest
           {
               CustomerId = customer2.Id,
               Items = new[] { new OrderItemRequest { ProductId = product.Id, Quantity = 4 } }
           });

           // One should succeed, one should fail due to insufficient inventory
           var results = await Task.WhenAll(
               order1Task.ContinueWith(t => new { Success = t.IsCompletedSuccessfully, Exception = t.Exception }),
               order2Task.ContinueWith(t => new { Success = t.IsCompletedSuccessfully, Exception = t.Exception })
           );

           // Assert - exactly one order should succeed
           var successCount = results.Count(r => r.Success);
           var failureCount = results.Count(r => !r.Success);

           Assert.Equal(1, successCount);
           Assert.Equal(1, failureCount);

           // Assert - inventory is consistent
           var finalProduct = await _context.Products.FindAsync(product.Id);
           Assert.Equal(2, finalProduct.InventoryCount); // 5 - 3 = 2 (only one order succeeded)
       }
   }

   // Test Database Fixture for sharing database across related tests
   public class TestDatabaseFixture : IDisposable
   {
       private readonly DbContextOptions<AppDbContext> _options;

       public TestDatabaseFixture()
       {
           var connectionString = $"Server=localhost;Database=TestDb_{Guid.NewGuid()};Trusted_Connection=true;";

           _options = new DbContextOptionsBuilder<AppDbContext>()
               .UseSqlServer(connectionString)
               .EnableSensitiveDataLogging()
               .Options;

           // Create database and run migrations
           using var context = new AppDbContext(_options);
           context.Database.EnsureCreated();
       }

       public AppDbContext CreateContext() => new AppDbContext(_options);

       public void Dispose()
       {
           using var context = new AppDbContext(_options);
           context.Database.EnsureDeleted();
       }
   }
   ```

5. **Implement Database Performance Testing**: Include performance validation
   in your test suite to catch database performance regressions early and
   ensure queries perform within acceptable bounds.

   ```go
   // Go with testing and benchmarking - performance testing
   package repository_test

   import (
       "context"
       "database/sql"
       "fmt"
       "testing"
       "time"

       _ "github.com/lib/pq"
       "github.com/stretchr/testify/assert"
       "github.com/stretchr/testify/require"
   )

   func TestUserRepository_PerformanceConstraints(t *testing.T) {
       db, cleanup := setupTestDB(t)
       defer cleanup()

       repo := NewUserRepository(db)

       // Create test dataset with known size
       const userCount = 10000
       createTestUsers(t, repo, userCount)

       t.Run("FindUsersByDepartment should complete within 100ms", func(t *testing.T) {
           start := time.Now()

           users, err := repo.FindUsersByDepartment(context.Background(), "Engineering")

           duration := time.Since(start)
           require.NoError(t, err)
           assert.True(t, len(users) > 0, "Should find engineering users")
           assert.Less(t, duration, 100*time.Millisecond,
               "Query took %v, expected < 100ms", duration)
       })

       t.Run("SearchUsers should handle large result sets efficiently", func(t *testing.T) {
           start := time.Now()

           users, err := repo.SearchUsers(context.Background(), SearchCriteria{
               NamePrefix: "Test",
               Limit:      1000,
           })

           duration := time.Since(start)
           require.NoError(t, err)
           assert.Len(t, users, 1000, "Should return exactly 1000 users")
           assert.Less(t, duration, 200*time.Millisecond,
               "Search took %v, expected < 200ms", duration)
       })
   }

   // Benchmark tests for performance regression detection
   func BenchmarkUserRepository_FindById(b *testing.B) {
       db, cleanup := setupTestDB(b)
       defer cleanup()

       repo := NewUserRepository(db)

       // Create test data
       user := createTestUser(b, repo, "benchmark@example.com")

       b.ResetTimer()
       b.RunParallel(func(pb *testing.PB) {
           for pb.Next() {
               _, err := repo.FindById(context.Background(), user.ID)
               if err != nil {
                   b.Fatalf("FindById failed: %v", err)
               }
           }
       })
   }

   func BenchmarkUserRepository_CreateUser(b *testing.B) {
       db, cleanup := setupTestDB(b)
       defer cleanup()

       repo := NewUserRepository(db)

       b.ResetTimer()
       for i := 0; i < b.N; i++ {
           user := &User{
               Email:    fmt.Sprintf("user%d@example.com", i),
               Username: fmt.Sprintf("user%d", i),
               Name:     fmt.Sprintf("User %d", i),
           }

           _, err := repo.Create(context.Background(), user)
           if err != nil {
               b.Fatalf("Create failed: %v", err)
           }
       }
   }

   func BenchmarkUserRepository_ComplexQuery(b *testing.B) {
       db, cleanup := setupTestDB(b)
       defer cleanup()

       repo := NewUserRepository(db)

       // Create sufficient test data
       createTestUsers(b, repo, 1000)

       criteria := SearchCriteria{
           DepartmentIn: []string{"Engineering", "Product", "Design"},
           CreatedAfter: time.Now().AddDate(0, -1, 0),
           IsActive:     true,
           Limit:        50,
       }

       b.ResetTimer()
       for i := 0; i < b.N; i++ {
           _, err := repo.SearchUsers(context.Background(), criteria)
           if err != nil {
               b.Fatalf("SearchUsers failed: %v", err)
           }
       }
   }

   // Database connection pooling performance test
   func TestConnectionPoolPerformance(t *testing.T) {
       db, cleanup := setupTestDB(t)
       defer cleanup()

       // Configure connection pool
       db.SetMaxOpenConns(10)
       db.SetMaxIdleConns(5)
       db.SetConnMaxLifetime(time.Hour)

       repo := NewUserRepository(db)

       const concurrentQueries = 50
       const queriesPerWorker = 10

       start := time.Now()

       // Run concurrent queries to test pool behavior
       results := make(chan error, concurrentQueries)

       for i := 0; i < concurrentQueries; i++ {
           go func(workerID int) {
               for j := 0; j < queriesPerWorker; j++ {
                   _, err := repo.FindById(context.Background(), 1)
                   if err != nil {
                       results <- err
                       return
                   }
               }
               results <- nil
           }(i)
       }

       // Collect results
       for i := 0; i < concurrentQueries; i++ {
           err := <-results
           require.NoError(t, err)
       }

       duration := time.Since(start)
       totalQueries := concurrentQueries * queriesPerWorker
       avgQueryTime := duration / time.Duration(totalQueries)

       t.Logf("Executed %d concurrent queries in %v (avg: %v per query)",
           totalQueries, duration, avgQueryTime)

       // Performance assertion
       assert.Less(t, avgQueryTime, 10*time.Millisecond,
           "Average query time %v exceeds 10ms threshold", avgQueryTime)
   }

   func setupTestDB(t testing.TB) (*sql.DB, func()) {
       // Connect to test database
       db, err := sql.Open("postgres", "postgres://user:pass@localhost/testdb?sslmode=disable")
       require.NoError(t, err)

       // Create tables
       _, err = db.Exec(`
           CREATE TABLE IF NOT EXISTS users (
               id SERIAL PRIMARY KEY,
               email VARCHAR(255) UNIQUE NOT NULL,
               username VARCHAR(100) NOT NULL,
               name VARCHAR(255) NOT NULL,
               department VARCHAR(100),
               is_active BOOLEAN DEFAULT true,
               created_at TIMESTAMP DEFAULT NOW()
           );
           CREATE INDEX IF NOT EXISTS idx_users_department ON users(department);
           CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
           CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
       `)
       require.NoError(t, err)

       cleanup := func() {
           db.Exec("TRUNCATE TABLE users RESTART IDENTITY")
           db.Close()
       }

       return db, cleanup
   }
   ```

## Examples

```python
# ❌ BAD: Business logic tangled with database, hard to test
class UserService:
    def __init__(self, database_url):
        self.engine = create_engine(database_url)

    def register_user(self, email, username, password):
        # Business logic mixed with database operations
        with self.engine.connect() as conn:
            # Check for duplicate email (database-dependent)
            result = conn.execute(
                "SELECT id FROM users WHERE email = %s", (email,)
            )
            if result.fetchone():
                raise ValueError("Email already exists")

            # Validation logic mixed with persistence
            if len(username) < 3:
                raise ValueError("Username too short")

            # Direct SQL in business logic
            conn.execute(
                "INSERT INTO users (email, username, password_hash) VALUES (%s, %s, %s)",
                (email, username, bcrypt.hashpw(password.encode(), bcrypt.gensalt()))
            )
            conn.commit()

# ✅ GOOD: Clear separation enabling different testing strategies
class UserRepository(ABC):
    @abstractmethod
    def find_by_email(self, email: str) -> Optional[User]:
        pass

    @abstractmethod
    def create(self, user: User) -> User:
        pass

class UserService:
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository

    def register_user(self, email: str, username: str, password: str) -> User:
        # Pure business logic - easily unit testable
        if self.user_repository.find_by_email(email):
            raise ValueError("Email already exists")

        if len(username) < 3:
            raise ValueError("Username too short")

        password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
        user = User(email=email, username=username, password_hash=password_hash)
        return self.user_repository.create(user)

# Unit test - business logic only
def test_register_user_validates_username():
    mock_repo = Mock(spec=UserRepository)
    mock_repo.find_by_email.return_value = None

    service = UserService(mock_repo)

    with pytest.raises(ValueError, match="Username too short"):
        service.register_user("test@example.com", "ab", "password123")

# Integration test - database interaction
def test_user_repository_creates_user_correctly(test_db_session):
    repo = SQLUserRepository(test_db_session)
    user = User(email="test@example.com", username="testuser", password_hash="hashed")

    created_user = repo.create(user)

    assert created_user.id is not None
    assert repo.find_by_email("test@example.com") is not None
```

```javascript
// ❌ BAD: Tests sharing state, unreliable results
describe('Order Processing', () => {
    let db;

    beforeAll(async () => {
        db = await connectToDatabase();
    });

    test('should create order', async () => {
        // Creates data that affects other tests
        const customer = await db.customers.create({
            email: 'test@example.com',
            name: 'Test Customer'
        });

        const order = await orderService.createOrder({
            customerId: customer.id,
            items: [{ productId: 1, quantity: 2 }]
        });

        expect(order.id).toBeDefined();
        // Data left in database
    });

    test('should handle duplicate orders', async () => {
        // Depends on data from previous test - flaky!
        const orders = await db.orders.findByCustomerEmail('test@example.com');
        expect(orders.length).toBeGreaterThan(0);
    });
});

// ✅ GOOD: Isolated tests with proper cleanup
describe('Order Processing', () => {
    let db;
    let testCustomer;
    let testProduct;

    beforeAll(async () => {
        db = await connectToTestDatabase();
    });

    beforeEach(async () => {
        // Clean slate for each test
        await db.beginTransaction();

        // Create fresh test data
        testCustomer = await CustomerTestFactory.create(db, {
            email: 'test@example.com',
            name: 'Test Customer'
        });

        testProduct = await ProductTestFactory.create(db, {
            name: 'Test Product',
            price: 100,
            stock: 10
        });
    });

    afterEach(async () => {
        // Roll back all changes
        await db.rollbackTransaction();
    });

    test('should create order with correct total', async () => {
        const order = await orderService.createOrder({
            customerId: testCustomer.id,
            items: [{ productId: testProduct.id, quantity: 2 }]
        });

        expect(order.total).toBe(200); // 2 * 100
        expect(order.status).toBe('pending');
    });

    test('should prevent order when insufficient stock', async () => {
        await expect(orderService.createOrder({
            customerId: testCustomer.id,
            items: [{ productId: testProduct.id, quantity: 15 }] // More than stock
        })).rejects.toThrow('Insufficient stock');
    });
});
```

```java
// ❌ BAD: No performance validation, slow queries undetected
@Test
public void testFindUsersByDepartment() {
    List<User> users = userRepository.findByDepartment("Engineering");
    assertThat(users).isNotEmpty();
    // No performance validation - query might be slow
}

// ✅ GOOD: Performance testing integrated into test suite
@Test
public void testFindUsersByDepartmentPerformance() {
    // Create realistic test data size
    createTestUsers(1000);

    long startTime = System.currentTimeMillis();
    List<User> users = userRepository.findByDepartment("Engineering");
    long duration = System.currentTimeMillis() - startTime;

    assertThat(users).isNotEmpty();
    assertThat(duration).isLessThan(100L); // 100ms performance requirement
}

@Test
public void testQueryWithProperIndexing() {
    createTestUsers(10000);

    // Test that complex query uses indexes efficiently
    Instant start = Instant.now();

    Page<User> results = userRepository.findUsersWithCriteria(
        UserSearchCriteria.builder()
            .departmentIn(Arrays.asList("Engineering", "Product"))
            .createdAfter(Instant.now().minus(30, ChronoUnit.DAYS))
            .isActive(true)
            .build(),
        PageRequest.of(0, 50)
    );

    Duration queryTime = Duration.between(start, Instant.now());

    assertThat(results.getContent()).hasSize(50);
    assertThat(queryTime.toMillis()).isLessThan(200L);

    // Verify query plan uses indexes (database-specific)
    verifyQueryPlanUsesIndexes();
}
```

## Related Bindings

- [data-validation-at-boundaries](../../docs/bindings/categories/database/data-validation-at-boundaries.md): Testing
  strategies should validate that boundary validation works correctly under
  various conditions. Both patterns work together to ensure data integrity
  through comprehensive validation testing at database boundaries.

- [transaction-management-patterns](../../docs/bindings/categories/database/transaction-management-patterns.md): Database
  testing must validate transaction behavior including rollback scenarios,
  isolation levels, and concurrent access patterns. Both patterns ensure that
  transactional systems behave correctly under test conditions.

- [orm-usage-patterns](../../docs/bindings/categories/database/orm-usage-patterns.md): Testing strategies should verify
  that ORM usage patterns perform correctly and don't introduce N+1 queries
  or other performance issues. Both patterns work together to ensure database
  interactions remain efficient and testable.
