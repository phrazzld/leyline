---
id: data-validation-at-boundaries
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: modularity
enforced_by: input validation frameworks & code review
---

# Binding: Validate Data Explicitly at Database Boundaries

All data crossing database boundaries must be explicitly validated by the
responsible module before persistence operations and after retrieval operations.
Each module must own its validation logic completely, without depending on
other modules or database constraints to ensure data integrity.

## Rationale

This binding directly implements our modularity tenet by ensuring that each
module takes complete responsibility for the validity of data at its database
boundaries. Just as good modules have clear, well-defined interfaces with
explicit contracts, database operations must have explicit validation that
makes data requirements visible and enforceable at the code level.

Think of database boundary validation like customs at international borders.
Each country (module) is responsible for checking what enters and leaves its
territory, regardless of what other countries might have done. You can't rely
on the previous country to have properly inspected goods—you must validate
everything that crosses your border according to your own standards and
requirements. Similarly, each module must validate all data it sends to or
receives from the database, creating a clear, defensible boundary.

The modularity principle becomes especially important in database validation
because databases are shared resources that multiple modules may interact with.
Without explicit boundary validation, modules become implicitly coupled through
shared data assumptions, making the system fragile and unpredictable. When
validation is explicit and module-owned, each component can evolve independently
while maintaining its data integrity contracts, and failures are contained to
the module that owns the validation logic.

## Rule Definition

Explicit database boundary validation means that every module implements
comprehensive input validation before persisting data and output validation
after retrieving data. This creates a defensive boundary where each module
ensures data quality without relying on external validation or database
constraints alone.

Key principles for modular database validation:

- **Input Validation**: Validate all data before database write operations
- **Output Validation**: Validate data retrieved from database queries
- **Module Ownership**: Each module owns its complete validation logic
- **Explicit Rules**: Validation requirements are visible in code, not hidden in database schema
- **Error Isolation**: Validation failures are handled locally with clear error messages

Common patterns this binding requires:

- Schema validation objects that define expected data structure
- Type checking and constraint validation before database operations
- Business rule validation within module boundaries
- Sanitization of user input before persistence
- Verification of foreign key relationships before creating associations

What this explicitly prohibits:

- Relying solely on database constraints for validation
- Assuming data from database queries is valid without verification
- Sharing validation logic between unrelated modules
- Allowing invalid data to reach database operations
- Generic validation that doesn't understand module-specific business rules

## Practical Implementation

1. **Create Dedicated Validation Objects**: Design validation objects that
   encapsulate all validation logic for specific data types. Keep validation
   focused and module-specific rather than creating generic validators.

   ```python
   # Python with Pydantic - module-specific validation
   from pydantic import BaseModel, validator, Field
   from typing import Optional
   import re

   class UserRegistrationValidator(BaseModel):
       """Validates user data at the boundary of the UserService module"""
       email: str = Field(..., max_length=255)
       username: str = Field(..., min_length=3, max_length=50)
       password: str = Field(..., min_length=8)
       age: Optional[int] = Field(None, ge=13, le=120)

       @validator('email')
       def validate_email_format(cls, v):
           email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
           if not re.match(email_pattern, v):
               raise ValueError('Invalid email format')
           return v.lower()

       @validator('username')
       def validate_username_content(cls, v):
           # Module-specific business rule: usernames must be alphanumeric
           if not v.isalnum():
               raise ValueError('Username must contain only letters and numbers')
           return v

       @validator('password')
       def validate_password_strength(cls, v):
           # Module-specific security requirements
           if not re.search(r'[A-Z]', v):
               raise ValueError('Password must contain at least one uppercase letter')
           if not re.search(r'[a-z]', v):
               raise ValueError('Password must contain at least one lowercase letter')
           if not re.search(r'\d', v):
               raise ValueError('Password must contain at least one digit')
           return v

   class UserService:
       def __init__(self, db_session):
           self.session = db_session

       def register_user(self, raw_user_data: dict) -> User:
           """Register new user with explicit validation at module boundary"""
           try:
               # Validate input at module boundary
               valid_data = UserRegistrationValidator(**raw_user_data)
           except ValidationError as e:
               raise UserValidationError(f"Invalid user data: {e}")

           # Additional business rule validation specific to this module
           if self._email_already_exists(valid_data.email):
               raise UserValidationError("Email address already registered")

           # Create user with validated data
           user = User(
               email=valid_data.email,
               username=valid_data.username,
               password_hash=self._hash_password(valid_data.password),
               age=valid_data.age
           )

           self.session.add(user)
           self.session.commit()

           # Validate output - ensure persisted data meets expectations
           return self._validate_persisted_user(user)

       def _validate_persisted_user(self, user: User) -> User:
           """Validate data coming back from database"""
           if not user.id or user.id <= 0:
               raise DataIntegrityError("User persisted without valid ID")
           if not user.created_at:
               raise DataIntegrityError("User persisted without creation timestamp")
           return user
   ```

2. **Implement Pre-persistence Validation**: Validate all business rules and
   data constraints before attempting database operations. This ensures that
   invalid data never reaches the database layer.

   ```java
   // Java with Spring Boot - comprehensive pre-persistence validation
   @Service
   public class OrderService {

       @Autowired
       private OrderRepository orderRepository;

       @Autowired
       private ProductService productService;

       @Autowired
       private CustomerService customerService;

       public Order createOrder(CreateOrderRequest request) {
           // Validate input at service boundary
           OrderValidator validator = new OrderValidator();
           ValidationResult result = validator.validate(request);

           if (!result.isValid()) {
               throw new OrderValidationException(
                   "Order validation failed: " + result.getErrors()
               );
           }

           // Validate business rules with external dependencies
           Customer customer = customerService.getCustomer(request.getCustomerId());
           if (customer == null) {
               throw new OrderValidationException("Customer not found: " + request.getCustomerId());
           }

           List<Product> products = productService.getProducts(request.getProductIds());
           if (products.size() != request.getProductIds().size()) {
               throw new OrderValidationException("One or more products not found");
           }

           // Validate inventory availability
           for (OrderItemRequest item : request.getItems()) {
               Product product = products.stream()
                   .filter(p -> p.getId().equals(item.getProductId()))
                   .findFirst()
                   .orElseThrow(() -> new OrderValidationException("Product not found: " + item.getProductId()));

               if (product.getStock() < item.getQuantity()) {
                   throw new OrderValidationException(
                       String.format("Insufficient stock for product %s: requested %d, available %d",
                           product.getName(), item.getQuantity(), product.getStock())
                   );
               }
           }

           // Create order with validated data
           Order order = Order.builder()
               .customerId(request.getCustomerId())
               .status(OrderStatus.PENDING)
               .totalAmount(calculateTotal(request.getItems(), products))
               .createdAt(Instant.now())
               .build();

           // Add validated order items
           for (OrderItemRequest itemRequest : request.getItems()) {
               OrderItem item = OrderItem.builder()
                   .productId(itemRequest.getProductId())
                   .quantity(itemRequest.getQuantity())
                   .unitPrice(getProductPrice(itemRequest.getProductId(), products))
                   .build();
               order.addItem(item);
           }

           // Final validation before persistence
           validateOrderInvariants(order);

           return orderRepository.save(order);
       }

       private void validateOrderInvariants(Order order) {
           if (order.getItems().isEmpty()) {
               throw new OrderValidationException("Order must contain at least one item");
           }

           BigDecimal calculatedTotal = order.getItems().stream()
               .map(item -> item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
               .reduce(BigDecimal.ZERO, BigDecimal::add);

           if (!order.getTotalAmount().equals(calculatedTotal)) {
               throw new OrderValidationException("Order total does not match item totals");
           }
       }
   }
   ```

3. **Validate Query Results**: Implement validation for data retrieved from
   the database to ensure it meets current business rules and hasn't been
   corrupted. This protects against data inconsistencies and evolution issues.

   ```typescript
   // TypeScript with Zod - output validation for database queries
   import { z } from 'zod';

   const ProductSchema = z.object({
     id: z.number().positive(),
     name: z.string().min(1).max(255),
     price: z.number().positive(),
     stock: z.number().nonnegative(),
     categoryId: z.number().positive(),
     isActive: z.boolean(),
     createdAt: z.date(),
     updatedAt: z.date()
   });

   const ProductListSchema = z.array(ProductSchema);

   export class ProductService {
     constructor(private repository: ProductRepository) {}

     async getActiveProducts(): Promise<Product[]> {
       // Query database
       const rawProducts = await this.repository.findByStatus('active');

       // Validate query results at module boundary
       try {
         const validatedProducts = ProductListSchema.parse(rawProducts);

         // Additional business rule validation for current context
         const validProducts = validatedProducts.filter(product => {
           if (!product.isActive) {
             console.warn(`Found inactive product in active query: ${product.id}`);
             return false;
           }

           if (product.stock < 0) {
             console.error(`Product has negative stock: ${product.id}`);
             return false;
           }

           return true;
         });

         return validProducts;

       } catch (error) {
         if (error instanceof z.ZodError) {
           throw new DataValidationError(
             `Product data validation failed: ${error.message}`,
             { rawData: rawProducts, validationErrors: error.errors }
           );
         }
         throw error;
       }
     }

     async updateProduct(id: number, updates: Partial<Product>): Promise<Product> {
       // Validate input updates
       const UpdateSchema = ProductSchema.partial().refine(
         (data) => Object.keys(data).length > 0,
         { message: "At least one field must be updated" }
       );

       const validatedUpdates = UpdateSchema.parse(updates);

       // Retrieve current product and validate
       const currentProduct = await this.getProductById(id);
       if (!currentProduct) {
         throw new ProductNotFoundError(`Product not found: ${id}`);
       }

       // Validate business rules for updates
       if (validatedUpdates.price !== undefined && validatedUpdates.price <= 0) {
         throw new ProductValidationError("Product price must be positive");
       }

       if (validatedUpdates.stock !== undefined && validatedUpdates.stock < 0) {
         throw new ProductValidationError("Product stock cannot be negative");
       }

       // Perform update
       const updatedProduct = await this.repository.update(id, validatedUpdates);

       // Validate result
       const validatedResult = ProductSchema.parse(updatedProduct);

       // Ensure update was applied correctly
       for (const [key, value] of Object.entries(validatedUpdates)) {
         if (validatedResult[key as keyof Product] !== value) {
           throw new DataIntegrityError(
             `Update validation failed: ${key} was not updated correctly`
           );
         }
       }

       return validatedResult;
     }
   }
   ```

4. **Handle Foreign Key and Relationship Validation**: Validate relationships
   and foreign key constraints explicitly in code before relying on database
   constraints. This provides better error messages and module control.

   ```csharp
   // C# with Entity Framework Core - relationship validation
   public class CommentService
   {
       private readonly AppDbContext _context;
       private readonly ILogger<CommentService> _logger;

       public CommentService(AppDbContext context, ILogger<CommentService> logger)
       {
           _context = context;
           _logger = logger;
       }

       public async Task<Comment> CreateCommentAsync(CreateCommentRequest request)
       {
           // Validate input structure
           if (string.IsNullOrWhiteSpace(request.Content))
           {
               throw new CommentValidationException("Comment content cannot be empty");
           }

           if (request.Content.Length > 2000)
           {
               throw new CommentValidationException("Comment content cannot exceed 2000 characters");
           }

           // Validate foreign key relationships explicitly
           var user = await _context.Users
               .Where(u => u.Id == request.UserId && u.IsActive)
               .FirstOrDefaultAsync();

           if (user == null)
           {
               throw new CommentValidationException($"User not found or inactive: {request.UserId}");
           }

           var post = await _context.Posts
               .Where(p => p.Id == request.PostId && p.Status == PostStatus.Published)
               .FirstOrDefaultAsync();

           if (post == null)
           {
               throw new CommentValidationException($"Post not found or not published: {request.PostId}");
           }

           // Validate business rules
           if (post.CommentsDisabled)
           {
               throw new CommentValidationException("Comments are disabled for this post");
           }

           // Check if user is allowed to comment (rate limiting, permissions, etc.)
           var recentComments = await _context.Comments
               .Where(c => c.UserId == request.UserId &&
                          c.CreatedAt > DateTime.UtcNow.AddMinutes(-5))
               .CountAsync();

           if (recentComments >= 3)
           {
               throw new CommentValidationException("Rate limit exceeded: maximum 3 comments per 5 minutes");
           }

           // Create comment with validated data
           var comment = new Comment
           {
               UserId = request.UserId,
               PostId = request.PostId,
               Content = SanitizeContent(request.Content),
               Status = CommentStatus.Pending,
               CreatedAt = DateTime.UtcNow
           };

           _context.Comments.Add(comment);
           await _context.SaveChangesAsync();

           // Validate persisted result
           var persistedComment = await _context.Comments
               .Include(c => c.User)
               .Include(c => c.Post)
               .FirstOrDefaultAsync(c => c.Id == comment.Id);

           if (persistedComment == null)
           {
               throw new DataIntegrityException("Comment was not persisted correctly");
           }

           // Verify relationships were established
           if (persistedComment.User?.Id != request.UserId)
           {
               throw new DataIntegrityException("Comment user relationship not established correctly");
           }

           if (persistedComment.Post?.Id != request.PostId)
           {
               throw new DataIntegrityException("Comment post relationship not established correctly");
           }

           _logger.LogInformation("Comment created successfully: {CommentId} by user {UserId} on post {PostId}",
               persistedComment.Id, request.UserId, request.PostId);

           return persistedComment;
       }

       private string SanitizeContent(string content)
       {
           // Sanitize HTML, remove potentially dangerous content
           // This is a simplified example - use a proper sanitization library
           return content
               .Trim()
               .Replace("<script", "&lt;script", StringComparison.OrdinalIgnoreCase)
               .Replace("javascript:", "javascript-", StringComparison.OrdinalIgnoreCase);
       }
   }
   ```

5. **Implement Comprehensive Error Handling**: Design error handling that
   provides clear, actionable feedback while maintaining module boundaries.
   Avoid exposing internal implementation details through error messages.

   ```go
   // Go with GORM - structured error handling for validation
   package service

   import (
       "errors"
       "fmt"
       "regexp"
       "strings"
       "time"

       "gorm.io/gorm"
   )

   type ValidationError struct {
       Field   string `json:"field"`
       Value   interface{} `json:"value,omitempty"`
       Message string `json:"message"`
   }

   type ValidationErrors []ValidationError

   func (ve ValidationErrors) Error() string {
       var messages []string
       for _, err := range ve {
           messages = append(messages, fmt.Sprintf("%s: %s", err.Field, err.Message))
       }
       return "Validation failed: " + strings.Join(messages, "; ")
   }

   type UserService struct {
       db *gorm.DB
   }

   func (s *UserService) CreateUser(req CreateUserRequest) (*User, error) {
       // Validate input at module boundary
       if errs := s.validateCreateUserRequest(req); len(errs) > 0 {
           return nil, errs
       }

       // Check business rules
       if exists, err := s.emailExists(req.Email); err != nil {
           return nil, fmt.Errorf("failed to check email uniqueness: %w", err)
       } else if exists {
           return nil, ValidationErrors{{
               Field:   "email",
               Value:   req.Email,
               Message: "email address is already registered",
           }}
       }

       user := &User{
           Email:     strings.ToLower(req.Email),
           Username:  req.Username,
           FirstName: req.FirstName,
           LastName:  req.LastName,
           CreatedAt: time.Now(),
           UpdatedAt: time.Now(),
       }

       // Hash password
       hashedPassword, err := s.hashPassword(req.Password)
       if err != nil {
           return nil, fmt.Errorf("failed to process password: %w", err)
       }
       user.PasswordHash = hashedPassword

       // Persist to database
       if err := s.db.Create(user).Error; err != nil {
           return nil, s.handleDatabaseError(err)
       }

       // Validate persisted result
       if err := s.validatePersistedUser(user); err != nil {
           return nil, fmt.Errorf("data integrity check failed: %w", err)
       }

       return user, nil
   }

   func (s *UserService) validateCreateUserRequest(req CreateUserRequest) ValidationErrors {
       var errors ValidationErrors

       // Email validation
       if req.Email == "" {
           errors = append(errors, ValidationError{
               Field:   "email",
               Message: "email is required",
           })
       } else {
           emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
           if !emailRegex.MatchString(req.Email) {
               errors = append(errors, ValidationError{
                   Field:   "email",
                   Value:   req.Email,
                   Message: "email format is invalid",
               })
           }
           if len(req.Email) > 255 {
               errors = append(errors, ValidationError{
                   Field:   "email",
                   Value:   req.Email,
                   Message: "email cannot exceed 255 characters",
               })
           }
       }

       // Username validation
       if req.Username == "" {
           errors = append(errors, ValidationError{
               Field:   "username",
               Message: "username is required",
           })
       } else {
           if len(req.Username) < 3 || len(req.Username) > 50 {
               errors = append(errors, ValidationError{
                   Field:   "username",
                   Value:   req.Username,
                   Message: "username must be between 3 and 50 characters",
               })
           }
           usernameRegex := regexp.MustCompile(`^[a-zA-Z0-9_]+$`)
           if !usernameRegex.MatchString(req.Username) {
               errors = append(errors, ValidationError{
                   Field:   "username",
                   Value:   req.Username,
                   Message: "username can only contain letters, numbers, and underscores",
               })
           }
       }

       // Password validation
       if req.Password == "" {
           errors = append(errors, ValidationError{
               Field:   "password",
               Message: "password is required",
           })
       } else {
           if len(req.Password) < 8 {
               errors = append(errors, ValidationError{
                   Field:   "password",
                   Message: "password must be at least 8 characters long",
               })
           }
           if !regexp.MustCompile(`[A-Z]`).MatchString(req.Password) {
               errors = append(errors, ValidationError{
                   Field:   "password",
                   Message: "password must contain at least one uppercase letter",
               })
           }
           if !regexp.MustCompile(`[a-z]`).MatchString(req.Password) {
               errors = append(errors, ValidationError{
                   Field:   "password",
                   Message: "password must contain at least one lowercase letter",
               })
           }
           if !regexp.MustCompile(`\d`).MatchString(req.Password) {
               errors = append(errors, ValidationError{
                   Field:   "password",
                   Message: "password must contain at least one digit",
               })
           }
       }

       return errors
   }

   func (s *UserService) validatePersistedUser(user *User) error {
       if user.ID == 0 {
           return errors.New("user was not assigned an ID")
       }
       if user.CreatedAt.IsZero() {
           return errors.New("user was not assigned a creation timestamp")
       }
       if user.Email == "" {
           return errors.New("user email was not persisted")
       }
       return nil
   }

   func (s *UserService) handleDatabaseError(err error) error {
       // Convert database errors to domain-specific errors
       // without exposing internal implementation details
       if errors.Is(err, gorm.ErrDuplicatedKey) {
           return ValidationErrors{{
               Field:   "email",
               Message: "email address is already registered",
           }}
       }

       // Log the actual database error for debugging
       s.logger.Error("Database operation failed", "error", err)

       // Return generic error to client
       return errors.New("failed to create user due to system error")
   }
   ```

## Examples

```sql
-- ❌ BAD: Relying solely on database constraints for validation
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INTEGER CHECK (age >= 18)
);

-- Application code just inserts without validation
INSERT INTO users (email, age) VALUES ('invalid-email', 16);
-- Results in cryptic database error messages
```

```python
# ❌ BAD: No validation at module boundaries
class UserService:
    def create_user(self, user_data):
        # Directly persist without validation
        user = User(**user_data)
        self.session.add(user)
        self.session.commit()  # May fail with database constraint errors
        return user

# ✅ GOOD: Explicit validation at module boundary
class UserService:
    def create_user(self, user_data):
        # Validate at module boundary
        validator = UserValidator()
        if not validator.is_valid(user_data):
            raise UserValidationError(validator.errors)

        # Additional business rule validation
        if self._email_exists(user_data['email']):
            raise UserValidationError("Email already registered")

        # Create with validated data
        user = User(**validator.cleaned_data)
        self.session.add(user)
        self.session.commit()

        # Validate persisted result
        if not user.id:
            raise DataIntegrityError("User not persisted correctly")

        return user
```

```javascript
// ❌ BAD: Mixed validation responsibilities
async function createOrder(orderData) {
    // Some validation here, some in database, some missing
    if (orderData.total > 0) {  // Incomplete validation
        await db.orders.insert(orderData);  // May fail on foreign keys
    }
}

// ✅ GOOD: Complete validation at service boundary
class OrderService {
    async createOrder(orderData) {
        // Complete input validation
        const validatedData = await this.validateOrderInput(orderData);

        // Validate relationships
        await this.validateCustomerExists(validatedData.customerId);
        await this.validateProductsExist(validatedData.items);

        // Validate business rules
        await this.validateInventoryAvailable(validatedData.items);

        // Create order with validated data
        const order = await this.db.orders.insert(validatedData);

        // Validate result
        if (!order.id || order.status !== 'pending') {
            throw new DataIntegrityError('Order not created correctly');
        }

        return order;
    }

    async validateOrderInput(data) {
        const schema = {
            customerId: { type: 'number', required: true },
            items: { type: 'array', minLength: 1, required: true },
            total: { type: 'number', min: 0.01, required: true }
        };

        return this.validator.validate(data, schema);
    }
}
```

## Related Bindings

- [fail-fast-validation](../../core/fail-fast-validation.md): Data validation
  at boundaries implements fail-fast principles by catching invalid data
  immediately at module entry points rather than allowing it to propagate
  through the system. Both patterns work together to create robust, predictable
  error handling.

- [use-structured-logging](../../core/use-structured-logging.md): Validation
  failures should be logged with structured data to enable monitoring and
  debugging. Both patterns support observability by making validation events
  visible and trackable across the system.

- [transaction-management-patterns](transaction-management-patterns.md):
  Validation and transaction management work together to ensure data integrity.
  Validation should occur before beginning transactions, and transaction
  boundaries should include validation of the final state before commit.
