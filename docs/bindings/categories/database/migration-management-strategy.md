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

This binding directly implements our simplicity tenet by eliminating the complexity
of bidirectional migration systems. When you try to maintain both "up" and "down"
migrations, you're essentially managing two separate codebases that must remain
perfectly synchronized—a recipe for bugs and maintenance nightmares. The apparent
safety of rollback capabilities is often illusory, as data transformations frequently
cannot be reversed without data loss.

Think of database migrations like a ratchet mechanism—designed to move in one
direction with confidence. Just as you wouldn't try to "un-bake" a cake, certain
database transformations fundamentally change the shape of your data in ways that
cannot be meaningfully reversed. By embracing forward-only migrations, we acknowledge
this reality and design our changes to be safe, incremental, and thoroughly tested
before deployment.

This approach forces better planning and more careful consideration of schema changes.
When you know there's no easy "undo" button, you're more likely to think through the
implications, test thoroughly, and deploy incrementally. This discipline leads to more
stable systems and fewer emergency rollbacks driven by poorly planned changes.

## Rule Definition

Forward-only migrations require a fundamental shift in how we think about database
evolution. Rather than treating migrations as reversible experiments, we treat them
as permanent improvements that must be carefully planned and validated.

Key principles of forward-only migrations:

- **One Direction**: Migrations only define how to move the schema forward, never backward
- **Backward Compatibility**: New schemas must work with existing application code during deployment
- **Data Preservation**: Migrations must never lose data without explicit, documented intention
- **Incremental Changes**: Large changes are broken into smaller, safer steps
- **Version Tracking**: Every migration is versioned and tracked to ensure ordered application

Common migration patterns that support this approach:

- Adding new columns with defaults or as nullable
- Creating new tables before removing old ones
- Using feature flags to control application behavior during transitions
- Maintaining compatibility windows where both old and new schemas work

What this explicitly prohibits:

- "Down" migrations that attempt to reverse schema changes
- Destructive operations without data preservation strategies
- Large, multi-step migrations that cannot be safely interrupted
- Relying on rollback as a primary recovery strategy

## Practical Implementation

1. **Use Additive Changes**: Always prefer adding new structures over modifying
   existing ones. Create new columns or tables, migrate data, then remove old
   structures only after confirming the new approach works correctly.

   ```sql
   -- Step 1: Add new column (safe, additive)
   ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMP;

   -- Step 2: Backfill data in batches (controlled migration)
   UPDATE users
   SET email_verified_at = created_at
   WHERE email_verified = true
     AND email_verified_at IS NULL
   LIMIT 1000;

   -- Step 3: Only after full migration and code deployment
   -- ALTER TABLE users DROP COLUMN email_verified;
   ```

2. **Implement Compatibility Windows**: Design migrations that allow both old and
   new application code to function during the deployment window. This enables
   zero-downtime deployments and safe rollbacks at the application level.

   ```python
   # Django migration with compatibility window
   class Migration(migrations.Migration):
       dependencies = [('myapp', '0001_initial')]

       operations = [
           # Add new field alongside old one
           migrations.AddField(
               model_name='Order',
               name='status_code',
               field=models.CharField(max_length=20, null=True),
           ),
           # Data migration maintains both fields
           migrations.RunPython(
               migrate_status_to_code,
               reverse_code=migrations.RunPython.noop,  # No reversal
           ),
       ]

   def migrate_status_to_code(apps, schema_editor):
       Order = apps.get_model('myapp', 'Order')
       # Map old integer status to new string codes
       status_map = {1: 'pending', 2: 'completed', 3: 'cancelled'}

       for order in Order.objects.filter(status_code__isnull=True):
           order.status_code = status_map.get(order.status, 'unknown')
           order.save()
   ```

3. **Version Every Migration**: Use a consistent versioning scheme that ensures
   migrations are applied in the correct order across all environments. Include
   timestamps or sequential numbers in migration identifiers.

   ```javascript
   // Knex.js migration with timestamp versioning
   // File: 20250112_140000_add_user_preferences.js
   exports.up = async function(knex) {
       await knex.schema.createTable('user_preferences', table => {
           table.uuid('user_id').primary();
           table.json('preferences').notNullable().defaultTo('{}');
           table.timestamps(true, true);

           table.foreign('user_id')
               .references('users.id')
               .onDelete('CASCADE');
       });

       // Track migration completion
       await knex('migration_history').insert({
           version: '20250112_140000',
           name: 'add_user_preferences',
           applied_at: knex.fn.now()
       });
   };

   // No down function - this is intentional
   exports.down = async function() {
       throw new Error('Forward-only migrations - no rollback available');
   };
   ```

4. **Create Robust Testing Strategies**: Test migrations against production-like
   data volumes and verify both the schema changes and data transformations work
   correctly. Include performance testing for large tables.

   ```ruby
   # RSpec test for Rails migration
   require 'rails_helper'
   require 'rake'

   RSpec.describe 'AddIndexToUserEmail migration' do
     before do
       # Create test data at scale
       User.insert_all(
         10_000.times.map { |i| { email: "user#{i}@example.com" } }
       )
     end

     it 'creates index within acceptable time' do
       expect {
         Timeout::timeout(30) do
           ActiveRecord::Migration.run(:up, 20250112140000)
         end
       }.not_to raise_error

       # Verify index exists and is used
       explain = User.connection.execute(
         "EXPLAIN SELECT * FROM users WHERE email = 'test@example.com'"
       )
       expect(explain.to_s).to include('Index Scan')
     end
   end
   ```

5. **Document Migration Decisions**: Every migration should include clear comments
   explaining why the change is being made, what compatibility requirements exist,
   and any special deployment considerations.

   ```sql
   -- Migration: 2025_01_12_split_user_names.sql
   -- Purpose: Split full_name into first_name and last_name for better querying
   -- Compatibility: Apps must read both old and new columns during transition
   -- Deploy: This migration must run before app version 2.5.0 is deployed

   BEGIN;

   -- Add new columns without NOT NULL to avoid locking
   ALTER TABLE users
   ADD COLUMN first_name VARCHAR(255),
   ADD COLUMN last_name VARCHAR(255);

   -- Create function for background data migration
   CREATE OR REPLACE FUNCTION migrate_user_names() RETURNS void AS $$
   DECLARE
     batch_size INT := 1000;
     last_id BIGINT := 0;
   BEGIN
     LOOP
       WITH batch AS (
         SELECT id, full_name
         FROM users
         WHERE id > last_id
           AND first_name IS NULL
         ORDER BY id
         LIMIT batch_size
         FOR UPDATE SKIP LOCKED
       )
       UPDATE users u
       SET first_name = split_part(b.full_name, ' ', 1),
           last_name = split_part(b.full_name, ' ', 2)
       FROM batch b
       WHERE u.id = b.id;

       GET DIAGNOSTICS last_id = ROW_COUNT;
       EXIT WHEN last_id < batch_size;

       -- Brief pause to avoid overloading replica lag
       PERFORM pg_sleep(0.1);
     END LOOP;
   END;
   $$ LANGUAGE plpgsql;

   COMMIT;
   ```

## Examples

```sql
-- ❌ BAD: Destructive migration with impossible rollback
CREATE OR REPLACE FUNCTION migrate_prices() RETURNS void AS $$
BEGIN
  -- Converting prices from dollars to cents
  UPDATE products SET price = price * 100;

  -- How do you rollback? Divide by 100? What if new prices were added?
  -- This creates an irreversible state change
END;
$$ LANGUAGE plpgsql;

-- ✅ GOOD: Safe additive migration with compatibility window
CREATE OR REPLACE FUNCTION migrate_prices() RETURNS void AS $$
BEGIN
  -- Add new column for cents
  ALTER TABLE products ADD COLUMN price_cents INTEGER;

  -- Migrate existing data
  UPDATE products
  SET price_cents = ROUND(price * 100)::INTEGER
  WHERE price_cents IS NULL;

  -- App can now use either column during transition
  -- Old column removed only after full deployment
END;
$$ LANGUAGE plpgsql;
```

```python
# ❌ BAD: Migration with complex rollback logic
class Migration(migrations.Migration):
    def forwards(self, orm):
        # Merge first_name and last_name into full_name
        for user in orm.User.objects.all():
            user.full_name = f"{user.first_name} {user.last_name}"
            user.save()

        # Delete original columns
        db.delete_column('users', 'first_name')
        db.delete_column('users', 'last_name')

    def backwards(self, orm):
        # This is a guess at best - what about "Mary Jane Smith"?
        db.add_column('users', 'first_name', models.CharField(max_length=50))
        db.add_column('users', 'last_name', models.CharField(max_length=50))

        for user in orm.User.objects.all():
            parts = user.full_name.split(' ', 1)
            user.first_name = parts[0]
            user.last_name = parts[1] if len(parts) > 1 else ''
            user.save()

# ✅ GOOD: Forward-only migration with careful planning
class Migration(migrations.Migration):
    dependencies = [('users', '0001_initial')]
    atomic = True  # Ensure all-or-nothing execution

    operations = [
        # Step 1: Add new column (this migration)
        migrations.AddField(
            model_name='User',
            name='full_name',
            field=models.CharField(max_length=255, blank=True),
        ),

        # Step 2: Data migration (separate migration)
        # Step 3: Update app to use full_name (deployment)
        # Step 4: Remove old columns (future migration after verification)
    ]
```

```javascript
// ❌ BAD: Single large migration with multiple concerns
exports.up = async (knex) => {
  // Too many changes in one migration
  await knex.schema.alterTable('orders', table => {
    table.dropColumn('status');  // Data loss!
    table.enum('state', ['pending', 'processing', 'completed']);
    table.decimal('tax_amount');
    table.decimal('shipping_amount');
    table.dropColumn('total');  // More data loss!
    table.index(['user_id', 'created_at']);
    table.foreign('user_id').references('users.id');
  });
};

exports.down = async (knex) => {
  // Impossible to restore lost data
  // This gives false confidence in rollback capability
};

// ✅ GOOD: Incremental migrations with data preservation
// Migration 1: Add new columns
exports.up = async (knex) => {
  await knex.schema.alterTable('orders', table => {
    table.enum('state', ['pending', 'processing', 'completed']).nullable();
    table.decimal('tax_amount', 10, 2).defaultTo(0);
    table.decimal('shipping_amount', 10, 2).defaultTo(0);
  });

  // Preserve existing data by computing values
  await knex.raw(`
    UPDATE orders
    SET state = CASE
      WHEN status = 1 THEN 'pending'
      WHEN status = 2 THEN 'processing'
      WHEN status = 3 THEN 'completed'
    END
  `);
};

// Subsequent migrations handle cleanup after verification
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
