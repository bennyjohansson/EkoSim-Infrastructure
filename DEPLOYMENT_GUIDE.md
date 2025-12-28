# EkoSim GCP Deployment Guide - Phase 1

**Deploy to Google Cloud Platform Compute Engine with containerized PostgreSQL**

## Prerequisites

- Google Cloud Platform account (active)
- Domain name registered (e.g., ekosim.app)
- GitHub account with access to EkoSim repositories
- Local terminal with gcloud CLI installed

## Estimated Timeline

- **VM Setup**: 30 minutes
- **Application Deployment**: 45 minutes
- **Domain & SSL**: 30 minutes
- **Testing & Verification**: 30 minutes
- **Total**: ~2.5 hours

---

## Phase 1: Create and Configure GCP VM

### Step 1: Create Compute Engine Instance

Open your terminal locally and run:

```bash
# Set your project ID
export PROJECT_ID="ekosim-production"
gcloud config set project $PROJECT_ID

# Create the VM instance
gcloud compute instances create ekosim-server \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-standard \
  --tags=http-server,https-server,ekosim \
  --metadata=startup-script='#! /bin/bash
    apt-get update
    apt-get install -y git'

# Wait for instance to be created (should take ~30 seconds)
```

### Step 2: Configure Firewall Rules

```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --target-tags=http-server \
  --description="Allow HTTP traffic"

# Allow HTTPS traffic
gcloud compute firewall-rules create allow-https \
  --allow tcp:443 \
  --target-tags=https-server \
  --description="Allow HTTPS traffic"

# Verify firewall rules
gcloud compute firewall-rules list --filter="name~'allow-http'"
```

### Step 3: Get VM External IP

```bash
# Get the external IP address
gcloud compute instances describe ekosim-server \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Save this IP - you'll need it for DNS configuration
export EKOSIM_IP=$(gcloud compute instances describe ekosim-server \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Your EkoSim IP: $EKOSIM_IP"
```

---

## Phase 2: Initial VM Setup

### Step 4: SSH into VM

```bash
# SSH into your instance
gcloud compute ssh ekosim-server --zone=us-central1-a

# You should now be inside the VM
```

### Step 5: Run Setup Script

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/bennyjohansson/EkoSim-Infrastructure/main/scripts/gcp-vm-setup.sh -o setup.sh
curl -fsSL https://raw.githubusercontent.com/bennyjohansson/EkoSim-Infrastructure/feature/gcp-phase1-deployment/scripts/gcp-vm-setup.sh -o setup.sh
c
chmod +x setup.sh
./setup.sh

# OR if you prefer to do it manually, copy the script content and run it

# After setup completes, apply Docker group permissions
newgrp docker

# Verify Docker is working
docker --version
docker-compose --version
```

---

## Phase 3: Clone Repositories and Configure

### Step 6: Clone Repositories

```bash
# Navigate to application directory
cd /opt/ekosim

# Clone all three repositories
# Replace YOUR_USERNAME with your GitHub username

# 1. C++ Backend (SSH URL)
git clone git@github.com:bennyjohansson/ekosimProject.git

# 2. Web Application (SSH URL)
git clone git@github.com:bennyjohansson/EkosimWeb.git

# 3. Infrastructure (SSH URL)
git clone git@github.com:bennyjohansson/EkoSim-Infrastructure.git

# Verify all repos are cloned
ls -la
# Should show: ekosimProject/ EkosimWeb/ EkoSim-Infrastructure/
```

### Step 7: Configure Environment Variables

```bash
# Navigate to infrastructure directory
cd /opt/ekosim/EkoSim-Infrastructure

# Copy environment template
cp .env.production.template .env

# Generate secure secrets
echo "Generating secure secrets..."

# Generate PostgreSQL password
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Generate JWT secret
export JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')

# Generate session secret
export SESSION_SECRET=$(openssl rand -hex 32)

# Update .env file with generated secrets
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

# Display the .env file (verify it's correct)
cat .env

# IMPORTANT: Save these secrets in a secure location!
echo ""
echo "⚠️  SAVE THESE SECRETS IN A SECURE PASSWORD MANAGER:"
echo "=================================================="
cat .env
echo "=================================================="
```

---

## Phase 4: Create Cloud Storage Bucket for Backups

### Step 8: Set Up Backup Storage

```bash
# Create Cloud Storage bucket for backups
gsutil mb -l us-central1 gs://ekosim-backups

# Set lifecycle policy to delete backups older than 90 days
cat > /tmp/lifecycle.json <<EOF
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

# Verify bucket was created
gsutil ls gs://ekosim-backups

# Set up service account authentication (already configured on Compute Engine)
```

### Step 9: Install Backup Script

```bash
# Make backup script executable
chmod +x /opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh
chmod +x /opt/ekosim/EkoSim-Infrastructure/scripts/restore-database.sh

# Test backup script (will run after we deploy)
# /opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh

# Set up cron job for daily backups at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh") | crontab -

# Verify cron job
crontab -l
```

---

## Phase 5: Deploy Application

### Step 10: Build and Start Containers

```bash
# Navigate to infrastructure directory
cd /opt/ekosim/EkoSim-Infrastructure

# Pull base images to speed up build
docker pull postgres:15-alpine
docker pull node:20-alpine
docker pull nginx:alpine
docker pull ubuntu:22.04

# Build and start all services (this will take 5-10 minutes)
docker-compose -f docker-compose.prod-postgresql.yml up -d --build

# Monitor the build process
docker-compose -f docker-compose.prod-postgresql.yml logs -f

# Wait for all services to be healthy (press Ctrl+C to exit logs)
```

### Step 11: Verify Services

```bash
# Check service status
docker-compose -f docker-compose.prod-postgresql.yml ps

# All services should show "Up" or "Up (healthy)"

# Check individual service health
docker logs ekosim-postgres
docker logs ekosim-backend
docker logs ekosim-api
docker logs ekosim-frontend

# Test database connection
docker exec ekosim-postgres psql -U ekosim -d ekosim -c "SELECT version();"

# Test API health endpoint (from within the VM)
curl http://localhost:3001/health

# Test frontend (from within the VM)
curl http://localhost/
```

---

## Phase 6: Configure Domain and SSL

### Step 12: Configure DNS

**In your domain registrar's control panel (e.g., Google Domains, Namecheap, etc.):**

1. Log in to your domain registrar
2. Navigate to DNS settings for `ekosim.app`
3. Add/Update these records:

```
Type: A
Name: @
Value: YOUR_VM_EXTERNAL_IP
TTL: 300

Type: A
Name: www
Value: YOUR_VM_EXTERNAL_IP
TTL: 300
```

4. Save changes
5. Wait 5-15 minutes for DNS propagation

**Verify DNS propagation:**

```bash
# From your local machine (not the VM)
nslookup ekosim.app
dig ekosim.app

# Should return your VM's IP address
```

### Step 13: Install SSL Certificate (Let's Encrypt)

```bash
# Back on the VM, stop the frontend container temporarily
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml stop ekosim-frontend

# Install SSL certificate
sudo certbot certonly --standalone \
  -d ekosim.app \
  -d www.ekosim.app \
  --agree-tos \
  --email your-email@example.com \
  --non-interactive

# Certificate should be installed at:
# /etc/letsencrypt/live/ekosim.app/fullchain.pem
# /etc/letsencrypt/live/ekosim.app/privkey.pem

# Create SSL directory for nginx
sudo mkdir -p /opt/ekosim/EkoSim-Infrastructure/ssl
sudo cp /etc/letsencrypt/live/ekosim.app/fullchain.pem /opt/ekosim/EkoSim-Infrastructure/ssl/
sudo cp /etc/letsencrypt/live/ekosim.app/privkey.pem /opt/ekosim/EkoSim-Infrastructure/ssl/
sudo chown -R $USER:$USER /opt/ekosim/EkoSim-Infrastructure/ssl
```

### Step 14: Update Nginx Configuration for SSL

```bash
# Create production nginx config with SSL
cd /opt/ekosim/EkoSim-Infrastructure

cat > config/nginx.prod.conf <<'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name ekosim.app www.ekosim.app;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name ekosim.app www.ekosim.app;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        root /usr/share/nginx/html;
        index index.html;

        # SPA routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # API proxy
        location /api/ {
            proxy_pass http://ekosim-api:3001/api/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Backend proxy
        location /ekosim/ {
            proxy_pass http://ekosim-backend:8080/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Cache static assets
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Update docker-compose to use the new nginx config
```

### Step 15: Restart with SSL

```bash
# Update the docker-compose file to mount SSL certificates
# (The docker-compose.prod-postgresql.yml already has the volume mount for ssl/)

# Restart frontend with SSL enabled
docker-compose -f docker-compose.prod-postgresql.yml up -d ekosim-frontend

# Verify all services are running
docker-compose -f docker-compose.prod-postgresql.yml ps

# Check logs
docker-compose -f docker-compose.prod-postgresql.yml logs -f ekosim-frontend
```

### Step 16: Set Up SSL Auto-Renewal

```bash
# Test SSL renewal
sudo certbot renew --dry-run

# Set up automatic renewal (runs twice daily)
(sudo crontab -l 2>/dev/null; echo "0 0,12 * * * certbot renew --quiet --post-hook 'cp /etc/letsencrypt/live/ekosim.app/*.pem /opt/ekosim/EkoSim-Infrastructure/ssl/ && cd /opt/ekosim/EkoSim-Infrastructure && docker-compose -f docker-compose.prod-postgresql.yml restart ekosim-frontend'") | sudo crontab -
```

---

## Phase 7: Testing and Verification

### Step 17: Comprehensive Testing

```bash
# From your local machine, test the production site

# Test HTTP redirect to HTTPS
curl -I http://ekosim.app
# Should return: HTTP/1.1 301 Moved Permanently

# Test HTTPS
curl -I https://ekosim.app
# Should return: HTTP/2 200

# Test API health
curl https://ekosim.app/api/health

# Test in browser
# Open: https://ekosim.app
```

### Step 18: Create Test User

```bash
# Register a test user through the web interface
# https://ekosim.app

# Or via API:
curl -X POST https://ekosim.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "SecurePassword123!"
  }'

# Login:
curl -X POST https://ekosim.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123!"
  }'
```

### Step 19: Run First Backup

```bash
# SSH back into the VM
gcloud compute ssh ekosim-server --zone=us-central1-a

# Run backup script manually
/opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh

# Verify backup was created locally
ls -lh /var/backups/ekosim/

# Verify backup was uploaded to Cloud Storage
gsutil ls gs://ekosim-backups/database/

# Check backup log
tail -n 50 /var/log/ekosim/backup.log
```

---

## Phase 8: Monitoring and Maintenance

### Step 20: Set Up Basic Monitoring

```bash
# Check system resources
htop

# Check disk usage
df -h

# Check Docker stats
docker stats

# Set up log rotation
sudo tee /etc/logrotate.d/ekosim <<EOF
/var/log/ekosim/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
    sharedscripts
}
EOF
```

### Step 21: Create Maintenance Scripts

```bash
# Create restart script
cat > /opt/ekosim/scripts/restart-ekosim.sh <<'EOF'
#!/bin/bash
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml restart
echo "EkoSim services restarted at $(date)"
EOF

chmod +x /opt/ekosim/scripts/restart-ekosim.sh

# Create status check script
cat > /opt/ekosim/scripts/check-status.sh <<'EOF'
#!/bin/bash
echo "=== EkoSim Status Check ==="
echo "Date: $(date)"
echo ""
echo "Services:"
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml ps
echo ""
echo "Disk Usage:"
df -h /
echo ""
echo "Memory Usage:"
free -h
echo ""
echo "Last 10 API logs:"
docker logs --tail 10 ekosim-api
EOF

chmod +x /opt/ekosim/scripts/check-status.sh
```

---

## Phase 9: Post-Deployment Checklist

### ✅ Deployment Verification Checklist

- [ ] VM created and accessible via SSH
- [ ] Docker and Docker Compose installed
- [ ] All repositories cloned
- [ ] Environment variables configured
- [ ] Cloud Storage bucket created
- [ ] All containers running and healthy
- [ ] Database initialized with schema
- [ ] DNS configured and propagated
- [ ] SSL certificate installed
- [ ] HTTPS working correctly
- [ ] HTTP redirects to HTTPS
- [ ] API endpoints responding
- [ ] Frontend loads correctly
- [ ] User registration works
- [ ] User login works
- [ ] Database backup script works
- [ ] Backup uploaded to Cloud Storage
- [ ] Cron jobs configured
- [ ] SSL auto-renewal configured

### 📊 Monitoring URLs

- **Application**: https://ekosim.app
- **API Health**: https://ekosim.app/api/health
- **GCP Console**: https://console.cloud.google.com

### 🔧 Useful Commands

```bash
# SSH into VM
gcloud compute ssh ekosim-server --zone=us-central1-a

# View all logs
cd /opt/ekosim/EkoSim-Infrastructure
docker-compose -f docker-compose.prod-postgresql.yml logs -f

# View specific service logs
docker logs -f ekosim-api
docker logs -f ekosim-backend
docker logs -f ekosim-postgres
docker logs -f ekosim-frontend

# Restart services
docker-compose -f docker-compose.prod-postgresql.yml restart

# Stop services
docker-compose -f docker-compose.prod-postgresql.yml stop

# Start services
docker-compose -f docker-compose.prod-postgresql.yml start

# Rebuild and restart a specific service
docker-compose -f docker-compose.prod-postgresql.yml up -d --build ekosim-api

# Check service health
docker-compose -f docker-compose.prod-postgresql.yml ps

# Access PostgreSQL
docker exec -it ekosim-postgres psql -U ekosim -d ekosim

# View system resources
htop
docker stats
```

---

## Troubleshooting

### Issue: Services won't start

```bash
# Check logs for errors
docker-compose -f docker-compose.prod-postgresql.yml logs

# Check if ports are available
sudo netstat -tlnp | grep -E '(80|443|3001|5432|8080)'

# Restart Docker
sudo systemctl restart docker
```

### Issue: Can't connect to database

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs ekosim-postgres

# Test connection
docker exec ekosim-postgres psql -U ekosim -d ekosim -c "SELECT 1;"
```

### Issue: SSL certificate errors

```bash
# Renew certificate
sudo certbot renew --force-renewal

# Copy to ssl directory
sudo cp /etc/letsencrypt/live/ekosim.app/*.pem /opt/ekosim/EkoSim-Infrastructure/ssl/

# Restart frontend
docker-compose -f docker-compose.prod-postgresql.yml restart ekosim-frontend
```

### Issue: Out of disk space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Clean up old backups
find /var/backups/ekosim -name "*.sql.gz" -mtime +7 -delete
```

---

## Cost Monitoring

Monitor your costs at: https://console.cloud.google.com/billing

**Expected Monthly Costs:**

- Compute Engine (e2-medium): ~$25/month
- Storage (50GB + backups): ~$5/month
- Network Egress: ~$5-10/month
- **Total: ~$35-40/month**

---

## Next Steps

1. **Monitor for 24 hours** - Ensure everything runs smoothly
2. **Beta test** - Invite 5-10 users to test
3. **Set up monitoring** - Consider Uptime Robot or similar
4. **Marketing** - Announce launch on social media
5. **Phase 2 Planning** - Start iOS app development

---

## Support

If you encounter issues:

1. Check the logs: `docker-compose logs`
2. Review troubleshooting section above
3. Check GCP console for VM status
4. Verify DNS propagation

**Deployment Complete! 🎉**

Your EkoSim application is now live at: https://ekosim.app
