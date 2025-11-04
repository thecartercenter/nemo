# Historical Data Documentation

## Overview

NEMO maintains comprehensive historical records of all data collection activities, system changes, and validation results. This document describes how historical data is stored, accessed, and managed in the system.

## Table of Contents

1. [Historical Data Types](#historical-data-types)
2. [Audit Logs](#audit-logs)
3. [Response History](#response-history)
4. [AI Validation History](#ai-validation-history)
5. [Analytics and Reporting](#analytics-and-reporting)
6. [Backup and Retention](#backup-and-retention)
7. [Accessing Historical Data](#accessing-historical-data)
8. [Data Retention Policies](#data-retention-policies)
9. [API Access](#api-access)
10. [Best Practices](#best-practices)

---

## Historical Data Types

NEMO tracks historical data in several key areas:

### 1. **Audit Logs**
Complete audit trail of all system actions including:
- User logins/logouts
- Data creation, updates, and deletions
- Form publications
- User assignments
- Exports and imports
- Review and approval actions

### 2. **Response Data**
- All form responses are permanently stored with timestamps
- Responses are never deleted (soft delete pattern)
- Complete history of response modifications
- Response review history

### 3. **AI Validation Results**
- Historical validation results for all responses
- Confidence scores and validation status over time
- Issues and suggestions from validation rules

### 4. **Form and Question Changes**
- Form version history
- Question modifications
- Validation rule changes

### 5. **User Activity**
- User login history
- Activity tracking
- Permission changes

---

## Audit Logs

### Overview

The audit log system provides a complete record of all actions performed in NEMO. Every significant action is logged with:
- User who performed the action
- Timestamp
- Action type
- Resource affected
- Changes made
- IP address and user agent

### Accessing Audit Logs

**Web Interface:**
```
/[locale]/m/[mission]/audit-logs
```

**Features:**
- Filter by action type, resource, user, or date range
- Export to CSV
- View statistics and trends
- Detailed view of individual log entries

### Audit Log Actions

The following actions are tracked:

| Action | Description |
|--------|-------------|
| `create` | Resource creation |
| `update` | Resource updates |
| `destroy` | Resource deletion |
| `login` | User login |
| `logout` | User logout |
| `export` | Data export |
| `import` | Data import |
| `view` | Resource viewing |
| `download` | File downloads |
| `print` | Printing actions |
| `publish` | Form publication |
| `unpublish` | Form unpublishing |
| `review` | Response review |
| `approve` | Approval actions |
| `reject` | Rejection actions |
| `assign` | User assignments |
| `unassign` | User unassignments |
| `activate` | Resource activation |
| `deactivate` | Resource deactivation |

### Tracked Resources

Audit logs track changes to:
- Users
- Forms
- Responses
- Questions
- Option Sets
- Reports
- Missions
- Assignments
- Broadcasts
- Settings
- Notifications

### Using Audit Logs

**Viewing Audit Logs:**

```ruby
# In Rails console
AuditLog.where(mission: mission)
        .recent
        .limit(100)

# Filter by action
AuditLog.where(mission: mission)
        .by_action(:create)
        .recent

# Filter by date range
AuditLog.where(mission: mission)
        .in_date_range(1.month.ago, Time.current)
        .recent

# Filter by user
AuditLog.where(mission: mission)
        .by_user(user)
        .recent
```

**Exporting Audit Logs:**

```ruby
# Export via controller
GET /[locale]/m/[mission]/audit-logs/export.csv?date_from=2024-01-01&date_to=2024-12-31
```

**Statistics:**

```ruby
# View statistics
GET /[locale]/m/[mission]/audit-logs/statistics
```

---

## Response History

### Overview

All form responses are stored permanently with complete historical information. Responses maintain:
- Creation timestamp (`created_at`)
- Last update timestamp (`updated_at`)
- Submission source (web, ODK, SMS)
- User who submitted
- Review status and reviewer
- Checkout information
- Complete answer history

### Response Timestamps

Every response includes:
- **`created_at`**: When the response was first created
- **`updated_at`**: When the response was last modified
- **`reviewed_at`**: When the response was reviewed (via reviewer association)

### Accessing Historical Responses

**Web Interface:**
```
/[locale]/m/[mission]/responses
```

**Filtering by Date:**
- Use date filters to view responses from specific time periods
- Responses are indexed by `created_at` for efficient querying

**Rails Console:**

```ruby
# Responses from a specific date range
Response.where(mission: mission)
        .where(created_at: 1.month.ago..Time.current)
        .latest_first

# Responses created after a date
Response.where(mission: mission)
        .created_after(1.week.ago)
        .latest_first

# Responses created before a date
Response.where(mission: mission)
        .created_before(1.month.ago)
        .latest_first

# Recent response count
Response.recent_count(Response.where(mission: mission))
# Returns: [5, "week"] if 5 responses in last week
```

### Response Modification History

While responses themselves don't have a version history table, modifications are tracked through:
1. **`updated_at`** timestamp
2. **Audit logs** for update actions
3. **Review history** via reviewer associations
4. **Comments and annotations** with timestamps

### Historical Response Analysis

**Analytics Dashboard:**
```
/[locale]/m/[mission]/analytics/dashboard?time_range=30_days
```

Available time ranges:
- `7_days` - Last 7 days
- `30_days` - Last 30 days
- `90_days` - Last 90 days
- `1_year` - Last year

---

## AI Validation History

### Overview

AI validation results are stored permanently for historical analysis. Each validation result includes:
- Validation timestamp
- Rule that was applied
- Response that was validated
- Confidence score
- Pass/fail status
- Issues and suggestions
- Explanation

### Accessing Validation History

**Via Rule:**
```
/[locale]/m/[mission]/ai-validation-rules/[rule_id]
```

Shows all validation results for a specific rule with:
- Total validations count
- Pass/fail statistics
- Pass rate percentage
- Individual result details

**Via Response:**
Validation results are accessible through the response show page and can be queried:

```ruby
# Get all validation results for a response
response.ai_validation_results
        .includes(:ai_validation_rule)
        .order(created_at: :desc)

# Get validation results by type
AiValidationResult.where(response: response)
                  .by_type('data_quality')
                  .order(created_at: :desc)

# Get high confidence results
AiValidationResult.where(response: response)
                  .high_confidence
                  .order(created_at: :desc)
```

### Validation Report

View comprehensive validation reports:
```
/[locale]/m/[mission]/ai-validation-rules/report?date_from=2024-01-01&date_to=2024-12-31
```

The report includes:
- Summary statistics
- Results by rule type
- Recent validation results
- Average confidence scores
- Pass/fail rates

### Historical Validation Analysis

**Query Examples:**

```ruby
# Validation results in date range
AiValidationResult.joins(:ai_validation_rule)
                  .where(ai_validation_rules: { mission: mission })
                  .where(created_at: 1.month.ago..Time.current)
                  .order(created_at: :desc)

# Failed validations over time
AiValidationResult.joins(:ai_validation_rule)
                  .where(ai_validation_rules: { mission: mission })
                  .failed
                  .where(created_at: 1.month.ago..Time.current)
                  .group_by_day(:created_at)
                  .count

# Validation trends by rule type
AiValidationResult.joins(:ai_validation_rule)
                  .where(ai_validation_rules: { mission: mission })
                  .where(created_at: 1.month.ago..Time.current)
                  .group(:validation_type)
                  .group_by_day(:created_at)
                  .count
```

---

## Analytics and Reporting

### Time-Based Analytics

The analytics dashboard provides historical analysis across multiple time ranges:

**Response Trends:**
- Daily/weekly/monthly response counts
- Response growth over time
- Submission patterns

**Form Performance:**
- Form completion rates over time
- Average completion time trends
- Form usage statistics

**User Activity:**
- User activity patterns
- Most active users over time
- Activity trends

**Geographic Distribution:**
- Response locations over time
- Geographic trends
- Location-based statistics

### Accessing Analytics

**Dashboard:**
```
/[locale]/m/[mission]/analytics/dashboard?time_range=30_days
```

**API Endpoints:**
```ruby
# Response trends
GET /[locale]/m/[mission]/analytics/response_trends?time_range=30_days

# Form performance
GET /[locale]/m/[mission]/analytics/form_performance

# Geographic data
GET /[locale]/m/[mission]/analytics/geographic_data
```

### Custom Date Ranges

Analytics support custom date ranges:
- 7 days
- 30 days
- 90 days
- 1 year
- Custom range (via API)

---

## Backup and Retention

### Backup System

NEMO includes a comprehensive backup system for data retention:

**Backup Types:**
- `full` - Complete mission backup
- `mission_data` - All mission data
- `forms_only` - Forms and questions only
- `responses_only` - Response data only

**Backup Options:**
- Include media files
- Include audit logs
- Scheduled backups
- Manual backups

### Accessing Backups

**Web Interface:**
```
/[locale]/m/[mission]/backups
```

**Features:**
- View backup history
- Download backups
- Restore from backup
- Cleanup old backups

### Backup Retention

Backups are retained according to configuration:
- Default: 30 days
- Configurable per mission
- Automatic cleanup of old backups

**Cleanup Old Backups:**

```ruby
# Cleanup backups older than 30 days
Backup.cleanup_old_backups(30)

# Cleanup backups older than 90 days
Backup.cleanup_old_backups(90)
```

---

## Accessing Historical Data

### Web Interface

**Audit Logs:**
```
/[locale]/m/[mission]/audit-logs
```

**AI Validation Report:**
```
/[locale]/m/[mission]/ai-validation-rules/report
```

**Analytics Dashboard:**
```
/[locale]/m/[mission]/analytics/dashboard
```

**Responses (with date filters):**
```
/[locale]/m/[mission]/responses?date_from=2024-01-01&date_to=2024-12-31
```

### Rails Console

**Common Queries:**

```ruby
# Get all responses from last month
responses = Response.where(mission: mission)
                    .where(created_at: 1.month.ago..Time.current)
                    .includes(:user, :form)

# Get audit logs for a user
audit_logs = AuditLog.where(mission: mission)
                     .by_user(user)
                     .recent
                     .limit(100)

# Get validation results for date range
validation_results = AiValidationResult.joins(:ai_validation_rule)
                                       .where(ai_validation_rules: { mission: mission })
                                       .where(created_at: 1.month.ago..Time.current)
                                       .includes(:response, :ai_validation_rule)

# Get recent activity statistics
recent_activity = AuditLog.where(mission: mission)
                          .where(created_at: 7.days.ago..Time.current)
                          .group_by_day(:created_at)
                          .count
```

### Exporting Historical Data

**CSV Export:**
- Audit logs can be exported as CSV
- Responses can be exported via the export interface
- Analytics data available via API

**Export Audit Logs:**
```
GET /[locale]/m/[mission]/audit-logs/export.csv?date_from=2024-01-01&date_to=2024-12-31
```

---

## Data Retention Policies

### Default Retention

- **Responses**: Permanent (never deleted)
- **Audit Logs**: Permanent (never automatically deleted)
- **AI Validation Results**: Permanent (never automatically deleted)
- **Backups**: 30 days (configurable)

### Retention Configuration

Retention policies can be configured per mission:

```ruby
# Set backup retention (in days)
mission.backup_retention_days = 90

# Cleanup old backups
Backup.cleanup_old_backups(mission.backup_retention_days)
```

### Data Archival

For long-term archival:
1. Create full backups
2. Export data to external storage
3. Archive audit logs
4. Document retention policies

---

## API Access

### REST API

**Audit Logs:**
```http
GET /api/v1/missions/:mission_id/audit_logs
GET /api/v1/missions/:mission_id/audit_logs/:id
```

**Responses:**
```http
GET /api/v1/missions/:mission_id/responses?created_after=2024-01-01
GET /api/v1/missions/:mission_id/responses?created_before=2024-12-31
```

**Analytics:**
```http
GET /api/v1/missions/:mission_id/analytics/response_trends?time_range=30_days
GET /api/v1/missions/:mission_id/analytics/form_performance
```

### OData API

Historical data is also accessible via OData endpoints:

```
/[locale]/m/[mission]/odata/$metadata
```

### Authentication

All API endpoints require authentication:
- API tokens
- User session authentication
- OAuth2 (if configured)

---

## Best Practices

### 1. Regular Backups

- Schedule regular backups
- Test backup restoration
- Store backups off-site
- Document backup procedures

### 2. Monitor Audit Logs

- Regularly review audit logs
- Set up alerts for critical actions
- Export audit logs periodically
- Analyze audit log statistics

### 3. Historical Analysis

- Use analytics dashboard for trends
- Export data for external analysis
- Track validation results over time
- Monitor response patterns

### 4. Data Archival

- Archive old data to external storage
- Document archival procedures
- Maintain data integrity
- Test archival restoration

### 5. Performance Considerations

- Use indexes for date-based queries
- Paginate large result sets
- Cache frequently accessed historical data
- Optimize queries with proper scopes

### 6. Privacy and Compliance

- Ensure historical data complies with regulations
- Implement data retention policies
- Protect sensitive historical data
- Audit data access

---

## Database Schema

### Key Tables

**audit_logs:**
- `id` (uuid)
- `user_id` (uuid)
- `mission_id` (uuid)
- `action` (string)
- `resource` (string)
- `resource_id` (uuid)
- `changes` (jsonb)
- `metadata` (jsonb)
- `ip_address` (string)
- `user_agent` (text)
- `created_at` (datetime)

**responses:**
- `id` (uuid)
- `form_id` (uuid)
- `user_id` (uuid)
- `mission_id` (uuid)
- `created_at` (datetime)
- `updated_at` (datetime)
- `reviewed` (boolean)
- `reviewer_id` (uuid)

**ai_validation_results:**
- `id` (uuid)
- `ai_validation_rule_id` (uuid)
- `response_id` (uuid)
- `validation_type` (string)
- `confidence_score` (decimal)
- `is_valid` (boolean)
- `passed` (boolean)
- `issues` (text array)
- `suggestions` (text array)
- `explanation` (text)
- `created_at` (datetime)

### Indexes

Historical data queries are optimized with indexes:
- `created_at` indexes on all timestamped tables
- Composite indexes for common query patterns
- Mission-based indexes for scoped queries

---

## Troubleshooting

### Common Issues

**1. Slow Historical Queries**

**Solution:**
- Ensure indexes are present
- Use scopes instead of raw queries
- Paginate large result sets
- Cache frequently accessed data

**2. Missing Audit Logs**

**Solution:**
- Check that `Auditable` concern is included
- Verify `current_user` is available
- Check audit log permissions
- Review audit log filters

**3. Large Backup Files**

**Solution:**
- Use selective backup types
- Exclude media files if not needed
- Compress backups
- Archive old backups

**4. Date Range Queries Not Working**

**Solution:**
- Verify date format (YYYY-MM-DD)
- Check timezone settings
- Ensure date fields are indexed
- Use proper date range syntax

---

## Support and Resources

### Documentation

- [Architecture Documentation](architecture.md)
- [API Documentation](api.md)
- [Deployment Guide](DEPLOYMENT.md)

### Code References

- `app/models/audit_log.rb` - Audit log model
- `app/models/response.rb` - Response model
- `app/models/ai_validation_result.rb` - Validation results
- `app/controllers/audit_logs_controller.rb` - Audit logs controller
- `app/controllers/analytics_controller.rb` - Analytics controller

### Contact

For questions or issues with historical data:
- Check the troubleshooting section
- Review audit logs for errors
- Contact system administrator
- Submit a support ticket

---

**Last Updated:** 2024-12-04  
**Version:** 15.1  
**Maintained By:** NEMO Development Team
