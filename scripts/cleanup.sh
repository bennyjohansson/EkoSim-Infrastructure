#!/bin/bash

set -e

echo "🧹 Cleaning up EkoSim Docker resources..."

# Detect container runtime and compose tool
CONTAINER_CMD=""
COMPOSE_CMD=""

# Check for Docker first
if command -v docker >/dev/null 2>&1; then
    echo "🐳 Using Docker"
    CONTAINER_CMD="docker"
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
# Check for Podman
elif command -v podman >/dev/null 2>&1; then
    echo "🐙 Using Podman"
    CONTAINER_CMD="podman"
    if command -v podman-compose >/dev/null 2>&1; then
        COMPOSE_CMD="podman-compose"
    else
        COMPOSE_CMD="podman compose"
    fi
else
    echo "❌ Error: Neither Docker nor Podman is available"
    exit 1
fi

# Stop all running containers
echo "🛑 Stopping all containers..."
$COMPOSE_CMD down 2>/dev/null || true
$COMPOSE_CMD -f docker-compose.prod.yml down 2>/dev/null || true

# Remove containers
echo "🗑️  Removing containers..."
$COMPOSE_CMD rm -f 2>/dev/null || true

# Remove images
echo "🗑️  Removing images..."
if [ "$CONTAINER_CMD" = "docker" ]; then
    docker images | grep ekosim | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true
else
    podman images | grep ekosim | awk '{print $3}' | xargs podman rmi -f 2>/dev/null || true
fi

# Clean up unused resources
echo "🧽 Cleaning up unused resources..."
$CONTAINER_CMD system prune -f

# Option to remove volumes (data)
if [ "$1" == "--volumes" ]; then
    echo "⚠️  Removing volumes (this will delete your database data)..."
    if [ "$CONTAINER_CMD" = "docker" ]; then
        docker volume rm ekosim-infrastructure_sqlite-data 2>/dev/null || true
    else
        podman volume rm ekosim-infrastructure_sqlite-data 2>/dev/null || true
    fi
fi

echo "✅ Cleanup complete!"
echo ""
if [ "$1" != "--volumes" ]; then
    echo "💾 Database volumes preserved. Use '--volumes' flag to remove them."
fi