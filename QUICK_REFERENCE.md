# EkoSim GCP Deployment - Quick Reference Card

## 🚀 Quick Start (From Your Local Machine)

### 1. Create GCP VM (5 minutes)

```bash
# Set your project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Create VM
gcloud compute instances create ekosim-server \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=http-server,https-server

# Configure firewall
gcloud compute firewall-rules create allow-http --allow tcp:80 --target-tags=http-server
gcloud compute firewall-rules create allow-https --allow tcp:443 --target-tags=https-server

# Get VM IP
gcloud compute instances describe ekosim-server --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### 2. SSH and Initial Setup (30 minutes)

```bash
# SSH into VM
gcloud compute ssh ekosim-server --zone=us-central1-a

# Run setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/EkoSim-Infrastructure/main/scripts/gcp-vm-setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh

# Activate Docker group
newgrp docker
```

### 3. Clone Repositories (5 minutes)

```bash
cd /opt/ekosim

# Clone repos (replace YOUR_USERNAME)
git clone https://github.com/YOUR_USERNAME/ekosim.git
git clone https://github.com/YOUR_USERNAME/EkoWeb.git
git clone https://github.com/YOUR_USERNAME/EkoSim-Infrastructure.git

ls -la  # Verify all three directories exist
```

### 4. Deploy Application (10 minutes)

```bash
cd /opt/ekosim/EkoSim-Infrastructure
./scripts/deploy.sh

# The script will:
# - Generate secure secrets
# - Create Cloud Storage bucket
# - Set up automated backups
# - Build and start all containers
# - Verify services are healthy
```

### 5. Configure DNS (15 minutes)

**In your domain registrar:**
- A record: `@` → `YOUR_VM_IP`
- A record: `www` → `YOUR_VM_IP`

**Verify DNS:**
```bash
nslookup ekosim.app
```

### 6. Install SSL Certificate (10 minutes)

```bash
# Stop frontend
docker-compose -f docker-compose.prod-postgresql.yml stop ekosim-frontend

# Get certificate
sudo certbot certonly --standalone \
  -d ekosim.app \
  -d www.ekosim.app \
  --email your-email@example.com \
  --agree-tos

# Copy certificates
sudo mkdir -p ssl
sudo cp /etc/letsencrypt/live/ekosim.app/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/ekosim.app/privkey.pem ssl/
sudo chown -R $USER:$USER ssl/

# Restart frontend
docker-compose -f docker-compose.prod-postgresql.yml start ekosim-frontend
```

### 7. Verify Deployment (5 minutes)

```bash
# Check services
docker-compose -f docker-compose.prod-postgresql.yml ps

# Test from another machine
curl https://ekosim.app
curl https://ekosim.app/api/health

# Run first backup
./scripts/backup-database.sh
```

---

## 📋 Essential Commands

### Service Management

```bash
# View all services
docker-compose -f docker-compose.prod-postgresql.yml ps

# View logs (all services)
docker-compose -f docker-compose.prod-postgresql.yml logs -f

# View logs (specific service)
docker logs -f ekosim-api

# Restart all services
docker-compose -f docker-compose.prod-postgresql.yml restart

# Restart specific service
docker-compose -f docker-compose.prod-postgresql.yml restart ekosim-api

# Stop all services
docker-compose -f docker-compose.prod-postgresql.yml stop

# Start all services
docker-compose -f docker-compose.prod-postgresql.yml start

# Rebuild and restart
docker-compose -f docker-compose.prod-postgresql.yml up -d --build
```

### Database Operations

```bash
# Access PostgreSQL
docker exec -it ekosim-postgres psql -U ekosim -d ekosim

# Common queries
SELECT COUNT(*) FROM users;
SELECT * FROM companies LIMIT 10;
\dt  -- List tables
\q   -- Quit

# Backup database
/opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh

# Restore from local backup
./scripts/restore-database.sh /var/backups/ekosim/ekosim_backup_YYYYMMDD_HHMMSS.sql.gz

# Restore from Cloud Storage
./scripts/restore-database.sh gs://ekosim-backups/database/ekosim_backup_YYYYMMDD_HHMMSS.sql.gz --from-gcs
```

### Monitoring

```bash
# System resources
htop
docker stats

# Disk usage
df -h
docker system df

# Service health
docker inspect ekosim-api | grep -A 10 "Health"

# Recent logs
docker logs --tail 50 ekosim-api
docker logs --tail 50 ekosim-backend
```

### Maintenance

```bash
# Clean Docker
docker system prune -a

# Clean old backups (keep last 7 days)
find /var/backups/ekosim -name "*.sql.gz" -mtime +7 -delete

# Update SSL certificate
sudo certbot renew
sudo cp /etc/letsencrypt/live/ekosim.app/*.pem /opt/ekosim/EkoSim-Infrastructure/ssl/
docker-compose -f docker-compose.prod-postgresql.yml restart ekosim-frontend

# Update application code
cd /opt/ekosim/ekosim && git pull
cd /opt/ekosim/EkoWeb && git pull
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml up -d --build
```

---

## 🔧 Troubleshooting Quick Fixes

### Services won't start
```bash
docker-compose -f docker-compose.prod-postgresql.yml logs
sudo systemctl restart docker
```

### Database connection failed
```bash
docker logs ekosim-postgres
docker exec ekosim-postgres psql -U ekosim -d ekosim -c "SELECT 1;"
```

### Out of disk space
```bash
docker system prune -a
find /var/backups/ekosim -mtime +7 -delete
```

### SSL certificate expired
```bash
sudo certbot renew --force-renewal
sudo cp /etc/letsencrypt/live/ekosim.app/*.pem ssl/
docker-compose -f docker-compose.prod-postgresql.yml restart ekosim-frontend
```

---

## 📊 Important Locations

| Item | Location |
|------|----------|
| Application | `/opt/ekosim/` |
| Environment Config | `/opt/ekosim/EkoSim-Infrastructure/.env` |
| Docker Compose | `/opt/ekosim/EkoSim-Infrastructure/docker-compose.prod-postgresql.yml` |
| Nginx Config | `/opt/ekosim/EkoSim-Infrastructure/config/nginx.conf` |
| SSL Certificates | `/opt/ekosim/EkoSim-Infrastructure/ssl/` |
| Local Backups | `/var/backups/ekosim/` |
| Cloud Backups | `gs://ekosim-backups/database/` |
| Logs | `/var/log/ekosim/` |
| Nginx Logs | `/opt/ekosim/EkoSim-Infrastructure/logs/nginx/` |

---

## 🌐 URLs & Endpoints

| Service | URL |
|---------|-----|
| **Production Site** | https://ekosim.app |
| **API Health** | https://ekosim.app/api/health |
| **GCP Console** | https://console.cloud.google.com |
| **GCP VM SSH** | `gcloud compute ssh ekosim-server --zone=us-central1-a` |

---

## 📝 Environment Variables

Required in `.env`:
```bash
POSTGRES_DB=ekosim
POSTGRES_USER=ekosim
POSTGRES_PASSWORD=<64-char-hex>    # openssl rand -hex 32
JWT_SECRET=<88-char-base64>        # openssl rand -base64 64
SESSION_SECRET=<64-char-hex>       # openssl rand -hex 32
ALLOWED_ORIGINS=https://ekosim.app,https://www.ekosim.app
```

---

## 💰 Monthly Costs (Estimated)

| Component | Cost |
|-----------|------|
| Compute Engine (e2-medium) | ~$25 |
| Storage (50GB + backups) | ~$5 |
| Network Egress | ~$5-10 |
| **Total** | **~$35-40** |

---

## 📚 Documentation

- **Full Deployment Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Architecture Overview**: [ARCHITECTURE_AND_DEPLOYMENT.md](../ARCHITECTURE_AND_DEPLOYMENT.md)
- **Infrastructure README**: [README.md](README.md)

---

## ⚡ Emergency Contacts

**If something goes wrong:**
1. Check logs: `docker-compose logs -f`
2. Check service status: `docker-compose ps`
3. Restart services: `docker-compose restart`
4. Check disk space: `df -h`
5. Restore from backup if needed

**Save this file locally and keep it handy!**
