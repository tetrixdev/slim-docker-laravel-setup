#!/bin/sh
# PostgreSQL backup script for slim-docker-laravel-setup
#
# Runs inside the backup sidecar container. Uses standard PG* environment
# variables set by the compose file to connect to the database.
#
# Backups are gzipped SQL dumps stored in /backups (a named Docker volume).
# Old backups are automatically deleted after BACKUP_RETENTION_DAYS (default: 7).
set -e

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${PGDATABASE}_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting backup of ${PGDATABASE}..."

pg_dump -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" | gzip > "$BACKUP_FILE"

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Backup complete: ${BACKUP_FILE} (${SIZE})"

# Clean up old backups
RETENTION=${BACKUP_RETENTION_DAYS:-7}
DELETED=$(find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION" -delete -print | wc -l)
if [ "$DELETED" -gt 0 ]; then
    echo "[$(date)] Cleaned up ${DELETED} backup(s) older than ${RETENTION} days"
fi
