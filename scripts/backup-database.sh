#!/bin/bash

# Database Backup Script for KCT Menswear Super Admin
# This script creates automated backups of the Supabase database

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="kct_backup_${TIMESTAMP}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check required environment variables
check_env() {
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is not set"
        echo "Please set it using: export DATABASE_URL='postgresql://...'"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Perform database backup
backup_database() {
    log_info "Starting database backup: $BACKUP_NAME"
    
    # Full backup with custom format for flexibility
    pg_dump "$DATABASE_URL" \
        --format=custom \
        --verbose \
        --no-owner \
        --no-privileges \
        --file="${BACKUP_DIR}/${BACKUP_NAME}.dump"
    
    # Also create SQL format for easy inspection
    pg_dump "$DATABASE_URL" \
        --format=plain \
        --no-owner \
        --no-privileges \
        --file="${BACKUP_DIR}/${BACKUP_NAME}.sql"
    
    # Compress SQL file
    gzip "${BACKUP_DIR}/${BACKUP_NAME}.sql"
    
    log_info "Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.dump"
    log_info "SQL backup: ${BACKUP_DIR}/${BACKUP_NAME}.sql.gz"
}

# Create backup metadata
create_metadata() {
    cat > "${BACKUP_DIR}/${BACKUP_NAME}.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "date": "$(date)",
    "type": "full",
    "format": "custom",
    "database_url": "${DATABASE_URL%%@*}@***",
    "retention_days": ${RETENTION_DAYS},
    "files": [
        "${BACKUP_NAME}.dump",
        "${BACKUP_NAME}.sql.gz"
    ]
}
EOF
    log_info "Metadata created: ${BACKUP_DIR}/${BACKUP_NAME}.json"
}

# Upload to cloud storage (S3, GCS, etc.)
upload_to_cloud() {
    if [ -n "$AWS_S3_BUCKET" ]; then
        log_info "Uploading to S3 bucket: $AWS_S3_BUCKET"
        aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.dump" "s3://${AWS_S3_BUCKET}/backups/" --storage-class STANDARD_IA
        aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" "s3://${AWS_S3_BUCKET}/backups/" --storage-class STANDARD_IA
        aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.json" "s3://${AWS_S3_BUCKET}/backups/"
    elif [ -n "$GCS_BUCKET" ]; then
        log_info "Uploading to GCS bucket: $GCS_BUCKET"
        gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.dump" "gs://${GCS_BUCKET}/backups/"
        gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz" "gs://${GCS_BUCKET}/backups/"
        gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.json" "gs://${GCS_BUCKET}/backups/"
    else
        log_warning "No cloud storage configured. Backups are only stored locally."
    fi
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning backups older than ${RETENTION_DAYS} days"
    
    # Local cleanup
    find "$BACKUP_DIR" -name "kct_backup_*.dump" -mtime +${RETENTION_DAYS} -delete
    find "$BACKUP_DIR" -name "kct_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    find "$BACKUP_DIR" -name "kct_backup_*.json" -mtime +${RETENTION_DAYS} -delete
    
    # Cloud cleanup for S3
    if [ -n "$AWS_S3_BUCKET" ]; then
        aws s3 ls "s3://${AWS_S3_BUCKET}/backups/" | while read -r line; do
            createDate=$(echo "$line" | awk '{print $1" "$2}')
            createDate=$(date -d "$createDate" +%s)
            olderThan=$(date -d "${RETENTION_DAYS} days ago" +%s)
            if [[ $createDate -lt $olderThan ]]; then
                fileName=$(echo "$line" | awk '{print $4}')
                if [[ $fileName == kct_backup_* ]]; then
                    aws s3 rm "s3://${AWS_S3_BUCKET}/backups/$fileName"
                fi
            fi
        done
    fi
}

# Verify backup
verify_backup() {
    log_info "Verifying backup integrity"
    
    # Check if files exist and have content
    if [ ! -s "${BACKUP_DIR}/${BACKUP_NAME}.dump" ]; then
        log_error "Backup file is empty or doesn't exist"
        exit 1
    fi
    
    # Test restore to temporary database (optional)
    if [ "$VERIFY_RESTORE" = "true" ]; then
        log_info "Testing restore (dry run)"
        pg_restore --list "${BACKUP_DIR}/${BACKUP_NAME}.dump" > /dev/null
        if [ $? -eq 0 ]; then
            log_info "Backup verification successful"
        else
            log_error "Backup verification failed"
            exit 1
        fi
    fi
}

# Send notification
send_notification() {
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Database backup completed successfully: ${BACKUP_NAME}\"}" \
            "$SLACK_WEBHOOK_URL"
    fi
    
    if [ -n "$EMAIL_TO" ]; then
        echo "Database backup completed: ${BACKUP_NAME}" | \
            mail -s "KCT Database Backup Success" "$EMAIL_TO"
    fi
}

# Main execution
main() {
    log_info "=== KCT Database Backup Script ==="
    
    check_env
    create_backup_dir
    backup_database
    create_metadata
    verify_backup
    upload_to_cloud
    cleanup_old_backups
    send_notification
    
    log_info "=== Backup completed successfully ==="
}

# Run main function
main "$@"