#!/bin/bash

# EC2 Server Setup Script for Manufacturing QC Backend
echo "🚀 Setting up EC2 instance for Manufacturing QC Backend..."

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    htop \
    unzip \
    build-essential \
    pkg-config \
    libpq-dev \
    libmagic-dev \
    supervisor

# Install Docker
echo "📦 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install PostgreSQL
echo "🗄️ Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Setup PostgreSQL database
sudo -u postgres psql << EOF
CREATE DATABASE qc_system;
CREATE USER qc_user WITH ENCRYPTED PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE qc_system TO qc_user;
ALTER USER qc_user CREATEDB;
\q
EOF

# Create application directory
sudo mkdir -p /opt/manufacturing-qc
sudo chown $USER:$USER /opt/manufacturing-qc
cd /opt/manufacturing-qc

# Create log directories
sudo mkdir -p /var/log/manufacturing-qc
sudo chown $USER:$USER /var/log/manufacturing-qc

echo "✅ EC2 setup completed. Ready for application deployment."
echo "📝 Next steps:"
echo "   1. Clone your repository"
echo "   2. Configure environment variables"
echo "   3. Run the application deployment script"
