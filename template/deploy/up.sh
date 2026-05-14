#!/bin/bash
# Server-side deploy script for slim-docker-laravel-setup
#
# Pulls latest images, starts services, builds backup sidecar locally,
# and waits for health checks to pass before reporting success.
#
# Automatically used by vps-setup's `up` command when present in the
# project directory. Can also be run directly: bash deploy/up.sh
set -e

DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$DEPLOY_DIR/compose.yml"

echo "Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans

# Wait for health checks
echo "Waiting for health checks..."
TIMEOUT=90
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    # Check for any containers still starting up or unhealthy
    if docker compose -f "$COMPOSE_FILE" ps 2>/dev/null | grep -qiE "\(health: starting\)|\(unhealthy\)"; then
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    else
        break
    fi
done

if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Warning: health check timeout after ${TIMEOUT}s"
    docker compose -f "$COMPOSE_FILE" ps
    exit 1
fi

echo "All services healthy."
