#!/bin/bash
# EkoSim PostgreSQL Backup Script
# Backs up the PostgreSQL database to Cloud Storage
# Schedule with cron: 0 3 * * * /opt/ekosim/scripts/backup-database.sh

set -e  # Exit on error

# Configuration
BACKUP_DIR="/var/backups/ekosim"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_NAME="ekosim-postgres"
DB_NAME="ekosim"
DB_USER="ekosim"
GCS_BUCKET="gs://ekosim-backups"
RETENTION_DAYS=7
LOG_FILE="/var/log/ekosim/backup.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting EkoSim Database Backup ==="

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log "❌ ERROR: PostgreSQL container '$CONTAINER_NAME' is not running"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup filename
BACKUP_FILE="$BACKUP_DIR/ekosim_backup_$DATE.sql"
COMPRESSED_FILE="$BACKUP_FILE.gz"

# Create database backup
log "📦 Creating database backup..."
if docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"; then
    log "✅ Database backup created: $BACKUP_FILE"
else
    log "❌ ERROR: Failed to create database backup"
    exit 1
fi

# Compress backup
log "🗜️ Compressing backup..."
if gzip "$BACKUP_FILE"; then
    log "✅ Backup compressed: $COMPRESSED_FILE"
else
    log "❌ ERROR: Failed to compress backup"
    exit 1
fi

# Get file size
BACKUP_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
log "📊 Backup size: $BACKUP_SIZE"

# Upload to Google Cloud Storage
log "☁️ Uploading to Google Cloud Storage..."
if gsutil cp "$COMPRESSED_FILE" "$GCS_BUCKET/database/"; then
    log "✅ Backup uploaded to $GCS_BUCKET/database/$(basename $COMPRESSED_FILE)"
else
    log "❌ ERROR: Failed to upload backup to Cloud Storage"
    exit 1
fi

# Verify upload
if gsutil ls "$GCS_BUCKET/database/$(basename $COMPRESSED_FILE)" > /dev/null 2>&1; then
    log "✅ Upload verified in Cloud Storage"
else
    log "⚠️ WARNING: Could not verify upload in Cloud Storage"
fi

# Clean up old local backups (keep last 7 days)
log "🧹 Cleaning up old local backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "ekosim_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "ekosim_backup_*.sql.gz" | wc -l)
log "📁 Local backups remaining: $REMAINING_BACKUPS"

# Optional: Clean up old Cloud Storage backups (keep last 30 days)
# Uncomment the following lines to enable Cloud Storage retention policy
# log "🧹 Cleaning up old Cloud Storage backups (keeping last 30 days)..."
# gsutil -m rm $(gsutil ls "$GCS_BUCKET/database/ekosim_backup_*.sql.gz" | head -n -30) 2>/dev/null || true

# Create a backup metadata file
METADATA_FILE="$BACKUP_DIR/last_backup.json"
cat > "$METADATA_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "date_local": "$(date '+%Y-%m-%d %H:%M:%S')",
  "filename": "$(basename $COMPRESSED_FILE)",
  "size": "$BACKUP_SIZE",
  "database": "$DB_NAME",
  "container": "$CONTAINER_NAME",
  "cloud_location": "$GCS_BUCKET/database/$(basename $COMPRESSED_FILE)"
}
EOF

log "✅ Backup metadata saved: $METADATA_FILE"

# Optional: Send notification (uncomment and configure)
# curl -X POST https://your-webhook-url.com/backup-notification \
#   -H "Content-Type: application/json" \
#   -d "{\"status\":\"success\",\"backup\":\"$(basename $COMPRESSED_FILE)\",\"size\":\"$BACKUP_SIZE\"}"

log "=== Backup Complete ==="
log ""

exit 0
