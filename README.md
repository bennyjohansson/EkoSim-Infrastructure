# EkoSim Infrastructure

**Docker Compose Orchestration & Deployment Configuration**

## Overview

This repository contains all infrastructure configuration for deploying the EkoSim platform. It orchestrates the C++ simulation engine, Node.js API server, Vue.js frontend, and PostgreSQL database using Docker Compose.

## What It Does

- **Service Orchestration**: Manages all EkoSim components as containerized services
- **Database Management**: PostgreSQL setup with schema migrations
- **Network Configuration**: Internal Docker networking for service communication
- **Volume Management**: Persistent data storage for databases and SQLite files
- **Environment Configuration**: Centralized environment variable management
- **Production Ready**: Includes production Docker Compose with Nginx

## Repository Structure

```
EkoSim-Infrastructure/
├── docker-compose.yml          # Development environment
├── docker-compose.prod.yml     # Production environment
├── docker-compose.minimal.yml  # Minimal testing setup
│
├── dockerfiles/
│   ├── backend.Dockerfile      # C++ simulation engine
│   ├── api.Dockerfile          # Node.js API server
│   └── frontend.Dockerfile     # Vue 3 frontend (dev mode)
│
├── database/
│   ├── schema/                 # PostgreSQL schema files
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_indexes.sql
│   │   ├── 003_seed_data.sql
│   │   └── ...
│   └── migrations/             # Database migration scripts
│
├── config/
│   ├── nginx.conf              # Nginx reverse proxy config
│   └── env/                    # Environment variable templates
│       ├── api.env.example
│       └── backend.env.example
│
└── scripts/
    ├── dev-start.sh            # Start development environment
    ├── prod-deploy.sh          # Deploy production
    ├── rebuild-backend.sh      # Rebuild C++ backend only
    └── cleanup.sh              # Clean up containers and volumes
```

## Services

### `ekosim-frontend` (Port 3000)

- **Image**: Node.js 20 Alpine
- **Purpose**: Serves Vue 3 frontend via Vite dev server
- **Volumes**: Live code reload from `../EkoWeb/frontend`
- **Environment**: `DOCKER_ENV=true` for container detection
- **Depends On**: ekosim-api

### `ekosim-api` (Port 3001)

- **Image**: Node.js 18 Alpine
- **Purpose**: Express API server with authentication and data proxy
- **Volumes**:
  - Live code reload from `../EkoWeb/api`
  - Named volume for node_modules
  - SQLite database access from `../ekosim/myDB`
- **Environment**: PostgreSQL connection, JWT secret
- **Depends On**: ekosim-postgres

### `ekosim-backend` (Port 8080)

- **Image**: Ubuntu 22.04 with C++ build tools
- **Purpose**: C++ economic simulation engine
- **Build**: Compiles C++ code from `../ekosim`
- **Volumes**: SQLite database output directory
- **Environment**: PostgreSQL connection for state storage
- **Depends On**: ekosim-postgres

### `ekosim-postgres` (Port 5432)

- **Image**: PostgreSQL 15 Alpine
- **Purpose**: Primary database for all application data
- **Volumes**:
  - Named volume for persistent data
  - Schema files mounted for automatic initialization
- **Health Check**: pg_isready every 30 seconds
- **Data**: Users, simulation state, time series, high scores

## Networking

All services communicate via the `ekosim-network` bridge network:

- Frontend → API: `http://ekosim-api:3001`
- API → PostgreSQL: `ekosim-postgres:5432`
- Backend → PostgreSQL: `ekosim-postgres:5432`

External access:

- Frontend: `http://localhost:3000`
- API: `http://localhost:3001`
- PostgreSQL: `localhost:5432` (dev only)

## Quick Start

### Development Environment

```bash
# Copy environment template
cp config/env/api.env.example .env

# Edit .env with your configuration
nano .env

# Start all services
docker-compose up

# Or use the script
./scripts/dev-start.sh
```

### Production Deployment

```bash
# Use production compose file
docker-compose -f docker-compose.prod.yml up -d

# Or use deployment script
./scripts/prod-deploy.sh
```

### Rebuild Single Service

```bash
# Rebuild just the C++ backend
docker-compose build ekosim-backend
docker-compose up -d ekosim-backend

# Or use the script
./scripts/rebuild-backend.sh
```

## Database Initialization

On first run, PostgreSQL automatically executes schema files in order:

1. `001_initial_schema.sql` - Core tables (users, parameters, data)
2. `002_indexes.sql` - Performance indexes
3. `003_seed_data.sql` - Default data
4. `004_compatibility_views.sql` - Legacy compatibility
5. `005_high_scores.sql` - High score tables
6. And so on...

## Environment Variables

Required in `.env` file:

```bash
POSTGRES_DB=ekosim
POSTGRES_USER=ekosim
POSTGRES_PASSWORD=<secure-password>
JWT_SECRET=<secure-random-string>
```

## Volume Management

### Named Volumes

- `postgres_data` - PostgreSQL database files (persistent)
- `ekosim-api-modules` - Node.js dependencies for API

### Bind Mounts

- `../EkoWeb/frontend:/app` - Frontend live reload
- `../EkoWeb/api:/app` - API live reload
- `../ekosim/myDB` - SQLite database access

## Production Differences

`docker-compose.prod.yml` includes:

- Nginx reverse proxy for SSL termination
- No bind mounts (code copied into containers)
- Health checks and restart policies
- Resource limits
- Production environment variables
- Volume-mounted configuration files

## Monitoring & Logs

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f ekosim-api

# Check service status
docker-compose ps

# Health check
curl http://localhost:3001/health
```

## Cleanup

```bash
# Stop services
docker-compose down

# Remove volumes (⚠️ deletes data)
docker-compose down -v

# Use cleanup script
./scripts/cleanup.sh
```

## Scaling Considerations

For production deployment:

- Consider Kubernetes for multi-node deployments
- Add Redis for session management
- Implement proper secrets management (Vault, AWS Secrets Manager)
- Set up log aggregation (ELK stack, Loki)
- Configure monitoring (Prometheus, Grafana)
- Implement CI/CD pipeline (GitHub Actions, GitLab CI)

## Troubleshooting

**Container won't start:**

```bash
docker-compose logs <service-name>
docker-compose ps
```

**Database connection issues:**

```bash
docker-compose exec ekosim-postgres psql -U ekosim -d ekosim
```

**Rebuild from scratch:**

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

---

**Part of the EkoSim Platform** - See also:

- [ekosim](../ekosim/README.md) - C++ simulation engine
- [EkoWeb](../EkoWeb/README.md) - API server and web frontend
