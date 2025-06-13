---
id: audit-logging-implementation
last_modified: '2025-01-12'
version: '0.1.0'
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

Think of audit logging like maintaining a detailed medical chart for a patient.
Every procedure, medication change, and vital sign measurement is explicitly
recorded with timestamps, signatures, and context. If a patient's condition
changes unexpectedly, doctors can trace back through the complete history to
understand what happened and make informed decisions. Similarly, when business
data changes unexpectedly—whether due to bugs, security breaches, or legitimate
business operations—having a complete audit trail enables rapid investigation
and resolution.

The challenge with audit logging is that it's often implemented as an
afterthought through generic database triggers or application-level logging
that captures insufficient context. This leads to audit records that tell you
"something changed" but not why it changed, what business process initiated
it, or whether the change was authorized. Explicit audit logging designs
capture the full business context of each change, making compliance audits,
security investigations, and data quality analysis straightforward rather
than requiring complex forensic reconstruction.

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
   automatically capture comprehensive context for all data modifications,
   ensuring no changes escape audit logging.

   ```sql
   -- Comprehensive audit trigger function
   CREATE OR REPLACE FUNCTION audit_user_changes()
   RETURNS TRIGGER AS $$
   DECLARE
       audit_context JSONB;
       change_hash VARCHAR(64);
       changed_cols TEXT[] := ARRAY[]::TEXT[];
       col_name TEXT;
   BEGIN
       -- Extract audit context from application
       audit_context := current_setting('app.audit_context', true)::JSONB;

       IF audit_context IS NULL THEN
           RAISE EXCEPTION 'Audit context required for all user table modifications. Set app.audit_context session variable.';
       END IF;

       -- Determine changed fields for UPDATE operations
       IF TG_OP = 'UPDATE' THEN
           FOR col_name IN
               SELECT column_name
               FROM information_schema.columns
               WHERE table_name = 'users' AND table_schema = 'public'
           LOOP
               EXECUTE format('SELECT ($1).%I IS DISTINCT FROM ($2).%I', col_name, col_name)
               USING OLD, NEW INTO STRICT changed_cols[array_length(changed_cols, 1) + 1];

               IF changed_cols[array_length(changed_cols, 1)] THEN
                   changed_cols[array_length(changed_cols, 1)] := col_name;
               ELSE
                   changed_cols := changed_cols[1:array_length(changed_cols, 1) - 1];
               END IF;
           END LOOP;
       END IF;

       -- Calculate integrity hash
       change_hash := encode(
           digest(
               COALESCE(audit_context->>'initiated_by_user_id', '') ||
               COALESCE(audit_context->>'business_process', '') ||
               TG_OP ||
               COALESCE(OLD::TEXT, '') ||
               COALESCE(NEW::TEXT, ''),
               'sha256'
           ),
           'hex'
       );

       -- Insert comprehensive audit record
       INSERT INTO user_audit_log (
           user_id,
           initiated_by_user_id,
           business_process,
           request_id,
           session_id,
           operation_type,
           old_values,
           new_values,
           changed_fields,
           authorization_method,
           authorized_by_role,
           ip_address,
           user_agent,
           data_classification,
           retention_category,
           compliance_tags,
           record_hash
       ) VALUES (
           COALESCE(NEW.id, OLD.id),
           (audit_context->>'initiated_by_user_id')::BIGINT,
           audit_context->>'business_process',
           audit_context->>'request_id',
           audit_context->>'session_id',
           TG_OP,
           CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
           CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW) ELSE to_jsonb(NEW) END,
           changed_cols,
           audit_context->>'authorization_method',
           audit_context->>'authorized_by_role',
           (audit_context->>'ip_address')::INET,
           audit_context->>'user_agent',
           COALESCE(audit_context->>'data_classification', 'internal'),
           COALESCE(audit_context->>'retention_category', 'standard'),
           string_to_array(COALESCE(audit_context->>'compliance_tags', ''), ','),
           change_hash
       );

       RETURN COALESCE(NEW, OLD);
   END;
   $$ LANGUAGE plpgsql;

   -- Apply trigger to users table
   CREATE TRIGGER user_audit_trigger
       AFTER INSERT OR UPDATE OR DELETE ON users
       FOR EACH ROW EXECUTE FUNCTION audit_user_changes();
   ```

3. **Build Business-Context Integration**: Integrate audit logging with
   application business logic to capture meaningful context about why changes
   occurred and under what business process authority.

   ```python
   # Python service layer with comprehensive audit context
   import json
   import hashlib
   from contextlib import contextmanager
   from dataclasses import dataclass, asdict
   from typing import Optional, List, Dict, Any
   from datetime import datetime
   import logging

   logger = logging.getLogger(__name__)

   @dataclass
   class AuditContext:
       initiated_by_user_id: int
       business_process: str
       request_id: str
       session_id: str
       authorization_method: str
       authorized_by_role: str
       ip_address: str
       user_agent: str
       data_classification: str = 'internal'
       retention_category: str = 'standard'
       compliance_tags: List[str] = None
       additional_context: Dict[str, Any] = None

       def __post_init__(self):
           if self.compliance_tags is None:
               self.compliance_tags = []
           if self.additional_context is None:
               self.additional_context = {}

   class AuditManager:
       """Manages audit context for database operations"""

       def __init__(self, db_connection):
           self.db_connection = db_connection

       @contextmanager
       def audit_context(self, context: AuditContext):
           """Set audit context for all database operations within this block"""

           # Validate required fields
           self._validate_audit_context(context)

           # Convert to JSON for PostgreSQL session variable
           context_json = json.dumps(asdict(context))

           try:
               # Set audit context in database session
               with self.db_connection.cursor() as cursor:
                   cursor.execute(
                       "SELECT set_config('app.audit_context', %s, false)",
                       (context_json,)
                   )

               logger.info("Audit context established", extra={
                   'business_process': context.business_process,
                   'initiated_by_user_id': context.initiated_by_user_id,
                   'request_id': context.request_id,
                   'compliance_tags': context.compliance_tags
               })

               yield context

           finally:
               # Clear audit context
               with self.db_connection.cursor() as cursor:
                   cursor.execute("SELECT set_config('app.audit_context', NULL, false)")

       def _validate_audit_context(self, context: AuditContext):
           """Validate that audit context contains all required fields"""
           required_fields = [
               'initiated_by_user_id', 'business_process', 'request_id',
               'authorization_method', 'authorized_by_role'
           ]

           for field in required_fields:
               if not getattr(context, field):
                   raise ValueError(f"Audit context missing required field: {field}")

           # Validate business process against allowed values
           allowed_processes = [
               'user_registration', 'profile_update', 'password_change',
               'account_deactivation', 'admin_override', 'data_migration',
               'gdpr_deletion', 'compliance_update'
           ]

           if context.business_process not in allowed_processes:
               raise ValueError(f"Unknown business process: {context.business_process}")

   class UserService:
       """User service with comprehensive audit logging"""

       def __init__(self, db_connection, audit_manager: AuditManager):
           self.db_connection = db_connection
           self.audit_manager = audit_manager

       def create_user(self, user_data: dict, request_context: dict) -> User:
           """Create new user with comprehensive audit logging"""

           audit_context = AuditContext(
               initiated_by_user_id=request_context['user_id'],
               business_process='user_registration',
               request_id=request_context['request_id'],
               session_id=request_context['session_id'],
               authorization_method=request_context['auth_method'],
               authorized_by_role=request_context['user_role'],
               ip_address=request_context['ip_address'],
               user_agent=request_context['user_agent'],
               data_classification='confidential',  # User PII
               compliance_tags=['GDPR', 'CCPA'],
               additional_context={
                   'registration_source': user_data.get('registration_source'),
                   'terms_version_accepted': user_data.get('terms_version')
               }
           )

           with self.audit_manager.audit_context(audit_context):
               with self.db_connection.cursor() as cursor:
                   cursor.execute("""
                       INSERT INTO users (email, full_name, created_at)
                       VALUES (%(email)s, %(full_name)s, NOW())
                       RETURNING id, email, full_name, created_at
                   """, user_data)

                   user_record = cursor.fetchone()

                   logger.info("User created successfully", extra={
                       'user_id': user_record['id'],
                       'business_process': 'user_registration',
                       'request_id': request_context['request_id'],
                       'audit_context': asdict(audit_context)
                   })

                   return User.from_db_record(user_record)

       def update_user_profile(self, user_id: int, updates: dict,
                             request_context: dict) -> User:
           """Update user profile with audit trail"""

           # Check if this is a sensitive update requiring enhanced audit
           sensitive_fields = {'email', 'full_name', 'phone_number'}
           is_sensitive = bool(sensitive_fields.intersection(updates.keys()))

           compliance_tags = ['GDPR']
           if is_sensitive:
               compliance_tags.extend(['PII_UPDATE', 'IDENTITY_VERIFICATION'])

           audit_context = AuditContext(
               initiated_by_user_id=request_context['user_id'],
               business_process='profile_update',
               request_id=request_context['request_id'],
               session_id=request_context['session_id'],
               authorization_method=request_context['auth_method'],
               authorized_by_role=request_context['user_role'],
               ip_address=request_context['ip_address'],
               user_agent=request_context['user_agent'],
               data_classification='confidential' if is_sensitive else 'internal',
               compliance_tags=compliance_tags,
               additional_context={
                   'updated_fields': list(updates.keys()),
                   'is_sensitive_update': is_sensitive,
                   'verification_method': request_context.get('verification_method')
               }
           )

           with self.audit_manager.audit_context(audit_context):
               with self.db_connection.cursor() as cursor:
                   # Build dynamic UPDATE query
                   update_clauses = []
                   update_params = {'user_id': user_id}

                   for field, value in updates.items():
                       update_clauses.append(f"{field} = %({field})s")
                       update_params[field] = value

                   query = f"""
                       UPDATE users
                       SET {', '.join(update_clauses)}, updated_at = NOW()
                       WHERE id = %(user_id)s
                       RETURNING id, email, full_name, updated_at
                   """

                   cursor.execute(query, update_params)
                   user_record = cursor.fetchone()

                   if not user_record:
                       raise ValueError(f"User {user_id} not found")

                   logger.info("User profile updated", extra={
                       'user_id': user_id,
                       'updated_fields': list(updates.keys()),
                       'is_sensitive_update': is_sensitive,
                       'request_id': request_context['request_id']
                   })

                   return User.from_db_record(user_record)

       def delete_user_gdpr(self, user_id: int, request_context: dict) -> bool:
           """Delete user data for GDPR compliance with comprehensive audit"""

           audit_context = AuditContext(
               initiated_by_user_id=request_context['user_id'],
               business_process='gdpr_deletion',
               request_id=request_context['request_id'],
               session_id=request_context['session_id'],
               authorization_method=request_context['auth_method'],
               authorized_by_role=request_context['user_role'],
               ip_address=request_context['ip_address'],
               user_agent=request_context['user_agent'],
               data_classification='restricted',  # GDPR deletion is highly sensitive
               retention_category='legal_hold',   # Keep audit record for legal requirements
               compliance_tags=['GDPR', 'RIGHT_TO_ERASURE', 'LEGAL_BASIS'],
               additional_context={
                   'deletion_reason': 'gdpr_right_to_erasure',
                   'legal_basis_verification': request_context.get('legal_verification'),
                   'data_retention_exception': request_context.get('retention_exception')
               }
           )

           with self.audit_manager.audit_context(audit_context):
               with self.db_connection.cursor() as cursor:
                   # First capture user data before deletion for audit
                   cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
                   user_record = cursor.fetchone()

                   if not user_record:
                       raise ValueError(f"User {user_id} not found")

                   # Perform GDPR deletion
                   cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))

                   logger.warning("GDPR user deletion completed", extra={
                       'user_id': user_id,
                       'business_process': 'gdpr_deletion',
                       'request_id': request_context['request_id'],
                       'legal_basis': request_context.get('legal_verification'),
                       'audit_retention': 'legal_hold'
                   })

                   return True
   ```

4. **Implement Compliance Reporting and Analysis**: Build tooling to analyze
   audit logs for compliance reporting, security investigation, and data
   quality monitoring that leverages the explicit audit structure.

   ```java
   // Java compliance reporting service
   @Service
   @Transactional(readOnly = true)
   public class ComplianceReportingService {

       private final JdbcTemplate jdbcTemplate;
       private final ObjectMapper objectMapper;
       private final Logger logger = LoggerFactory.getLogger(ComplianceReportingService.class);

       public ComplianceReportingService(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
           this.jdbcTemplate = jdbcTemplate;
           this.objectMapper = objectMapper;
       }

       public GdprComplianceReport generateGdprReport(Long userId, LocalDate startDate, LocalDate endDate) {
           String sql = """
               SELECT
                   audit_id,
                   event_timestamp,
                   business_process,
                   operation_type,
                   old_values,
                   new_values,
                   changed_fields,
                   initiated_by_user_id,
                   authorization_method,
                   ip_address,
                   compliance_tags
               FROM user_audit_log
               WHERE user_id = ?
                 AND event_timestamp >= ?
                 AND event_timestamp <= ?
                 AND 'GDPR' = ANY(compliance_tags)
               ORDER BY event_timestamp DESC
           """;

           List<AuditRecord> auditRecords = jdbcTemplate.query(sql,
               new Object[]{userId, startDate, endDate},
               this::mapAuditRecord);

           return GdprComplianceReport.builder()
               .userId(userId)
               .reportPeriod(DateRange.of(startDate, endDate))
               .auditRecords(auditRecords)
               .dataProcessingActivities(extractDataProcessingActivities(auditRecords))
               .retentionCompliance(checkRetentionCompliance(auditRecords))
               .accessLog(extractAccessLog(auditRecords))
               .build();
       }

       public SecurityAuditReport generateSecurityAuditReport(LocalDate startDate, LocalDate endDate,
                                                             SecurityAuditCriteria criteria) {
           StringBuilder sqlBuilder = new StringBuilder("""
               SELECT
                   audit_id,
                   event_timestamp,
                   user_id,
                   initiated_by_user_id,
                   business_process,
                   operation_type,
                   authorization_method,
                   authorized_by_role,
                   ip_address,
                   user_agent,
                   old_values,
                   new_values,
                   compliance_tags
               FROM user_audit_log
               WHERE event_timestamp >= ? AND event_timestamp <= ?
           """);

           List<Object> params = new ArrayList<>();
           params.add(startDate);
           params.add(endDate);

           // Add security-specific filters
           if (criteria.getSuspiciousIpRanges() != null && !criteria.getSuspiciousIpRanges().isEmpty()) {
               sqlBuilder.append(" AND (");
               for (int i = 0; i < criteria.getSuspiciousIpRanges().size(); i++) {
                   if (i > 0) sqlBuilder.append(" OR ");
                   sqlBuilder.append("ip_address << ?::inet");
                   params.add(criteria.getSuspiciousIpRanges().get(i));
               }
               sqlBuilder.append(")");
           }

           if (criteria.getHighRiskOperations() != null && !criteria.getHighRiskOperations().isEmpty()) {
               sqlBuilder.append(" AND business_process = ANY(?)");
               params.add(criteria.getHighRiskOperations().toArray(new String[0]));
           }

           if (criteria.getUnauthorizedAccess()) {
               sqlBuilder.append(" AND authorization_method NOT IN ('oauth', 'api_key', 'mfa')");
           }

           sqlBuilder.append(" ORDER BY event_timestamp DESC");

           List<AuditRecord> auditRecords = jdbcTemplate.query(sqlBuilder.toString(),
               params.toArray(), this::mapAuditRecord);

           return SecurityAuditReport.builder()
               .reportPeriod(DateRange.of(startDate, endDate))
               .criteria(criteria)
               .suspiciousActivities(identifySuspiciousActivities(auditRecords))
               .unauthorizedAccess(identifyUnauthorizedAccess(auditRecords))
               .privilegedOperations(extractPrivilegedOperations(auditRecords))
               .ipAddressAnalysis(analyzeIpAddressPatterns(auditRecords))
               .userBehaviorAnalysis(analyzeUserBehavior(auditRecords))
               .build();
       }

       public DataLineageReport generateDataLineageReport(Long userId, String dataField) {
           String sql = """
               SELECT
                   audit_id,
                   event_timestamp,
                   business_process,
                   operation_type,
                   old_values,
                   new_values,
                   initiated_by_user_id,
                   authorization_method,
                   request_id
               FROM user_audit_log
               WHERE user_id = ?
                 AND (
                     ? = ANY(changed_fields)
                     OR operation_type = 'INSERT'
                     OR operation_type = 'DELETE'
                 )
               ORDER BY event_timestamp ASC
           """;

           List<AuditRecord> changes = jdbcTemplate.query(sql,
               new Object[]{userId, dataField}, this::mapAuditRecord);

           return DataLineageReport.builder()
               .userId(userId)
               .dataField(dataField)
               .changeHistory(buildChangeHistory(changes, dataField))
               .dataProvenance(extractDataProvenance(changes))
               .qualityMetrics(calculateDataQualityMetrics(changes))
               .build();
       }

       private List<DataChange> buildChangeHistory(List<AuditRecord> auditRecords, String dataField) {
           return auditRecords.stream()
               .map(record -> {
                   JsonNode oldValues = parseJsonNode(record.getOldValues());
                   JsonNode newValues = parseJsonNode(record.getNewValues());

                   String oldValue = oldValues != null ?
                       oldValues.path(dataField).asText(null) : null;
                   String newValue = newValues != null ?
                       newValues.path(dataField).asText(null) : null;

                   return DataChange.builder()
                       .timestamp(record.getEventTimestamp())
                       .operationType(record.getOperationType())
                       .oldValue(oldValue)
                       .newValue(newValue)
                       .businessProcess(record.getBusinessProcess())
                       .initiatedBy(record.getInitiatedByUserId())
                       .authorizationMethod(record.getAuthorizationMethod())
                       .requestId(record.getRequestId())
                       .build();
               })
               .collect(Collectors.toList());
       }

       private AuditRecord mapAuditRecord(ResultSet rs, int rowNum) throws SQLException {
           return AuditRecord.builder()
               .auditId(UUID.fromString(rs.getString("audit_id")))
               .eventTimestamp(rs.getTimestamp("event_timestamp").toInstant())
               .userId(rs.getLong("user_id"))
               .initiatedByUserId(rs.getLong("initiated_by_user_id"))
               .businessProcess(rs.getString("business_process"))
               .operationType(rs.getString("operation_type"))
               .oldValues(rs.getString("old_values"))
               .newValues(rs.getString("new_values"))
               .changedFields(extractArrayFromPostgreSQL(rs.getArray("changed_fields")))
               .authorizationMethod(rs.getString("authorization_method"))
               .authorizedByRole(rs.getString("authorized_by_role"))
               .ipAddress(rs.getString("ip_address"))
               .userAgent(rs.getString("user_agent"))
               .complianceTags(extractArrayFromPostgreSQL(rs.getArray("compliance_tags")))
               .build();
       }

       @Scheduled(cron = "0 0 2 * * ?") // Run daily at 2 AM
       public void generateDailyComplianceReports() {
           LocalDate yesterday = LocalDate.now().minusDays(1);

           logger.info("Starting daily compliance report generation for {}", yesterday);

           try {
               // Generate GDPR reports for all users with activity
               generateGdprActivitySummary(yesterday);

               // Generate security audit summary
               generateSecurityAuditSummary(yesterday);

               // Check for audit integrity
               verifyAuditIntegrity(yesterday);

               logger.info("Daily compliance report generation completed successfully");

           } catch (Exception e) {
               logger.error("Failed to generate daily compliance reports", e);
               // Alert compliance team
               alertingService.sendComplianceAlert("Daily audit report generation failed", e);
           }
       }

       private void verifyAuditIntegrity(LocalDate date) {
           String sql = """
               SELECT COUNT(*) as suspicious_count
               FROM user_audit_log
               WHERE DATE(event_timestamp) = ?
                 AND (
                     record_hash IS NULL
                     OR LENGTH(record_hash) != 64
                     OR business_process IS NULL
                     OR initiated_by_user_id IS NULL
                 )
           """;

           Integer suspiciousCount = jdbcTemplate.queryForObject(sql, Integer.class, date);

           if (suspiciousCount > 0) {
               logger.error("Found {} audit records with integrity issues for date {}",
                   suspiciousCount, date);
               alertingService.sendSecurityAlert(
                   "Audit integrity violation detected",
                   Map.of("date", date.toString(), "suspicious_count", suspiciousCount)
               );
           }
       }
   }
   ```

5. **Establish Audit Log Retention and Access Controls**: Implement explicit
   policies for audit log retention, access control, and compliance with
   regulatory requirements for long-term audit integrity.

   ```typescript
   // TypeScript audit retention management
   import { EventEmitter } from 'events';
   import { Logger } from 'winston';

   interface RetentionPolicy {
     category: string;
     retentionPeriodDays: number;
     complianceRequirements: string[];
     archivalStrategy: 'delete' | 'archive' | 'anonymize';
     legalHoldSupport: boolean;
   }

   interface AuditAccessRequest {
     requestId: string;
     requestedBy: string;
     businessJustification: string;
     dataSubject?: string;
     timeRange: {
       startDate: Date;
       endDate: Date;
     };
     accessLevel: 'read' | 'export' | 'analysis';
     complianceBasis: string[];
   }

   class AuditRetentionManager extends EventEmitter {
     private retentionPolicies: Map<string, RetentionPolicy> = new Map();
     private legalHolds: Set<string> = new Set();

     constructor(
       private readonly logger: Logger,
       private readonly database: DatabaseConnection,
       private readonly complianceService: ComplianceService
     ) {
       super();
       this.initializeRetentionPolicies();
       this.startRetentionMonitoring();
     }

     private initializeRetentionPolicies(): void {
       // Standard business data
       this.retentionPolicies.set('standard', {
         category: 'standard',
         retentionPeriodDays: 2555, // 7 years
         complianceRequirements: ['SOX', 'general_business'],
         archivalStrategy: 'archive',
         legalHoldSupport: true
       });

       // GDPR personal data
       this.retentionPolicies.set('gdpr_personal', {
         category: 'gdpr_personal',
         retentionPeriodDays: 1095, // 3 years
         complianceRequirements: ['GDPR', 'data_protection'],
         archivalStrategy: 'anonymize',
         legalHoldSupport: true
       });

       // Security events
       this.retentionPolicies.set('security', {
         category: 'security',
         retentionPeriodDays: 3650, // 10 years
         complianceRequirements: ['security_policy', 'incident_response'],
         archivalStrategy: 'archive',
         legalHoldSupport: true
       });

       // Financial transactions
       this.retentionPolicies.set('financial', {
         category: 'financial',
         retentionPeriodDays: 2555, // 7 years
         complianceRequirements: ['SOX', 'tax_law', 'financial_regulation'],
         archivalStrategy: 'archive',
         legalHoldSupport: true
       });

       // Legal hold (indefinite retention)
       this.retentionPolicies.set('legal_hold', {
         category: 'legal_hold',
         retentionPeriodDays: -1, // Indefinite
         complianceRequirements: ['litigation_hold', 'regulatory_investigation'],
         archivalStrategy: 'archive',
         legalHoldSupport: true
       });
     }

     async processRetentionPolicy(): Promise<void> {
       this.logger.info('Starting audit log retention processing');

       for (const [category, policy] of this.retentionPolicies) {
         if (policy.retentionPeriodDays === -1) {
           continue; // Skip indefinite retention categories
         }

         try {
           await this.processRetentionForCategory(category, policy);
         } catch (error) {
           this.logger.error(`Retention processing failed for category ${category}`, error);
           this.emit('retention_error', { category, error });
         }
       }

       this.logger.info('Audit log retention processing completed');
     }

     private async processRetentionForCategory(category: string, policy: RetentionPolicy): Promise<void> {
       const cutoffDate = new Date();
       cutoffDate.setDate(cutoffDate.getDate() - policy.retentionPeriodDays);

       // Find records eligible for retention processing
       const eligibleRecords = await this.database.query(`
         SELECT audit_id, user_id, event_timestamp, compliance_tags, record_hash
         FROM user_audit_log
         WHERE retention_category = $1
           AND event_timestamp < $2
           AND audit_id NOT IN (
             SELECT audit_id FROM audit_legal_holds
             WHERE status = 'active'
           )
         ORDER BY event_timestamp ASC
         LIMIT 1000
       `, [category, cutoffDate]);

       if (eligibleRecords.length === 0) {
         this.logger.debug(`No records eligible for retention in category ${category}`);
         return;
       }

       this.logger.info(`Processing ${eligibleRecords.length} records for retention in category ${category}`);

       switch (policy.archivalStrategy) {
         case 'archive':
           await this.archiveRecords(eligibleRecords, policy);
           break;
         case 'anonymize':
           await this.anonymizeRecords(eligibleRecords, policy);
           break;
         case 'delete':
           await this.deleteRecords(eligibleRecords, policy);
           break;
       }

       // Record retention action in compliance log
       await this.complianceService.recordRetentionAction({
         category,
         recordCount: eligibleRecords.length,
         action: policy.archivalStrategy,
         cutoffDate,
         policy
       });
     }

     private async archiveRecords(records: any[], policy: RetentionPolicy): Promise<void> {
       for (const record of records) {
         // Move to archive table with integrity preservation
         await this.database.transaction(async (tx) => {
           // Insert into archive table
           await tx.query(`
             INSERT INTO user_audit_log_archive
             SELECT * FROM user_audit_log WHERE audit_id = $1
           `, [record.audit_id]);

           // Verify archive integrity
           const archived = await tx.query(`
             SELECT record_hash FROM user_audit_log_archive WHERE audit_id = $1
           `, [record.audit_id]);

           if (archived[0]?.record_hash !== record.record_hash) {
             throw new Error(`Archive integrity check failed for record ${record.audit_id}`);
           }

           // Remove from active table
           await tx.query(`
             DELETE FROM user_audit_log WHERE audit_id = $1
           `, [record.audit_id]);

           this.logger.debug(`Archived audit record ${record.audit_id}`);
         });
       }
     }

     private async anonymizeRecords(records: any[], policy: RetentionPolicy): Promise<void> {
       for (const record of records) {
         await this.database.transaction(async (tx) => {
           // Create anonymized version preserving audit trail structure
           const anonymizedData = this.anonymizeAuditData(record);

           // Insert anonymized record
           await tx.query(`
             INSERT INTO user_audit_log_anonymized (
               original_audit_id, event_timestamp, business_process,
               operation_type, anonymized_data, compliance_tags,
               anonymization_timestamp, anonymization_method
             ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), 'gdpr_anonymization')
           `, [
             record.audit_id,
             record.event_timestamp,
             record.business_process,
             record.operation_type,
             JSON.stringify(anonymizedData),
             record.compliance_tags
           ]);

           // Remove original record
           await tx.query(`
             DELETE FROM user_audit_log WHERE audit_id = $1
           `, [record.audit_id]);

           this.logger.debug(`Anonymized audit record ${record.audit_id}`);
         });
       }
     }

     private anonymizeAuditData(record: any): any {
       return {
         business_process: record.business_process, // Keep for compliance analysis
         operation_type: record.operation_type,
         user_id_hash: this.hashPersonalData(record.user_id.toString()),
         ip_address_subnet: this.anonymizeIpAddress(record.ip_address),
         anonymized_timestamp: record.event_timestamp,
         data_classification: 'anonymized'
       };
     }

     async requestAuditAccess(request: AuditAccessRequest): Promise<string> {
       // Validate access request
       await this.validateAccessRequest(request);

       // Log access request for compliance
       await this.database.query(`
         INSERT INTO audit_access_requests (
           request_id, requested_by, business_justification,
           data_subject, time_range_start, time_range_end,
           access_level, compliance_basis, status, created_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', NOW())
       `, [
         request.requestId,
         request.requestedBy,
         request.businessJustification,
         request.dataSubject,
         request.timeRange.startDate,
         request.timeRange.endDate,
         request.accessLevel,
         request.complianceBasis,
       ]);

       // Require approval for sensitive access
       if (request.accessLevel === 'export' || request.complianceBasis.includes('investigation')) {
         await this.complianceService.requestApproval(request);
         this.logger.info(`Audit access request ${request.requestId} requires approval`);
         return 'pending_approval';
       }

       // Grant immediate access for standard read requests
       await this.grantAuditAccess(request);
       this.logger.info(`Granted audit access for request ${request.requestId}`);
       return 'granted';
     }

     private async validateAccessRequest(request: AuditAccessRequest): Promise<void> {
       // Validate business justification
       if (!request.businessJustification || request.businessJustification.length < 50) {
         throw new Error('Detailed business justification required for audit access');
       }

       // Validate compliance basis
       const validBases = [
         'gdpr_subject_access', 'security_investigation', 'compliance_audit',
         'data_quality_analysis', 'regulatory_inquiry', 'legal_discovery'
       ];

       if (!request.complianceBasis.some(basis => validBases.includes(basis))) {
         throw new Error('Valid compliance basis required for audit access');
       }

       // Validate time range
       const maxRangeDays = 365;
       const requestRangeDays = Math.ceil(
         (request.timeRange.endDate.getTime() - request.timeRange.startDate.getTime())
         / (1000 * 60 * 60 * 24)
       );

       if (requestRangeDays > maxRangeDays) {
         throw new Error(`Audit access request cannot exceed ${maxRangeDays} days`);
       }
     }

     private startRetentionMonitoring(): void {
       // Run retention processing daily
       setInterval(async () => {
         try {
           await this.processRetentionPolicy();
         } catch (error) {
           this.logger.error('Scheduled retention processing failed', error);
         }
       }, 24 * 60 * 60 * 1000); // 24 hours

       // Monitor for legal holds
       setInterval(async () => {
         try {
           await this.checkLegalHoldUpdates();
         } catch (error) {
           this.logger.error('Legal hold monitoring failed', error);
         }
       }, 60 * 60 * 1000); // 1 hour
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
    changed_fields TEXT[],

    -- Authorization and compliance context
    authorization_method VARCHAR(50),
    compliance_tags TEXT[],
    record_hash VARCHAR(64) NOT NULL
);

-- Immutable, comprehensive audit record
INSERT INTO user_audit_log (
    user_id, initiated_by_user_id, business_process,
    operation_type, new_values, authorization_method,
    compliance_tags, record_hash
) VALUES (
    123, 456, 'profile_update',
    'UPDATE', '{"email": "new@example.com"}', 'oauth',
    ARRAY['GDPR', 'PII_UPDATE'], 'abc123...'
);
```

```python
# ❌ BAD: Implicit audit logging without context
def update_user(user_id, data):
    # Hidden audit logging with no business context
    db.execute("UPDATE users SET email = %s WHERE id = %s",
              data['email'], user_id)

    # Generic log message with minimal information
    logger.info("User updated")
```

```python
# ✅ GOOD: Explicit audit context with comprehensive logging
def update_user_profile(user_id: int, updates: dict, request_context: dict):
    audit_context = AuditContext(
        initiated_by_user_id=request_context['user_id'],
        business_process='profile_update',
        request_id=request_context['request_id'],
        authorization_method=request_context['auth_method'],
        compliance_tags=['GDPR', 'PII_UPDATE'],
        additional_context={
            'updated_fields': list(updates.keys()),
            'verification_method': request_context.get('verification')
        }
    )

    with audit_manager.audit_context(audit_context):
        db.execute("""
            UPDATE users SET email = %(email)s, updated_at = NOW()
            WHERE id = %(user_id)s
        """, {'email': updates['email'], 'user_id': user_id})

        logger.info("User profile updated with complete audit trail", extra={
            'user_id': user_id,
            'business_process': 'profile_update',
            'compliance_tags': ['GDPR', 'PII_UPDATE']
        })
```

```javascript
// ❌ BAD: Silent data changes without audit trail
async function deleteUser(userId) {
    // No audit trail, no compliance consideration
    await db.query('DELETE FROM users WHERE id = ?', [userId]);
    console.log('User deleted');
}
```

```javascript
// ✅ GOOD: Comprehensive audit trail for sensitive operations
async function deleteUserGdpr(userId, requestContext) {
    const auditContext = {
        initiatedByUserId: requestContext.userId,
        businessProcess: 'gdpr_deletion',
        requestId: requestContext.requestId,
        authorizationMethod: requestContext.authMethod,
        complianceTags: ['GDPR', 'RIGHT_TO_ERASURE'],
        additionalContext: {
            deletionReason: 'gdpr_right_to_erasure',
            legalBasisVerification: requestContext.legalVerification
        }
    };

    await auditManager.withContext(auditContext, async () => {
        // Capture complete user data before deletion for audit
        const userData = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

        // Perform deletion with comprehensive audit logging
        await db.query('DELETE FROM users WHERE id = ?', [userId]);

        logger.warn('GDPR user deletion completed', {
            userId,
            businessProcess: 'gdpr_deletion',
            complianceTags: ['GDPR', 'RIGHT_TO_ERASURE'],
            auditRetention: 'legal_hold'
        });
    });
}
```

## Related Bindings

- [use-structured-logging](../../core/use-structured-logging.md): Audit logging
  implementations must coordinate with structured logging to ensure consistent
  correlation IDs, business context, and compliance metadata across all system
  logs. Both patterns work together to create comprehensive observability.

- [data-validation-at-boundaries](data-validation-at-boundaries.md): Audit
  logging requires validation of audit context and business process identifiers
  to ensure audit records contain accurate, complete information for compliance
  and investigation purposes.

- [transaction-management-patterns](transaction-management-patterns.md): Audit
  logging must be integrated with transaction boundaries to ensure audit records
  are created atomically with data changes, preventing scenarios where data
  changes succeed but audit logging fails.
