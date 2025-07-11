---
id: audit-logging-implementation
last_modified: '2025-01-12'
version: '0.2.0'
derived_from: explicit-over-implicit
enforced_by: audit triggers & compliance review
---

# Binding: Implement Comprehensive Audit Logging for Data Changes

All database operations that modify business-critical data must generate
explicit, immutable audit records that capture the complete context of each
change. Design audit logging to make data lineage, compliance requirements,
and security investigations transparent rather than relying on implicit
logging or reconstructing changes from incomplete information.

## Rationale

This binding directly implements our explicit-over-implicit tenet by ensuring
that all data modifications are explicitly recorded with complete context
rather than relying on implicit assumptions about what happened to data over
time. In business applications, understanding "what changed, when, who did it,
and why" is critical for compliance, debugging, security investigation, and
business intelligence.

Like a medical chart that records every procedure with timestamps and context, comprehensive audit logging captures not just what changed, but who, when, why, and under what business context. This makes compliance audits, security investigations, and data quality analysis straightforward rather than requiring complex forensic reconstruction.

The challenge is that audit logging is often implemented through generic database triggers or application-level logging that captures insufficient context. This leads to audit records that tell you "something changed" but not the business context. Explicit audit logging designs capture the full business context of each change.

## Rule Definition

Comprehensive audit logging means systematically capturing the complete context
of all data modifications in immutable records that support compliance,
security, and operational requirements. This requires explicit design choices
about what to log, how to structure audit records, and how to ensure audit
integrity over time.

Key principles for explicit audit logging:

- **Complete Context Capture**: Record not just what changed, but who, when, why, and under what business context
- **Immutable Audit Records**: Design audit logs that cannot be modified or deleted after creation
- **Structured Audit Schema**: Use consistent, queryable formats that support compliance reporting and analysis
- **Business-Aware Logging**: Include business process context, not just technical operation details
- **Retention and Access Controls**: Implement explicit policies for audit log retention and access

Common patterns this binding requires:

- Audit tables with immutable insert-only designs
- Structured audit record formats with mandatory context fields
- Integration with business process identifiers and user authentication
- Automated compliance reporting from audit logs
- Retention policies that meet regulatory requirements

What this explicitly prohibits:

- Generic database change logs without business context
- Audit records that can be modified or deleted after creation
- Inconsistent audit formats across different data types
- Missing correlation between audit records and business processes
- Audit logging that requires manual interpretation for compliance

## Practical Implementation

1. **Design Immutable Audit Table Structures**: Create dedicated audit tables
   that capture complete change context with immutable, append-only designs
   that prevent tampering with historical records.

   ```sql
   -- Comprehensive audit table design
   CREATE TABLE user_audit_log (
       audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

       -- Business context
       user_id BIGINT NOT NULL,
       initiated_by_user_id BIGINT NOT NULL,
       business_process VARCHAR(100) NOT NULL, -- 'user_registration', 'profile_update', etc.
       request_id VARCHAR(100), -- Correlation with application requests
       session_id VARCHAR(100),

       -- Change details
       operation_type VARCHAR(20) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
       table_name VARCHAR(100) NOT NULL DEFAULT 'users',

       -- Complete state capture
       old_values JSONB, -- Previous state (NULL for INSERT)
       new_values JSONB, -- New state (NULL for DELETE)
       changed_fields TEXT[], -- Array of field names that changed

       -- Authorization context
       authorization_method VARCHAR(50), -- 'api_key', 'oauth', 'admin_override'
       authorized_by_role VARCHAR(100),
       ip_address INET,
       user_agent TEXT,

       -- Compliance metadata
       data_classification VARCHAR(50), -- 'public', 'internal', 'confidential', 'restricted'
       retention_category VARCHAR(50), -- Links to retention policy
       compliance_tags TEXT[], -- GDPR, HIPAA, SOX, etc.

       -- Integrity verification
       record_hash VARCHAR(64) NOT NULL, -- Hash of critical fields for integrity checking

       -- Index for efficient querying
       CONSTRAINT user_audit_log_immutable CHECK (true) -- Prevents updates via constraint
   );

   -- Prevent any modifications to audit records
   CREATE RULE user_audit_no_update AS ON UPDATE TO user_audit_log DO INSTEAD NOTHING;
   CREATE RULE user_audit_no_delete AS ON DELETE TO user_audit_log DO INSTEAD NOTHING;

   -- Indexes for compliance reporting
   CREATE INDEX idx_user_audit_user_id_time ON user_audit_log (user_id, event_timestamp DESC);
   CREATE INDEX idx_user_audit_business_process ON user_audit_log (business_process, event_timestamp DESC);
   CREATE INDEX idx_user_audit_compliance_tags ON user_audit_log USING GIN (compliance_tags);
   CREATE INDEX idx_user_audit_ip_address ON user_audit_log (ip_address, event_timestamp DESC);
   ```

2. **Implement Context-Aware Audit Triggers**: Create database triggers that
   automatically capture comprehensive context for all data modifications.

   ```sql
   -- Simplified audit trigger that captures business context
   CREATE OR REPLACE FUNCTION audit_user_changes() RETURNS TRIGGER AS $$
   BEGIN
       INSERT INTO user_audit_log (
           user_id, initiated_by_user_id, business_process,
           operation_type, old_values, new_values, event_timestamp
       ) VALUES (
           COALESCE(NEW.id, OLD.id),
           current_setting('app.user_id')::BIGINT,
           current_setting('app.business_process'),
           TG_OP,
           CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD) END,
           CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) END,
           NOW()
       );
       RETURN COALESCE(NEW, OLD);
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER user_audit_trigger
       AFTER INSERT OR UPDATE OR DELETE ON users
       FOR EACH ROW EXECUTE FUNCTION audit_user_changes();
   ```

3. **Build Business-Context Integration**: Integrate audit logging with
   application business logic to capture meaningful context about why changes
   occurred and under what business process authority.

   ```typescript
   // Service layer with audit context management
   class AuditContext {
     constructor(
       public userId: number,
       public businessProcess: string,
       public requestId: string,
       public authMethod: string
     ) {}
   }

   class UserService {
     async updateProfile(userId: number, data: any, context: AuditContext) {
       // Set audit context for database triggers
       await this.db.query('SELECT set_config($1, $2, false)', [
         'app.audit_context',
         JSON.stringify(context)
       ]);

       // Perform update - audit logging happens automatically via triggers
       await this.db.query('UPDATE users SET email = $1 WHERE id = $2', [
         data.email, userId
       ]);
     }
   }
   ```

## Examples

```sql
-- ❌ BAD: Generic database logging without business context
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    timestamp TIMESTAMP DEFAULT NOW(),
    user_id INTEGER
);

-- Minimal context, no business meaning, mutable records
INSERT INTO audit_log (table_name, operation, user_id)
VALUES ('users', 'UPDATE', 123);
```

```sql
-- ✅ GOOD: Comprehensive business-aware audit logging
CREATE TABLE user_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Complete business context
    user_id BIGINT NOT NULL,
    initiated_by_user_id BIGINT NOT NULL,
    business_process VARCHAR(100) NOT NULL,
    request_id VARCHAR(100),

    -- Change details with full state capture
    operation_type VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,

    -- Compliance and retention metadata
    data_classification VARCHAR(50),
    compliance_tags TEXT[],
    record_hash VARCHAR(64) NOT NULL
);

-- Immutable audit records with integrity verification
CREATE RULE user_audit_no_update AS ON UPDATE TO user_audit_log DO INSTEAD NOTHING;
```

## Related Bindings

- [use-structured-logging](../../core/use-structured-logging.md): Audit logging
  implementations must coordinate with structured logging to ensure consistent
  correlation IDs, business context, and compliance metadata across all system
  logs. Both patterns work together to create comprehensive observability.

- [data-validation-at-boundaries](../../docs/bindings/categories/database/data-validation-at-boundaries.md): Audit
  logging requires validation of audit context and business process identifiers
  to ensure audit records contain accurate, complete information for compliance
  and investigation purposes.

- [transaction-management-patterns](../../docs/bindings/categories/database/transaction-management-patterns.md): Audit
  logging must be integrated with transaction boundaries to ensure audit records
  are created atomically with data changes, preventing scenarios where data
  changes succeed but audit logging fails.
