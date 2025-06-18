# Grug Pattern Examples

Simple examples showing grug principles in action. No complex setups, just clear before/after comparisons.

## 1. Complexity Demon Slaying

### Before (Complex)
```typescript
// Abstract factory pattern for "flexibility"
interface NotificationFactory {
  createNotification(type: string, config: NotificationConfig): Notification;
}

class EmailNotificationFactory implements NotificationFactory {
  // 50+ lines of factory code...
}

// Usage requires factory + config object
const factory = NotificationFactoryManager.getInstance();
const notification = factory.createNotification('email.marketing', {
  recipient: 'user@example.com',
  subject: 'Hello',
  // ... 15 more config options
});
```

### After (Simple)
```typescript
// Just a function
function sendEmail(to: string, subject: string, body: string) {
  // send the email
}

// Direct usage
sendEmail('user@example.com', 'Hello', 'Welcome!');
```

**Lesson:** Factories and patterns often add complexity without value. Start simple.

## 2. Humble Debugging

### Before (Print Debugging)
```javascript
function calculateDiscount(cart) {
  console.log('Starting calculation...');
  console.log('Cart items:', cart.items);

  const subtotal = cart.items.reduce((sum, item) => {
    console.log(`Processing ${item.name}`);
    const itemTotal = item.price * item.quantity;
    console.log(`Item total: ${itemTotal}`);
    return sum + itemTotal;
  }, 0);

  console.log('Subtotal:', subtotal);
  // ... more console.logs
}
```

### After (Debugger-First)
```javascript
function calculateDiscount(cart) {
  const subtotal = cart.items.reduce((sum, item) => {
    return sum + (item.price * item.quantity);
  }, 0);

  // Set breakpoint here, inspect all values
  return subtotal * discount;
}
```

**Lesson:** Debuggers show everything. Print debugging shows only what you remember to log.

## 3. Integration-First Testing

### Before (Too Many Unit Tests)
```javascript
// 15 unit tests for simple getters/setters
test('User.getName returns name', () => {
  const user = new User('John');
  expect(user.getName()).toBe('John');
});

// Testing implementation details
test('User stores name in private field', () => {
  const user = new User('John');
  expect(user._name).toBe('John'); // Testing internals!
});
```

### After (Integration Focus)
```javascript
// Test at service boundaries
test('UserService creates user and sends welcome email', async () => {
  const service = new UserService(db, emailer);
  const user = await service.createUser('John', 'john@example.com');

  expect(user.id).toBeDefined();
  expect(emailer.sentEmails).toContainEqual({
    to: 'john@example.com',
    template: 'welcome'
  });
});
```

**Lesson:** Test where components interact, not every internal detail.

## 4. Saying No to Complexity

### The Request
"We need a configuration system that supports YAML, JSON, environment variables, with validation, transformation, and runtime reloading."

### The Response
"We have 3 config values. Let's use environment variables:
- `DATABASE_URL`
- `PORT`
- `DEBUG`

If we need more later, we'll add them."

**Lesson:** Push back on premature flexibility. YAGNI.

## 5. Tool Mastery Over Tool Hopping

### Before
```
Monday: "Let's try this new bundler!"
Tuesday: "Actually, this other one is faster!"
Wednesday: "Wait, there's a new framework!"
// Never mastering any tool
```

### After
```
Year 1: Master your debugger completely
Year 2: Still using same debugger, 10x more productive
Year 3: Teaching others advanced debugging techniques
```

**Lesson:** Deep knowledge of one tool beats shallow knowledge of many.

## Key Takeaways

1. **Start simple** - You can always add complexity later (but you probably won't need to)
2. **Use debuggers** - They're already there, learn them
3. **Test at boundaries** - That's where bugs live
4. **Say no** - Most requested features aren't needed
5. **Master your tools** - Invest time in learning, not switching

Remember: "complexity very, very bad" - these examples show how to spot and eliminate it.
