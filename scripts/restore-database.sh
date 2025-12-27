#!/bin/bash
# EkoSim PostgreSQL Restore Script
# Restores the PostgreSQL database from a backup file

set -e  # Exit on error

# Configuration
CONTAINER_NAME="ekosim-postgres"
DB_NAME="ekosim"
DB_USER="ekosim"
LOG_FILE="/var/log/ekosim/restore.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file.sql.gz> [--from-gcs]"
    echo ""
    echo "Examples:"
    echo "  $0 /var/backups/ekosim/ekosim_backup_20250127_030000.sql.gz"
    echo "  $0 gs://ekosim-backups/database/ekosim_backup_20250127_030000.sql.gz --from-gcs"
    echo ""
    exit 1
fi

BACKUP_FILE="$1"
FROM_GCS="$2"

log "=== Starting EkoSim Database Restore ==="

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log "❌ ERROR: PostgreSQL container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Download from Cloud Storage if needed
if [ "$FROM_GCS" == "--from-gcs" ]; then
    log "☁️ Downloading backup from Google Cloud Storage..."
    TEMP_FILE="/tmp/$(basename $BACKUP_FILE)"
    if gsutil cp "$BACKUP_FILE" "$TEMP_FILE"; then
        log "✅ Backup downloaded to $TEMP_FILE"
        BACKUP_FILE="$TEMP_FILE"
    else
        log "❌ ERROR: Failed to download backup from Cloud Storage"
        exit 1
    fi
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log "❌ ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

log "📦 Using backup file: $BACKUP_FILE"

# Decompress if needed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    log "🗜️ Decompressing backup..."
    DECOMPRESSED_FILE="${BACKUP_FILE%.gz}"
    if gunzip -c "$BACKUP_FILE" > "$DECOMPRESSED_FILE"; then
        log "✅ Backup decompressed"
        RESTORE_FILE="$DECOMPRESSED_FILE"
    else
        log "❌ ERROR: Failed to decompress backup"
        exit 1
    fi
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Confirm restoration
echo ""
echo "⚠️  WARNING: This will DROP and recreate the database '$DB_NAME'"
echo "Current database will be PERMANENTLY DELETED!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log "❌ Restoration cancelled by user"
    exit 1
fi

# Stop dependent services
log "🛑 Stopping dependent services..."
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml stop ekosim-api ekosim-backend ekosim-frontend

# Drop existing database and recreate
log "🗄️ Dropping existing database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
log "🗄️ Creating new database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"

# Restore database
log "📥 Restoring database from backup..."
if cat "$RESTORE_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"; then
    log "✅ Database restored successfully"
else
    log "❌ ERROR: Failed to restore database"
    exit 1
fi

# Restart services
log "🔄 Restarting services..."
docker-compose -f docker-compose.prod-postgresql.yml start ekosim-api ekosim-backend ekosim-frontend

# Wait for services to be healthy
log "⏳ Waiting for services to be healthy..."
sleep 10

# Check service health
if docker-compose -f docker-compose.prod-postgresql.yml ps | grep -q "Up (healthy)"; then
    log "✅ Services are healthy"
else
    log "⚠️ WARNING: Some services may not be healthy, check docker-compose ps"
fi

# Clean up temporary files
if [ "$FROM_GCS" == "--from-gcs" ]; then
    rm -f "$TEMP_FILE"
fi
if [ -f "$DECOMPRESSED_FILE" ] && [ "$DECOMPRESSED_FILE" != "$BACKUP_FILE" ]; then
    rm -f "$DECOMPRESSED_FILE"
fi

log "=== Restoration Complete ==="
log "Please verify the application is working correctly"
log ""

exit 0
