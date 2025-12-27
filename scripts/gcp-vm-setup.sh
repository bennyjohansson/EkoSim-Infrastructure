#!/bin/bash
# GCP Compute Engine Setup Script for EkoSim
# This script sets up a fresh Ubuntu VM with Docker and all dependencies

set -e  # Exit on error

echo "=== EkoSim GCP Compute Engine Setup ==="
echo "Starting setup at $(date)"

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
echo "🔧 Installing essential tools..."
sudo apt-get install -y \
    curl \
    git \
    vim \
    htop \
    ufw \
    certbot \
    python3-certbot-nginx

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose (standalone for compatibility)
echo "🐳 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION="v2.24.0"
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install Google Cloud SDK (if not already installed)
echo "☁️ Installing Google Cloud SDK..."
if ! command -v gcloud &> /dev/null; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
    echo "✅ Google Cloud SDK installed"
else
    echo "✅ Google Cloud SDK already installed"
fi

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8080/tcp  # Backend (internal only, can be restricted later)
sudo ufw allow 3001/tcp  # API (internal only, can be restricted later)
echo "✅ Firewall configured"

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/ekosim
sudo chown $USER:$USER /opt/ekosim
cd /opt/ekosim

# Create backup directory
echo "📁 Creating backup directory..."
sudo mkdir -p /var/backups/ekosim
sudo chown $USER:$USER /var/backups/ekosim

# Create logs directory
echo "📁 Creating logs directory..."
sudo mkdir -p /var/log/ekosim
sudo chown $USER:$USER /var/log/ekosim

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Log out and log back in for Docker group permissions to take effect"
echo "2. Run: cd /opt/ekosim"
echo "3. Clone your repositories"
echo "4. Copy .env.production.template to .env and fill in values"
echo "5. Run deployment script"
echo ""
echo "⚠️  IMPORTANT: Run 'newgrp docker' or log out/in before using Docker"
