#!/bin/bash
# EkoSim Quick Deploy Script
# Automates the deployment process on GCP VM

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         EkoSim Production Deployment Script               ║"
echo "║         Phase 1: GCP Compute Engine + PostgreSQL          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on VM or local machine
if [ ! -d "/opt/ekosim" ]; then
    log_error "This script must be run on the GCP VM in /opt/ekosim directory"
    echo ""
    echo "Run these commands first:"
    echo "  1. Create VM: gcloud compute instances create ekosim-server ..."
    echo "  2. SSH into VM: gcloud compute ssh ekosim-server --zone=us-central1-a"
    echo "  3. Run setup: curl -fsSL <setup-script-url> | bash"
    echo ""
    exit 1
fi

cd /opt/ekosim

# Step 1: Verify repositories are cloned
echo ""
echo "Step 1: Verifying repositories..."
if [ ! -d "ekosim" ] || [ ! -d "EkoWeb" ] || [ ! -d "EkoSim-Infrastructure" ]; then
    log_error "Repositories not found. Please clone them first:"
    echo "  git clone https://github.com/YOUR_USERNAME/ekosim.git"
    echo "  git clone https://github.com/YOUR_USERNAME/EkoWeb.git"
    echo "  git clone https://github.com/YOUR_USERNAME/EkoSim-Infrastructure.git"
    exit 1
fi
log_info "All repositories found"

# Step 2: Check if .env exists
echo ""
echo "Step 2: Checking environment configuration..."
cd EkoSim-Infrastructure
if [ ! -f ".env" ]; then
    log_warn ".env file not found. Creating from template..."
    
    if [ ! -f ".env.production.template" ]; then
        log_error "Template not found. Please ensure .env.production.template exists"
        exit 1
    fi
    
    # Generate secrets
    POSTGRES_PASSWORD=$(openssl rand -hex 32)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
    SESSION_SECRET=$(openssl rand -hex 32)
    
    # Create .env file
    cat > .env <<EOF
# EkoSim Production Environment Variables
POSTGRES_DB=ekosim
POSTGRES_USER=ekosim
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
ALLOWED_ORIGINS=https://ekosim.app,https://www.ekosim.app
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
    
    log_info ".env file created with generated secrets"
    log_warn "IMPORTANT: Save these secrets in a secure location!"
    echo "=============================================="
    cat .env
    echo "=============================================="
    echo ""
    read -p "Press Enter to continue after saving secrets..."
else
    log_info ".env file exists"
fi

# Step 3: Create Cloud Storage bucket for backups
echo ""
echo "Step 3: Setting up Cloud Storage for backups..."
if gsutil ls gs://ekosim-backups > /dev/null 2>&1; then
    log_info "Backup bucket already exists"
else
    log_info "Creating backup bucket..."
    gsutil mb -l us-central1 gs://ekosim-backups
    
    # Set lifecycle policy
    cat > /tmp/lifecycle.json <<'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 90}
      }
    ]
  }
}
EOF
    gsutil lifecycle set /tmp/lifecycle.json gs://ekosim-backups
    log_info "Backup bucket created with 90-day retention"
fi

# Step 4: Make scripts executable
echo ""
echo "Step 4: Setting up backup scripts..."
chmod +x scripts/backup-database.sh
chmod +x scripts/restore-database.sh
chmod +x scripts/gcp-vm-setup.sh
log_info "Scripts are executable"

# Step 5: Set up cron jobs
echo ""
echo "Step 5: Configuring automated backups..."
if crontab -l 2>/dev/null | grep -q "backup-database.sh"; then
    log_info "Backup cron job already configured"
else
    (crontab -l 2>/dev/null; echo "0 3 * * * /opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh") | crontab -
    log_info "Backup cron job configured (daily at 3 AM)"
fi

# Step 6: Create log directories
echo ""
echo "Step 6: Creating log directories..."
sudo mkdir -p /var/log/ekosim
sudo chown $USER:$USER /var/log/ekosim
mkdir -p logs/nginx
log_info "Log directories created"

# Step 7: Pull Docker images
echo ""
echo "Step 7: Pulling base Docker images..."
docker pull postgres:15-alpine
docker pull node:20-alpine
docker pull nginx:alpine
docker pull ubuntu:22.04
log_info "Base images pulled"

# Step 8: Build and start services
echo ""
echo "Step 8: Building and starting services..."
echo "This may take 5-10 minutes..."
docker-compose -f docker-compose.prod-postgresql.yml up -d --build

# Step 9: Wait for services to be healthy
echo ""
echo "Step 9: Waiting for services to be healthy..."
echo "This may take 30-60 seconds..."
sleep 30

MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if docker-compose -f docker-compose.prod-postgresql.yml ps | grep -q "Up (healthy)"; then
        log_info "All services are healthy"
        break
    fi
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    log_warn "Services may not be fully healthy yet. Check with: docker-compose ps"
fi

# Step 10: Display service status
echo ""
echo "Step 10: Service Status"
docker-compose -f docker-compose.prod-postgresql.yml ps

# Step 11: Test database connection
echo ""
echo "Step 11: Testing database connection..."
if docker exec ekosim-postgres psql -U ekosim -d ekosim -c "SELECT version();" > /dev/null 2>&1; then
    log_info "Database connection successful"
else
    log_error "Database connection failed"
fi

# Step 12: Display next steps
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Deployment Complete! 🎉                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Configure DNS:"
echo "   - Point ekosim.app to your VM IP"
echo "   - Get IP with: gcloud compute instances describe ekosim-server --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)'"
echo ""
echo "2. Install SSL Certificate:"
echo "   - Stop frontend: docker-compose -f docker-compose.prod-postgresql.yml stop ekosim-frontend"
echo "   - Run: sudo certbot certonly --standalone -d ekosim.app -d www.ekosim.app"
echo "   - Copy certs: sudo cp /etc/letsencrypt/live/ekosim.app/*.pem ssl/"
echo "   - Update nginx config with SSL"
echo "   - Restart: docker-compose -f docker-compose.prod-postgresql.yml start ekosim-frontend"
echo ""
echo "3. Test Application:"
echo "   - From another machine: curl http://YOUR_VM_IP"
echo "   - After DNS: curl https://ekosim.app"
echo ""
echo "4. Run First Backup:"
echo "   - ./scripts/backup-database.sh"
echo ""
echo "Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  View logs:    docker-compose -f docker-compose.prod-postgresql.yml logs -f"
echo "  Check status: docker-compose -f docker-compose.prod-postgresql.yml ps"
echo "  Restart all:  docker-compose -f docker-compose.prod-postgresql.yml restart"
echo "  Stop all:     docker-compose -f docker-compose.prod-postgresql.yml stop"
echo ""
echo "Documentation: /opt/ekosim/EkoSim-Infrastructure/DEPLOYMENT_GUIDE.md"
echo ""
