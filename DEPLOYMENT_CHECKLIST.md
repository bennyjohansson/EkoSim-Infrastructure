# EkoSim GCP Deployment Checklist

Use this checklist to ensure all steps are completed during deployment.

## Pre-Deployment Preparation

### Local Machine Setup

- [x ] Google Cloud SDK installed and authenticated (`gcloud auth login`)
- [ x] Project ID configured (`gcloud config set project YOUR_PROJECT_ID`)
- [ ] Domain name registered (e.g., ekosim.app)
- [ ] GitHub repositories are accessible
- [ ] Architecture document reviewed

### GCP Account

- [ x] Billing enabled
- [ x] Compute Engine API enabled
- [ x] Cloud Storage API enabled
- [ x] Sufficient quota for e2-medium instance

---

## Phase 1: GCP VM Creation (15 minutes)

### Create VM Instance

- [x ] VM created with correct specs (e2-medium, 50GB)
- [x] VM is in running state
- [x ] Firewall rules created (HTTP, HTTPS)
- [x ] External IP address obtained and saved "Your EkoSim IP: 34.61.19.198"
- [x ] Can SSH into VM successfully

**Commands:**

```bash
gcloud compute instances create ekosim-server \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=http-server,https-server

gcloud compute firewall-rules create allow-http --allow tcp:80 --target-tags=http-server
gcloud compute firewall-rules create allow-https --allow tcp:443 --target-tags=https-server

# Get IP
gcloud compute instances describe ekosim-server --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

**VM IP Address:** **\*\***\*\***\*\***\_\_\_\_**\*\***\*\***\*\***

---

## Phase 2: Initial VM Setup (30 minutes)

### SSH and Setup

- [x] SSH connection established
- [x ] System packages updated
- [x ] Docker installed
- [x ] Docker Compose installed
- [x ] Google Cloud SDK installed
- [x ] UFW firewall configured
- [x ] Application directories created (`/opt/ekosim`)
- [x ] Backup directory created (`/var/backups/ekosim`)
- [x ] Log directory created (`/var/log/ekosim`)
- [x ] Docker group permissions applied (`newgrp docker`)

**Command:**

```bash
gcloud compute ssh ekosim-server --zone=us-central1-a
# Then run gcp-vm-setup.sh
```

---

## Phase 3: Repository Setup (10 minutes)

### Clone Repositories

- [ x] Changed to `/opt/ekosim` directory
- [ x] ekosim repository cloned
- [ x] EkoWeb repository cloned
- [ x] EkoSim-Infrastructure repository cloned
- [ x] All repositories have correct permissions

**Commands:**

```bash
cd /opt/ekosim
git clone https://github.com/YOUR_USERNAME/ekosim.git
git clone https://github.com/YOUR_USERNAME/EkoWeb.git
git clone https://github.com/YOUR_USERNAME/EkoSim-Infrastructure.git
```

---

## Phase 4: Environment Configuration (10 minutes)

### Generate Secrets

- [x ] `.env` file created from template
- [x ] PostgreSQL password generated
- [ x] JWT secret generated
- [x ] Session secret generated
- [ ] ALLOWED_ORIGINS set to production domain
- [ x] Secrets saved in password manager

**Secrets to Save:**

```
POSTGRES_PASSWORD: _________________________________
JWT_SECRET: _______________________________________
SESSION_SECRET: ___________________________________
```

**Commands:**

```bash
cd /opt/ekosim/EkoSim-Infrastructure
openssl rand -hex 32  # PostgreSQL password
openssl rand -base64 64 | tr -d '\n'  # JWT secret
openssl rand -hex 32  # Session secret
```

---

## Phase 5: Cloud Storage Setup (5 minutes)

### Create Backup Bucket

- [ ] Cloud Storage bucket created (`gs://ekosim-backups`)
- [ ] Lifecycle policy set (90-day retention)
- [ ] Bucket permissions verified
- [ ] Can list bucket contents

**Command:**

```bash
gsutil mb -l us-central1 gs://ekosim-backups
```

---

## Phase 6: Application Deployment (20 minutes)

### Deploy Services

- [x] Deployment script executed
- [ ] PostgreSQL container started
- [ ] Backend container built and started
- [ ] API container built and started
- [ ] Frontend container built and started
- [ ] All containers show "Up (healthy)" status
- [ ] Database initialized with schema
- [ ] Can connect to database

**Command:**

```bash
cd /opt/ekosim/EkoSim-Infrastructure
./scripts/deploy.sh
```

**Verification:**

```bash
docker-compose -f docker-compose.prod-postgresql.yml ps
docker exec ekosim-postgres psql -U ekosim -d ekosim -c "SELECT version();"
```

---

## Phase 7: Backup Configuration (10 minutes)

### Setup Automated Backups

- [ ] Backup script is executable
- [ ] Restore script is executable
- [ ] Cron job configured for daily backups (3 AM)
- [ ] Manual backup test successful
- [ ] Backup appears in Cloud Storage
- [ ] Local backup file created
- [ ] Backup log file created

**Commands:**

```bash
/opt/ekosim/EkoSim-Infrastructure/scripts/backup-database.sh
gsutil ls gs://ekosim-backups/database/
crontab -l  # Verify cron job
```

---

## Phase 8: DNS Configuration (15 minutes)

### Domain Setup

- [ ] DNS A record created for @ (apex domain)
- [ ] DNS A record created for www subdomain
- [ ] Both records point to VM external IP
- [ ] TTL set to 300 seconds (5 minutes)
- [ ] DNS propagation verified with nslookup
- [ ] DNS propagation verified with dig

**DNS Records:**

```
Type: A, Name: @, Value: YOUR_VM_IP, TTL: 300
Type: A, Name: www, Value: YOUR_VM_IP, TTL: 300
```

**Verification (from local machine):**

```bash
nslookup ekosim.app
dig ekosim.app
```

---

## Phase 9: SSL Certificate (15 minutes)

### Let's Encrypt Setup

- [ ] Frontend container stopped
- [ ] Certbot installed on VM
- [ ] SSL certificate obtained for both domains
- [ ] Certificate files exist in `/etc/letsencrypt/live/ekosim.app/`
- [ ] Certificates copied to `ssl/` directory
- [ ] Correct permissions on SSL files
- [ ] Nginx configuration updated for SSL
- [ ] Frontend container restarted
- [ ] HTTPS working correctly
- [ ] HTTP redirects to HTTPS
- [ ] SSL certificate auto-renewal configured

**Commands:**

```bash
docker-compose -f docker-compose.prod-postgresql.yml stop ekosim-frontend

sudo certbot certonly --standalone \
  -d ekosim.app \
  -d www.ekosim.app \
  --email your-email@example.com \
  --agree-tos

sudo cp /etc/letsencrypt/live/ekosim.app/*.pem ssl/
sudo chown -R $USER:$USER ssl/

docker-compose -f docker-compose.prod-postgresql.yml start ekosim-frontend
```

**Verification:**

```bash
curl -I http://ekosim.app  # Should redirect to HTTPS
curl -I https://ekosim.app  # Should return 200 OK
```

---

## Phase 10: Testing & Verification (20 minutes)

### Functional Testing

- [ ] Frontend loads at https://ekosim.app
- [ ] HTTPS certificate is valid (no warnings)
- [ ] HTTP automatically redirects to HTTPS
- [ ] API health endpoint responds: `/api/health`
- [ ] Backend health endpoint works (if exposed)
- [ ] User registration works
- [ ] User login works
- [ ] Dashboard displays data
- [ ] All charts render correctly
- [ ] No console errors in browser
- [ ] Mobile responsive design works

### System Health

- [ ] All containers running: `docker ps`
- [ ] No error logs: `docker-compose logs`
- [ ] Database connection working
- [ ] Adequate disk space: `df -h`
- [ ] Memory usage acceptable: `free -h`
- [ ] CPU usage normal: `htop`

### Backup Verification

- [ ] Backup script runs without errors
- [ ] Backup file created locally
- [ ] Backup uploaded to Cloud Storage
- [ ] Can list backups in GCS
- [ ] Restore script tested (optional)

**Test Commands:**

```bash
# From local machine
curl https://ekosim.app
curl https://ekosim.app/api/health

# From VM
docker-compose -f docker-compose.prod-postgresql.yml ps
docker-compose -f docker-compose.prod-postgresql.yml logs --tail 50
```

---

## Phase 11: Monitoring Setup (15 minutes)

### Logging & Monitoring

- [ ] Log rotation configured
- [ ] Nginx access logs accessible
- [ ] Nginx error logs accessible
- [ ] Application logs accessible via Docker
- [ ] Backup logs in `/var/log/ekosim/backup.log`
- [ ] Status check script created
- [ ] Restart script created

### External Monitoring (Optional)

- [ ] UptimeRobot or similar configured
- [ ] Email alerts set up
- [ ] Status page created

---

## Phase 12: Security Verification (10 minutes)

### Security Checklist

- [ ] SSH key-based authentication only (no password)
- [ ] UFW firewall enabled
- [ ] Only ports 80 and 443 exposed externally
- [ ] Strong PostgreSQL password
- [ ] Secure JWT secret
- [ ] Environment variables not in git
- [ ] `.env` file has restricted permissions (600)
- [ ] SSL certificate valid and trusted
- [ ] Rate limiting enabled on API
- [ ] CORS configured correctly

**Commands:**

```bash
sudo ufw status
ls -la .env  # Should be -rw-------
```

---

## Phase 13: Documentation (10 minutes)

### Documentation Complete

- [ ] Secrets saved in password manager
- [ ] VM IP address documented
- [ ] Domain configuration documented
- [ ] Emergency procedures documented
- [ ] Team members have access to documentation
- [ ] Support contact information updated

---

## Post-Deployment (First 48 Hours)

### Monitoring Period

- [ ] Check logs every 6 hours
- [ ] Monitor disk space
- [ ] Verify backups running automatically
- [ ] Test user registrations
- [ ] Monitor CPU/memory usage
- [ ] Check for any error patterns
- [ ] Verify SSL certificate working
- [ ] Test from different devices/browsers

### Day 1 Checklist

- [ ] Morning check (9 AM)
- [ ] Afternoon check (3 PM)
- [ ] Evening check (9 PM)
- [ ] Backup completed successfully

### Day 2 Checklist

- [ ] Morning check (9 AM)
- [ ] Afternoon check (3 PM)
- [ ] Evening check (9 PM)
- [ ] Backup completed successfully
- [ ] No critical issues reported

---

## Launch Preparation

### Beta Testing

- [ ] 5-10 beta users invited
- [ ] Beta user feedback collected
- [ ] Critical bugs fixed
- [ ] Performance acceptable

### Marketing

- [ ] Social media accounts ready
- [ ] Launch announcement prepared
- [ ] ProductHunt submission planned
- [ ] Blog post or press release ready

### Support

- [ ] Support email set up
- [ ] FAQ page created
- [ ] Known issues documented
- [ ] Escalation procedure defined

---

## Emergency Contacts & Resources

**VM SSH:**

```bash
gcloud compute ssh ekosim-server --zone=us-central1-a
```

**GCP Console:**
https://console.cloud.google.com

**Quick Fixes:**

- Restart: `docker-compose -f docker-compose.prod-postgresql.yml restart`
- Logs: `docker-compose -f docker-compose.prod-postgresql.yml logs -f`
- Status: `docker-compose -f docker-compose.prod-postgresql.yml ps`

**Support Resources:**

- Deployment Guide: `/opt/ekosim/EkoSim-Infrastructure/DEPLOYMENT_GUIDE.md`
- Quick Reference: `/opt/ekosim/EkoSim-Infrastructure/QUICK_REFERENCE.md`
- Architecture Doc: `/opt/ekosim/ARCHITECTURE_AND_DEPLOYMENT.md`

---

## Sign-Off

**Deployment Completed By:** \***\*\*\*\*\*\*\***\_\_\_\_\***\*\*\*\*\*\*\***

**Date:** \***\*\*\*\*\*\*\***\_\_\_\_\***\*\*\*\*\*\*\***

**Time:** \***\*\*\*\*\*\*\***\_\_\_\_\***\*\*\*\*\*\*\***

**All Checks Passed:** ☐ Yes ☐ No (document issues below)

**Issues/Notes:**

---

---

---

**Production URL:** https://ekosim.app

**Status:** ☐ Live ☐ Beta ☐ Testing

---

## Maintenance Schedule

**Daily:**

- Automated backups (3 AM)
- Log rotation

**Weekly:**

- Review logs for errors
- Check disk usage
- Monitor user growth

**Monthly:**

- Security updates
- Performance review
- Cost analysis
- Feature planning

---

**Congratulations! Your EkoSim platform is now deployed to production! 🎉**
