#!/bin/bash

# Database Restore Script for KCT Menswear Super Admin
# This script restores database from backup files

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_prompt() {
    echo -e "${BLUE}[PROMPT]${NC} $1"
}

# Check required environment variables
check_env() {
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is not set"
        echo "Please set it using: export DATABASE_URL='postgresql://...'"
        exit 1
    fi
}

# List available backups
list_backups() {
    log_info "Available backups:"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "$BACKUP_DIR"/*.dump 2>/dev/null | awk '{print NR".", $9, "("$5")", $6, $7, $8}' || echo "No backups found"
    else
        log_error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi
    echo ""
}

# Select backup file
select_backup() {
    if [ -n "$1" ]; then
        BACKUP_FILE="$1"
    else
        list_backups
        log_prompt "Enter the backup file path or number: "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            BACKUP_FILE=$(ls "$BACKUP_DIR"/*.dump 2>/dev/null | sed -n "${selection}p")
        else
            BACKUP_FILE="$selection"
        fi
    fi
    
    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    log_info "Selected backup: $BACKUP_FILE"
}

# Download from cloud if needed
download_from_cloud() {
    if [ -n "$2" ]; then
        CLOUD_PATH="$2"
        
        if [[ "$CLOUD_PATH" == s3://* ]]; then
            log_info "Downloading from S3: $CLOUD_PATH"
            aws s3 cp "$CLOUD_PATH" "$BACKUP_DIR/"
            BACKUP_FILE="$BACKUP_DIR/$(basename "$CLOUD_PATH")"
        elif [[ "$CLOUD_PATH" == gs://* ]]; then
            log_info "Downloading from GCS: $CLOUD_PATH"
            gsutil cp "$CLOUD_PATH" "$BACKUP_DIR/"
            BACKUP_FILE="$BACKUP_DIR/$(basename "$CLOUD_PATH")"
        fi
    fi
}

# Create restore point
create_restore_point() {
    log_info "Creating restore point before restoration"
    RESTORE_POINT="restore_point_$(date +%Y%m%d_%H%M%S)"
    
    pg_dump "$DATABASE_URL" \
        --format=custom \
        --no-owner \
        --no-privileges \
        --file="${BACKUP_DIR}/${RESTORE_POINT}.dump"
    
    log_info "Restore point created: ${BACKUP_DIR}/${RESTORE_POINT}.dump"
}

# Confirm restoration
confirm_restore() {
    log_warning "WARNING: This will restore the database from backup."
    log_warning "Current data will be replaced with backup data."
    echo ""
    log_prompt "Type 'RESTORE' to confirm: "
    read -r confirmation
    
    if [ "$confirmation" != "RESTORE" ]; then
        log_info "Restoration cancelled"
        exit 0
    fi
}

# Perform restoration
restore_database() {
    log_info "Starting database restoration"
    
    # Parse database name from URL
    DB_NAME=$(echo "$DATABASE_URL" | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    # Options for restoration
    RESTORE_OPTS="--verbose --no-owner --no-privileges"
    
    if [ "$DROP_EXISTING" = "true" ]; then
        log_warning "Dropping existing database objects"
        RESTORE_OPTS="$RESTORE_OPTS --clean --if-exists"
    fi
    
    if [ "$DATA_ONLY" = "true" ]; then
        log_info "Restoring data only (no schema)"
        RESTORE_OPTS="$RESTORE_OPTS --data-only"
    fi
    
    if [ "$SCHEMA_ONLY" = "true" ]; then
        log_info "Restoring schema only (no data)"
        RESTORE_OPTS="$RESTORE_OPTS --schema-only"
    fi
    
    # Perform restore
    pg_restore $RESTORE_OPTS -d "$DATABASE_URL" "$BACKUP_FILE" || {
        log_error "Restoration failed. Your restore point is: ${RESTORE_POINT}.dump"
        exit 1
    }
    
    log_info "Database restoration completed successfully"
}

# Verify restoration
verify_restore() {
    log_info "Verifying restoration"
    
    # Check table counts
    psql "$DATABASE_URL" -c "
        SELECT 
            schemaname,
            COUNT(*) as table_count
        FROM pg_tables 
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
        GROUP BY schemaname;" || {
        log_error "Verification failed"
        exit 1
    }
    
    log_info "Restoration verified"
}

# Post-restore tasks
post_restore() {
    log_info "Running post-restore tasks"
    
    # Update sequences
    psql "$DATABASE_URL" -c "
        DO \$\$
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN 
                SELECT 
                    schemaname, 
                    tablename, 
                    pg_get_serial_sequence(schemaname||'.'||tablename, 'id') as seq
                FROM pg_tables 
                WHERE schemaname = 'public' 
                AND pg_get_serial_sequence(schemaname||'.'||tablename, 'id') IS NOT NULL
            LOOP
                EXECUTE 'SELECT setval(''' || r.seq || ''', COALESCE((SELECT MAX(id) FROM ' || 
                        r.schemaname || '.' || r.tablename || '), 1))';
            END LOOP;
        END \$\$;"
    
    # Refresh materialized views if any
    psql "$DATABASE_URL" -c "
        DO \$\$
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN SELECT schemaname, matviewname 
                     FROM pg_matviews 
                     WHERE schemaname = 'public'
            LOOP
                EXECUTE 'REFRESH MATERIALIZED VIEW ' || r.schemaname || '.' || r.matviewname;
            END LOOP;
        END \$\$;"
    
    # Analyze tables for query optimizer
    psql "$DATABASE_URL" -c "ANALYZE;"
    
    log_info "Post-restore tasks completed"
}

# Send notification
send_notification() {
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Database restoration completed successfully from: $(basename "$BACKUP_FILE")\"}" \
            "$SLACK_WEBHOOK_URL"
    fi
    
    if [ -n "$EMAIL_TO" ]; then
        echo "Database restored from: $(basename "$BACKUP_FILE")" | \
            mail -s "KCT Database Restoration Success" "$EMAIL_TO"
    fi
}

# Show usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [BACKUP_FILE]

Options:
    -h, --help          Show this help message
    -y, --yes           Skip confirmation prompt
    -d, --data-only     Restore data only (no schema)
    -s, --schema-only   Restore schema only (no data)
    -c, --clean         Drop existing database objects before restore
    --no-restore-point  Skip creating restore point
    
Environment Variables:
    DATABASE_URL        PostgreSQL connection string (required)
    BACKUP_DIR          Directory containing backups (default: ./backups)
    
Examples:
    $0                                    # Interactive mode
    $0 ./backups/kct_backup_20240101.dump # Restore specific file
    $0 -y -d backup.dump                  # Restore data only without confirmation
    
EOF
}

# Parse arguments
SKIP_CONFIRM=false
SKIP_RESTORE_POINT=false
DROP_EXISTING=false
DATA_ONLY=false
SCHEMA_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -d|--data-only)
            DATA_ONLY=true
            shift
            ;;
        -s|--schema-only)
            SCHEMA_ONLY=true
            shift
            ;;
        -c|--clean)
            DROP_EXISTING=true
            shift
            ;;
        --no-restore-point)
            SKIP_RESTORE_POINT=true
            shift
            ;;
        *)
            BACKUP_FILE="$1"
            shift
            ;;
    esac
done

# Main execution
main() {
    log_info "=== KCT Database Restore Script ==="
    
    check_env
    download_from_cloud "$@"
    select_backup "$BACKUP_FILE"
    
    if [ "$SKIP_CONFIRM" != "true" ]; then
        confirm_restore
    fi
    
    if [ "$SKIP_RESTORE_POINT" != "true" ]; then
        create_restore_point
    fi
    
    restore_database
    verify_restore
    post_restore
    send_notification
    
    log_info "=== Restoration completed successfully ==="
}

# Run main function
main "$@"