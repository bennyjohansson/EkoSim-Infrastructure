#!/bin/bash
# Quick rebuild script for C++ backend in container
# Usage: ./scripts/rebuild-backend.sh

set -e

CONTAINER_NAME="ekosim-infrastructure_ekosim-backend_1"
SOURCE_DIR="../ekosim"
APP_DIR="/app"

echo "🔨 Rebuilding C++ backend in container..."

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container ${CONTAINER_NAME} is not running"
    exit 1
fi

echo "📦 Copying source files to container..."
podman cp ${SOURCE_DIR}/. ${CONTAINER_NAME}:${APP_DIR}/

echo "🛠️  Recompiling..."
podman exec ${CONTAINER_NAME} sh -c "cd ${APP_DIR} && make clean && make"

echo "🔄 Restarting container..."
podman restart ${CONTAINER_NAME}

echo "✅ Backend rebuilt and restarted successfully!"
echo "📊 Check logs with: podman logs ${CONTAINER_NAME} --tail 20"
