---
id: migration-management-strategy
last_modified: '2025-01-12'
version: '0.1.0'
derived_from: simplicity
enforced_by: migration tools & code review
---

# Binding: Apply Forward-Only Database Migrations

Database schema changes must be implemented as forward-only migrations that can be
safely applied in sequence without requiring rollback capabilities. Each migration
should be atomic, idempotent when possible, and maintain data integrity throughout
the evolution process.

## Rationale

Bidirectional migration systems create complexity by managing two synchronized codebases for "up" and "down" operations. Most rollback capabilities are illusory—data transformations often cannot be reversed without loss. Forward-only migrations force better planning, thorough testing, and incremental deployment, leading to more stable systems.

## Rule Definition

**Core Requirements:**
- **One Direction**: Migrations only move schema forward, never backward
- **Backward Compatibility**: New schemas work with existing application code during deployment
- **Data Preservation**: Never lose data without explicit, documented intention
- **Incremental Changes**: Break large changes into smaller, safer steps
- **Version Tracking**: Every migration is versioned and applied in order

**Required Patterns:**
- Adding new columns with defaults or as nullable
- Creating new tables before removing old ones
- Using feature flags during transitions
- Maintaining compatibility windows for safe deployments

**Prohibited Patterns:**
- "Down" migrations attempting to reverse schema changes
- Destructive operations without data preservation
- Large, multi-step migrations that cannot be safely interrupted
- Relying on rollback as primary recovery strategy

## Practical Implementation

**Additive Changes:**
```sql
-- Step 1: Add new column (safe, additive)
ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMP;

-- Step 2: Backfill data in batches
UPDATE users SET email_verified_at = created_at
WHERE email_verified = true AND email_verified_at IS NULL LIMIT 1000;

-- Step 3: Drop old column only after verification
-- ALTER TABLE users DROP COLUMN email_verified;
```

**Compatibility Windows:**
```python
class Migration(migrations.Migration):
    operations = [
        migrations.AddField(
            model_name='Order',
            name='status_code',
            field=models.CharField(max_length=20, null=True),
        ),
        migrations.RunPython(migrate_status_to_code, reverse_code=migrations.RunPython.noop),
    ]

def migrate_status_to_code(apps, schema_editor):
    Order = apps.get_model('myapp', 'Order')
    status_map = {1: 'pending', 2: 'completed', 3: 'cancelled'}
    for order in Order.objects.filter(status_code__isnull=True):
        order.status_code = status_map.get(order.status, 'unknown')
        order.save()
```

**Version Tracking:**
```javascript
// File: 20250112_140000_add_user_preferences.js
exports.up = async function(knex) {
    await knex.schema.createTable('user_preferences', table => {
        table.uuid('user_id').primary();
        table.json('preferences').defaultTo('{}');
        table.foreign('user_id').references('users.id').onDelete('CASCADE');
    });
};

exports.down = async function() {
    throw new Error('Forward-only migrations - no rollback available');
};
```

**Testing Strategies:**
```ruby
RSpec.describe 'Migration' do
  it 'completes within acceptable time' do
    User.insert_all(10_000.times.map { |i| { email: "user#{i}@example.com" } })

    expect {
      Timeout::timeout(30) { ActiveRecord::Migration.run(:up, 20250112140000) }
    }.not_to raise_error
  end
end
```

**Documentation:**
```sql
-- Migration: split_user_names.sql
-- Purpose: Split full_name for better querying
-- Compatibility: Apps must read both columns during transition

ALTER TABLE users ADD COLUMN first_name VARCHAR(255), ADD COLUMN last_name VARCHAR(255);

UPDATE users SET
  first_name = split_part(full_name, ' ', 1),
  last_name = split_part(full_name, ' ', 2)
WHERE first_name IS NULL;
```

## Examples

```sql
-- ❌ BAD: Destructive migration with impossible rollback
UPDATE products SET price = price * 100;  -- How to rollback? Data loss!

-- ✅ GOOD: Safe additive migration with compatibility window
ALTER TABLE products ADD COLUMN price_cents INTEGER;
UPDATE products SET price_cents = ROUND(price * 100)::INTEGER WHERE price_cents IS NULL;
-- App uses either column during transition; old column removed later
```

```python
# ❌ BAD: Migration with complex rollback logic
def forwards(self, orm):
    for user in orm.User.objects.all():
        user.full_name = f"{user.first_name} {user.last_name}"
        user.save()
    db.delete_column('users', 'first_name')  # Data loss!

# ✅ GOOD: Forward-only migration with careful planning
class Migration(migrations.Migration):
    operations = [
        migrations.AddField(model_name='User', name='full_name',
                          field=models.CharField(max_length=255, blank=True)),
        # Data migration and cleanup happen in separate migrations
    ]
```

```javascript
// ❌ BAD: Single large migration with data loss
await knex.schema.alterTable('orders', table => {
  table.dropColumn('status');  // Data loss!
  table.enum('state', ['pending', 'processing', 'completed']);
});

// ✅ GOOD: Incremental migration preserving data
await knex.schema.alterTable('orders', table => {
  table.enum('state', ['pending', 'processing', 'completed']).nullable();
});
await knex.raw(`UPDATE orders SET state = CASE WHEN status = 1 THEN 'pending' END`);
```

## Related Bindings

- [external-configuration](../../core/external-configuration.md): Migration scripts must
  externalize environment-specific settings like database connections and feature flags.
  This ensures the same migration code works across development, staging, and production
  environments without modification.

- [fail-fast-validation](../../core/fail-fast-validation.md): Migrations should validate
  their preconditions before making changes. Check that expected tables exist, verify
  data integrity constraints will be maintained, and ensure the migration hasn't already
  been applied. Fail immediately with clear errors rather than corrupting data.

- [use-structured-logging](../../core/use-structured-logging.md): Migration tools must
  log their actions with structured data including timestamps, affected tables, row
  counts, and duration. This creates an audit trail for troubleshooting and compliance,
  especially important given the irreversible nature of forward-only migrations.
