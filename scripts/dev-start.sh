#!/bin/bash

set -e

echo "🚀 Starting EkoSim Development Environment..."

# Check if required sibling directories exist
if [ ! -d "../ekosim" ]; then
    echo "❌ Error: ../ekosim directory not found"
    exit 1
fi

if [ ! -d "../EkoWeb" ]; then
    echo "❌ Error: ../EkoWeb directory not found"
    exit 1
fi

# Detect container runtime and compose tool
CONTAINER_CMD=""
COMPOSE_CMD=""

# Check for Docker first
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
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
    echo "❌ Error: Neither Docker nor Podman is available or running"
    echo "Please install and start Docker Desktop or Podman before running this script"
    exit 1
fi

echo "🔧 Container runtime: $CONTAINER_CMD"
echo "🔧 Compose tool: $COMPOSE_CMD"

# Build and start all services
echo "📦 Building containers..."
$COMPOSE_CMD build

echo "🔄 Starting services..."
$COMPOSE_CMD up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 10

# Show status
echo "📊 Service Status:"
$COMPOSE_CMD ps

echo ""
echo "✅ Development environment is ready!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 API: http://localhost:3001"
echo "⚙️  Backend: http://localhost:8080"
echo ""
echo "📝 View logs: $COMPOSE_CMD logs -f [service-name]"
echo "🛑 Stop: $COMPOSE_CMD down"