# EkoSim Infrastructure

Docker orchestration and deployment infrastructure for the EkoSim Economic Simulation Platform.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vue Frontend  │    │   Node.js API   │    │   C++ Backend   │
│   (Container)   │◄──►│   (Container)   │◄──►│   + SQLite      │
│     Nginx       │    │                 │    │   (Container)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Project Structure

This repository orchestrates three separate git repositories:

```
Projects/
├── ekosim/                    # C++ Backend + SQLite (separate repo)
├── EkoWeb/                    # Vue Frontend + Node.js API (separate repo)
└── EkoSim-Infrastructure/     # Docker orchestration (this repo)
    ├── dockerfiles/           # Container build instructions
    │   ├── frontend.Dockerfile
    │   ├── api.Dockerfile
    │   └── backend.Dockerfile
    ├── docker-compose.yml     # Development environment
    ├── docker-compose.prod.yml # Production environment
    ├── scripts/               # Deployment and utility scripts
    │   ├── dev-start.sh
    │   ├── prod-deploy.sh
    │   └── cleanup.sh
    └── config/                # Environment configurations
        ├── nginx.conf
        └── env/
```

## Quick Start

### Prerequisites

Ensure you have the following structure:
```
Projects/
├── ekosim/          # Your C++ backend repository
├── EkoWeb/          # Your Vue + Node.js repository  
└── EkoSim-Infrastructure/  # This repository
```

### Development Environment

```bash
# Start development environment
./scripts/dev-start.sh

# View logs
docker-compose logs -f

# Stop environment
docker-compose down
```

### Production Environment

```bash
# Deploy production environment
./scripts/prod-deploy.sh

# Stop production environment  
docker-compose -f docker-compose.prod.yml down
```

### Cleanup

```bash
# Clean up containers and images
./scripts/cleanup.sh

# Clean up including volumes (⚠️ removes database data)
./scripts/cleanup.sh --volumes
```

## Services

- **Frontend** (Port 3000 dev / 80 prod): Vue.js application served by Nginx
- **API** (Port 3001 dev): Node.js REST API
- **Backend** (Port 8080): C++ simulation engine with SQLite database

## Configuration

Copy and customize environment files:
```bash
cp config/env/api.env.example config/env/api.env
cp config/env/backend.env.example config/env/backend.env
```

## Development Notes

- Development mode uses volume mounts for live code reloading
- SQLite database persists in a Docker volume
- Nginx proxies API calls to backend services
- All services communicate through a shared Docker network

## Repositories

- **Frontend & API**: https://github.com/bennyjohansson/EkoWeb
- **C++ Backend**: https://github.com/bennyjohansson/ekosim  
- **Infrastructure**: https://github.com/bennyjohansson/EkoSim-Infrastructure (this repo)

## Next Steps

1. **Customize Dockerfiles** based on your specific build requirements
2. **Update environment variables** in `config/env/` files
3. **Adjust nginx configuration** in `config/nginx.conf` as needed
4. **Test the setup** with your actual project structure