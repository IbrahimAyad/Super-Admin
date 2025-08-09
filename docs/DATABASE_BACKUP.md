# Database Backup Strategy

Complete backup and disaster recovery plan for KCT Menswear database.

## Overview

This document outlines the database backup strategy, including automated backups, manual procedures, and disaster recovery plans.

## Backup Types

### 1. Automated Supabase Backups

Supabase provides automatic daily backups for Pro plan and above:

- **Frequency**: Daily
- **Retention**: 7 days (Pro), 30 days (Team), 90 days (Enterprise)
- **Type**: Point-in-time recovery (PITR)
- **Access**: Via Supabase Dashboard > Settings > Database > Backups

### 2. Manual Backups

Use the provided scripts for additional backup control:

```bash
# Full backup
./scripts/backup-database.sh

# With cloud upload (S3)
AWS_S3_BUCKET=your-bucket ./scripts/backup-database.sh

# With custom retention
RETENTION_DAYS=60 ./scripts/backup-database.sh
```

### 3. Continuous Replication

For critical production environments, set up continuous replication:

```sql
-- Enable logical replication
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;
```

## Backup Schedule

### Production Environment

| Type | Frequency | Retention | Storage |
|------|-----------|-----------|---------|
| Full Backup | Daily at 2 AM UTC | 30 days | S3 + Local |
| Incremental | Every 6 hours | 7 days | S3 |
| Transaction Logs | Continuous | 24 hours | S3 |
| Weekly Archive | Sundays | 1 year | Glacier |
| Monthly Archive | 1st of month | 5 years | Glacier |

### Staging Environment

| Type | Frequency | Retention | Storage |
|------|-----------|-----------|---------|
| Full Backup | Daily | 7 days | Local |
| Before Deployment | Manual | 3 versions | S3 |

## Automated Backup Setup

### 1. Cron Job Configuration

Add to crontab:

```bash
# Daily backup at 2 AM UTC
0 2 * * * /path/to/backup-database.sh >> /var/log/db-backup.log 2>&1

# Incremental every 6 hours
0 */6 * * * /path/to/incremental-backup.sh >> /var/log/db-backup.log 2>&1

# Weekly archive on Sunday
0 3 * * 0 /path/to/archive-backup.sh weekly >> /var/log/db-backup.log 2>&1

# Monthly archive on 1st
0 4 1 * * /path/to/archive-backup.sh monthly >> /var/log/db-backup.log 2>&1
```

### 2. Environment Variables

Create `/etc/kct-backup.env`:

```bash
# Database connection
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Backup configuration
BACKUP_DIR=/var/backups/kct
RETENTION_DAYS=30

# Cloud storage (S3)
AWS_S3_BUCKET=kct-database-backups
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1

# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
EMAIL_TO=ops@kctmenswear.com

# Verification
VERIFY_RESTORE=true
```

### 3. Systemd Service (Linux)

Create `/etc/systemd/system/kct-backup.service`:

```ini
[Unit]
Description=KCT Database Backup
After=network.target

[Service]
Type=oneshot
User=postgres
EnvironmentFile=/etc/kct-backup.env
ExecStart=/opt/kct/scripts/backup-database.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/kct-backup.timer`:

```ini
[Unit]
Description=KCT Database Backup Timer
Requires=kct-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:

```bash
sudo systemctl enable kct-backup.timer
sudo systemctl start kct-backup.timer
```

## Cloud Storage Setup

### AWS S3

1. Create S3 bucket:

```bash
aws s3 mb s3://kct-database-backups
```

2. Set lifecycle policy:

```json
{
  "Rules": [
    {
      "Id": "MoveToIA",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    },
    {
      "Id": "DeleteOld",
      "Status": "Enabled",
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
```

3. Set bucket policy for encryption:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::kct-database-backups/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    }
  ]
}
```

### Google Cloud Storage

1. Create GCS bucket:

```bash
gsutil mb -c STANDARD -l us-central1 gs://kct-database-backups
```

2. Set lifecycle rules:

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "NEARLINE"
        },
        "condition": {
          "age": 30
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 90
        }
      }
    ]
  }
}
```

## Restoration Procedures

### Quick Restore

```bash
# List available backups
./scripts/restore-database.sh

# Restore specific backup
./scripts/restore-database.sh ./backups/kct_backup_20240101.dump

# Restore from S3
./scripts/restore-database.sh s3://kct-database-backups/kct_backup_20240101.dump
```

### Disaster Recovery

1. **Assess the situation**:
   - Identify the failure type
   - Determine data loss extent
   - Choose recovery point

2. **Notify stakeholders**:
   - Send incident notification
   - Estimate recovery time
   - Update status page

3. **Prepare new environment**:
   ```bash
   # Create new database
   createdb -h new-host kct_restore
   
   # Set environment
   export DATABASE_URL=postgresql://user:pass@new-host:5432/kct_restore
   ```

4. **Restore from backup**:
   ```bash
   # Download latest backup
   aws s3 cp s3://kct-database-backups/latest.dump ./
   
   # Restore with verification
   ./scripts/restore-database.sh -y latest.dump
   ```

5. **Verify restoration**:
   ```sql
   -- Check critical tables
   SELECT COUNT(*) FROM products;
   SELECT COUNT(*) FROM orders;
   SELECT COUNT(*) FROM customers;
   
   -- Verify recent data
   SELECT MAX(created_at) FROM orders;
   ```

6. **Update application**:
   - Update connection strings
   - Clear caches
   - Test functionality

7. **Post-recovery**:
   - Document incident
   - Update runbooks
   - Schedule retrospective

## Monitoring

### Health Checks

Monitor backup health with these queries:

```sql
-- Check last backup time
SELECT 
    datname,
    pg_last_wal_receive_lsn(),
    pg_last_wal_replay_lsn(),
    pg_last_xact_replay_timestamp()
FROM pg_stat_database
WHERE datname = current_database();

-- Check backup size growth
SELECT 
    pg_database_size(current_database()) as db_size,
    pg_size_pretty(pg_database_size(current_database())) as pretty_size;

-- Monitor table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

### Alerts

Set up alerts for:

- Backup failure
- Backup size anomaly (>20% change)
- Restoration test failure
- Storage quota exceeded
- Retention policy violation

## Testing

### Monthly Restore Test

Perform monthly restoration tests:

```bash
# Create test database
createdb kct_restore_test

# Restore to test
DATABASE_URL=postgresql://localhost/kct_restore_test \
  ./scripts/restore-database.sh -y latest.dump

# Run verification suite
npm run test:database

# Clean up
dropdb kct_restore_test
```

### Annual Disaster Recovery Drill

Conduct annual DR drill:

1. Simulate failure scenario
2. Execute recovery procedures
3. Measure recovery time (RTO)
4. Verify data integrity (RPO)
5. Document lessons learned

## Security

### Encryption

- **At Rest**: All backups encrypted with AES-256
- **In Transit**: TLS 1.2+ for all transfers
- **Key Management**: Rotate encryption keys quarterly

### Access Control

- Limit backup access to ops team
- Use IAM roles for cloud access
- Audit backup access logs
- Implement MFA for restore operations

### Compliance

- GDPR: Implement right to be forgotten in backups
- PCI DSS: Encrypt payment data in backups
- SOC 2: Maintain audit trail of backup operations

## Cost Optimization

### Storage Tiers

| Age | Storage Class | Cost/GB/Month |
|-----|--------------|---------------|
| 0-30 days | Standard | $0.023 |
| 31-90 days | Infrequent Access | $0.0125 |
| 91-365 days | Glacier | $0.004 |
| >365 days | Deep Archive | $0.001 |

### Optimization Tips

1. Compress backups (60-80% reduction)
2. Deduplicate data before backup
3. Use incremental backups
4. Clean up test/dev backups
5. Right-size retention periods

## Troubleshooting

### Common Issues

#### Backup Fails with "Permission Denied"

```bash
# Check permissions
\du
# Grant backup role
GRANT pg_read_all_data TO backup_user;
```

#### Restore Fails with "Database in Use"

```bash
# Terminate connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'kct_production' AND pid <> pg_backend_pid();
```

#### Slow Backup Performance

```sql
-- Increase work memory
SET work_mem = '256MB';
-- Increase maintenance work memory
SET maintenance_work_mem = '1GB';
```

## Documentation

### Runbooks

- [Backup Failure Response](./runbooks/backup-failure.md)
- [Emergency Restore](./runbooks/emergency-restore.md)
- [Disaster Recovery](./runbooks/disaster-recovery.md)

### Related Documents

- [Database Schema](./sql/schema.sql)
- [Migration History](./sql/migrations/)
- [Security Policy](./SECURITY.md)

## Contact

**Database Team**: db-team@kctmenswear.com  
**On-Call**: +1-xxx-xxx-xxxx  
**Escalation**: CTO / VP Engineering

---

**Last Updated**: August 2025  
**Version**: 1.0.0  
**Review Schedule**: Quarterly