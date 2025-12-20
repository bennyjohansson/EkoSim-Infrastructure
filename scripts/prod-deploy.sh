#!/bin/bash

set -e

echo "🚀 Deploying EkoSim Production Environment..."

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

# Create environment files if they don't exist
if [ ! -f "./config/env/api.env" ]; then
    echo "📝 Creating API environment file template..."
    cat > ./config/env/api.env << EOF
NODE_ENV=production
PORT=3000
DATABASE_PATH=/data/ekosim.db
BACKEND_URL=http://ekosim-backend:8080
# Add your production API configuration here
EOF
fi

if [ ! -f "./config/env/backend.env" ]; then
    echo "📝 Creating Backend environment file template..."
    cat > ./config/env/backend.env << EOF
DATABASE_PATH=/data/ekosim.db
LOG_LEVEL=info
# Add your production backend configuration here
EOF
fi

# Stop any running containers
echo "🛑 Stopping existing containers..."
$COMPOSE_CMD -f docker-compose.prod.yml down

# Build production containers
echo "📦 Building production containers..."
$COMPOSE_CMD -f docker-compose.prod.yml build --no-cache

# Start production environment
echo "🔄 Starting production services..."
$COMPOSE_CMD -f docker-compose.prod.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 15

# Show status
echo "📊 Service Status:"
$COMPOSE_CMD -f docker-compose.prod.yml ps

echo ""
echo "✅ Production environment is ready!"
echo "🌐 Application: http://localhost"
echo ""
echo "📝 View logs: $COMPOSE_CMD -f docker-compose.prod.yml logs -f [service-name]"
echo "🛑 Stop: $COMPOSE_CMD -f docker-compose.prod.yml down"