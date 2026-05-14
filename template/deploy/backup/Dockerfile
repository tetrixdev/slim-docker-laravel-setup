# =============================================================================
# BACKUP SIDECAR
# slim-docker-laravel-setup
#
# Lightweight container that runs scheduled PostgreSQL backups.
# Built locally on the server (not in CI) — build takes ~1 second.
# =============================================================================
FROM postgres:17-alpine

RUN apk add --no-cache dcron

COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Run backup daily at 03:00 server time
RUN echo "0 3 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1" | crontab -

RUN mkdir -p /backups

CMD ["crond", "-f", "-l", "2"]
