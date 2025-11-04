# Historical Data Quick Reference

Quick reference guide for accessing and working with historical data in NEMO.

## URLs

### Audit Logs
- **List**: `/[locale]/m/[mission]/audit-logs`
- **Export**: `/[locale]/m/[mission]/audit-logs/export.csv`
- **Statistics**: `/[locale]/m/[mission]/audit-logs/statistics`

### AI Validation
- **Report**: `/[locale]/m/[mission]/ai-validation-rules/report`
- **Rule History**: `/[locale]/m/[mission]/ai-validation-rules/[id]`

### Analytics
- **Dashboard**: `/[locale]/m/[mission]/analytics/dashboard?time_range=30_days`
- **Response Trends**: `/[locale]/m/[mission]/analytics/response_trends`

### Backups
- **List**: `/[locale]/m/[mission]/backups`
- **Download**: `/[locale]/m/[mission]/backups/[id]/download`

## Rails Console Queries

### Audit Logs
```ruby
# Recent logs
AuditLog.where(mission: mission).recent.limit(100)

# By action
AuditLog.where(mission: mission).by_action(:create).recent

# By date range
AuditLog.where(mission: mission)
        .in_date_range(1.month.ago, Time.current)
        .recent

# By user
AuditLog.where(mission: mission).by_user(user).recent
```

### Responses
```ruby
# Last month
Response.where(mission: mission)
        .where(created_at: 1.month.ago..Time.current)
        .latest_first

# Recent count
Response.recent_count(Response.where(mission: mission))
```

### AI Validation
```ruby
# Validation results for date range
AiValidationResult.joins(:ai_validation_rule)
                  .where(ai_validation_rules: { mission: mission })
                  .where(created_at: 1.month.ago..Time.current)
                  .order(created_at: :desc)

# Failed validations
AiValidationResult.joins(:ai_validation_rule)
                  .where(ai_validation_rules: { mission: mission })
                  .failed
                  .where(created_at: 1.month.ago..Time.current)
```

## Time Ranges

Available time ranges for analytics:
- `7_days` - Last 7 days
- `30_days` - Last 30 days  
- `90_days` - Last 90 days
- `1_year` - Last year

## Audit Log Actions

Tracked actions: `create`, `update`, `destroy`, `login`, `logout`, `export`, `import`, `view`, `download`, `print`, `publish`, `unpublish`, `review`, `approve`, `reject`, `assign`, `unassign`, `activate`, `deactivate`

## Data Retention

- **Responses**: Permanent
- **Audit Logs**: Permanent
- **AI Validation Results**: Permanent
- **Backups**: 30 days (configurable)

## Export Formats

- **Audit Logs**: CSV
- **Responses**: CSV, Excel, JSON
- **Analytics**: JSON, CSV
- **Backups**: SQL dump, JSON

## Key Models

- `AuditLog` - System audit trail
- `Response` - Form responses
- `AiValidationResult` - Validation history
- `Backup` - Data backups

## See Also

- [Full Historical Data Documentation](HISTORICAL_DATA.md)
- [Architecture Documentation](architecture.md)
- [API Documentation](api.md)
